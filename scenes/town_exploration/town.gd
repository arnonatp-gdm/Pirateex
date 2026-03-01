## Town – town exploration phase (pub + shop stubs with transaction logic).
## Press [1] to visit pub (hire crew with MP), [2] for shop (buy upgrade with SP).
## Press [Escape] to sail back to sea exploration.
extends Node2D

var _island: IslandData = null
var _status_msg: String = ""

## Available upgrades in this town's shop (stub: fixed list).
const SHOP_UPGRADES: Array = [
	"res://data/upgrades/settlers_compass.tres",
	"res://data/upgrades/pirates_launcher.tres",
]
## MP cost to hire a crew member.
const CREW_MP_COST := 15
## SP reward from hiring crew (flavour buff).
const CREW_SP_BONUS := 0

func _ready() -> void:
	var island_id: int = GameState.phase_context.get("island_id", 1)
	_island = WorldState.get_island(island_id)
	var name_str: String = _island.island_name if _island else "Unknown Island"
	print("[Town] Arrived at: ", name_str)
	_status_msg = "Welcome to " + name_str + "!"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		print("[Town] Leaving town, back to sea.")
		GameState.switch_phase(GameState.Phase.SEA_EXPLORATION)
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_visit_pub()
			KEY_2:
				_visit_shop()
			KEY_3:
				_enter_town_combat()

func _visit_pub() -> void:
	print("[Town] Pub: Hiring crew member for %d MP." % CREW_MP_COST)
	if PlayerState.spend_mp(CREW_MP_COST):
		_status_msg = "Hired a crew member! MP spent: %d. MP remaining: %d" \
			% [CREW_MP_COST, PlayerState.mp]
		PlayerState.record_interaction("trade",
			_island.controlling_faction.faction_name if _island and _island.controlling_faction else "neutral",
			"success")
	else:
		_status_msg = "Not enough MP to hire crew! Need %d MP." % CREW_MP_COST
	print("[Town] ", _status_msg)
	queue_redraw()

func _visit_shop() -> void:
	# Offer first available upgrade from the shop list.
	for path in SHOP_UPGRADES:
		var upgrade: UpgradeData = load(path)
		if upgrade == null:
			continue
		print("[Town] Shop: Offering upgrade '%s' for %d SP." \
			% [upgrade.upgrade_name, upgrade.sp_cost])
		if PlayerState.sp >= upgrade.sp_cost:
			PlayerState.lose_sp(upgrade.sp_cost)
			PlayerState.add_upgrade(upgrade)
			_status_msg = "Bought: %s! SP spent: %d. SP remaining: %d" \
				% [upgrade.upgrade_name, upgrade.sp_cost, PlayerState.sp]
			PlayerState.record_interaction("trade",
				_island.controlling_faction.faction_name \
					if _island and _island.controlling_faction else "neutral",
				"success")
		else:
			_status_msg = "Not enough SP for '%s'. Need %d, have %d." \
				% [upgrade.upgrade_name, upgrade.sp_cost, PlayerState.sp]
		print("[Town] ", _status_msg)
		queue_redraw()
		return
	_status_msg = "No upgrades available in this shop."
	print("[Town] ", _status_msg)
	queue_redraw()

func _enter_town_combat() -> void:
	print("[Town] Entering town combat.")
	GameState.switch_phase(GameState.Phase.TOWN_COMBAT,
		{"island_id": _island.island_id if _island else 1})

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.15, 0.1, 0.05))
	var title := "TOWN: " + (_island.island_name if _island else "?")
	draw_string(ThemeDB.fallback_font, Vector2(500, 50),
		title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.GOLD)
	draw_string(ThemeDB.fallback_font, Vector2(200, 200),
		"[1] Pub – Hire crew (%d MP)" % CREW_MP_COST,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.CYAN)
	draw_string(ThemeDB.fallback_font, Vector2(200, 240),
		"[2] Shop – Buy upgrade (costs SP)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	draw_string(ThemeDB.fallback_font, Vector2(200, 280),
		"[3] Town Combat (stub)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.ORANGE)
	draw_string(ThemeDB.fallback_font, Vector2(200, 340),
		"Player SP:%d  MP:%d" % [PlayerState.sp, PlayerState.mp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(200, 600),
		_status_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.LIGHT_GREEN)
	draw_string(ThemeDB.fallback_font, Vector2(200, 680),
		"[Esc] Return to sea",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.LIGHT_GRAY)
