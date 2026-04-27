# FinSage

FinSage adalah aplikasi manajemen keuangan premium berbasis Flutter dengan arsitektur modular, lokal database terenkripsi, dan backup ke Google Drive.

## Stack

- Flutter 3.19+ (Null Safety)
- Bloc/Cubit (`flutter_bloc`)
- SQLite + Drift (`sqflite`, `sqflite_sqlcipher`, `drift`, `drift_sqflite`)
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

## Setup

1. Konfigurasi Android keystore sesuai [keystore_instructions.md](keystore_instructions.md)
2. Siapkan Google Sign-In di Android/iOS
3. Commit dan push ke GitHub branch `main`
4. CI GitHub Actions akan menjalankan:
   - `flutter test`
   - `flutter build apk --release`
   - signing APK dari secrets
   - publish GitHub Release saat push tag `vX.Y.Z`

## Screenshots (Placeholder)

- Dashboard: `docs/screenshots/dashboard.png`
- Transactions: `docs/screenshots/transactions.png`
- Settings Backup: `docs/screenshots/settings_backup.png`

## Catatan

- Keystore binary tidak disimpan di repository.
- File placeholder keystore: `android/app.keystore.placeholder`.
- Lokalisasi source: `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`.
