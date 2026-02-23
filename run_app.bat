@echo off
cd /d "%~dp0"
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr

:: Check if emulator is already running
"%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe" devices | findstr "emulator" >nul 2>nul
if %errorlevel%==0 (
    echo Emulator already running!
    goto run_app
)

echo Starting Android emulator...
start "" "%LOCALAPPDATA%\Android\sdk\emulator\emulator.exe" -avd Medium_Phone_API_36.1

echo Waiting for emulator to boot...
:wait_loop
"%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe" wait-for-device
"%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe" shell getprop sys.boot_completed 2>nul | findstr "1" >nul
if errorlevel 1 (
    timeout /t 2 /nobreak >nul
    goto wait_loop
)

:run_app
echo Emulator ready! Starting Travel Buddy Mobile...
flutter run --dart-define-from-file=.env
pause
