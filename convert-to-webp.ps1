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

# pick only original JPGs (exclude those with -400 or -800 suffix)
# collect JPGs case-insensitively
$jpgFiles = Get-ChildItem $imgDir -Include "*.jpg","*.JPG" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.BaseName -notmatch '-(400|800)(?:-|$)' }
Write-Host "Found $($jpgFiles.Count) JPG files to process:" -ForegroundColor Cyan
$jpgFiles | ForEach-Object { Write-Host "  - $($_.Name)" }
if ($jpgFiles.Count -eq 0) {
    Write-Host "No original JPG files found (maybe everything is already resized)"
    exit 0
}

# detect ImageMagick and cwebp
$hasMagick = (Get-Command magick -ErrorAction SilentlyContinue) -ne $null
$hasCwebp = (Get-Command cwebp -ErrorAction SilentlyContinue) -ne $null
if (-not $hasCwebp -and -not $hasMagick) {
    Write-Host "Error: neither cwebp nor ImageMagick found.\nInstall one of them to generate WebP files."
    exit 1
}

if ($hasMagick) {
    Write-Host "ImageMagick detected; thumbnails will be generated."
    # widths in pixels for responsive srcset
    $thumbWidths = @(400, 800)
} else {
    Write-Host "ImageMagick not found; only full‑size WebP will be produced."
}

$successCount = 0
$failureCount = 0

foreach ($file in $jpgFiles) {
    $inputFile = $file.FullName
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
    $outputFile = [System.IO.Path]::ChangeExtension($inputFile, ".webp")
    
    Write-Host "Converting: $($file.Name)..." -NoNewline
    
    try {
        if ($hasCwebp) {
            & cwebp -q $quality "$inputFile" -o "$outputFile"
        } else {
            # fallback using ImageMagick
            & magick "$inputFile" -quality $quality "$outputFile"
        }
        
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

    if ($hasMagick) {
        foreach ($w in $thumbWidths) {
            $thumbJpg = Join-Path $imgDir "$baseName-$w.jpg"
            $thumbWebp = Join-Path $imgDir "$baseName-$w.webp"
            try {
                & magick "$inputFile" -resize ${w}x "$thumbJpg"
                if ($hasCwebp) {
                    & cwebp -q $quality "$thumbJpg" -o "$thumbWebp"
                } else {
                    & magick "$thumbJpg" -quality $quality "$thumbWebp"
                }
                Write-Host "    created thumb ${w}px" -ForegroundColor Yellow
            } catch {
                Write-Host "    thumb ${w}px failed: $_" -ForegroundColor Red
            }
        }
    }
}

Write-Host ""
Write-Host "Conversion complete!" -ForegroundColor Cyan
Write-Host "Successful: $successCount | Failed: $failureCount" -ForegroundColor Green
Write-Host ""
Write-Host "WebP files created in: $imgDir"
