#!/usr/bin/env bash
# vpnbook.sh — VPNBook provider (module)
set -euo pipefail

PROVIDER_VPNBOOK_PRIORITY=30

VPNBOOK_CA=$(cat <<'CAEOF'
-----BEGIN CERTIFICATE-----
MIIDSzCCAjOgAwIBAgIUJdJ6+6lTiYZBvpl2P40Lgx3BeHowDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAwwLdnBuYm9vay5jb20wHhcNMjMwMjIwMTk0NTM1WhcNMzMw
MjE3MTk0NTM1WjAWMRQwEgYDVQQDDAt2cG5ib29rLmNvbTCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAMcVK+hYl6Wl57YxXIVy7Jlgglj42LaC2sUWK3ls
aRcKQfs/ridG6+9dSP1ziCrZ1f5pOLz34gMYXChhUOc/x9rSIRGHao4gHeXmEoGs
twjxA+kRBSv5xqeUgaTKAhdwiV5SvBE8EViWe3rlHLoUbWBQ7Kky/L4cg7u+ma1V
31PgOPhWY3RqZJLBMu3PHCctaaHQyoPLDNDyCz7Zb2Wos+tjIb3YP5GTfkZlnJsN
va0HdSGEyerTQL5fqW2V6IZ4t2Np2kVnJcfEWgJF0Kw1nqoPfKjxM44bR+K1EGGW
ir1rs/RFPg8yFVxd4ZHpqoCo2lXZjc6oP1cwtIswIHb6EbsCAwEAAaOBkDCBjTAd
BgNVHQ4EFgQULgM8Z91cLOSHl6EDF8jalx3piqQwUQYDVR0jBEowSIAULgM8Z91c
LOSHl6EDF8jalx3piqShGqQYMBYxFDASBgNVBAMMC3ZwbmJvb2suY29tghQl0nr7
qVOJhkG+mXY/jQuDHcF4ejAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIBBjANBgkq
hkiG9w0BAQsFAAOCAQEAT5hsP+dz11oREADNMlTEehXWfoI0aBws5c8noDHoVgnc
BXuI4BREP3k6OsOXedHrAPA4dJXG2e5h33Ljqr5jYbm7TjUVf1yT/r3TDKIJMeJ4
+KFs7tmXy0ejLFORbk8v0wAYMQWM9ealEGePQVjOhJJysEhJfA4u5zdGmJDYkCr+
3cTiig/a53JqpwjjYFVHYPSJkC/nTz6tQOw9crDlZ3j+LLWln0Cy/bdj9oqurnrc
xUtl3+PWM9D1HoBpdGduvQJ4HXfss6OrajukKfDsbDS4njD933vzRd4E36GjOI8Q
1VKIe7kamttHV5HCsoeSYLjdxbXBAY2E0ZhQzpZB7g==
-----END CERTIFICATE-----
CAEOF
)

