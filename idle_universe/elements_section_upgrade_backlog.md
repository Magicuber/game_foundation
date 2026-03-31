# Elements Section Upgrade Backlog

Date: 2026-03-30

## Review Scope

This backlog was derived from the current `idle_universe` implementation and the design notes in `M:\Ai stuff\Notes`.

Primary code and data reviewed:

- `idle_universe/src/bootstrap/game_loader.gd`
- `idle_universe/src/core/game_state.gd`
- `idle_universe/src/systems/element_system.gd`
- `idle_universe/src/systems/upgrades_system.gd`
- `idle_universe/src/data/elements.json`
- `idle_universe/src/data/upgrades.json`
- `idle_universe/dust_scaling_comparison.md`

Primary design notes reviewed:

- `M:\Ai stuff\Notes\shared_systems.md`
- `M:\Ai stuff\Notes\upgrades.md`
- `M:\Ai stuff\Notes\skill_trees.md`
- `M:\Ai stuff\Notes\idle_math_models.md`
- `M:\Ai stuff\Notes\prestige_systems.md`
- `M:\Ai stuff\Notes\progression_design_7.md`
- `M:\Ai stuff\Notes\progression_design_10.md`

Project thread note:

- No separate MCP or shared project-thread history was exposed to this session, so prior discussion context was inferred from repo docs and the external notes set.

## Key Takeaways From The Review

- The Elements menu already has strong scaffolding for section-based expansion, Dust conversion, and next-unlock messaging.
- The current live upgrade model is data-driven, but only three effect handlers exist: `auto_smash`, `critical_auto_smash`, and `fission_split`.
- Dust already has a readable hybrid quality formula, which makes recipe, selection, and automation upgrades especially high-leverage.
- Section visibility, era gating, and late-element ranges are already present in the data model, so future-facing upgrades can scale cleanly if effect handlers are added.
- The biggest near-term gap is not raw content volume; it is player-facing buildcraft inside the Elements panel.

## Scoring Scale

- Relevance: `1` = weak fit for the current game, `5` = directly aligned with the current Elements loop.
- Uniqueness: `1` = common idle pattern, `5` = strong identity-builder for this game.
- Implementation Time: `1` = light extension or UI hook, `5` = major multi-system feature.
- Scalability: `1` = narrow/local effect, `5` = grows well across sections, eras, and future content.

## Assumptions

- Ordering is strongest near-term fit first, then broader and more experimental upgrades later.
- Every JSON block below follows the raw `src/data/upgrades.json` shape currently used by `idle_universe`.
- Proposed `effect_type` values are design targets only. Most would need new handler logic in `UpgradesSystem`, `GameState`, and/or `game_loader.gd`.

## 1. Cascade Hammers

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 5

Adds a repeat roll to automated smashing so the existing `particle_smasher` path has a clean second-stage upgrade.

```json
{
  "id": "cascade_hammers",
  "name": "Cascade Hammers",
  "description": "Auto smashes have a chance to immediately repeat on the same selected element.",
  "currency_id": "ele_H",
  "tier": 1,
  "base_cost": 60,
  "cost_mode": "additive_power",
  "cost_scaling": 1.45,
  "max_level": 25,
  "current_level": 0,
  "effect_type": "auto_smash_echo",
  "effect_amount": 0.04
}
```

## 2. Manual Overcharge

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Rewards active play by charging a stronger smash after repeated manual taps, keeping manual interaction relevant beside automation.

```json
{
  "id": "manual_overcharge",
  "name": "Manual Overcharge",
  "description": "Repeated manual smashes charge a burst hit that produces extra output.",
  "currency_id": "ele_H",
  "tier": 1,
  "base_cost": 80,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "manual_combo_bonus",
  "effect_amount": 1.0
}
```

## 3. Critical Retuning

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Expands crit logic beyond Proton-spawn flavor by letting critical behavior improve both manual and automated production bursts.

```json
{
  "id": "critical_retuning",
  "name": "Critical Retuning",
  "description": "Critical smashes can upgrade both manual and auto output into larger bursts.",
  "currency_id": "ele_He",
  "tier": 1,
  "base_cost": 120,
  "cost_mode": "additive_power",
  "cost_scaling": 1.55,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "critical_output_bonus",
  "effect_amount": 0.08
}
```

## 4. Unlock Tunneling

Scores: Relevance 5 | Uniqueness 2 | Implementation Time 1 | Scalability 5

Directly supports the current next-element unlock loop by shaving cost off the next visible unlock.

```json
{
  "id": "unlock_tunneling",
  "name": "Unlock Tunneling",
  "description": "Reduces the cost of the next unlockable element.",
  "currency_id": "ele_He",
  "tier": 1,
  "base_cost": 150,
  "cost_mode": "additive_power",
  "cost_scaling": 1.45,
  "max_level": 25,
  "current_level": 0,
  "effect_type": "unlock_cost_discount",
  "effect_amount": 0.02
}
```

## 5. Auto Unlock Circuit

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Turns the current unlock button into a later-game automation target, reducing menu friction without bypassing the existing section gates.

```json
{
  "id": "auto_unlock_circuit",
  "name": "Auto Unlock Circuit",
  "description": "Automatically unlocks the next visible element when its cost is affordable.",
  "currency_id": "ele_Ne",
  "tier": 2,
  "base_cost": 900,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "auto_unlock_next",
  "effect_amount": 1.0
}
```

## 6. Adjacent Spillover

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 5

Makes element progression feel more chemical and less linear by sometimes granting output from a neighboring unlocked element.

```json
{
  "id": "adjacent_spillover",
  "name": "Adjacent Spillover",
  "description": "Smashes have a chance to also produce a neighboring unlocked element.",
  "currency_id": "ele_Ne",
  "tier": 2,
  "base_cost": 1200,
  "cost_mode": "additive_power",
  "cost_scaling": 1.55,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "adjacent_output_chance",
  "effect_amount": 0.03
}
```

## 7. Section Breakthrough

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 3 | Scalability 5

Leverages the existing sectioned Elements menu by giving each completed visible section a permanent section-wide boost.

```json
{
  "id": "section_breakthrough",
  "name": "Section Breakthrough",
  "description": "Completing a visible element section grants a permanent production bonus for that section.",
  "currency_id": "ele_Si",
  "tier": 2,
  "base_cost": 2500,
  "cost_mode": "additive_power",
  "cost_scaling": 1.7,
  "max_level": 5,
  "current_level": 0,
  "effect_type": "section_completion_bonus",
  "effect_amount": 0.25
}
```

## 8. Shell Closure

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 2 | Scalability 5

Ties major progression spikes to noble-gas milestones, which fits both chemistry theme and the current section breakpoints.

