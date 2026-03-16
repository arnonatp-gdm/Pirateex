## AiOpponent – drives the enemy paddle in sea combat.
## Faction-specific behavior: Settlers, Conquerors, Pirates, Ferals.
## Surrenders when either SP or MP falls to 75% of starting values.
extends Node

## Reference to the enemy paddle node.
var paddle: Node2D = null
## Starting pearl values (set at combat start).
var start_sp: int = 80
var start_mp: int = 80
var sp: int = 80
var mp: int = 80
var faction: String = "Settlers"
var ship_tier: int = 1

const FLEE_THRESHOLD := 0.75
const AI_SPEED := 180.0

## Ability instances.
var attack_ability: CombatAbility = null
var wall_ability: CombatAbility = null

## Tracks whether AI has attempted to flee.
var has_fled: bool = false

## Faction-specific state.
var _action_count: int = 0          # attacks in current burst (Pirates / Ferals)
var _feral_phase: String = "attack" # "attack" | "wait" for Ferals cycle

signal ai_fled(remaining_sp: int, remaining_mp: int)
## Emitted when AI wants to fire; SeaCombat handles actual ball spawning.
signal ai_fired(pattern: AttackPattern)
## Emitted when AI wants to deploy a wall.
signal ai_walled(pattern: WallPattern, wall_type: String)

func setup(enemy_sp: int, enemy_mp: int,
		   p_attack: AttackPattern, p_wall: WallPattern,
		   p_paddle: Node2D, p_faction: String = "Settlers",
		   p_tier: int = 1) -> void:
	start_sp = enemy_sp
	start_mp = enemy_mp
	sp = enemy_sp
	mp = enemy_mp
	paddle = p_paddle
	faction = p_faction
	ship_tier = p_tier
	attack_ability = CombatAbility.new(p_attack)
	wall_ability = CombatAbility.new(p_wall)
	print("[AI] Setup – SP=", sp, " MP=", mp,
		" faction=", faction, " tier=", ship_tier)

## Called every frame by SeaCombat.
func ai_process(delta: float, balls: Array) -> void:
	if has_fled:
		return
	_tick_abilities(delta)
	_check_flee()
	_track_ball(delta, balls)
	_try_fire()
	_try_wall()

func _tick_abilities(delta: float) -> void:
	if attack_ability != null:
		attack_ability.tick(delta)
	if wall_ability != null:
		wall_ability.tick(delta)

func _check_flee() -> void:
	var sp_ratio: float = float(sp) / float(start_sp) if start_sp > 0 else 1.0
	var mp_ratio: float = float(mp) / float(start_mp) if start_mp > 0 else 1.0
	if sp_ratio <= FLEE_THRESHOLD or mp_ratio <= FLEE_THRESHOLD:
		has_fled = true
		print("[AI] Surrendering – SP_ratio=%.2f MP_ratio=%.2f" % [sp_ratio, mp_ratio])
		ai_fled.emit(sp, mp)

func _track_ball(delta: float, balls: Array) -> void:
	if paddle == null or balls.is_empty():
		return
	# Track nearest ball heading toward the AI side (top half, y < 360).
	var nearest: Node2D = null
	var nearest_dist: float = 1e9
	for b in balls:
		if not is_instance_valid(b):
			continue
		if b.position.y > 360:
			continue  # ball moving toward player side
		var d := abs(paddle.position.x - b.position.x)
		if d < nearest_dist:
			nearest_dist = d
			nearest = b
	if nearest == null:
		return
	# Move toward ball x position.
	var dir: float = sign(nearest.position.x - paddle.position.x)
	paddle.position.x += dir * AI_SPEED * delta
	paddle.position.x = clamp(paddle.position.x, 40, 1240)

# ─── Fire dispatch ────────────────────────────────────────────────────────────
func _try_fire() -> void:
	match faction:
		"Settlers":   _try_fire_settlers()
		"Conquerors": _try_fire_conquerors()
		"Pirates":    _try_fire_pirates()
		"Ferals":     _try_fire_ferals()
		_:            _try_fire_default()

func _try_fire_default() -> void:
	if attack_ability == null or not attack_ability.is_ready():
		return
	var pattern := attack_ability.pattern as AttackPattern
	if pattern == null or mp < pattern.mp_cost:
		return
	if randf() > 0.6:
		mp -= pattern.mp_cost
		attack_ability.use()
		ai_fired.emit(pattern)
		print("[AI] Fires attack – MP remaining: ", mp)

## Settlers: only fire when cooldown has naturally expired; never reset early.
func _try_fire_settlers() -> void:
	_try_fire_default()

