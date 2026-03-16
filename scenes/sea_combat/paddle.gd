## Paddle – player-controlled (or AI) paddle in sea combat.
## Shape is determined by ship tier and faction (multi-segment pattern).
extends Node2D

const SPEED := 280.0
const PADDLE_HEIGHT := 12.0
const SEGMENT_UNIT := 15.0   # pixels per underscore unit
const SEGMENT_GAP  := 8.0    # gap between segments

## Tier segment patterns per faction (tiers 1–9).
## Each entry is an Array of unit-counts per segment (1 unit = SEGMENT_UNIT px).
## Settlers patterns match the spec: e.g. T1 "___" = one segment of 3 units.
const TIER_PATTERNS: Dictionary = {
	"Settlers": [
		[3],              # T1: ___
		[2, 2],           # T2: __ __
		[3, 3],           # T3: ___ ___
		[2, 3, 2],        # T4: __ ___ __
		[3, 2, 3],        # T5: ___ __ ___
		[4, 2, 2, 4],     # T6: ____ __ __ ____
		[3, 4, 4, 3],     # T7: ___ ____ ____ ___
		[2, 3, 4, 3, 2],  # T8: __ ___ ____ ___ __
		[3, 3, 4, 3, 3],  # T9: ___ ___ ____ ___ ___
	],
	"Conquerors": [
		[4],                  # T1
		[3, 3],               # T2
		[4, 4],               # T3
		[3, 4, 3],            # T4
		[4, 3, 4],            # T5
		[4, 4, 4, 4],         # T6
		[3, 4, 4, 4, 3],      # T7
		[4, 3, 4, 3, 4],      # T8
		[4, 4, 4, 4, 4],      # T9
	],
	"Pirates": [
		[2],                  # T1
		[2, 3],               # T2
		[3, 2, 3],            # T3
		[2, 3, 2, 2],         # T4
		[3, 2, 3, 2],         # T5
		[2, 3, 2, 3, 2],      # T6
		[3, 2, 4, 2, 3],      # T7
		[2, 3, 4, 3, 2],      # T8
		[3, 2, 4, 2, 3, 2],   # T9
	],
	"Ferals": [
		[1],                        # T1
		[1, 2],                     # T2
		[2, 1, 2],                  # T3
		[1, 2, 1, 2],               # T4
		[2, 1, 3, 1, 2],            # T5
		[1, 2, 3, 2, 1],            # T6
		[2, 1, 3, 1, 3, 1, 2],     # T7
		[1, 2, 3, 4, 3, 2, 1],     # T8
		[2, 1, 3, 1, 4, 1, 3, 1, 2], # T9
	],
}

var is_player: bool = true
var ship_tier: int = 1
var faction: String = "Settlers"

## Ability instances (set by SeaCombat).
var attack_ability: CombatAbility = null
var wall_ability: CombatAbility = null
var attack_secondary: CombatAbility = null
var wall_secondary: CombatAbility = null

func _process(delta: float) -> void:
	if is_player:
		_handle_input(delta)
	_tick_abilities(delta)
	queue_redraw()

func _handle_input(delta: float) -> void:
	if Input.is_action_pressed("move_left"):
		position.x -= SPEED * delta
	if Input.is_action_pressed("move_right"):
		position.x += SPEED * delta
	var hw := _get_half_width()
	position.x = clamp(position.x, hw + 4, 1280.0 - hw - 4)

func _tick_abilities(delta: float) -> void:
	if attack_ability != null:
		attack_ability.tick(delta)
	if wall_ability != null:
		wall_ability.tick(delta)
	if attack_secondary != null:
		attack_secondary.tick(delta)
	if wall_secondary != null:
		wall_secondary.tick(delta)

## Returns an Array of world-space Rect2 for each paddle segment.
func get_segment_rects() -> Array:
	var pattern := _get_tier_pattern()
	var widths: Array = []
	var total_width := 0.0
	for units in pattern:
		var w: float = units * SEGMENT_UNIT
		widths.append(w)
		total_width += w
	total_width += max(0, widths.size() - 1) * SEGMENT_GAP
	var rects: Array = []
	var cur_x := position.x - total_width / 2.0
	for w in widths:
		rects.append(Rect2(cur_x, position.y - PADDLE_HEIGHT / 2.0, w, PADDLE_HEIGHT))
		cur_x += w + SEGMENT_GAP
	return rects

## Returns the bounding Rect2 (backward-compatible single-rect accessor).
func get_rect() -> Rect2:
	var rects := get_segment_rects()
	if rects.is_empty():
		return Rect2(position.x - 40, position.y - PADDLE_HEIGHT / 2.0, 80, PADDLE_HEIGHT)
	var left: float = rects[0].position.x
	var right: float = rects[-1].end.x
	return Rect2(left, position.y - PADDLE_HEIGHT / 2.0, right - left, PADDLE_HEIGHT)

func _get_tier_pattern() -> Array:
	var tier_idx := clampi(ship_tier - 1, 0, 8)
	if TIER_PATTERNS.has(faction):
		return TIER_PATTERNS[faction][tier_idx]
	return TIER_PATTERNS["Settlers"][tier_idx]

func _get_half_width() -> float:
	var pattern := _get_tier_pattern()
	var total := 0.0
	for units in pattern:
		total += units * SEGMENT_UNIT
	total += max(0, pattern.size() - 1) * SEGMENT_GAP
	return total / 2.0

func _draw() -> void:
	var col := Color.CYAN if is_player else Color.ORANGE_RED
	for rect in get_segment_rects():
		var local_x: float = rect.position.x - position.x
		draw_rect(Rect2(local_x, -PADDLE_HEIGHT / 2.0, rect.size.x, PADDLE_HEIGHT), col)
