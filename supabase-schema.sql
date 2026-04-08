-- =============================================
-- SLIP GAJI BPKPD SRAGEN - SUPABASE SCHEMA
-- Jalankan di: Supabase Dashboard → SQL Editor
-- =============================================

-- Tabel pegawai (ASN dan P3K)
CREATE TABLE IF NOT EXISTS pegawai (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nip         TEXT UNIQUE NOT NULL,
  nama        TEXT NOT NULL,
  no_rek      TEXT DEFAULT '',
  pin         TEXT NOT NULL,         -- PIN aktif
  pin_default TEXT NOT NULL,         -- PIN default (untuk reset)
  tipe        TEXT DEFAULT 'ASN' CHECK (tipe IN ('ASN', 'P3K')),
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Tabel slip gaji ASN
CREATE TABLE IF NOT EXISTS slip_gaji (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nip               TEXT NOT NULL,
  nama              TEXT DEFAULT '',
  no_rek            TEXT DEFAULT '',
  bulan             TEXT NOT NULL,
  gaji              BIGINT DEFAULT 0,
  pot_bank_jateng   BIGINT DEFAULT 0,
  dplk              BIGINT DEFAULT 0,
  pot_bppkad        BIGINT DEFAULT 0,
  korpri            BIGINT DEFAULT 0,
  dh_wanita         BIGINT DEFAULT 0,
  sosial_bppkad     BIGINT DEFAULT 0,
  beras             BIGINT DEFAULT 0,
  zakat             BIGINT DEFAULT 0,
  besukan_tu        BIGINT DEFAULT 0,
  pmi               BIGINT DEFAULT 0,
  kop_sedya_rhy     BIGINT DEFAULT 0,
  kop_perdagangan   BIGINT DEFAULT 0,
  bkk_gesi          BIGINT DEFAULT 0,
  joko_tingkir      BIGINT DEFAULT 0,
  bri               BIGINT DEFAULT 0,
  bkk_karangmalang  BIGINT DEFAULT 0,
  bjb               BIGINT DEFAULT 0,
  penerimaan_bersih BIGINT DEFAULT 0,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(nip, bulan)
);

-- Tabel slip TPP (ASN dan P3K)
CREATE TABLE IF NOT EXISTS slip_tpp (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nip               TEXT NOT NULL,
  nama              TEXT DEFAULT '',
  no_rek            TEXT DEFAULT '',
  bulan             TEXT NOT NULL,
  tipe              TEXT DEFAULT 'ASN' CHECK (tipe IN ('ASN', 'P3K')),
  tpp_kotor         BIGINT DEFAULT 0,
  pot_tpp           BIGINT DEFAULT 0,
  penerimaan        BIGINT DEFAULT 0,
  pot_koperasi      BIGINT DEFAULT 0,
  matra             BIGINT DEFAULT 0,
  zakat             BIGINT DEFAULT 0,
  infaq             BIGINT DEFAULT 0,
  bpjs              BIGINT DEFAULT 0,
  penerimaan_bersih BIGINT DEFAULT 0,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(nip, bulan, tipe)
);

-- Tabel konfigurasi admin
CREATE TABLE IF NOT EXISTS admin_config (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

INSERT INTO admin_config (key, value) VALUES
  ('admin_password', 'Admin@BPKPD2026')
ON CONFLICT (key) DO NOTHING;

-- Disable RLS (aplikasi internal/intranet)
ALTER TABLE pegawai     DISABLE ROW LEVEL SECURITY;
ALTER TABLE slip_gaji   DISABLE ROW LEVEL SECURITY;
ALTER TABLE slip_tpp    DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_config DISABLE ROW LEVEL SECURITY;

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_slip_gaji_nip   ON slip_gaji(nip);
CREATE INDEX IF NOT EXISTS idx_slip_tpp_nip    ON slip_tpp(nip);
CREATE INDEX IF NOT EXISTS idx_pegawai_nip     ON pegawai(nip);
CREATE INDEX IF NOT EXISTS idx_slip_tpp_tipe   ON slip_tpp(tipe);

-- =============================================
-- RPC: Upsert pegawai BATCH (untuk import massal)
-- Menerima array JSON, proses 1 trip ke database
-- =============================================
CREATE OR REPLACE FUNCTION upsert_pegawai_batch(
  p_records JSONB
) RETURNS VOID AS $$
DECLARE
  rec JSONB;
BEGIN
  FOR rec IN SELECT * FROM jsonb_array_elements(p_records)
  LOOP
    INSERT INTO pegawai (nip, nama, no_rek, pin, pin_default, tipe)
    VALUES (
      rec->>'nip', rec->>'nama', rec->>'no_rek',
      rec->>'pin', rec->>'pin', rec->>'tipe'
    )
    ON CONFLICT (nip) DO UPDATE SET
      nama        = EXCLUDED.nama,
      no_rek      = EXCLUDED.no_rek,
      tipe        = EXCLUDED.tipe,
      pin_default = EXCLUDED.pin_default,
      pin         = CASE
                      WHEN pegawai.pin = pegawai.pin_default THEN EXCLUDED.pin_default
                      ELSE pegawai.pin
                    END,
      updated_at  = NOW();
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- RPC: Upsert pegawai tunggal (untuk operasi individual)
CREATE OR REPLACE FUNCTION upsert_pegawai(
  p_nip TEXT, p_nama TEXT, p_no_rek TEXT, p_pin TEXT, p_tipe TEXT
) RETURNS VOID AS $$
BEGIN
  PERFORM upsert_pegawai_batch(jsonb_build_array(
    jsonb_build_object('nip',p_nip,'nama',p_nama,'no_rek',p_no_rek,'pin',p_pin,'tipe',p_tipe)
  ));
END;
$$ LANGUAGE plpgsql;
