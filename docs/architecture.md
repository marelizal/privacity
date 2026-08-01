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
  csv.sh                  Server list fetch, pipe-delimited parsing
  ovpn.sh                 OpenVPN lifecycle (connect, disconnect, status)
  providers/
    vpngate.sh            VPN Gate provider — downloads CSV → pipe format
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
2. Parses global options (`-c`, `--server`, `--fast`, `--log-file`, `--verbose`)
3. Dispatches to the appropriate `cmd_*` function

### Module: `lib/common.sh`

Provides:
- **Color constants**: `RED`, `GREEN`, `YELLOW`, `CYAN`, `BOLD`, `DIM`
- **Logging**: `log` (✓), `warn` ([!]), `error` ([x]), `info`, `dim`, `die` (fatal)
- **`_sudo()`**: Run as root directly or via `sudo`. Tries `sudo -n` first for non-interactive use.
- **`_ts()`**: Optional timestamps when `VERBOSE=true` (safe with `set -e`)
- **`run_with_spinner()`**: Run a function in the background with a progress spinner (yellow spinner → green ✓ or red ✗)
- **`notify()`**: Desktop notification via `notify-send`
- **`check_deps()`**: Verify required binaries; auto-install missing ones via apt

### Module: `lib/csv.sh`

Orchestrates the provider and parses the unified server list:

| Function | Description |
|---|---|
| `fetch_servers` | Calls all provider `provider_*_fetch()` functions, concatenates `.db` files into `servers.csv` |
| `parse_servers <file>` | Parse pipe-delimited format, sort by score descending (or ping with `--fast`), optional country filter |
| `pick_entry` | Pick the server to connect: explicit `--server` match, else best of the list |
| `find_server_entry` | Match a server by hostname or country (case-insensitive substring) |
| `list_countries <file>` | Extract unique countries from parsed server list |
| `_cache_fresh <file>` | Check if cached file is within TTL |

### Provider scripts (`lib/providers/`)

Each provider is a standalone script exposing `provider_*_fetch()`. Sourced automatically via `"$LIB_DIR"/providers/*.sh`.

| Script | Provider | Entries | Protocol | Method |
|---|---|---|---|---|
| `vpngate.sh` | VPN Gate | ~150+ | OpenVPN | Downloads public CSV, converts to pipe format with shared `vpn:vpn` auth |

### Module: `lib/ovpn.sh`

Manages the OpenVPN connection lifecycle:

| Function | Description |
|---|---|
| `connect_daemon <entry>` | Background connection, injects credentials (`auth.txt` + `--auth-user-pass`), writes PID file |
| `cmd_disconnect` | Kill OpenVPN, remove PID/config/auth, cleanup tunnel, restore network |
| `cmd_status` | Show connection state, IP, ping, speed |
| `cmd_reconnect` | Pick new server, disconnect existing, connect |
| `write_config <b64>` | Decode and sanitize Base64 OpenVPN config |
| `_set_tunnel_dns` | Force DNS through the tunnel (`resolvectl dns tun0 1.1.1.1`) |
| `_verify_ip_change` | Warn if the external IP didn't change after connect (possible leak) |
| `get_external_ip` | Get public IP via multiple fallback services |
| `check_internet` | Verify DNS + HTTP connectivity after tunnel is up |

### Module: `lib/net.sh`

Standalone network diagnostic tool:

```
./lib/net.sh check    # Internet connectivity check
./lib/net.sh ip       # Show external IP
./lib/net.sh ping     # Latency to Google DNS (8.8.8.8)
```

### Config sanitization

`write_config()` in `ovpn.sh` strips these dangerous OpenVPN directives:

- `script-security`
- `up`, `down` (and all `up-*` / `down-*` variants)
- `persist-key`
- `route-pre-down`, `route-up`, `ipchange`

It also adds `data-ciphers` if missing (ensures AES-GCM is available on modern OpenVPN).

### Connection hardening

`write_config()` appends leak-prevention directives that are safe to force:

- `remote-cert-tls server` — reject servers without a server-class certificate (MITM protection)
- `tls-version-min 1.2` — no legacy TLS
- `ifconfig-ipv6` + `redirect-gateway ipv6` + `block-ipv6` — blackhole IPv6 (VPN Gate is IPv4-only) when OpenVPN ≥ 2.5

After the tunnel is up, `connect_daemon`:

- forces DNS through the tunnel (`_set_tunnel_dns`: `resolvectl dns tun0 1.1.1.1`, `domain tun0 ~.`)
- verifies the external IP changed from the pre-connect value (`_verify_ip_change`) and warns on a leak

### Connection flow

