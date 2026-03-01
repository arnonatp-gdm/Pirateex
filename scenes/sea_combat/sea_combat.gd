## SeaCombat – pong-like sea combat phase.
##
## Layout (Y axis):
##   0   ─── enemy side (top) ───
##  360  ─── mid-field ───
##  720  ─── player side (bottom) ───
##
## Controls:
##   A/D           – move paddle left/right
##   R             – fire primary attack pattern (costs MP)
##   Y             – deploy primary wall (costs SP)
##   Double-click  – toggles secondary patterns for R/Y
##   F             – flee (only available at/below 50% SP or MP)
##
## Pearl rules:
##   - SP lost when player's ship is hit (ball reaches bottom)
##   - MP consumed when player fires
##   - Warn+allow flee when SP or MP ≤ 50% of start values
##   - Lose (ship lost) when SP or MP hits 0
##
## AI surrenders at 75% of its starting values.
extends Node2D

const BALL_SCENE        := preload("res://scenes/sea_combat/ball.tscn")
const WALL_SCENE        := preload("res://scenes/sea_combat/wall_segment.tscn")
const PADDLE_SCENE      := preload("res://scenes/sea_combat/paddle.tscn")

## Default patterns (loaded from data/).
const DEFAULT_ATTACK_PRIMARY   := preload("res://data/patterns/attack_single.tres")
const DEFAULT_ATTACK_SECONDARY := preload("res://data/patterns/attack_triple.tres")
const DEFAULT_WALL_PRIMARY     := preload("res://data/patterns/wall_standard.tres")
const DEFAULT_WALL_SECONDARY   := preload("res://data/patterns/wall_double.tres")

const BALL_SPEED := 250.0

## Enemy starting pearls (from phase context).
var _enemy_sp: int = 80
var _enemy_mp: int = 80
var _enemy_bounty: int = 0
var _npc_id: int = -1

## Starting values for flee threshold.
var _start_player_sp: int = 0
var _start_player_mp: int = 0

var _player_paddle: Node2D = null
var _enemy_paddle: Node2D = null
var _ai: Node = null
var _balls: Array = []
var _walls: Array = []

## Player combat abilities.
var _player_attack_primary: CombatAbility = null
var _player_attack_secondary: CombatAbility = null
var _player_wall_primary: CombatAbility = null
var _player_wall_secondary: CombatAbility = null
var _use_secondary: bool = false

var _can_flee: bool = false
var _combat_over: bool = false

## Debug/HUD message.
var _status_msg: String = ""

func _ready() -> void:
	var context := GameState.phase_context
	_enemy_sp = context.get("enemy_sp", 80)
	_enemy_mp = context.get("enemy_mp", 80)
	_enemy_bounty = context.get("enemy_bounty", 0)
	_npc_id = context.get("npc_id", -1)

	_start_player_sp = PlayerState.sp
	_start_player_mp = PlayerState.mp

	print("[SeaCombat] Start – player SP=", PlayerState.sp,
		" MP=", PlayerState.mp,
		" enemy SP=", _enemy_sp, " MP=", _enemy_mp)

	_build_paddles()
	_build_player_abilities()
	_build_ai()

func _build_paddles() -> void:
	# Player paddle at bottom.
	_player_paddle = PADDLE_SCENE.instantiate()
	_player_paddle.position = Vector2(640, 680)
	_player_paddle.is_player = true
	add_child(_player_paddle)

	# Enemy paddle at top.
	_enemy_paddle = PADDLE_SCENE.instantiate()
	_enemy_paddle.position = Vector2(640, 40)
	_enemy_paddle.is_player = false
	add_child(_enemy_paddle)

func _build_player_abilities() -> void:
	_player_attack_primary   = CombatAbility.new(DEFAULT_ATTACK_PRIMARY)
	_player_attack_secondary = CombatAbility.new(DEFAULT_ATTACK_SECONDARY)
	_player_wall_primary     = CombatAbility.new(DEFAULT_WALL_PRIMARY)
	_player_wall_secondary   = CombatAbility.new(DEFAULT_WALL_SECONDARY)

func _build_ai() -> void:
	_ai = load("res://scenes/sea_combat/ai_opponent.gd").new()
	_ai.setup(_enemy_sp, _enemy_mp,
		DEFAULT_ATTACK_PRIMARY, DEFAULT_WALL_PRIMARY, _enemy_paddle)
	_ai.ai_fled.connect(_on_ai_fled)
	_ai.ai_fired.connect(_on_ai_fired)
	add_child(_ai)

