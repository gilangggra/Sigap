# ARCHITECTURE — SIGAP Mobile
**Civic Mutual-Aid & Caregiver Network**

---

## 1. Tech Stack

| Layer | Teknologi | Alasan |
|---|---|---|
| Mobile Framework | React Native + Expo SDK 51 | Cross-platform, familiar dengan React ecosystem |
| Navigation | React Navigation v6 | Stack + Bottom Tab per role |
| State Management | Zustand | Lightweight, no boilerplate |
| Server State / Cache | TanStack Query (React Query) | Cache, background refetch, optimistic updates |
| Styling | NativeWind (Tailwind RN) | Konsisten dengan paradigma utility-first |
| Backend | Supabase | Auth, Realtime, PostGIS, RLS built-in |
| Database | PostgreSQL + PostGIS | Geospatial query untuk radius relawan |
| Push Notification | Expo Notifications + FCM + APNs | Critical Alert bypass DND |
| SMS Fallback | Twilio / Vonage SMS Gateway | Fallback tanpa internet |
| Validasi | Zod | Runtime type-safety untuk form & API response |

---

## 2. Folder Structure (Feature-First)

```
sigap-mobile/
├── app/                          # Expo Router entry (opsional jika pakai file-based routing)
├── src/
│   ├── features/
│   │   ├── emergency/            # FEATURE 1: Emergency Dispatch
│   │   │   ├── components/
│   │   │   │   ├── SosButton.tsx
│   │   │   │   ├── CountdownOverlay.tsx
│   │   │   │   ├── ResponderCard.tsx
│   │   │   │   └── IceCardViewer.tsx
│   │   │   ├── hooks/
│   │   │   │   ├── useEmergencyDispatch.ts
│   │   │   │   ├── useResponderLock.ts
│   │   │   │   └── useEmergencyChannel.ts   # Supabase Realtime
│   │   │   ├── screens/
│   │   │   │   ├── SosScreen.tsx
│   │   │   │   └── IncidentDetailScreen.tsx
│   │   │   ├── services/
│   │   │   │   ├── emergencyService.ts      # Dispatch logic
│   │   │   │   └── smsFallbackService.ts
│   │   │   ├── store/
│   │   │   │   └── emergencyStore.ts        # Zustand slice
│   │   │   └── types/
│   │   │       └── emergency.types.ts
│   │   │
│   │   ├── wellness/             # FEATURE 2: Wellness Check-in
│   │   │   ├── components/
│   │   │   │   ├── CheckinCard.tsx
│   │   │   │   ├── MedicationReminder.tsx
│   │   │   │   └── EscalationStatus.tsx
│   │   │   ├── hooks/
│   │   │   │   ├── useWellnessCheckin.ts
│   │   │   │   └── useMedicationSchedule.ts
│   │   │   ├── screens/
│   │   │   │   ├── WellnessHomeScreen.tsx
│   │   │   │   └── MedicationLogScreen.tsx
│   │   │   ├── services/
│   │   │   │   └── wellnessService.ts
│   │   │   └── types/
│   │   │       └── wellness.types.ts
│   │   │
│   │   ├── microtask/            # FEATURE 3: Micro-Task Board
│   │   │   ├── components/
│   │   │   │   ├── TaskCard.tsx
│   │   │   │   ├── TaskForm.tsx
│   │   │   │   └── SocialCreditBadge.tsx
│   │   │   ├── hooks/
│   │   │   │   ├── useNearbyTasks.ts
│   │   │   │   └── useTaskAcceptance.ts
│   │   │   ├── screens/
│   │   │   │   ├── TaskBoardScreen.tsx
│   │   │   │   └── CreateTaskScreen.tsx
│   │   │   └── types/
│   │   │       └── microtask.types.ts
│   │   │
│   │   ├── auth/                 # FEATURE 4: Auth & Verification
│   │   │   ├── components/
│   │   │   │   ├── OtpInput.tsx
│   │   │   │   └── RoleSelector.tsx
│   │   │   ├── screens/
│   │   │   │   ├── PhoneInputScreen.tsx
│   │   │   │   ├── OtpVerifyScreen.tsx
│   │   │   │   ├── RoleSelectScreen.tsx
│   │   │   │   └── RtCodeInputScreen.tsx
│   │   │   ├── hooks/
│   │   │   │   └── useAuth.ts
│   │   │   └── types/
│   │   │       └── auth.types.ts
│   │   │
│   │   ├── profile/              # FEATURE 5: Profile & ICE Card
│   │   │   ├── components/
│   │   │   │   └── IceCardForm.tsx
│   │   │   ├── screens/
│   │   │   │   ├── ProfileScreen.tsx
│   │   │   │   └── IceCardEditScreen.tsx
│   │   │   └── types/
│   │   │       └── profile.types.ts
│   │   │
│   │   └── admin/                # FEATURE 6: Civic Admin Dashboard
│   │       ├── components/
│   │       │   ├── PendingResidentList.tsx
│   │       │   └── IncidentHistoryTable.tsx
│   │       ├── screens/
│   │       │   ├── AdminDashboardScreen.tsx
│   │       │   └── ResidentValidationScreen.tsx
│   │       └── types/
│   │           └── admin.types.ts
│   │
│   ├── shared/
│   │   ├── components/
│   │   │   ├── Button.tsx            # Reusable button (ada variant simplified)
│   │   │   ├── Typography.tsx
│   │   │   ├── Avatar.tsx
│   │   │   └── ErrorBoundary.tsx
│   │   ├── hooks/
│   │   │   ├── useGeolocation.ts     # Wrapper expo-location
│   │   │   ├── useNetworkStatus.ts   # NetInfo wrapper
│   │   │   └── useRole.ts            # Baca role dari auth store
│   │   ├── lib/
│   │   │   ├── supabaseClient.ts     # Singleton Supabase client
│   │   │   ├── fcmService.ts         # FCM + Critical Alert setup
│   │   │   ├── smsGateway.ts         # Twilio/Vonage wrapper
│   │   │   └── logger.ts             # Production-safe logger
│   │   ├── types/
│   │   │   ├── supabase.types.ts     # Generated dari Supabase CLI
│   │   │   └── global.types.ts
│   │   └── utils/
│   │       ├── geoUtils.ts           # Hitung jarak, format koordinat
│   │       ├── tokenUtils.ts         # Emergency token helpers
│   │       └── formatUtils.ts        # Tanggal, nama, dll
│   │
│   ├── navigation/
│   │   ├── RootNavigator.tsx         # Auth check → route ke role navigator
│   │   ├── CareReceiverNavigator.tsx # Simplified tab navigator
│   │   ├── ResponderNavigator.tsx
│   │   ├── GuardianNavigator.tsx
│   │   └── AdminNavigator.tsx
│   │
│   └── store/
│       ├── authStore.ts              # User session, role, RT info
│       └── appStore.ts               # Global app state (theme, language)
│
├── .cursorrules
├── PRD.md
├── ARCHITECTURE.md
├── DATABASE_SCHEMA.sql
└── ENV_EXAMPLE.env
```

