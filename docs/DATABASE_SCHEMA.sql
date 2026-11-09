-- ============================================================
-- SIGAP MOBILE — DATABASE SCHEMA
-- PostgreSQL + PostGIS + Supabase
-- Feature-First Organization
-- ============================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- ENUM TYPES
-- ============================================================

CREATE TYPE user_role AS ENUM (
    'care_receiver',
    'guardian',
    'responder',
    'civic_admin'
);

CREATE TYPE incident_status AS ENUM (
    'dispatched',    -- SOS dikirim, belum ada yang merespons
    'responding',    -- Relawan sudah lock (saya meluncur)
    'on_site',       -- Relawan di lokasi
    'resolved',      -- Insiden selesai
    'cancelled'      -- Dibatalkan saat countdown
);

CREATE TYPE task_status AS ENUM (
    'open',
    'accepted',
    'in_progress',
    'completed',
    'cancelled'
);

CREATE TYPE task_category AS ENUM (
    'ambil_resep',
    'belanja_logistik',
    'pendampingan_mobilitas',
    'lainnya'
);

CREATE TYPE checkin_status AS ENUM (
    'baik',
    'kurang_enak',
    'butuh_bantuan'
);

CREATE TYPE escalation_status AS ENUM (
    'pending',         -- Belum ada respons check-in
    'reminder_sent',   -- Reminder kedua sudah dikirim (90 menit)
    'guardian_alerted',-- Guardian sudah dinotifikasi (120 menit)
    'admin_alerted',   -- Civic Admin sudah dinotifikasi (150 menit)
    'resolved'         -- Care-Receiver akhirnya merespons
);

-- ============================================================
-- FEATURE 4: AUTH & COMMUNITY STRUCTURE
-- ============================================================

