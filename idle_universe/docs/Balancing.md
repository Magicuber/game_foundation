# Balancing

[Back to Project Documentation](./README.md)

## Purpose

This file groups values that likely need playtest tuning.
Many are already wired in code, but still deserve balance passes before content expansion.

## High-priority tuning groups

### Blessing economy

- `BLESSING_COST_QUADRATIC_A = 10.0`
- `BLESSING_COST_QUADRATIC_B = 400.0`
- `BLESSING_COST_QUADRATIC_C = 1600.0`

Why: blessing gain curve controls meta pacing. Small changes have large downstream effect on bonus stacking.

### Planet worker economy

- `PLANET_WORKER_BASE_COST = 1000.0`
- `PLANET_WORKER_COST_RATIO = 1.25`
- `PLANET_WORKER_COST_ROUND_TO = 25.0`
- `PLANET_XP_LEVEL_TWO_REQUIREMENT = 1500.0`
- `PLANET_XP_LEVEL_TWENTY_FIVE_REQUIREMENT = 10000000.0`
- `RESEARCH_POINTS_PER_PRODUCTION = 0.001`

Why: worker purchase cost, XP climb, and RP flow define whether Planet A/B feel meaningful or grindy.

### Dust conversion formula

- `BASE_SCALAR = 0.024`
- `QUANTITY_EXPONENT = 0.90`
- `DIVERSITY_EXPONENT = 0.55`
- `STABILITY_WEIGHT = 0.65`
- `TIER_WEIGHT = 0.35`
- `STABILITY_BY_INDEX` table

Why: dust is primary currency. If formula is too generous, it invalidates upgrades and planet purchases. If too stingy, pace dies.

### Upgrade costs and power

- `particle_smasher` base cost / scaling
- `critical_smasher_chance` and `critical_smasher_chance_2`
- `fission_1` and `fission_2`
- `elemental_resonance` step cost and level cap
- `critical_payload`, `resonant_yield`, `double_hit`, `smasher_bearings`

Why: upgrades control automation and output spikes. These are the main levers for idle snowball.

### Automation pacing

- `auto_smash_interval` from upgrade stack
- `auto_smash_spawn_count`
- manual smash throughput after crit / double-hit bonuses
- any future auto-target or queue-speed bonuses

Why: pacing decides whether idle loop feels active or spammy. These values also shape offline catch-up pressure.

### Smash variant chances

- Foil spawn chance
- Holographic spawn chance
- Polychrome spawn chance

Why: variants can create extreme output spikes. Need clear caps and progression curve.

### Fission and crit stacking

- Combined crit chance from upgrades + blessings
- Fission overflow behavior above 100%
- Manual double-hit and resonant yield rates

Why: stacked percentage systems can explode quickly. Need playtest validation around high-level stacking.

### Prestige rewards

- Prestige point rewards per milestone
- Prestige dust multiplier nodes
- Planet unlock rewards tied to milestones

Why: prestige must feel like a meaningful reset without skipping too much of the progression curve.

## Content values to watch

- Element unlock costs in `elements.json`
- Planet purchase costs in `planets.json`
- Moon upgrade RP costs in `planet_menu.json`
- Blessing rarity roll weights and display chances
- Oblation recipe reward values and multipliers

## Balance questions to answer in playtest

- Does Planet A reach level milestones at a satisfying pace?
- Do blessing bonuses feel rare enough to matter?
- Does dust conversion reward variety more than hoarding?
- Do upgrade costs keep automation purchases meaningful?
- Do placeholder systems create confusing UI pressure or healthy future-proofing?

## Suggested pass order

1. Blessings and dust conversion
2. Planet worker economy
3. Upgrade pacing and automation
4. Prestige reward size
5. Variant / crit stacking caps

## Related docs

- [Game Mechanics](./game_mechanics.md)
- [Dust Recipe Service](./dust_recipe_service.md)
- [Upgrades](./upgrades.md)
- [Planets](./planets.md)
- [Prestige Manager](./prestige_manager.md)
- [Back to docs index](./README.md)