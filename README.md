# privacity

CLI tool that fetches the fastest public VPN Gate servers and connects via OpenVPN — interactive or daemon mode.

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
privacity help          # Show help
```

## Requirements

- `openvpn`
- `wget`
- `curl`
- `base64`
- `sudo` privileges

## How it works

1. Downloads the server list from the [VPN Gate API](http://www.vpngate.net/api/iphone/)
2. Parses servers by Score (highest first)
3. Decodes the Base64 OpenVPN config of the best server
4. Connects via OpenVPN and monitors the tunnel
5. In interactive mode: shows external IP, ping, location, and live download/upload speed
6. Press `Q` to disconnect

## Directory layout

```
~/.local/share/privacity/
  servers.csv       Cached server list (5 min TTL)
  active.ovpn       Decoded OpenVPN config
  privacity.pid     PID of background OpenVPN (daemon mode)
  last_host         Last connected server hostname
  openvpn.log       OpenVPN daemon log
```

## License

GPL v3
