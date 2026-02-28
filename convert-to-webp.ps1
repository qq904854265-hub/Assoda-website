# Batch convert JPG to WebP using cwebp
# Quality: 80 (good balance between file size and visual quality)

$imgDir = "f:\MyAssoda\ASSODA-website\img"
$quality = 80

if (-not (Test-Path $imgDir)) {
    Write-Host "Error: img directory not found at $imgDir"
    exit 1
}

Write-Host "Converting JPG files to WebP..." 
Write-Host "Quality: $quality"
Write-Host "Input directory: $imgDir"
Write-Host ""

$jpgFiles = Get-ChildItem $imgDir -Filter "*.JPG" -ErrorAction SilentlyContinue
if ($jpgFiles.Count -eq 0) {
    Write-Host "No JPG files found"
    exit 0
}

$successCount = 0
$failureCount = 0

foreach ($file in $jpgFiles) {
    $inputFile = $file.FullName
    $outputFile = [System.IO.Path]::ChangeExtension($file.FullName, ".webp")
    
    Write-Host "Converting: $($file.Name)..." -NoNewline
    
    try {
        & cwebp -q $quality "$inputFile" -o "$outputFile"
        
        if (Test-Path $outputFile) {
            $jpgSize = $file.Length / 1024
            $webpSize = (Get-Item $outputFile).Length / 1024
            $savings = [Math]::Round(((1 - $webpSize / $jpgSize) * 100), 1)
            Write-Host " OK (saved $savings%)" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host " FAILED" -ForegroundColor Red
            $failureCount++
        }
    } catch {
        Write-Host " ERROR: $_" -ForegroundColor Red
        $failureCount++
    }
}

Write-Host ""
Write-Host "Conversion complete!" -ForegroundColor Cyan
Write-Host "Successful: $successCount | Failed: $failureCount" -ForegroundColor Green
Write-Host ""
Write-Host "WebP files created in: $imgDir"