```json
{
  "id": "shell_closure",
  "name": "Shell Closure",
  "description": "Unlocking a noble gas grants a permanent boost to its completed atomic shell.",
  "currency_id": "dust",
  "tier": 2,
  "base_cost": 4000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.65,
  "max_level": 5,
  "current_level": 0,
  "effect_type": "noble_gas_milestone_bonus",
  "effect_amount": 0.2
}
```

## 9. Atomic Ladder

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 3 | Scalability 5

Uses total unlocked elements as a global progression stat so early atoms stay useful as the table expands.

```json
{
  "id": "atomic_ladder",
  "name": "Atomic Ladder",
  "description": "Every unlocked element increases production of lower atomic-number elements.",
  "currency_id": "ele_Si",
  "tier": 2,
  "base_cost": 3500,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "unlocked_element_synergy",
  "effect_amount": 0.01
}
```

## 10. Bulk Smash Matrix

Scores: Relevance 4 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Lets manual play batch actions instead of raw taps, which keeps the fuse interaction viable later without requiring autoplay.

```json
{
  "id": "bulk_smash_matrix",
  "name": "Bulk Smash Matrix",
  "description": "Manual smashes can resolve as multi-hit bursts instead of single taps.",
  "currency_id": "dust",
  "tier": 2,
  "base_cost": 6000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.8,
  "max_level": 5,
  "current_level": 0,
  "effect_type": "manual_bulk_smash",
  "effect_amount": 1.0
}
```

## 11. Dust Lens

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 2 | Scalability 5

Adds a high-value UX layer by previewing profitable Dust batches instead of forcing blind selection.

```json
{
  "id": "dust_lens",
  "name": "Dust Lens",
  "description": "Shows the best currently affordable Dust recipes inside the Elements menu.",
  "currency_id": "dust",
  "tier": 1,
  "base_cost": 250,
  "cost_mode": "additive_power",
  "cost_scaling": 1.0,
  "max_level": 1,
  "current_level": 0,
  "effect_type": "dust_recipe_preview",
  "effect_amount": 1.0
}
```

## 12. Fraction Locks

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 1 | Scalability 4

Expands the Dust selector with finer percentage steps so the existing system becomes tactically deeper with minimal new tech.

```json
{
  "id": "fraction_locks",
  "name": "Fraction Locks",
  "description": "Unlocks finer Dust selection percentages for each element tile.",
  "currency_id": "dust",
  "tier": 1,
  "base_cost": 500,
  "cost_mode": "additive_power",
  "cost_scaling": 1.0,
  "max_level": 1,
  "current_level": 0,
  "effect_type": "dust_selection_granularity",
  "effect_amount": 1.0
}
```

## 13. Stable Blend Catalyst

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 2 | Scalability 5

Builds directly on the current Dust variety formula by making balanced recipes more rewarding.

```json
{
  "id": "stable_blend_catalyst",
  "name": "Stable Blend Catalyst",
  "description": "Balanced Dust recipes gain a matched-stack efficiency bonus.",
  "currency_id": "dust",
  "tier": 2,
  "base_cost": 1800,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "dust_matched_set_bonus",
  "effect_amount": 0.05
}
```

## 14. Entropy Recovery

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 5

Softens Dust conversion loss and makes recipe experimentation less punishing, especially on rare elements.

```json
{
  "id": "entropy_recovery",
  "name": "Entropy Recovery",
  "description": "Dust conversion refunds a share of the consumed elements.",
  "currency_id": "dust",
  "tier": 2,
  "base_cost": 2200,
  "cost_mode": "additive_power",
  "cost_scaling": 1.65,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "dust_refund_rate",
  "effect_amount": 0.02
}
```

## 15. Cross-Section Blend

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 5

Pushes players to use multiple periodic-table bands together instead of staying inside one section forever.

```json
{
  "id": "cross_section_blend",
  "name": "Cross-Section Blend",
  "description": "Dust recipes gain extra quality when they include elements from multiple visible sections.",
  "currency_id": "dust",
  "tier": 3,
  "base_cost": 7500,
  "cost_mode": "additive_power",
  "cost_scaling": 1.7,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "dust_section_variety_bonus",
  "effect_amount": 0.08
}
```

## 16. Dust Ignition

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Turns Dust conversion into an active tempo tool by attaching a short-lived atomic speed buff after each conversion.

```json
{
  "id": "dust_ignition",
  "name": "Dust Ignition",
  "description": "Creating Dust grants a short global smash-speed boost.",
  "currency_id": "dust",
  "tier": 2,
  "base_cost": 2600,
  "cost_mode": "additive_power",
  "cost_scaling": 1.55,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "post_dust_haste",
  "effect_amount": 0.04
}
```

## 17. Recipe Codex

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 3 | Scalability 5

Lets players save successful Dust recipes, which matters more as section count and recipe complexity rise.

```json
{
  "id": "recipe_codex",
  "name": "Recipe Codex",
  "description": "Unlocks save slots for named Dust recipe presets.",
  "currency_id": "dust",
  "tier": 2,
  "base_cost": 4000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 5,
  "current_level": 0,
  "effect_type": "dust_recipe_slots",
  "effect_amount": 1.0
}
```

## 18. Dust Autobatcher

Scores: Relevance 5 | Uniqueness 5 | Implementation Time 4 | Scalability 5

Creates a long-term aspiration upgrade by letting the game automatically repeat a stored Dust recipe over time.

```json
{
  "id": "dust_autobatcher",
  "name": "Dust Autobatcher",
  "description": "Automatically repeats a saved Dust recipe at a fixed interval.",
  "currency_id": "dust",
  "tier": 3,
  "base_cost": 15000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.75,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "auto_dust_batch",
  "effect_amount": 0.1
}
```

## 19. Iron Peak Smelter

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 5

Uses the real-world stability theme already present in Dust math by making iron-peak elements especially efficient converters.

```json
{
  "id": "iron_peak_smelter",
  "name": "Iron Peak Smelter",
  "description": "Elements near the iron peak contribute extra Dust quality.",
  "currency_id": "ele_Fe",
  "tier": 3,
  "base_cost": 9000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.65,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "dust_stability_peak_bonus",
  "effect_amount": 0.04
}
```

## 20. Noble Gas Compression

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Adds a distinct family bonus that makes noble gases more than just progression checkpoints.

```json
{
  "id": "noble_gas_compression",
  "name": "Noble Gas Compression",
  "description": "Noble gases contribute extra efficiency to Dust conversions.",
  "currency_id": "ele_Xe",
  "tier": 3,
  "base_cost": 12000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.65,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "dust_family_bonus_noble",
  "effect_amount": 0.05
}
```

## 21. Hydrogen Prime

Scores: Relevance 4 | Uniqueness 2 | Implementation Time 1 | Scalability 4

Gives the first real atom a persistent identity by making Hydrogen stronger as the table expands.

