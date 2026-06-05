@echo off
echo.
echo  ==========================================
echo   Nativa - Starting local environment
echo  ==========================================
echo.

REM Check Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  ERROR: Docker is not installed or not running.
    echo  Install Docker Desktop from https://www.docker.com/products/docker-desktop/
    pause
    exit /b 1
)

REM Check .env
if not exist ".env" (
    echo  Creating .env file...
    echo ANTHROPIC_API_KEY=your_key_here > .env
    echo.
    echo  ACTION REQUIRED: Open .env and add your Anthropic API key.
    echo  Get one at https://console.anthropic.com
    echo.
    pause
    exit /b 1
)

REM Check API key is set
findstr /C:"your_key_here" .env >nul
if %errorlevel% equ 0 (
    echo  ERROR: Please set your ANTHROPIC_API_KEY in the .env file first.
    pause
    exit /b 1
)

echo  Starting Postgres + .NET API via Docker Compose...
docker compose up --build -d

echo.
echo  Waiting for API to be ready...
:wait_loop
timeout /t 3 /nobreak >nul
curl -s http://localhost:5000/health >nul 2>&1
if %errorlevel% neq 0 goto wait_loop

echo  Backend is ready at http://localhost:5000
echo  Swagger UI:       http://localhost:5000/swagger
echo.

REM Check Flutter
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  Flutter not found. To run the mobile app:
    echo  1. Install Flutter: https://docs.flutter.dev/get-started/install/windows
    echo  2. Run: flutter run -d windows
    echo     OR: flutter run -d chrome  (web version)
    echo.
    echo  Backend is running. Press any key to exit.
    pause
    exit /b 0
)

echo  Starting Flutter app (Windows desktop)...
cd flutter_app
start "Nativa Flutter" flutter run -d windows

echo.
echo  ==========================================
echo   All services started!
echo   API:     http://localhost:5000
echo   Swagger: http://localhost:5000/swagger
echo  ==========================================
echo.
echo  Press any key to stop all services...
pause >nul

echo  Stopping Docker services...
cd ..
docker compose down
echo  Done.
