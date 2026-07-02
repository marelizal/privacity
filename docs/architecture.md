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
  csv.sh                  Server list fetch from providers, pipe-delimited parsing
  ovpn.sh                 OpenVPN lifecycle (connect, disconnect, status)
  wg.sh                   WireGuard lifecycle (connect, disconnect, config write)
  providers/
    vpngate.sh            VPN Gate provider — downloads CSV → pipe format
    vpnbook.sh            VPNBook provider — scrapes RSC payload → 40 entries
completions/
  privacity.bash          Bash completion
  privacity.zsh           Zsh completion
  privacity.1             Man page
tests/
  flow.bats               Integration tests
  privacity.bats          Unit tests
  fixtures/               Test data (pipe-delimited, OVPN configs)
```

### Entry point (`privacity`)

1. Sources all `lib/*.sh` modules plus any scripts in `lib/providers/`
2. Parses global options (`-c`, `--profile`, `--log-file`, `--verbose`, `--protocol`)
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

Orchestrates all providers and parses the unified server list:

| Function | Description |
|---|---|
| `fetch_servers` | Calls all provider `provider_*_fetch()` functions, concatenates `.db` files into `servers.csv` |
| `parse_servers <file>` | Parse pipe-delimited format, sort by score descending, optional country filter + protocol filter |
| `list_countries <file>` | Extract unique countries from parsed server list |
| `_cache_fresh <file>` | Check if cached file is within TTL |

### Provider scripts (`lib/providers/`)

Each provider is a standalone script exposing `provider_*_fetch()`. Sourced automatically via `"$LIB_DIR"/providers/*.sh`.

| Script | Provider | Entries | Protocols | Method |
|---|---|---|---|---|
| `vpngate.sh` | VPN Gate | ~150+ | OpenVPN | Downloads public CSV, converts to pipe format |
| `vpnbook.sh` | VPNBook | 40 (10 servers × 4 ports) | OpenVPN + WireGuard | Scrapes Next.js RSC payload, generates configs with embedded CA/cert/key |

Provider priority (`PROVIDER_<NAME>_PRIORITY`): VPN Gate = 50, VPNBook = 30 (lower = less preferred). During `fetch_servers()`, all `.db` files are concatenated; `parse_servers()` sorts by score/ping regardless of source.

### Module: `lib/ovpn.sh`

Manages the OpenVPN connection lifecycle:

| Function | Description |
|---|---|
| `connect_daemon <entry>` | Background connection, writes PID file |
| `cmd_disconnect` | Kill OpenVPN (or WireGuard), remove PID/config, cleanup, restore network |
| `cmd_status` | Show connection state, IP, ping, speed |
| `cmd_reconnect` | Fetch new server, disconnect existing, connect |
| `write_config <b64>` | Decode and sanitize Base64 OpenVPN config |
| `get_external_ip` | Get public IP via multiple fallback services |
| `check_internet` | Verify DNS + HTTP connectivity after tunnel is up |

### Module: `lib/wg.sh`

Manages the WireGuard connection lifecycle:

| Function | Description |
|---|---|
| `connect_wireguard <entry>` | Decode and write WireGuard config, bring up via `wg-quick` |
| `disconnect_wireguard` | Bring down `wg-privacity` interface |
| `write_wg_config <b64>` | Decode Base64 WireGuard config, strip dangerous directives (PreUp/PostUp/PreDown/PostDown) |

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

`write_config()` in `ovpn.sh` strips these dangerous OpenVPN directives; `write_wg_config()` in `wg.sh` strips PreUp/PostUp/PreDown/PostDown:

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
       ├─ daemon:       fetch (all providers) → parse (pipe format) → pick best → connect_tunnel (wg|ovpn) → check → speed → exit
       ├─ disconnect:   kill OpenVPN / bring down WG → cleanup files
       ├─ status:       read PID/tun/wg → show info
       └─ ...

connect_tunnel(entry)
  ├─ protocol=wg   → connect_wireguard (write_wg_config → wg-quick up)
  ├─ protocol=ovpn → connect_daemon (write_config → openvpn --daemon)
  └─ unknown       → die
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
  csv.sh                  Obtención de lista de servidores de proveedores, análisis pipe-delimited
  ovpn.sh                 Ciclo de vida de OpenVPN (conectar, desconectar, estado)
  wg.sh                   Ciclo de vida de WireGuard (conectar, desconectar, escribir config)
  providers/
    vpngate.sh            Proveedor VPN Gate — descarga CSV → formato pipe
    vpnbook.sh            Proveedor VPNBook — extrae RSC → 40 entradas
completions/
  privacity.bash          Completado para Bash
  privacity.zsh           Completado para Zsh
  privacity.1             Página man
tests/
  flow.bats               Pruebas de integración
  privacity.bats          Pruebas unitarias
  fixtures/               Datos de prueba (pipe-delimited, configs OVPN)
```

### Punto de entrada (`privacity`)

1. Carga todos los módulos `lib/*.sh` más los scripts en `lib/providers/`
2. Analiza opciones globales (`-c`, `--profile`, `--log-file`, `--verbose`, `--protocol`)
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

Orquesta todos los proveedores y analiza la lista de servidores unificada:

| Función | Descripción |
|---|---|
| `fetch_servers` | Llama a todas las funciones `provider_*_fetch()`, concatena archivos `.db` en `servers.csv` |
| `parse_servers <archivo>` | Analiza formato pipe-delimited, ordena por puntuación, filtro opcional por país + protocolo |
| `list_countries <archivo>` | Extraer países únicos de la lista de servidores analizada |
| `_cache_fresh <archivo>` | Verificar si el archivo cacheado está dentro del TTL |

### Scripts de proveedores (`lib/providers/`)

Cada proveedor es un script independiente que expone `provider_*_fetch()`. Se carga automáticamente vía `"$LIB_DIR"/providers/*.sh`.

| Script | Proveedor | Entradas | Protocolos | Método |
|---|---|---|---|---|
| `vpngate.sh` | VPN Gate | ~150+ | OpenVPN | Descarga CSV público, convierte a formato pipe |
| `vpnbook.sh` | VPNBook | 40 (10 servidores × 4 puertos) | OpenVPN + WireGuard | Extrae RSC de Next.js, genera configs con CA/cert/key embebidos |

Prioridad de proveedor (`PROVIDER_<NAME>_PRIORITY`): VPN Gate = 50, VPNBook = 30 (menor = menos preferido). Durante `fetch_servers()`, todos los `.db` se concatenan; `parse_servers()` ordena por score/ping sin importar la fuente.

### Módulo: `lib/ovpn.sh`

Gestiona el ciclo de vida de la conexión OpenVPN:

| Función | Descripción |
|---|---|
| `connect_daemon <entrada>` | Conexión en segundo plano, escribe archivo PID |
| `cmd_disconnect` | Matar OpenVPN (o WireGuard), eliminar PID/config, limpiar, restaurar red |
| `cmd_status` | Mostrar estado de conexión, IP, ping, velocidad |
| `cmd_reconnect` | Obtener nuevo servidor, desconectar existente, conectar |
| `write_config <b64>` | Decodificar y sanitizar configuración OpenVPN en Base64 |
| `get_external_ip` | Obtener IP pública mediante múltiples servicios alternativos |
| `check_internet` | Verificar conectividad DNS + HTTP después de que el túnel esté activo |

### Módulo: `lib/wg.sh`

Gestiona el ciclo de vida de la conexión WireGuard:

| Función | Descripción |
|---|---|
| `connect_wireguard <entrada>` | Decodificar y escribir configuración WireGuard, activar vía `wg-quick` |
| `disconnect_wireguard` | Desactivar interfaz `wg-privacity` |
| `write_wg_config <b64>` | Decodificar configuración WireGuard Base64, eliminar directivas peligrosas (PreUp/PostUp/PreDown/PostDown) |

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

`write_config()` en `ovpn.sh` elimina estas directivas peligrosas; `write_wg_config()` en `wg.sh` elimina PreUp/PostUp/PreDown/PostDown:

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
       ├─ daemon:       fetch (todos los proveedores) → parse (formato pipe) → elegir mejor → connect_tunnel (wg|ovpn) → check → speed → exit
       ├─ disconnect:   matar OpenVPN / bajar WG → limpiar archivos
       ├─ status:       leer PID/tun/wg → mostrar info
       └─ ...

connect_tunnel(entry)
  ├─ protocol=wg   → connect_wireguard (write_wg_config → wg-quick up)
  ├─ protocol=ovpn → connect_daemon (write_config → openvpn --daemon)
  └─ unknown       → die
```

Ver [flow.md](flow.md) para un diagrama visual.
