@echo off
echo ========================================
echo    ZERDA ADMIN PANEL STARTING...
echo ========================================
echo.

cd /d "%~dp0"

echo Installing dependencies...
call npm install

echo.
echo Starting server...
echo Admin Panel: http://localhost:3002
echo API Endpoint: http://localhost:3002/api
echo.

call npm start

pause