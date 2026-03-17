# Designer

## Core

This document defines the desired **game design core** for this project.

If I analyze the current game, its identity is already clear:

- a small creature-collection RPG loop
- venture-based exploration
- data-driven map variation
- lightweight party management
- crafting as expedition preparation
- boss-clear progression

The design core that should be preserved and strengthened:

- **Primary fantasy**: prepare at camp, enter a dangerous biome, gather resources, fight or capture creatures, defeat the biome boss, return stronger.
- **Primary loop**: `Prepare -> Venture -> Encounter -> Reward -> Progress Objective -> Return -> Craft / Manage Team -> Venture again`.
- **Session shape**: short readable runs, not endless wandering.
- **Decision density**: the player should regularly choose between safety, resources, capture value, and boss progress.
- **Biome identity**: each map must feel mechanically different, not only visually different.
- **Reward readability**: the player must understand why they received materials, objective progress, or battle rewards.
- **Roster value**: creatures should matter through stats, passives, item loadout, and matchup role.
- **Crafting purpose**: crafting must support venture planning, not exist as a detached menu activity.
- **Boss purpose**: boss fights must certify that the player understood the biome loop.

Current design pillars for this repository:

- `Verdant Wilds` teaches gather -> craft -> capture -> boss.
- `Ember Caves` raises pressure through stronger resource and combat economy.
- resource nodes are not only economy objects; they are also risk triggers
- objectives are not side text; they are the structure of player learning
- camp is not only a menu; it is the planning and recovery phase

Design rules that should guide future content:

- Every map must introduce a distinct risk/reward profile.
- Every resource type must have gameplay meaning, not only recipe presence.
- Every creature should have a readable combat role.
- Every new item must answer "why would the player craft or equip this now?"
- Every objective chain must teach, reinforce, or test one intended behavior.
- Every reward source must support the main loop instead of distracting from it.
- Every UI message should clarify player consequence, not restate raw data only.

Good future expansions for this project:

- more explicit biome-specific encounter modifiers
- clearer enemy roles and passive interactions
- objective variants that encourage different route choices
- stronger map exit and boss pacing signals
- better progression communication for crafting and team upgrades

## Review guidelines

These design review rules should be enforced strictly. If a change breaks the design core, it should be rejected even if the implementation is technically clean.

Immediate rejection criteria:

- Reject if a feature weakens the main venture loop without replacing it with a stronger loop.
- Reject if a new system adds menu complexity but does not create meaningful player decisions.
- Reject if a new map differs only in art and numbers, but not in behavior or decision-making.
- Reject if rewards become harder to understand after the change.
- Reject if an objective asks the player to do something the game does not teach or signal.
- Reject if crafting items have no clear expedition value.
- Reject if a creature, item, or resource is added without a readable role.
- Reject if a boss can be beaten through the exact same behavior as regular encounters with no additional test.
- Reject if randomness hides player agency instead of creating tension.
- Reject if a change increases grind without increasing interesting choices.

Design review checklist:

- Can the player explain the current goal in one sentence?
- Can the player explain why one route, item, or creature is better in this run?
- Does the map present at least one meaningful tradeoff?
- Does the reward model reinforce the intended behavior?
- Does the system create anticipation, tension, payoff, or mastery?
- Does the feature improve the feeling of preparing for and surviving a venture?
- Does failure teach something useful?
- Does success feel earned and legible?

Balance review checklist:

- Strong options must have clear cost, setup requirement, or risk.
- Weak options must still have a niche or be removed.
- Early-game objectives must teach one thing at a time.
- Mid-game content must combine known lessons under pressure.
- Rare rewards must feel exciting without becoming mandatory.
- Resource scarcity must create planning, not confusion.

Game design north star:

- The player should always feel that camp choices matter in the field, and field choices matter back at camp.

