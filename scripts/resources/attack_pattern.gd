## AttackPattern – defines how many balls are fired and their pearl value.
class_name AttackPattern
extends Resource

@export var pattern_name: String = ""
@export var ball_count: int = 1
## Pearl value each ball carries (affects SP damage on hit).
@export var ball_pearl_value: int = 1
## MP cost to fire this pattern.
@export var mp_cost: int = 1
## Cooldown in seconds.
@export var cooldown: float = 5.0
## Spread angle in degrees for multi-ball patterns.
@export var spread_degrees: float = 0.0
