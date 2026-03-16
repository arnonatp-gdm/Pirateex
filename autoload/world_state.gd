## WorldState – autoload singleton holding world data (islands, factions, NPC ships).
extends Node

## All 13 islands (populated in _ready from data/).
var islands: Array[IslandData] = []
## All 4 factions.
var factions: Array[FactionData] = []
## Runtime NPC ship instances (Dictionary: id → data dict).
var npc_ships: Array[Dictionary] = []

## Paths to preloaded faction resources.
const FACTION_PATHS: Array = [
	"res://data/factions/settlers.tres",
	"res://data/factions/conquerors.tres",
	"res://data/factions/pirates.tres",
	"res://data/factions/ferals.tres",
]

## Paths to preloaded island resources.
const ISLAND_PATHS: Array = [
	"res://data/islands/island_01.tres",
	"res://data/islands/island_02.tres",
	"res://data/islands/island_03.tres",
	"res://data/islands/island_04.tres",
	"res://data/islands/island_05.tres",
	"res://data/islands/island_06.tres",
	"res://data/islands/island_07.tres",
	"res://data/islands/island_08.tres",
	"res://data/islands/island_09.tres",
	"res://data/islands/island_10.tres",
	"res://data/islands/island_11.tres",
	"res://data/islands/island_12.tres",
	"res://data/islands/island_13.tres",
]

func _ready() -> void:
	_load_factions()
	_load_islands()
	_spawn_npc_ships()
	print("[WorldState] Ready – factions: ", factions.size(),
		" islands: ", islands.size(),
		" NPC ships: ", npc_ships.size())

func _load_factions() -> void:
	for path in FACTION_PATHS:
		if ResourceLoader.exists(path):
			var f: FactionData = load(path)
			factions.append(f)
		else:
			push_warning("[WorldState] Missing faction resource: " + path)

func _load_islands() -> void:
	for path in ISLAND_PATHS:
		if ResourceLoader.exists(path):
			var isl: IslandData = load(path)
			islands.append(isl)
		else:
			push_warning("[WorldState] Missing island resource: " + path)

## Spawn one NPC ship per faction per island pair as simple data dictionaries.
func _spawn_npc_ships() -> void:
	var id := 0
	for faction in factions:
		# Each faction gets 2 NPC ships at game start.
		for _i in range(2):
			var origin_idx := randi() % islands.size()
			var dest_idx := randi() % islands.size()
			npc_ships.append({
				"id": id,
				"faction": faction.faction_name,
				"origin": origin_idx,
				"destination": dest_idx,
				"sp": 80,
				"mp": 80,
				"ship_tier": randi_range(1, 3),
				"consecutive_successes": 0,
				"is_famous": false,
				"bounty": 0,
			})
			id += 1

## Returns the FactionData by name, or null.
func get_faction(name: String) -> FactionData:
	for f in factions:
		if f.faction_name == name:
			return f
	return null

## Returns the IslandData by id, or null.
func get_island(island_id: int) -> IslandData:
	for isl in islands:
		if isl.island_id == island_id:
			return isl
	return null

## Called when an NPC ship completes a successful interaction.
func npc_record_success(npc_id: int) -> void:
	for ship in npc_ships:
		if ship["id"] == npc_id:
			ship["consecutive_successes"] += 1
			if not ship["is_famous"] and ship["consecutive_successes"] >= 3:
				ship["is_famous"] = true
				ship["bounty"] = 40
				print("[WorldState] Famous Captain born! NPC #", npc_id,
					" faction=", ship["faction"])
			return
