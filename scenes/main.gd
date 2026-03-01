## Main – root scene that reacts to GameState phase changes and swaps sub-scenes.
extends Node

## Preloaded phase scenes.
const SEA_EXPLORATION_SCENE := preload("res://scenes/sea_exploration/sea_map.tscn")
const SEA_COMBAT_SCENE     := preload("res://scenes/sea_combat/sea_combat.tscn")
const TOWN_EXPLORATION_SCENE := preload("res://scenes/town_exploration/town.tscn")
const TOWN_COMBAT_SCENE    := preload("res://scenes/town_combat/town_combat.tscn")

var _active_scene: Node = null

func _ready() -> void:
	GameState.phase_changed.connect(_on_phase_changed)
	_init_player()
	# Start in sea exploration.
	GameState.switch_phase(GameState.Phase.SEA_EXPLORATION)

func _init_player() -> void:
	var ship: ShipData = load("res://data/ships/corvette.tres")
	# Stub: pick first upgrade from settlers as default starting upgrade.
	var upgrade: UpgradeData = load("res://data/upgrades/settlers_compass.tres")
	PlayerState.initialize_ship(ship, [upgrade] as Array[UpgradeData])
	PlayerState.ship_name = "The Wanderer"
	print("[Main] Player initialised – SP=", PlayerState.sp, " MP=", PlayerState.mp)

func _on_phase_changed(new_phase: GameState.Phase, _context: Dictionary) -> void:
	_swap_scene(new_phase)

func _swap_scene(phase: GameState.Phase) -> void:
	if _active_scene != null:
		_active_scene.queue_free()
		_active_scene = null

	var scene_res: PackedScene = null
	match phase:
		GameState.Phase.SEA_EXPLORATION:
			scene_res = SEA_EXPLORATION_SCENE
		GameState.Phase.SEA_COMBAT:
			scene_res = SEA_COMBAT_SCENE
		GameState.Phase.TOWN_EXPLORATION:
			scene_res = TOWN_EXPLORATION_SCENE
		GameState.Phase.TOWN_COMBAT:
			scene_res = TOWN_COMBAT_SCENE

	if scene_res != null:
		_active_scene = scene_res.instantiate()
		add_child(_active_scene)
