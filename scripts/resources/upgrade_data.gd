## UpgradeData – data-driven resource for a ship or player upgrade.
class_name UpgradeData
extends Resource

@export var upgrade_name: String = ""
@export var description: String = ""
## Which faction grants this upgrade.
@export var faction: FactionData = null
## Stat boosts.
@export var sp_bonus: int = 0
@export var mp_bonus: int = 0
@export var attack_bonus: float = 0.0
@export var defense_bonus: float = 0.0
## Cost in SP (tech upgrades) or MP (magic upgrades).
@export var sp_cost: int = 0
@export var mp_cost: int = 0
