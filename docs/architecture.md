# Architecture

---

**English** · [Español](#espa%C3%B1ol)

---

## English

### Code structure

```
privacity                 Entry point, option parsing, main dispatch
lib/
  common.sh               Shared functions, paths, logging, helpers
  net.sh                  Standalone network check tool
  speed.sh                Download and upload speed test
  csv.sh                  VPN Gate CSV download and parsing
  ovpn.sh                 OpenVPN lifecycle (connect, disconnect, status)
completions/
  privacity.bash          Bash completion
  privacity.zsh           Zsh completion
  privacity.1             Man page
tests/
  flow.bats               Integration tests
  privacity.bats          Unit tests
  fixtures/               Test data (CSV, OVPN configs)
```

### Entry point (`privacity`)

1. Sources all `lib/*.sh` modules
2. Parses global options (`-c`, `--profile`, `--log-file`, `--verbose`)
3. Processes config file (if `CONFIG_FILE` exists)
4. Dispatches to the appropriate `cmd_*` function

### Module: `lib/common.sh`

Provides:
- **Color constants**: `RED`, `GREEN`, `YELLOW`, `CYAN`, `BOLD`, `DIM`
- **Logging**: `log` (✓), `warn` ([!]), `error` ([x]), `info`, `dim`, `die` (fatal)
- **`_sudo()`**: Run as root directly or via `sudo`. Tries `sudo -n` first for non-interactive use.
- **`_ts()`**: Optional timestamps when `VERBOSE=true` (safe with `set -e`)
- **`run_with_spinner()`**: Run a function in the background with a progress spinner (yellow spinner → green ✓ or red ✗)
- **`notify()`**: Desktop notification via `notify-send`
- **`check_deps()`**: Verify required binaries; prompt to install missing ones
- **`load_config()`**: Read `~/.config/privacity/config`
- **`use_profile()`**: Switch config file and data dir to per-profile paths

### Module: `lib/csv.sh`

Handles all VPN Gate server list operations:

| Function | Description |
|---|---|
| `fetch_csv` | Download CSV from VPN Gate (HTTPS, fallback HTTP), cache with 5-minute TTL |
| `parse_servers <file>` | Parse CSV via python3, sort by score descending, optional country filter |
| `list_countries` | Extract unique countries from cached CSV |
| `_cache_fresh` | Check if cached CSV is within TTL |

### Module: `lib/ovpn.sh`

Manages the OpenVPN connection lifecycle:

| Function | Description |
|---|---|
| `connect_interactive <host> <port>` | Guided connection with progress UX, live dashboard, key listener |
| `connect_daemon <host> <port>` | Background connection, writes PID file |
| `cmd_disconnect` | Kill OpenVPN, remove PID file, cleanup |
| `cmd_status` | Show connection state, IP, ping, speed |
| `cmd_reconnect` | Fetch new server, disconnect existing, connect |
| `write_config <b64>` | Decode and sanitize Base64 OpenVPN config |
| `get_external_ip` | Get public IP via multiple fallback services |
| `check_internet` | Verify DNS + HTTP connectivity after tunnel is up |

### Module: `lib/net.sh`

Standalone network diagnostic tool:

```
./lib/net.sh check    # Internet connectivity check
./lib/net.sh ip       # Show external IP
./lib/net.sh ping     # Latency to Google DNS (8.8.8.8)
```

### Module: `lib/speed.sh`

Standalone speed test tool:

```
./lib/speed.sh        # Download 10 MiB + upload test
```

- Download: fetches `speed.cloudflare.com/__down` (10 MiB)
- Upload: POSTs to `nghttp2.org/anything` (measured via curl)

### Config sanitization

`write_config()` in `ovpn.sh` strips these dangerous OpenVPN directives:

- `script-security`
- `up`, `down` (and all `up-*` / `down-*` variants)
- `persist-key`
- `route-pre-down`, `route-up`, `ipchange`

It also adds `data-ciphers` if missing (ensures AES-GCM is available on modern OpenVPN).

### Connection flow

```
main()
  ├─ check_deps()
  ├─ load_config()
  ├─ parse CLI options
  └─ dispatch command
       ├─ interactive: fetch → parse → display top 3 → confirm → connect → check → speed → dashboard
       ├─ daemon:      fetch → parse → pick best → connect → check → speed → exit
       ├─ disconnect:  kill OpenVPN → cleanup files
       ├─ status:      read PID → check tun → show info
       └─ ...
```

See [flow.md](flow.md) for a visual diagram.

---

## Español

### Estructura del código

```
privacity                 Punto de entrada, análisis de opciones, despachador
lib/
  common.sh               Funciones compartidas, rutas, logging, ayudantes
  net.sh                  Herramienta independiente de verificación de red
  speed.sh                Prueba de velocidad de descarga y subida
  csv.sh                  Descarga y análisis de CSV de VPN Gate
  ovpn.sh                 Ciclo de vida de OpenVPN (conectar, desconectar, estado)
completions/
  privacity.bash          Completado para Bash
  privacity.zsh           Completado para Zsh
  privacity.1             Página man
tests/
  flow.bats               Pruebas de integración
  privacity.bats          Pruebas unitarias
  fixtures/               Datos de prueba (CSV, configuraciones OVPN)
```

### Punto de entrada (`privacity`)

1. Carga todos los módulos `lib/*.sh`
2. Analiza opciones globales (`-c`, `--profile`, `--log-file`, `--verbose`)
3. Procesa el archivo de configuración (si `CONFIG_FILE` existe)
4. Despacha a la función `cmd_*` correspondiente

### Módulo: `lib/common.sh`

Proporciona:
- **Constantes de color**: `RED`, `GREEN`, `YELLOW`, `CYAN`, `BOLD`, `DIM`
- **Logging**: `log` (✓), `warn` ([!]), `error` ([x]), `info`, `dim`, `die` (fatal)
- **`_sudo()`**: Ejecutar como root directamente o vía `sudo`. Primero intenta `sudo -n` para uso no interactivo.
- **`_ts()`**: Marcas de tiempo opcionales cuando `VERBOSE=true` (seguro con `set -e`)
- **`run_with_spinner()`**: Ejecutar una función en segundo plano con un spinner de progreso (spinner amarillo → ✓ verde o ✗ rojo)
- **`notify()`**: Notificación de escritorio vía `notify-send`
- **`check_deps()`**: Verificar binarios requeridos; preguntar para instalar los faltantes
- **`load_config()`**: Leer `~/.config/privacity/config`
- **`use_profile()`**: Cambiar archivo de configuración y directorio de datos a rutas por perfil

### Módulo: `lib/csv.sh`

Maneja todas las operaciones de la lista de servidores de VPN Gate:

| Función | Descripción |
|---|---|
| `fetch_csv` | Descargar CSV desde VPN Gate (HTTPS, fallback HTTP), cachear con TTL de 5 minutos |
| `parse_servers <archivo>` | Analizar CSV vía python3, ordenar por puntuación descendente, filtro opcional por país |
| `list_countries` | Extraer países únicos del CSV cacheado |
| `_cache_fresh` | Verificar si el CSV cacheado está dentro del TTL |

### Módulo: `lib/ovpn.sh`

Gestiona el ciclo de vida de la conexión OpenVPN:

| Función | Descripción |
|---|---|
| `connect_interactive <host> <puerto>` | Conexión guiada con progreso, panel en vivo, listener de teclas |
| `connect_daemon <host> <puerto>` | Conexión en segundo plano, escribe archivo PID |
| `cmd_disconnect` | Matar OpenVPN, eliminar archivo PID, limpiar |
| `cmd_status` | Mostrar estado de conexión, IP, ping, velocidad |
| `cmd_reconnect` | Obtener nuevo servidor, desconectar existente, conectar |
| `write_config <b64>` | Decodificar y sanitizar configuración OpenVPN en Base64 |
| `get_external_ip` | Obtener IP pública mediante múltiples servicios alternativos |
| `check_internet` | Verificar conectividad DNS + HTTP después de que el túnel esté activo |

### Módulo: `lib/net.sh`

Herramienta independiente de diagnóstico de red:

```
./lib/net.sh check    # Verificar conectividad a Internet
./lib/net.sh ip       # Mostrar IP externa
./lib/net.sh ping     # Latencia a Google DNS (8.8.8.8)
```

### Módulo: `lib/speed.sh`

Herramienta independiente de prueba de velocidad:

```
./lib/speed.sh        # Descarga 10 MiB + prueba de subida
```

- Descarga: obtiene `speed.cloudflare.com/__down` (10 MiB)
- Subida: POST a `nghttp2.org/anything` (medido vía curl)

### Sanitización de configuración

`write_config()` en `ovpn.sh` elimina estas directivas peligrosas de OpenVPN:

- `script-security`
- `up`, `down` (y todas las variantes `up-*` / `down-*`)
- `persist-key`
- `route-pre-down`, `route-up`, `ipchange`

También agrega `data-ciphers` si falta (asegura que AES-GCM esté disponible en OpenVPN moderno).

### Flujo de conexión

```
main()
  ├─ check_deps()
  ├─ load_config()
  ├─ analizar opciones CLI
  └─ despachar comando
       ├─ interactivo: descargar → analizar → mostrar top 3 → confirmar → conectar → verificar → velocidad → panel
       ├─ daemon:      descargar → analizar → elegir mejor → conectar → verificar → velocidad → salir
       ├─ disconnect:  matar OpenVPN → limpiar archivos
       ├─ status:      leer PID → verificar tun → mostrar info
       └─ ...
```

Ver [flow.md](flow.md) para un diagrama visual.
