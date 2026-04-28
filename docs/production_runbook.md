# FinSage Production Runbook

Dokumen ini dipakai saat persiapan rilis, rilis, dan rollback produksi.

## 1. Pre-Release Checklist

1. Pastikan branch `main` hijau pada workflow `testing.yml`.
2. Pastikan `pubspec.yaml` version sudah benar (`X.Y.Z+build`).
3. Pastikan tag rilis yang akan dipush memakai format `vX.Y.Z` dan cocok dengan `pubspec` semantic version.
4. Validasi secrets GitHub terisi:
   - `KEYSTORE_B64`
   - `KEYSTORE_PASS`
   - `KEY_ALIAS`
   - `KEY_PASS`
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_SERVER_CLIENT_ID`
5. Pastikan `android/key.properties` dan `android/app/key.properties` tetap placeholder (`***`) di repo.
6. Pastikan tidak ada file keystore real yang ter-track git (`android/app/*.keystore`).

## 2. Release Steps

1. Buat commit final ke `main`.
2. Push tag versi:
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
3. Tunggu workflow `release.yml` selesai.
4. Verifikasi artifact pada GitHub Release:
   - `finsage-vX.Y.Z-release.apk`
   - `finsage-vX.Y.Z-release.apk.sha256`
5. Verifikasi nilai checksum di release notes cocok dengan file `.sha256`.
6. Smoke test APK di minimal 1 device fisik + 1 emulator.

## 3. Post-Release Validation

1. Login Google berhasil.
2. CRUD transaksi dan budget normal.
3. Backup manual berhasil.
4. Restore preview muncul.
5. Restore file valid berhasil dan data ter-refresh.
6. Error backup invalid/checksum mismatch terlokalisasi benar (en/id).
7. App Info di Settings menampilkan versi build yang sesuai release.

## 4. Rollback Plan

1. Jika rilis bermasalah, hentikan distribusi APK versi baru.
2. Publikasikan ulang APK stabil sebelumnya dari release terdahulu.
3. Buat hotfix branch dari `main`:
   ```bash
   git checkout -b hotfix/<issue-id>
   ```
4. Patch, merge ke `main`, lalu rilis patch version baru (`vX.Y.(Z+1)`).
5. Tambahkan catatan insiden singkat di PR hotfix:
   - dampak
   - akar masalah
   - perubahan perbaikan
   - langkah verifikasi

## 5. Incident Escalation

1. Kategori `Critical`:
   - aplikasi crash saat startup
   - data lokal rusak saat restore
   - backup cloud tidak bisa dipakai sama sekali
2. Untuk `Critical`, rollback dulu, baru lanjut hotfix.

