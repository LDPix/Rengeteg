# AGENT GUIDELINES

## IMPORTANT

All changes must follow this document.

If a request conflicts with these guidelines, follow the guidelines.

---

# 🎯 Project Overview

This is a 2D creature-collection exploration RPG built in Godot 4.6 using GDScript.

The game is inspired by Pokémon but focuses on expedition-based gameplay instead of linear progression.

Core loop:
Camp → Choose Map → Explore → Battle/Capture → Gather → Exit → Craft/Prepare → Repeat

Primary goal:
Make each expedition a meaningful sequence of decisions driven by risk vs reward.

---

# 🧠 Design Philosophy

- Decisions > raw stat progression
- Exploration is driven by risk vs reward
- The player chooses when to push deeper or retreat
- Runs should be repeatable but slightly different each time
- Systems should be simple, modular, and extensible

Content is secondary to structure.

Always prioritize improving the core gameplay loop over adding more content.

---

# 🎮 Core Gameplay Rules

- The game is run-based (expeditions), not linear progression
- Player progression is driven primarily by items and decisions
- Creatures are part of strategy, not the sole progression system
- Gathering, combat, and exploration are interconnected

The player must always face tradeoffs.

Avoid adding systems that:
- remove decision-making
- trivialize risk
- create dominant strategies

---

# 🧱 System Design Guidelines

When adding or modifying systems:

- Prefer extending existing systems over creating new ones
- Keep systems data-driven where possible (e.g. game_data.gd)
- Avoid hardcoding logic when it can be defined in data
- Ensure new features integrate with:
  - encounters
  - objectives
  - items
  - exploration loop

All systems must support the expedition loop.

---

# 🌍 World Lore

The world was once home to an advanced civilization — now dead.

Its remnants appear across maps as ruins, artifacts, and fragments of ancient magic and technology. The player uncovers this history through exploration, not exposition.

Two categories of POI exist based on this lore:

1. **Ancient / Arcane POIs** — ruins, altars, sealed vaults, arcane constructs. Tied to the lost civilization. May yield recipes, ancient items, or lore fragments.
2. **Environmental POIs** — biome-specific. Predator nests, resource groves, hidden caches, natural shrines. Vary by map.

Both categories must create decisions. Neither is purely decorative.

---

# 🗺️ Map & POI Design Rules

Maps must not feel like empty space.

Each map should include:
- a safe entrance area
- mid-zone decision points
- deeper high-risk/high-reward areas
- a boss or final objective zone

## POIs (Points of Interest)

POIs are core to map design. Each POI must create a meaningful decision.

### Risk/Reward Structure

All POIs use an explicit **choice-based risk/reward model** (not spatial placement logic):

When the player activates a POI, they are shown a choice panel:
- **Safe option** — small guaranteed reward, no combat
- **Risky option** — triggers an encounter; better reward if won
- **Cancel** — leave without committing

This is defined per-POI via a `risk_choice` dictionary in `game_data.gd`:
```
risk_choice: {
  safe: { prompt, result_text, rewards },
  risky: { prompt, encounter: { encounter_tag, message, ui_variant, level_bonus, stat_multiplier, exp_multiplier, reward_bundle } }
}
```

POIs without `risk_choice` use simple `immediate_rewards` (no player choice).

### Ancient POI Rewards

Ancient/arcane POIs are the primary source of **crafting recipes**.

- Basic items (tutorial-level) are always craftable
- Advanced held items and utility items require a discovered recipe
- Recipes drop from ancient POIs or boss battles
- A recipe-locked item does not appear in the crafting menu until found

### Environmental POI Examples
- resource grove (high yield, combat risk)
- predator nest (combat-focused, creature drops)
- natural shrine (temporary buff)
- hidden cache (loot, possibly guarded)

### Ancient POI Examples
- ruined vault / entry cache (artifact loot, recipe chance)
- arcane altar (ritual encounter, stat reward)
- sealed construct (boss-like, unique reward)
- lore fragment site (recipe + world-building text)

Avoid:
- decorative POIs with no gameplay impact
- uniform map layouts
- evenly distributed rewards
- spatial "value inside danger zone" logic — use explicit choice panels instead

---

# ⚔️ Combat & Creature Design

- Combat is turn-based and resource-driven (HP, MP, etc.)
- Encounters must support exploration decisions
- Creature abilities should reinforce playstyles

Avoid:
- unnecessary stat inflation
- overly complex mechanics that slow gameplay

---

# 🎒 Item System Rules

