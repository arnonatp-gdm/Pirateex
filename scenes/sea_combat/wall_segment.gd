## WallSegment – a defensive wall piece placed by player/enemy.
## Has a pearl value; reduces ball pearl value when bouncing.
extends Node2D

var pearl_value: int = 1
var length: float = 80.0
var owner_id: String = "player"

## Time-to-live in seconds (walls are temporary).
var ttl: float = 8.0

func setup(pv: int, seg_length: float, owner: String) -> void:
	pearl_value = pv
	length = seg_length
	owner_id = owner

func _process(delta: float) -> void:
	ttl -= delta
	if ttl <= 0:
		queue_free()
	queue_redraw()

## Returns the Rect2 of this wall for overlap checks.
func get_rect() -> Rect2:
	return Rect2(position.x - length / 2, position.y - 5, length, 10)

func _draw() -> void:
	var col := Color.BLUE if owner_id == "player" else Color.RED
	draw_rect(Rect2(-length / 2, -5, length, 10), col)
	draw_string(ThemeDB.fallback_font, Vector2(-6, -8),
		"W:" + str(pearl_value), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
