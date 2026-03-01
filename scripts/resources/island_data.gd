## IslandData – data-driven resource for one of the 13 islands.
class_name IslandData
extends Resource

@export var island_name: String = ""
@export var island_id: int = 0
@export var position: Vector2 = Vector2.ZERO
@export var controlling_faction: FactionData = null
@export var has_town: bool = true
@export var description: String = ""
