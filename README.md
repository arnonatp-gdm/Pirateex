# Pirateex

A sea-exploration pirate game set in **Terrentia** — a world of 13 contested islands.

## Game Overview

Pirateex is built in **Godot 4.6** using GDScript.

### The World

| Faction | Tech/Magic | Cultural/Chaos |
|---------|-----------|----------------|
| **Settlers** | Tech | Cultural |
| **Conquerors** | Magic | Cultural |
| **Pirates** | Tech | Chaos |
| **Ferals** | Magic | Chaos |

13 islands form the contested sea map. The player sails between them, trading or fighting
factions. Collecting enough resources allows taking over islands — at which point all
factions turn hostile and a race-to-conquest begins.

### Core Loop

1. Sail the map → interact with NPC ships or islands
2. Choose **Attack** or **Trade** at each encounter
3. Earn/spend **Star Pearls (SP)** (tech) and **Moon Pearls (MP)** (magic)
4. Upgrade your ship and player stats at town shops/pubs
5. Eventually capture all 13 islands before your ship is destroyed

---

## Phases

### 1 · Sea Exploration
- Static map with 13 islands rendered as coloured circles
- NPC ships of all 4 factions sail between islands automatically
- Player moves left/right with **A/D**
- **E** — interact with a nearby island (enter town)
- **Q** — attack a nearby NPC ship (enter sea combat)
- **W** — attempt to trade with a nearby NPC (stub, recorded as interaction)

### 2 · Sea Combat (Pong-like)

A vertical pong arena. Player paddle at the bottom, enemy at the top.

#### Controls
| Key | Action |
|-----|--------|
| **A / ←** | Move paddle left |
| **D / →** | Move paddle right |
| **R** | Fire attack pattern (costs MP) |
| **Y** | Deploy wall (costs SP) |
| **Double-click** | Toggle primary ↔ secondary pattern |
| **F** | Flee (available when SP or MP ≤ 50 % of starting value) |

#### Pearl Economy
- **MP** is spent every time you fire.
- **SP** is lost when an enemy ball reaches your side (by the ball's pearl value).
- When either SP or MP drops to **50 %** of your starting value, a flee prompt appears.
- Reaching **0** in either pearl type means **ship lost** → respawn at port.

#### Balls & Walls
- Each ball carries a pearl value. When it hits a wall, both lose value; at 0, the ball vanishes.
- Two balls from opposing sides colliding each lose 1 pearl value.
- Walls are temporary and cost SP to deploy.

#### Cooldown / Reset
- Each ability has a **5 s** cooldown by default.
- When on cooldown you can **reset early** for double the base cost (multiplier doubles per consecutive reset, resets to ×1 on natural completion).

#### AI
- Enemy AI surrenders when its SP or MP falls to **75 %** of starting values.
- Winning yields **half of the enemy's starting pearls** + their bounty.

### 3 · Town Exploration

Press these keys inside a town:

| Key | Action |
|-----|--------|
| **1** | Pub — hire crew (costs 15 MP) |
| **2** | Shop — buy first available SP upgrade |
| **3** | Enter town combat (stub) |
| **Esc** | Return to sea |

### 4 · Town Combat
Placeholder. Press **Esc** to return to town.

---

## Currencies

| Pearl | Used for | Lost when |
|-------|----------|-----------|
| **SP (Star Pearls)** | Tech upgrades, deploying walls | Ship is hit by a ball |
| **MP (Moon Pearls)** | Magic upgrades, firing attacks | Shooting in combat |

---

## Project Structure

```
Pirateex/
├── project.godot
├── autoload/
│   ├── game_state.gd        # Phase switching singleton
│   ├── player_state.gd      # SP/MP, upgrades, interaction history
│   └── world_state.gd       # Islands, factions, NPC ships
├── scripts/
│   ├── state_machine.gd
│   └── resources/
│       ├── faction_data.gd
│       ├── island_data.gd
│       ├── ship_data.gd
│       ├── upgrade_data.gd
│       ├── attack_pattern.gd
│       └── wall_pattern.gd
├── data/
│   ├── factions/            # 4 .tres faction resources
│   ├── islands/             # 13 .tres island resources
│   ├── ships/               # corvette.tres
│   ├── upgrades/            # 4 starter upgrade .tres files
│   └── patterns/            # attack & wall pattern .tres files
└── scenes/
    ├── main.tscn / main.gd
    ├── sea_exploration/
    │   ├── sea_map.tscn / sea_map.gd
    │   └── npc_ship.tscn / npc_ship.gd
    ├── sea_combat/
    │   ├── sea_combat.tscn / sea_combat.gd
    │   ├── paddle.tscn / paddle.gd
    │   ├── ball.tscn / ball.gd
    │   ├── wall_segment.tscn / wall_segment.gd
    │   ├── combat_ability.gd
    │   └── ai_opponent.gd
    ├── town_exploration/
    │   └── town.tscn / town.gd
    └── town_combat/
        └── town_combat.tscn / town_combat.gd
```

---

## How to Run

1. Download and install **[Godot 4.6](https://godotengine.org/download/)**.
2. Open Godot → **Import** → select the `project.godot` file in this repository.
3. Click **Play** (F5) or **Run current scene** (F6 on `scenes/main.tscn`).

No additional dependencies required. All content is data-driven via `.tres` resource files.

---

## Reputation / Evaluation System

Every player interaction (attack or trade) is recorded in `PlayerState`:
- Last **5 interactions** are stored (older entries are dropped).
- **tech_score** — incremented by tech upgrades; axis for Settlers/Pirates alignment.
- **cultural_score** — incremented by trades, decremented by attacks.
- After **3 consecutive successes** the player becomes a *Famous Captain* with a bounty.
- NPC ships follow the same consecutive-success tracking for their own fame status.

---

## Starter Ship

The player always starts with a **Corvette** (100 SP, 100 MP, 3 upgrade slots)
and one pre-selected upgrade (Navigator's Compass from Settlers by default —
full upgrade selection UI is out of scope for this scaffold).

If the ship is lost, pressing through the "ship lost" flow respawns the player
with a fresh Corvette at the nearest port (naming is stubbed to "The Wanderer II").
