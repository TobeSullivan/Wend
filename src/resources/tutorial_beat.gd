extends Resource
class_name TutorialBeat

@export var trigger: String = "on_mission_load"

@export_multiline var text: String = ""

@export var anchor: String = ""

@export var ghost_cells: Array[Vector2i] = []

@export var blocking: bool = false
