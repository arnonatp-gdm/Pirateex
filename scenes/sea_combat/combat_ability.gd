## CombatAbility – tracks cooldown and reset multiplier for one ability.
## Used by both player and AI paddles.
class_name CombatAbility
extends RefCounted

## Pattern resource (AttackPattern or WallPattern).
var pattern: Resource = null
var cooldown_remaining: float = 0.0
var base_cost: int = 1          # SP for wall, MP for attack
var reset_multiplier: int = 1   # doubles each consecutive reset until timer fills

signal ready_changed(is_ready: bool)

func _init(p_pattern: Resource) -> void:
	pattern = p_pattern
	if pattern is AttackPattern:
		base_cost = pattern.mp_cost
	elif pattern is WallPattern:
		base_cost = pattern.sp_cost

## Returns true if ability is off cooldown.
func is_ready() -> bool:
	return cooldown_remaining <= 0.0

## Tick cooldown. Returns true when cooldown just completed.
func tick(delta: float) -> bool:
	if cooldown_remaining <= 0.0:
		return false
	cooldown_remaining -= delta
	if cooldown_remaining <= 0.0:
		cooldown_remaining = 0.0
		reset_multiplier = 1
		ready_changed.emit(true)
		return true
	return false

## Use the ability (start cooldown). Returns actual cost paid.
func use() -> int:
	var cooldown_duration: float = _get_cooldown()
	cooldown_remaining = cooldown_duration
	var cost := base_cost
	ready_changed.emit(false)
	return cost

## Reset cooldown early for double the cost (doubles each consecutive reset).
## Returns extra cost to pay. Returns -1 if already ready.
func reset_early() -> int:
	if is_ready():
		return -1
	var extra_cost := base_cost * reset_multiplier * 2
	reset_multiplier = clamp(reset_multiplier * 2, 1, 16)
	cooldown_remaining = 0.0
	ready_changed.emit(true)
	return extra_cost

func _get_cooldown() -> float:
	if pattern is AttackPattern:
		return pattern.cooldown
	if pattern is WallPattern:
		return pattern.cooldown
	return 5.0
