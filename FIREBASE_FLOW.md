# Firebase Usage in This App — Step by Step

This doc explains **how** and **where** Firebase is used in the Contacts app, in order.

---

## 1. What We Use

| Firebase product      | Purpose in this app                          |
|-----------------------|----------------------------------------------|
| **Firebase Core**     | Connect the app to your Firebase project     |
| **Firebase Auth**     | Sign in with Google, know “who is logged in” |
| **Cloud Firestore**   | Store user profile + contacts per user       |

---

## 2. Firebase Console Setup (one-time)

Do this in [Firebase Console](https://console.firebase.google.com/):

1. **Create or select project** (e.g. `fir-contacts-management`).
2. **Add an Android app** with package name `com.example.firebase_contacts_management`, then download `google-services.json` into `android/app/`.
3. **Authentication → Sign-in method → Google → Enable** and set a support email.
4. **Project settings → Your apps → Android app → Add fingerprint** and add your debug **SHA-1** (run `get_sha1.bat` or use `keytool`).
5. **Build → Firestore Database → Create database** (e.g. test mode for development).
6. *(If Android sign-in fails)* In Google Cloud Console → Credentials, copy the **Web client** OAuth 2.0 Client ID into `lib/auth_config.dart` as `kGoogleWebClientId`.

---

## 3. Flutter Dependencies

In `pubspec.yaml` we use:

```yaml
dependencies:
  firebase_core: ^4.4.0      # base + init
  firebase_auth: ^6.1.4      # sign-in / currentUser / authStateChanges
  cloud_firestore: ^6.1.2    # users + contacts
  google_sign_in: ^6.2.2     # Google account picker + tokens
```

Then run: `flutter pub get`.

---

## 4. Step 1 — Initialize Firebase at App Start

**File:** `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

- **Why:** Firebase must be initialized before any Auth or Firestore calls.
- **`DefaultFirebaseOptions.currentPlatform`** comes from `lib/firebase_options.dart` (values from your Firebase project / `google-services.json`).

---

## 5. Step 2 — Decide Screen by Auth State

**File:** `lib/main.dart`

```dart
home: StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (snapshot.hasData && snapshot.data != null) {
      return const HomeScreen();   // logged in
    }
    return const LoginScreen();    // not logged in
  },
),
```

- **`authStateChanges()`** is a stream: it emits the current user when they sign in or sign out.
- **Logic:**  
  - Loading → show spinner.  
  - User exists → show `HomeScreen`.  
  - No user → show `LoginScreen`.

---

## 6. Step 3 — Google Sign-In (Login Screen)

**File:** `lib/screens/login_screen.dart`

When the user taps “Continue with Google”:

1. **Create Google Sign-In and start flow**
   ```dart
   final googleSignIn = GoogleSignIn(
     serverClientId: kGoogleWebClientId.isEmpty ? null : kGoogleWebClientId,
   );
   final googleUser = await googleSignIn.signIn();
   ```
   - Opens the Google account picker.  
   - If user cancels, `googleUser == null` → stop.

2. **Get tokens from Google**
   ```dart
   final googleAuth = await googleUser.authentication;
   final credential = GoogleAuthProvider.credential(
     accessToken: googleAuth.accessToken,
     idToken: googleAuth.idToken,
   );
   ```
   - `idToken` is what Firebase Auth uses to create a session.

3. **Sign in to Firebase with that credential**
   ```dart
   await FirebaseAuth.instance.signInWithCredential(credential);
   ```
   - Firebase Auth now has a “current user”; `authStateChanges()` will emit and the app switches to `HomeScreen`.

---

## 7. Step 4 — Save Sign-In Info to Firestore (Login Screen)

**File:** `lib/screens/login_screen.dart` (right after sign-in succeeds)

```dart
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'uid': user.uid,
    'email': user.email ?? '',
    'displayName': user.displayName ?? '',
    'photoURL': user.photoURL ?? '',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
```

- **Path:** `users/{userId}`.
- **Purpose:** Keep a copy of the signed-in user’s profile in Firestore (email, name, photo, last update).
- **`merge: true`** keeps existing fields and only updates the ones you send (e.g. on later logins).

---

## 8. Firestore Data Layout

All Firebase usage in this app follows this structure:

```
Firestore
└── users (collection)
    └── {userId} (document)     ← Auth UID
          ├── uid
          ├── email
          ├── displayName
          ├── photoURL
          ├── updatedAt
          └── contacts (subcollection)
                └── {contactId} (document)
                      ├── name
                      ├── phone
                      ├── email
                      └── createdAt
