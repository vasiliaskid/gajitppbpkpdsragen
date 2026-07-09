# KONTEKS PROYEK — Slip Gaji & TPP BPKPD Kabupaten Sragen

> File ini LOKAL saja, tidak di-push ke GitHub.
> Update file ini setiap ada perubahan signifikan.

---

## 🏛️ Gambaran Umum

Aplikasi web untuk pegawai **BPKPD (Badan Pengelolaan Keuangan dan Pendapatan Daerah) Kabupaten Sragen** agar dapat melihat dan mengunduh slip gaji & TPP secara mandiri melalui browser.

- **Deploy:** Netlify (auto-deploy dari GitHub push)
- **GitHub:** https://github.com/vasiliaskid/gajitppbpkpdsragen
- **Database:** Supabase (PostgreSQL)
- **Frontend:** HTML + Vanilla JS + CSS (tanpa framework)
- **Jenis:** Static site (tidak ada backend server)

---

## 📁 Struktur File

```
slipgaji/
├── index.html            ← Portal pegawai (login, lihat slip, ganti PIN)
├── admin.html            ← Dashboard admin (import data, manajemen user)
├── supabase-config.js    ← Credentials Supabase (tidak di-push ke GitHub)
├── supabase-schema.sql   ← Schema database lengkap (jalankan di Supabase SQL Editor)
├── netlify.toml          ← Konfigurasi Netlify
├── .gitignore            ← konteks.md & file sensitif dikecualikan
├── konteks.md            ← File ini (lokal saja)
│
│   [LAMA — sudah tidak dipakai, bisa dihapus]
├── data-gaji.js          ← Data gaji hardcoded (diganti Supabase)
├── data-tpp.js           ← Data TPP hardcoded (diganti Supabase)
├── generator-admin.html  ← Generator JS lama (diganti admin.html)
└── generator-tpp.html    ← Generator TPP lama (diganti admin.html)
```

---

## 🗄️ Database Supabase

### Tabel

| Tabel | Fungsi |
|---|---|
| `pegawai` | Semua pegawai ASN & P3K (NIP, nama, PIN aktif, PIN default, tipe, no_rek) |
| `slip_gaji` | Data gaji ASN per bulan (unique: nip + bulan) |
| `slip_tpp` | Data TPP ASN & P3K per bulan (unique: nip + bulan + tipe) |
| `admin_config` | Konfigurasi: password admin (key-value) |

### RPC Functions (Stored Procedure)

| Fungsi | Kegunaan |
|---|---|
| `upsert_pegawai_batch(p_records JSONB)` | Upsert massal pegawai — **CERDAS**: tidak overwrite PIN jika pegawai sudah ganti PIN sendiri |
| `upsert_pegawai(p_nip, p_nama, ...)` | Wrapper tunggal yang memanggil batch dengan 1 item |

### Logika PIN Cerdas
- Saat import: jika `pin == pin_default` (belum diganti) → update pin sesuai Excel
- Saat import: jika `pin != pin_default` (sudah diganti) → **PIN lama dipertahankan**, hanya `pin_default` yang diupdate

---

## 👤 Fitur Portal Pegawai (`index.html`)

1. **Login** dengan NIP + PIN
2. **Tab Slip Gaji** (hanya ASN):
   - Pilih bulan dari dropdown
   - Tampilkan slip dengan rincian penerimaan & potongan
   - Download PDF slip gaji
3. **Tab Info TPP** (ASN & P3K):
   - Pilih bulan dari dropdown
   - Tampilkan slip TPP dengan rincian
   - Download PDF slip TPP
4. **Ganti PIN** (modal):
   - Tombol 🔑 PIN di topbar
   - Validasi: min 4 digit, harus angka, konfirmasi, tidak boleh sama dengan PIN default
5. **Notifikasi PIN Default:**
   - Banner kuning muncul jika pegawai masih pakai PIN default
6. **P3K Otomatis:**
   - Jika pegawai P3K (tidak ada data gaji), langsung masuk tab TPP
7. **Logout**

---

## 👨‍💼 Fitur Admin Dashboard (`admin.html`)

### Login Admin
- Password default: `Admin@BPKPD2026`
- Dicek ke tabel `admin_config` key `admin_password`
- Bisa diubah langsung di tabel Supabase

### Tab Import Data

#### Import Gaji ASN & P3K
- Paste dari Excel Gaji (Copy-paste, tanpa header) ke kotak yang sesuai
- **15 kolom (Format sama untuk ASN & P3K):** No | Nama | No Rek | Gaji Bruto | Bank Jateng | DPLK | BRI | BKK Karangmalang | BPR Djoko Tingkir | Kop Sedia Rahayu | Kop Perdagangan | Jml Pot Ekstern | Jml Pot Intern | Total Potongan | Gaji Bersih
- Data dimasukkan ke tabel `slip_gaji`
- **Batch mode:** hanya 2 query ke Supabase (bukan per-baris), selesai dalam hitungan detik