---

## 3. Data Flow Utama

### 3.1 Emergency Dispatch Flow

```
Care-Receiver
    │
    ├── [Tap SOS Button]
    │       │
    │       ▼
    │   CountdownOverlay (8 detik)
    │       │
    │       ├── [Tap Batalkan] → selesai
    │       │
    │       └── [Timeout] → useEmergencyDispatch.trigger()
    │               │
    │               ├── Ambil GPS koordinat (expo-location)
    │               │       └── [Gagal] → pakai last known location
    │               │
    │               ├── Cek koneksi internet (useNetworkStatus)
    │               │       └── [Offline] → smsFallbackService.send()
    │               │
    │               └── [Online] → supabase.rpc('dispatch_emergency', { lat, lng })
    │                       │
    │                       ▼
    │               Server: PostGIS ST_DWithin query
    │               Ambil 5 responder terdekat (radius 500m → 800m jika < 3)
    │               Insert ke tabel `incidents`
    │               Broadcast via Supabase Realtime channel: emergency
    │                       │
    │               ┌───────┴────────────────────┐
    │               ▼                            ▼
    │       Push Notification              Guardian Push
    │       ke 5 Responder                 Notification
    │       (FCM Critical Alert)
    │
Responder
    │
    ├── [Terima Notifikasi → Buka App]
    │
    ├── [Tap "Saya Meluncur"] → useResponderLock.lock(incidentId)
    │       │
    │       └── Supabase UPDATE incidents SET responder_id = X WHERE responder_id IS NULL
    │               │
    │               ├── [Success] → Responder dapat peta rute + akses ICE Card token
    │               └── [Race condition / sudah dilock] → tampilkan "Sudah Ditangani"
    │
    └── [Di Lokasi → Tap "Lihat Data Medis"] → validasi emergency_token (server)
            │
            └── [Selesai → Tap "Insiden Selesai"] → Guardian/Admin resolve
```

