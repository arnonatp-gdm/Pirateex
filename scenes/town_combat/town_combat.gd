## TownCombat – placeholder scene for town combat (detailed mechanics TBD).
## Press [Esc] to return to town.
extends Node2D

var _island_id: int = 1

func _ready() -> void:
	_island_id = GameState.phase_context.get("island_id", 1)
	print("[TownCombat] Placeholder – island_id=", _island_id)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		print("[TownCombat] Returning to town.")
		GameState.switch_phase(GameState.Phase.TOWN_EXPLORATION,
			{"island_id": _island_id})

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.2, 0.05, 0.05))
	draw_string(ThemeDB.fallback_font, Vector2(400, 300),
		"TOWN COMBAT – placeholder (mechanics TBD)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.ORANGE_RED)
	draw_string(ThemeDB.fallback_font, Vector2(450, 380),
		"[Esc] Return to Town",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
