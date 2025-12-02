@echo off
REM ex10x Astro Dev Server Startup Script
REM Kills any existing instances before launching

echo Stopping any existing Node/Astro processes on port 4321...

REM Find and kill any process using port 4321
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":4321" ^| findstr "LISTENING"') do (
    echo Killing process PID: %%a
    taskkill /F /PID %%a 2>nul
)

REM Small delay to ensure port is released
timeout /t 1 /nobreak >nul

echo Starting Astro dev server...
npm run dev
