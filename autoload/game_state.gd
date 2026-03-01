## GameState – autoload singleton that manages the active game phase.
## Phases: sea_exploration, sea_combat, town_exploration, town_combat
extends Node

enum Phase {
	SEA_EXPLORATION,
	SEA_COMBAT,
	TOWN_EXPLORATION,
	TOWN_COMBAT,
}

var current_phase: Phase = Phase.SEA_EXPLORATION

## Context passed when switching into a phase (e.g. target ship for combat).
var phase_context: Dictionary = {}

signal phase_changed(new_phase: Phase, context: Dictionary)

func switch_phase(new_phase: Phase, context: Dictionary = {}) -> void:
	current_phase = new_phase
	phase_context = context
	print("[GameState] Switching to phase: ", Phase.keys()[new_phase], " context=", context)
	phase_changed.emit(new_phase, context)

func phase_name() -> String:
	return Phase.keys()[current_phase]
