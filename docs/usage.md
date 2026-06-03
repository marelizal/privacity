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
|---|---|
| `-c`, `--country <name>` | Filter servers by country (e.g. `Japan`, `US`, `Korea, Republic of`) |
| `--profile <name>` | Isolated profile (separate config + data dirs) |
| `--log-file <path>` | Write all output to a file (tee) |
| `--verbose` | Show timestamps in output |

### Commands

#### `privacity` (interactive, default)

Guided mode. Shows the top 3 servers, asks for confirmation, connects, and displays a live dashboard with speed, IP, and ping.

Controls during connection:
- **Q** — Disconnect and exit
- **S** — Disconnect and switch to the next best server

```
privacity
privacity -c Japan
```

#### `daemon`

Connect in background. No terminal interaction needed after launch.

```
privacity daemon
privacity -c Japan daemon
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

Show the top 10 servers by score and all available countries.

```
privacity list
privacity -c Korea list
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

---

## Español

### Estructura de comandos

```
privacity [opciones] <comando> [args]
```

Las opciones globales deben ir **antes** del comando.

### Opciones globales

| Opción | Descripción |
|---|---|
| `-c`, `--country <nombre>` | Filtrar servidores por país (ej. `Japan`, `US`, `Korea, Republic of`) |
| `--profile <nombre>` | Perfil aislado (configuración + datos separados) |
| `--log-file <ruta>` | Escribir toda la salida a un archivo (tee) |
| `--verbose` | Mostrar marcas de tiempo en la salida |

### Comandos

#### `privacity` (interactivo, predeterminado)

Modo guiado. Muestra los 3 mejores servidores, pide confirmación, conecta y muestra un panel en vivo con velocidad, IP y ping.

Controles durante la conexión:
- **Q** — Desconectar y salir
- **S** — Desconectar y cambiar al siguiente mejor servidor

```
privacity
privacity -c Japan
```

#### `daemon`

Conectar en segundo plano. No requiere interacción con la terminal después del inicio.

```
privacity daemon
privacity -c Japan daemon
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

Mostrar los 10 mejores servidores por puntuación y todos los países disponibles.

```
privacity list
privacity -c Korea list
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