```json
{
  "id": "hydrogen_prime",
  "name": "Hydrogen Prime",
  "description": "Hydrogen production scales with total unlocked elements.",
  "currency_id": "ele_H",
  "tier": 1,
  "base_cost": 40,
  "cost_mode": "additive_power",
  "cost_scaling": 1.4,
  "max_level": 30,
  "current_level": 0,
  "effect_type": "element_scaling_bonus_h",
  "effect_amount": 0.01
}
```

## 22. Helium Buffer

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Turns surplus Helium into a useful support resource instead of a simple step on the ladder.

```json
{
  "id": "helium_buffer",
  "name": "Helium Buffer",
  "description": "Stored Helium improves unlock efficiency and fission reliability.",
  "currency_id": "ele_He",
  "tier": 1,
  "base_cost": 200,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "helium_support_bonus",
  "effect_amount": 0.03
}
```

## 23. Carbon Framework

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 5

Anchors a mid-early recipe identity around Carbon by boosting mixed-element Dust structures.

```json
{
  "id": "carbon_framework",
  "name": "Carbon Framework",
  "description": "Carbon-heavy recipes gain extra Dust diversity efficiency.",
  "currency_id": "ele_C",
  "tier": 2,
  "base_cost": 1200,
  "cost_mode": "additive_power",
  "cost_scaling": 1.55,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "carbon_recipe_bonus",
  "effect_amount": 0.05
}
```

## 24. Neon Gatekeeper

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 1 | Scalability 5

Uses the existing `ERA_MENU_UNLOCK_ELEMENT_ID` milestone as a natural point for a major atomic progression accelerant.

```json
{
  "id": "neon_gatekeeper",
  "name": "Neon Gatekeeper",
  "description": "Unlocking Neon permanently improves future element unlock pacing.",
  "currency_id": "ele_Ne",
  "tier": 2,
  "base_cost": 1400,
  "cost_mode": "additive_power",
  "cost_scaling": 1.45,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "post_neon_unlock_bonus",
  "effect_amount": 0.03
}
```

## 25. Silicon Scaffold

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Positions Silicon as a structural atom that enhances section-level systems rather than raw throughput alone.

```json
{
  "id": "silicon_scaffold",
  "name": "Silicon Scaffold",
  "description": "Section bonuses and tile-based effects gain extra strength from Silicon.",
  "currency_id": "ele_Si",
  "tier": 2,
  "base_cost": 2800,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "section_bonus_amp_si",
  "effect_amount": 0.05
}
```

## 26. Transition Foundry

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 5

Gives the dense midgame transition-metal stretch a distinct upgrade identity instead of feeling like a long homogeneous block.

```json
{
  "id": "transition_foundry",
  "name": "Transition Foundry",
  "description": "Transition metal elements gain stronger production and recipe synergy.",
  "currency_id": "ele_Fe",
  "tier": 3,
  "base_cost": 6000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.65,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "transition_metal_bonus",
  "effect_amount": 0.04
}
```

## 27. Iron Core

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 5

Makes Iron a central atomic milestone by turning it into the anchor for section-wide passive power.

```json
{
  "id": "iron_core",
  "name": "Iron Core",
  "description": "Iron increases section-wide passive generation and Dust quality.",
  "currency_id": "ele_Fe",
  "tier": 3,
  "base_cost": 8500,
  "cost_mode": "additive_power",
  "cost_scaling": 1.7,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "iron_anchor_bonus",
  "effect_amount": 0.06
}
```

## 28. Silver Conductor

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Pushes coinage metals toward a crit and automation identity, which is strong both mechanically and thematically.

```json
{
  "id": "silver_conductor",
  "name": "Silver Conductor",
  "description": "Copper, Silver, and Gold family effects improve crit chaining and auto-smash throughput.",
  "currency_id": "ele_Ag",
  "tier": 3,
  "base_cost": 18000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.7,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "coinage_family_chain_bonus",
  "effect_amount": 0.05
}
```

## 29. Xenon Flash

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 3 | Scalability 4

Adds a flashy reactive identity to late noble gases by turning them into temporary global haste triggers.

```json
{
  "id": "xenon_flash",
  "name": "Xenon Flash",
  "description": "Noble gas actions can trigger a temporary global speed burst.",
  "currency_id": "ele_Xe",
  "tier": 3,
  "base_cost": 22000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.7,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "noble_gas_haste_proc",
  "effect_amount": 0.08
}
```

## 30. Gold Foil Target

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 3 | Scalability 4

Makes Gold matter in the atomic layer by letting high-value hits bleed some of their value into Dust.

```json
{
  "id": "gold_foil_target",
  "name": "Gold Foil Target",
  "description": "Critical atomic hits can generate bonus Dust splinters.",
  "currency_id": "ele_Au",
  "tier": 4,
  "base_cost": 120000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.75,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "crit_to_dust_splinter",
  "effect_amount": 0.1
}
```

## 31. Lanthanide Lattice

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 5

Gives the rare-earth stretch a strong late-game support identity by amplifying all atomic automation layers.

```json
{
  "id": "lanthanide_lattice",
  "name": "Lanthanide Lattice",
  "description": "Lanthanide elements amplify atomic automation and recipe support effects.",
  "currency_id": "ele_Nd",
  "tier": 4,
  "base_cost": 180000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.75,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "rare_earth_automation_bonus",
  "effect_amount": 0.05
}
```

## 32. Actinide Reactor

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 3 | Scalability 4

Turns the actinide range into a separate late-game identity by converting radioactive instability into passive Dust.

```json
{
  "id": "actinide_reactor",
  "name": "Actinide Reactor",
  "description": "Actinide elements slowly generate Dust passively over time.",
  "currency_id": "ele_U",
  "tier": 5,
  "base_cost": 400000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.8,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "actinide_passive_dust",
  "effect_amount": 0.06
}
```

## 33. Uranium Cascade

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 4 | Scalability 5

Evolves the current fission mechanic into a late-game signature system by occasionally adding an extra fragment to heavy output.

```json
{
  "id": "uranium_cascade",
  "name": "Uranium Cascade",
  "description": "Heavy-element fission can split into an extra fragment instead of stopping at two parts.",
  "currency_id": "ele_U",
  "tier": 5,
  "base_cost": 500000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.85,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "fission_extra_fragment",
  "effect_amount": 0.03
}
```

## 34. Era Catalyst

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 3 | Scalability 5

Bridges the atomic and era systems by making element progress more valuable to the next implemented layer.

```json
{
  "id": "era_catalyst",
  "name": "Era Catalyst",
  "description": "Completed element milestones improve efficiency toward the next era unlock.",
  "currency_id": "dust",
  "tier": 4,
  "base_cost": 250000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.8,
  "max_level": 5,
  "current_level": 0,
  "effect_type": "era_requirement_efficiency",
  "effect_amount": 0.2
}
```

## 35. Orbital Blueprints

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 3 | Scalability 5

Improves long-term cohesion by making atomic mastery feed directly into the future planet loop.

