# Tower Tier Aura — Wend

Last updated: 2026-06-23
Repo path: `design/TOWER_AURA.md`
Status: **LOCKED form, playtest-tunable values.** Canonical spec for the tier-investment tell.

This supersedes the older "base aura **ring** + size step" phrasing in `decisions.md` /
`design/COSMETICS.md`, and replaces the merge-reference's **"body color walks a 10-stop ramp"**
as the per-tier tell. The body returns to a **pure skin slot**. The other tier reads stay:
**barrels = multishot count**, **tier badge = number**, **T10 = gold accent ring**.

---

## 1. Decision

The tier-investment signal is a **ground glow** under the tower — a soft radial light pooled at
the tower's base — that **intensifies with merge tier** and whose **color is set per board** so it
stays legible against any ground.

Why ground glow (over the outline ring / "both" tested 2026-06-23): it reads as the tower's
investment without fighting the body silhouette or the heavy dark outline, and it sits on the
*ground* layer where per-board contrast is the only variable to solve. The ring competed with the
tower outline and was redundant with the T10 gold ring.

Why per-board color: no single ramp reads on every board. Against terracotta (Suburbia) a **warm**
glow pops; against the bright/saturated greens (Summer, Forest) a **cool** glow pops and warm
washes out. Boards are an abundant cosmetic slot, so the ramp is an **authored per-board property**,
not one global value.

The tower art is **identical across tiers** for the glow's purpose — only the aura changes. (The
functional morph — barrel count, tier badge — is separate and unchanged.)

---

## 2. Visual model (the glow)

- **Shape:** soft radial gradient, circular, centered at the tower's **base-center** — offset down
  ~**10% of tower height** from sprite center so it reads as pooling at the feet, not haloing the body.
- **Layer / z-order:** drawn **behind the tower body**, **above** the board ground + path. Parent it
  to the tower so it tracks position and culls with it.
- **Gradient stops** (fraction of glow radius): inner color at **0%**, mid color at **40%**,
  transparent at **72%**. Inner is a bright near-white tint of the ramp; mid is the ramp's saturated hue.
- **Pulse:** gentle breathing — at peak, **scale ×1.09** and **opacity ×1.35**, ease-in-out, looping.
  Period shortens as tier climbs (higher tier = faster, more "alive"). Pulse is **cosmetic only**
  (see §5) — it must run on visual frame time, never the sim tick.

---

## 3. Tier mapping (T1 → T10)

Merge tiers run **1–10** (pure-merge ladder). **Tier 1 = no aura.** Tiers **2–10** carry the glow,
intensifying monotonically.

The values the user approved on 2026-06-23 were a 3-step preview (low / mid / high). Map them as the
endpoints of the 10-tier curve. For tier `t` in 2..10, let **p = (t − 2) / 8** (0 at T2, 1 at T10):

| Param | T2 (p=0) | T10 (p=1) | Interpolation |
|---|---|---|---|
| Glow diameter | **1.5 × H** | **2.6 × H** | lerp (H = tower on-board height) |
| Edge softness (blur) | **0.14 × H** | **0.30 × H** | lerp |
| Opacity | **0.50** | **0.95** | lerp |
| Pulse period | **2.7 s** | **1.3 s** | lerp (shorter = faster) |

- **Color** is sampled from the board's ramp (3 stops: low → mid → high) at position `p`.
- **Multishot notches (optional, recommended):** the power spikes are at **T3 / T6 / T10** (×2/×3/×4).
  Give those three tiers a small extra brightness/saturation bump so the aura visibly "clicks" at the
  milestones. Not required for v1 if it complicates the curve — the smooth ramp alone reads.
- **T10:** keep the existing **gold accent ring** on the body (already specced in the pivot) *in
  addition* to the hottest glow step.

**These numbers are playtest-tunable** (same posture as every other curve — see `open_items.md`).
Eyeball at real board density (many mixed-tier towers packed in a maze) before committing; if the
glows muddy together, pull opacity and diameter down, not up.

---

## 4. Per-board color ramps

Each ramp is **{inner, mid}** hex per step (inner = bright near-white tint, mid = saturated hue).

**Warm ramp**
| Step | inner | mid |
|---|---|---|
| low  | `#fff0b8` | `#f5c542` |
| mid  | `#ffc488` | `#f0832e` |
| high | `#ffae7a` | `#ff2f24` |