# ──────────────────────────────────────────────────────────────────────
# Per-frame update
# ──────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _combat_over:
		return

	_tick_player_abilities(delta)
	_ai.ai_process(delta, _balls)
	_move_balls(delta)
	_check_ball_paddle_hits()
	_check_ball_wall_hits()
	_check_ball_ball_hits()
	_check_flee_condition()
	queue_redraw()

func _tick_player_abilities(delta: float) -> void:
	_player_attack_primary.tick(delta)
	_player_attack_secondary.tick(delta)
	_player_wall_primary.tick(delta)
	_player_wall_secondary.tick(delta)

# ──────────────────────────────────────────────────────────────────────
# Input
# ──────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _combat_over:
		return

	# Toggle primary/secondary patterns on double-click.
	if event.is_action_pressed("action_secondary"):
		_use_secondary = !_use_secondary
		_status_msg = "Using %s patterns." % ("secondary" if _use_secondary else "primary")
		print("[SeaCombat] Pattern mode: ", _status_msg)
		return

	if event.is_action_pressed("action_attack"):
		_player_fire()
	elif event.is_action_pressed("action_wall"):
		_player_deploy_wall()
	elif event.is_action_pressed("action_flee"):
		_try_flee()

func _active_attack() -> CombatAbility:
	return _player_attack_secondary if _use_secondary else _player_attack_primary

func _active_wall() -> CombatAbility:
	return _player_wall_secondary if _use_secondary else _player_wall_primary

# ──────────────────────────────────────────────────────────────────────
# Player actions
# ──────────────────────────────────────────────────────────────────────
func _player_fire() -> void:
	var ability := _active_attack()
	var pattern := ability.pattern as AttackPattern
	if pattern == null:
		return

	if not ability.is_ready():
		# Offer reset for double cost.
		var extra := ability.reset_early()
		if not PlayerState.spend_mp(extra):
			_status_msg = "Not enough MP to reset cooldown!"
			print("[SeaCombat] ", _status_msg)
			return
		print("[SeaCombat] Attack cooldown reset, paid MP: ", extra)
		_fire_balls(pattern, "player")
		return

	if not PlayerState.spend_mp(pattern.mp_cost):
		_status_msg = "Not enough MP to fire!"
		print("[SeaCombat] ", _status_msg)
		return

	ability.use()
	_fire_balls(pattern, "player")
	_check_zero_pearls()

func _fire_balls(pattern: AttackPattern, owner: String) -> void:
	var base_dir := Vector2(0, -1) if owner == "player" else Vector2(0, 1)
	var spread := deg_to_rad(pattern.spread_degrees)
	for i in range(pattern.ball_count):
		var angle := 0.0
		if pattern.ball_count > 1:
			angle = lerp(-spread / 2, spread / 2, float(i) / (pattern.ball_count - 1))
		var vel := base_dir.rotated(angle) * BALL_SPEED
		var start_pos := _player_paddle.position + Vector2(0, -20) \
			if owner == "player" else _enemy_paddle.position + Vector2(0, 20)
		var ball: Node2D = BALL_SCENE.instantiate()
		ball.setup(pattern.ball_pearl_value, vel, owner)
		ball.position = start_pos
		add_child(ball)
		_balls.append(ball)
	print("[SeaCombat] Fired %d ball(s) – pattern: %s" % [pattern.ball_count, pattern.pattern_name])

func _player_deploy_wall() -> void:
	var ability := _active_wall()
	var pattern := ability.pattern as WallPattern
	if pattern == null:
		return

	if not ability.is_ready():
		var extra := ability.reset_early()
		if PlayerState.sp < extra:
			_status_msg = "Not enough SP to reset wall cooldown!"
			print("[SeaCombat] ", _status_msg)
			return
		PlayerState.lose_sp(extra)
		print("[SeaCombat] Wall cooldown reset, paid SP: ", extra)
		_place_walls(pattern, "player")
		return

	if PlayerState.sp < pattern.sp_cost:
		_status_msg = "Not enough SP to deploy wall!"
		print("[SeaCombat] ", _status_msg)
		return

	PlayerState.lose_sp(pattern.sp_cost)
	ability.use()
	_place_walls(pattern, "player")
	_check_zero_pearls()

