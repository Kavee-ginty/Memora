@echo off
setlocal

set "TEMP=%~dp0.tmp\gradle"
set "TMP=%TEMP%"
if not exist "%TEMP%" mkdir "%TEMP%"

set "ENV_FILE=%~dp0.env"
if not exist "%ENV_FILE%" (
  echo Missing %ENV_FILE%
  goto :failed
)

for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
  if "%%A"=="MEMORA_SUPABASE_URL" set "MEMORA_SUPABASE_URL=%%B"
  if "%%A"=="MEMORA_SUPABASE_PUBLISHABLE_KEY" set "MEMORA_SUPABASE_PUBLISHABLE_KEY=%%B"
)

if not defined MEMORA_SUPABASE_URL (
  echo MEMORA_SUPABASE_URL is missing from %ENV_FILE%
  goto :failed
)
if not defined MEMORA_SUPABASE_PUBLISHABLE_KEY (
  echo MEMORA_SUPABASE_PUBLISHABLE_KEY is missing from %ENV_FILE%
  goto :failed
)

cd /d "%~dp0mobile"
call flutter build apk --debug ^
  --dart-define="MEMORA_SUPABASE_URL=%MEMORA_SUPABASE_URL%" ^
  --dart-define="MEMORA_SUPABASE_PUBLISHABLE_KEY=%MEMORA_SUPABASE_PUBLISHABLE_KEY%" ^
  --dart-define="MEMORA_API_BASE_URL=http://127.0.0.1:8000" ^
  --dart-define="MEMORA_OAUTH_REDIRECT_URI=com.kaveeginty.memora://login-callback"
if errorlevel 1 goto :failed

copy /y "build\app\outputs\flutter-apk\app-debug.apk" "build\app\outputs\flutter-apk\Memora.apk" >nul
if errorlevel 1 goto :failed

echo.
echo Built: %CD%\build\app\outputs\flutter-apk\Memora.apk
pause
exit /b 0

:failed
echo.
echo Memora APK build failed.
pause
exit /b 1
