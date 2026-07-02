# Usage

---

**English** · [Español](#espa%C3%B1ol)

---

## English

### Command structure

```
privacity [options] <command> [args]
```

Global options must come **before** the command.

### Global options

| Option | Description |
|---|---|---|
| `-c`, `--country <name>` | Filter servers by country (e.g. `Japan`, `US`, `Korea, Republic of`) |
| `--fast` | Sort servers by lowest ping (ms) instead of highest score |
| `--protocol <type>` | Force VPN protocol: `ovpn`, `wg`, or `auto` (default) |
| `--countries` | Show all available countries (also via `privacity countries`) |
| `--profile <name>` | Isolated profile (separate config + data dirs) |
| `--log-file <path>` | Write all output to a file (tee) |
| `--verbose` | Show timestamps in output |

### Commands

#### `privacity` (daemon, default)

Connect to the best available server in background. Supports protocol auto-detection.

```
privacity
privacity -c Japan
privacity --protocol wg
privacity -c Japan --fast
```

#### `countries`

Show all available countries and their codes from the cached server list.

```
privacity countries
privacity --countries
```

If the server list hasn't been downloaded yet, it fetches it first. Useful before using `-c`.

#### `daemon`

Connect in background. No terminal interaction needed after launch.

```
privacity daemon
privacity -c Japan daemon
privacity -c Japan --fast daemon
privacity --profile work daemon
```

#### `daemon --persist`

Install a systemd user service so the VPN connects automatically after login.

```
privacity daemon --persist
```

#### `daemon --unpersist`

Remove the systemd user service.

```
privacity daemon --unpersist
```

#### `disconnect`

Tear down the current VPN connection.

```
privacity disconnect
```

#### `reconnect`

Pick the best server (optionally filtered by `-c`) and reconnect.

```
privacity reconnect
privacity -c US reconnect
```

#### `status`

Show connection details: server, country, external IP, ping, and live speed.

```
privacity status
```

#### `speedtest`

Measure download and upload speed via Cloudflare.

```
privacity speedtest
privacity -c Japan speedtest
```

#### `list`

Show the top 20 servers with score and ping (ms), and all available countries.

```
privacity list
privacity -c Korea list
privacity --fast list
```

#### `update`

Clone the latest version from GitHub and reinstall.

```
privacity update
```

#### `help`

Print the help message.

```
privacity help
```

### Profiles

Profiles isolate configuration and data. Use `--profile <name>` to create or use a profile:

```
privacity --profile personal daemon
privacity --profile work daemon
```

Each profile has its own:
- Config: `~/.config/privacity/<name>.config`
- Data dir: `~/.local/share/privacity/<name>/`

### Logging

Log all output to a file:

```
privacity --log-file /tmp/vpn.log daemon
```

Combine with `--verbose` for timestamps:

```
privacity --verbose --log-file /tmp/vpn.log daemon
```

### Country filter

The `-c` / `--country` flag works with most commands:

```
privacity -c Japan
privacity -c "Korea, Republic of" daemon
privacity -c US list
privacity -c Germany speedtest
privacity -c France reconnect
```

Country matching is case-insensitive and supports partial matches.

### Protocol selection

The `--protocol` flag controls which VPN protocol to use:

| Value | Behavior |
|---|---|
| `auto` (default) | Uses whatever protocol the server provides (openvpn or wireguard) |
| `ovpn` | Only show OpenVPN servers |
| `wg` | Only show WireGuard servers |

```
privacity --protocol wg
privacity --protocol ovpn -c Japan
privacity --fast --protocol auto
```

---

## Español

### Estructura de comandos

```
privacity [opciones] <comando> [args]
```

Las opciones globales deben ir **antes** del comando.

### Opciones globales

| Opción | Descripción |
|---|---|---|
| `-c`, `--country <nombre>` | Filtrar servidores por país (ej. `Japan`, `US`, `Korea, Republic of`) |
| `--fast` | Ordenar servidores por ping más bajo (ms) en vez de puntuación |
| `--protocol <tipo>` | Forzar protocolo VPN: `ovpn`, `wg` o `auto` (predeterminado) |
| `--countries` | Mostrar todos los países disponibles (también vía `privacity countries`) |
| `--profile <nombre>` | Perfil aislado (configuración + datos separados) |
| `--log-file <ruta>` | Escribir toda la salida a un archivo (tee) |
| `--verbose` | Mostrar marcas de tiempo en la salida |

### Comandos

#### `privacity` (daemon, predeterminado)

Conecta al mejor servidor disponible en segundo plano. Soporta detección automática de protocolo.

```
privacity
privacity -c Japan
privacity --protocol wg
privacity -c Japan --fast
```

#### `countries`

Muestra todos los países disponibles y sus códigos de la lista de servidores cacheada.

```
privacity countries
privacity --countries
```

#### `daemon`

Conectar en segundo plano. No requiere interacción con la terminal después del inicio.

```
privacity daemon
privacity -c Japan daemon
privacity -c Japan --fast daemon
privacity --profile trabajo daemon
```

#### `daemon --persist`

Instalar un servicio de usuario de systemd para que la VPN conecte automáticamente al iniciar sesión.

```
privacity daemon --persist
```

#### `daemon --unpersist`

Eliminar el servicio de systemd.

```
privacity daemon --unpersist
```

#### `disconnect`

Finalizar la conexión VPN actual.

```
privacity disconnect
```

#### `reconnect`

Elegir el mejor servidor (opcionalmente filtrado por `-c`) y reconectar.

```
privacity reconnect
privacity -c US reconnect
```

#### `status`

Mostrar detalles de la conexión: servidor, país, IP externa, ping y velocidad en vivo.

```
privacity status
```

#### `speedtest`

Medir velocidad de descarga y subida vía Cloudflare.

```
privacity speedtest
privacity -c Japan speedtest
```

#### `list`

Mostrar los 20 mejores servidores con puntuación y ping (ms), y todos los países disponibles.

```
privacity list
privacity -c Korea list
privacity --fast list
```

#### `update`

Clonar la última versión desde GitHub y reinstalar.

```
privacity update
```

#### `help`

Mostrar el mensaje de ayuda.

```
privacity help
```

### Perfiles

Los perfiles aíslan la configuración y los datos. Usa `--profile <nombre>` para crear o usar un perfil:

```
privacity --profile personal daemon
privacity --profile trabajo daemon
```

Cada perfil tiene su propio:
- Config: `~/.config/privacity/<nombre>.config`
- Directorio de datos: `~/.local/share/privacity/<nombre>/`

### Registro (logging)

Guardar toda la salida en un archivo:

```
privacity --log-file /tmp/vpn.log daemon
```

Combinar con `--verbose` para marcas de tiempo:

```
privacity --verbose --log-file /tmp/vpn.log daemon
```

### Filtro por país

La bandera `-c` / `--country` funciona con la mayoría de los comandos:

```
privacity -c Japan
privacity -c "Korea, Republic of" daemon
privacity -c US list
privacity -c Germany speedtest
privacity -c France reconnect
```

La coincidencia no distingue mayúsculas y admite coincidencias parciales.

### Selección de protocolo

La bandera `--protocol` controla qué protocolo VPN usar:

| Valor | Comportamiento |
|---|---|
| `auto` (predeterminado) | Usa el protocolo que provea el servidor (openvpn o wireguard) |
| `ovpn` | Solo mostrar servidores OpenVPN |
| `wg` | Solo mostrar servidores WireGuard |

```
privacity --protocol wg
privacity --protocol ovpn -c Japan
privacity --fast --protocol auto
```
