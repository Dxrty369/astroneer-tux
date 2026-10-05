# Astroneer AstroTuxLauncher

Astroneer dedicated server egg for Pterodactyl, managed by
[AstroTuxLauncher](https://github.com/JoeJoeTV/AstroTuxLauncher). The launcher
runs the native Windows dedicated server under WINE and adds an RCON console,
player monitoring, Discord/ntfy notifications and graceful saves.

## Install notes

Two variables are required to prevent the server from crashing on startup:

- **Server Owner Name** — Steam display name of the server owner. Also grants
  that user owner and administrator rights.
- **Server Owner SteamID** — SteamID64 of the server owner, e.g.
  `76561198000000000`. Also grants that user owner and administrator rights. See
  the [Steam FAQ](https://help.steampowered.com/en/faqs/view/2816-BE67-5B69-0FEC).

**Public IP** is optional: the launcher detects it by itself. Set it only if
detection returns the wrong address, and enable `OVERWRITE_IP` alongside it.

There is no separate install step. The entrypoint inspects the server directory
and runs `install` on the first boot and `start` on every boot after that. The
first install downloads a few hundred MiB from Steam and takes roughly a minute
on a decent connection.

## Client configuration

Encryption is disabled on the server. The launcher hard-codes this in its
generated config (`DisableEncryption = true`), and the egg writes
`net.AllowEncryption=False` into `Engine.ini` to match, so the server is reached
without Steam's networking layer.

Every player must therefore disable encryption on their own client. Edit
`Engine.ini` (located at
`%LocalAppData%\Astro\Saved\Config\WindowsNoEditor\Engine.ini`) on **every**
player's computer and add:

```
[SystemSettings]
net.AllowEncryption=False
```

Clients that skip this cannot connect. The launcher logs a notice on every boot
that encryption is off.

## Server ports

The server requires a single allocation.

| Port | default |
|------|---------|
| Game | 8777    |

8777 is the port this egg configures, and any port can be substituted — the egg
writes your allocation's port into `Engine.ini` automatically.

## Minimum RAM warning

Astroneer requires at least 700 MiB to run. If more than one player will connect,
1 GiB seems to be a minimum.

## Minimum storage warning

Astroneer requires at least 3 GiB. The size may increase with larger save files.

## Variables

### Required

| Variable | Description |
|----------|-------------|
| `SERVER_NAME` | Name shown in the server browser. |
| `OWNER_NAME` | Steam display name of the server owner. |
| `OWNER_GUID` | SteamID64 of the server owner, e.g. `76561198000000000`. |

### Server access

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_PWD` | *empty* | Password players must enter. Leave empty for a public server. See the password note below. |
| `PUBLIC_IP` | *empty* | Leave empty to let the launcher detect it. |
| `OVERWRITE_IP` | `0` | Force `PUBLIC_IP` even when it looks wrong. |

The launcher can detect your public IP on its own, which is preferable whenever
the server sits behind NAT. Set this only if detection returns the wrong
address, and enable `OVERWRITE_IP` alongside it.

### Startup and logging

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_AUTO_UPDATE` | `1` | Check for and apply game updates on every start. |
| `LOG_DEBUG` | `1` | Include `DEBUG`-level messages in the console and log file. |
| `CHECK_NETWORK` | `0` | Warn when the network config looks unusual. Makes external requests and delays startup. |

Setting `LOG_DEBUG` to `0` lowers the console and log level from `DEBUG` to
`INFO`. Startup, save, shutdown and error lines stay visible either way — only
the verbose per-line detail goes away. `INFO` is the quiet setting if you want
less noise without losing anything important.

### Notifications

| Variable | Default | Description |
|----------|---------|-------------|
| `NOTIFY_METHOD` | *empty* | Empty, `discord` or `ntfy`. |
| `DISCORD_WEBHOOK` | *empty* | Only used when the method is `discord`. |
| `NTFY_TOPIC` | *empty* | Only used when the method is `ntfy`. |
| `UPTIME_KUMA_URL` | *empty* | Makes the panel status follow the real server status. |

Events available for the whitelist: `message`, `start`, `registered`,
`shutdown`, `crash`, `player_join`, `player_leave`, `command`, `save`,
`savegame_change`.

## Console commands

The launcher's RCON console accepts these commands:

| Command | Description |
|---------|-------------|
| `help` | Print the available commands. |
| `shutdown` | Shut the Dedicated Server down gracefully. |
| `restart` | Restart the Dedicated Server. |
| `info` | Information about the running server. |
| `kick` | Kick a player by GUID or name. |
| `whitelist` | `enable`, `disable` or `status`. |
| `list` | List players. |
| `savegame` | `load`, `save`, `new` or `list`. |
| `player` | `set` or `get` a player's category. |

`whitelist`, `savegame` and `player` require a subcommand and do nothing without
one — `savegame` on its own is rejected rather than guessed.

## Troubleshooting

### The server restarts itself after `shutdown`

Wings treats a server that exits without a power action as crashed, and its
`detect_clean_exit_as_crash` option defaults to `true`. Because `shutdown` in the
console is not a Wings power action, the process exits cleanly with code 0 and
is then restarted automatically.

Disable this in `/etc/pterodactyl/config.yml`:

```yaml
crash_detection:
  enabled: true
  detect_clean_exit_as_crash: false
  timeout: 60
```

Restart Wings afterwards. Real crashes and out-of-memory kills will still be
restarted; only clean exits will be left alone. The same applies to the Stop
button in the panel.

### Importing the egg returns HTTP 500

This egg requires a `config.logs` key. Without it the panel's `EggParserService`
reads a null value and the model rule `required_without:config_from` fails,
which surfaces as a 500 rather than a 422. If you are importing an older
revision, add `"logs": "{}"` to the `config` object.

### The Steam Owner SteamID variable is rejected

The rule is `digits_between:17,20`, which counts digits. An earlier revision
used `min:17|max:20`, which Laravel reads as "value between 17 and 20" and
therefore rejected every real SteamID64. Update the egg if you imported it
before the fix.

### Password with special characters is rejected

`SERVER_PWD` is validated with `alpha_dash`, which allows only letters, digits,
hyphens and underscores. A password such as `Astroneer#2026` is refused without
further explanation. Widen the rule to `nullable|string|between:1,100` if you
need punctuation.

### First Playfab authentication returns HTTP 400

The first XAuth request commonly returns `HTTP Error 400: Bad Request` and the
second succeeds. The launcher retries, so this is expected and harmless.

## Notes

- `config.logs` is empty, so the panel does not colourise or filter log lines.
  The launcher writes its own timestamped lines to stdout, which the console
  displays directly.
- `SERVER_PWD` appears in cleartext in the launcher logs. Avoid exporting logs
  anywhere shared if you set a password.
- `meta.version` is `PTDL_v1`. The panel converts it on import, so the egg works
  as-is.

## Credits

This egg bundles [AstroTuxLauncher](https://github.com/JoeJoeTV/AstroTuxLauncher)
by JoeJoeTV, downloaded and checksum-verified during the image build. The
launcher is licensed under GPL-3.0, which is why this repository uses the same
license.

## License

GPL-3.0 — see [LICENSE](LICENSE).

Astroneer itself is a trademark of System Era Softworks. This repository is not
affiliated with or endorsed by System Era Softworks or Bouncy Rock.
