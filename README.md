# privacity

CLI tool that fetches the fastest public [VPN Gate](https://www.vpngate.net/) servers and connects via OpenVPN — interactive or daemon mode.

## Features

- 🔒 Sanitizes OpenVPN configs (strips `script-security`, `up`, `down`, etc.)
- 🌐 Internet health check after connect (DNS + HTTP connectivity)
- ⚡ Built-in speed test via Cloudflare
- 🧪 12 bats tests — `shellcheck` clean

## Install

```bash
sudo make install
sudo make completions   # bash/zsh completion
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

Runtime: `openvpn`, `wget`, `curl`, `base64`, `sudo`
Dev: `shellcheck`, `bats` (for testing)

## How it works

1. Downloads server list from VPN Gate (HTTPS, fallback HTTP)
2. Parses CSV with python3 `csv` module — handles quoted commas
3. Selects highest-score server
4. Decodes Base64 OpenVPN config, strips dangerous directives
5. Connects via OpenVPN with `--cd "$DIR"` and `chmod 700` on data dir
6. Verifies internet: DNS (`google.com` via `8.8.8.8`) + HTTP (204 check)
7. Measures download speed via Cloudflare
8. Interactive mode: live RX/TX speed, IP, ping, location
9. Press `Q` to disconnect, `S` to switch server

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
bash -n privacity                    # syntax check
shellcheck -s bash privacity         # static analysis
sudo apt install bats && bats tests/ # unit tests
```

## License

GPL v3 — see [LICENSE](LICENSE)