```json
{
  "id": "orbital_blueprints",
  "name": "Orbital Blueprints",
  "description": "Element milestones reduce the material requirements for early planetary progression.",
  "currency_id": "dust",
  "tier": 4,
  "base_cost": 300000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.8,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "planetary_bridge_bonus",
  "effect_amount": 0.05
}
```

## 36. Section Surveyor

Scores: Relevance 4 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Exposes more future table structure ahead of `world_level` progression, which gives players better medium-term planning targets.

```json
{
  "id": "section_surveyor",
  "name": "Section Surveyor",
  "description": "Reveals an additional locked Elements section ahead of world progression.",
  "currency_id": "dust",
  "tier": 2,
  "base_cost": 3200,
  "cost_mode": "additive_power",
  "cost_scaling": 1.7,
  "max_level": 4,
  "current_level": 0,
  "effect_type": "visible_section_bonus",
  "effect_amount": 1.0
}
```

## 37. Atomic Presets

Scores: Relevance 4 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Adds practical quality-of-life by saving current element focus and Dust selections as reusable loadouts.

```json
{
  "id": "atomic_presets",
  "name": "Atomic Presets",
  "description": "Unlocks preset slots for saved element focus and Dust selection layouts.",
  "currency_id": "dust",
  "tier": 2,
  "base_cost": 2800,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 5,
  "current_level": 0,
  "effect_type": "atomic_preset_slots",
  "effect_amount": 1.0
}
```

## 38. Archive Scanner

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 5

Uses historical run data to tell the player which element or recipe path has been most efficient so far.

```json
{
  "id": "archive_scanner",
  "name": "Archive Scanner",
  "description": "Shows best-ever element batches, unlock timings, and Dust recipe records.",
  "currency_id": "dust",
  "tier": 2,
  "base_cost": 3500,
  "cost_mode": "additive_power",
  "cost_scaling": 1.0,
  "max_level": 1,
  "current_level": 0,
  "effect_type": "atomic_analytics_unlock",
  "effect_amount": 1.0
}
```

## 39. Offline Collider

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 3 | Scalability 5

Adds a high-value idle-game expectation that fits the current automated smash model and scales well across future content layers.

```json
{
  "id": "offline_collider",
  "name": "Offline Collider",
  "description": "A share of auto-smashing and saved Dust batching continues while offline.",
  "currency_id": "dust",
  "tier": 4,
  "base_cost": 200000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.85,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "offline_atomic_efficiency",
  "effect_amount": 0.03
}
```

## 40. Quantum Snapshot

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 3 | Scalability 4

Creates a strategic timing layer by storing free or discounted unlock charges over time for use on bottleneck elements.

```json
{
  "id": "quantum_snapshot",
  "name": "Quantum Snapshot",
  "description": "Periodically stores an unlock charge that can be spent on the next element unlock.",
  "currency_id": "dust",
  "tier": 4,
  "base_cost": 260000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.8,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "unlock_charge_rate",
  "effect_amount": 0.1
}
```

## 41. Family Resonance

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 4 | Scalability 5

Turns periodic-table families into real progression sets, which would give the Elements menu much stronger identity than a pure numeric ladder.

```json
{
  "id": "family_resonance",
  "name": "Family Resonance",
  "description": "Completing a chemical family unlocks a permanent family-specific bonus.",
  "currency_id": "dust",
  "tier": 3,
  "base_cost": 18000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.75,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "family_completion_bonus",
  "effect_amount": 0.05
}
```

## 42. Event Trigger Matrix

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 4 | Scalability 4

Introduces controlled random events into the atomic layer, which the external notes repeatedly highlight as a useful secondary system.

```json
{
  "id": "event_trigger_matrix",
  "name": "Event Trigger Matrix",
  "description": "Atomic actions can trigger temporary events such as flares, surges, or anomaly batches.",
  "currency_id": "dust",
  "tier": 3,
  "base_cost": 24000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.8,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "atomic_event_chance",
  "effect_amount": 0.03
}
```

## 43. Element Mastery Seeds

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 4 | Scalability 5

Creates a permanent atomic mastery track that can survive future reset layers and keep full-section clears meaningful.

```json
{
  "id": "element_mastery_seeds",
  "name": "Element Mastery Seeds",
  "description": "Section completions generate permanent Element Mastery used for atomic upgrades.",
  "currency_id": "dust",
  "tier": 4,
  "base_cost": 280000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.8,
  "max_level": 5,
  "current_level": 0,
  "effect_type": "element_mastery_gain",
  "effect_amount": 1.0
}
```

## 44. Atomic Research Branch

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 5 | Scalability 5

Acts as the unlock point for a dedicated branching atomic tech tree, matching the strongest long-term note recommendations around skill trees.

```json
{
  "id": "atomic_research_branch",
  "name": "Atomic Research Branch",
  "description": "Unlocks a branching research tree dedicated to the Elements layer.",
  "currency_id": "dust",
  "tier": 4,
  "base_cost": 350000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.0,
  "max_level": 1,
  "current_level": 0,
  "effect_type": "atomic_tree_unlock",
  "effect_amount": 1.0
}
```

## 45. Periodic Atlas

Scores: Relevance 3 | Uniqueness 4 | Implementation Time 3 | Scalability 5

Adds family and block metadata to the Elements UI so future upgrades can target alkali metals, halogens, noble gases, and similar sets cleanly.

```json
{
  "id": "periodic_atlas",
  "name": "Periodic Atlas",
  "description": "Unlocks family, block, and chemistry-tag overlays inside the Elements menu.",
  "currency_id": "dust",
  "tier": 3,
  "base_cost": 30000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.0,
  "max_level": 1,
  "current_level": 0,
  "effect_type": "periodic_metadata_unlock",
  "effect_amount": 1.0
}
```

## 46. Derivative Relay

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 4 | Scalability 5

Imports the strongest derivative-generator idea from incremental design notes by letting high-tier elements slowly feed lower-tier ones.

```json
{
  "id": "derivative_relay",
  "name": "Derivative Relay",
  "description": "Higher elements passively generate lower adjacent elements over time.",
  "currency_id": "ele_Au",
  "tier": 4,
  "base_cost": 220000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.8,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "downstream_element_generation",
  "effect_amount": 0.04
}
```

## 47. Radioactive Half-Life

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 4 | Scalability 5

Turns late heavy elements into a novel source of timed conversions, decay decisions, and passive Dust generation.

```json
{
  "id": "radioactive_half_life",
  "name": "Radioactive Half-Life",
  "description": "Heavy radioactive elements slowly decay into lower elements or Dust.",
  "currency_id": "ele_U",
  "tier": 5,
  "base_cost": 750000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.9,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "radioactive_decay_rate",
  "effect_amount": 0.05
}
```

## 48. Vacuum Extraction

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 3 | Scalability 5

Lets Dust partially reverse the normal one-way flow by backfilling missing unlock resources, which gives Dust a second strategic use.

