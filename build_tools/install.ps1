# Define required files and directories to check
$requiredItems = @{
    "build_tools directory" = "build_tools"
    "build script" = "build.ps1"
    "launch4j configuration" = "launch4j_config.xml"
}

# Check if all required items exist
$allItemsExist = $true
$missingItems = @()

foreach ($item in $requiredItems.GetEnumerator()) {
    $itemName = $item.Key
    $itemPath = $item.Value
    
    if (-not (Test-Path -Path $itemPath)) {
        $allItemsExist = $false
        $missingItems += $itemName
        Write-Host "Missing: $itemName" -ForegroundColor Yellow
    } else {
        Write-Host "Found: $itemName" -ForegroundColor Green
    }
}

# If all items exist, do nothing
if ($allItemsExist) {
    Write-Host "All required files and directories already exist. No downloads needed." -ForegroundColor Green
    exit 0
}

# Otherwise, download and extract
Write-Host "Missing required items: $($missingItems -join ', ')" -ForegroundColor Yellow
Write-Host "Downloading necessary files..." -ForegroundColor Cyan

# Define the URL of the file and the output path
$url = "https://github.com/optical002/aether-flow-tooling/releases/download/build-tools-v0.1.0/build_tools.zip"
$outputPath = ".\build_tools.zip"

# Download the file
try {
    Invoke-WebRequest -Uri $url -OutFile $outputPath
    Write-Host "Download completed successfully." -ForegroundColor Green
    
    # Check if the zip file exists
    if (Test-Path $outputPath) {
        Write-Host "Extracting files..." -ForegroundColor Cyan
        # Extract the contents of the zip file to the current directory
        Expand-Archive -Path $outputPath -DestinationPath ".\" -Force
        Write-Host "Extraction complete!" -ForegroundColor Green

        # Delete the downloaded zip file
        Remove-Item $outputPath -Force
        Write-Host "Removed the downloaded zip file." -ForegroundColor Gray
        
        # Verify the files now exist
        $stillMissing = @()
        foreach ($item in $requiredItems.GetEnumerator()) {
            $itemName = $item.Key
            $itemPath = $item.Value
            
            if (-not (Test-Path -Path $itemPath)) {
                $stillMissing += $itemName
            }
        }
        
        if ($stillMissing.Count -eq 0) {
            Write-Host "All required files and directories are now available." -ForegroundColor Green
        } else {
            Write-Host "Warning: The following items are still missing: $($stillMissing -join ', ')" -ForegroundColor Red
        }
    } else {
        Write-Host "Failed to download the file." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error downloading file: $_" -ForegroundColor Red
    exit 1
}