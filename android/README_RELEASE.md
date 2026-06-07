# Android signed-release setup

The `Android Release Build` GitHub Actions workflow (`.github/workflows/android-release.yml`)
builds a signed `.aab` ready for Play Console upload, but it needs an upload
keystore and four repository secrets that **only the keystore/Play Console
owner can create** -- they cannot be provisioned from this codebase.

## 1. Generate an upload keystore (once, keep it forever)

```
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Store `upload-keystore.jks` somewhere safe outside the repo -- losing it means
you can never update the app under the same Play Store listing again.

## 2. Add repository secrets

In GitHub → Settings → Secrets and variables → Actions, add:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` output |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password you chose |
| `ANDROID_KEY_ALIAS` | `upload` (or whatever alias you used) |
| `ANDROID_KEY_PASSWORD` | the key password you chose |

## 3. Run the workflow

Trigger `Android Release Build` manually from the Actions tab
(`workflow_dispatch`). It decodes the keystore, writes `android/key.properties`,
and runs `flutter build appbundle --release`. The signed `.aab` is uploaded as
a build artifact, ready to upload to Play Console → Production/Internal testing.

## Local release builds

To build locally, create `android/key.properties` (gitignored) pointing at
your keystore file:

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

`android/app/build.gradle` automatically picks it up and signs release builds
with it; without this file, release builds fall back to the debug key (fine
for local testing, but Play Console will reject the upload).
