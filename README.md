# SIGAP Mobile — Civic Mutual-Aid & Caregiver Network

Aplikasi mobile kesiapsiagaan lingkungan rukun tetangga (*hyperlocal civic safety & mutual-aid*) yang menghubungkan lansia, keluarga, relawan tetangga, dan pengurus RT/RW dalam jaringan tanggap darurat dan saling bantu berbasis geospasial (**PostGIS + Supabase**).

---

## 🌟 Fitur Utama (Berdasarkan PRD)

### 1. Tanggap Darurat Cepat (One-Tap SOS & Dispatch System)
- **Tombol SOS Besar Lansia (120x120 dp):** Mudah diakses dengan rasio kontras tinggi (WCAG AA).
- **Hitung Mundur Pembatalan 8 Detik:** Dilengkapi umpan balik multi-sensoris (getaran berulang dan audio alert) untuk mencegah alarm palsu.
- **Geofenced Responder Alert:** Menggunakan PostGIS (`ST_DWithin`) untuk menyiarkan sinyal darurat ke relawan terdekat dalam radius 500m (otomatis ekspansi ke 800m jika relawan siaga < 3 orang).
- **First Responder Lock:** Mekanisme penguncian relawan pertama (*optimistic lock*) agar tidak terjadi tumpang tindih penanganan.
- **Akses Kartu Medis Darurat (ICE Card 2 Jam):** Relawan yang mengunci insiden mendapatkan token darurat sementara untuk membaca golongan darah, alergi, dan riwayat penyakit korban.
- **Offline SMS Fallback:** Mengirim SMS darurat otomatis jika koneksi internet terputus.

### 2. Pemantauan Kesejahteraan (Daily Check-in & Dead-Man Switch)
- **Kartu Check-in Satu Sentuhan:** Pertanyaan kondisi pagi dengan pilihan emotikon ramah (😊 Baik, 😐 Kurang Enak, 🤒 Butuh Bantuan) bertarget sentuh lansia ($\ge 72\text{ dp}$).
- **Eskalasi Otomatis Dead-Man Switch:**
  - 90 menit tanpa respons: Pengingat kedua.
  - 120 menit tanpa respons: Notifikasi panggilan darurat ke ponsel keluarga (Guardian).
  - 150 menit tanpa respons: Peringatan ke Pengurus RT (Civic Admin) untuk pemeriksaan fisik ke rumah korban.
- **Jadwal & Kepatuhan Minum Obat:** Pengingat audio-visual harian yang tersinkronisasi langsung dengan dasbor keluarga.

### 3. Papan Tugas Bantuan Mikro (Mutual-Aid Task Board)
- **Permohonan Bantuan Antartetangga:** Kategori ambil resep obat, belanja kebutuhan pokok, pendampingan posyandu/mobilitas.
- **Sistem Poin Sosial:** Apresiasi non-finansial bagi relawan (+10 poin per tugas mikro selesai, +50 poin per respons darurat SOS).
- **Papan Peringkat Relawan RT (Leaderboard):** Menampilkan warga relawan paling aktif dan berdedikasi di lingkungan RT.

### 4. Struktur Komunitas & Verifikasi RT (Role-Based Access)
- **Care-Receiver:** Mode lansia (*simplified UI*), tipografi besar ($\ge 20\text{ sp}$), kontras tinggi.
- **Community Responder:** Radar insiden dan tugas tetangga radius 800m, toggle status siaga/istirahat.
- **Primary Guardian:** Dasbor pemantauan real-time kondisi orang tua dan pengelolaan kartu ICE.
- **Civic Administrator (Admin RT):** Validasi domisili warga baru dengan kode undangan RT unik.

---

## 🛠️ Tech Stack & Arsitektur

- **Framework:** Flutter 3.27+ (Dart 3)
- **Arsitektur:** Feature-First Clean Architecture
- **State Management:** `package:provider` (^6.1.2) dengan `ChangeNotifier` & `MultiProvider`
- **Routing:** `go_router` (^14.8.1)
- **Backend & Database:** Supabase (PostgreSQL + PostGIS Geospasial)
- **Keamanan:** Row Level Security (RLS) & enkripsi AES `pgcrypto`
- **Aksesibilitas:** Standar WCAG AA, target sentuh minimum $\ge 64\text{ dp}$ (lansia $\ge 72\text{ dp}$), ukuran font $\ge 18$–$20\text{ sp}$.

---

## 📂 Struktur Folder Proyek

```
lib/
├── core/
│   ├── constants/        # Warna kontras tinggi, dimensi sentuh lansia, konstanta app
│   ├── router/           # Konfigurasi modular GoRouter
│   ├── services/         # Client Supabase, Geolokasi, Feedback Audio/Haptic, SMS Fallback
│   ├── state/            # AuthProvider global
│   └── theme/            # Tema standar gelap & tema khusus lansia (Senior Theme)
├── features/
│   ├── admin/            # Validasi warga RT & riwayat insiden
│   ├── auth/             # OTP Telepon, pemilihan peran, verifikasi kode RT
│   ├── emergency/        # SOS countdown, first-responder lock, incident detail
│   ├── microtask/        # Papan tugas mikro, form permohonan, leaderboard poin sosial
│   ├── profile/          # Pengaturan profil & formulir/viewer terenkripsi ICE Card
│   └── wellness/         # Check-in harian, Dead-Man switch, jadwal obat
├── shared/
│   └── components/       # AccessibleButton, Typography, Card standar aksesibilitas
└── main.dart             # Inisialisasi lingkungan (.env), Supabase, & MultiProvider
```

---

## 🚀 Panduan Memulai (Quick Start)

### 1. Prasyarat
- [Flutter SDK](https://flutter.dev) (versi $\ge 3.27.0$)
- Akun [Supabase](https://supabase.com) (tersedia paket gratis)

### 2. Instalasi Dependensi
```bash
git clone https://github.com/gilangggra/Sigap.git
cd Sigap
flutter pub get
```

### 3. Konfigurasi Lingkungan (`.env`)
Buat file `.env` di direktori root aplikasi (sejajar dengan `.env.example`):
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-publishable-or-anon-key
DEFAULT_RT_AREA_ID=00000000-0000-0000-0000-000000000000
EMERGENCY_SMS_GATEWAY=+628110000000
```

### 4. Setup Database Supabase
Buka **SQL Editor** pada dashboard Supabase Anda, lalu jalankan seluruh skrip SQL dari file:
```
docs/DATABASE_SCHEMA.sql
```

### 5. Menjalankan Pengujian (Testing)
```bash
flutter test
flutter analyze
```

### 6. Menjalankan Aplikasi
```bash
flutter run
```

