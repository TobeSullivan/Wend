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

const TOWER_BASE_RANGE := 160.0
const TOWER_BASE_DAMAGE := 25.0
const TOWER_BASE_COOLDOWN := 0.8

const TOWER_DAMAGE_INCREMENT := 0.34
const TOWER_ATTACK_SPEED_INCREMENT := 0.15
const TOWER_RANGE_INCREMENT := 0.10

const CRIT_CHANCE_PER_TIER := 0.10
const CRIT_CHANCE_HARD_CAP := 0.75
const CRIT_DAMAGE_BASE := 1.5
const CRIT_DAMAGE_PER_TIER := 0.20
const MULTISHOT_HARD_CAP := 3

const UPGRADE_COST_BASE := {
	"damage": 15,
	"range": 20,
	"attack_speed": 20,
	"crit_chance": 25,
	"crit_damage": 25,
	"multishot": 60,
}

const LIVES_PER_PLAYER := 100
