# privacity

![tests](https://github.com/marelizal/privacity/actions/workflows/test.yml/badge.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
<a href='https://cafecito.app/marelizal' rel='noopener' target='_blank'><img srcset='https://cdn.cafecito.app/imgs/buttons/button_1.png 1x, https://cdn.cafecito.app/imgs/buttons/button_1_2x.png 2x, https://cdn.cafecito.app/imgs/buttons/button_1_3.75x.png 3.75x' src='https://cdn.cafecito.app/imgs/buttons/button_1.png' alt='Invitame un café en cafecito.app' /></a>

---

**English** · [Español](#espa%C3%B1ol) · [Documentation](docs/index.md)

---

## English

CLI tool that finds the fastest public VPN servers from multiple providers (**VPN Gate**, **VPNBook**) and connects via **OpenVPN** or **WireGuard**.

### Features

- 🔒 Sanitizes OpenVPN configs (strips `script-security`, `up`, `down`, `persist-key`, etc.)
- 🔀 Multi-provider: VPN Gate + VPNBook, unified server list
- 📡 WireGuard support (wg-quick) + OpenVPN
- ⚡ Auto-protocol selection or manual `--protocol ovpn|wg|auto`
- 🌐 Internet health check after connect (DNS + HTTP)
- ⚡ Download + upload speed test
- 🔔 Desktop notifications on connect/disconnect/fail
- 🗂️ Multi-profile: `privacity --profile work daemon`
- 📝 Log to file with `--log-file <path>` + `--verbose` timestamps
- 🌍 Country filter: `privacity -c Japan`
- ⚙️ Config file: `~/.config/privacity/config` (country, mode, fast, protocol)
- ⚡ Low-latency sort: `privacity --fast` (sort by ping instead of score)
- 📋 List countries: `privacity --countries`
- 💤 Systemd persist: `privacity daemon --persist`
- 🧪 bats tests — `shellcheck` clean

### Quick start

```bash
git clone https://github.com/marelizal/privacity.git
cd privacity
sudo make install
sudo make completions
privacity
```

[Installation](docs/installation.md) · [Usage](docs/usage.md) · [Configuration](docs/configuration.md) · [Architecture](docs/architecture.md) · [Development](docs/development.md)

---

## Español

Herramienta CLI que obtiene los servidores públicos más rápidos de múltiples proveedores (**VPN Gate**, **VPNBook**) y se conecta vía **OpenVPN** o **WireGuard**.

### Características

- 🔒 Sanitiza configuraciones OpenVPN (elimina `script-security`, `up`, `down`, `persist-key`, etc.)
- 🔀 Multi-proveedor: VPN Gate + VPNBook, lista unificada de servidores
- 📡 Soporte WireGuard (wg-quick) + OpenVPN
- ⚡ Selección automática de protocolo o manual con `--protocol ovpn|wg|auto`
- 🌐 Verifica conectividad a Internet después de conectar (DNS + HTTP)
- ⚡ Prueba de velocidad de descarga y subida
- 🔔 Notificaciones de escritorio al conectar/desconectar/fallar
- 🗂️ Multi-perfil: `privacity --profile trabajo daemon`
- 📝 Log a archivo con `--log-file <ruta>` + marcas de tiempo con `--verbose`
- 🌍 Filtro por país: `privacity -c Japon`
- ⚙️ Archivo de configuración: `~/.config/privacity/config` (país, modo, fast, protocol)
- ⚡ Orden por latencia: `privacity --fast` (ordena por ping en vez de puntuación)
- 📋 Listar países: `privacity --countries`
- 💤 Persistencia systemd: `privacity daemon --persist`
- 🧪 pruebas bats — `shellcheck` limpio

### Inicio rápido

```bash
git clone https://github.com/marelizal/privacity.git
cd privacity
sudo make install
sudo make completions
privacity
```

[Instalación](docs/installation.md#espa%C3%B1ol) · [Uso](docs/usage.md#espa%C3%B1ol) · [Configuración](docs/configuration.md#espa%C3%B1ol) · [Arquitectura](docs/architecture.md#espa%C3%B1ol) · [Desarrollo](docs/development.md#espa%C3%B1ol)

---

## License / Licencia

GPL v3 — see [LICENSE](LICENSE)