VPNBOOK_CERT=$(cat <<'CERTEOF'
-----BEGIN CERTIFICATE-----
MIIDYDCCAkigAwIBAgIQP/z/mAlVNddzohzjQghcqzANBgkqhkiG9w0BAQsFADAW
MRQwEgYDVQQDDAt2cG5ib29rLmNvbTAeFw0yMzAyMjAyMzMwNDlaFw0zMzAyMTcy
MzMwNDlaMB0xGzAZBgNVBAMMEmNsaWVudC52cG5ib29rLmNvbTCCASIwDQYJKoZI
hvcNAQEBBQADggEPADCCAQoCggEBANPiNyyYH6yLXss6AeHLzJ6/9JfUzVAs7ttq
8OWJRkBjKuEPW3MUVjpMgptm6+zJohM4IdSo/ES6H81sLK4AWiUUOzeOt8xAzgib
NrLss5px0D0Pm+uXH8hGOle386JH5oyOQ6ub2O3ro0TeTF4rg43TF1oOz2AVS/gc
sB3d6AG73otZ4C6/wabiGz4rFO8xl4S4PBKX73Eb7cdSoACc8AIrqcR+PEDHOZYt
1qp4lM87+5ADEXelpe9vLTaoXonIuZElqA9rwFi/KQmPCHsl7eEnmSo1iOg0y3iP
0CRHzv8FkvhhpB9Z3i3TUxq8XvnLtEQ38eD5Dw20WMYPmPShtXMCAwEAAaOBojCB
nzAJBgNVHRMEAjAAMB0GA1UdDgQWBBQKO5Ub8pRCA8iTdRIxUIeMpNX2vzBRBgNV
HSMESjBIgBQuAzxn3Vws5IeXoQMXyNqXHemKpKEapBgwFjEUMBIGA1UEAwwLdnBu
Ym9vay5jb22CFCXSevupU4mGQb6Zdj+NC4MdwXh6MBMGA1UdJQQMMAoGCCsGAQUF
BwMCMAsGA1UdDwQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAQEAel1YOAWHWFLH3N41
SCIdQNbkQ18UFBbtZz4bzV6VeCWHNzPtWQ6UIeADpcBp0mngS09qJCQ8PwOBMvFw
MizhDz2Ipz817XtLJuEMQ3Io51LRxPP394mlw46e8KFOh06QI8jnC/QlBH19PI+M
OeQ3Gx6uYK41HHmyu/Z7dUE4c4s2iiHA7UgD98dkrU0rGAv1R/d2xRXqEm4PrwDj
MlC1TY8LrIJd6Ipt00uUfHVAzhX3NKR528azYH3bud5NV+KEiQZSyirUyoMbMQeO
UXh+GEDX5GBPElzQmPOsLete/PMH9Ayg6Gh/sccqwgH7BxjqcVLKXg2S4jL5BUPd
kI3/sg==
-----END CERTIFICATE-----
CERTEOF
)

VPNBOOK_KEY=$(cat <<'KEYEOF'
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDT4jcsmB+si17L
OgHhy8yev/SX1M1QLO7bavDliUZAYyrhD1tzFFY6TIKbZuvsyaITOCHUqPxEuh/N
bCyuAFolFDs3jrfMQM4Imzay7LOacdA9D5vrlx/IRjpXt/OiR+aMjkOrm9jt66NE
3kxeK4ON0xdaDs9gFUv4HLAd3egBu96LWeAuv8Gm4hs+KxTvMZeEuDwSl+9xG+3H
UqAAnPACK6nEfjxAxzmWLdaqeJTPO/uQAxF3paXvby02qF6JyLmRJagPa8BYvykJ
jwh7Je3hJ5kqNYjoNMt4j9AkR87/BZL4YaQfWd4t01MavF75y7REN/Hg+Q8NtFjG
D5j0obVzAgMBAAECggEAAV/BLdfatLq+paC9rGIu9ISYKHfn0PJJpkCeSU7HltlN
yOHZnPhvyrb+TdWwB/wSwf8mMQPbhvKSDDn8XDCCZSUpcSXKyVdOPr4K78QbMhA0
4oB8aV20hg72h+UYfl/q/dRaWf2LvZc+ms66Pg4YL05EI4BfFedtc7Fz7u2meIRl
Wm0b7/QQ10wrR1I7PonZzgnU9diB1cKxptJ06AfJmCGobymjq/A1JsAr/NFnJlmu
yq3n5tcRpfc8K+XsfnpwDQJo3kKwLGIoBmUkGEcHgQhVwOL5+P+3pTYr1bt4cAUp
FxbExqcxW0es//g3x2Z80icUpa4/OvSTAa0XF3J4UQKBgQDv4E/3/r5lULYIksNC
zO1yRp7awv41ZAUpDSglNtWsehnhhUsiVE/Ezmyz4E0qjsW2+EUxUZ990T4ZVK4b
9cEhB/TDBc6PBPd498aIGiiqznWXMdsU2o6xrvkQeWdmXoVjvWTcRWlfAQ+PQBOJ
tJ3wR7ZoHgu0P/yzIzn0eQ+BiQKBgQDiIDgRtlQBw8tZc66OzxWOuJh6M5xUF5zY
S0SLXFWlKVkfGACaerHUlFwZKID39BBifgXO1VOQ6AzalDd2vaIU9CHo2bFpTY7S
EkkcIt9Gpl5o1sjEyJChXBIz+s48XBMXlqFN7AdhX/H6R43g8eS/YlzqSBxkUcAa
V3tt8n+sGwKBgD+aSXnnKNKyWOHjEDUJIzh2sy4sH71GXPvqiid756II6g3bCvX6
RwBW/4meQrezDYebQrV2AAUbUwziYBv3yJKainKfeop/daK0iAaUcQ4BGjrRtFZO
MSG51D5jAmCpVVMB59lj6jGPlXGVOtj7dBk+2oW22cGcacOR5o8E/nCJAoGBALVP
KCXrj8gqea4rt1cCbEKXeIrjPwGePUCgeUFUs8dONAteb31ty5CrtHznoSEvLMQM
UBPbsLmLlmLcXOx0eLVcWqQdiMbqTQ3bY4uP2n8HfsOJFEnUl0MKU/4hp6N2IEjV
mlikW/aTu632Gai3y7Y45E9lqn41nlaAtpMd0YjpAoGBAL8VimbhI7FK7X1vaxXy
tnqLuYddL+hsxXXfcIVNjLVat3L2WN0YKZtbzWD8TW8hbbtnuS8F8REg7YvYjkZJ
t8VO6ZmI7I++borJBNmbWS4gEk85DYnaLI9iw4oF2+Dr0LKKAaUL+Pq67wmvufOn
hTobb/WAAcA75GKmU4jn5Ln2
-----END PRIVATE KEY-----
KEYEOF
)

