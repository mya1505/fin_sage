# Keystore Setup Instructions

1. Generate keystore:
```bash
keytool -genkey -v -keystore android/app/fin_sage.keystore -alias finsage -keyalg RSA -keysize 2048 -validity 10000
```

2. Simpan password di GitHub Secrets:
- `KEYSTORE_PASS`
- `KEY_ALIAS`
- `KEY_PASS`

3. Base64-encode keystore lalu simpan di secret `KEYSTORE_B64`:
```bash
base64 android/app/fin_sage.keystore | tr -d '\n'
```

4. Pastikan file keystore asli tidak di-commit ke repository.
