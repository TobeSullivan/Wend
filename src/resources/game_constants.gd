extends Node

const STARTING_GOLD := 250
const TOWER_COST := 10
const KILL_BONUS := 1
const ROUND_BONUS_BASE := 25
const INTEREST_RATE := 0.10
const INTEREST_CAP := 50
const SELL_REFUND_RATE := 0.30

const BUILD_TIME_FIRST := 30.0
const BUILD_TIME_NORMAL := 25.0
const BUILD_TIME_LATE := 8.0
const LATE_ROUND_THRESHOLD := 30

const MOB_BASE_HP := 100.0
const MOB_SPEED := 80.0
const MOB_SLOW_FLOOR := 0.10
const MOB_HP_FLAT_ROUNDS := 5
const MOB_HP_GROWTH := 1.12
const SPAWN_INTERVAL := 1.0

# --- Boss ---
# Mobs die permanently now; a boss rides among the wave every N rounds and a
# leak past it costs a heavy chunk of lives. (design_revisions_2026-06-22 §2)
const BOSS_INTERVAL := 10
const BOSS_HP_MULT := 8.0
const BOSS_LEAK_PENALTY := 5

# --- Fail state (lives) ---
# Trials: leaks cost lives directly; run ends when they hit zero.
# PvP: 100-life see-saw, transferred on LEAKS (not kills); score is the tiebreak.
const TRIALS_LIVES := 10
const LIVES_PER_PLAYER := 100

# --- Tower tier ladder (merge replaces the old free-form upgrades) ---
# Pure merge: two of tier N -> one tier N+1. Max T10 (2^n base towers).
# All stats derive from tier. SCALING IS A PLACEHOLDER (mirrors
# wend_merge_reference.html) -- real balance is deferred, do not treat as final.
const MIN_TIER := 1
const MAX_TIER := 10

# Multishot is the dominant lever: unlocks at T3/T6/T10 -> x2/x3/x4 (cap 4).
const MULTISHOT_T2 := 3
const MULTISHOT_T3 := 6
const MULTISHOT_T4 := 10
const MULTISHOT_HARD_CAP := 4

const TOWER_BASE_RANGE := 160.0
const TOWER_BASE_DAMAGE := 25.0
const TOWER_BASE_COOLDOWN := 0.8

# Per-tier stat curves (placeholder; balance later).
const TIER_DAMAGE_GROWTH := 1.20      # dmg = base * growth^(tier-1)
const TIER_RATE_GROWTH := 1.05        # fire rate scales -> cooldown = base / growth^(tier-1)
const TIER_RANGE_PER_TIER := 10.0     # range += this per tier above 1

# Crit is parked under the tier model (no tier grants it yet); plumbing kept.
const CRIT_CHANCE_HARD_CAP := 0.75
const CRIT_DAMAGE_BASE := 1.5
