## AiOpponent – drives the enemy paddle in sea combat.
## Simple AI: tracks the ball, fires occasionally.
## Surrenders when either SP or MP falls to 75% of starting values.
extends Node

## Reference to the enemy paddle node.
var paddle: Node2D = null
## Starting pearl values (set at combat start).
var start_sp: int = 80
var start_mp: int = 80
var sp: int = 80
var mp: int = 80

const FLEE_THRESHOLD := 0.75
const AI_SPEED := 180.0

## Attack pattern resource.
var attack_ability: CombatAbility = null
var wall_ability: CombatAbility = null

## Tracks whether AI has attempted to flee.
var has_fled: bool = false

signal ai_fled(remaining_sp: int, remaining_mp: int)
## Emitted when AI wants to fire; SeaCombat handles actual ball spawning.
signal ai_fired(pattern: AttackPattern)

func setup(enemy_sp: int, enemy_mp: int,
		   p_attack: AttackPattern, p_wall: WallPattern,
		   p_paddle: Node2D) -> void:
	start_sp = enemy_sp
	start_mp = enemy_mp
	sp = enemy_sp
	mp = enemy_mp
	paddle = p_paddle
	attack_ability = CombatAbility.new(p_attack)
	wall_ability = CombatAbility.new(p_wall)
	print("[AI] Setup – SP=", sp, " MP=", mp)

## Called every frame by SeaCombat.
func ai_process(delta: float, balls: Array) -> void:
	if has_fled:
		return
	_tick_abilities(delta)
	_check_flee()
	_track_ball(delta, balls)
	_try_fire()

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

func _try_fire() -> void:
	if attack_ability == null or not attack_ability.is_ready():
		return
	var pattern := attack_ability.pattern as AttackPattern
	if pattern == null:
		return
	if mp >= pattern.mp_cost and randf() > 0.6:
		mp -= pattern.mp_cost
		attack_ability.use()
		ai_fired.emit(pattern)
		print("[AI] Fires attack – MP remaining: ", mp)
