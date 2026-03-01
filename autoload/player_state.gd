## PlayerState – autoload singleton holding persistent player data.
## Tracks SP, MP, upgrades, last-5 interactions, evaluation axes.
extends Node

## ---- Pearls ----
var sp: int = 100   # Star Pearls (tech currency; lost when hit)
var mp: int = 100   # Moon Pearls (magic currency; spent to shoot)

## ---- Ship ----
var ship_name: String = "The Wanderer"
var ship_data: ShipData = null        # set at game start
var upgrades: Array[UpgradeData] = []  # active upgrades

## ---- Evaluation axes ----
## tech_score > 0 → tech leaning; < 0 → magic leaning
var tech_score: int = 0
## cultural_score > 0 → cultural/trader; < 0 → chaos/fighter
var cultural_score: int = 0

## ---- Interaction history (last 5) ----
## Each entry: { "type": "trade"|"attack", "faction": String, "result": String }
var last_interactions: Array = []
const MAX_INTERACTIONS: int = 5

## ---- Consecutive-success tracking (for "famous captain" nomination) ----
var consecutive_successes: int = 0
var is_famous: bool = false
var bounty: int = 0

## ---- Island ownership ----
## Once the player starts taking islands, all factions turn hostile.
var owned_islands: Array = []
var hostile_mode: bool = false

signal pearls_changed(sp: int, mp: int)
signal ship_lost()
signal became_famous(bounty: int)

# ---------- Pearl helpers ----------

func add_sp(amount: int) -> void:
	sp = max(0, sp + amount)
	pearls_changed.emit(sp, mp)

func lose_sp(amount: int) -> void:
	sp = max(0, sp - amount)
	pearls_changed.emit(sp, mp)
	if sp == 0:
		_on_ship_lost()

func spend_mp(amount: int) -> bool:
	if mp < amount:
		return false
	mp -= amount
	pearls_changed.emit(sp, mp)
	if mp == 0:
		_on_ship_lost()
	return true

func add_mp(amount: int) -> void:
	mp = max(0, mp + amount)
	pearls_changed.emit(sp, mp)

# ---------- Ship management ----------

func initialize_ship(data: ShipData, chosen_upgrades: Array[UpgradeData] = []) -> void:
	ship_data = data
	sp = data.base_sp
	mp = data.base_mp
	upgrades = chosen_upgrades.duplicate()
	print("[PlayerState] Ship initialised: ", ship_name, " SP=", sp, " MP=", mp)
	pearls_changed.emit(sp, mp)

func _on_ship_lost() -> void:
	print("[PlayerState] Ship lost! Returning to port for a new ship.")
	consecutive_successes = 0
	ship_lost.emit()

func respawn_ship(data: ShipData, new_name: String = "The Wanderer") -> void:
	ship_name = new_name
	initialize_ship(data)

# ---------- Interaction tracking ----------

func record_interaction(type: String, faction_name: String, result: String) -> void:
	var entry := { "type": type, "faction": faction_name, "result": result }
	last_interactions.push_back(entry)
	if last_interactions.size() > MAX_INTERACTIONS:
		last_interactions.pop_front()

	# Evaluation axes
	if type == "trade":
		cultural_score += 1
	else:
		cultural_score -= 1

	if result == "success":
		consecutive_successes += 1
		_check_famous()
	else:
		consecutive_successes = 0

	print("[PlayerState] Interaction recorded: ", entry,
		" consecutive=", consecutive_successes)

func _check_famous() -> void:
	if not is_famous and consecutive_successes >= 3:
		is_famous = true
		bounty = 50
		print("[PlayerState] Player is now a Famous Captain! Bounty: ", bounty)
		became_famous.emit(bounty)

# ---------- Island ownership ----------

func capture_island(island_id: int) -> void:
	if island_id not in owned_islands:
		owned_islands.append(island_id)
		if not hostile_mode:
			hostile_mode = true
			print("[PlayerState] First island captured – all factions now hostile!")
		print("[PlayerState] Island #", island_id, " captured. Total: ", owned_islands.size())

# ---------- Upgrade helpers ----------

func add_upgrade(upgrade: UpgradeData) -> bool:
	if ship_data == null:
		return false
	if upgrades.size() >= ship_data.upgrade_slots:
		print("[PlayerState] No upgrade slots available.")
		return false
	upgrades.append(upgrade)
	# Apply stat bonuses
	sp += upgrade.sp_bonus
	mp += upgrade.mp_bonus
	pearls_changed.emit(sp, mp)
	print("[PlayerState] Upgrade applied: ", upgrade.upgrade_name)
	return true
