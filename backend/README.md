# GYMKU Backend (Laravel 12 + PostgreSQL)

Folder ini berisi **kode khusus GYMKU** (migrasi, model, controller, seeder, test, rute).
Rangka Laravel-nya (vendor, artisan, config, dst.) dibuat sekali oleh Composer di komputer Anda,
supaya repo tetap kecil.

## Prasyarat
PHP 8.2+, Composer, PostgreSQL 14+ (ekstensi `pdo_pgsql` aktif).

## Pasang (sekali saja)

Jalankan dari **root repo**:

```bash
# 1. Buat rangka Laravel di folder sementara
composer create-project laravel/laravel:^12.0 _laravel
cd _laravel && php artisan install:api --no-interaction && cd ..

# 2. Salin rangka ke backend/ TANPA menimpa file GYMKU
#    Linux/macOS/Git Bash:
cp -rn _laravel/. backend/
#    Windows (CMD/PowerShell):  robocopy _laravel backend /E /XC /XN /XO

# 3. Hapus folder sementara
rm -rf _laravel          # Windows: rmdir /s /q _laravel

# 4. Konfigurasi
cd backend
cp .env.example .env
php artisan key:generate
```

Edit `backend/.env` (zona waktu penting agar "hari ini" dan masa aktif sesuai WIB; sudah ada di `.env.example`).
`APP_TIMEZONE` dibaca oleh `config/app.php`, dan koneksi PostgreSQL otomatis memakai zona yang sama (`DB_TIMEZONE`):

```
APP_TIMEZONE=Asia/Jakarta
```

```
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=gymku
DB_USERNAME=postgres
DB_PASSWORD=<kata sandi postgres Anda>
```

```bash
# 5. Buat database, migrasi, isi data contoh
createdb -U postgres gymku        # atau lewat pgAdmin
php artisan migrate --seed
php artisan storage:link

# 6. Jalankan
php artisan serve --host=0.0.0.0   # http://127.0.0.1:8000
php artisan test                   # opsional
```

Ulang dari nol: `php artisan migrate:fresh --seed`.

## Akun contoh (dari seeder)

| Peran  | Login                                  | Kata sandi |
|--------|----------------------------------------|------------|
| Admin  | `admin` atau `admin@gymku.id`          | `admin123` |
| Member | `Naufal Badu` / `naufal@gmail.com`     | `Gymku123` |
| Member | `Tamu Baru` / `baru@gymku.id` (tanpa paket) | `Gymku123` |

## Alamat dari aplikasi Flutter
- Emulator Android: `http://10.0.2.2:8000/api`
- HP asli (satu Wi-Fi): `http://<IP-laptop>:8000/api`
- Android memblokir HTTP polos: tambahkan `android:usesCleartextTraffic="true"` pada `<application>` di `android/app/src/main/AndroidManifest.xml` (hanya untuk pengembangan).

Autentikasi (dan selalu kirim `Accept: application/json`): kirim header `Authorization: Bearer <token>` (token dari `/auth/login`).

## Endpoint (tahap ini)

| Metode | Path | Keterangan |
|---|---|---|
| POST | `/api/auth/register` | name, email, password (min 8, huruf+angka), password_confirmation |
| POST | `/api/auth/login` | `login` (email atau nama) + `password` |
| POST | `/api/auth/logout` | |
| GET / PUT | `/api/me` | profil + status keanggotaan / ubah profil |
| PUT | `/api/me/password` | current_password, password, password_confirmation |
| POST | `/api/me/face` | unggah foto wajah (`photo`) → `App\Services\FaceMatcher` |
| GET | `/api/announcements` | Pusat Informasi member: `{banner, items}` (sudah disaring per member, jadwal, kedaluwarsa) |
| POST | `/api/announcements/{id}/view` | menambah hitungan dilihat |
| GET/POST | `/api/admin/announcements` | daftar (`?status=`) / buat |
| PUT | `/api/admin/announcements/{id}` | ubah |
| PATCH | `/api/admin/announcements/{id}/archive` | `{archived: true|false}` |
| DELETE | `/api/admin/announcements/{id}` | hapus |
| GET | `/api/admin/members?q=` | cari member untuk pemilih target |

