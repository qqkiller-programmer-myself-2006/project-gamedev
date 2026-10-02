param (
    [string]$InputFile,
    [string]$OutputFile
)

if (-not $InputFile -or -not $OutputFile) {
    Write-Host "Usage: .\convert_to_ogv.ps1 -InputFile <path_to_mp4> -OutputFile <path_to_ogv>"
    exit 1
}

if (-not (Test-Path $InputFile)) {
    Write-Host "Error: Input file '$InputFile' does not exist."
    exit 1
}

$outputDir = Split-Path $OutputFile -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

Write-Host "Converting $InputFile to $OutputFile using libtheora..."
ffmpeg -y -i $InputFile -c:v libtheora -q:v 7 -c:a libvorbis -q:a 4 -vf "scale=1280:720,fps=30" $OutputFile
