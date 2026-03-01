## WallPattern – defines a wall deployment configuration.
class_name WallPattern
extends Resource

@export var pattern_name: String = ""
## SP cost to deploy.
@export var sp_cost: int = 5
## Pearl value each wall segment carries (bouncing reduces ball pearl value).
@export var wall_pearl_value: int = 1
## Number of wall segments placed.
@export var segment_count: int = 1
## Segment length in pixels.
@export var segment_length: float = 80.0
## Cooldown in seconds.
@export var cooldown: float = 5.0
