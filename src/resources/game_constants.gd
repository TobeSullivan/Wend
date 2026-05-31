extends Node

# Global constants — values that apply universally across all maps and modes.
# Per-map values (grid, layout, supply, rounds, thresholds) live in MapResource.
# Registered as the `GameConstants` autoload singleton (see project.godot).
# Nothing here is per-map; if a value varies by map it belongs in MapResource.

# === Economy ===
const STARTING_GOLD := 250
const TOWER_COST := 10
const KILL_BONUS := 1
const ROUND_BONUS_BASE := 25      # actual round bonus = ROUND_BONUS_BASE + completed_round
const INTEREST_RATE := 0.10       # 1g earned per 10g held
const INTEREST_CAP := 50          # max interest awarded per round
const SELL_REFUND_RATE := 0.30    # fraction of total invested returned on sell

# === Build phase timings (seconds) ===
const BUILD_TIME_FIRST := 30.0
const BUILD_TIME_NORMAL := 25.0
const BUILD_TIME_LATE := 8.0
const LATE_ROUND_THRESHOLD := 30  # rounds at/after this use the compressed timer

# === Mob ===
const MOB_BASE_HP := 100.0
const MOB_SPEED := 80.0            # pixels/sec
const MOB_SLOW_FLOOR := 0.10       # never reduced below 10% base speed by stacked slows
const MOB_HP_FLAT_ROUNDS := 5      # HP constant through this round
const MOB_HP_GROWTH := 1.12        # HP ×/round after the flat window
const SPAWN_INTERVAL := 1.0        # seconds between mob spawns

# === Tower base stats ===
const TOWER_BASE_RANGE := 160.0    # pixels (~3.3 tiles at 48px/tile)
const TOWER_BASE_DAMAGE := 25.0
const TOWER_BASE_COOLDOWN := 0.8
const TOWER_TIER_INCREMENT := 0.10 # +10% per tier on most stats

# === Crit / multishot caps ===
const CRIT_CHANCE_PER_TIER := 0.10
const CRIT_CHANCE_HARD_CAP := 0.75
const CRIT_DAMAGE_BASE := 1.5
const CRIT_DAMAGE_PER_TIER := 0.20
const MULTISHOT_HARD_CAP := 3      # max +N additional targets

# === Upgrade cost ramp: cost(tier_after) = base * tier_after ===
const UPGRADE_COST_BASE := {
	"damage": 15,
	"range": 20,
	"attack_speed": 20,
	"crit_chance": 25,
	"crit_damage": 25,
	"multishot": 60,
}

# === Lives (PVP) ===
const LIVES_PER_PLAYER := 100      # total pool = LIVES_PER_PLAYER * player_count
