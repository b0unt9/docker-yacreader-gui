@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: build.bat ^<version^> [latest]
    echo Example: build.bat X.Y.Z
    echo Example: build.bat X.Y.Z latest
    exit /b 1
)

set "VERSION=%~1"
set "IS_LATEST=%~2"

for /f "tokens=1,2,3 delims=." %%a in ("%VERSION%") do (
    set "MAJOR=%%a"
    set "MINOR=%%a.%%b"
)

set "DH_IMAGE=b0unt9/yacreader-gui"
set "GHCR_IMAGE=ghcr.io/b0unt9/yacreader-gui"

set "TAGS=-t %DH_IMAGE%:%VERSION% -t %DH_IMAGE%:%MINOR% -t %DH_IMAGE%:%MAJOR%"
set "TAGS=%TAGS% -t %GHCR_IMAGE%:%VERSION% -t %GHCR_IMAGE%:%MINOR% -t %GHCR_IMAGE%:%MAJOR%"

if /i "%IS_LATEST%"=="latest" (
    set "TAGS=%TAGS% -t %DH_IMAGE%:latest -t %GHCR_IMAGE%:latest"
)

echo ===================================================
echo [Build Configuration]
echo Target Version : %VERSION%
echo Build Args     : YACREADER_VERSION=%VERSION%
echo Platforms      : linux/amd64, linux/arm64
echo Tags           : %TAGS%
echo ===================================================
echo.

docker buildx inspect builder >nul 2>&1
if errorlevel 1 (
    echo [Info] Creating new buildx instance 'builder'...
    docker buildx create --name builder --use
) else (
    docker buildx use builder
)

echo [Info] Starting multi-architecture build and push...
docker buildx build ^
  --platform linux/amd64,linux/arm64 ^
  --build-arg YACREADER_VERSION=%VERSION% ^
  %TAGS% ^
  --push
  .

if %errorlevel% neq 0 (
    echo.
    echo [Error] Build failed!
    exit /b %errorlevel%
)

echo.
echo [Success] Successfully build %DH_IMAGE%:%VERSION%