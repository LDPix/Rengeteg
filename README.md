# Rengeteg

A **monster-collection exploration RPG** built with **Godot 4.6**.

Players explore different maps, encounter wild creatures, gather resources, and upgrade their team between expeditions.

---

# Team

Fadeev Nikita (everything)

---

# Overview

Creature Expedition is a **roguelite-style creature battler** where each run begins from a camp. From camp you choose a map, venture out to explore it, and return with captured creatures and materials.

The game focuses on:

* exploration
* creature battles
* team management
* crafting items
* map-based progression

---

# Core Gameplay Loop

1. Start at **Camp**
2. Choose a **map**
3. **Explore the map**
4. Encounter **wild creatures**
5. **Battle or capture** them
6. Gather **resources**
7. Exit the map
8. Return to **Camp** to heal and upgrade
9. Venture out again

---

# Current Features

## Maps

Two playable maps:

### Verdant Wilds

A forest environment with grassy encounter zones.

Creatures:

* Mossling
* Shellhorn
* Cinder Pup

Resources:

* trees
* herbs

### Ember Caves

A volcanic cave environment with lava hazards.

Creatures:

* Cinder Pup
* Shellhorn

Resources:

* stone
* crystals

---

## Battle System

Turn-based creature battles with the following actions:

* Attack
* Switch
* Capture
* Run

Features:

* automatic switching when a creature faints
* capture mechanics
* enemy counterattacks

---

## Creature System

Creatures have:

* HP
* Attack
* Defense

Captured creatures are added to the player's team.

If the team is full, creatures are sent to storage.

---

## Camp

Camp acts as the **hub between expeditions**.

At camp players can:

* heal their team
* upgrade creature stats
* choose a map
* start a new expedition

---

# Controls

| Action         | Key               |
| -------------- | ----------------- |
| Move           | WASD              |
| Interact       | E                 |
| Open Camp      | C                 |
| Battle actions | Mouse             |

---

# Project Structure

```text
scenes/
  battle/
  overworld/
  ui/

scripts/
  battle.gd
  overworld.gd
  camp.gd
  game_state.gd
  game_data.gd
```

Key systems:

* **GameState** – persistent player data
* **GameData** – creature and map definitions
* **Battle system** – turn-based combat logic
* **Overworld** – map exploration and encounters

---

# Tech Stack

Engine:

* **Godot 4.6**

Language:

* **GDScript**

Design tools:

* Paper Design (UI prototyping)

---

# Running the Game

Open the project in **Godot 4.6** and run the main scene.

```bash
godot
```

Or export using:

```
Project → Export
```

Supported platforms:

* Windows
* macOS
* Linux
* Web (planned)

---

# Development Status

Current stage:

**Prototype / Early development**

Working systems:

* map exploration
* battle system
* creature capture
* camp hub
* two maps

Planned features:

* more creatures
* procedural maps
* better combat UI
* animations
* creature abilities
* map progression

---

# Roadmap

Planned improvements:

* new regions
* boss encounters
* creature evolution
* rare spawns
* improved UI
* save system
* audio and visual polish
