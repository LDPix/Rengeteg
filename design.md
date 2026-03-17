# 🌿 Rengeteg – Design Document

## Team

Fadeev Nikita - everything

## 🎮 Game Idea

**Rengeteg** is a 2D creature-collection exploration RPG built in **Godot 4.6**.

The game focuses on **map-based expeditions** where players:
- explore handcrafted maps
- capture creatures
- gather materials
- craft items
- prepare for increasingly challenging runs

The design emphasizes:
- **risk vs reward exploration**
- **item-driven progression**
- **replayable, decision-based gameplay**

---

## 🔁 Core Gameplay Loop

### Action → Reward → Expansion

**Action**
- Explore maps
- Battle and capture creatures
- Gather resources (with possible encounter risk)
- Choose when to push forward or retreat
- Face the map boss

**Reward**
- Materials
- Captured creatures
- EXP
- Crafted items
- Boss rewards

**Expansion**
- Stronger team (new creatures, leveling)
- Build customization via held items
- Better preparation for future expeditions


---

## 📈 Difficulty Curve

### 🌱 Early Game
- Guided objectives (gather, craft, capture)
- Low-risk environments
- Focus on learning core systems

### 🌿 Mid Game
- More encounters and map structure
- Resource gathering introduces risk
- Items and abilities become important
- Player decisions matter more

### 🔥 Late Game
- Harder maps and stronger bosses
- Greater reliance on builds and strategy
- Efficient resource and team management required

---

## 🧬 Progression

Progression is layered and avoids simple stat grinding:

- **Creatures** → level up and improve stats  
- **Items (core system)** → held items define builds and strategy  
- **Crafting** → materials → items → stronger runs  
- **Maps (planned)** → boss completion unlocks new challenges  
- **Player skill** → better decisions and resource management  

---

## ⚙️ Technical Overview

### Engine
- Godot 4.6
- GDScript

### Core Systems
- Overworld exploration (TileMap-based)
- Turn-based battle system
- Creature system (stats, abilities, passives)
- Item & crafting system (data-driven)
- Resource gathering system
- Objective system (in progress)
- Encounter system (zone-based + node-based planned)
