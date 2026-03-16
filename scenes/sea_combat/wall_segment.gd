## WallSegment – a defensive wall piece placed by player/enemy.
## Uses pearl_value as wall SP. Vanishes when pearl_value reaches 0 (SP-based, not TTL).
extends Node2D

var pearl_value: int = 1
var length: float = 80.0
var owner_id: String = "player"
## Wall type: "standard" | "bouncing" | "ball_shooting" | "timer_mod"
var wall_type: String = "standard"
## For timer_mod walls: positive slows player attack; negative speeds up AI attack.
var timer_effect: float = 0.0

func setup(pv: int, seg_length: float, owner: String,
		wtype: String = "standard", te: float = 0.0) -> void:
	pearl_value = pv
	length = seg_length
	owner_id = owner
	wall_type = wtype
	timer_effect = te

func _process(_delta: float) -> void:
	queue_redraw()

## Called when a ball hits this wall.
## Bouncing walls are immune to SP loss. Others lose 1 SP per hit.
func take_hit() -> void:
	if wall_type == "bouncing":
		return  # immune – never loses SP
	pearl_value -= 1
	if pearl_value <= 0:
		queue_free()

## Returns the Rect2 of this wall for overlap checks.
func get_rect() -> Rect2:
	return Rect2(position.x - length / 2, position.y - 5, length, 10)

func _draw() -> void:
	var col: Color
	match wall_type:
		"bouncing":
			col = Color.CYAN if owner_id == "player" else Color.ORANGE
		"ball_shooting":
			col = Color.MAGENTA if owner_id == "player" else Color.HOT_PINK
		"timer_mod":
			col = Color.GREEN if owner_id == "player" else Color.YELLOW_GREEN
		_:
			col = Color.BLUE if owner_id == "player" else Color.RED
	draw_rect(Rect2(-length / 2, -5, length, 10), col)
	draw_string(ThemeDB.fallback_font, Vector2(-6, -8),
		"W:" + str(pearl_value), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
