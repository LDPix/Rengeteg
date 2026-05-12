# Rengeteg — Game State Reference
*For LLM context. Engine: Godot 4.6, GDScript with explicit typing.*

---

## Game design overview

### Concept

Rengeteg is a 2D creature-collection RPG structured around **repeatable expeditions** rather than linear world progression. The closest reference is Pokémon, but the pacing and decision model are closer to a light roguelite: each run into a map is a contained session with its own stakes, and permanent progression comes from what you bring back.

The name means "forest" or "wilderness" in Hungarian.

### Core tension

The player always faces a push-your-luck decision: **go deeper for better rewards or retreat with what you have.** Resources, encounter risk, and party health all degrade as you push further. The exit is always available. Leaving early is a valid strategy.

Every system is designed to make this tension real — not decorative.

### Core loop

**Camp → Select Map → Explore → Battle / Gather / Interact with POIs → Exit → Return to Camp → Craft / Prepare → Repeat**

Each phase feeds into the next:
- Exploration yields materials and captured creatures
- Materials fund crafting at camp
- Crafted items and creatures strengthen the party for the next run
- Stronger parties can push deeper, reach boss zones, unlock new maps

### What drives progression

**Items are the primary axis of build customization.** Held items (one per creature) define playstyle — aggressive (sharp_fang, ember_idol), defensive (moss_charm, stone_ring), utility (fleet_feather, hunter_lens, mist_cloak). Creatures carry the build; leveling is secondary.

**Crafting gates content.** You cannot craft most items without materials gathered on runs. Advanced recipes must be discovered at ancient POIs before they appear in the crafting menu — so exploration is the unlock mechanism, not time or level.

**Maps unlock via boss defeat.** Completing the Verdant Wilds boss opens Ember Caves. Each map has its own creature pool, biome, and resource types.

### Design priorities

1. **Decisions over stat progression.** Every encounter, POI, and route choice should create a real tradeoff — not a math problem with an obvious answer.
2. **Risk vs. reward is explicit, not spatial.** POIs present choice panels (safe option / risky option / cancel) rather than relying on "dangerous area = good loot" map design.
3. **Runs are repeatable but vary.** Resource nodes, POIs, and encounter zone activation are randomized per run. No two expeditions are identical, but the map layout is fixed.
4. **Simple systems, deep interaction.** Each system (combat, crafting, items, gathering) is kept lean. Depth comes from their intersection, not from complexity within any one system.
5. **Content is secondary to structure.** Two maps and four creatures with a working loop beats ten maps with shallow mechanics.

### World lore

The world was once home to an advanced civilization — now dead. Its remnants appear across maps as ruins, artifacts, and fragments of ancient magic and technology. The player uncovers this history through exploration, not exposition.

Two POI categories emerge from this:
- **Ancient / Arcane POIs** — ruins, altars, sealed vaults, arcane constructs. Tied to the lost civilization. Primary source of recipe discoveries and lore.
- **Environmental POIs** — biome-specific. Predator nests, resource groves, natural shrines, hidden caches. Vary by map.

Both categories create decisions. Neither is decorative.

### Success criteria for any change

A feature or change is successful if it:
- Increases meaningful decisions during a run
- Improves risk vs. reward dynamics
- Integrates cleanly with the existing loop (encounters, objectives, items, crafting)
- Keeps the game simple and extensible

---

## What the game is (technical summary)

A 2D creature-collection expedition RPG. The core loop is:

**Camp → Select Map → Explore Overworld → Battle / Gather / Interact with POIs → Exit → Return to Camp → Craft / Prepare → Repeat**

Runs are repeatable. The map regenerates each expedition (resource nodes, POIs, encounter patches, boss placement). Progression comes from items, captured creatures, and unlocking new maps/recipes — not from grinding levels.

---

## Project structure

