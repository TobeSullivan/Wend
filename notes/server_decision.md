# Server / hosting — decision note

Captured 2026-06-05 (current pricing; verify before committing real spend).
**Updated 2026-06-08** — box upsized + relocated (see "Box move" below).

## Decision
**Hetzner Cloud CPX31, Hillsboro US-West (`hil`), for the beta.** (`5.78.110.182`)
Don't shop further for now.

### Box move (2026-06-08) — supersedes the original CPX11/Ashburn pick
The beta box was upsized from CPX11→**CPX31** (4 vCPU / 8 GB / 160 GB) because
2 GB was too tight for Nakama + Postgres sitting next to the match sim. Hetzner
**`ash` (US-East) had no CPX31 capacity** and CPX11 is deprecated Gen1, so this is a
**fresh create + delete-old**, *not* an in-place resize — landing the box at **`hil`
(Hillsboro OR, US-West)** instead. The old CPX11 at `ash` is deleted.
- **Latency tradeoff (accepted):** the original Ashburn pick was specifically to sit
  close to US testers (user is in Michigan). Hillsboro is the opposite coast — roughly
  ~20ms east-coast RTT traded for ~50–60ms cross-country. Harmless for the beta: the
  netcode is round-barrier / host-authoritative and tolerates it. If a CPX31 frees up in
  `ash` and latency ever matters, recreating there is a clean re-provision (cheap while
  nothing depends on the box).

- **What Hetzner is:** German cloud provider, best-in-class price-to-performance, AMD EPYC,
  all-inclusive pricing (traffic, IPv4/6, DDoS, firewall). DCs in Germany, Finland, US
  (Ashburn VA, Hillsboro OR), Singapore. No free tier.
- **CPX31** (4 vCPU / 8GB / 160GB) — the box we actually run — ≈ **$16–18/mo** capped.
  (CPX11 (2 vCPU/2GB) ≈ $5–7/mo was the original pick but too tight; CPX22 (2 vCPU/4GB)
  ≈ $9.50/mo.) Hetzner raised prices ~30–37% in April 2026 (DRAM costs) — still the
  cheapest serious option at this spec.
- **Ashburn is correct even now that we're PC-first** — testers are US (user in Michigan);
  EU boxes would add latency.

## Is the old "$5–10/mo, it's light" estimate still true?
**For the beta, yes.** For scale, it depends entirely on architecture, not the host.

- The cheap estimate assumed the **round-barrier model** (server relays kill counts, doesn't
  simulate). The current **Option A** does the opposite — the server **simulates the whole
  match** → CPU-heavy, **one match per box**. Under Option A, cost scales linearly with
  concurrent matches.
- **Option B** (lightweight relay; clients report kills; many matches per box) restores the
  cheap-scaling story. With Option B + Nakama on one Hetzner box, hosting stays well under
  1% of revenue into the thousands of concurrent users.
- **Provider choice is a rounding error. The scaling lever is Option A → B**, already on the
  roadmap. "We have a dedicated server" ≠ "we can scale" — different claims.

## Alternatives (for the record)
- **Vultr** — 32 DCs, best global reach if latency to far regions ever matters.
- **Oracle Cloud Always Free** — 4 ARM cores / 24GB free forever, but ARM-compat + idle-
  reclaim + account-recovery risk; fine for labs, not guaranteed production. ~$6/mo Hetzner
  beats fighting Oracle's setup for a beta.
- DigitalOcean/Linode — pricier per spec; better managed-services ecosystem we don't need.

## Anti-cheat coupling (important)
The deterministic round-barrier design means the server can **re-simulate any round from
(seed + each player's build inputs + round#) and compute the true kill count** — it never
has to trust the client. But re-sim = CPU = basically Option A's cost. Resolution: **tier
it** — PVE/casual trust the client (low stakes; spot-check anomalies); **ranked uses
authoritative re-sim** (smaller population; prestige cosmetics are the cheat incentive), or
re-sim only leaderboard-top/flagged submissions. So "no cheaters in ranked" is achievable
without trusting clients — but it's real work, on the launch critical path since ranked
ships. Design it in its own session.
