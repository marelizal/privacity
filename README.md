# privacity

![tests](https://github.com/marelizal/privacity/actions/workflows/test.yml/badge.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

CLI tool that fetches the fastest public [VPN Gate](https://www.vpngate.net/) servers and connects via OpenVPN — interactive or daemon mode.

![demo](privacity.png)

## Features

- 🔒 Sanitizes OpenVPN configs (strips `script-security`, `up`, `down`, `persist-key`, etc.)
- 🌐 Internet health check after connect (DNS + HTTP connectivity)
- ⚡ Built-in speed test via Cloudflare
- 🧪 23 bats tests — `shellcheck` clean (0 warnings)

## Quick start

```bash
git clone https://github.com/marelizal/privacity.git
cd privacity
sudo make install
sudo make completions
privacity
```

## Install

```bash
sudo make install          # installs to /usr/local/bin/
sudo make completions      # bash/zsh completion
make hooks                 # enable pre-commit checks (shellcheck + bats)
```

## Usage

```bash
privacity               # Interactive guided mode
privacity daemon        # Connect in background (no terminal)
privacity disconnect    # Tear down current VPN
privacity reconnect     # Pick best server and reconnect
privacity status        # Show connection info and live speed
privacity speedtest     # Measure download speed via Cloudflare
privacity update        # Pull latest version and reinstall
privacity help          # Show help
```

## Requirements

| Runtime | Dev / testing |
|---|---|
| `openvpn`, `wget`, `curl` | `shellcheck`, `bats` |
| `base64` (coreutils), `sudo` | `python3` (CSV parsing) |

## How it works

1. Downloads server list from VPN Gate (HTTPS, fallback HTTP)
2. Parses CSV with python3 `csv` module — handles quoted commas in country names
3. Selects highest-score server
4. Decodes Base64 OpenVPN config, strips dangerous directives
5. Connects via OpenVPN with `--cd "$DIR"` and `chmod 700` on data dir
6. Verifies internet: DNS (`google.com` via `8.8.8.8`) + HTTP (204 check)
7. Measures download speed via Cloudflare
8. Interactive mode: live RX/TX speed, IP, ping, location
9. Press `Q` to disconnect, `S` to switch server

See [FLOW.md](FLOW.md) for a detailed execution diagram.

## Directory layout

```
~/.local/share/privacity/
  servers.csv       Cached server list (5 min TTL)
  active.ovpn       Sanitized OpenVPN config
  privacity.pid     PID of background OpenVPN
  last_host         Last connected server hostname
  openvpn.log       OpenVPN daemon log
```

## Development

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

## License

GPL v3 — see [LICENSE](LICENSE)