```
scripts/
  game_data.gd          — static definitions (creatures, items, maps, abilities, objectives)
  game_state.gd         — runtime state (party, inventory, run state, tutorial flags)
  map_run_service.gd    — generates & applies map runs to the scene
  overworld.gd          — expedition map controller
  overworld_tile_layer.gd — custom TileMapLayer with Wang autotile support
  overworld_poi.gd      — POI Area2D with choice/reward/encounter logic
  encounter_patch.gd    — Area2D marking wild encounter zones
  resource_node.gd      — gatherable resource node (Area2D, procedural visuals)
  player.gd             — grid-based movement, emits `stepped` signal
  battle.gd             — full turn-based combat
  camp.gd               — camp hub (team, crafting, map select, collection)
  bestiary_panel.gd     — modal bestiary UI
  boss_encounter.gd     — boss trigger Area2D
  exit_zone.gd          — exit trigger
scenes/
  Camp.tscn
  Battle.tscn
  overworld/
    Overworld_Verdant.tscn
    Overworld_Ember.tscn
    Player.tscn
    OverworldPOI.tscn
    BossEncounter.tscn
    ResourceNode.tscn
    ExitZone.tscn
  ui/
    ObjectivePanel.tscn
    BattleCreaturePanel.tscn
    CreatureChip.tscn
    MapOptionButton.tscn
    PrimaryActionButton.tscn
assets/
  creatures/   — SVG/PNG creature portraits
  tiles/       — 32×32 terrain tiles
  tilesets/    — 128×128 Wang spritesheets (PNG + JSON metadata)
  resources/   — resource node sprites
  items/       — item icons (SVG)
  ui/stats/    — stat icon SVGs (hp, mp, atk, def, spd, acc, eva, crit, exp)
  ui/abilities/ — ability icons
  ui/camp/     — camp nav icons
```

---

## Static data (game_data.gd)

### Creatures

| id | element | passive | boss? |
|----|---------|---------|-------|
| mossling | grass | verdant_focus (restore 3 MP at battle start) | no |
| cinder_pup | fire | ember_instinct (+5 crit during battle) | no |
| shellhorn | earth | stonehide (+3 DEF during battle) | no |
| mossking | grass | verdant_focus | yes |

Stat scaling per level: +6 HP, +2 MP, +2 ATK, +2 DEF, +1 SPD.
DEFAULT_LEVEL = 4. MAX_LEVEL = 50.

### Abilities

| id | power | mp_cost | element |
|----|-------|---------|---------|
| strike | 10 | 0 | normal |
| leaf_strike | 14 | 2 | grass |
| ember_bite | 14 | 2 | fire |
| horn_bash | 14 | 2 | earth |

Each creature has `abilities: ["strike", "<element_move>"]`.

### Items (19)

**Consumables:** basic_seal (bind attempt), small_potion (+30 HP to one creature), focus_tonic (+5 MP to one creature)

**Held items (equip to creature, one slot):**
moss_charm (+3 DEF), sharp_fang (+3 ATK), stone_ring (+8 HP),
fleet_feather (+2 SPD), hunter_lens (+3 ACC), mist_cloak (+3 EVA),
ember_idol (+3 ATK, fire only), mana_bead (+3 MP)

**Camp items:** party_tent (permanent +1 party slot, base limit 2 → max 3)

### Materials

wood, herb, stone, crystal, core_shard, species_mat

Recipes produce items from material combos. Recipes may be **locked** (require discovery at ancient POIs before appearing in the crafting UI).

### Maps

**verdant_wilds** — tutorial map
- Creatures: mossling, shellhorn (rare), cinder_pup (rare)
- Boss: mossking (level +2, 1.35× stats, 1.8× exp)
- 8 resource spawn points, 4 POI spawns, 4 encounter zones, 2 boss spawn points
- Encounter chance: 10% per step on encounter tile

**ember_caves** — unlocked after defeating mossking
- Boss: alpha_cinder_pup (level +2, 1.4× stats, 1.85× exp)

### Objectives (global sequence, 9 stages)

1. `tutorial_bind` — bind first creature (enter grass + use seal)
2. `gather` wood ×4
3. `gather` herb ×3
4. `craft` small_potion
5. `battle_win` in verdant_wilds
6. `craft` sharp_fang
7. `equip_held_item` sharp_fang
8. `gather_multi` (wood ×5, herb ×2, stone ×2) for party_tent
9. `boss_defeat` mossking

Progress is stored as a single integer index (`global_objective_progression`).

### POI types

| id | description |
|----|-------------|
| rich_grove | Gather bonus resources |
| predator_nest | Risk/reward: safe search vs. lure encounter |
| shrine | Passive buff or healing |
| expedition_cache | Items or materials |
| shortcut | Path unlock |

Ancient POIs (vaults, altars, sealed constructs) are distinct — they gate recipe discovery.

---

## Runtime state (game_state.gd)