```json
{
  "id": "vacuum_extraction",
  "name": "Vacuum Extraction",
  "description": "Dust can backfill a share of the cost for blocked element unlocks.",
  "currency_id": "dust",
  "tier": 5,
  "base_cost": 500000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.85,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "dust_unlock_subsidy",
  "effect_amount": 0.04
}
```

## 49. Prestige Nuclei

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 5 | Scalability 5

Creates an atomic reset layer that could eventually sit underneath planets and above raw element grinding, matching the external prestige guidance.

```json
{
  "id": "prestige_nuclei",
  "name": "Prestige Nuclei",
  "description": "Unlocks an atomic prestige reset that awards permanent Nuclei bonuses.",
  "currency_id": "dust",
  "tier": 5,
  "base_cost": 1000000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.0,
  "max_level": 1,
  "current_level": 0,
  "effect_type": "atomic_prestige_unlock",
  "effect_amount": 1.0
}
```

## 50. Universal Periodicity

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 5 | Scalability 5

Acts as a capstone system where completed families, sections, and atomic milestones all feed a single global multiplier model.

```json
{
  "id": "universal_periodicity",
  "name": "Universal Periodicity",
  "description": "Completed sections, families, and milestone atoms feed a single global atomic multiplier.",
  "currency_id": "dust",
  "tier": 5,
  "base_cost": 1500000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.9,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "global_periodic_mastery",
  "effect_amount": 0.08
}
```

## Recommended First 10 To Build

If the goal is strongest payoff with the lowest implementation risk, start here:

1. `unlock_tunneling`
2. `cascade_hammers`
3. `dust_lens`
4. `fraction_locks`
5. `auto_unlock_circuit`
6. `stable_blend_catalyst`
7. `entropy_recovery`
8. `shell_closure`
9. `section_breakthrough`
10. `offline_collider`

That mix strengthens the existing atomic loop, the Dust system, and long-session quality-of-life without forcing a full new progression layer on day one.

## Additional Tier 1 Early-Game Upgrades

These 20 supplements are focused specifically on speeding the first shell, smoothing the first Dust interactions, and reducing early unlock friction. All of them use `tier: 1`.

## 51. Proton Primer

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Gives the first few minutes more energy by making manual smashing of the lightest atoms feel stronger immediately.

```json
{
  "id": "proton_primer",
  "name": "Proton Primer",
  "description": "Manual smashes of the lightest elements have a chance to create extra output.",
  "currency_id": "ele_H",
  "tier": 1,
  "base_cost": 15,
  "cost_mode": "additive_power",
  "cost_scaling": 1.35,
  "max_level": 25,
  "current_level": 0,
  "effect_type": "manual_early_bonus",
  "effect_amount": 0.03
}
```

## 52. Hydrogen Momentum

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Rewards uninterrupted early manual play by ramping speed during short smashing streaks.

```json
{
  "id": "hydrogen_momentum",
  "name": "Hydrogen Momentum",
  "description": "Consecutive manual smashes build a short-lived speed bonus.",
  "currency_id": "ele_H",
  "tier": 1,
  "base_cost": 30,
  "cost_mode": "additive_power",
  "cost_scaling": 1.4,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "consecutive_manual_haste",
  "effect_amount": 0.04
}
```

## 53. Light Element Focus

Scores: Relevance 5 | Uniqueness 2 | Implementation Time 1 | Scalability 5

Adds a clean first-section multiplier so the early table progresses faster without complex new rules.

```json
{
  "id": "light_element_focus",
  "name": "Light Element Focus",
  "description": "Elements in the first section produce more efficiently.",
  "currency_id": "ele_He",
  "tier": 1,
  "base_cost": 45,
  "cost_mode": "additive_power",
  "cost_scaling": 1.4,
  "max_level": 30,
  "current_level": 0,
  "effect_type": "first_section_output_bonus",
  "effect_amount": 0.02
}
```

## 54. Starter Cache

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Reduces the dead air after each new unlock by seeding a small starter stack of the newly unlocked element.

```json
{
  "id": "starter_cache",
  "name": "Starter Cache",
  "description": "Unlocking a new element grants a small starter amount of that element.",
  "currency_id": "ele_He",
  "tier": 1,
  "base_cost": 80,
  "cost_mode": "additive_power",
  "cost_scaling": 1.45,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "unlock_grant_amount",
  "effect_amount": 3.0
}
```

## 55. Guided Unlocks

Scores: Relevance 5 | Uniqueness 2 | Implementation Time 1 | Scalability 4

Cheap early discounting aimed specifically at getting players through the first ten elements without long stalls.

```json
{
  "id": "guided_unlocks",
  "name": "Guided Unlocks",
  "description": "Reduces unlock costs for early elements.",
  "currency_id": "ele_He",
  "tier": 1,
  "base_cost": 100,
  "cost_mode": "additive_power",
  "cost_scaling": 1.4,
  "max_level": 25,
  "current_level": 0,
  "effect_type": "early_unlock_discount",
  "effect_amount": 0.02
}
```

## 56. First Shell Rush

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Each early unlock accelerates the rest of the first shell, which makes the opening stretch feel like a chain rather than isolated steps.

```json
{
  "id": "first_shell_rush",
  "name": "First Shell Rush",
  "description": "Every unlocked first-section element boosts the pace of the remaining first-section unlocks.",
  "currency_id": "ele_Li",
  "tier": 1,
  "base_cost": 140,
  "cost_mode": "additive_power",
  "cost_scaling": 1.45,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "unlocked_early_chain_bonus",
  "effect_amount": 0.015
}
```

## 57. Particle Alignment

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Improves the usefulness of automation right when it first matters by making auto-smash better on the opening section.

```json
{
  "id": "particle_alignment",
  "name": "Particle Alignment",
  "description": "Auto smashing is faster while the selected element is in the first section.",
  "currency_id": "ele_Li",
  "tier": 1,
  "base_cost": 180,
  "cost_mode": "additive_power",
  "cost_scaling": 1.45,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "first_section_auto_speed_bonus",
  "effect_amount": 0.03
}
```

## 58. Manual Crit Primer

Scores: Relevance 4 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Extends crit-style excitement into the active opening loop so manual play has a second payoff vector beyond base output.

```json
{
  "id": "manual_crit_primer",
  "name": "Manual Crit Primer",
  "description": "Manual smashes gain a small critical chance in the early game.",
  "currency_id": "ele_Li",
  "tier": 1,
  "base_cost": 220,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "critical_manual_smash",
  "effect_amount": 0.02
}
```

## 59. Gentle Fission

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Introduces a lighter early version of fission logic so the mechanic starts teaching itself before the midgame.

```json
{
  "id": "gentle_fission",
  "name": "Gentle Fission",
  "description": "Fission is more likely to trigger for early produced elements.",
  "currency_id": "ele_Be",
  "tier": 1,
  "base_cost": 280,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "early_fission_bonus",
  "effect_amount": 0.02
}
```

