## SeaMap – sea exploration phase.
## Renders 13 islands as placeholder markers; spawns NPC ships that move
## between islands and can initiate trade or attack interactions.
extends Node2D

const NPC_SHIP_SCENE := preload("res://scenes/sea_exploration/npc_ship.tscn")

## Island visual radius in pixels.
const ISLAND_RADIUS := 20.0
## Player movement speed (pixels/sec).
const PLAYER_SPEED := 150.0

## Runtime island nodes keyed by island_id.
var _island_nodes: Dictionary = {}
## Player position on the map.
var _player_pos: Vector2 = Vector2(640, 360)
## Drawn NPC ship nodes.
var _npc_nodes: Array = []

func _ready() -> void:
	print("[SeaMap] Entering sea exploration.")
	_build_islands()
	_spawn_npc_ships()

func _build_islands() -> void:
	for isl: IslandData in WorldState.islands:
		var node := Node2D.new()
		node.position = isl.position
		node.name = "Island_" + str(isl.island_id)
		add_child(node)
		_island_nodes[isl.island_id] = node

func _spawn_npc_ships() -> void:
	for npc in WorldState.npc_ships:
		var ship_node: Node2D = NPC_SHIP_SCENE.instantiate()
		ship_node.setup(npc)
		add_child(ship_node)
		_npc_nodes.append(ship_node)

func _process(delta: float) -> void:
	_handle_player_movement(delta)
	_draw_debug()
	_check_island_proximity()

func _handle_player_movement(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	_player_pos += dir * PLAYER_SPEED * delta
	_player_pos.x = clamp(_player_pos.x, 0, 1280)
	_player_pos.y = clamp(_player_pos.y, 0, 720)

func _draw_debug() -> void:
	queue_redraw()

func _draw() -> void:
	# Player ship (blue dot).
	draw_circle(_player_pos, 10, Color.CYAN)
	# Islands.
	for isl: IslandData in WorldState.islands:
		var owner_faction: FactionData = isl.controlling_faction
		var col := Color.WHITE
		if owner_faction != null:
			col = owner_faction.color
		draw_circle(isl.position, ISLAND_RADIUS, col)
		draw_string(ThemeDB.fallback_font, isl.position + Vector2(ISLAND_RADIUS + 4, 4),
			isl.island_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	# HUD
	draw_string(ThemeDB.fallback_font, Vector2(10, 20),
		"SEA EXPLORATION  SP:%d  MP:%d" % [PlayerState.sp, PlayerState.mp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(10, 40),
		"[A/D] Move  [E] Interact  [Q] Attack  [W] Trade",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.LIGHT_GRAY)

## Check if player is near an island to enable interaction.
func _check_island_proximity() -> void:
	const INTERACT_DIST := 60.0
	if Input.is_action_just_pressed("ui_interact"):
		for isl: IslandData in WorldState.islands:
			if _player_pos.distance_to(isl.position) < INTERACT_DIST:
				print("[SeaMap] Near island: ", isl.island_name, " – entering town.")
				GameState.switch_phase(GameState.Phase.TOWN_EXPLORATION,
					{"island_id": isl.island_id})
				return

## Any nearby NPC ship can trigger combat (placeholder: press Q).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_attack"):
		_try_attack_nearest_npc()

func _try_attack_nearest_npc() -> void:
	const ATTACK_DIST := 100.0
	for node in _npc_nodes:
		if not is_instance_valid(node):
			continue
		if _player_pos.distance_to(node.position) < ATTACK_DIST:
			var npc: Dictionary = node.npc_data
			print("[SeaMap] Initiating combat vs NPC: ", npc["faction"],
				" tier=", npc.get("ship_tier", 1))
			GameState.switch_phase(GameState.Phase.SEA_COMBAT, {
				"enemy_sp": npc["sp"],
				"enemy_mp": npc["mp"],
				"enemy_bounty": npc["bounty"],
				"npc_id": npc["id"],
				"enemy_faction": npc.get("faction", "Settlers"),
				"enemy_tier": npc.get("ship_tier", 1),
			})
			return
	print("[SeaMap] No NPC in range to attack.")
