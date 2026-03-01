## NpcShip – represents one NPC vessel sailing between islands.
## Moves from origin island to destination, then picks a new destination.
extends Node2D

const SPEED := 60.0
const INTERACT_DIST := 40.0  # pixels before "arriving" at island.

var npc_data: Dictionary = {}

var _target_pos: Vector2 = Vector2.ZERO
var _arrived: bool = false

func setup(data: Dictionary) -> void:
	npc_data = data
	if WorldState.islands.size() > 0:
		var origin_idx: int = npc_data.get("origin", 0)
		origin_idx = clamp(origin_idx, 0, WorldState.islands.size() - 1)
		position = WorldState.islands[origin_idx].position
		_pick_next_destination()

func _pick_next_destination() -> void:
	if WorldState.islands.is_empty():
		return
	var dest_idx: int = randi() % WorldState.islands.size()
	npc_data["destination"] = dest_idx
	_target_pos = WorldState.islands[dest_idx].position
	_arrived = false

func _process(delta: float) -> void:
	if _arrived:
		return
	var dir := (_target_pos - position)
	if dir.length() < INTERACT_DIST:
		_on_arrived()
	else:
		position += dir.normalized() * SPEED * delta
	queue_redraw()

func _on_arrived() -> void:
	_arrived = true
	# Randomly trade or attack (stub).
	var action := "trade" if randf() > 0.4 else "attack"
	print("[NpcShip #", npc_data["id"], "] ", npc_data["faction"],
		" – ", action, " at island #", npc_data["destination"])
	if action == "trade":
		WorldState.npc_record_success(npc_data["id"])
	# Wait then move on.
	await get_tree().create_timer(2.0).timeout
	_pick_next_destination()

func _draw() -> void:
	# Colour matches faction.
	var col := Color.WHITE
	var faction: FactionData = WorldState.get_faction(npc_data.get("faction", ""))
	if faction != null:
		col = faction.color
	# Triangle representing the ship.
	var pts: PackedVector2Array = [
		Vector2(0, -10), Vector2(-7, 8), Vector2(7, 8)
	]
	draw_colored_polygon(pts, col)
	# Famous captain indicator.
	if npc_data.get("is_famous", false):
		draw_arc(Vector2.ZERO, 14, 0, TAU, 16, Color.YELLOW, 2.0)
