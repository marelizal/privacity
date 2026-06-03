# privacity — Execution Flow

```
                          ┌──────────────┐
                          │    START     │
                          │   main()     │
                          └──────┬───────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │   CHECKS     │
                          │  deps        │
                          │  (openvpn,   │
                          │   wget,      │
                          │   curl,      │
                          │   base64)    │
                          └──────┬───────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │   FETCH      │
                          │  servers.csv │  ◄── https://www.vpngate.net/api/iphone/
                          │  (5 min TTL) │      fallback: http://
                          └──────┬───────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │   PARSE      │
                          │  CSV         │  ◄── python3 csv reader
                          │  top 50      │      handles quoted commas
                          │  sort score  │
                          └──────┬───────┘
                                 │
                                 ▼
                     ┌─────────────────────┐
                     │   INTERACTIVE?      │
                     │  (no subcommand =   │
                     │   interactive)      │
                     └──┬──────────────┬───┘
                        │              │
         YES (default)  │              │  NO (daemon|disconnect|...)
                        ▼              │
                 ┌──────────────┐      │
                 │   DISPLAY    │      │
                 │  top 3       │      │
                 │  servers     │      │
                 └──────┬───────┘      │
                        │              │
                        ▼              │
                 ┌──────────────┐      │
                 │   CONFIRM    │      │
                 │  [Y/n]       │      │
                 └──────┬───────┘      │
                        │              │
               ┌────────┴────────┐     │
               │                 │     │
            [Y] ▼                │     │
        ┌──────────────┐         │  [N] ▼
        │   WRITE      │         │  ┌──────────┐
        │  config      │         │  │  EXIT    │
        │  + sanitize  │         │  └──────────┘
        └──────┬───────┘         │
               │                 │
               ▼                 │
        ┌──────────────┐         │
        │  OPENVPN     │         │
        │  start       │         │
        │  --cd "$DIR" │         │
        └──────┬───────┘         │
               │                 │
               ▼                 │
        ┌──────────────┐         │
        │  TUNNEL      │         │
        │  wait loop   │         │
        │  (20s)       │         │
        └──────┬───────┘         │
               │                 │
      ┌────────┴────────┐        │
      │                 │        │
   UP ▼                 │  FAIL  │
   ┌──────────┐         ▼       │
   │  CHECK   │  ┌──────────┐   │
   │  internet│  │  ERROR   │   │
   │  DNS+HTTP│  │  +kill   │   │
   └────┬─────┘  └──────────┘   │
        │                       │
        ▼                       │
   ┌──────────┐                 │
   │  SPEED   │                 │
   │  test    │                 │
   │  10 MiB  │                 │
   └────┬─────┘                 │
        │                       │
        ▼                       │
   ┌──────────┐                 │
   │  HEADER  │                 │
   │  IP,     │                 │
   │  Ping,   │                 │
   │  Loc,    │                 │
   │  Speed   │                 │
   └────┬─────┘                 │
        │                       │
        ▼                       │
   ┌──────────────┐             │
   │  MONITOR     │             │
   │  loop        │             │
   │  RX/TX every │             │
   │  2 seconds   │             │
   └──┬───────┬───┘             │
      │       │                 │
   [Q]▼       │  [S]            │
   ┌──────┐   ▼            ┌────┴────┐
   │ KILL │   ┌──────────┐ │        │
   │ +exit│   │ KILL     │ │        │
   └──────┘   │ +return 1│ │        │
              └────┬─────┘ │        │
                   │       │        │
                   └───┬───┘        │
                       │            │
                       ▼            │
                ┌──────────────┐    │
                │  LOOP AGAIN  │    │
                │  (new best)  │────┘
                └──────────────┘
```

## Subcommands

```
privacity               ─────  Interactive guided mode (default)
privacity daemon        ─────  Daemon mode
privacity disconnect    ─────  Kill tunnel + cleanup
privacity reconnect     ─────  Disconnect → fetch → connect (daemon)
privacity status        ─────  Show connection state + speed
privacity speedtest     ─────  Download 10 MiB from Cloudflare
privacity update        ─────  git clone → make install
privacity help          ─────  Show help
```
