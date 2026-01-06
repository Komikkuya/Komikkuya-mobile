## 🤖 Android Build

**Runner:** `ubuntu-latest`

### Output Files

| File | Arsitektur | Ukuran | Target Device |
|------|------------|--------|---------------|
| `Komikkuya-X.apk` | Universal (fat) | ~53 MB | Semua perangkat |
| `Komikkuya-X-arm64-v8a.apk` | ARM64 | ~18 MB | HP modern (2017+) |
| `Komikkuya-X-armeabi-v7a.apk` | ARM32 | ~16 MB | HP lama (32-bit) |
| `Komikkuya-X-x86_64.apk` | x86_64 | ~18 MB | Emulator/Chromebook |

> 💡 **Tidak yakin pilih yang mana?** Download **Komikkuya-X.apk** (tanpa suffix)

---

## 🍎 iOS Build

**Runner:** `macos-latest`

### Output Files

| File | Ukuran | Keterangan |
|------|--------|------------|
| `Komikkuya-X.ipa` | ~12 MB | Unsigned IPA |

### ⚠️ iOS Installation Notes

IPA yang dihasilkan **tidak di-sign** (unsigned). Untuk install di device:

| Tool | Link |
|------|------|
| **AppleJr IPA Signer** | https://applejr.net/ |
| **AltStore** | https://altstore.io/ |
| **Sideloadly** | https://sideloadly.io/ |
| **Scarlet** | https://usescarlet.com/ |

---

## 🛠️ Troubleshooting

### APK gagal install
- Pastikan **Unknown Sources** diaktifkan
- Coba download ulang APK (mungkin corrupt)

### IPA tidak bisa di-install
- Gunakan sideload tool (AltStore/Scarlet)
- Pastikan certificate/profile masih valid
---

## 📊 Build Status

[![Build Android & iOS](https://github.com/Komikkuya/Komikkuya-mobile/actions/workflows/dart.yml/badge.svg)](https://github.com/Komikkuya/Komikkuya-mobile/actions/workflows/dart.yml)