- Items are the primary form of build customization
- Held items define playstyle and strategy
- Items must create tradeoffs, not just bonuses

Good item design:
- changes player behavior during runs
- interacts with multiple systems

Avoid:
- flat stat boosts without gameplay impact

---

# 🎨 Asset Creation Guidelines (Paper MCP)

---

# 🖥️ UI Text Guidelines

- All title text in the game must be uppercase.
- When adding or updating UI, treat headings, panel titles, section titles, battle titles, popup titles, and other title-role text as all-caps by default.
- New UI layout work should preserve readability first: clear hierarchy, clean spacing, and minimal unnecessary framing.

This project uses Paper MCP for generating visual assets.

When new assets are required, the agent should:

- Prefer generating assets via Paper MCP instead of placeholders
- Ensure assets match the game style (2D, top-down, readable)
- Keep visuals simple and functional

## Use Paper MCP for:
- POIs (shrines, nests, caches, groves)
- resource nodes
- creatures (for prototyping)
- UI icons (items, materials, abilities)
- environment props

## Generation defaults:
- Generate **one variant** per asset unless explicitly told otherwise
- Do not generate multi-frame review packs or bulk variants without being asked

## Asset quality guidelines:
- clear silhouette at small sizes
- consistent scale relative to player
- minimal visual noise
- biome-consistent colors:

If style is unclear:
- generate simple, readable assets
- prioritize clarity over detail

Avoid:
- mixing inconsistent art styles
- using random external assets
- leaving missing visuals when assets can be generated

---

# 🧩 Asset Usage Rules

When implementing new features:

- Every new gameplay entity must have a visual representation
- If no asset exists, generate one using Paper MCP
- Prefer reusing existing assets when appropriate

Do not delay implementation waiting for perfect visuals.

---

# 🏷️ Asset Naming Conventions

Use consistent naming:

- poi_<type>.png
  (e.g. poi_shrine.png, poi_nest.png)

- node_<type>.png
  (e.g. node_wood.png)

- item_<name>.png

- creature_<name>.png

Use lowercase and underscores.

---

# ⚙️ Code Guidelines

- Follow existing project structure
- Do not introduce new architecture unless necessary
- Keep scripts modular and focused
- Prefer readability over clever abstractions

Use:
- game_data.gd → static definitions
- game_state.gd → runtime state

Avoid:
- large monolithic scripts
- duplicated logic
- tightly coupled systems

---

# 🧪 Implementation Rules (For Agents)

When making changes:

1. Understand the existing system before modifying it
2. Prefer modifying existing systems over adding new ones
3. Keep changes minimal and targeted
4. Do not break existing functionality

When adding features:
- briefly explain your plan
- implement changes
- provide a concise changelog
- list assumptions or TODOs

---

# 🖼️ UI: Stat Display Rules

When displaying creature stats (HP, MP, ATK, DEF, SPD, etc.) in any UI panel:

- Always use a stat icon + value pair, never text abbreviations like "HP 50" or "ATK 30"
- Stat icons are located at `res://assets/ui/stats/*_icon.svg`
- Available icons: `hp_icon.svg`, `mp_icon.svg`, `atk_icon.svg`, `def_icon.svg`, `spd_icon.svg`, `acc_icon.svg`, `eva_icon.svg`, `crit_icon.svg`, `exp_icon.svg`
- Each stat chip: HBoxContainer > TextureRect (icon, 18×18, TEXTURE_FILTER_NEAREST) + Label (value)

---

# ⚠️ GDScript Typing Rules

Do not rely on type inference when the value may be a Variant.

Always explicitly declare variable types when:
- the value comes from dictionaries (e.g. game_data.gd)
- the value may be null or dynamic
- the type is not guaranteed at compile time

Example (avoid):
var value = some_dict[key]

Correct:
var value: int = some_dict[key]

---

# 🚫 Anti-Patterns (Do Not Do)

- Do not overengineer systems
- Do not introduce complex frameworks
- Do not add features without gameplay purpose
- Do not remove player decision-making
- Do not redesign large systems unless explicitly asked

If a feature does not improve the core loop, do not add it.

---

# 🧭 Current Focus

- Improve expedition structure and map design
- Add meaningful POIs
- Increase decision-making during runs
- Improve encounter variety
- Make maps feel structured and intentional

Do not prioritize adding new creatures or content over improving the core loop.

---

# 🟢 Success Criteria

A change is successful if:

- It increases meaningful decisions during a run
- It improves risk vs reward dynamics
- It enhances map structure and readability
- It integrates cleanly with existing systems
- It keeps the game simple and extensible
