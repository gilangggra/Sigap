# PRD — SIGAP Mobile
**Civic Mutual-Aid & Caregiver Network**
Versi: 1.0.0 | Status: Draft | Terakhir diperbarui: November 2026

---

## 1. Overview

### 1.1 Latar Belakang
Indonesia memiliki ~32 juta lansia (2024) dengan proyeksi meningkat ke 48 juta pada 2035. Mayoritas tinggal di komunitas urban padat dengan struktur RT/RW yang aktif namun belum terdigitalisasi. Ketika terjadi kondisi darurat medis, gap antara waktu kejadian dan respon pertolongan pertama seringkali terlalu lebar — bukan karena tidak ada yang peduli, melainkan karena tidak ada sistem koordinasi cepat antar tetangga.

### 1.2 Visi Produk
Mengubah RT/RW menjadi infrastruktur kesiapsiagaan hyperlocal pertama di Indonesia — di mana setiap lansia terhubung ke jaringan relawan tetangga yang dapat merespons dalam hitungan menit, bukan jam.

### 1.3 Target Pengguna
- **Primer:** Lansia 60+ dan penyandang disabilitas yang tinggal semi-mandiri
- **Sekunder:** Keluarga/wali yang tinggal terpisah
- **Tersier:** Relawan warga aktif, pengurus RT/RW

---

## 2. Peran Pengguna (Role-Based Access)

| Role | ID | Deskripsi |
|---|---|---|
| Care-Receiver | `care_receiver` | Lansia/disabilitas, antarmuka simplified |
| Primary Guardian | `guardian` | Keluarga inti, menerima notifikasi & laporan |
| Community Responder | `responder` | Relawan tetangga terverifikasi |
| Civic Administrator | `civic_admin` | Pengurus RT/RW, validasi & manajemen wilayah |

---

## 3. Fitur per Feature Module

---

### FEATURE 1: Emergency Dispatch
**Prioritas:** P0 — Core, tidak bisa launch tanpa ini

#### F1.1 — One-Tap SOS Button
**Sebagai** Care-Receiver,
**saya ingin** memicu alarm darurat dengan satu tombol,
**agar** bantuan datang secepat mungkin tanpa langkah yang rumit.

**Acceptance Criteria:**
- [ ] Tombol SOS tampil di layar utama dengan ukuran minimum 120x120dp
- [ ] Tombol tersedia di lockscreen widget (Android) dan Dynamic Island shortcut (iOS)
- [ ] Tekan tombol fisik power 3x berturut-turut juga memicu SOS
- [ ] Setelah dipicu, countdown 8 detik muncul dengan opsi "Batalkan"
- [ ] Jika tidak dibatalkan, sinyal SOS dikirim ke server dalam ≤ 3 detik
- [ ] Ponsel bergetar kuat selama countdown

**Edge Cases:**
- Jika GPS belum ready saat SOS dipicu → kirim last known location + flag `gps_approximate: true`
- Jika tidak ada internet → fallback ke SMS gateway otomatis

#### F1.2 — Geofenced Responder Alert
**Sebagai** sistem,
**saya ingin** memilih 5 relawan terdekat yang sedang aktif,
**agar** respons pertolongan datang dari orang yang paling dekat secara fisik.

**Acceptance Criteria:**
- [ ] Query PostGIS `ST_DWithin` radius 500m dari koordinat SOS
- [ ] Jika relawan < 3 dalam radius 500m → expand ke 800m otomatis
- [ ] Push notification dikirim ke maksimal 5 relawan terdekat
- [ ] Notifikasi menggunakan FCM High Priority / APNs Critical Alert (bypass DND)
- [ ] Notifikasi Guardian dikirim bersamaan, tidak menunggu responder

#### F1.3 — First Responder Lock
**Sebagai** Responder,
**saya ingin** mengklaim insiden dengan menekan "Saya Meluncur",
**agar** tidak terjadi duplikasi respons dari banyak relawan.

**Acceptance Criteria:**
- [ ] Hanya 1 relawan yang bisa lock insiden (optimistic lock via Supabase)
- [ ] Setelah lock, relawan lain melihat status "Sedang Ditangani oleh [nama inisial]"
- [ ] Relawan yang lock mendapat peta rute instan ke lokasi korban (deep-link Google Maps)
- [ ] Guardian & Admin RT mendapat notifikasi identitas relawan yang merespons

