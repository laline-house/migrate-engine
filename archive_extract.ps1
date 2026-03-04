<#
.SYNOPSIS
    Datastrata — Extraction Archive & Manifest Script (PowerShell)

.DESCRIPTION
    Run this after dropping your CSV extracts into the archive folder.
    1. Finds all .csv files in the target folder
    2. For each file: counts rows, generates SHA-256 hash, records file size
    3. Appends results to extraction_manifest.csv in the raw_archive root
    4. Sets each CSV to read-only (immutable archive)
    5. Prints a summary table to screen

.EXAMPLE
    .\archive_extract.ps1 raw_archive\global_reference
    .\archive_extract.ps1 raw_archive\payroll\reference
    .\archive_extract.ps1 raw_archive\payroll\transactions
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$TargetFolder
)

# Resolve full path
$TargetFolder = (Resolve-Path $TargetFolder -ErrorAction Stop).Path

if (-not (Test-Path $TargetFolder -PathType Container)) {
    Write-Host "Error: '$TargetFolder' is not a valid directory." -ForegroundColor Red
    exit 1
}

# Find the raw_archive root by walking up
$archiveRoot = $TargetFolder
$parts = $TargetFolder -split [regex]::Escape([IO.Path]::DirectorySeparatorChar)
for ($i = 0; $i -lt $parts.Count; $i++) {
    if ($parts[$i] -eq "raw_archive") {
        $archiveRoot = ($parts[0..$i] -join [IO.Path]::DirectorySeparatorChar)
        break
    }
}

$manifestPath = Join-Path $archiveRoot "extraction_manifest.csv"

# Find all CSV files (not recursive, exclude manifest)
$csvFiles = Get-ChildItem -Path $TargetFolder -Filter "*.csv" -File |
    Where-Object { $_.Name -ne "extraction_manifest.csv" } |
    Sort-Object Name

if ($csvFiles.Count -eq 0) {
    Write-Host "No CSV files found in '$TargetFolder'." -ForegroundColor Yellow
    exit 0
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$extractedBy = $env:USERNAME
$relativeFolder = $TargetFolder.Substring($archiveRoot.Length + 1) -replace '\\', '/'

# Header
Write-Host ""
Write-Host ("=" * 90) -ForegroundColor DarkCyan
Write-Host "  Datastrata - Extraction Archive Script" -ForegroundColor Cyan
Write-Host "  Target folder:  $TargetFolder" -ForegroundColor Gray
Write-Host "  Manifest:       $manifestPath" -ForegroundColor Gray
Write-Host "  Timestamp:      $timestamp" -ForegroundColor Gray
Write-Host ("=" * 90) -ForegroundColor DarkCyan
Write-Host ""

# Functions
function Get-FileSHA256 {
    param([string]$FilePath)
    $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
    return $hash.Hash.ToLower()
}

function Get-CsvRowCount {
    param([string]$FilePath)
    $lineCount = 0
    $header = $null
    $reader = [System.IO.StreamReader]::new($FilePath, [System.Text.Encoding]::UTF8)
    try {
        # Read header
        $headerLine = $reader.ReadLine()
        if ($headerLine) {
            $header = ($headerLine -split ',').Count
        }
        # Count data rows
        while ($null -ne $reader.ReadLine()) {
            $lineCount++
        }
    }
    finally {
        $reader.Close()
    }
    return @{ Rows = $lineCount; Cols = $header }
}

function Get-LayerFromName {
    param([string]$FileName)
    $upper = $FileName.ToUpper()
    if ($upper.StartsWith("L0_")) { return "Layer 0" }
    elseif ($upper.StartsWith("L1_")) { return "Layer 1" }
    elseif ($upper.StartsWith("L2_")) { return "Layer 2" }
    elseif ($upper.StartsWith("L3_")) { return "Layer 3" }
    return "Unknown"
}

function Get-UvoFromName {
    param([string]$FileName)
    $name = $FileName
    if ($name -match "^L[0-3]_") {
        $name = $name.Substring(3)
    }
    return $name -replace '\.csv$', ''
}

function Format-FileSize {
    param([long]$Bytes)
    if ($Bytes -lt 1024) { return "$Bytes B" }
    elseif ($Bytes -lt 1048576) { return "{0:N1} KB" -f ($Bytes / 1024) }
    else { return "{0:N1} MB" -f ($Bytes / 1048576) }
}

# Process files
$results = @()
$writeHeader = -not (Test-Path $manifestPath)

foreach ($file in $csvFiles) {
    Write-Host "  Processing: $($file.Name)..." -NoNewline -ForegroundColor White

    $counts = Get-CsvRowCount -FilePath $file.FullName
    $hash = Get-FileSHA256 -FilePath $file.FullName
    $layer = Get-LayerFromName -FileName $file.Name
    $uvoName = Get-UvoFromName -FileName $file.Name
    $sizeStr = Format-FileSize -Bytes $file.Length

    # Set read-only
    $file.IsReadOnly = $true

    $results += [PSCustomObject]@{
        filename          = $file.Name
        uvo_name          = $uvoName
        layer             = $layer
        archive_folder    = $relativeFolder
        row_count         = $counts.Rows
        col_count         = $counts.Cols
        file_size         = $file.Length
        sha256            = $hash
        extract_timestamp = $timestamp
        extracted_by      = $extractedBy
    }

    Write-Host " $($counts.Rows.ToString('N0')) rows, $($counts.Cols) cols, $sizeStr, " -NoNewline -ForegroundColor Gray
    Write-Host "locked." -ForegroundColor Green
}

# Write to manifest
if ($writeHeader) {
    $headerLine = "filename,uvo_name,layer,archive_folder,row_count,col_count,file_size,sha256,extract_timestamp,extracted_by"
    Add-Content -Path $manifestPath -Value $headerLine -Encoding UTF8
}

foreach ($r in $results) {
    $line = "$($r.filename),$($r.uvo_name),$($r.layer),$($r.archive_folder),$($r.row_count),$($r.col_count),$($r.file_size),$($r.sha256),$($r.extract_timestamp),$($r.extracted_by)"
    Add-Content -Path $manifestPath -Value $line -Encoding UTF8
}

# Summary
$totalRows = ($results | Measure-Object -Property row_count -Sum).Sum
$totalSize = ($results | Measure-Object -Property file_size -Sum).Sum

Write-Host ""
Write-Host ("-" * 90) -ForegroundColor DarkCyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host ("-" * 90) -ForegroundColor DarkCyan
Write-Host "  Files processed:    $($results.Count)" -ForegroundColor White
Write-Host "  Total data rows:    $($totalRows.ToString('N0'))" -ForegroundColor White
Write-Host "  Total file size:    $(Format-FileSize -Bytes $totalSize)" -ForegroundColor White
Write-Host "  Manifest updated:   $manifestPath" -ForegroundColor White
Write-Host "  All files locked:   Read-only" -ForegroundColor Green
Write-Host ("-" * 90) -ForegroundColor DarkCyan
Write-Host "  Next step: Verify row counts against SynergySoft source." -ForegroundColor Yellow
Write-Host ("=" * 90) -ForegroundColor DarkCyan
Write-Host ""