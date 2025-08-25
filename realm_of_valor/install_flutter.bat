@echo off
echo Installing Flutter for Realm of Valor...
echo.

echo Step 1: Downloading Flutter SDK...
echo Please download Flutter from: https://docs.flutter.dev/get-started/install/windows
echo Extract it to C:\flutter
echo.

echo Step 2: Adding Flutter to PATH...
setx PATH "%PATH%;C:\flutter\bin"
echo.

echo Step 3: Verifying installation...
echo Please restart your terminal and run: flutter doctor
echo.

echo Step 4: Running the app...
echo After Flutter is installed, run: flutter run
echo.

pause