func _place_walls(pattern: WallPattern, owner: String) -> void:
	var anchor_paddle := _player_paddle if owner == "player" else _enemy_paddle
	var base_y := anchor_paddle.position.y - 30 if owner == "player" \
		else anchor_paddle.position.y + 30
	for i in range(pattern.segment_count):
		var offset_x := (i - (pattern.segment_count - 1) / 2.0) * (pattern.segment_length + 10)
		var wall: Node2D = WALL_SCENE.instantiate()
		wall.setup(pattern.wall_pearl_value, pattern.segment_length, owner)
		wall.position = Vector2(anchor_paddle.position.x + offset_x, base_y)
		add_child(wall)
		_walls.append(wall)
	print("[SeaCombat] Deployed %d wall segment(s)" % pattern.segment_count)

# ──────────────────────────────────────────────────────────────────────
# Physics / collision
# ──────────────────────────────────────────────────────────────────────
func _move_balls(delta: float) -> void:
	# Clean up freed balls.
	_balls = _balls.filter(func(b): return is_instance_valid(b))

func _check_ball_paddle_hits() -> void:
	var to_remove: Array = []
	for ball in _balls:
		if not is_instance_valid(ball):
			continue
		# Enemy ball heading toward player (moving downward).
		if ball.owner_id == "enemy" and ball.velocity.y > 0:
			if ball.position.y >= _player_paddle.position.y - 20:
				if _paddle_overlaps_ball(_player_paddle, ball):
					ball.velocity.y = -abs(ball.velocity.y)
				elif ball.position.y > 720 + ball.radius:
					# Missed player → SP damage.
					print("[SeaCombat] Player hit! SP loss: ", ball.pearl_value)
					PlayerState.lose_sp(ball.pearl_value)
					to_remove.append(ball)
					_check_zero_pearls()

		# Player ball heading toward enemy (moving upward, y decreasing).
		elif ball.owner_id == "player" and ball.velocity.y < 0:
			if ball.position.y <= _enemy_paddle.position.y + 20:
				if _paddle_overlaps_ball(_enemy_paddle, ball):
					ball.velocity.y = abs(ball.velocity.y)
				elif ball.position.y < -ball.radius:
					# Missed enemy → enemy takes SP damage.
					print("[SeaCombat] Enemy hit! Enemy SP loss: ", ball.pearl_value)
					_ai.sp = max(0, _ai.sp - ball.pearl_value)
					to_remove.append(ball)
					if _ai.sp <= 0:
						_combat_win()

	for b in to_remove:
		if is_instance_valid(b):
			b.queue_free()
	_balls = _balls.filter(func(b): return is_instance_valid(b))

func _paddle_overlaps_ball(paddle: Node2D, ball: Node2D) -> bool:
	var pr := paddle.get_rect()
	return pr.has_point(ball.position)

func _check_ball_wall_hits() -> void:
	_walls = _walls.filter(func(w): return is_instance_valid(w))
	var to_remove: Array = []
	for ball in _balls:
		if not is_instance_valid(ball):
			continue
		for wall in _walls:
			if not is_instance_valid(wall):
				continue
			if wall.get_rect().has_point(ball.position):
				ball.bounce_off_wall(wall.pearl_value)
				if not is_instance_valid(ball):
					break  # ball vanished
	_balls = _balls.filter(func(b): return is_instance_valid(b))

func _check_ball_ball_hits() -> void:
	for i in range(_balls.size()):
		for j in range(i + 1, _balls.size()):
			var a: Node2D = _balls[i]
			var b2: Node2D = _balls[j]
			if not is_instance_valid(a) or not is_instance_valid(b2):
				continue
			if a.owner_id == b2.owner_id:
				continue  # only cross-team collisions
			if a.position.distance_to(b2.position) < a.radius + b2.radius:
				a.collide_with_ball(b2)
	_balls = _balls.filter(func(b): return is_instance_valid(b))

# ──────────────────────────────────────────────────────────────────────
# Win / lose / flee
# ──────────────────────────────────────────────────────────────────────
func _check_flee_condition() -> void:
	var sp_ratio := float(PlayerState.sp) / float(_start_player_sp) if _start_player_sp > 0 else 1.0
	var mp_ratio := float(PlayerState.mp) / float(_start_player_mp) if _start_player_mp > 0 else 1.0
	_can_flee = (sp_ratio <= 0.5 or mp_ratio <= 0.5)

