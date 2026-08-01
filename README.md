# privacity

![tests](https://github.com/marelizal/privacity/actions/workflows/test.yml/badge.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
<a href='https://cafecito.app/marelizal' rel='noopener' target='_blank'><img srcset='https://cdn.cafecito.app/imgs/buttons/button_1.png 1x, https://cdn.cafecito.app/imgs/buttons/button_1_2x.png 2x, https://cdn.cafecito.app/imgs/buttons/button_1_3.75x.png 3.75x' src='https://cdn.cafecito.app/imgs/buttons/button_1.png' alt='Invitame un café en cafecito.app' /></a>

---

**English** · [Español](#espa%C3%B1ol) · [Documentation](docs/index.md)

---

## English

CLI tool that finds the fastest public VPN Gate servers and connects via **OpenVPN**.

### Features

- 🔒 Sanitizes OpenVPN configs (strips `script-security`, `up`, `down`, `persist-key`, etc.)
- 🛡️ Leak protection: forced DNS through tunnel, IPv6 blocked, server-cert verification (`remote-cert-tls`)
- 🔀 VPN Gate server list, unified and cached (5 min TTL)
- ⚡ OpenVPN with auto-injected credentials (no prompts in daemon)
- 🌐 Internet health check after connect (DNS + HTTP)
- 🔔 Desktop notifications on connect/disconnect/fail
- 🎯 Pick any server from the list: `privacity --server <host>`
- 📝 Log to file with `--log-file <path>` + `--verbose` timestamps
- 🌍 Country filter: `privacity -c Japan`
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

[Installation](docs/installation.md) · [Usage](docs/usage.md) · [Architecture](docs/architecture.md) · [Development](docs/development.md)

---

## Español

Herramienta CLI que obtiene los servidores públicos más rápidos de **VPN Gate** y se conecta vía **OpenVPN**.

### Características

- 🔒 Sanitiza configuraciones OpenVPN (elimina `script-security`, `up`, `down`, `persist-key`, etc.)
- 🛡️ Protección de fugas: DNS forzado por el túnel, IPv6 bloqueado, verificación del certificado del servidor (`remote-cert-tls`)
- 🔀 Lista de servidores VPN Gate, unificada y cacheada (TTL 5 min)
- ⚡ OpenVPN con credenciales inyectadas automáticamente (sin prompts en demonio)
- 🌐 Verifica conectividad a Internet después de conectar (DNS + HTTP)
- 🔔 Notificaciones de escritorio al conectar/desconectar/fallar
- 🎯 Elegir cualquier servidor de la lista: `privacity --server <host>`
- 📝 Log a archivo con `--log-file <ruta>` + marcas de tiempo con `--verbose`
- 🌍 Filtro por país: `privacity -c Japon`
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

[Instalación](docs/installation.md#espa%C3%B1ol) · [Uso](docs/usage.md#espa%C3%B1ol) · [Arquitectura](docs/architecture.md#espa%C3%B1ol) · [Desarrollo](docs/development.md#espa%C3%B1ol)

---

## License / Licencia

GPL v3 — see [LICENSE](LICENSE)