```

- One **user** doc per signed-in account.
- One **contacts** subcollection per user; each contact is a document there.

---

## 9. Step 5 — Use Firestore for Contacts (Home Screen)

**File:** `lib/screens/home_screen.dart`

**References:**

- User’s contacts:  
  `FirebaseFirestore.instance.collection('users').doc(uid).collection('contacts')`
- In code this is wrapped in `_contactsRef(uid)`.

**Ensure user doc exists before adding a contact:**

```dart
static Future<void> _ensureUserCollection(String uid) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .set({'uid': uid}, SetOptions(merge: true));
}
```

- Called before the first contact is added so `users/{uid}` (and thus the contacts subcollection) exists.

**Add contact:**

```dart
await _ensureUserCollection(uid);
await _contactsRef(uid).add(contact.toMap());
```

- `contact.toMap()` gives `name`, `phone`, `email`, `createdAt` (or `FieldValue.serverTimestamp()` for new contacts).

**Edit contact:**

```dart
await _contactsRef(uid).doc(contact.id).update({
  'name': updated.name,
  'phone': updated.phone,
  'email': updated.email,
});
```

**Delete contact:**

```dart
await _contactsRef(uid).doc(contact.id).delete();
```

**List contacts (live list):**

```dart
stream: _contactsRef(uid)
    .orderBy('createdAt', descending: true)
    .snapshots(),
```

- `snapshots()` keeps the list in sync with Firestore (add/edit/delete show up automatically).

---

## 10. End-to-End Flow (Summary)

1. **App starts**  
   `main()` → `Firebase.initializeApp()` → `runApp(MyApp)`.

2. **MyApp**  
   Listens to `FirebaseAuth.instance.authStateChanges()`:
   - No user → **LoginScreen**  
   - User → **HomeScreen**

3. **User taps “Continue with Google” (LoginScreen)**  
   - `GoogleSignIn().signIn()` → account picker.  
   - `GoogleAuthProvider.credential(...)` from Google tokens.  
   - `FirebaseAuth.instance.signInWithCredential(credential)`.  
   - Save profile to `users/{uid}` in Firestore.  
   - Stream emits user → app shows **HomeScreen**.

4. **HomeScreen**  
   - Uses `FirebaseAuth.instance.currentUser.uid`.  
   - Listens to `users/{uid}/contacts` with `snapshots()`.  
   - FAB → add contact: `_ensureUserCollection(uid)` then `_contactsRef(uid).add(...)`.  
   - Edit/delete use `_contactsRef(uid).doc(id).update/delete`.

5. **Sign out**  
   - `FirebaseAuth.instance.signOut()` and `GoogleSignIn().signOut()`.  
   - `authStateChanges()` emits `null` → app shows **LoginScreen** again.

---

## 11. Quick Reference: Where What Happens

| What                     | Where            | How                                                                 |
|--------------------------|------------------|---------------------------------------------------------------------|
| Init Firebase            | `main.dart`      | `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` |
| Auth-based routing       | `main.dart`      | `StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(), …)` |
| Google Sign-In           | `login_screen.dart` | `GoogleSignIn().signIn()` → `credential` → `signInWithCredential()`   |
| Save sign-in to Firestore| `login_screen.dart` | `FirebaseFirestore.instance.collection('users').doc(uid).set(…, merge: true)` |
| User’s contacts ref      | `home_screen.dart`  | `_contactsRef(uid)` → `users/{uid}/contacts`                         |
| Add contact              | `home_screen.dart`  | `_ensureUserCollection(uid)` then `_contactsRef(uid).add(contact.toMap())` |
| Edit / delete contact    | `home_screen.dart`  | `_contactsRef(uid).doc(id).update(...)` / `.delete()`                |
| Live contact list        | `home_screen.dart`  | `_contactsRef(uid).orderBy('createdAt').snapshots()` in a `StreamBuilder` |

This is the full Firebase usage flow in this project, step by step.
