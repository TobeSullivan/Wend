# Remote beta: dedicated server + distribution plan

Captured 2026-06-05. Decision after the first live multiplayer test. Companion to
`notes/multiplayer_architecture.md` (the broader rollout/cost reference) — this is the
concrete build plan for getting a **remote, mobile** beta working.

## What forced this

LAN/P2P is proven live (lobby → seed-sync → build relay → lockstep → lives barrier,
PC↔PC on localhost). But the LAN model can't carry a real beta:
- Testers are in **other houses / other networks** — `192.168.1.70` is unreachable.
- The old "internet path" (host port-forwards UDP 8771) is unacceptable to ask of testers.
- Mobile testers are on **carrier-grade NAT** (saw the phone on `100.x` cellular) → P2P
  punch-through is unreliable on cell.
- **Steam relay (the arch doc's "best beta path") is PC/Mac only** → useless for Android.
- Distribution via USB `adb install` only works for someone at the dev's laptop.

## Long-term home (the target we build toward)

- **Match authority = headless Godot dedicated server.** Run the EXISTING
  `MatchCoordinator` under `--headless` on a Linux VPS with a public IP + open UDP, over
  ENet. Clients connect *outbound* to `server:port` → works through any NAT/cellular (the
  server is the public endpoint; no port-forwarding by testers, no relay needed). Reuses
  ~100% of the match code (already GDScript, already headless-verified). Round-barrier
  netcode = kilobytes/round, so one small box coordinates many concurrent matches.
- **Meta backend = self-hosted Nakama** (Docker + Postgres) for cross-platform identity
  (device / Google / Apple / Steam), matchmaking (queue → assign to a server slot + match
  code), leaderboards / LP / seasons. Added when we outgrow a fixed-address beta.
- **Distribution = Google Play Internal Testing** (AAB via Play Console; testers install
  through the Play Store).
- **Host = Hetzner VPS** (~$5–10/mo is plenty for beta; CCX13 ~$16 when Nakama lands).

### Why headless-Godot-server, NOT "coordinator inside Nakama"
The coordinator (clock + zero-sum lives math + N-board lockstep) is already GDScript and
headless-verified. Running it headless reuses everything. A Nakama match handler would
mean rewriting that logic in Go/TS and duplicating it. So: **authority stays in Godot;
Nakama is the directory/matchmaker that points clients at a Godot match server.** Both are
endorsed by `multiplayer_architecture.md` §0/§1; this picks the lower-code one.

Transport stays **ENet** (UDP, low latency, MultiplayerPeer-swappable). WebSocket/WebRTC
only needed if we add a web build later.

## Staged build (each step independently usable)

### M1 — Dedicated Godot match server (the beta unblocker) — NEXT
- **Headless server boot mode**: auto-host as authority-only (no window, no UI, no player
  seat). New boot branch + a launch flag/env.
- **Decouple authority from player**: today the lobby host *is* a player at seat 0
  (`lobby.gd`, `SceneManager.net_host`, `map_loader.build_match local_index`). Change so
  the server (peer id 1) is authority but occupies NO seat/board; seats are assigned to
  joined clients only; `NetMatch` on the server runs the clock + `resolve_lives` +
  broadcasts but sims no local player board.
- **Client connect-to-server**: lobby Join points at a configured server address; add a
  simple **room/match code** so testers land in the same match (start: one fixed match;
  add numeric codes within M1).
- **Deploy**: Godot **Linux headless export**, Hetzner VPS, `systemd` unit to keep alive,
  open the UDP port in the firewall.
- **Done when**: PC + Android, on different networks/cellular, both connect to the public
  server and play a full match. No tester network config.
- Dev loop: build + verify locally first (headless server + 2 clients on localhost), then
  deploy to the VPS as the last step.

### M2 — Distribution via Google Play Internal Testing (parallel to M1)
- Play Console account (**$25 one-time**), **AAB** export (not APK) + Play App Signing,
  Internal Testing track, add testers by email → they install via the Play Store.
- Needs a minimal store listing + app signing key setup. Mostly console steps (user) +
  an AAB export config (me).

### M3 — Nakama meta backend (toward launch)
- Identity, matchmaking (lobby shrink 8→6→4, widen rank bands under load — never bots),
  leaderboards / LP / seasons; hands clients a match-server address. Add **authoritative
  validation** here, before any ranked launch (beta stays trust-client).

## Division of labor
- **User provisions**: Hetzner VPS (I'll spec it + give exact setup commands), Play
  Console $25 + tester emails, picks server region.
- **I build**: server boot mode + authority/player decouple, client address/room-code,
  Linux export config, deploy scripts + systemd unit, AAB export config.

## Open questions (need answers to start M1 cleanly)
1. **Tester locations / region** — Hetzner has US (Ashburn/Hillsboro) + EU. Where are most
   beta testers? (Picks VPS region for latency.)
2. **Join model for first remote test** — one fixed match everyone joins, or numeric room
   codes from the start? (Lean: ship a fixed match first, add codes inside M1.)
3. **Server cardinality** — single shared server process for the beta (simplest), fine?
   (Multiple match servers + orchestration is an M3/Nakama concern.)
