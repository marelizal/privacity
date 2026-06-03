# privacity

![tests](https://github.com/marelizal/privacity/actions/workflows/test.yml/badge.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

---

**English** · [Español](#espa%C3%B1ol) · [Documentation](docs/index.md)

---

## English

CLI tool that fetches the fastest public [VPN Gate](https://www.vpngate.net/) servers and connects via OpenVPN.

### Features

- 🔒 Sanitizes OpenVPN configs (strips `script-security`, `up`, `down`, `persist-key`, etc.)
- 🌐 Internet health check after connect (DNS + HTTP)
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

[Installation](docs/installation.md) · [Usage](docs/usage.md) · [Configuration](docs/configuration.md) · [Architecture](docs/architecture.md) · [Development](docs/development.md)

---

## Español

Herramienta CLI que obtiene los servidores públicos más rápidos de [VPN Gate](https://www.vpngate.net/) y se conecta vía OpenVPN.

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

[Instalación](docs/installation.md#espa%C3%B1ol) · [Uso](docs/usage.md#espa%C3%B1ol) · [Configuración](docs/configuration.md#espa%C3%B1ol) · [Arquitectura](docs/architecture.md#espa%C3%B1ol) · [Desarrollo](docs/development.md#espa%C3%B1ol)

---

## License / Licencia

GPL v3 — see [LICENSE](LICENSE)