_generate_ovpn_config() {
  local hostname="$1" ip="$2" proto="$3" port="$4"

  cat <<CONFIGEOF
client
dev tun
proto $proto
remote $ip $port
resolv-retry infinite
nobind
persist-key
persist-tun
auth-user-pass
comp-lzo
verb 3
cipher AES-256-CBC
fast-io
pull
route-delay 2
redirect-gateway
<ca>
$VPNBOOK_CA
</ca>
<cert>
$VPNBOOK_CERT
</cert>
<key>
$VPNBOOK_KEY
</key>
CONFIGEOF
}

provider_vpnbook_fetch() {
  mkdir -p "$DIR/providers"
  chmod 700 "$DIR" 2>/dev/null || true

  local page
  page=$(timeout 15 curl -s -H 'RSC: 1' 'https://www.vpnbook.com/freevpn/openvpn' 2>/dev/null) || {
    _provider_vpnbook_err "curl failed"
    return 1
  }

  [[ -n "$page" ]] || {
    _provider_vpnbook_err "empty response"
    return 1
  }

  local password
  password=$(echo "$page" | python3 -c "
import sys, re
content = sys.stdin.read()
idx = content.find('Password')
if idx >= 0:
    chunk = content[idx:idx+300]
    for m in re.finditer(r'children\":\"(\w+)\"', chunk):
        val = m.group(1)
        if val != 'Password':
            print(val)
            break
" 2>/dev/null) || true

  [[ -n "$password" ]] || {
    _provider_vpnbook_err "could not extract password"
    return 1
  }

  local servers_json
  servers_json=$(echo "$page" | python3 -c "
import sys, re, json
content = sys.stdin.read()
m = re.search(r'servers\":(\[.*?\])\}', content)
if m:
    servers = json.loads(m.group(1))
    out = []
    for s in servers:
        out.append(f\"{s['id']}|{s['hostname']}|{s['ipAddress']}|{s['countryCode']}|{s['countryName']}\")
    print('\\n'.join(out))
" 2>/dev/null) || {
    _provider_vpnbook_err "could not parse servers"
    return 1
  }

  [[ -n "$servers_json" ]] || {
    _provider_vpnbook_err "empty server list"
    return 1
  }

  local db="$DIR/providers/vpnbook.db"
  : > "$db"

  local proto port name
  while IFS='|' read -r sid hostname ip ccode cname; do
    for entry in "tcp|443|tcp443" "tcp|80|tcp80" "udp|53|udp53" "udp|25000|udp25000"; do
      proto="${entry%%|*}"
      rest="${entry#*|}"
      port="${rest%%|*}"
      name="${rest#*|}"

      local config
      config=$(_generate_ovpn_config "$hostname" "$ip" "$proto" "$port")

      local b64
      b64=$(echo "$config" | base64 -w0)

      echo "${hostname}|${cname}|${ccode}|50|50|ovpn|${b64}|vpnbook" >> "$db"
    done
  done <<< "$servers_json"

  [[ -s "$db" ]]
}

_provider_vpnbook_err() {
  echo "[vpnbook] ERROR: $*" >&2
}