#### Import TPP ASN
- Paste dari Excel
- **16 kolom:** No | Nama | NIP | Gol/Ruang | Kelas Jabatan | TPP Kotor | Pot TPP (BPJS+PPH) | Matra | Koperasi | Zakat | Infaq | BPJS | BPJS Kes 1% AKL | Transfer Bank
- Kolom Gol/Ruang dan Kelas Jabatan di-skip saat parsing (tidak disimpan)
- Tersimpan di `slip_tpp` dengan `tipe = 'ASN'`

#### Import TPP P3K
- Sama seperti TPP ASN
- Tersimpan di `slip_tpp` dengan `tipe = 'P3K'`
- Pegawai P3K otomatis dibuat di tabel `pegawai` jika belum ada

### Tab Manajemen User
- **Tabel semua pegawai:** NIP, Nama, Tipe, No Rek, PIN Default, PIN Aktif
- **Cari** berdasarkan NIP atau Nama
- **Filter** by Tipe (ASN / P3K)
- **Aksi per pegawai:**
  - 👁 Detail — modal popup lihat semua info + PIN lengkap
  - ↩ Reset PIN — kembalikan PIN ke PIN default
  - 🗑 Hapus — hapus pegawai + SEMUA data slip-nya (permanen)

---

## ⚡ Catatan Teknis Penting

### Kenapa Batch Import?
Import lama: loop `await` per baris → 60 pegawai = **120+ query** (~30-60 detik)
Import baru: 1 RPC batch + 1 upsert = **2 query** (~2-3 detik)

### Kenapa TIDAK pakai JSON.stringify() di RPC?
Supabase JS client otomatis serialisasi JS array/object ke JSONB saat dikirim ke PostgREST.
Kalau di-`JSON.stringify()` dulu → PostgreSQL menerima string, bukan array → error `"cannot extract elements from a scalar"`.

### Format Bulan
Bebas ketik teks (contoh: "April 2026", "Maret 2026").
Data diurutkan berdasarkan `created_at`, bukan nama bulan.
Konsistensi format adalah tanggung jawab admin.

### Keamanan
- RLS Supabase **dimatikan** (aplikasi intranet)
- Supabase **Anon Key** aman di-commit karena dirancang untuk publik
- Password admin tersimpan plaintext di `admin_config` (bisa diupgrade ke hashed nantinya)
- PIN pegawai tersimpan plaintext (bisa diupgrade ke bcrypt nantinya)

---

## 🔧 Setup Awal (Untuk Deployment Baru)

1. Buat project Supabase di https://app.supabase.com
2. Jalankan `supabase-schema.sql` di SQL Editor Supabase
3. Isi `supabase-config.js` dengan Project URL + Publishable Key dari Supabase Settings → API
4. Push ke GitHub → Netlify auto-deploy
5. Buka `/admin.html`, login dengan `Admin@BPKPD2026`
6. Import data dari Excel di masing-masing tab
7. Pegawai login di `/` (index.html)

---

## 📝 Riwayat Perubahan Besar

| Tanggal | Perubahan |
|---|---|
| April 2026 | Inisiasi proyek — data hardcoded di JS files |
| April 2026 | Migrasi ke Supabase: hapus data-gaji.js & data-tpp.js sebagai sumber data |
| April 2026 | Buat admin.html: dashboard import Excel + manajemen user |
| April 2026 | Optimasi: import batch (dari 120+ query → 2 query) |
| April 2026 | Fix: hapus JSON.stringify dari RPC call (error "cannot extract elements from scalar") |
| Juli 2026  | Tambah kolom BPJS Kes 1% AKL di slip_tpp, update parsing Excel TPP (layout baru: +Gol/Ruang, +Kelas Jabatan, +BPJS Kes 1% AKL) |
| Juli 2026  | Tambah fitur Import Gaji P3K (menggantikan panel Potongan Internal ASN yang sudah tidak dipakai), update tampilan slip gaji agar P3K juga bisa melihat |
| Juli 2026  | Integrasi Fonnte API untuk notifikasi Blast WhatsApp massal, tambah fitur Edit Akun Pegawai untuk mengubah nama, rekening, dan No WA secara manual |

---

## 🚧 Potensi Perbaikan Ke Depan

- [ ] Hash PIN pegawai (bcrypt) untuk keamanan lebih
- [ ] Hash password admin
- [ ] Aktifkan RLS Supabase + Auth untuk keamanan penuh
- [ ] Pagination di manajemen user jika pegawai > 100
- [ ] Export data ke Excel dari admin
- [ ] Hapus file lama: `data-gaji.js`, `data-tpp.js`, `generator-admin.html`, `generator-tpp.html`
