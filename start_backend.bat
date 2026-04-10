@echo off
setlocal enabledelayedexpansion
title NOOR Premium Services
color 0B

:MENU
cls
echo.
echo =================================================================
echo.
echo           ███╗   ██╗ ██████╗  ██████╗ ██████╗ 
echo           ████╗  ██║██╔═══██╗██╔═══██╗██╔══██╗
echo           ██╔██╗ ██║██║   ██║██║   ██║██████╔╝
echo           ██║╚██╗██║██║   ██║██║   ██║██╔══██╗
echo           ██║ ╚████║╚██████╔╝╚██████╔╝██║  ██║
echo           ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
echo.
echo          N O O R   C O R E   I N T E L L I G E N C E        
echo                     Launchpad Engine v4.0                       
echo.
echo =================================================================
echo.

:: --- DEPENDENCY CHECKS ---
echo [ SYSTEM HEALTH CHECK ]
set DOCKER_ACTIVE=0
docker ps >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    set DOCKER_ACTIVE=1
    echo   [+] Docker Engine : ONLINE  ✅
) else (
    echo   [-] Docker Engine : OFFLINE ❌
    echo.
    echo   [!] CRITICAL: Docker Desktop must be running to use Options 1 or 2.
    echo       Please start Docker and try again.
    echo.
    pause
)

where python >nul 2>nul
if !ERRORLEVEL! EQU 0 (
    echo   [+] Python Env    : ONLINE  ✅
) else (
    echo   [-] Python Env    : OFFLINE ❌ (Docker strictly required)
)
echo -----------------------------------------------------------------
echo.
echo  Choose Launch Profile:
echo.
echo    [1] 🌟 DOCKER: Clean Start (Recommended)
echo        Fully cleans ports, destroys stuck containers, builds anew.
echo.
echo    [2] ⚡ DOCKER: Fast Resume
echo        Quickly spins up existing containers without rebuilding.
echo.
echo    [3] 🐍 LOCAL: Python Native Mode
echo        Runs FastAPI locally on your system using a Virtual Env.
echo.
echo    [4] ❌ EXIT
echo.
set "envChoice=1"
set /p envChoice=" Enter Selection [1-4] (Default: 1): "

if "%envChoice%"=="1" goto :DOCKER_CHECK_CLEAN
if "%envChoice%"=="2" goto :DOCKER_CHECK_FAST
if "%envChoice%"=="3" goto :LOCAL_CHECK
if "%envChoice%"=="4" exit /b 0

:: Fallback if they hit enter
goto :RUN_DOCKER_CLEAN

:DOCKER_CHECK_CLEAN
if !DOCKER_ACTIVE! EQU 0 (
    echo.
    echo  ❌ ERROR: Docker is offline. Option 1 requires Docker.
    pause
    goto :MENU
)
goto :RUN_DOCKER_CLEAN

:DOCKER_CHECK_FAST
if !DOCKER_ACTIVE! EQU 0 (
    echo.
    echo  ❌ ERROR: Docker is offline. Option 2 requires Docker.
    pause
    goto :MENU
)
goto :RUN_DOCKER_FAST

:RUN_DOCKER_CLEAN
cls
echo =================================================================
echo              🌟 INITIATING CLEAN DOCKER DEPLOYMENT
echo =================================================================
echo.
echo  [Step 1/3] 🧹 Sweeping legacy containers and freeing ports...
docker compose down >nul 2>&1
timeout /t 3 >nul

echo.
echo  [Step 2/3] 🔓 Releasing database locks for Docker...
if exist "backend\noor.db" del /f /q "backend\noor.db" 2>nul
if exist "backend\noor.db-wal" del /f /q "backend\noor.db-wal" 2>nul
if exist "backend\noor.db-shm" del /f /q "backend\noor.db-shm" 2>nul

echo.
echo  [Step 3/3] 🏗️ Engineering NOOR core images (Redis, Qdrant, API)...
echo.
echo =================================================================
echo   ✅ NOOR IS BOOTING IN REAL-TIME
echo   🛰️  API Docs Server : http://localhost:8000/docs
echo   🎙️  Websocket Brain : ws://localhost:8000/ws/chat
echo =================================================================
echo.
echo.
echo   [Action] Initializing NOOR Core...
docker compose up -d --build
echo.
echo  [Step 2/2] 🔄 Seeding Diverse Real Estate Context (Inside Container)...
docker compose exec backend python scripts/seed_data.py
if %ERRORLEVEL% NEQ 0 (
    echo  ⚠️  Warning: Container seeding failed. NOOR will use last known memory.
)

echo.
echo =================================================================
echo   ✅ NOOR IS BOOTING IN REAL-TIME
echo   🛰️  API Docs Server : http://localhost:8000/docs
echo   🎙️  Websocket Brain : ws://localhost:8000/ws/chat
echo =================================================================
echo.
echo   [Action] Streaming live container logs... (Press CTRL+C to stop servers)
echo.
docker compose logs -f
exit /b 0

:RUN_DOCKER_FAST
cls
echo =================================================================
echo                 ⚡ INITIATING FAST DOCKER RESUME
echo =================================================================
echo.
echo  [Step 1/2] 🚀 Awakening NOOR intelligence containers...
docker compose up -d
echo.
echo  [Step 2/2] 🔄 Seeding Diverse Real Estate Context (Inside Container)...
docker compose exec backend python scripts/seed_data.py
if %ERRORLEVEL% NEQ 0 (
    echo  ⚠️  Warning: Container seeding failed. Check your Docker health.
)

echo.
echo =================================================================
echo   ✅ NOOR IS BOOTING IN REAL-TIME
echo   🛰️  API Docs Server : http://localhost:8000/docs
echo   🎙️  Websocket Brain : ws://localhost:8000/ws/chat
echo =================================================================
echo.
echo   [Action] Streaming live container logs... (Press CTRL+C to stop servers)
echo.
docker compose logs -f
exit /b 0


:LOCAL_CHECK
cls
echo =================================================================
echo                 🐍 INITIATING LOCAL NATIVE BOOT
echo =================================================================
echo.
where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo  ❌ ERROR: Python is not installed natively on your system.
    echo  Re-routing to Docker Deployment...
    timeout /t 3
    goto :RUN_DOCKER_CLEAN
)

cd backend

:: VENV LOGIC
if not exist "venv" (
    echo  [Step 1/3] 🏗️ Architecting Python Virtual Environment...
    python -m venv venv
    call venv\Scripts\activate
    
    echo  [Step 2/3] 📦 Installing intelligence libraries...
    python -m pip install --upgrade pip
    pip install -r requirements.txt
) else (
    echo  [Step 1/2] ✅ Virtual Environment Verified natively.
    call venv\Scripts\activate
)

:: DATABASE LOGIC
if exist "noor.db" (
    echo.
    echo  [Database] Local brain module located.
    set "seedChoice=n"
    set /p seedChoice="  ? Would you like to factory reset and re-seed 50 properties? (y/n) [n]: "
    if /i "!seedChoice!"=="y" (
        echo  🔄 Seeding Real Estate Context Database...
        python -m scripts.seed_data
    )
) else (
    echo.
    echo  [Step 2/2] 🏗️ Formatting fresh Database Architecture...
    python -m scripts.seed_data
)

echo.
echo =================================================================
echo                 🚀 LAUNCHING LOCAL API SERVER
echo =================================================================
echo   🛰️  API Target: http://127.0.0.1:8000
echo   To shutdown, press CTRL+C
echo.
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
exit /b 0
