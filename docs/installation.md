# Installation

---

**English** · [Español](#espa%C3%B1ol)

---

## English

### Requirements

| Package | Purpose |
|---|---|
| `openvpn` | VPN tunnel |
| `wget`, `curl` | HTTP requests (server list, health checks) |
| `base64` (coreutils) | Decode OpenVPN configs |
| `sudo` | Privilege escalation for OpenVPN |
| `python3` | CSV parsing (server list) |
| `notify-send` (optional) | Desktop notifications |

### Install from source

```bash
git clone https://github.com/marelizal/privacity.git
cd privacity
sudo make install          # /usr/local/bin/ + man page + lib/
sudo make completions      # bash/zsh completion
make hooks                 # enable pre-commit checks
```

### Verify

```bash
privacity help
```

Should print the help screen with all commands.

### Update

```bash
privacity update
```

This clones the latest version from GitHub and reinstalls. If `sudo` access is unavailable, run `sudo privacity update` instead.

### Uninstall

```bash
cd privacity  # or the repo directory
sudo make uninstall
sudo make uninstall-completions
sudo make uninstall-man
```

Remove config and data:

```bash
rm -rf ~/.config/privacity ~/.local/share/privacity
```

---

## Español

### Requisitos

| Paquete | Propósito |
|---|---|
| `openvpn` | Túnel VPN |
| `wget`, `curl` | Peticiones HTTP (lista de servidores, verificación) |
| `base64` (coreutils) | Decodificar configuraciones OpenVPN |
| `sudo` | Elevación de privilegios para OpenVPN |
| `python3` | Análisis de CSV (lista de servidores) |
| `notify-send` (opcional) | Notificaciones de escritorio |

### Instalar desde fuente

```bash
git clone https://github.com/marelizal/privacity.git
cd privacity
sudo make install          # /usr/local/bin/ + página man + lib/
sudo make completions      # completado bash/zsh
make hooks                 # activar ganchos pre-commit
```

### Verificar

```bash
privacity help
```

Debe mostrar la pantalla de ayuda con todos los comandos.

### Actualizar

```bash
privacity update
```

Clona la última versión desde GitHub y reinstala. Si no tienes acceso a `sudo`, ejecuta `sudo privacity update`.

### Desinstalar

```bash
cd privacity  # o el directorio del repositorio
sudo make uninstall
sudo make uninstall-completions
sudo make uninstall-man
```

Eliminar configuración y datos:

```bash
rm -rf ~/.config/privacity ~/.local/share/privacity
```