## 60. Counter Surge

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 3

Makes each new discovery feel more rewarding by attaching a first-time burst when an element becomes visible in the counter.

```json
{
  "id": "counter_surge",
  "name": "Counter Surge",
  "description": "Discovering a new counter-visible element grants a burst of related production.",
  "currency_id": "ele_Be",
  "tier": 1,
  "base_cost": 340,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "first_discovery_burst",
  "effect_amount": 1.0
}
```

## 61. Dust Starter Kit

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Makes the first few Dust conversions feel generous enough that players actually learn and use the system early.

```json
{
  "id": "dust_starter_kit",
  "name": "Dust Starter Kit",
  "description": "The first Dust conversions gain bonus efficiency.",
  "currency_id": "ele_C",
  "tier": 1,
  "base_cost": 450,
  "cost_mode": "additive_power",
  "cost_scaling": 1.45,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "first_dust_conversion_bonus",
  "effect_amount": 0.04
}
```

## 62. Soft Conversion Matrix

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Reduces the pain of using first-shell elements in Dust recipes, which lowers the hesitation to experiment.

```json
{
  "id": "soft_conversion_matrix",
  "name": "Soft Conversion Matrix",
  "description": "Dust conversion refunds more of the first-section elements it consumes.",
  "currency_id": "dust",
  "tier": 1,
  "base_cost": 40,
  "cost_mode": "additive_power",
  "cost_scaling": 1.45,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "early_dust_refund",
  "effect_amount": 0.02
}
```

## 63. Balanced Batch Bonus

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Trains players to build better Dust recipes early by rewarding small balanced first-shell batches.

```json
{
  "id": "balanced_batch_bonus",
  "name": "Balanced Batch Bonus",
  "description": "Balanced first-section Dust recipes gain extra payout.",
  "currency_id": "dust",
  "tier": 1,
  "base_cost": 65,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "early_dust_diversity_bonus",
  "effect_amount": 0.03
}
```

## 64. Hydrogen Reserve

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 3

Makes holding a healthy Hydrogen bank tactically useful instead of feeling like pure overflow.

```json
{
  "id": "hydrogen_reserve",
  "name": "Hydrogen Reserve",
  "description": "Stored Hydrogen improves early unlock efficiency.",
  "currency_id": "ele_H",
  "tier": 1,
  "base_cost": 55,
  "cost_mode": "additive_power",
  "cost_scaling": 1.4,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "stored_hydrogen_bonus",
  "effect_amount": 0.02
}
```

## 65. Helium Cushion

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 3

Creates a second early stockpiling decision by letting extra Helium reduce early progression volatility.

```json
{
  "id": "helium_cushion",
  "name": "Helium Cushion",
  "description": "Stored Helium increases the effectiveness of early unlock and starter-grant effects.",
  "currency_id": "ele_He",
  "tier": 1,
  "base_cost": 120,
  "cost_mode": "additive_power",
  "cost_scaling": 1.45,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "stored_helium_bonus",
  "effect_amount": 0.02
}
```

## 66. Lithium Spark

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Gives upgrade purchasing a tempo reward so the early menu loop feels more dynamic.

```json
{
  "id": "lithium_spark",
  "name": "Lithium Spark",
  "description": "Buying a Tier 1 upgrade grants a short burst of atomic production speed.",
  "currency_id": "ele_Li",
  "tier": 1,
  "base_cost": 260,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "upgrade_purchase_burst",
  "effect_amount": 0.05
}
```

## 67. Carbon Thread

Scores: Relevance 4 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Makes Carbon the first element that meaningfully shapes recipe quality instead of only unlock progress.

```json
{
  "id": "carbon_thread",
  "name": "Carbon Thread",
  "description": "Dust recipes that include Carbon gain extra material quality.",
  "currency_id": "ele_C",
  "tier": 1,
  "base_cost": 520,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "carbon_dust_quality_bonus",
  "effect_amount": 0.03
}
```

## 68. Oxygen Lift

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Creates a simple but readable early chemistry pairing by making Oxygen-based recipes better launch points into Dust.

```json
{
  "id": "oxygen_lift",
  "name": "Oxygen Lift",
  "description": "Dust recipes that include Oxygen improve their overall payout.",
  "currency_id": "ele_O",
  "tier": 1,
  "base_cost": 800,
  "cost_mode": "additive_power",
  "cost_scaling": 1.55,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "oxygen_recipe_bonus",
  "effect_amount": 0.04
}
```

## 69. Neon Preview

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 1 | Scalability 4

Improves the end of the opening arc by previewing what the player should prepare for once the second section opens.

```json
{
  "id": "neon_preview",
  "name": "Neon Preview",
  "description": "Reveals second-section requirements and planning hints before the first shell is complete.",
  "currency_id": "ele_Ne",
  "tier": 1,
  "base_cost": 1200,
  "cost_mode": "additive_power",
  "cost_scaling": 1.0,
  "max_level": 1,
  "current_level": 0,
  "effect_type": "second_section_preview",
  "effect_amount": 1.0
}
```

## 70. Unlock Windfall

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Rewards each early unlock with a short burst of forward momentum so progression feels less stop-start.

```json
{
  "id": "unlock_windfall",
  "name": "Unlock Windfall",
  "description": "Unlocking a new element grants a small burst of progress toward the next one.",
  "currency_id": "ele_B",
  "tier": 1,
  "base_cost": 420,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "unlock_completion_windfall",
  "effect_amount": 0.05
}
```

## Best Of The New 20

If you want the highest-value early pass from this supplemental batch, start with:

1. `guided_unlocks`
2. `starter_cache`
3. `proton_primer`
4. `dust_starter_kit`
5. `neon_preview`

## Additional Gain, Smasher, And Fission Upgrades

These 10 supplements are focused only on raw element gain, smasher performance, and fission depth.

## 71. Resonant Yield

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 5

Adds a clean throughput boost by letting successful smashes produce extra copies of their output.

```json
{
  "id": "resonant_yield",
  "name": "Resonant Yield",
  "description": "Smashes have a chance to create extra copies of the produced element.",
  "currency_id": "ele_Li",
  "tier": 1,
  "base_cost": 10000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "bonus_element_output",
  "effect_amount": 0.05
}
```

## 72. Smasher Overdrive

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Pushes the Particle Smasher line harder by giving automation a second dedicated speed amplifier.

```json
{
  "id": "smasher_overdrive",
  "name": "Smasher Overdrive",
  "description": "Particle Smasher actions resolve faster than the base automation curve.",
  "currency_id": "ele_He",
  "tier": 1,
  "base_cost": 2500,
  "cost_mode": "additive_power",
  "cost_scaling": 1.55,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "auto_smash_haste_bonus",
  "effect_amount": 0.03
}
```

