@echo off
echo Getting SHA-1 fingerprint for Firebase...
echo.
echo This will show your debug keystore SHA-1 fingerprint.
echo Copy the SHA-1 value (the long string after "SHA1:")
echo.
echo ========================================
echo.

keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

echo.
echo ========================================
echo.
echo Next steps:
echo 1. Copy the SHA-1 value above
echo 2. Go to Firebase Console ^> Project Settings ^> Your apps ^> Android app
echo 3. Click "Add fingerprint" and paste the SHA-1
echo 4. Wait a few minutes, then rebuild your app
echo.
pause
