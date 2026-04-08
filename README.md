# 📋 PANDUAN DEPLOY SLIP GAJI BPKPD SRAGEN KE NETLIFY

## ✅ Kenapa Netlify (bukan PHP/InfinityFree)?

| | Netlify | PHP/InfinityFree |
|---|---|---|
| **Database** | ❌ Tidak perlu | ✅ Perlu setup DB |
| **Keamanan** | HTTPS otomatis | Manual |
| **Gratis** | Ya, generous | Ya, tapi lemot |
| **Kecepatan** | CDN global, cepat | Server shared, sering lemot |
| **Deploy** | Drag & drop | FTP upload |
| **Maintenance** | Minimal | Perlu update PHP |

**Kesimpulan: Netlify JAUH lebih cocok untuk kebutuhan ini karena data sudah di-embed di HTML (tidak butuh database sama sekali).**

---

## ⚙️ LANGKAH DEPLOY KE NETLIFY

### 1. Siapkan folder
```
slip-gaji/
└── index.html   ← file utama (sudah jadi)
```

### 2. Deploy ke Netlify (cara termudah)
1. Buka https://app.netlify.com
2. Daftar akun (gratis)
3. Drag & drop **folder `slip-gaji`** ke halaman Netlify
4. Selesai! Dapat URL seperti: `https://bpkpd-gaji.netlify.app`

### 3. Custom domain (opsional)
- Di Netlify dashboard → Domain Settings
- Tambah domain sendiri, misal: `gaji.sragen.go.id`
- Netlify akan beri instruksi DNS

---

## 🔑 CARA UPDATE NIP PEGAWAI

Saat ini NIP menggunakan placeholder (`NIPXXX001`, dst). 
**Sebelum deploy ke production, ganti dengan NIP asli:**

1. Buka `index.html` dengan text editor (Notepad++, VSCode)
2. Cari bagian `const EMPLOYEES = [`
3. Ganti setiap `"nip":"NIPXXX001"` dengan NIP asli pegawai
4. Simpan dan re-upload ke Netlify

Contoh:
```
"nip":"NIPXXX001" → "nip":"197010101 200003 1 001"
```

Lihat file `DAFTAR_NIP_PIN_ADMIN.txt` untuk daftar lengkap.

---

## 🔐 CARA UPDATE PIN

PIN saat ini di-generate random 6 digit.
Untuk mengubah PIN individual:
1. Cari nama pegawai di `index.html`
2. Ubah nilai `"pin":"XXXXXX"`
3. Simpan dan re-upload

**Catatan Keamanan:**
- Data ada di dalam file HTML (bisa dilihat di source code)
- Untuk keamanan lebih tinggi di masa depan, pertimbangkan pindah ke Netlify Functions + database terenkripsi

---

## 📱 CARA PAKAI (untuk pegawai)

1. Buka URL aplikasi di browser HP/komputer
2. Masukkan NIP dan PIN
3. Slip gaji tampil otomatis
4. Tekan **Download PDF** untuk simpan

---

## 🔄 UPDATE DATA BULAN BARU

Setiap ganti bulan:
1. Buka `index.html`
2. Update nilai-nilai gaji di `const EMPLOYEES`
3. Update teks `"Bulan April 2026"` di beberapa tempat
4. Re-upload ke Netlify (drag & drop lagi)

---

## 📁 STRUKTUR FILE TPP

Untuk fitur TPP (belum aktif), perlu:
1. Tambah data TPP ke dalam `EMPLOYEES` (field baru)
2. Tampilkan di tab TPP

---

Dibuat: April 2026 | BPKPD Kabupaten Sragen