#### F1.4 — ICE Card Temporary Access
**Sebagai** Responder yang sedang menangani insiden aktif,
**saya ingin** mengakses ringkasan data medis korban,
**agar** saya bisa memberikan pertolongan yang tepat.

**Acceptance Criteria:**
- [ ] Tombol "Lihat Data Medis" hanya muncul jika responder memiliki active emergency token
- [ ] Token digenerate server saat responder lock insiden, berlaku 2 jam
- [ ] Data yang ditampilkan: golongan darah, alergi obat, penyakit kronis, kontak dokter
- [ ] Akses token dicatat di audit log dengan timestamp
- [ ] Setelah insiden resolved / token expired → data medis tidak dapat diakses lagi

#### F1.5 — Incident Resolution
**Sebagai** Guardian atau Admin,
**saya ingin** menutup status darurat setelah situasi terkendali,
**agar** sistem kembali ke kondisi normal dan riwayat tercatat.

**Acceptance Criteria:**
- [ ] Tombol "Tandai Selesai" tersedia untuk Guardian dan Civic Admin
- [ ] Responder wajib mengisi catatan singkat tindakan sebelum resolve
- [ ] Catatan tersimpan di riwayat medis korban
- [ ] Token ICE Card dicabut saat insiden ditutup
- [ ] Semua pihak mendapat notifikasi "Insiden telah diselesaikan"

#### F1.6 — SMS Fallback
**Sebagai** sistem,
**saya ingin** mengirim SMS darurat jika koneksi internet terputus,
**agar** sinyal SOS tetap tersampaikan meski dalam kondisi jaringan buruk.

**Acceptance Criteria:**
- [ ] Deteksi koneksi hilang dalam ≤ 5 detik menggunakan NetInfo
- [ ] SMS otomatis dikirim ke: Guardian terdaftar + nomor darurat RT
- [ ] Isi SMS: nama, alamat, koordinat GPS, tautan Google Maps
- [ ] Konfirmasi pengiriman SMS ditampilkan di UI

---

### FEATURE 2: Wellness Check-in
**Prioritas:** P0 — Core

#### F2.1 — Daily Check-in Card
**Sebagai** Care-Receiver,
**saya ingin** menjawab pertanyaan kondisi pagi dalam satu tap,
**agar** keluarga tahu saya baik-baik saja tanpa harus menelepon setiap hari.

**Acceptance Criteria:**
- [ ] Notifikasi check-in dikirim setiap pagi pada jam yang bisa dikonfigurasi (default: 07.30)
- [ ] Card pertanyaan besar dengan 3 pilihan ikon: 😊 Baik / 😐 Kurang Enak / 😟 Butuh Bantuan
- [ ] Jawaban tersinkronisasi ke dasbor Guardian dalam ≤ 10 detik
- [ ] Jika "Butuh Bantuan" dipilih → Guardian mendapat notifikasi segera

#### F2.2 — Dead-Man Switch Escalation
**Sebagai** sistem,
**saya ingin** mendeteksi ketidakresponsifan pengguna,
**agar** keluarga bisa dihubungi sebelum kondisi memburuk.

**Acceptance Criteria:**
- [ ] Jika tidak ada respons dalam 90 menit → reminder kedua dikirim
- [ ] Jika tidak ada respons dalam 120 menit → Guardian mendapat push notification untuk telepon
- [ ] Jika Guardian tidak merespons dalam 30 menit → Civic Admin diberitahu
- [ ] Eskalasi dihentikan jika Care-Receiver merespons di tahap manapun
- [ ] Hari libur nasional dapat dikonfigurasi untuk menonaktifkan eskalasi

#### F2.3 — Medication & Hydration Reminder
**Sebagai** Care-Receiver,
**saya ingin** diingatkan jadwal minum obat dan minum air,
**agar** saya tidak melewatkan konsumsi obat harian.

**Acceptance Criteria:**
- [ ] Guardian bisa menambah jadwal obat dengan nama, dosis, dan waktu
- [ ] Reminder tampil sebagai notification + audio (expo-av)
- [ ] Care-Receiver tap "Sudah Diminum" → status dicentang
- [ ] Status centang tersinkronisasi ke dasbor Guardian real-time
- [ ] Jika 3x berturut-turut tidak dicentang → Guardian dinotifikasi

---

### FEATURE 3: Micro-Task Board
**Prioritas:** P1 — High Value