```
main()
  ├─ check_deps()
  ├─ parse CLI options
  └─ dispatch command
       ├─ daemon:       fetch (vpngate) → parse (pipe format) → pick best → connect_daemon → check → exit
       ├─ disconnect:   kill OpenVPN → cleanup files
       ├─ status:       read PID/tun → show info
       └─ ...

connect_tunnel(entry)
  └─ connect_daemon (write_config → auth.txt + openvpn --daemon)
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
  csv.sh                  Obtención de lista de servidores, análisis pipe-delimited
  ovpn.sh                 Ciclo de vida de OpenVPN (conectar, desconectar, estado)
  providers/
    vpngate.sh            Proveedor VPN Gate — descarga CSV → formato pipe
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
2. Analiza opciones globales (`-c`, `--server`, `--fast`, `--log-file`, `--verbose`)
3. Despacha a la función `cmd_*` correspondiente

### Módulo: `lib/common.sh`

Proporciona:
- **Constantes de color**: `RED`, `GREEN`, `YELLOW`, `CYAN`, `BOLD`, `DIM`
- **Logging**: `log` (✓), `warn` ([!]), `error` ([x]), `info`, `dim`, `die` (fatal)
- **`_sudo()`**: Ejecutar como root directamente o vía `sudo`. Primero intenta `sudo -n` para uso no interactivo.
- **`_ts()`**: Marcas de tiempo opcionales cuando `VERBOSE=true` (seguro con `set -e`)
- **`run_with_spinner()`**: Ejecutar una función en segundo plano con un spinner de progreso (spinner amarillo → ✓ verde o ✗ rojo)
- **`notify()`**: Notificación de escritorio vía `notify-send`
- **`check_deps()`**: Verificar binarios requeridos; auto-instalar los faltantes vía apt

### Módulo: `lib/csv.sh`

Orquesta el proveedor y analiza la lista de servidores unificada:

| Función | Descripción |
|---|---|
| `fetch_servers` | Llama a las funciones `provider_*_fetch()`, concatena archivos `.db` en `servers.csv` |
| `parse_servers <archivo>` | Analiza formato pipe-delimited, ordena por puntuación (o ping con `--fast`), filtro opcional por país |
| `pick_entry` | Elegir el servidor a conectar: coincidencia `--server` explícita, si no el mejor de la lista |
| `find_server_entry` | Coincidir servidor por hostname o país (subcadena sin distinguir mayúsculas) |
| `list_countries <archivo>` | Extraer países únicos de la lista de servidores analizada |
| `_cache_fresh <archivo>` | Verificar si el archivo cacheado está dentro del TTL |

### Scripts de proveedores (`lib/providers/`)

Cada proveedor es un script independiente que expone `provider_*_fetch()`. Se carga automáticamente vía `"$LIB_DIR"/providers/*.sh`.

| Script | Proveedor | Entradas | Protocolo | Método |
|---|---|---|---|---|
| `vpngate.sh` | VPN Gate | ~150+ | OpenVPN | Descarga CSV público, convierte a formato pipe con auth compartida `vpn:vpn` |

### Módulo: `lib/ovpn.sh`

Gestiona el ciclo de vida de la conexión OpenVPN:

| Función | Descripción |
|---|---|
| `connect_daemon <entrada>` | Conexión en segundo plano, inyecta credenciales (`auth.txt` + `--auth-user-pass`), escribe archivo PID |
| `cmd_disconnect` | Matar OpenVPN, eliminar PID/config/auth, limpiar tunel, restaurar red |
| `cmd_status` | Mostrar estado de conexión, IP, ping, velocidad |
| `cmd_reconnect` | Elegir nuevo servidor, desconectar existente, conectar |
| `write_config <b64>` | Decodificar y sanitizar configuración OpenVPN en Base64 |
| `_set_tunnel_dns` | Forzar DNS por el túnel (`resolvectl dns tun0 1.1.1.1`) |
| `_verify_ip_change` | Avisar si la IP externa no cambió tras conectar (posible fuga) |
| `get_external_ip` | Obtener IP pública mediante múltiples servicios alternativos |
| `check_internet` | Verificar conectividad DNS + HTTP después de que el túnel esté activo |

### Módulo: `lib/net.sh`

Herramienta independiente de diagnóstico de red:

```
./lib/net.sh check    # Verificar conectividad a Internet
./lib/net.sh ip       # Mostrar IP externa
./lib/net.sh ping     # Latencia a Google DNS (8.8.8.8)
```

### Sanitización de configuración

`write_config()` en `ovpn.sh` elimina estas directivas peligrosas:

- `script-security`
- `up`, `down` (y todas las variantes `up-*` / `down-*`)
- `persist-key`
- `route-pre-down`, `route-up`, `ipchange`

También agrega `data-ciphers` si falta (asegura que AES-GCM esté disponible en OpenVPN moderno).

### Endurecimiento de la conexión

`write_config()` agrega directivas de prevención de fugas que son seguras de forzar:

- `remote-cert-tls server` — rechaza servidores sin certificado de tipo servidor (protección contra MITM)
- `tls-version-min 1.2` — sin TLS obsoleto
- `ifconfig-ipv6` + `redirect-gateway ipv6` + `block-ipv6` — bloquea IPv6 (VPN Gate es solo IPv4) cuando OpenVPN ≥ 2.5

Después de que el túnel esté activo, `connect_daemon`:

- fuerza DNS por el túnel (`_set_tunnel_dns`: `resolvectl dns tun0 1.1.1.1`, `domain tun0 ~.`)
- verifica que la IP externa cambió respecto al valor previo (`_verify_ip_change`) y avisa ante una fuga

### Flujo de conexión

```
main()
  ├─ check_deps()
  ├─ analizar opciones CLI
  └─ despachar comando
       ├─ daemon:       fetch (vpngate) → parse (formato pipe) → elegir mejor → connect_daemon → check → exit
       ├─ disconnect:   matar OpenVPN → limpiar archivos
       ├─ status:       leer PID/tun → mostrar info
       └─ ...

connect_tunnel(entry)
  └─ connect_daemon (write_config → auth.txt + openvpn --daemon)
```

Ver [flow.md](flow.md) para un diagrama visual.