-- Wilayah RT/RW
CREATE TABLE rt_areas (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rt_number       VARCHAR(10) NOT NULL,
    rw_number       VARCHAR(10) NOT NULL,
    kelurahan       VARCHAR(100) NOT NULL,
    kecamatan       VARCHAR(100) NOT NULL,
    kota            VARCHAR(100) NOT NULL,
    -- Titik pusat RT untuk referensi geospasial
    center_point    GEOGRAPHY(POINT, 4326),
    -- Kode unik untuk onboarding warga
    invite_code     VARCHAR(12) UNIQUE NOT NULL,
    invite_code_expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Profil pengguna (extend auth.users Supabase)
CREATE TABLE profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name       VARCHAR(100) NOT NULL,
    phone_number    VARCHAR(20) UNIQUE NOT NULL,
    role            user_role NOT NULL,
    rt_area_id      UUID REFERENCES rt_areas(id),
    -- Verifikasi oleh Civic Admin
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at     TIMESTAMPTZ,
    verified_by     UUID REFERENCES profiles(id),
    -- Lokasi terakhir (hanya disimpan saat relawan online, tidak permanen)
    last_known_location GEOGRAPHY(POINT, 4326),
    last_location_at    TIMESTAMPTZ,
    -- Simplified mode untuk Care-Receiver
    simplified_mode BOOLEAN NOT NULL DEFAULT FALSE,
    -- Push token untuk notifikasi
    fcm_token       TEXT,
    apns_token      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Relasi Guardian ↔ Care-Receiver (many-to-many)
CREATE TABLE guardian_relationships (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guardian_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    care_receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (guardian_id, care_receiver_id)
);

-- ============================================================
-- FEATURE 5: PROFILE & ICE CARD
-- ============================================================

-- ICE Card (Emergency Information Card) — data medis terenkripsi
CREATE TABLE ice_cards (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    care_receiver_id    UUID UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    -- Kolom dienkripsi dengan pgcrypto
    blood_type_enc      BYTEA,           -- pgp_sym_encrypt(blood_type, key)
    allergies_enc       BYTEA,           -- pgp_sym_encrypt(allergies_json, key)
    chronic_conditions_enc BYTEA,        -- pgp_sym_encrypt(conditions_json, key)
    -- Kontak dokter (tidak dienkripsi, perlu aksesibilitas cepat)
    doctor_name         VARCHAR(100),
    doctor_phone        VARCHAR(20),
    doctor_notes        TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- FEATURE 1: EMERGENCY DISPATCH
-- ============================================================

-- Insiden darurat
CREATE TABLE incidents (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    care_receiver_id UUID NOT NULL REFERENCES profiles(id),
    -- Lokasi saat SOS dipicu
    location        GEOGRAPHY(POINT, 4326) NOT NULL,
    location_address TEXT,              -- Reverse geocode (opsional)
    gps_approximate BOOLEAN NOT NULL DEFAULT FALSE,
    -- Status & respons
    status          incident_status NOT NULL DEFAULT 'dispatched',
    responder_id    UUID REFERENCES profiles(id),
    responder_locked_at TIMESTAMPTZ,
    -- Resolusi
    resolved_at     TIMESTAMPTZ,
    resolved_by     UUID REFERENCES profiles(id),
    resolution_notes TEXT,
    -- Fallback
    sms_sent        BOOLEAN NOT NULL DEFAULT FALSE,
    sms_sent_at     TIMESTAMPTZ,
    -- Metadata
    rt_area_id      UUID REFERENCES rt_areas(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index geospasial untuk query ST_DWithin
CREATE INDEX idx_incidents_location ON incidents USING GIST (location);
CREATE INDEX idx_incidents_status ON incidents (status);
CREATE INDEX idx_incidents_created_at ON incidents (created_at DESC);

-- Token akses darurat untuk ICE Card
CREATE TABLE emergency_tokens (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id     UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    responder_id    UUID NOT NULL REFERENCES profiles(id),
    token           VARCHAR(64) UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
    -- Berlaku 2 jam sejak digenerate
    expires_at      TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '2 hours'),
    revoked_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_emergency_tokens_responder ON emergency_tokens (responder_id, expires_at);

-- Responder yang dihubungi per insiden (5 terdekat)
CREATE TABLE incident_notifications (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id     UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    responder_id    UUID NOT NULL REFERENCES profiles(id),
    distance_meters NUMERIC(8,2),
    notified_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    seen_at         TIMESTAMPTZ,
    UNIQUE (incident_id, responder_id)
);

-- ============================================================
-- FEATURE 2: WELLNESS CHECK-IN
-- ============================================================

-- Konfigurasi jadwal check-in per Care-Receiver
CREATE TABLE wellness_schedules (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    care_receiver_id    UUID UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    checkin_time        TIME NOT NULL DEFAULT '07:30:00',
    -- Batas waktu sebelum eskalasi
    reminder_after_min  INT NOT NULL DEFAULT 90,
    escalate_after_min  INT NOT NULL DEFAULT 120,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Log check-in harian
CREATE TABLE wellness_logs (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    care_receiver_id    UUID NOT NULL REFERENCES profiles(id),
    check_date          DATE NOT NULL DEFAULT CURRENT_DATE,
    status              checkin_status,
    escalation_status   escalation_status NOT NULL DEFAULT 'pending',
    -- Waktu respons
    responded_at        TIMESTAMPTZ,
    -- Waktu pengiriman notifikasi eskalasi
    reminder_sent_at    TIMESTAMPTZ,
    guardian_alerted_at TIMESTAMPTZ,
    admin_alerted_at    TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (care_receiver_id, check_date)
);

CREATE INDEX idx_wellness_logs_date ON wellness_logs (check_date, escalation_status);

-- Jadwal obat
CREATE TABLE medication_schedules (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    care_receiver_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_by          UUID NOT NULL REFERENCES profiles(id), -- Guardian yang buat
    medication_name     VARCHAR(100) NOT NULL,
    dosage              VARCHAR(50),
    -- Multiple waktu per hari (array)
    reminder_times      TIME[] NOT NULL,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Log konsumsi obat
CREATE TABLE medication_logs (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id         UUID NOT NULL REFERENCES medication_schedules(id) ON DELETE CASCADE,
    care_receiver_id    UUID NOT NULL REFERENCES profiles(id),
    scheduled_time      TIMESTAMPTZ NOT NULL,
    taken_at            TIMESTAMPTZ,     -- NULL = belum diminum
    skipped             BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_medication_logs_receiver ON medication_logs (care_receiver_id, scheduled_time DESC);

-- ============================================================
-- FEATURE 3: MICRO-TASK BOARD
-- ============================================================

-- Tiket bantuan mikro
CREATE TABLE tasks (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_by      UUID NOT NULL REFERENCES profiles(id),  -- Guardian atau Care-Receiver
    care_receiver_id UUID NOT NULL REFERENCES profiles(id), -- Penerima bantuan
    category        task_category NOT NULL,
    description     VARCHAR(200) NOT NULL,
    -- Lokasi tujuan tugas
    destination_location    GEOGRAPHY(POINT, 4326),
    destination_address     TEXT,
    -- Waktu dibutuhkan
    needed_before   TIMESTAMPTZ,
    -- Status & respons
    status          task_status NOT NULL DEFAULT 'open',
    responder_id    UUID REFERENCES profiles(id),
    accepted_at     TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    completion_notes TEXT,
    -- Lokasi origin (RT Care-Receiver) untuk geofencing
    rt_area_id      UUID REFERENCES rt_areas(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tasks_location ON tasks USING GIST (destination_location);
CREATE INDEX idx_tasks_status ON tasks (status, rt_area_id);

-- Poin sosial relawan
CREATE TABLE social_credits (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    responder_id    UUID NOT NULL REFERENCES profiles(id),
    -- Source event
    source_type     VARCHAR(20) NOT NULL CHECK (source_type IN ('task', 'emergency')),
    source_id       UUID NOT NULL,       -- task.id atau incident.id
    points          INT NOT NULL,
    description     VARCHAR(100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_social_credits_responder ON social_credits (responder_id, created_at DESC);

-- ============================================================
-- AUDIT LOG (GLOBAL)
-- ============================================================

CREATE TABLE audit_logs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id        UUID REFERENCES profiles(id),
    action          VARCHAR(100) NOT NULL,  -- e.g. 'ice_card.accessed', 'incident.resolved'
    target_type     VARCHAR(50),
    target_id       UUID,
    metadata        JSONB,
    ip_address      INET,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_actor ON audit_logs (actor_id, created_at DESC);
CREATE INDEX idx_audit_logs_target ON audit_logs (target_type, target_id);

-- ============================================================
-- STORED FUNCTIONS (RPC via Supabase)
-- ============================================================

-- F1: Dispatch Emergency — cari 5 responder terdekat
CREATE OR REPLACE FUNCTION dispatch_emergency(
    p_care_receiver_id  UUID,
    p_lat               DOUBLE PRECISION,
    p_lng               DOUBLE PRECISION,
    p_gps_approximate   BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    incident_id UUID,
    nearby_responders JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_incident_id   UUID;
    v_location      GEOGRAPHY;
    v_radius        INT := 500;
    v_responders    JSONB;
    v_count         INT;
BEGIN
    v_location := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::GEOGRAPHY;

    -- Insert insiden
    INSERT INTO incidents (care_receiver_id, location, gps_approximate)
    VALUES (p_care_receiver_id, v_location, p_gps_approximate)
    RETURNING id INTO v_incident_id;

    -- Cari responder dalam radius 500m
    SELECT COUNT(*) INTO v_count
    FROM profiles p
    WHERE p.role = 'responder'
    AND p.is_verified = TRUE
    AND p.last_known_location IS NOT NULL
    AND ST_DWithin(p.last_known_location, v_location, v_radius);

    -- Expand ke 800m jika responder < 3
    IF v_count < 3 THEN
        v_radius := 800;
    END IF;

    -- Ambil 5 responder terdekat + catat ke incident_notifications
    WITH nearby AS (
        SELECT
            p.id,
            p.full_name,
            p.fcm_token,
            p.apns_token,
            ST_Distance(p.last_known_location, v_location) AS distance_meters
        FROM profiles p
        WHERE p.role = 'responder'
        AND p.is_verified = TRUE
        AND p.last_known_location IS NOT NULL
        AND ST_DWithin(p.last_known_location, v_location, v_radius)
        ORDER BY distance_meters ASC
        LIMIT 5
    )
    INSERT INTO incident_notifications (incident_id, responder_id, distance_meters)
    SELECT v_incident_id, id, distance_meters FROM nearby;

    -- Return data untuk Edge Function (kirim push notif)
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', p.id,
            'fcm_token', p.fcm_token,
            'distance_meters', n.distance_meters
        )
    ) INTO v_responders
    FROM incident_notifications n
    JOIN profiles p ON p.id = n.responder_id
    WHERE n.incident_id = v_incident_id;

    RETURN QUERY SELECT v_incident_id, v_responders;
END;
$$;

-- F2: Lock Incident oleh Responder (atomic)
CREATE OR REPLACE FUNCTION lock_incident(
    p_incident_id   UUID,
    p_responder_id  UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_updated INT;
BEGIN
    UPDATE incidents
    SET
        responder_id = p_responder_id,
        responder_locked_at = NOW(),
        status = 'responding'
    WHERE id = p_incident_id
    AND responder_id IS NULL
    AND status = 'dispatched';

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    IF v_updated = 1 THEN
        -- Generate emergency token untuk akses ICE Card
        INSERT INTO emergency_tokens (incident_id, responder_id)
        VALUES (p_incident_id, p_responder_id);

        -- Catat audit log
        INSERT INTO audit_logs (actor_id, action, target_type, target_id)
        VALUES (p_responder_id, 'incident.locked', 'incidents', p_incident_id);

        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$;

-- F3: Validasi Emergency Token untuk akses ICE Card
CREATE OR REPLACE FUNCTION validate_emergency_token(
    p_token         VARCHAR(64),
    p_responder_id  UUID
)
RETURNS UUID   -- returns care_receiver_id jika valid, NULL jika tidak
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_care_receiver_id UUID;
BEGIN
    SELECT i.care_receiver_id INTO v_care_receiver_id
    FROM emergency_tokens et
    JOIN incidents i ON i.id = et.incident_id
    WHERE et.token = p_token
    AND et.responder_id = p_responder_id
    AND et.expires_at > NOW()
    AND et.revoked_at IS NULL
    AND i.status IN ('responding', 'on_site');

    IF v_care_receiver_id IS NOT NULL THEN
        INSERT INTO audit_logs (actor_id, action, target_type, target_id)
        VALUES (p_responder_id, 'ice_card.accessed', 'profiles', v_care_receiver_id);
    END IF;

    RETURN v_care_receiver_id;
END;
$$;

-- F4: Get nearby tasks untuk Responder (geospasial)
CREATE OR REPLACE FUNCTION get_nearby_tasks(
    p_responder_id  UUID,
    p_radius_meters INT DEFAULT 800
)
RETURNS TABLE (
    task_id         UUID,
    category        task_category,
    description     VARCHAR,
    destination_address TEXT,
    needed_before   TIMESTAMPTZ,
    distance_meters NUMERIC,
    care_receiver_name VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_responder_location GEOGRAPHY;
BEGIN
    SELECT last_known_location INTO v_responder_location
    FROM profiles WHERE id = p_responder_id;

    IF v_responder_location IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        t.id,
        t.category,
        t.description,
        t.destination_address,
        t.needed_before,
        ST_Distance(t.destination_location, v_responder_location)::NUMERIC(8,2),
        p.full_name
    FROM tasks t
    JOIN profiles p ON p.id = t.care_receiver_id
    WHERE t.status = 'open'
    AND t.destination_location IS NOT NULL
    AND ST_DWithin(t.destination_location, v_responder_location, p_radius_meters)
    ORDER BY ST_Distance(t.destination_location, v_responder_location) ASC;
END;
$$;

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ice_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellness_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- profiles: user hanya bisa lihat profil di RT yang sama
CREATE POLICY "profiles_same_rt" ON profiles
    FOR SELECT USING (
        rt_area_id = (SELECT rt_area_id FROM profiles WHERE id = auth.uid())
    );

CREATE POLICY "profiles_own_update" ON profiles
    FOR UPDATE USING (id = auth.uid());

-- ice_cards: hanya care_receiver sendiri atau guardian terdaftar
-- (akses responder via emergency token ditangani di function, bukan RLS langsung)
CREATE POLICY "ice_cards_owner_read" ON ice_cards
    FOR SELECT USING (
        care_receiver_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM guardian_relationships
            WHERE guardian_id = auth.uid()
            AND care_receiver_id = ice_cards.care_receiver_id
        )
    );

CREATE POLICY "ice_cards_owner_write" ON ice_cards
    FOR ALL USING (care_receiver_id = auth.uid());

-- incidents: visible ke pihak terkait dan admin RT yang sama
CREATE POLICY "incidents_visible" ON incidents
    FOR SELECT USING (
        care_receiver_id = auth.uid()
        OR responder_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM guardian_relationships
            WHERE guardian_id = auth.uid()
            AND care_receiver_id = incidents.care_receiver_id
        )
        OR EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'civic_admin'
            AND rt_area_id = incidents.rt_area_id
        )
    );

-- tasks: visible ke semua di RT yang sama
CREATE POLICY "tasks_rt_visible" ON tasks
    FOR SELECT USING (
        rt_area_id = (SELECT rt_area_id FROM profiles WHERE id = auth.uid())
    );

CREATE POLICY "tasks_creator_modify" ON tasks
    FOR ALL USING (created_by = auth.uid());

-- wellness_logs: hanya care_receiver dan guardian
CREATE POLICY "wellness_logs_visible" ON wellness_logs
    FOR SELECT USING (
        care_receiver_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM guardian_relationships
            WHERE guardian_id = auth.uid()
            AND care_receiver_id = wellness_logs.care_receiver_id
        )
    );

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_incidents_updated_at
    BEFORE UPDATE ON incidents
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Award social credit saat insiden resolved
CREATE OR REPLACE FUNCTION award_emergency_credit()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'resolved' AND OLD.status != 'resolved' AND NEW.responder_id IS NOT NULL THEN
        INSERT INTO social_credits (responder_id, source_type, source_id, points, description)
        VALUES (NEW.responder_id, 'emergency', NEW.id, 50, 'Respons darurat berhasil diselesaikan');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_award_emergency_credit
    AFTER UPDATE ON incidents
    FOR EACH ROW EXECUTE FUNCTION award_emergency_credit();

-- Award social credit saat task completed
CREATE OR REPLACE FUNCTION award_task_credit()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.responder_id IS NOT NULL THEN
        INSERT INTO social_credits (responder_id, source_type, source_id, points, description)
        VALUES (NEW.responder_id, 'task', NEW.id, 10, 'Tugas mikro berhasil diselesaikan');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_award_task_credit
    AFTER UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION award_task_credit();