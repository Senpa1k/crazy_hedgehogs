param (
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][int]$SizeOfDir,
    [Parameter(Mandatory=$true)][int]$SizeLimit
)

# Initialize variables
$sum = 0
$m = 0

# Get parent directory and backup directory path
$parentDir = Split-Path -Path $Path -Parent
$backupDir = Join-Path -Path $parentDir -ChildPath "backup"

# Check if the directory exists
if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Output "Error: directory '$Path' does not exist."
    exit 1
}

# Create backup directory if it doesn't exist
if (-not (Test-Path -Path $backupDir -PathType Container)) {
    try {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    } catch {
        Write-Output "Cannot create backup directory: $_"
        exit 1
    }
}

# Calculate current directory size (in KB, similar to du -s)
$currentSize = (Get-ChildItem -Path $Path -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB
$result = [math]::Round(($currentSize * 100 / $SizeOfDir), 2)
Write-Output "The directory is $result% full"

# Get files sorted by creation time (oldest first)
$sortedFiles = Get-ChildItem -Path $Path | Sort-Object CreationTime

if ($result -gt $SizeLimit) {
    Write-Output "Directory exceeds size limit ($SizeLimit%). Selecting files to archive..."
    foreach ($file in $sortedFiles) {
        $fileSize = ($file.Length / 1KB)
        $result = $result - ($fileSize * 100 / $SizeOfDir)
        $m++
        if ($result -le ($SizeLimit / 1.5)) {
            break
        }
    }
} else {
    Write-Output "Directory usage is within limit."
    exit 0
}

if ($m -gt 0) {
    # Generate backup file name with timestamp
    $backupFile = Join-Path -Path $backupDir -ChildPath ("backup_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".zip")

    Write-Output "Archiving $m oldest files to: $backupFile"
    try {
        # Archive files using Compress-Archive
        $filesToArchive = $sortedFiles | Select-Object -First $m
        Compress-Archive -Path ($filesToArchive.FullName) -DestinationPath $backupFile -Force

        # Check if archive was created successfully
        if (Test-Path -Path $backupFile) {
            Write-Output "Archive created successfully. Deleting archived files..."
            foreach ($file in ($filesToArchive)) {
                Remove-Item -Path $file.FullName -Recurse -Force
            }
            Write-Output "Deleted $m old files."
        } else {
            Write-Output "Error: failed to create archive. Files will not be deleted."
            exit 1
        }
    } catch {
        Write-Output "Error: failed to create archive: $_ Files will not be deleted."
        exit 1
    }
} else {
    Write-Output "No files selected for archiving."
}

Write-Output "Cleanup completed successfully."
exit 0
