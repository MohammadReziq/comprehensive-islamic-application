@echo off
set KEYSTORE=%USERPROFILE%\.android\debug.keystore
if not exist "%KEYSTORE%" (
  echo ERROR: Keystore not found at %KEYSTORE%
  echo Make sure you have built a Flutter/Android app at least once.
  pause
  exit /b 1
)

set KEYTOOL=keytool
if exist "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" set "KEYTOOL=C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
if exist "C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe" set "KEYTOOL=C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe"

"%KEYTOOL%" -list -v -keystore "%KEYSTORE%" -alias androiddebugkey -storepass android -keypass android
if errorlevel 1 (
  echo.
  echo If keytool not found, run from Android Studio: Build ^> Flutter ^> Open Android module in Android Studio, then run in terminal:
  echo keytool -list -v -keystore "%%USERPROFILE%%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
  echo.
  pause
  exit /b 1
)

echo.
echo ========================================================
echo COPY the SHA1 line above and add it in Google Cloud:
echo Credentials ^> Android OAuth client ^> SHA-1 fingerprint
echo ========================================================
pause