```gdscript
# Creatures
party: Array                  # active creatures (limit: get_party_limit())
box: Array                    # stored creatures
BASE_PARTY_LIMIT = 2          # +1 per party_tent owned

# Inventory
materials: Dictionary         # {wood, herb, stone, crystal, core_shard, species_mat}
item_inventory: Dictionary    # consumable counts; starts with 5 basic_seals
owned_camp_items: Dictionary  # {party_tent: int, ...}
unlocked_recipes: Array       # recipe IDs discovered at ancient POIs

# Progression
global_objective_progression: int   # index 0–8
encountered_creatures: Array        # IDs seen (for bestiary)
map_completion_state: Dictionary    # per-map {completed, timestamp}

# Active run
map_run_active: bool
current_map_run: Dictionary   # {resource_nodes, poi_nodes, active_patch_ids, boss_spawn_id, objectives, ...}
current_map_id: String

# Battle handoff
pending_wild_id: String
pending_battle_context: Dictionary  # {level_bonus, stat_multiplier, exp_multiplier, is_boss, ...}
battle_return_scene: String
battle_return_position: Vector2

# Tutorial flags
tutorial_state: Dictionary
first_defeat_explainer_shown: bool
first_boss_warning_shown: bool
ember_unlock_notification_shown: bool
camp_notice: String           # one-shot message shown at camp
```

Key state methods:
- `ensure_starter()` — create mossling if party empty
- `add_creature_to_collection(creature_data)` — to party or box
- `get_effective_creature_stat(creature, stat)` — base + held item bonus + battle bonus
- `craft_item(recipe_id)` — deduct materials, add item
- `begin_map_run(map_id)` / `end_map_run()` — run lifecycle
- `update_objective_progress(type, params)` — advance objective
- `notify_battle_won()`, `notify_creature_captured()`, `notify_boss_defeated()`

---

## Map run system (map_run_service.gd)

`setup_current_map_run(overworld_node)` is called when an expedition scene loads. It either restores an existing run from `game_state.current_map_run` or generates a new one.

**Generation:**
1. `_pick_active_patch_ids()` — select encounter zone subset by weight
2. `_pick_weighted_nodes()` — select resource and POI spawn points
3. Assign resource types/rarities; assign POI types
4. Pick boss spawn point

**Application to scene:**
1. Instantiate `ResourceNode.tscn` instances at selected spawn points
2. Instantiate `OverworldPOI.tscn` instances at selected spawn points
3. Mark `EncounterPatch` nodes active/inactive; call `_sync_encounter_tile_layer()`
4. Instantiate `BossEncounter.tscn` if boss objective is active

**`_sync_encounter_tile_layer(overworld)`:**
Rebuilds `TileMap_Encounter.layout_rows` so visual encounter tiles match active `EncounterPatch` zones. Tests 5 sample points per tile (center + 4 near-corner insets at 0.05/0.95 offsets) against each active patch's `contains_point()`. Any tile where at least one sample hits an active patch gets the encounter tile key (`"f"` or `"h"`).

---

## Tile system (overworld_tile_layer.gd)

`OverworldTileLayer` extends `TileMapLayer` with `@tool`.

**Export properties:**
```gdscript
@export var layout_rows: PackedStringArray  # 2D char grid; "." = empty
@export var tile_paths: Dictionary          # char → "res://assets/tiles/foo.png"
@export var tile_tags: Dictionary           # char → semantic tag string
@export var wang_sets: Dictionary           # char → {json, png, upper_chars}
@export var preview_colors: Dictionary      # char → Color (editor only)
```

**Drawing:**
`_draw()` iterates `layout_rows`. For each non-`.` cell:
- If the char has a Wang set: sample 4 diagonal neighbor chars, determine NW/NE/SW/SE corner terrain ("upper" if neighbor is in `upper_chars`, else "lower"), look up matching tile in the JSON metadata, call `draw_texture_rect_region()` with that tile's `Rect2`.
- Otherwise: `draw_texture_rect()` with the flat tile texture.

**Wang spritesheet format:**
128×128 PNG, 4×4 grid of 32×32 tiles. Tile ID = `NW<<3 | NE<<2 | SW<<1 | SE`. JSON metadata maps each tile's (NW,NE,SW,SE) corner strings to a bounding box `Rect2`. Generated by `scripts/build_wang_tilesets.py` using PIL bilinear blending + S-curve sharpening from pairs of existing 32×32 tile PNGs.

**Active Wang tilesets (assets/tilesets/):**
- `verdant_soil_grass` — dirt ↔ grass
- `verdant_grass_forest` — grass ↔ deep_grove_encounter
- `verdant_grass_tall` — grass ↔ tall_grass_encounter
- `verdant_grass_flowers` — grass ↔ flowers