#### F3.1 — Create Assistance Request
**Sebagai** Care-Receiver atau Guardian,
**saya ingin** membuat permintaan bantuan kecil,
**agar** kebutuhan sehari-hari terpenuhi tanpa harus bergantung sepenuhnya pada keluarga jauh.

**Acceptance Criteria:**
- [ ] Kategori tersedia: Ambil Resep Obat / Belanja Kebutuhan / Pendampingan Mobilitas / Lainnya
- [ ] Form input: deskripsi (maks 200 karakter), lokasi tujuan, waktu dibutuhkan
- [ ] Tiket hanya visible ke relawan dalam radius 800m
- [ ] Care-Receiver dapat membatalkan tiket selama belum ada yang accept

#### F3.2 — Responder Task Acceptance
**Sebagai** Responder,
**saya ingin** melihat dan menerima tiket bantuan di sekitar saya,
**agar** saya bisa membantu tetangga sesuai ketersediaan waktu.

**Acceptance Criteria:**
- [ ] Daftar tiket ditampilkan berurutan berdasarkan jarak terdekat
- [ ] Tombol "Ambil Tugas" mengunci tiket untuk relawan tersebut
- [ ] Setelah selesai, relawan menandai "Selesai" dan poin sosial bertambah

#### F3.3 — Social Credit System
**Sebagai** sistem,
**saya ingin** mencatat kontribusi relawan,
**agar** ada apresiasi non-finansial yang mendorong partisipasi berkelanjutan.

**Acceptance Criteria:**
- [ ] Setiap tugas selesai: +10 poin sosial
- [ ] Emergency response: +50 poin sosial
- [ ] Leaderboard per RT ditampilkan di halaman komunitas
- [ ] Riwayat jam sukarela dapat diekspor sebagai PDF (untuk program RT berprestasi)

---

### FEATURE 4: Authentication & Verification
**Prioritas:** P0 — Core

#### F4.1 — Onboarding & Role Registration
**Acceptance Criteria:**
- [ ] Registrasi dengan nomor telepon (OTP via Supabase Auth)
- [ ] Setelah OTP verified → pilih role
- [ ] Semua role kecuali `civic_admin` wajib input kode RT/RW unik untuk verifikasi domisili
- [ ] Profil belum aktif sampai Civic Admin memvalidasi akun

#### F4.2 — RT/RW Code Validation
**Acceptance Criteria:**
- [ ] Civic Admin generate kode unik per lingkungan dari dashboard
- [ ] Kode berlaku 30 hari dan bisa di-refresh
- [ ] Satu kode hanya untuk satu lingkungan — tidak bisa dipakai cross-RT

---

### FEATURE 5: Profile & ICE Card Management
**Prioritas:** P1

#### F5.1 — Emergency ICE Card Setup
**Acceptance Criteria:**
- [ ] Care-Receiver atau Guardian mengisi: golongan darah, alergi obat, penyakit kronis, kontak dokter
- [ ] Data dienkripsi at-rest (Supabase Vault / pgcrypto)
- [ ] Hanya dapat diubah oleh Care-Receiver atau Guardian
- [ ] Riwayat perubahan data medis dicatat di audit log

---

### FEATURE 6: Civic Admin Dashboard
**Prioritas:** P1

#### F6.1 — Resident Validation
**Acceptance Criteria:**
- [ ] Admin melihat daftar akun pending verification
- [ ] Approve / Reject dengan catatan alasan
- [ ] Dashboard menampilkan peta sebaran warga terdaftar per RT

#### F6.2 — Incident History
**Acceptance Criteria:**
- [ ] Riwayat seluruh insiden darurat di lingkungan dengan filter tanggal
- [ ] Export CSV untuk pelaporan ke Kelurahan

---

## 4. Non-Functional Requirements

| Kategori | Requirement |
|---|---|
| Performa | SOS dispatch ≤ 3 detik end-to-end |
| Ketersediaan | Uptime 99.5% untuk fitur emergency |
| Keamanan | RLS aktif semua tabel, ICE Card encrypted at-rest |
| Aksesibilitas | WCAG AA untuk simplified mode |
| Offline | SMS fallback wajib berfungsi tanpa internet |
| Privasi | Koordinat GPS tidak disimpan permanen di client |

---

## 5. Out of Scope (v1.0)
- Integrasi langsung dengan sistem BPJS / faskes
- Fitur video call darurat
- Hardware IoT BLE gelang (roadmap v2.0)
- Notifikasi ke Puskesmas otomatis (roadmap v2.0)