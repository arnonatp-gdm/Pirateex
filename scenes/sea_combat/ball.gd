## Ball – a projectile in sea combat with a pearl value.
## When pearl_value hits 0 the ball vanishes.
## Bouncing off a wall reduces the ball's pearl value by the wall's value.
## Two balls colliding each lose a configurable amount.
extends Node2D

const BALL_BALL_DAMAGE := 1  # pearl value lost when two balls collide

var pearl_value: int = 1
var velocity: Vector2 = Vector2.ZERO
var radius: float = 8.0

## Who owns this ball: "player" or "enemy"
var owner_id: String = "player"

func setup(pv: int, vel: Vector2, owner: String) -> void:
	pearl_value = pv
	velocity = vel
	owner_id = owner

func _process(delta: float) -> void:
	position += velocity * delta
	# Bounce off left/right walls of viewport.
	if position.x < radius:
		position.x = radius
		velocity.x = abs(velocity.x)
	if position.x > 1280 - radius:
		position.x = 1280 - radius
		velocity.x = -abs(velocity.x)
	queue_redraw()

## Called when this ball bounces off a wall segment.
func bounce_off_wall(wall_pv: int) -> void:
	velocity.y = -velocity.y
	pearl_value -= wall_pv
	_check_vanish()

## Called when this ball collides with another ball.
func collide_with_ball(other: Node2D) -> void:
	pearl_value -= BALL_BALL_DAMAGE
	if other.has_method("on_ball_hit"):
		other.on_ball_hit(BALL_BALL_DAMAGE)
	velocity = -velocity
	_check_vanish()

func on_ball_hit(damage: int) -> void:
	pearl_value -= damage
	_check_vanish()

func _check_vanish() -> void:
	if pearl_value <= 0:
		queue_free()

func _draw() -> void:
	var col := Color.YELLOW if owner_id == "player" else Color.RED
	draw_circle(Vector2.ZERO, radius, col)
	draw_string(ThemeDB.fallback_font, Vector2(-6, 4),
		str(pearl_value), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.BLACK)
