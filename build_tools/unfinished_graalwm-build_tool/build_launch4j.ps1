# PowerShell script to run Launch4j and create an executable with bundled JRE

$baseDir = $PSScriptRoot
$launch4jDir = Join-Path -Path $baseDir -ChildPath "build_tools\launch4j"
$launch4jExe = Join-Path -Path $launch4jDir -ChildPath "launch4jc.exe"
$configFile = Join-Path -Path $baseDir -ChildPath "launch4j_config.xml"
$targetDir = Join-Path -Path $baseDir -ChildPath "build_artifacts\19"
$jarFile = Join-Path -Path $targetDir -ChildPath "aether-flow-example-game-assembly-0.1.0-SNAPSHOT.jar"
$outputExe = Join-Path -Path $targetDir -ChildPath "game_launch4j.exe"

# Verify required files and directories exist
Write-Host "Verifying files and directories..."

if (-not (Test-Path -Path $launch4jExe)) {
    Write-Host "ERROR: Launch4j executable not found at: $launch4jExe" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $configFile)) {
    Write-Host "ERROR: Launch4j configuration file not found at: $configFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $jarFile)) {
    Write-Host "ERROR: JAR file not found at: $jarFile" -ForegroundColor Red
    exit 1
}

$jrePath = Join-Path -Path $baseDir -ChildPath "build_tools\jre"
if (-not (Test-Path -Path $jrePath)) {
    Write-Host "ERROR: JRE directory not found at: $jrePath" -ForegroundColor Red
    exit 1
}

# Run Launch4j
Write-Host "Running Launch4j to create executable with bundled JRE..."
Write-Host "Configuration file: $configFile"
Write-Host "Input JAR: $jarFile"
Write-Host "Output EXE: $outputExe"
Write-Host "Bundled JRE: $jrePath"

$process = Start-Process -FilePath $launch4jExe -ArgumentList $configFile -NoNewWindow -PassThru -Wait
$exitCode = $process.ExitCode

if ($exitCode -eq 0) {
    if (Test-Path -Path $outputExe) {
        Write-Host "SUCCESS: Created executable at: $outputExe" -ForegroundColor Green
        Write-Host "The executable includes a bundled JRE from: $jrePath"
        Write-Host "You can now run the application by executing: $outputExe"
    } else {
        Write-Host "WARNING: Launch4j reported success but the executable was not found at: $outputExe" -ForegroundColor Yellow
    }
} else {
    Write-Host "ERROR: Launch4j failed with exit code: $exitCode" -ForegroundColor Red
    Write-Host "Check the Launch4j configuration file for errors."
}