**Cool ramp**
| Step | inner | mid |
|---|---|---|
| low  | `#a6f5d8` | `#21c08c` |
| mid  | `#b3c6ff` | `#4f7bff` |
| high | `#ecbcff` | `#c44eff` |

**Board → ramp (current):**
- **Suburbia** (terracotta brick) → **warm**
- **Summer grass** (bright lime) → **cool**
- **Forest** (deep green) → **cool**
- **Default board** → **cool** (green-ground default)

**Authoring rule for new boards:** pick (or author) the ramp whose glow gives the strongest pop
against that board's ground — judged by eye at authoring time, the same eyeball pass every board gets.
In testing, mid/dark warm grounds took the warm ramp (bright core carries it); bright/cool grounds took
the cool ramp. The ramp keys off the **ground**, not the tower body (the body is a skin slot and can be
any color; it sits on top of the glow's center anyway).

**Whose board's ramp?** Resolve from the board being **rendered**:
- Your own board → your **equipped** board's ramp.
- A **spectated / opponent** board → the **default** board's ramp. (Opponent equipped skins are never
  known and must never ride the match record — same rule as board/tower skins.)

---

## 5. Determinism & the record

- The aura is **render-only**. It is **derived from the tower's merge tier**, which is already real
  gameplay state in the record — so the aura renders **truthfully on every board** (yours and
  spectated), unlike a skin. But the aura visuals themselves **never enter the record**.
- The **pulse** uses engine/visual time or a local tween — **never** the sim tick and **never**
  `randf()` in the sim path. (Sim determinism is load-bearing for re-sim anti-cheat; keep all aura
  animation off it.)
- Because the glow is a separate node from the body, it is **independent of the equipped skin** —
  this is what satisfies the locked "upgrade legibility survives skins" case (see §7).

---

## 6. Implementation hooks (Godot 4 — CC owns this)

*Illustrative only — CC implements.*

- Add a `TierAura` node as a child of the tower, behind the body. Two viable renderers:
  - **Shader on a quad (recommended):** uniforms `inner_color`, `mid_color`, `radius`, `mid_stop=0.40`,
    `edge_stop=0.72`, `alpha`. Exact 2-stop falloff, full control.
  - **Cheap fallback:** one authored soft white radial-gradient PNG; `modulate = mid_color`,
    `scale` per tier, `modulate.a` per tier. Loses the bright inner core but is fine (single-hue art
    tints cleanly at runtime — the established rule for outline/single-hue assets).
- **Drive it from tier:** the per-tier morph already happens in `tower` on place/merge — hook the aura
  update there. T1 → hide. T2..T10 → set diameter/opacity/period/color from §3, ramp from §4.
- **Resolve the ramp** where board/tower skins already resolve (`map_loader` / `build_controller`,
  `is_local` split). Suggest a resolver: `CosmeticsCatalog.aura_ramp_for(board_id)`.
- **Pulse:** an `AnimationPlayer` loop or a `_process`/tween on `scale` + `modulate.a`, period per tier.
- **Retire** the body-color tier ramp from the merge-reference model so the body is a true skin slot.

```gdscript
# illustrative only
func set_tier_aura(tier: int, ramp: AuraRamp, tower_h: float) -> void:
    if tier <= 1:
        aura.visible = false; return
    aura.visible = true
    var p := float(tier - 2) / 8.0
    aura.diameter = lerp(1.5, 2.6, p) * tower_h
    aura.alpha    = lerp(0.50, 0.95, p)
    aura.period   = lerp(2.7, 1.3, p)
    aura.inner    = ramp.inner_at(p)
    aura.mid      = ramp.mid_at(p)
```

---

## 7. Test cases (for `test_case_library.md` — not in every checkout)

- 🔒 **Tier aura is legible on every board** (per-board ramp resolves; warm on Suburbia, cool on the
  greens) **and over every tower skin** (aura is a separate node from the body). Extends the existing
  🔒 "upgrade legibility survives skins."
- Aura is driven by merge tier: **T1 shows none**; T2→T10 intensify; T10 also keeps the gold ring.
- Aura **never enters the record**; pulse never runs on the sim tick (determinism intact).
- Spectated/opponent boards render the aura from the **default** board ramp (no skin leak).
