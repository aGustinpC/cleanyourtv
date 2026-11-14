# Mi TV Hisense: sin bloatware y con un inicio estilo Apple TV

Configuración completa de un **Hisense "SmartTV 4K FFM"** (placa `wutaishan`, MediaTek, Google TV / Android 14,
firmware `UKN6.251123.001.049`), hecha con [cleanyourtv](https://github.com/Gathin23/cleanyourtv). Esta rama es un
fork: todo el proyecto original está intacto, y lo propio está en esta carpeta `mi-tv/` y en unos cambios al
launcher (abajo).

La base es [`examples/hisense-u7-wutaishan`](../examples/hisense-u7-wutaishan/), que es la misma placa y el mismo
firmware. **Nada se desinstala**: todo se desactiva y se puede volver atrás.

## Qué hace

**Limpieza** (`debloat/`, en tandas):

| Lista | Qué desactiva |
|---|---|
| `01-rastreo.txt` | Reconocimiento de lo que ves (Vtp_ACR), rastreo y autoinstalaciones de socios de Google, envío de errores, calendario |
| `02-hisense.txt` | VIDAA, pestaña Hisense, Family Moment, modos tienda y hotel, "limpiador", HiAlexa, DLNA, cámara IA, navegador Hisense |
| `03-streaming.txt` | Paramount+, Tubi, PrendeTV, YouTube Music, Play Juegos (las que no se usan en esta casa) |
| `04-funciones.txt` | "Ok Google", Chromecast, duplicar pantalla |
| `05-setupwraith.txt` | El asistente de configuración de Google TV, que si no le gana el inicio al launcher |

Se conservan las actualizaciones OTA, TV en vivo/HDMI, entradas, control remoto, teclado, Play Store y salvapantallas.
Google Assistant (`com.google.android.katniss`) **no se puede desactivar en este firmware**: el TV lo reactiva en cada
arranque (comprobado en dos reinicios), así que está comentado en `04-funciones.txt`.

**Inicio nuevo** (`tema/config.json` + el launcher de cleanyourtv con dos opciones propias):

- Todas las apps en **una fila** que se desplaza de lado, con banda de cristal (`single_row`, `dock_band_all`).
- La app enfocada muestra su **nombre en grande, en letra gruesa y del color principal de la app** (`hero_title_art`).
- Al abrir una app, su ventana **crece desde el icono**, como en macOS (`app_open_zoom`).
- **Fondos en blanco y negro** que cambian cada hora, oscurecidos un 35 %, siempre visibles (sin difuminado).
- Fuente **Space Grotesk** en todo el launcher.
- Botones de arriba solo con icono, sin saludo.
- Botones **YouTube, Disney+, Prime Video y Configuración** del control funcionando sin Google TV.

**Extra**: DNS privado de AdGuard (bloquea anuncios y rastreadores; no los de YouTube).

## Cómo aplicarlo

Requisitos en el PC (Windows): [adb](https://developer.android.com/tools/releases/platform-tools), Python 3, JDK 17 y
el Android SDK (plataforma 34, build-tools 34.0.0). Desde la raíz del repositorio:

```powershell
python -m venv tools\venv
tools\venv\Scripts\pip install -r tools\requirements.txt
```

En el TV: Ajustes → Preferencias del dispositivo → Información → pulsa 7 veces "Compilación". Luego, en Opciones de
desarrollador, activa **Depuración inalámbrica**. En este modelo la depuración USB sola no abre el puerto 5555.

1. **Vincular** el PC: Depuración inalámbrica → "Vincular dispositivo con código", y
   `adb pair <ip>:<puerto de vinculación> <código>`. Después `adb connect <ip>:<puerto>` con el puerto de la pantalla
   principal. Ese puerto cambia cada vez que se activa la depuración.
2. **Copia de seguridad**: guarda `pm list packages -f`, `getprop` y `settings list global|secure|system` en `backup/`.
3. **Limpieza**, una tanda cada vez, mirando el TV entre tandas:
   ```powershell
   $env:TV_ADB_BINARY = 'adb'; $env:TV_HOST = '<ip>:<puerto>'
   powershell -ExecutionPolicy Bypass -File tools\disable.ps1 mi-tv\debloat\01-rastreo.txt
   ```
   Antes de `05-setupwraith.txt`, **olvida la red Wi-Fi y vuelve a unirte desde Ajustes** (lee la cabecera del archivo).
4. **Launcher y tema**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File mi-tv\scripts\instalar-launcher.ps1 -Tv <ip>:<puerto>
   ```
   La primera vez, quita `-StockLauncher none` del script, para que el instalador desactive Google TV
   (`com.google.android.apps.tv.launcherx`) después de comprobar que el launcher nuevo es el inicio.
5. **Fondos** (opcional): ver abajo.
6. **DNS** (opcional): `adb shell settings put global private_dns_specifier dns.adguard-dns.com` y
   `adb shell settings put global private_dns_mode hostname`. No lo pongas si tu router ya filtra (Pi-hole, AdGuard
   Home, VPN).
7. **Al terminar, apaga la depuración**: revoca las autorizaciones, apaga Depuración inalámbrica y Depuración USB, y
   reinicia.

## Cambios al launcher

Están en `launcher/` de esta rama; con `git diff` contra `main` se ven todos:

- `AppColours.java` (nuevo): saca el color principal del logo de una app. Agrupa los píxeles vivos por tono y gana el
  tono que más ocupa, con un mínimo del 3 %. Si el logo no tiene ninguno, usa su gris o blanco. Los colores oscuros se
  aclaran para que el nombre se lea sobre el fondo.
- `hero_title_art` (`Config.java`, `MainActivity.java`, `config.xml`): el nombre grande de la app enfocada en letra
  gruesa y de su color.
- `app_open_zoom` (`AppAdapter.java`): abre las apps con `ActivityOptions.makeScaleUpAnimation` desde el icono.
- `fonts.xml` + `res/font/spacegrotesk*`: Space Grotesk en lugar de Outfit.

Las dos opciones están **apagadas por defecto**; el tema las enciende. Con la fuente nueva el APK pasa del límite de
576 KB que el proyecto original pone a sus contribuciones. En el TV no importa.

## Botones del control

Sin Google TV, el sistema de Hisense (`com.vt.tv.smartsense`) intercepta YouTube, Disney+ y Prime Video y le pide a
Google TV que abra la app, así que no pasa nada. Lo mismo ocurre con el engranaje. Los atiende el servicio de
accesibilidad del launcher (`HomeKeyService`, "Botón Inicio") con estos códigos en el tema:

| Botón | Keycode | Scancode |
|---|---|---|
| YouTube | 190 | 469 |
| Disney+ | 1562 | 418 |
| Prime Video | 1503 | 468 |
| Configuración (engranaje) | 83 | 598 |
| Perfil | 288 | 600 (sin uso) |

Con `InputKeyService` no funcionaba en este TV; con `HomeKeyService` sí.

**Precio**: con el servicio filtrando teclas, mantener pulsado el volumen sube de uno en uno en vez de forma continua.
Para recuperarlo, a cambio de esos botones, pon `"key_filter": false` en el tema.

## Ordenar las apps

Desde el TV, sin PC: mantén **OK** sobre una app → **Mover** → flechas → **Atrás**. Para varias, mantén **OK** sobre el
engranaje → **Reordenar apps**. Si vuelves a subir el tema, el orden puede volver al de `dock_apps`.

## Fondos

Son 23 wallpapers en blanco y negro de **Wallpaper Engine** (Steam Workshop), listados en `fondos/lista.txt`. **No
están en el repositorio**, porque son obras de sus autores. Suscríbete a ellos en Steam y regenéralos:

```powershell
winget install Gyan.FFmpeg
tools\venv\Scripts\pip install pillow
powershell -ExecutionPolicy Bypass -File mi-tv\fondos\sacar-fondos.ps1 -RePKG C:\ruta\a\RePKG.exe
powershell -ExecutionPolicy Bypass -File mi-tv\scripts\instalar-launcher.ps1 -Tv <ip>:<puerto> -SoloTema
```

[RePKG](https://github.com/notscuffed/repkg) abre los `scene.pkg`. De los de video se toma un fotograma. Todos se
recortan a 1920×1080 y se pasan a gris. `fondos/buscar-byn.py` es la herramienta que encontró los que casi no tienen
color. Como el launcher no reproduce video de fondo, en el TV se ven como imagen fija.

## Deshacerlo

```powershell
powershell -ExecutionPolicy Bypass -File mi-tv\scripts\restaurar-tv.ps1 -Tv <ip>:<puerto>                   # todo
powershell -ExecutionPolicy Bypass -File mi-tv\scripts\restaurar-tv.ps1 -Tv <ip>:<puerto> -QuitarLauncher    # y el launcher
powershell -ExecutionPolicy Bypass -File mi-tv\scripts\restaurar-tv.ps1 -Tv <ip>:<puerto> -Paquete <paquete> # uno solo
```

Paquetes útiles: Chromecast `com.google.android.apps.mediashell`, AirPlay `com.google.android.tungsten.setupwraith`
(con él activo Google TV recupera el inicio), Paramount+ `com.cbs.ca`, Tubi `com.tubitv`. Para quitar solo el DNS:
`adb shell settings put global private_dns_mode opportunistic`.

## Créditos y licencias

- [cleanyourtv](https://github.com/Gathin23/cleanyourtv), de Gathin23: licencia MIT (`LICENSE`).
- Space Grotesk, de Florian Karsten: SIL Open Font License (`launcher/FONT-LICENSE-SPACEGROTESK-OFL.txt`).
- Los fondos pertenecen a sus autores del Steam Workshop y no se distribuyen aquí.
