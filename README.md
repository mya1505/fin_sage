# FinSage

FinSage adalah aplikasi manajemen keuangan premium berbasis Flutter dengan arsitektur modular, lokal database terenkripsi, dan backup ke Google Drive.

## Stack

- Flutter 3.19+ (Null Safety)
- Bloc/Cubit (`flutter_bloc`)
- SQLite + Drift (`sqflite`, `sqflite_sqlcipher`, `drift`, `drift_sqflite`)
- App preferences (`shared_preferences`)
- Backup Drive (`google_sign_in`, `googleapis`)
- UI (`fl_chart`, `flutter_svg`, `lottie`, custom painter)
- Lokalisasi (`intl`, ARB `en/id`, MessageLookup via `AppLocalizations`)
- Testing (`flutter_test`, `integration_test`, `mocktail`)

## Struktur

Lihat folder `lib/` untuk pembagian:
- `core/`: constants, errors, utilities, reusable widgets
- `features/`: auth, dashboard, transactions, budgets, reports, settings
- `data/`: models, repositories, datasources
- `logic/`: cubits per fitur

## Alur Aplikasi

- Route awal memakai auth gate (`/`) yang memvalidasi status login Google.
- Pengguna belum login diarahkan ke halaman auth.
- Pengguna login langsung masuk ke dashboard.
- Restore backup menampilkan preview file berbasis model type-safe (`BackupFileModel`).
- Backup cloud otomatis membersihkan backup lama (retensi 30 file terbaru) agar storage Drive tetap terkontrol.
- Backup baru menyimpan sidecar checksum SHA-256, dan restore akan memverifikasi checksum saat tersedia.
- Setelah restore backup berhasil, data transaksi/budget/dashboard otomatis di-refresh.
- Event backup/restore utama dicatat sebagai structured log dan breadcrumb Sentry untuk observability produksi.
- Preference tema dan bahasa disimpan lokal (`SharedPreferences`) dan dipulihkan saat startup.
- Migrasi database dipusatkan di `DbMigrationService` untuk upgrade schema bertahap.
- Dashboard menampilkan ringkasan bulanan + transaksi terbaru.
- Form transaksi mendukung tipe `income/expense` dan pemilihan kategori.
- Transaksi mendukung edit/update langsung dari daftar.
- Kategori kustom dapat ditambah langsung dari halaman transaksi.
- Kategori non-default dapat diarsipkan jika belum dipakai oleh transaksi.
- Anggaran mendukung edit/update langsung dari daftar budget.
- Anggaran sekarang mendukung hapus budget dengan konfirmasi.
- Ekspor CSV disimpan ke file sementara dan ditampilkan path hasil ekspor.
- Laporan mendukung filter bulanan dengan ringkasan income/expense/balance sebelum export.
- Laporan juga mendukung filter tipe transaksi (semua/pemasukan/pengeluaran).
- Settings menyediakan aksi sign out dengan konfirmasi.
- Settings mendukung toggle notifikasi budget dan reset data lokal aman.
- Settings menampilkan riwayat waktu backup terakhir.
- Settings menampilkan status auto-backup (attempt/success/error) dan tombol validasi job background.
- Settings menampilkan indikator progress saat operasi backup/restore berjalan dan kartu info aplikasi (nama + versi build).
- Auth bootstrap melakukan silent session restore agar status login lebih konsisten setelah restart.
- Inisialisasi service startup (notifikasi + auto-backup scheduler) bersifat fail-safe agar app tetap bisa boot jika plugin background gagal.
- Proses restore backup memiliki dialog konfirmasi sebelum overwrite data lokal.
- Restore backup sekarang memvalidasi file backup dan menolak file korup/tidak valid sebelum overwrite database lokal.

## Setup

1. Konfigurasi Android keystore sesuai [keystore_instructions.md](keystore_instructions.md)
2. Siapkan Google Sign-In di Android/iOS (lihat [docs/android_google_signin_setup.md](docs/android_google_signin_setup.md))
3. Set `dart-define` Google OAuth saat build Android:
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_SERVER_CLIENT_ID`
4. (Opsional) Konfigurasi observability:
   - `SENTRY_DSN`
   - `SENTRY_TRACE_SAMPLE_RATE` (0.0 - 1.0, default `0.1`)
5. Commit dan push ke GitHub branch `main`
6. Workflow GitHub Actions:
   - `testing.yml`: jalan saat `push` ke `main` (security guardrail, format check, static analysis, unit/widget/integration tests, concurrency cancel run lama)
   - `release.yml`: jalan saat push tag `vX.Y.Z` (preflight check tag vs pubspec version, build APK signed, inject `APP_VERSION` via `dart-define`, verifikasi signature + checksum, verifikasi ulang checksum artifact sebelum publish GitHub Release, cleanup material signing setelah build)
   - Artefak release bernama `finsage-vX.Y.Z-release.apk` + file checksum `finsage-vX.Y.Z-release.apk.sha256`.
7. Operasional rilis/rollback: lihat [docs/production_runbook.md](docs/production_runbook.md)

## Screenshots (Placeholder)

- Dashboard: `docs/screenshots/dashboard.png`
- Transactions: `docs/screenshots/transactions.png`
- Settings Backup: `docs/screenshots/settings_backup.png`

## Catatan

- Keystore binary tidak disimpan di repository.
- File placeholder keystore: `android/app.keystore.placeholder`.
- Lokalisasi source: `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`.
- Release workflow Android akan gagal jika secret `GOOGLE_CLIENT_ID` dan `GOOGLE_SERVER_CLIENT_ID` belum diisi.
