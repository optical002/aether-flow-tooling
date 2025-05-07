@echo off
setlocal enabledelayedexpansion

echo Running sbt clean assembly...
".\build_tools\git\git-bash.exe" sbt clean assembly

echo Using PowerShell to handle versioning and file copying...

:: Capture PowerShell output to get the version number
for /f "tokens=1,* delims==" %%a in ('powershell.exe -ExecutionPolicy Bypass -File "build_utils.ps1"') do (
    if "%%a"=="BUILD_VERSION" (
        set BUILD_VERSION=%%b
    )
)

if %errorlevel% neq 0 (
    echo PowerShell script failed with error code %errorlevel%
    exit /b %errorlevel%
)

:: Echo the version number for use by other processes
echo.
echo Latest build version is: !BUILD_VERSION!
echo.

:: Automatically build native executable
echo Building native executable with GraalVM...

set "BASE_DIR=%~dp0"
set "NEW_DIR=%BASE_DIR%build_artifacts\!BUILD_VERSION!"
set "BUILD_TOOLS_DIR=%BASE_DIR%build_tools"
set "GRAALVM_DIR=%BUILD_TOOLS_DIR%\graalvm"

:: Dynamically find the JAR file in the build directory
set "JAR_FILE="
for /f "delims=" %%i in ('dir /b "!NEW_DIR!\*assembly*.jar" 2^>nul') do (
    set "JAR_FILE=!NEW_DIR!\%%i"
    echo Found JAR file: !JAR_FILE!
)

:: If no assembly JAR found, try to find any JAR file
if "!JAR_FILE!"=="" (
    for /f "delims=" %%i in ('dir /b "!NEW_DIR!\*.jar" 2^>nul') do (
        set "JAR_FILE=!NEW_DIR!\%%i"
        echo Found JAR file: !JAR_FILE!
    )
)

:: Check if JAR file exists
if "!JAR_FILE!"=="" (
    echo ERROR: No JAR file found in !NEW_DIR!
    exit /b 1
)

:: Run the native image build in a separate script
echo Running GraalVM native image build in a separate process...
call "%BASE_DIR%build_native.bat" "%BASE_DIR%" "!NEW_DIR!" "!JAR_FILE!" "%BUILD_TOOLS_DIR%" "%GRAALVM_DIR%"

:: Check directly if the executable exists (most reliable method)
if exist "!NEW_DIR!\game.exe" (
    echo Confirmed executable exists at !NEW_DIR!\game.exe
    
    :: Copy all resources from build_tools/resources directory
    if exist "%BUILD_TOOLS_DIR%\resources" (
        echo Copying resources from %BUILD_TOOLS_DIR%\resources to !NEW_DIR!
        xcopy /Y /E /I "%BUILD_TOOLS_DIR%\resources\*" "!NEW_DIR!\" >nul
        echo Successfully copied resources.
    ) else (
        echo No resources directory found at %BUILD_TOOLS_DIR%\resources
    )
    echo.
    echo =====================================================
    echo Build complete! Native executable created successfully.
    echo Executable location: !NEW_DIR!\game.exe
    echo All resources copied to the same directory.
    echo =====================================================
) else (
    echo.
    echo =====================================================
    echo Native image build failed or executable was not created.
    echo Expected location: !NEW_DIR!\game.exe
    echo =====================================================
)

echo.
echo Build process complete.
echo JAR file location: build_artifacts\!BUILD_VERSION!\aether-flow-example-game-assembly-0.1.0-SNAPSHOT.jar

endlocal