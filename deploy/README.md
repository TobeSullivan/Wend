# Wend dedicated server — deploy

Headless Godot match authority. The server is a **room router**: one process hosts MANY
concurrent matches keyed by `match_id` (`net/match_server.gd` + `match_room.gd`), each an
isolated authority sim. Clients are pointed here by Nakama (matchmaking → forming lobby → GO),
then `JOIN_ROOM`. Target box: **Hetzner CPX31, Hillsboro (`hil`)**, `5.78.110.182` (see
`notes/server_decision.md`). Background + roadmap: `notes/remote_beta_plan.md`.

The exported game binary *is* the server — `--headless -- --server` routes `boot.gd`
into `SceneManager.start_dedicated_server()`. Transport is ENet over **UDP 8771**. Runs on the
same box as the Nakama stack (`deploy/nakama/`).

---

## 0. One-time: build the server binary (on the dev machine)

Already built into `deploy/build/wend_server.x86_64`. To rebuild after code changes:

```powershell
# from repo root, with Godot 4.6.3 + Linux export templates installed
& "C:\Users\tobes\Desktop\Godot.exe" --headless --path src `
  --export-release "Linux Server" "deploy/build/wend_server.x86_64"
```

Output is a self-contained ELF x86-64 (pck embedded, ~74 MB). `deploy/build/` is gitignored.

> **Note:** `export_presets.cfg` is gitignored (machine-specific paths — project convention,
> same as the Android preset), so the "Linux Server" preset lives only on the build machine.
> If it's ever missing, recreate it in the Godot editor (Project → Export → Add → Linux) with:
> `Architecture = x86_64`, `Embed PCK = on`, `Export Path = ../deploy/build/wend_server.x86_64`,
> `dedicated_server = off` (the server sims the full match scene, so keep all resources).

---

## 1. One-time: open the firewall (Hetzner side)

ENet is **UDP**. Open **UDP 8771** inbound. Two layers — do both if you use the Hetzner
Cloud Firewall:

- **Hetzner Cloud Firewall** (console → Firewalls, or `hcloud`): add inbound rule
  `UDP / 8771 / any IPv4+IPv6`. Keep TCP 22 (SSH) open.
- **On the box** (only if `ufw` is enabled — fresh Hetzner Ubuntu usually isn't):
  ```bash
  ufw allow 8771/udp
  ufw allow OpenSSH
  ```

## 2. Deploy (from the dev machine)

```bash
# Git Bash / WSL, from repo root. Your SSH key must be authorized on the box.
bash deploy/deploy.sh root@<VPS_IP>
```

This uploads the binary + unit, creates a system `wend` user, installs to `/opt/wend`,
enables + starts `wend-server.service`, and prints its status. Re-run anytime to ship a
new build (it restarts the service).

### What the script does on the box (for reference / manual setup)
```bash
useradd --system --home /opt/wend --shell /usr/sbin/nologin wend
install -d -o wend -g wend /opt/wend
install -m 0755 -o wend -g wend wend_server.x86_64 /opt/wend/wend_server.x86_64
install -m 0644 wend-server.service /etc/systemd/system/wend-server.service
systemctl daemon-reload && systemctl enable --now wend-server.service
```

## 3. Verify

```bash
ssh root@<VPS_IP> systemctl status wend-server      # should be active (running)
ssh root@<VPS_IP> journalctl -u wend-server -f       # expect:
#   [server] room router up on port 8771 — waiting for JOIN_ROOM
```

Clients reach a room via Nakama (Find Match → matchmaker → forming lobby → GO points them here →
`JOIN_ROOM`), so there's no connect-by-IP screen anymore. To smoke-test the server's room path
directly over ENet without Nakama, run two `src/tools/room_e2e_client.tscn` instances with the same
`MBTD_MATCH` (see that harness) — both should land in one room and get `START_MATCH`. Two real
clients matchmaking + playing a full match across networks is the remaining human E2E.

## 4. Client address for shipped tester builds

The client no longer hardcodes the match-server IP — it gets `{host, port}` from Nakama's lobby
`GO` message. So the address lives **server-side** in `deploy/nakama/data/modules/index.js`
(`MATCH_SERVER_HOST` / `MATCH_SERVER_PORT`); change it there + `docker compose restart nakama` and
every client picks it up with no rebuild. (`lobby.gd`'s old `DEFAULT_SERVER` const is gone.)

---

## Troubleshooting

- **`active (running)` but no clients connect** → firewall. Confirm UDP (not TCP) 8771 is
  open at *both* the Hetzner Cloud Firewall and any on-box `ufw`. `ss -lunp | grep 8771`
  on the box should show the binary listening.
- **Service fails instantly / `status` shows a loader error** → a missing shared lib.
  Headless Godot is mostly self-contained, but on a minimal image you may need:
  `apt-get install -y libfontconfig1`. Check with `ldd /opt/wend/wend_server.x86_64 | grep "not found"`.
- **`exec format error`** → wrong arch. Hetzner CPX = x86_64; the preset is x86_64. (An
  ARM Hetzner CAX box would need a `linux_release.arm64` re-export.)
- **Restart loop** → `journalctl -u wend-server -n 50` for the GDScript error.
