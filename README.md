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
- Preference tema dan bahasa disimpan lokal (`SharedPreferences`) dan dipulihkan saat startup.
- Migrasi database dipusatkan di `DbMigrationService` untuk upgrade schema bertahap.
- Dashboard menampilkan ringkasan bulanan + transaksi terbaru.
- Form transaksi mendukung tipe `income/expense` dan pemilihan kategori.
- Kategori kustom dapat ditambah langsung dari halaman transaksi.
- Kategori non-default dapat diarsipkan jika belum dipakai oleh transaksi.
- Ekspor CSV disimpan ke file sementara dan ditampilkan path hasil ekspor.
- Proses restore backup memiliki dialog konfirmasi sebelum overwrite data lokal.

## Setup

1. Konfigurasi Android keystore sesuai [keystore_instructions.md](keystore_instructions.md)
2. Siapkan Google Sign-In di Android/iOS
3. Commit dan push ke GitHub branch `main`
4. Workflow GitHub Actions:
   - `testing.yml`: jalan saat `push` ke `main` (unit/widget/integration tests)
   - `release.yml`: jalan saat push tag `vX.Y.Z` (test gate, build APK signed, build iOS no-codesign, publish GitHub Release)

## Screenshots (Placeholder)

- Dashboard: `docs/screenshots/dashboard.png`
- Transactions: `docs/screenshots/transactions.png`
- Settings Backup: `docs/screenshots/settings_backup.png`

## Catatan

- Keystore binary tidak disimpan di repository.
- File placeholder keystore: `android/app.keystore.placeholder`.
- Lokalisasi source: `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`.
