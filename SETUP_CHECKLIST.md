# Google Sign-In Setup

This app uses **Firebase Authentication** with **Google Sign-In**. If Android sign-in fails, set the Web Client ID in `lib/auth_config.dart` (see step 4).

---

## If you see Error 10 / sign_in_failed

### 1. Enable Google Sign-In in Firebase

1. [Firebase Console](https://console.firebase.google.com/) → project **fir-contacts-management**
2. **Authentication** → **Sign-in method**
3. **Google** → **Enable** → set Support email → **Save**

### 2. Add your SHA-1 fingerprint

**Get SHA-1**

- Double-click **`get_sha1.bat`** in the project root, or run:
  ```bash
  keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
  ```
- Copy the **SHA1** line (e.g. `AA:BB:CC:DD:...`).

**Add it in Firebase**

1. Firebase Console → **⚙️ Project settings**
2. **Your apps** → your Android app → **Add fingerprint**
3. Paste the SHA-1 → **Save**

### 3. Update google-services.json

After adding SHA-1, Firebase may offer to **download the new config**:

1. Download **google-services.json**
2. Replace `android/app/google-services.json` with it  
   (this refreshes the config Firebase uses for Google Sign-In).

### 4. (If still failing) Set Web Client ID

1. Open [Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials?project=fir-contacts-management)
2. Under **OAuth 2.0 Client IDs**, open **"Web client (auto created by Google Service)"**
3. Copy the **Client ID** (e.g. `46980072358-xxxxx.apps.googleusercontent.com`)
4. In the project, open **`lib/auth_config.dart`**
5. Set: `const String kGoogleWebClientId = 'YOUR_CLIENT_ID';`
6. Save and rebuild.

### 5. Rebuild the app

```bash
flutter clean
flutter run
```

---

## Checklist

- [ ] Google Sign-In **enabled** in Firebase → Authentication → Sign-in method  
- [ ] **SHA-1** added in Firebase → Project settings → Android app  
- [ ] **google-services.json** from Firebase (after SHA-1) is in `android/app/`  
- [ ] If sign-in still fails: **Web Client ID** set in `lib/auth_config.dart`  
- [ ] `flutter clean && flutter run` done after any config change  

---

## Notes

- SHA-1 is per machine; add each dev machine’s SHA-1 if needed.
- For release builds, add your **release** keystore’s SHA-1 in Firebase as well.
