extends Resource
class_name MapResource

# The single map format shared by all three modes. Campaign missions are
# hand-authored .tres files committed to the repo; PVE/PVP maps are produced
# in memory by map_generator.gd. map_loader.gd consumes this and configures the
# scene — it does not know or care which mode produced the resource.

enum Mode { CAMPAIGN, PVE, PVP }
enum WindowType { DAILY, WEEKLY, MONTHLY }

@export var seed: int = 0
@export var mode: Mode = Mode.CAMPAIGN

# === Layout ===
@export var grid_size: Vector2i = Vector2i(20, 11)  # canonical board (every .tres overrides explicitly)
@export var entry_cell: Vector2i = Vector2i.ZERO
@export var exit_cell: Vector2i = Vector2i.ZERO
@export var checkpoint_cells: Array[Vector2i] = []   # 1–3 entries, in visit order
@export var obstacle_cells: Array[Vector2i] = []      # permanent walls
# Untyped on purpose: a typed Array[ZoneDefinition] is a cross-script reference
# that the project memory flags as failure-prone in .tres. Elements are
# ZoneDefinition resources, enforced by duck-typing in map_loader.
@export var bonus_zones: Array = []

# === Match parameters ===
@export var supply_cap: int = 50
@export var round_count: int = 10
@export var mob_count: int = 8                        # enemy supply, constant per match

# === Scoring — Campaign and PVE only; left at 0 for PVP ===
@export var bronze_threshold: int = 0
@export var silver_threshold: int = 0
@export var gold_threshold: int = 0

# === Campaign-only (0/empty for generated maps) ===
@export var mission_index: int = 0
@export var mission_name: String = ""
@export var mission_description: String = ""

# === PVE-only (0/empty for campaign and PVP) ===
@export var scale_tier: int = 0                       # 1–5
@export var window_type: WindowType = WindowType.DAILY
@export var window_date: String = ""                  # ISO date, e.g. "2026-05-30"
