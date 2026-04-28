# Android Google Sign-In Setup

1. Buka Google Cloud Console, pilih project yang dipakai aplikasi.
2. Aktifkan API berikut:
   - Google Drive API
3. Pada OAuth consent screen, tambahkan scope:
   - `email`
   - `https://www.googleapis.com/auth/drive.appdata`
4. Buat OAuth Client ID:
   - Android client (package name + SHA-1 debug/release)
   - Web client (dipakai sebagai `GOOGLE_SERVER_CLIENT_ID`)
5. Isi GitHub Secrets untuk release Android:
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_SERVER_CLIENT_ID`
6. Untuk build lokal/manual, kirim `dart-define`:

```bash
flutter build apk --release \
  --dart-define=GOOGLE_CLIENT_ID=<your_google_client_id> \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<your_google_server_client_id>
```

7. Pastikan akun tester sudah diizinkan pada OAuth consent screen jika status app masih testing.