### 3.2 Dead-Man Switch Flow

```
Scheduled Job (pg_cron / Supabase Edge Function)
    │
    └── Setiap pagi 07.30 WIB
            │
            └── Kirim push notification check-in ke semua Care-Receiver aktif
                    │
                    ├── [Care-Receiver tap dalam 90 menit] → update wellness_logs → selesai
                    │
                    └── [Tidak ada respons setelah 90 menit]
                            │
                            └── Kirim reminder kedua
                                    │
                                    ├── [Respons] → selesai
                                    │
                                    └── [Tidak ada respons setelah 120 menit]
                                            │
                                            └── Push notification ke Guardian
                                                    │
                                                    └── [Guardian tidak respons 30 menit]
                                                            │
                                                            └── Notifikasi Civic Admin
```

### 3.3 Micro-Task Flow

```
Guardian / Care-Receiver
    │
    └── [Buat Tiket di CreateTaskScreen]
            │
            └── Supabase INSERT tasks (dengan koordinat lokasi)
                    │
                    └── Edge Function: query responder dalam radius 800m
                                │
                                └── Push notification ke responder eligible
                                        │
                                        └── Responder [Tap "Ambil Tugas"]
                                                │
                                                └── Optimistic update di client
                                                        + Supabase UPDATE tasks SET responder_id
                                                                │
                                                                └── [Selesai] → +10 poin sosial
```

---

## 4. State Management Strategy

```
Zustand Stores:
┌─────────────────────────────────────────────────────────┐
│ authStore                                               │
│   - session: Session | null                             │
│   - user: IUser | null                                  │
│   - role: TRole                                         │
│   - rtId: string                                        │
│   - isVerified: boolean                                 │
├─────────────────────────────────────────────────────────┤
│ emergencyStore                                          │
│   - activeIncident: IIncident | null                    │
│   - countdown: number                                   │
│   - dispatchStatus: 'idle'|'counting'|'sent'|'error'    │
│   - emergencyToken: string | null                       │
├─────────────────────────────────────────────────────────┤
│ appStore                                                │
│   - isSimplifiedMode: boolean                           │
│   - networkStatus: 'online'|'offline'                   │
│   - locale: 'id-ID'                                     │
└─────────────────────────────────────────────────────────┘

TanStack Query: semua data remote (tasks, wellness logs, incidents history)
Supabase Realtime: hanya channel emergency (subscribe saat role = responder)
```

---

## 5. Security Architecture

```
┌──────────────────────────────────────────┐
│  Mobile Client                           │
│  - Hanya akses via anon key              │
│  - RLS memfilter data per user/role      │
│  - Tidak ada service_role key            │
└──────────────┬───────────────────────────┘
               │ HTTPS / WSS
┌──────────────▼───────────────────────────┐
│  Supabase Edge Functions                 │
│  - dispatch_emergency (geospatial query) │
│  - generate_emergency_token              │
│  - escalate_wellness (pg_cron trigger)   │
└──────────────┬───────────────────────────┘
               │
┌──────────────▼───────────────────────────┐
│  PostgreSQL + PostGIS                    │
│  - RLS policies per tabel                │
│  - ICE Card encrypted (pgcrypto)         │
│  - Audit log tabel                       │
│  - Emergency token TTL = 2 jam           │
└──────────────────────────────────────────┘
```

---

## 6. Navigation Structure per Role

```
RootNavigator
│
├── [Belum login] → AuthStack
│   └── PhoneInput → OtpVerify → RoleSelect → RtCodeInput
│
├── [role: care_receiver] → CareReceiverTabs (Simplified Mode)
│   ├── Tab: Beranda (SosButton + CheckinCard besar)
│   ├── Tab: Obat (MedicationReminder)
│   └── Tab: Profil
│
├── [role: responder] → ResponderTabs
│   ├── Tab: Tugas (TaskBoard + Emergency Alerts)
│   ├── Tab: Peta (Nearby incidents/tasks)
│   └── Tab: Profil
│
├── [role: guardian] → GuardianTabs
│   ├── Tab: Pantau (Wellness dashboard lansia)
│   ├── Tab: Riwayat
│   └── Tab: Profil
│
└── [role: civic_admin] → AdminTabs
    ├── Tab: Validasi (Pending residents)
    ├── Tab: Insiden (History)
    └── Tab: Kelola (RT code, titik kumpul)
```