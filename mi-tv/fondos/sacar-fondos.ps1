# Regenera los fondos del tema a partir de los wallpapers de Wallpaper Engine de lista.txt:
#   - video:  un fotograma a los 3 s con ffmpeg
#   - escena: la imagen horizontal más grande de su scene.pkg, extraída con RePKG
# y los deja en mi-tv\tema\wallpapers recortados a 16:9, en 1920x1080 y en escala de grises.
#
# Uso (desde la raíz del repositorio):
#   powershell -ExecutionPolicy Bypass -File mi-tv\fondos\sacar-fondos.ps1 -RePKG C:\ruta\RePKG.exe
# Necesita ffmpeg en el PATH (winget install Gyan.FFmpeg), RePKG (github.com/notscuffed/repkg) y el entorno de
# Python del repo con Pillow (tools\venv\Scripts\pip install pillow).
param(
    [Parameter(Mandatory = $true)][string]$RePKG,
    [string]$Workshop = 'C:\Program Files (x86)\Steam\steamapps\workshop\content\431960'
)
$ErrorActionPreference = 'Stop'
$aqui = $PSScriptRoot
$repo = (Resolve-Path (Join-Path $aqui '..\..')).Path
$py = Join-Path $repo 'tools\venv\Scripts\python.exe'
$raw = Join-Path $aqui 'raw'
$escenas = Join-Path $aqui 'escenas'
$fotogramas = Join-Path $aqui 'fotogramas'
New-Item -ItemType Directory -Force $raw, $escenas, $fotogramas | Out-Null

foreach ($linea in Get-Content (Join-Path $aqui 'lista.txt') -Encoding UTF8) {
    if ($linea -match '^\s*#' -or $linea -notmatch '^\s*(\d+)\s+(video|escena)') { continue }
    $id, $tipo = $Matches[1], $Matches[2]
    $dir = Join-Path $Workshop $id
    if (-not (Test-Path $dir)) { Write-Warning "$id no está en $Workshop (¿suscrito en Steam?)"; continue }
    if ($tipo -eq 'video') {
        $mp4 = Get-ChildItem $dir -Filter *.mp4 | Select-Object -First 1
        & ffmpeg -hide_banner -loglevel error -y -ss 3 -i $mp4.FullName -frames:v 1 -q:v 2 (Join-Path $fotogramas "$id.jpg")
    } else {
        & $RePKG extract -o (Join-Path $raw $id) (Join-Path $dir 'scene.pkg') *> $null
    }
}
& $py -I -X utf8 -W ignore (Join-Path $aqui 'elegir.py') $raw $escenas
$destino = Join-Path $repo 'mi-tv\tema\wallpapers'
& $py -I -W ignore (Join-Path $aqui 'preparar.py') $escenas $destino
& $py -I -W ignore (Join-Path $aqui 'preparar.py') $fotogramas $destino
Write-Host "Fondos listos en $destino. Súbelos con mi-tv\scripts\instalar-launcher.ps1 -SoloTema."