func _try_flee() -> void:
	if not _can_flee:
		_status_msg = "Cannot flee yet. Pearls still above 50%."
		print("[SeaCombat] ", _status_msg)
		return
	print("[SeaCombat] Player flees!")
	_end_combat(false, true)

func _check_zero_pearls() -> void:
	if PlayerState.sp <= 0 or PlayerState.mp <= 0:
		print("[SeaCombat] Player out of pearls – ship lost!")
		_end_combat(false, false)

func _combat_win() -> void:
	print("[SeaCombat] Victory! Claiming half of enemy pearls.")
	PlayerState.add_sp(_enemy_sp / 2)
	PlayerState.add_mp(_enemy_mp / 2)
	if _enemy_bounty > 0:
		PlayerState.add_sp(_enemy_bounty)
		print("[SeaCombat] Collected bounty: ", _enemy_bounty)
	PlayerState.record_interaction("attack",
		GameState.phase_context.get("faction", "unknown"), "success")
	_end_combat(true, false)

func _on_ai_fled(_remaining_sp: int, _remaining_mp: int) -> void:
	print("[SeaCombat] Enemy surrendered!")
	_combat_win()

func _on_ai_fired(pattern: AttackPattern) -> void:
	_fire_balls(pattern, "enemy")

func _end_combat(won: bool, fled: bool) -> void:
	if _combat_over:
		return
	_combat_over = true
	var result_msg := "Player won!" if won else ("Player fled." if fled else "Ship lost!")
	print("[SeaCombat] Combat ended – ", result_msg)

	if not won and not fled:
		# Ship lost – respawn flow.
		var ship: ShipData = load("res://data/ships/corvette.tres")
		PlayerState.respawn_ship(ship, "The Wanderer II")

	# Return to sea exploration.
	await get_tree().create_timer(1.0).timeout
	GameState.switch_phase(GameState.Phase.SEA_EXPLORATION)

# ──────────────────────────────────────────────────────────────────────
# HUD draw
# ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	# Background.
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.05, 0.05, 0.2))
	# Midfield line.
	draw_line(Vector2(0, 360), Vector2(1280, 360), Color(0.3, 0.3, 0.5), 1)

	# HUD – player stats.
	var flee_hint := "  [F] FLEE AVAILABLE!" if _can_flee else ""
	draw_string(ThemeDB.fallback_font, Vector2(10, 715),
		"SP:%d  MP:%d%s" % [PlayerState.sp, PlayerState.mp, flee_hint],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	# HUD – enemy stats.
	draw_string(ThemeDB.fallback_font, Vector2(10, 15),
		"ENEMY SP:%d  MP:%d" % [_ai.sp, _ai.mp],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.ORANGE_RED)
	# Pattern mode.
	var mode_str := "SECONDARY" if _use_secondary else "PRIMARY"
	draw_string(ThemeDB.fallback_font, Vector2(900, 360),
		"Pattern: %s  [DblClick toggle]" % mode_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)
	# Controls.
	draw_string(ThemeDB.fallback_font, Vector2(10, 695),
		"[A/D] Move  [R] Attack  [Y] Wall  [F] Flee",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.LIGHT_GRAY)
	# Cooldown indicators.
	_draw_cooldown_bar(Vector2(10, 670), "ATK", _active_attack())
	_draw_cooldown_bar(Vector2(200, 670), "WALL", _active_wall())
	# Status.
	if _status_msg != "":
		draw_string(ThemeDB.fallback_font, Vector2(400, 360),
			_status_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.YELLOW)

func _draw_cooldown_bar(pos: Vector2, label: String, ability: CombatAbility) -> void:
	if ability == null:
		return
	draw_string(ThemeDB.fallback_font, pos, label + ":", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	var bar_x := pos.x + 40
	var bar_y := pos.y - 10
	var max_cd: float = ability.pattern.cooldown if ability.pattern != null else 5.0
	var progress := 1.0 - clamp(ability.cooldown_remaining / max_cd, 0.0, 1.0)
	draw_rect(Rect2(bar_x, bar_y, 100, 10), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(bar_x, bar_y, 100 * progress, 10),
		Color.GREEN if ability.is_ready() else Color.YELLOW)