## 73. Precision Smash Chamber

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Turns both manual and automated hits into higher-quality element gain by improving the output of each smash.

```json
{
  "id": "precision_smash_chamber",
  "name": "Precision Smash Chamber",
  "description": "Successful smashes have an increased chance to produce amplified element output.",
  "currency_id": "ele_Li",
  "tier": 2,
  "base_cost": 4500,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "smash_output_multiplier",
  "effect_amount": 0.08
}
```

## 74. Fission Echo

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 3 | Scalability 4

When a split happens, this gives each fissioned product a chance to echo once more for higher total gain.

```json
{
  "id": "fission_echo",
  "name": "Fission Echo",
  "description": "Fission products can duplicate themselves once after a successful split.",
  "currency_id": "ele_Be",
  "tier": 2,
  "base_cost": 7000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.65,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "fission_product_echo",
  "effect_amount": 0.06
}
```

## 75. Split Harmonizer

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 3 | Scalability 5

Makes fission more rewarding as the table expands by scaling split consistency with the number of valid unlocked partitions.

```json
{
  "id": "split_harmonizer",
  "name": "Split Harmonizer",
  "description": "Fission becomes more reliable as more valid unlocked split patterns exist.",
  "currency_id": "ele_C",
  "tier": 2,
  "base_cost": 9000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.7,
  "max_level": 12,
  "current_level": 0,
  "effect_type": "fission_partition_bonus",
  "effect_amount": 0.05
}
```

## 76. Element Gain Relay

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Builds short gain chains by giving newly produced elements a chance to rebate part of the parent step.

```json
{
  "id": "element_gain_relay",
  "name": "Element Gain Relay",
  "description": "Gaining an element can also refund part of the previous element in the chain.",
  "currency_id": "ele_N",
  "tier": 2,
  "base_cost": 11000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.65,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "parent_element_rebate",
  "effect_amount": 0.04
}
```

## 77. Critical Smasher Lattice

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 3 | Scalability 4

Redirects crit energy into more reliable element gain instead of leaving the benefit mostly cosmetic.

```json
{
  "id": "critical_smasher_lattice",
  "name": "Critical Smasher Lattice",
  "description": "Critical smashes convert more often into direct bonus element gain.",
  "currency_id": "ele_O",
  "tier": 2,
  "base_cost": 14000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.7,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "critical_element_gain",
  "effect_amount": 0.05
}
```

## 78. Triple Impact Chamber

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 3 | Scalability 4

Adds a satisfying burst rhythm to automation by turning periodic smasher hits into triple impacts.

```json
{
  "id": "triple_impact_chamber",
  "name": "Triple Impact Chamber",
  "description": "Periodic auto-smash actions resolve as triple-hit bursts.",
  "currency_id": "dust",
  "tier": 3,
  "base_cost": 22000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.75,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "burst_auto_smash",
  "effect_amount": 1.0
}
```

## 79. Clean Split Lattice

Scores: Relevance 4 | Uniqueness 5 | Implementation Time 4 | Scalability 5

Biases fission toward better unlocked outputs so late-game splitting feels strategic instead of purely random.

```json
{
  "id": "clean_split_lattice",
  "name": "Clean Split Lattice",
  "description": "Fission prefers higher-value valid split outcomes when multiple partitions exist.",
  "currency_id": "ele_Fe",
  "tier": 3,
  "base_cost": 40000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.8,
  "max_level": 10,
  "current_level": 0,
  "effect_type": "fission_quality_bias",
  "effect_amount": 0.1
}
```

## 80. Atomic Harvest Grid

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 3 | Scalability 5

Converts steady smasher uptime into a broader element gain multiplier that scales with section progression.

```json
{
  "id": "atomic_harvest_grid",
  "name": "Atomic Harvest Grid",
  "description": "Element gain improves while the smasher stays active and more sections are unlocked.",
  "currency_id": "dust",
  "tier": 3,
  "base_cost": 60000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.8,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "smasher_uptime_gain_bonus",
  "effect_amount": 0.04
}
```

## Additional Simple Predust Upgrades

## 81. Smasher Bearings

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 1 | Scalability 5

Makes the Particle Smasher cycle a little faster without changing the underlying automation loop.

```json
{
  "id": "smasher_bearings",
  "name": "Smasher Bearings",
  "description": "Particle Smasher actions resolve faster.",
  "currency_id": "ele_N",
  "tier": 1,
  "base_cost": 300,
  "cost_mode": "additive_power",
  "cost_scaling": 1.45,
  "max_level": 25,
  "current_level": 0,
  "effect_type": "auto_smash_speed_bonus",
  "effect_amount": 0.04
}
```

## 82. Double Hit

Scores: Relevance 4 | Uniqueness 3 | Implementation Time 2 | Scalability 4

Gives manual smashing a simple output bump so early active play stays competitive with automation.

```json
{
  "id": "double_hit",
  "name": "Double Hit",
  "description": "Manual smashes have a chance to create one extra copy of their output.",
  "currency_id": "ele_Li",
  "tier": 1,
  "base_cost": 8000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "manual_bonus_output",
  "effect_amount": 0.01
}
```

## 83. Critical Routing

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 1 | Scalability 5

Expands the value of the existing crit system by simply raising how often critical smashes happen.

```json
{
  "id": "critical_routing",
  "name": "Critical Routing",
  "description": "Critical smashes trigger more often.",
  "currency_id": "ele_B",
  "tier": 1,
  "base_cost": 10000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "critical_auto_smash",
  "effect_amount": 1.0
}
```

## 84. Critical Payload

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Improves crit results directly by making each smash worth more when it lands.

```json
{
  "id": "critical_payload",
  "name": "Critical Payload",
  "description": "Critical Smashes create more bonus output.",
  "currency_id": "ele_O",
  "tier": 1,
  "base_cost": 2500,
  "cost_mode": "additive_power",
  "cost_scaling": 1.55,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "critical_spawn_bonus",
  "effect_amount": 1.0
}
```

## 85. Fission Calibration

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 1 | Scalability 5

Raises fission consistency in the most direct way possible by increasing the existing split chance.

```json
{
  "id": "fission_calibration",
  "name": "Fission Calibration",
  "description": "Fission triggers more often.",
  "currency_id": "ele_F",
  "tier": 1,
  "base_cost": 1800,
  "cost_mode": "additive_power",
  "cost_scaling": 1.5,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "fission_split",
  "effect_amount": 0.75
}
```

## 86. Fission Efficiency

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Adds a small gain bump whenever fission happens so the split path feels better without changing its core rules.

```json
{
  "id": "fission_efficiency",
  "name": "Fission Efficiency",
  "description": "Fission results have a chance to duplicate one of their outputs.",
  "currency_id": "ele_Be",
  "tier": 1,
  "base_cost": 4000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.55,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "fission_bonus_output",
  "effect_amount": 0.02
}
```