---

## Overworld_Verdant scene structure

```
Overworld (Node2D, overworld.gd)  encounter_chance=0.1
├── BackgroundRoot (CanvasLayer layer=-1)
│   └── BackgroundFill (ColorRect)
├── TileMap_Background (OverworldTileLayer)  — full grass base; Wang: g↔g transitions
├── TileMap_Ground (OverworldTileLayer)      — terrain details: dirt "d", grass "g", flowers "f"
│   Wang: d↔g (soil_grass), g↔f (grass_flowers); flower patches in rows 0,15-17
├── TileMap_Encounter (OverworldTileLayer)   — tall grass "f", deep grove "h"
│   No Wang (flat tile placed directly on encounter cells)
├── TileMap_Objects (OverworldTileLayer)     — trees "t", bushes "b"
├── GeneratedContent (Node2D)
│   ├── Resources (Node2D)   — ResourceNode instances placed at runtime
│   ├── Boss (Node2D)        — BossEncounter instance placed at runtime
│   └── POIs (Node2D)        — OverworldPOI instances placed at runtime
├── ResourceSpawnPoints (Node2D)  — 8 markers: WestRoots, NorthCanopy, EastBlooms,
│   SouthTrail, ClearingWest, ClearingEast, NorthRim, SouthPocket
├── POISpawnPoints (Node2D)       — 4 markers: EntryCache, WaystoneShrine, RichGrove, PredatorNest
├── EncounterZones (Node2D)       — 4 EncounterPatch (Area2D): CentralFork, ShrineBend,
│   DeepGrove, EntranceFringe
├── BossSpawnPoints (Node2D)      — 2 markers: MosskingGrove, ClearingHeart
├── PlayerSpawn (Marker2D)
├── Player (Player.tscn)
└── ExitZone (ExitZone.tscn)
```

---

## Combat system (battle.gd)

Turn-based, speed-determined order. Each turn: player chooses ability / capture / flee / switch.

**Formulas:**
```
hit_chance  = clamp(accuracy * (atk_acc / def_eva), 0.35, 0.95)
damage      = max(1, (move_power + atk_attack) * (1.0 - def_defense / (def_defense + 25.0)))
crit        = 2× damage if roll < crit_chance
flee_chance = clamp(0.55 + spd_diff_ratio * 0.40 + failed_attempts * 0.12, 0.25, 0.95)
```

**Capture:** consumes a basic_seal. Bind succeeds or fails (shown with animation). Captured creature goes to party or box. If party full it goes to box.

**Rewards on win:** exp (possibly boss-multiplied) + possible drops (items/materials from map's reward table). Wild creatures can drop materials; bosses drop specific items.

**Passives** apply as stat bonuses at battle start (stored in `battle_bonuses` dict, not written to game_state creature permanently).

**Outcome routing:**
- Win → return to overworld at `battle_return_position`
- Loss → run forfeited, return to Camp

---

## Camp (camp.gd)

Four views: `MAIN`, `COLLECTION`, `MAPS`, `CRAFTING`.

**MAIN:** team preview chips, current objective summary, map selector, VENTURE button.

**COLLECTION:** creature detail (stats as icon+value chips, element, passive), held item equip/unequip, consumable use, box access, party ↔ box transfer.

**MAPS:** list of unlocked maps, selection, lock hints for locked maps.

**CRAFTING:** material inventory display, recipe list with category tabs (consumable / held / camp), owned-only and craftable-only filters, search. Recipe-locked items hidden until discovered.

**Tutorial system:** intro overlay with step-by-step highlights. Currently suppressed (`intro_overlay.visible = false`) for testing.

---

## UI conventions

- All titles/headers/buttons are **UPPERCASE**.
- Stats always displayed as **icon + numeric value** (never text abbreviations). Icons at `res://assets/ui/stats/*_icon.svg`.
- Font stack: Cinzel (headers), CrimsonText / Lora / CormorantGaramond (body), m5x7 (pixel accents).
- Theme file: `ui/theme.tres`.

---

## Coding conventions

- **Explicit typing everywhere.** Never infer from Variant. `var x: int = some_dict.get("key", 0)` not `var x = ...`
- Static definitions → `game_data.gd`. Runtime state → `game_state.gd`. Never mix.
- Scripts are modular; avoid large monoliths.
- Comments only for non-obvious WHY (hidden constraints, workarounds). No docstrings.
- No error handling for impossible cases. No backwards-compat shims.
