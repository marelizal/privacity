---
name: vpn
description: |
  VPN, OpenVPN, and network tunnel knowledge for the privacity project.
  Use when dealing with OpenVPN configs, routing, tun interfaces, or VPN troubleshooting.
---

# VPN & OpenVPN

## Tunnel lifecycle

1. OpenVPN creates a `tun` virtual interface (layer 3)
2. Traffic sent to the tun interface is encrypted and forwarded through the VPN server
3. The VPN server decrypts and sends to the internet
4. Return traffic follows the reverse path

## OpenVPN configs from VPN Gate

- Configs are base64-encoded in the 15th CSV field
- Dangerous directives to strip: `script-security`, `up`, `down`, `route-up`, `ipchange`, `plugin`, `tls-verify`, `auth-user-pass-verify`
- Always inject `data-ciphers DEFAULT:AES-128-CBC` for compatibility with OpenVPN ≥2.7

## Troubleshooting

- `ip link show tun0` — tunnel exists
- `ip route show` — verify default route points to tun
- `cat /sys/class/net/tun0/statistics/{rx,tx}_bytes` — live byte counters
- Ping external IP directly (`ping 8.8.8.8`) to bypass DNS; then test DNS (`host google.com`)
- Check OpenVPN log: `~/.local/share/privacity/openvpn.log`

## Connection check

- `curl -s -o /dev/null -w "%{http_code}" https://www.google.com/generate_204` — returns 204 if traffic egresses to internet
- `host google.com 8.8.8.8` — DNS via Google's resolver
