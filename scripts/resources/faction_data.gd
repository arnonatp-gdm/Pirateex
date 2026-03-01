## FactionData – data-driven resource describing a faction.
## Branding axes: tech_affinity (vs magic), cultural (vs chaos).
class_name FactionData
extends Resource

@export var faction_name: String = ""
@export var tech_affinity: bool = false   # true = tech, false = magic
@export var cultural: bool = false         # true = cultural/trader, false = chaos/fighter
@export var color: Color = Color.WHITE
@export var description: String = ""
