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

### Step 3: Enable Firestore (for contacts)

1. Firebase Console → **Build** → **Firestore Database** → **Create database**
2. Choose **Start in test mode** (or use rules that allow read/write for authenticated users).
3. Pick a location and **Enable**.

### Step 4: Run the app

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

## How contacts are saved in Firebase (Firestore)

Contacts are stored in **Cloud Firestore** so each signed-in user has their own list.

### Firestore layout

```
users
  └── {userId}          ← Firebase Auth UID (from currentUser.uid)
        └── contacts    ← subcollection
              └── {contactId}   ← auto-generated doc ID
                    ├── name      (string)
                    ├── phone     (string)
                    ├── email     (string)
                    └── createdAt (timestamp)
```

### What the app does

| Action  | Firestore call | Where in code |
|---------|----------------|---------------|
| **Add** | `users/{uid}/contacts.add(data)` | `home_screen.dart` → `_addContact()` → `_contactsRef(uid).add(contact.toMap())` |
| **Edit**| `users/{uid}/contacts/{id}.update(fields)` | `_editContact()` → `_contactsRef(uid).doc(contact.id).update({...})` |
| **Delete** | `users/{uid}/contacts/{id}.delete()` | `_deleteContact()` → `_contactsRef(uid).doc(contact.id).delete()` |
| **List** | `users/{uid}/contacts.orderBy('createdAt').snapshots()` | `StreamBuilder` in `home_screen.dart` body |

### Turning a contact into Firestore data

`Contact.toMap()` in `lib/models/contact.dart` returns a map Firestore accepts:

- `name`, `phone`, `email` — strings  
- `createdAt` — `FieldValue.serverTimestamp()` for new contacts, or `Timestamp.fromDate(...)` when updating

So “saving in Firebase” here means:

1. **New contact:** call `_contactsRef(uid).add(contact.toMap())` (e.g. from the FAB → Add contact → Save).
2. **Edit contact:** call `_contactsRef(uid).doc(contact.id).update({ 'name': ..., 'phone': ..., 'email': ... })`.
3. **Delete contact:** call `_contactsRef(uid).doc(contact.id).delete()`.

Firestore must be enabled in the Firebase Console (see Step 3 above); the app uses the default project and does not need extra config to save.

## Getting Started

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Firebase Flutter documentation](https://firebase.google.com/docs/flutter/setup)
