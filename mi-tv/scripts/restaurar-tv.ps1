# Deshace todo lo hecho en el TV Hisense (wutaishan): reactiva cada paquete de las listas mi-tv\debloat\0*.txt,
# devuelve Home a Google TV y quita el DNS de AdGuard. Nada se desinstaló, así que todo vuelve tal cual.
#
# Uso (desde la raíz del repositorio, con Depuración inalámbrica activa y el PC ya vinculado):
#   powershell -ExecutionPolicy Bypass -File mi-tv\scripts\restaurar-tv.ps1 -Tv 192.168.1.50:41234
#   ... -Paquete com.google.android.apps.mediashell   reactiva solo ese paquete
#   ... -QuitarLauncher                                 además desinstala el launcher (com.gathin.tvhome)
# -Tv es la IP y el puerto de la pantalla principal de Depuración inalámbrica. $env:ADB puede apuntar a adb.exe.
param(
    [Parameter(Mandatory = $true)][string]$Tv,
    [string]$Paquete = '',
    [switch]$QuitarLauncher
)
$adb = if ($env:ADB) { $env:ADB } else { 'adb' }
& $adb connect $Tv | Out-Host
$s = @('-s', $Tv)

if ($Paquete) {
    & $adb @s shell pm enable --user 0 $Paquete
    return
}

# El orden importa: primero Google TV, para que Home tenga dueño antes de tocar nada más.
& $adb @s shell pm enable --user 0 com.google.android.apps.tv.launcherx
& $adb @s shell cmd package set-home-activity --user 0 com.google.android.apps.tv.launcherx/.home.HomeActivity

$listas = Get-ChildItem (Join-Path $PSScriptRoot '..\debloat\0*.txt') | Sort-Object Name
foreach ($lista in $listas) {
    foreach ($linea in Get-Content $lista.FullName) {
        $pkg = ($linea -replace '#.*', '').Trim()
        if ($pkg) { & $adb @s shell pm enable --user 0 $pkg }   # uno por llamada, como pide PROMPT.md
    }
}

& $adb @s shell settings put global private_dns_mode opportunistic

if ($QuitarLauncher) { & $adb @s shell pm uninstall com.gathin.tvhome }

Write-Host "`nPaquetes que siguen desactivados:"
& $adb @s shell pm list packages -d
Write-Host "Home ahora:"
& $adb @s shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
