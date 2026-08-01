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
                          ┌──────────────┐
                          │   PICK       │
                          │  best server │  ◄── --server <host> | -c <country> | --fast
                          │  (8th field) │
                          └──────┬───────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │   WRITE      │
                          │  config      │
                          │  + sanitize  │
                          │  + auth.txt  │
                          └──────┬───────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │  OPENVPN     │
                          │  start       │
                          │  --daemon    │
                          │  --auth-user-│
                          │   pass       │
                          └──────┬───────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │  TUNNEL      │
                          │  wait loop   │
                          │  (20s)       │
                          └──────┬───────┘
                                 │
                      ┌──────────┴──────────┐
                      │                     │
                   UP ▼                 FAIL ▼
                   ┌──────────┐     ┌──────────┐
                   │  CHECK   │     │  ERROR   │
                   │  internet│     │  +kill   │
                   │  DNS+HTTP│     └──────────┘
                   └────┬─────┘
                        │
                        ▼
                   ┌──────────┐
                   │  HEADER  │
                   │  IP,     │
                   │  Ping,   │
                   │  Loc     │
                   └──────────┘
```

Daemon mode exits after connecting; `disconnect` and `status` act on
the running OpenVPN process (PID file in the state dir).

## Subcommands

```
privacity               ─────  Daemon mode (default)
privacity daemon        ─────  Daemon mode
privacity disconnect    ─────  Kill tunnel + cleanup
privacity reconnect     ─────  Disconnect → fetch → connect (daemon)
privacity status        ─────  Show connection state + speed
privacity list          ─────  Show top servers + countries
privacity update        ─────  git clone → make install
privacity help          ─────  Show help
```