## 87. Unlock Discount Matrix

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 1 | Scalability 5

Lowers the cost of unlocking new elements, giving early progression more room to breathe.

```json
{
  "id": "unlock_discount_matrix",
  "name": "Unlock Discount Matrix",
  "description": "Element unlock costs are reduced.",
  "currency_id": "ele_Li",
  "tier": 1,
  "base_cost": 3000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.55,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "unlock_cost_discount",
  "effect_amount": 0.03
}
```

## 88. Section Subsidy

Scores: Relevance 4 | Uniqueness 3 | Implementation Time 1 | Scalability 4

Reduces the cost of opening the next element section without introducing any new step to the flow.

```json
{
  "id": "section_subsidy",
  "name": "Section Subsidy",
  "description": "Element section unlock costs are reduced.",
  "currency_id": "ele_B",
  "tier": 1,
  "base_cost": 5000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "section_unlock_discount",
  "effect_amount": 0.04
}
```

## 89. Light Chain Output

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Boosts gain for the opening stretch of elements so the first few sections move more cleanly.

```json
{
  "id": "light_chain_output",
  "name": "Light Chain Output",
  "description": "Elements in the early chain produce extra output.",
  "currency_id": "ele_C",
  "tier": 1,
  "base_cost": 7000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.55,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "early_element_gain_bonus",
  "effect_amount": 0.05
}
```

## 90. Mid Chain Output

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Extends the same simple gain approach into the midgame elements where pacing often starts to sag.

```json
{
  "id": "mid_chain_output",
  "name": "Mid Chain Output",
  "description": "Mid-chain elements produce extra output.",
  "currency_id": "ele_N",
  "tier": 2,
  "base_cost": 10000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "mid_element_gain_bonus",
  "effect_amount": 0.05
}
```

## 91. Heavy Chain Primer

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Applies a straightforward gain multiplier to the heavier predust elements so later unlocking does not feel flat.

```json
{
  "id": "heavy_chain_primer",
  "name": "Heavy Chain Primer",
  "description": "Later predust elements produce extra output.",
  "currency_id": "ele_Ne",
  "tier": 2,
  "base_cost": 13000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.62,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "late_element_gain_bonus",
  "effect_amount": 0.05
}
```

## 92. Auto Smasher Lubricant

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 1 | Scalability 5

Adds another small auto-smash speed source for players who want more idle throughput without extra systems.

```json
{
  "id": "auto_smasher_lubricant",
  "name": "Auto Smasher Lubricant",
  "description": "Auto-smash speed increases further.",
  "currency_id": "ele_O",
  "tier": 2,
  "base_cost": 15000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "auto_smash_speed_bonus",
  "effect_amount": 0.03
}
```

## 93. Manual Smasher Grip

Scores: Relevance 4 | Uniqueness 3 | Implementation Time 1 | Scalability 4

Improves manual smashing throughput with a simple flat boost instead of adding combo or timing rules.

```json
{
  "id": "manual_smasher_grip",
  "name": "Manual Smasher Grip",
  "description": "Manual smashes produce more output.",
  "currency_id": "ele_F",
  "tier": 2,
  "base_cost": 9000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.55,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "manual_smash_gain_bonus",
  "effect_amount": 0.04
}
```

## 94. Selected Element Gain

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Rewards focusing on one selected atom by giving that currently active element a small output multiplier.

```json
{
  "id": "selected_element_gain",
  "name": "Selected Element Gain",
  "description": "The currently selected element produces more output when smashed.",
  "currency_id": "ele_Ne",
  "tier": 2,
  "base_cost": 12000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "selected_element_gain_bonus",
  "effect_amount": 0.05
}
```

## 95. Produced Element Gain

Scores: Relevance 5 | Uniqueness 3 | Implementation Time 1 | Scalability 5

Applies a broad gain multiplier to produced elements, making it one of the cleanest universal predust upgrades.

```json
{
  "id": "produced_element_gain",
  "name": "Produced Element Gain",
  "description": "Produced elements gain a flat output bonus.",
  "currency_id": "ele_Na",
  "tier": 2,
  "base_cost": 18000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.62,
  "max_level": 20,
  "current_level": 0,
  "effect_type": "global_element_gain_bonus",
  "effect_amount": 0.04
}
```

## 96. Unlock Rebate

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Softens progression cost spikes by returning a small amount of spent currency after each element unlock.

```json
{
  "id": "unlock_rebate",
  "name": "Unlock Rebate",
  "description": "Unlocking an element refunds part of its cost.",
  "currency_id": "ele_Mg",
  "tier": 2,
  "base_cost": 20000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.65,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "unlock_cost_rebate",
  "effect_amount": 0.08
}
```

## 97. Section Relay

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Lets newly opened sections start stronger by attaching a simple gain bonus to the latest visible section.

```json
{
  "id": "section_relay",
  "name": "Section Relay",
  "description": "Elements in the newest unlocked section gain extra output.",
  "currency_id": "ele_Al",
  "tier": 2,
  "base_cost": 24000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.65,
  "max_level": 12,
  "current_level": 0,
  "effect_type": "latest_section_gain_bonus",
  "effect_amount": 0.06
}
```

## 98. Split Stability

Scores: Relevance 4 | Uniqueness 4 | Implementation Time 2 | Scalability 4

Makes fission outcomes a bit more rewarding without changing the two-part split structure.

```json
{
  "id": "split_stability",
  "name": "Split Stability",
  "description": "Fission outputs gain a small flat yield bonus.",
  "currency_id": "ele_Si",
  "tier": 2,
  "base_cost": 26000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.65,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "fission_gain_bonus",
  "effect_amount": 0.05
}
```

## 99. Proton Recovery

Scores: Relevance 4 | Uniqueness 3 | Implementation Time 1 | Scalability 4

Turns the crit lane into a steadier early resource source by directly increasing bonus Proton gain.

```json
{
  "id": "proton_recovery",
  "name": "Proton Recovery",
  "description": "Critical smashes generate additional bonus Protons.",
  "currency_id": "ele_P",
  "tier": 2,
  "base_cost": 16000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.6,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "critical_proton_bonus",
  "effect_amount": 1.0
}
```

## 100. Chain Momentum

Scores: Relevance 5 | Uniqueness 4 | Implementation Time 2 | Scalability 5

Adds a broad but simple predust pacing bonus by increasing output when progressing forward through the element chain.

```json
{
  "id": "chain_momentum",
  "name": "Chain Momentum",
  "description": "Higher-index unlocked elements gain a modest output bonus.",
  "currency_id": "ele_S",
  "tier": 2,
  "base_cost": 30000,
  "cost_mode": "additive_power",
  "cost_scaling": 1.68,
  "max_level": 15,
  "current_level": 0,
  "effect_type": "index_scaled_gain_bonus",
  "effect_amount": 0.03
}
```
