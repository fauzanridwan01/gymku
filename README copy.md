# GYMKU (Flutter) — Tahap 1: sisi Member

## Cara menjalankan
```bash
# 1) buat folder platform (android/ios/web) di dalam folder ini
flutter create . --project-name gymku --org id.gymku
# 2) pasang dependency
flutter pub get
# 3) jalankan
flutter run
```
`flutter create .` tidak menimpa `lib/` dan `pubspec.yaml` yang sudah ada.
Pastikan perangkat/emulator punya internet saat pertama jalan (font Google Fonts diunduh sekali).

## Akun demo
| Nama | Password | Kondisi |
|---|---|---|
| Naufal Badu | Gymku123 | Member Premium aktif (142 hari), 1 booking, ada riwayat |
| Tamu Baru | Gymku123 | Belum punya membership (uji layar terkunci & beli paket) |
| admin | admin123 | Panel admin (tahap 2) |

## Sudah jalan (logika nyata, data tersimpan di memori)
Login & daftar • Beranda (3 kondisi: belum member / aktif / dibekukan) • Booking kelas
(slot, penuh, batal, aturan 1 jam) • Paket → Pembayaran (kode promo `GYMKU20`, QRIS / VA / e-wallet,
timer) → Sukses (membership aktif/diperpanjang) • Profil • Data diri • Ganti password
(kekuatan + syarat) • Riwayat check-in & pembayaran • Target & Streak (buat/hapus, streak
dihitung dari check-in) • Bekukan member (7/14/21/30 hari, jadwal, aktifkan lebih awal) • Pusat Informasi.

## Belum ada (tahap berikutnya)
Scan/daftar wajah • seluruh sisi Admin (Dashboard, Laporan, Scan Wajah, Paket & Promo,
Keamanan, blokir/blacklist, permintaan buka beku) • notifikasi pengingat • backend.

## Agar "100% dipakai" di dunia nyata (tidak bisa hanya dari kode Flutter)
- **Backend + database** untuk akun, membership, booking, transaksi. Semua titik sambung
  ditandai `// API:` di `lib/core/app_state.dart`.
- **Payment gateway** (Midtrans/Xendit): QRIS asli & webhook. Tombol "Saya sudah bayar
  (simulasi)" harus dihapus.
- **Pengenalan wajah**: kamera + model/layanan face recognition (mis. ML Kit / AWS Rekognition).
- **Simpan sesi login** (token) dan hashing password di server.
- Logo: export node `55:161` dari Figma ke `assets/logo.png` lalu ganti ikon placeholder di `auth_screens.dart`.