Body buat/ubah informasi: `category` (Pengumuman|Kelas|Promo), `title`, `body`,
`target_user_id` (kosong = semua member), `is_banner`, `valid_until` (tanggal),
`publish_at` (opsional, jadwal tayang), `status` (`draft`|`published`).

### Paket, promo, checkout (QRIS simulasi)

| Metode | Path | Keterangan |
|---|---|---|
| GET | `/api/plans` | paket aktif + promo otomatis yang berlaku untuk user ini |
| POST | `/api/orders` | `{plan_code, promo_code?}` → pesanan `pending` (15 menit) |
| GET | `/api/orders/{code}` | status pesanan (otomatis `expired` bila lewat waktu) |
| POST | `/api/orders/{code}/refresh` | perpanjang waktu bayar |
| POST | `/api/orders/{code}/cancel` | batalkan |
| POST | `/api/orders/{code}/simulate-pay` | **simulasi** webhook QRIS: tandai lunas, buat/perpanjang keanggotaan (nonaktif di production) |
| GET | `/api/transactions` | riwayat pembayaran berhasil |
| GET | `/api/admin/plans` · PUT `/api/admin/plans/{id}` `{price}` · PATCH `.../enabled` | kelola harga/aktif paket |
| GET/POST | `/api/admin/promos` · PUT `/{id}` · POST `/{id}/end` · PATCH `/{id}/enabled` | kelola promo |

Aturan: kode promo menggantikan promo otomatis; promo "khusus perpanjangan" hanya untuk member aktif;
harga dihitung di server.

### Kelas, booking, check-in

| Metode | Path | Keterangan |
|---|---|---|
| GET | `/api/classes?date=YYYY-MM-DD` | jadwal kelas satu hari (default hari ini): sisa slot + status booking saya |
| GET | `/api/bookings` | kelas yang saya booking |
| POST | `/api/bookings` | `{class_id}`; ditolak jika diblokir/tidak aktif/dibekukan, kelas sudah mulai, penuh, atau tanggalnya di masa pembekuan |
| DELETE | `/api/bookings/{class_id}` | batal, maksimal 1 jam sebelum kelas |
| GET | `/api/checkins` | riwayat + kunjungan & hari aktif bulan ini |
| POST | `/api/checkins` | check-in mandiri: `photo` **wajib** dan wajah harus sudah terdaftar (`/api/me/face`); dicocokkan via `FaceMatcher`; jeda 2 menit |
| POST | `/api/admin/checkins` | admin mencatat check-in: `{user_id, method: face|manual}` |

## Tempat algoritma wajah (untuk teman satu tim)
Ubah isi dua method di `app/Services/FaceMatcher.php` (`embed()` dan `match()`).
Tabel `face_templates` (kolom `embedding` jsonb) dan endpoint `/api/me/face` sudah siap.

## Pembayaran QRIS
Disimulasikan (tanpa payment gateway) lewat `POST /api/orders/{code}/simulate-pay`.
Endpoint ini hanya aktif saat `APP_ENV` = `local`/`testing`, atau jika `GYMKU_SIMULATE_PAY=true`.
Di server sungguhan biarkan mati dan ganti dengan webhook payment gateway (verifikasi tanda tangan).

## Keamanan singkat
- Login/register dibatasi 10 percobaan per menit; token berlaku 30 hari (`SANCTUM_EXPIRATION`, menit).
- Member yang diblokir langsung ditolak di semua endpoint (kecuali logout), walau token lamanya masih ada.
- Semua error di `/api/*` selalu berbentuk JSON, termasuk 401 tanpa header `Accept`.
- Login: isian berisi `@` dianggap email, selain itu nama; tidak membedakan huruf besar-kecil.

## Peta tabel
`users` · `plans` · `promos` + `promo_plan` · `promo_codes` · `memberships` · `freezes` ·
`freeze_requests` · `transactions` · `gym_classes` · `bookings` · `checkins` · `targets` ·
`announcements` · `block_records` · `activity_logs` · `face_templates`
(+ `personal_access_tokens` dari Sanctum).

## Belum dibuat (tahap berikutnya)
Target, pembekuan, dan aksi admin lain
(sesuai penanda `// API:` di `lib/core/app_state.dart`), lalu menyambungkan Flutter ke API.
