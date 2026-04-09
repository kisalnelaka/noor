@echo off
setlocal

echo.
echo    █████╗ ██╗   ██╗██████╗  █████╗ 
echo   ██╔══██╗██║   ██║██╔══██╗██╔══██╗
echo   ███████║██║   ██║██████╔╝███████║
echo   ██╔══██║██║   ██║██╔══██╗██╔══██║
echo   ██║  ██║╚██████╔╝██║  ██║██║  ██║
echo   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
echo.
echo     AURA ANDROID BUILD PLATFORM (V2)
echo ===================================================

echo [1/3] Fetching Flutter Dependencies...
cd frontend
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter pub get failed.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/3] Building Premium Android APK...
echo This will take a few minutes as the intelligence system is bundled.
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Building APK failed.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [3/3] Exporting APK to Aura Root...
set APK_SOURCE=build\app\outputs\flutter-apk\app-release.apk
set APK_DEST=..\NOOR.apk

if exist "%APK_SOURCE%" (
    copy "%APK_SOURCE%" "%APK_DEST%"
    echo.
    echo ✅ SUCCESS: APK exported to: %APK_DEST%
) else (
    echo [ERROR] Could not find the generated APK.
)

cd ..
echo.
pause