## Conquerors: stack 2 attacks per cooldown cycle using reset_early.
func _try_fire_conquerors() -> void:
	if attack_ability == null or not attack_ability.is_ready():
		return
	var pattern := attack_ability.pattern as AttackPattern
	if pattern == null or mp < pattern.mp_cost:
		return
	# First attack.
	mp -= pattern.mp_cost
	attack_ability.use()
	ai_fired.emit(pattern)
	print("[AI] Conquerors fires #1 – MP remaining: ", mp)
	# Immediately stack a second attack via reset_early.
	var extra := attack_ability.reset_early()
	if extra >= 0 and mp >= pattern.mp_cost + extra:
		mp -= pattern.mp_cost + extra
		attack_ability.use()
		ai_fired.emit(pattern)
		print("[AI] Conquerors fires #2 (stacked) – MP remaining: ", mp)

## Pirates: burst 3 attacks, then request a ball-shooting wall.
func _try_fire_pirates() -> void:
	if _action_count >= 3:
		return  # waiting for wall deployment to reset burst
	if attack_ability == null or not attack_ability.is_ready():
		return
	var pattern := attack_ability.pattern as AttackPattern
	if pattern == null or mp < pattern.mp_cost:
		return
	mp -= pattern.mp_cost
	attack_ability.use()
	ai_fired.emit(pattern)
	_action_count += 1
	print("[AI] Pirates fires burst %d/3 – MP remaining: " % _action_count, mp)
	# Reset early to allow fast follow-up shots within the burst.
	if _action_count < 3:
		var extra := attack_ability.reset_early()
		if extra >= 0 and mp >= extra:
			mp -= extra

## Ferals: 5 attacks, wait for natural expiry, then 5 more attacks, repeat.
func _try_fire_ferals() -> void:
	if attack_ability == null:
		return
	if _feral_phase == "wait":
		if attack_ability.is_ready():
			_feral_phase = "attack"
			_action_count = 0
			print("[AI] Ferals re-enter attack phase")
		return
	# Attack phase.
	if not attack_ability.is_ready():
		return
	var pattern := attack_ability.pattern as AttackPattern
	if pattern == null or mp < pattern.mp_cost:
		return
	if _action_count >= 5:
		_feral_phase = "wait"
		print("[AI] Ferals switching to wait phase")
		return
	mp -= pattern.mp_cost
	attack_ability.use()
	ai_fired.emit(pattern)
	_action_count += 1
	print("[AI] Ferals fires %d/5 – MP remaining: " % _action_count, mp)
	# Reset early for rapid follow-ups.
	if _action_count < 5:
		var extra := attack_ability.reset_early()
		if extra >= 0 and mp >= extra:
			mp -= extra

# ─── Wall dispatch ────────────────────────────────────────────────────────────
func _try_wall() -> void:
	match faction:
		"Settlers":   _try_wall_settlers()
		"Conquerors": _try_wall_conquerors()
		"Pirates":    _try_wall_pirates()
		"Ferals":     _try_wall_ferals()
		_:            _try_wall_default()

func _try_wall_default() -> void:
	if wall_ability == null or not wall_ability.is_ready():
		return
	var pattern := wall_ability.pattern as WallPattern
	if pattern == null or sp < pattern.sp_cost:
		return
	sp -= pattern.sp_cost
	wall_ability.use()
	ai_walled.emit(pattern, "standard")

## Settlers: deploy bouncing walls (immune to SP loss) as soon as possible.
func _try_wall_settlers() -> void:
	if wall_ability == null or not wall_ability.is_ready():
		return
	var pattern := wall_ability.pattern as WallPattern
	if pattern == null or sp < pattern.sp_cost:
		return
	sp -= pattern.sp_cost
	wall_ability.use()
	ai_walled.emit(pattern, "bouncing")
	print("[AI] Settlers deploys bouncing wall")

## Conquerors: deploy timer_mod walls that extend player attack cooldowns.
func _try_wall_conquerors() -> void:
	if wall_ability == null or not wall_ability.is_ready():
		return
	var pattern := wall_ability.pattern as WallPattern
	if pattern == null or sp < pattern.sp_cost:
		return
	sp -= pattern.sp_cost
	wall_ability.use()
	ai_walled.emit(pattern, "timer_mod")
	print("[AI] Conquerors deploys timer_mod wall")

## Pirates: deploy ball-shooting wall after completing a 3-attack burst.
func _try_wall_pirates() -> void:
	if _action_count < 3:
		return  # burst not yet complete
	if wall_ability == null or not wall_ability.is_ready():
		return
	var pattern := wall_ability.pattern as WallPattern
	if pattern == null or sp < pattern.sp_cost:
		return
	sp -= pattern.sp_cost
	wall_ability.use()
	ai_walled.emit(pattern, "ball_shooting")
	_action_count = 0  # reset burst counter after wall
	print("[AI] Pirates deploys ball_shooting wall, burst reset")

## Ferals: deploy timer_mod walls that reduce the AI's own attack cooldown.
func _try_wall_ferals() -> void:
	if wall_ability == null or not wall_ability.is_ready():
		return
	var pattern := wall_ability.pattern as WallPattern
	if pattern == null or sp < pattern.sp_cost:
		return
	sp -= pattern.sp_cost
	wall_ability.use()
	ai_walled.emit(pattern, "timer_mod")
	print("[AI] Ferals deploys timer_mod wall (lowers AI timer)")
