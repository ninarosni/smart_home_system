@echo off
echo Cleaning build directories...
if exist build rd /s /q build
if exist android\app\build rd /s /q android\app\build

echo Unsetting conflicting environment variables...
set ANDROID_PREFS_ROOT=

echo Running Flutter build...
flutter build apk --debug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS! The APK should be in build\app\outputs\flutter-apk\app-debug.apk
    echo To run the app, use: flutter run --use-application-binary=build\app\outputs\flutter-apk\app-debug.apk
) else (
    echo.
    echo Build failed. Please check the error logs above.
)
pause
