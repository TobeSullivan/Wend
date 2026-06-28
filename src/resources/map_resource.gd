extends Resource
class_name MapResource

enum Mode { CAMPAIGN, PVE, PVP }
enum WindowType { DAILY, WEEKLY, MONTHLY }

@export var map_seed: int = 0
@export var mode: Mode = Mode.CAMPAIGN

@export var grid_size: Vector2i = Vector2i(25, 16)
@export var entry_cell: Vector2i = Vector2i.ZERO
@export var exit_cell: Vector2i = Vector2i.ZERO
@export var checkpoint_cells: Array[Vector2i] = []
@export var obstacles: Array = []
@export var obstacle_cells: Array[Vector2i] = []
@export var bonus_zones: Array = []

@export var supply_cap: int = 50
@export var round_count: int = 10
@export var mob_count: int = 8

@export var star1_threshold: int = 0
@export var star2_threshold: int = 0
@export var star3_threshold: int = 0

@export var mission_index: int = 0
@export var mission_name: String = ""
@export var mission_description: String = ""
@export var tutorial_beats: Array = []

@export var scale_tier: int = 0
@export var window_type: WindowType = WindowType.DAILY
@export var window_date: String = ""
