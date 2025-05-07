# PowerShell script to find the highest version number and copy JAR files

# Get the base artifacts directory
$baseDir = ".\build_artifacts"

# Create base directory if it doesn't exist
if (!(Test-Path -Path $baseDir)) {
    New-Item -ItemType Directory -Path $baseDir | Out-Null
    Write-Host "Created base directory: $baseDir"
}

# Find the highest version number
$highestVersion = 0
if (Test-Path -Path $baseDir) {
    $directories = Get-ChildItem -Path $baseDir -Directory | Where-Object { $_.Name -match '^\d+$' }
    
    foreach ($dir in $directories) {
        $version = [int]$dir.Name
        if ($version -gt $highestVersion) {
            $highestVersion = $version
        }
    }
}

# Increment to get new version
$newVersion = $highestVersion + 1
$newDir = Join-Path -Path $baseDir -ChildPath $newVersion

# Create new directory
Write-Host "Creating directory: $newDir (Next version: $newVersion)"
if (!(Test-Path -Path $newDir)) {
    New-Item -ItemType Directory -Path $newDir | Out-Null
    Write-Host "Directory created successfully."
} else {
    Write-Host "Directory already exists. Using existing directory."
}

# Find and copy the JAR files
$jarFound = $false

# First, look for assembly JARs
$assemblyJars = Get-ChildItem -Path "target" -Recurse -Filter "*assembly*.jar" | Where-Object { $_.FullName -like "*scala-*\*" }

foreach ($jar in $assemblyJars) {
    Write-Host "Found JAR: $($jar.FullName)"
    
    # Move the file
    Write-Host "Moving `"$($jar.FullName)`" to `"$newDir`""
    try {
        Move-Item -Path $jar.FullName -Destination $newDir -Force
        Write-Host "Successfully moved file."
        $jarFound = $true
    } catch {
        Write-Host "Failed to move file. Trying to copy instead..."
        try {
            Copy-Item -Path $jar.FullName -Destination $newDir -Force
            Write-Host "Successfully copied file."
            $jarFound = $true
        } catch {
            Write-Host "Failed to copy file: $_"
        }
    }
}

# If no assembly JARs were found, look for other JARs
if (-not $jarFound) {
    $otherJars = Get-ChildItem -Path "target" -Recurse -Filter "*.jar" | 
                Where-Object { ($_.Name -notlike "*-tests.jar") -and ($_.Name -notlike "*-test.jar") }
    
    foreach ($jar in $otherJars) {
        Write-Host "Found JAR: $($jar.FullName)"
        
        # Move the file
        Write-Host "Moving `"$($jar.FullName)`" to `"$newDir`""
        try {
            Move-Item -Path $jar.FullName -Destination $newDir -Force
            Write-Host "Successfully moved file."
            $jarFound = $true
        } catch {
            Write-Host "Failed to move file. Trying to copy instead..."
            try {
                Copy-Item -Path $jar.FullName -Destination $newDir -Force
                Write-Host "Successfully copied file."
                $jarFound = $true
            } catch {
                Write-Host "Failed to copy file: $_"
            }
        }
    }
}

# Check if any JAR files were found
if ($jarFound) {
    Write-Host "JAR file(s) successfully processed to $newDir"
    Write-Host "Build artifacts stored in: $newDir"
    
    # Special output line for batch script to capture the version number
    Write-Host "BUILD_VERSION=$newVersion"
    
    exit 0
} else {
    Write-Host "JAR build failed. No JAR files found."
    exit 1
}
