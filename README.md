# Firebase Contacts Management

A Flutter app with **Google Sign-In via Firebase Authentication** — no OAuth 2.0 or Web Client ID in code; setup is done only in the Firebase Console.

> ⚠️ **Getting Error Code 10?** See [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md).

## Google Sign-In setup (Firebase only)

### Step 1: Enable Google Sign-In in Firebase

1. Open [Firebase Console](https://console.firebase.google.com/) → project **fir-contacts-management**
2. **Authentication** → **Sign-in method** → **Google** → **Enable**
3. Set **Support email** and **Save**

### Step 2: Add SHA-1 and update google-services.json

**Get SHA-1**

- Run `get_sha1.bat` in the project root, or:
  ```bash
  keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
  ```
- Copy the **SHA1** value (e.g. `AA:BB:CC:...`).

**Add it in Firebase**

1. Firebase Console → **⚙️ Project settings**
2. **Your apps** → Android app `com.example.firebase_contacts_management` → **Add fingerprint**
3. Paste SHA-1 → **Save**
4. If Firebase offers it, **download the new `google-services.json`** and replace `android/app/google-services.json`.

### Step 3: Run the app

```bash
flutter pub get
flutter run
```

### Troubleshooting (Error 10 / sign_in_failed)

- Enable **Google** in Firebase → Authentication → Sign-in method.
- Add **SHA-1** in Firebase → Project settings → Android app → Add fingerprint.
- Use the **google-services.json** from Firebase (after adding SHA-1).
- Then: `flutter clean && flutter run`

See [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) for the full checklist.

## Getting Started

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Firebase Flutter documentation](https://firebase.google.com/docs/flutter/setup)
