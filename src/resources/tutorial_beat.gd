extends Resource
class_name TutorialBeat

# One ordered tutorial beat for a campaign mission (design/CAMPAIGN.md "Tutorial-beat
# system"). Authored as a sub-resource in a MapResource's `tutorial_beats` array; only
# the five campaign maps carry these. TutorialDirector groups them by trigger and fires
# them as the match plays. Generated PVE/PVP maps leave the array empty.
#
# Stored in MapResource.tutorial_beats as an UNTYPED Array (duck-typed in the director),
# mirroring bonus_zones/obstacles — project memory flags typed cross-script Array[X] in
# .tres as failure-prone.

# When this beat fires. One of the trigger ids the director understands:
#   on_mission_load        — at scene load, before the first build (framing line)
#   on_build_phase_start   — first time the player can place towers
#   on_first_tower_placed  — the player's first placement
#   on_round_start         — the run phase begins (timer expiry or Start Round)
#   on_first_kill          — first mob shattered/respawned
#   on_round_end           — a round's run phase finished
#   on_win                 — match over
@export var trigger: String = "on_mission_load"

# The line shown to the player.
@export_multiline var text: String = ""

# Optional region the callout leans toward (no literal pointer-arrow yet): "" (default,
# bottom-center toast), "board", "score", "upgrade_panel". Informational anchors the
# design also lists ("tower", "respawn", "zone") fall back to the default position.
@export var anchor: String = ""

# Optional build-guidance tiles to prompt via the ghost outline (build_guide.gd). Empty
# = no overlay for this beat. A prompted tile clears once the player builds on it.
@export var ghost_cells: Array[Vector2i] = []

# Does play pause until the player acknowledges? Default false (a non-blocking toast).
# Only M1's opening framing beat sets this true.
@export var blocking: bool = false
