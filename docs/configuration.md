# Configuration

---

**English** · [Español](#espa%C3%B1ol)

---

## English

### Config file

`privacity` reads `~/.config/privacity/config` if it exists. The format is simple `KEY=VALUE` (spaces around `=` are allowed):

```
# Preferred country
country = Japan

# Default mode: "daemon" or "interactive"
mode = daemon

# Sort by lowest ping instead of score
fast = true
```

Blank lines and lines starting with `#` are ignored.

### Supported keys

| Key | Values | Description |
|---|---|---|
| `country` | Any VPN Gate country name | Default country filter |
| `mode` | `daemon` | Default command when none given |
| `fast` | `true` or `false` | Sort servers by lowest ping instead of score |
| `protocol` | `ovpn`, `wg`, or `auto` | Default VPN protocol |

### Precedence

CLI flags override config file values:

1. CLI flag (`-c Japan`) → highest priority
2. Config file (`country = Japan`) → medium priority
3. Built-in default (no filter) → lowest priority

### Profiles

Use `--profile <name>` to isolate config and data:

```
privacity --profile work daemon
privacity --profile personal daemon
```

Each profile uses:

| Aspect | Default | With `--profile <name>` |
|---|---|---|
| Config file | `~/.config/privacity/config` | `~/.config/privacity/<name>.config` |
| Data dir | `~/.local/share/privacity/` | `~/.local/share/privacity/<name>/` |

Profiles are independent — changing one does not affect the other. If a profile's config file does not exist, it is silently ignored.

### Directory layout

```
~/.config/privacity/
  config              Global configuration (KEY=VALUE)
  work.config         Profile "work" configuration
  personal.config     Profile "personal" configuration

~/.local/share/privacity/
  servers.csv         Cached server list (5 minute TTL)
  active.ovpn         Sanitized OpenVPN config
  privacity.pid       PID of background OpenVPN process
  last_host           Last connected server hostname + country
  openvpn.log         OpenVPN daemon log
  wireguard.conf       WireGuard config (if previously connected via WG)

~/.local/share/privacity/work/
  ...same structure as above, but for the "work" profile
```

### Systemd service

When you run `privacity daemon --persist`, it installs a systemd user service at:

```
~/.config/systemd/user/privacity.service
```

The service is enabled and started immediately. It runs the daemon with the configured country and mode. To remove:

```
privacity daemon --unpersist
```

---

## Español

### Archivo de configuración

`privacity` lee `~/.config/privacity/config` si existe. El formato es `CLAVE=VALOR` (los espacios alrededor de `=` están permitidos):

```
# País preferido
country = Japan

# Modo predeterminado: "daemon" o "interactive"
mode = daemon

# Ordenar por ping más bajo en vez de puntuación
fast = true
```

Las líneas en blanco y las que comienzan con `#` se ignoran.

### Claves soportadas

| Clave | Valores | Descripción |
|---|---|---|
| `country` | Cualquier país de VPN Gate | Filtro de país predeterminado |
| `mode` | `daemon` | Comando predeterminado cuando no se especifica ninguno |
| `fast` | `true` o `false` | Ordenar servidores por ping más bajo en vez de puntuación |
| `protocol` | `ovpn`, `wg` o `auto` | Protocolo VPN predeterminado |

### Prioridad

Las banderas de CLI sobrescriben los valores del archivo de configuración:

1. Banderas CLI (`-c Japan`) → prioridad más alta
2. Archivo de configuración (`country = Japan`) → prioridad media
3. Valor predeterminado (sin filtro) → prioridad más baja

### Perfiles

Usa `--profile <nombre>` para aislar configuración y datos:

```
privacity --profile trabajo daemon
privacity --profile personal daemon
```

Cada perfil usa:

| Aspecto | Predeterminado | Con `--profile <nombre>` |
|---|---|---|
| Archivo de config | `~/.config/privacity/config` | `~/.config/privacity/<nombre>.config` |
| Directorio de datos | `~/.local/share/privacity/` | `~/.local/share/privacity/<nombre>/` |

Los perfiles son independientes — cambiar uno no afecta al otro. Si el archivo de configuración de un perfil no existe, se ignora silenciosamente.

### Estructura de directorios

```
~/.config/privacity/
  config              Configuración global (CLAVE=VALOR)
  trabajo.config      Configuración del perfil "trabajo"
  personal.config     Configuración del perfil "personal"

~/.local/share/privacity/
  servers.csv         Lista de servidores cacheada (TTL 5 min)
  active.ovpn         Configuración OpenVPN sanitizada
  privacity.pid       PID del proceso OpenVPN en segundo plano
  last_host           Último servidor conectado + país
  openvpn.log         Bitácora del daemon OpenVPN
  wireguard.conf       Configuración WireGuard (si se conectó vía WG)

~/.local/share/privacity/trabajo/
  ...misma estructura que arriba, pero para el perfil "trabajo"
```

### Servicio systemd

Cuando ejecutas `privacity daemon --persist`, se instala un servicio de usuario de systemd en:

```
~/.config/systemd/user/privacity.service
```

El servicio se habilita e inicia inmediatamente. Ejecuta el daemon con el país y modo configurados. Para eliminar:

```
privacity daemon --unpersist
```
