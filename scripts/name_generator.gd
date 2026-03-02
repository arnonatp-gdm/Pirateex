# GDScript implementation

# Function to generate a captain's name based on faction data
func generate_captain_name(faction: FactionData, rng: RandomNumberGenerator = null) -> String:
    var first_name = _pick(faction.first_name_list, rng)
    var last_name = _pick(faction.last_name_list, rng)
    return first_name + " " + last_name

# Function to generate a ship's name based on faction data and ship class
func generate_ship_name(faction: FactionData, ship_class: String = "Corvette", rng: RandomNumberGenerator = null) -> String:
    var class_name = ship_class
    var last_name = _pick(faction.last_name_list, rng)
    var first_name = _pick(faction.first_name_list, rng)
    return class_name + " " + last_name + " " + first_name

# Helper function to pick a random item from a list
func _pick(array: Array, rng: RandomNumberGenerator = null) -> Variant:
    if rng == null:
        return array[randi() % array.size()]
    return array[rng.rand_range(0, array.size() - 1)]