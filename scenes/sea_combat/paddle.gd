## Paddle – player-controlled (or AI) paddle in sea combat.
## Left/Right input moves the paddle horizontally.
extends Node2D

const SPEED := 280.0

var paddle_width: float = 80.0
var paddle_height: float = 12.0
var is_player: bool = true

## Ability instances (set by SeaCombat).
var attack_ability: CombatAbility = null   # primary attack
var wall_ability: CombatAbility = null     # primary wall
var attack_secondary: CombatAbility = null
var wall_secondary: CombatAbility = null

## Which abilities are currently "secondary" (double-click to use).
var _use_secondary: bool = false

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
	position.x = clamp(position.x, paddle_width / 2, 1280 - paddle_width / 2)

func _tick_abilities(delta: float) -> void:
	if attack_ability != null:
		attack_ability.tick(delta)
	if wall_ability != null:
		wall_ability.tick(delta)
	if attack_secondary != null:
		attack_secondary.tick(delta)
	if wall_secondary != null:
		wall_secondary.tick(delta)

## Returns the Rect2 for the paddle.
func get_rect() -> Rect2:
	return Rect2(
		position.x - paddle_width / 2,
		position.y - paddle_height / 2,
		paddle_width,
		paddle_height
	)

func _draw() -> void:
	var col := Color.CYAN if is_player else Color.ORANGE_RED
	draw_rect(Rect2(-paddle_width / 2, -paddle_height / 2, paddle_width, paddle_height), col)
