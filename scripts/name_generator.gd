extends Node

# Word lists for Ship and Captain Name Generation
var tools = ["Hammer", "Saw", "Chisel", "Axe"]
var jobs = ["Blacksmith", "Carpenter", "Mage", "Scout"]
var spells = ["Fireball", "Heal", "Invisibility"]
var actioners = ["Dashes", "Stabs", "Casts", "Sprints"]
var temperaments = ["Brave", "Cunning", "Honorable"]
var materials = ["Wood", "Steel", "Magical Essence"]
var results = ["Victory", "Defeat", "Draw"]
var states_of_matter = ["Solid", "Liquid", "Gas"]
var body_parts = ["Arm", "Leg", "Head"]

# Function to generate captain names
func generate_captain_name(cultural):
    var last_name = get_random_last_name()
    var first_name = get_random_first_name(cultural)
    return first_name + " " + last_name

# Function to generate ship names
func generate_ship_name(faction_data):
    var class_name = "corvette"  # Default class
    var last_name = get_random_last_name()
    var first_name = get_random_first_name(faction_data.cultural)
    return class_name + " " + last_name + " " + first_name

# Helper functions to get random names from lists
func get_random_last_name():
    return tools[randi() % tools.size()]

func get_random_first_name(cultural):
    return jobs[randi() % jobs.size()]  # This can be extended for cultural
