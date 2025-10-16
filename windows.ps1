param (
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][int]$SizeOfDir,
    [Parameter(Mandatory=$true)][int]$SizeLimit
)

$sum = 0
$m = 0
$parentDir = Split-Path -Path $Path -Parent
$backupDir = Join-Path -Path $parentDir -ChildPath "backup"

if (-not (Test-Path -Path $Path -PathType Container)) {
    Write-Output "Error: directory '$Path' does not exist."
    exit 1
}

if (-not (Test-Path -Path $backupDir -PathType Container)) {
    try {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    } catch {
        Write-Output "Cannot create backup directory: $_"
        exit 1
    }
}

$currentSize = (Get-ChildItem -Path $Path -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB
$result = [math]::Round(($currentSize * 100 / $SizeOfDir), 2)
Write-Output "The directory is $result% full"

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
    $backupFile = Join-Path -Path $backupDir -ChildPath ("backup_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".zip")

    Write-Output "Archiving $m oldest files to: $backupFile"
    try {
        $filesToArchive = $sortedFiles | Select-Object -First $m
        Compress-Archive -Path ($filesToArchive.FullName) -DestinationPath $backupFile -Force

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
