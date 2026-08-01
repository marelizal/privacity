# Usage

---

**English** · [Español](#espa%C3%B1ol)

---

## English

### Command structure

```
privacity [options] <command>
```

Global options must come **before** the command. No command = daemon mode (connect to best server in background).

### Global options

| Option | Description |
|---|---|
| `-c`, `--country <name>` | Filter servers by country (e.g. `Japan`, `US`, `Korea`) |
| `--server <host>` | Connect to a specific server (hostname or country from the list) |
| `--fast` | Sort servers by lowest ping (ms) instead of highest score |
| `--countries` | Show all available countries (also via `privacity countries`) |
| `--log-file <path>` | Write all output to a file (tee) |
| `--verbose` | Show timestamps in output |

### Commands

#### `privacity` (daemon, default)

Connect to the best available server in background. Public VPN Gate servers authenticate automatically with the shared `vpn`/`vpn` credentials — no prompt.

```
privacity
privacity -c Japan
privacity -c Japan --fast
privacity --server vpn123
```

#### `daemon`

Connect in background. No terminal interaction needed after launch.

```
privacity daemon
privacity -c Japan daemon
privacity -c Japan --fast daemon
```

#### `daemon --persist` / `daemon --unpersist`

Install / remove a systemd user service so the VPN auto-connects after login.

```
privacity daemon --persist
privacity daemon --unpersist
```

#### `--server`

Pick a specific server from the cached list, by hostname or country (case-insensitive substring). Requires a fresh server list — run `privacity list` first if the cache is empty. Combine with `-c` to narrow the match.

```
privacity list                    # find servers
privacity --server vpn123         # connect to it
privacity -c Japan --server tokyo # hostname must match within Japan
```

#### `countries`

Show all available countries. Fetches the list first if the cache is empty.

```
privacity countries
privacity --countries
```

#### `list`

Show the top 20 servers with score and ping (ms), plus available countries.

```
privacity list
privacity -c Korea list
privacity --fast list
```

#### `disconnect`

Tear down the current VPN connection.

```
privacity disconnect
```

#### `reconnect`

Pick the best server (optionally filtered by `-c`/`--server`) and reconnect.

```
privacity reconnect
privacity -c US reconnect
```

#### `status`

Show connection details: server, country, external IP, ping, and live speed.

```
privacity status
```

#### `update`

Clone the latest version from GitHub and reinstall (also installs completions).

```
privacity update
```

#### `help`

Print the help message.

```
privacity help
```

### Logging

```
privacity --log-file /tmp/vpn.log daemon
privacity --verbose --log-file /tmp/vpn.log daemon
```

### Country filter

Country matching is case-insensitive and supports partial matches.

```
privacity -c Japan
privacity -c "Korea" daemon
privacity -c US list
privacity -c France reconnect
```

---

## Español

### Estructura de comandos

```
privacity [opciones] <comando>
```

Las opciones globales deben ir **antes** del comando. Sin comando = modo demonio (conecta al mejor servidor en segundo plano).

### Opciones globales

| Opción | Descripción |
|---|---|
| `-c`, `--country <nombre>` | Filtrar servidores por país (ej. `Japan`, `US`, `Korea`) |
| `--server <host>` | Conectar a un servidor específico (hostname o país de la lista) |
| `--fast` | Ordenar servidores por ping más bajo (ms) en vez de puntuación |
| `--countries` | Mostrar todos los países disponibles (también vía `privacity countries`) |
| `--log-file <ruta>` | Escribir toda la salida a un archivo (tee) |
| `--verbose` | Mostrar marcas de tiempo en la salida |

### Comandos

#### `privacity` (demonio, predeterminado)

Conecta al mejor servidor disponible en segundo plano. Los servidores públicos de VPN Gate autentican automáticamente con las credenciales compartidas `vpn`/`vpn` — sin prompts.

```
privacity
privacity -c Japan
privacity -c Japan --fast
privacity --server vpn123
```

#### `daemon`

Conectar en segundo plano. No requiere interacción con la terminal después del inicio.

```
privacity daemon
privacity -c Japan daemon
privacity -c Japan --fast daemon
```

#### `daemon --persist` / `daemon --unpersist`

Instalar / eliminar un servicio de usuario de systemd para que la VPN conecte automáticamente al iniciar sesión.

```
privacity daemon --persist
privacity daemon --unpersist
```

#### `--server`

Elegir un servidor específico de la lista cacheada, por hostname o país (subcadena sin distinguir mayúsculas). Requiere lista fresca — corre `privacity list` primero si la caché está vacía. Combínalo con `-c` para acotar.

```
privacity list                    # buscar servidores
privacity --server vpn123         # conectar a ese
privacity -c Japan --server tokyo # el hostname debe estar en Japan
```

#### `countries`

Mostrar todos los países disponibles. Descarga la lista primero si la caché está vacía.

```
privacity countries
privacity --countries
```

#### `list`

Mostrar los 20 mejores servidores con puntuación y ping (ms), y todos los países disponibles.

```
privacity list
privacity -c Korea list
privacity --fast list
```

#### `disconnect`

Finalizar la conexión VPN actual.

```
privacity disconnect
```

#### `reconnect`

Elegir el mejor servidor (opcionalmente filtrado por `-c`/`--server`) y reconectar.

```
privacity reconnect
privacity -c US reconnect
```

#### `status`

Mostrar detalles de la conexión: servidor, país, IP externa, ping y velocidad en vivo.

```
privacity status
```

#### `update`

Clonar la última versión desde GitHub y reinstalar (también instala completions).

```
privacity update
```

#### `help`

Mostrar el mensaje de ayuda.

```
privacity help
```

### Registro (logging)

```
privacity --log-file /tmp/vpn.log daemon
privacity --verbose --log-file /tmp/vpn.log daemon
```

### Filtro por país

La coincidencia no distingue mayúsculas y admite coincidencias parciales.

```
privacity -c Japan
privacity -c "Korea" daemon
privacity -c US list
privacity -c France reconnect
```
