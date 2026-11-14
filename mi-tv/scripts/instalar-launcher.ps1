# Compila el launcher, lo instala en el TV como Home y le aplica el tema de mi-tv\tema.
# Úsalo tras cambiar el código o config.xml; para cambiar solo el orden, el dock o los fondos basta -SoloTema.
#
# Uso (desde la raíz del repositorio, con Depuración inalámbrica activa y el PC ya vinculado):
#   powershell -ExecutionPolicy Bypass -File mi-tv\scripts\instalar-launcher.ps1 -Tv 192.168.1.50:41234
#   ... -SoloTema       solo vuelve a subir mi-tv\tema (orden, columnas, fondos)
# Necesita: adb (o $env:ADB con su ruta), JDK 17 en JAVA_HOME, Android SDK en ANDROID_HOME, y el entorno de
# Python del repo (python -m venv tools\venv; tools\venv\Scripts\pip install -r tools\requirements.txt).
param(
    [Parameter(Mandatory = $true)][string]$Tv,
    [switch]$SoloTema
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo
$env:TV_ADB_BINARY = if ($env:ADB) { $env:ADB } else { 'adb' }
$env:TV_HOST = $Tv
& $env:TV_ADB_BINARY connect $Tv | Out-Host

if (-not $SoloTema) {
    Remove-Item Env:SKIP_BUILD -ErrorAction SilentlyContinue
    # -HomeKeyService: los botones YouTube/Disney+/Prime/Configuración del control (app_keys y
    # settings_key_keycodes en el tema), como en examples/hisense-u75-hengshan.
    # -StockLauncher none: Google TV ya está desactivado por mi-tv\debloat, no hay que tocarlo.
    & powershell -ExecutionPolicy Bypass -File launcher\build-and-install.ps1 -TvHost $Tv -StockLauncher none -HomeKeyService
    if ($LASTEXITCODE -ne 0) { throw 'la instalación del launcher falló; mira el mensaje de arriba' }
}
& powershell -ExecutionPolicy Bypass -File tools\theme.ps1 -TvHost $Tv (Join-Path $repo 'mi-tv\tema')
