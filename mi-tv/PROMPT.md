# Prompt: replicar la configuración de `mi-tv/`

Pega esto en Claude Code (o en otra IA de programación con acceso a la terminal) en un PC conectado a la misma red
que el TV, con este repositorio clonado y abierto como carpeta de trabajo:

> Sigue `mi-tv/PROMPT.md` para replicar en mi TV la configuración de `mi-tv/`.

Antes, en el TV: Ajustes → Preferencias del dispositivo → Información → pulsa OK 7 veces sobre "Compilación". Luego,
en Opciones de desarrollador, activa **Depuración inalámbrica** (y Depuración USB si aparece). Deja el TV encendido.

---

## Instrucciones para la IA

Vas a replicar en el TV de esta persona la configuración documentada en `mi-tv/README.md`. **Léelo entero antes de
empezar.** Las reglas de seguridad de [`PROMPT.md`](../PROMPT.md) y [`AGENTS.md`](../AGENTS.md) siguen valiendo y
mandan sobre todo lo de aquí. Si algo de este archivo choca con ellas, gana `PROMPT.md`. Habla con la persona en
español.

### 1. Comprobar que es el mismo TV

- Conecta por ADB como dice `PROMPT.md`. En este modelo solo funciona la Depuración inalámbrica: pide el código y el
  puerto de "Vincular dispositivo con código", haz `adb pair` y luego `adb connect` con el puerto de la pantalla
  principal. Para los scripts del repo usa `TV_ADB_BINARY` (ver `tools/native-adb.md`).
- Lee `getprop ro.product.device`, `ro.build.display.id` y `ro.build.version.sdk`.
  - Si es **`wutaishan` con `UKN6.251123.001.049`**, las listas de `mi-tv/debloat/` y los códigos de botones del tema
    valen tal cual.
  - Si es **otro modelo u otro firmware**, díselo a la persona. Busca su carpeta en `examples/` y sigue el
    procedimiento general de `PROMPT.md`; usa `mi-tv/` solo como referencia de diseño. No apliques las listas a
    ciegas: comprueba cada paquete con `pm list packages` y `dumpsys package`.
- Si no es Android TV / Google TV, para y sigue lo que dice `PROMPT.md` para ese caso.

### 2. Copia de seguridad

Haz la de `PROMPT.md`: paquetes, `getprop` y ajustes en `backup/`. Anota también quién es el dueño de la red Wi-Fi:
`dumpsys wifi | grep -o 'cname=[^ ]*'`.

### 3. Preguntas a la persona (todas juntas, en un checklist)

Sus gustos no son los de la persona que hizo `mi-tv/`:

- **Apps de streaming**: qué apps usa. Ajusta `mi-tv/debloat/03-streaming.txt` para quitar solo las que no use, y
  `dock_apps` en `mi-tv/tema/config.json` con las suyas y en su orden.
- **Funciones** (`04-funciones.txt`): si usa Chromecast, duplicar pantalla o "Ok Google". Comenta las líneas de lo
  que quiera conservar. Google Assistant (`katniss`) no se puede desactivar en este firmware: díselo.
- **AirPlay**: si lo usa (iPhone, iPad o Mac), **no** se puede tener el launcher. Haz solo la limpieza, sin
  `05-setupwraith.txt`.
- **Botones del control** contra **volumen continuo**: con los botones YouTube, Disney+, Prime y Configuración
  activos, mantener el volumen pulsado sube de uno en uno. Que elija. Si prefiere el volumen, pon
  `"key_filter": false` en el tema.
- **DNS de AdGuard**: si lo quiere, y si su router ya filtra (Pi-hole, AdGuard Home, VPN). En ese caso no lo pongas.
- **Fondos**: si tiene Wallpaper Engine con los fondos de `mi-tv/fondos/lista.txt`, si quiere otros, o ninguno.
- Qué tiene conectado a los USB del TV.

### 4. Limpieza

- Aplica `mi-tv/debloat/01` a `04` **de una en una** con `tools\disable.ps1` (o `tools/disable.sh`). Haz una captura
  (`tools/tv.py --screenshot`) después de cada tanda y mírala.
- `05-setupwraith.txt` va **solo si quiere el launcher**, y antes: si la red Wi-Fi pertenece a setupwraith, pídele que
  **olvide la red y vuelva a unirse** desde Ajustes. Comprueba que el `cname` pasó a `android.uid.system:1000`.
  Si no, el TV pierde el Wi-Fi y tú la conexión.
- Espera unos 15 s, reinicia y compara `pm list packages -d` con lo aplicado. Tras el reinicio la Depuración
  inalámbrica se apaga y cambia de puerto: pídele que la vuelva a activar y que te diga el puerto nuevo.

### 5. Launcher

- Comprueba que hay JDK 17 y Android SDK (plataforma 34, build-tools 34.0.0). Si faltan, pide permiso antes de
  instalarlos.
- **Primera instalación**, para que el instalador desactive Google TV solo después de comprobar que el launcher nuevo
  es el inicio:
  ```powershell
  powershell -ExecutionPolicy Bypass -File launcher\build-and-install.ps1 -TvHost <ip>:<puerto> -HomeKeyService
  ```
  Confirma con `dumpsys activity activities | grep mFocusedApp`.
- Sube el tema: `mi-tv\scripts\instalar-launcher.ps1 -Tv <ip>:<puerto> -SoloTema`. Las siguientes reinstalaciones
  ya pueden usar ese script sin `-SoloTema`.
- **Fondos** (si los quiere): `mi-tv\fondos\sacar-fondos.ps1`. Necesita ffmpeg y RePKG; pide permiso antes de
  descargar y ejecutar RePKG. Luego vuelve a subir el tema con `-SoloTema`. Sin fondos, borra de
  `mi-tv/tema/config.json` las claves `wallpaper*` o pon `"wallpaper": false`.
- Revisa con capturas: la fila de apps, el título en color y el menú de Entradas. La animación de apertura no sale en
  las capturas.

### 6. Botones del control

Pídele que pulse con el **control de verdad** (una pulsación simulada por ADB no demuestra nada): YouTube, Disney+,
Prime Video, el engranaje, Netflix, Input y Home. Si alguno no responde, lee los códigos en
`logcat | grep interceptKeyTq` mientras lo pulsa y ajusta `app_keys` y `settings_key_keycodes` en el tema. En este TV
solo funciona con `HomeKeyService`, no con `InputKeyService` (está en `mi-tv/README.md`).

### 7. DNS (si lo quiso)

`settings put global private_dns_specifier dns.adguard-dns.com` y `settings put global private_dns_mode hostname`.
Comprueba que una app reproduce.

### 8. Cerrar

Haz exactamente lo que dice `PROMPT.md`:

1. Que revoque las autorizaciones de depuración USB.
2. Que apague la Depuración inalámbrica. Comprueba su puerto con `tools/adb-closed.py`.
3. Que apague la Depuración USB y reinicie. Comprueba el 5555 con `tools/adb-closed.py`.

Déjale escrito cómo deshacerlo: `mi-tv\scripts\restaurar-tv.ps1` y la sección "Deshacerlo" de `mi-tv/README.md`.
