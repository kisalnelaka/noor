@echo off
echo ===================================================
echo 📱 Starting NOOR Android Emulator Deploy 📱
echo ===================================================

echo.
echo [1/2] Fetching Flutter Dependencies...
cd frontend
call flutter pub get

echo.
echo [2/2] Launching NOOR on Android Device/Emulator...
echo Ensure you have an Android device connected via ADB or an Android Emulator running.
call flutter run -d emulator-5554

pause
