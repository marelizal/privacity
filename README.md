# privacity

![tests](https://github.com/marelizal/privacity/actions/workflows/test.yml/badge.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

---

**English** · [Español](#español)

---

## English

CLI tool that fetches the fastest public [VPN Gate](https://www.vpngate.net/) servers and connects via OpenVPN — interactive or daemon mode.

### Features

- 🔒 Sanitizes OpenVPN configs (strips `script-security`, `up`, `down`, `persist-key`, etc.)
- 🌐 Internet health check after connect (DNS + HTTP connectivity)
- ⚡ Download + upload speed test
- 🔔 Desktop notifications on connect/disconnect/fail
- 🗂️ Multi-profile: `privacity --profile work daemon`
- 📝 Log to file with `--log-file <path>` + `--verbose` timestamps
- 🌍 Country filter: `privacity -c Japan daemon`
- ⚙️ Config file: `~/.config/privacity/config` (country, mode)
- 💤 Systemd persist: `privacity daemon --persist`
- 🧪 24 bats tests — `shellcheck` clean (0 warnings)

### Quick start

```bash
git clone https://github.com/marelizal/privacity.git
cd privacity
sudo make install
sudo make completions
privacity
```

### Install

```bash
sudo make install          # /usr/local/bin/ + man page + lib/
sudo make completions      # bash/zsh completion
make hooks                 # pre-commit (shellcheck + bats)
```

### Usage

```bash
privacity                        # Interactive guided mode
privacity daemon                 # Connect in background (no terminal)
privacity disconnect             # Tear down current VPN
privacity reconnect              # Pick best server and reconnect
privacity status                 # Show connection info and live speed
privacity speedtest              # Download + upload speed test
privacity update                 # Pull latest version and reinstall
privacity list                   # Show top 10 servers + available countries
privacity help                   # Show help

# Options (place before command)
privacity -c Japan daemon          # Filter by country
privacity --profile work daemon    # Isolated config + data per profile
privacity --log-file /tmp/vpn.log daemon
privacity --verbose daemon
privacity daemon --persist         # Install systemd user service
privacity daemon --unpersist       # Remove systemd user service
```

### Config file

`~/.config/privacity/config` — simple `KEY=VALUE` format:

```
# Preferred country (any VPN Gate country name)
country = Japan

# Default mode (daemon or interactive)
mode = daemon
```

CLI flags override config values. Per-profile configs via `--profile`:
`~/.config/privacity/<profile>.config`

### Requirements

| Runtime | Dev / testing |
|---|---|
| `openvpn`, `wget`, `curl` | `shellcheck`, `bats` |
| `base64` (coreutils), `sudo` | `python3` (CSV parsing) |
| `notify-send` (optional) | — |

### How it works

1. Downloads server list from VPN Gate (HTTPS, fallback HTTP)
2. Parses CSV with python3 `csv` module — handles quoted commas in country names
3. Selects highest-score server (optionally filtered by country)
4. Decodes Base64 OpenVPN config, strips dangerous directives
5. Connects via OpenVPN with `--cd "$DIR"` and `chmod 700` on data dir
6. Verifies internet: DNS (`google.com` via `8.8.8.8`) + HTTP (204 check)
7. Measures download speed via Cloudflare, upload speed via nghttp2
8. Interactive mode: live RX/TX speed, IP, ping, location
9. Press `Q` to disconnect, `S` to switch server

### Directory layout

```
~/.local/share/privacity/
  servers.csv       Cached server list (5 min TTL)
  active.ovpn       Sanitized OpenVPN config
  privacity.pid     PID of background OpenVPN
  last_host         Last connected server hostname
  openvpn.log       OpenVPN daemon log
```

Per-profile data lives in `~/.local/share/privacity/<profile>/`

### Development

```bash
# Syntax & lint
bash -n privacity lib/*.sh
shellcheck -S warning -s bash privacity lib/*.sh

# Tests
sudo apt install bats
bats tests/*.bats

# Standalone tools (for debugging)
./lib/net.sh check
./lib/speed.sh

# Pre-commit hook (auto-runs on git commit)
make hooks
```

---

## Español

Herramienta CLI que obtiene los servidores públicos más rápidos de [VPN Gate](https://www.vpngate.net/) y se conecta vía OpenVPN — modo interactivo o daemon.

### Características

- 🔒 Sanitiza configuraciones OpenVPN (elimina `script-security`, `up`, `down`, `persist-key`, etc.)
- 🌐 Verifica conectividad a Internet después de conectar (DNS + HTTP)
- ⚡ Prueba de velocidad de descarga y subida
- 🔔 Notificaciones de escritorio al conectar/desconectar/fallar
- 🗂️ Multi-perfil: `privacity --profile trabajo daemon`
- 📝 Log a archivo con `--log-file <ruta>` + marcas de tiempo con `--verbose`
- 🌍 Filtro por país: `privacity -c Japon daemon`
- ⚙️ Archivo de configuración: `~/.config/privacity/config` (país, modo)
- 💤 Persistencia systemd: `privacity daemon --persist`
- 🧪 24 pruebas bats — `shellcheck` limpio (0 advertencias)

### Inicio rápido

```bash
git clone https://github.com/marelizal/privacity.git
cd privacity
sudo make install
sudo make completions
privacity
```

### Instalación

```bash
sudo make install          # /usr/local/bin/ + página man + lib/
sudo make completions      # completado bash/zsh
make hooks                 # gancho pre-commit (shellcheck + bats)
```

### Uso

```bash
privacity                        # Modo interactivo guiado
privacity daemon                 # Conectar en segundo plano (sin terminal)
privacity disconnect             # Desconectar VPN actual
privacity reconnect              # Elegir mejor servidor y reconectar
privacity status                 # Mostrar info de conexión y velocidad
privacity speedtest              # Prueba de velocidad (descarga + subida)
privacity update                 # Obtener última versión y reinstalar
privacity list                   # Mostrar top 10 servidores + países
privacity help                   # Mostrar ayuda

# Opciones (antes del comando)
privacity -c Japon daemon          # Filtrar por país
privacity --profile trabajo daemon # Datos y config aislados por perfil
privacity --log-file /tmp/vpn.log daemon
privacity --verbose daemon
privacity daemon --persist         # Instalar servicio systemd de usuario
privacity daemon --unpersist       # Eliminar servicio systemd de usuario
```

### Archivo de configuración

`~/.config/privacity/config` — formato simple `CLAVE=VALOR`:

```
# País preferido (cualquier país de VPN Gate)
country = Japan

# Modo por defecto (daemon o interactivo)
mode = daemon
```

Las banderas de CLI sobrescriben los valores del archivo. Config por perfil vía `--profile`:
`~/.config/privacity/<perfil>.config`

### Requisitos

| Ejecución | Dev / pruebas |
|---|---|
| `openvpn`, `wget`, `curl` | `shellcheck`, `bats` |
| `base64` (coreutils), `sudo` | `python3` (análisis CSV) |
| `notify-send` (opcional) | — |

### Cómo funciona

1. Descarga lista de servidores desde VPN Gate (HTTPS, fallback HTTP)
2. Analiza el CSV con el módulo `csv` de python3 — maneja comillas en nombres de país
3. Selecciona el servidor con mayor puntuación (opcionalmente filtrado por país)
4. Decodifica la configuración OpenVPN en Base64, elimina directivas peligrosas
5. Conecta vía OpenVPN con `--cd "$DIR"` y `chmod 700` en el directorio de datos
6. Verifica Internet: DNS (`google.com` vía `8.8.8.8`) + HTTP (código 204)
7. Mide velocidad de descarga vía Cloudflare, subida vía nghttp2
8. Modo interactivo: velocidad RX/TX en vivo, IP, ping, ubicación
9. Presiona `Q` para desconectar, `S` para cambiar de servidor

### Estructura de directorios

```
~/.local/share/privacity/
  servers.csv       Lista de servidores cacheados (TTL 5 min)
  active.ovpn       Configuración OpenVPN sanitizada
  privacity.pid     PID de OpenVPN en segundo plano
  last_host         Último servidor conectado
  openvpn.log       Bitácora del daemon OpenVPN
```

Los datos por perfil están en `~/.local/share/privacity/<perfil>/`

### Desarrollo

```bash
# Sintaxis y lint
bash -n privacity lib/*.sh
shellcheck -S warning -s bash privacity lib/*.sh

# Pruebas
sudo apt install bats
bats tests/*.bats

# Herramientas independientes (para depuración)
./lib/net.sh check
./lib/speed.sh

# Gancho pre-commit (se ejecuta automáticamente en git commit)
make hooks
```

---

## License / Licencia

GPL v3 — see [LICENSE](LICENSE)
