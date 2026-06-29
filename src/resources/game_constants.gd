extends Node

const STARTING_GOLD := 250
const TOWER_COST := 10
const KILL_BONUS := 1
const ROUND_BONUS_BASE := 25
const SELL_REFUND_RATE := 0.30

const BUILD_TIME_FIRST := 30.0
const BUILD_TIME_NORMAL := 25.0

const MOB_BASE_HP := 150.0
const MOB_SPEED := 80.0
const MOB_SLOW_FLOOR := 0.10
const MOB_HP_FLAT_ROUNDS := 3
const MOB_HP_GROWTH := 1.12
const SPAWN_INTERVAL := 0.8

const WAVE_COUNT_BASE := 14
const WAVE_COUNT_PER_ROUND := 2
const WAVE_COUNT_MAX := 60

const TRIALS_STAR_ROUNDS := {
	1: [5, 10, 15],
	2: [6, 12, 18],
	3: [8, 14, 20],
	4: [9, 16, 23],
	5: [10, 18, 25],
}

const SCALE_HP_MULT := [0.45, 0.70, 1.0, 1.45, 1.9]
const SCALE_HP_RAMP_ROUND := 18

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

const CRIT_CHANCE_PER_TIER := 0.05
const CRIT_CHANCE_HARD_CAP := 0.75
const CRIT_DAMAGE_BASE := 1.5
const CRIT_DAMAGE_MAX := 2.5
