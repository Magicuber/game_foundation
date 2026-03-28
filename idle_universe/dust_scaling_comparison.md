# Dust Scaling Comparison

This revision assumes Dust will eventually support both:

- manual conversion from the `Elements` menu
- automated conversion through a future system that periodically consumes configured element batches

To stay automation-friendly, each method below is described as a deterministic batch-value formula that can be reused by both manual and auto-conversion flows.

## Concept Review

You clarified an important constraint: Dust should **not** overproduce in the early game.

That changes the target behavior significantly. A good Dust formula now needs to:

- stay below raw input mass early
- become more rewarding later as element tiers and batch quality improve
- avoid exploding too hard once automation unlocks

Because of that, the previous "Exponential Early Ramp" version was too generous for your current design goal. Method 1 has now been revised into an **Exponential Late Ramp** model: it starts below mass with an `early_scalar`, then grows exponentially with higher-tier batches and eventually overtakes raw mass later in progression.

## Comparison Table

| Category | Method 1: Exponential Late Ramp | Method 2: Diminishing Quantity, Stronger Variety | Method 3: Set-Collection / Entropy Bonus |
| --- | --- | --- | --- |
| Core Idea | Dust starts below raw input mass, then ramps upward exponentially as higher-tier elements enter the batch. | Dust scales with weighted mass after applying diminishing returns to each element stack, then gets a stronger diversity multiplier. | Dust scales from a blend of total mass, highest-tier element used, and explicit rewards for using more unique element types. |
| Automation-Ready Version | Auto-conversion repeatedly evaluates the configured batch and awards Dust using an exponential tier multiplier that begins conservative and grows later. | Auto-conversion repeatedly evaluates the configured batch, but diminishing returns prevent giant stockpiles from turning into runaway Dust. | Auto-conversion repeatedly evaluates the configured batch and strongly rewards recipe quality, making the auto-loadout itself part of the strategy. |
| Formula | `Dust = floor(M * early_scalar * growth_base^(highest_weight / pivot_weight) * (1 + diversity_bonus * (D - 1)))` | `Dust = floor((sum(q_e^0.5 * w_e)) * (1 + 0.20 * (D - 1)))` | `Dust = floor(M * 0.35 + highest_weight * D^2 + set_bonus)` |
| Default Tuning Example | `early_scalar = 0.55`, `growth_base = 1.6`, `pivot_weight = 30`, `diversity_bonus = 0.05` | `quantity_exponent = 0.5`, `diversity_bonus = 0.20` | `mass_scalar = 0.35`, `diversity_exponent = 2`, `set_bonus = +50 at 3, 5, and 8 types` |
| Early-Game Goal Fit | Good. Specifically tuned to stay below raw mass before higher-tier batches show up. | Good. Naturally conservative in the early game. | Fair. Can still overshoot early if the bonus structure is too generous. |
| Suggested Auto Conversion Flow | Consume a fixed configured batch every automation cycle. Early batches stay tame, while better late batches scale harder. | Consume a fixed configured batch every automation cycle. | Consume a fixed configured batch every automation cycle. |
| Manual Experience | Easy to understand at a high level: early batches are modest, later batches become noticeably better. | Understandable, but players benefit from a live preview because value is not linear. | Most rewarding for theory-crafting, but hardest to estimate without a preview. |
| Automated Experience | Better than an early-overpay exponential, but still likely to need automation caps or batch limits late. | Stable over time because larger piles do not scale too explosively under automation. | Feels like tuning a machine recipe, but could become solvable into one dominant batch pattern. |
| Amount Scaling | Strong. Total mass matters a lot, but the biggest gains come from better-tier inputs over time. | Moderate. More quantity helps, but each additional stack contributes less than the last. | Moderate. Quantity matters, but it is only one part of the final score. |
| Heavy Element Scaling | Very strong. Higher-tier inputs are what push the exponential ramp upward. | Strong. Heavy elements remain very valuable even after diminishing returns. | Very strong. Heavy elements matter through both total mass and the highest-weight bonus. |
| Diversity Scaling | Mild to moderate. Diversity helps, but tier is the main growth driver. | Strong. Variety is a major multiplier, so mixed batches feel rewarding. | Very strong. Variety is one of the main drivers of Dust value. |
| Automation Stability | Medium. Safer than the old early-overpay version, but still riskier than Method 2. | High. Best at preventing automation from flattening the rest of progression. | Medium. Strategic and interesting, but more likely to need retuning once automation enters the game. |
| Best Auto Behavior | Best if Dust should start conservative, then become a stronger auto-conversion reward later. | Best if automation should stay balanced and require occasional optimization. | Best if automation should feel like building an efficient conversion recipe. |
| UI Preview Needs | Medium. Players will benefit from seeing when a batch starts crossing from "sub-mass" into "above-mass" value. | Medium. Players benefit from seeing how diminishing returns affect output. | High. Players will likely need a full predicted Dust preview and maybe recipe hints. |
| Player Readability | Medium to high. Easier than Method 3, and conceptually cleaner than the previous early-overpay version. | Medium. Players understand the idea, but the square-root behavior is less obvious. | Medium to low. Players may need UI previews because the result comes from several moving parts. |
| Strategy Depth | Medium. Players are incentivized to bring in better-tier ingredients rather than just more low-tier matter. | Medium. Players balance stack size versus variety more meaningfully. | High. Players are encouraged to optimize batch composition for bonus value. |
| Balance Risk | Medium to high. Safer than early overproduction, but still capable of spiking once high-tier automation begins. | Lowest risk. Diminishing returns naturally slow down stockpile abuse in both manual and auto modes. | Medium to high risk. Can produce strong best recipe patterns if not tuned carefully. |
| Best Use Case | Best if Dust should begin restrained and then grow into a more rewarding late-progress conversion system. | Best for a long-term prestige/meta currency that needs stable balance. | Best if Dust conversion is meant to be a strategic mini-system on its own. |
| Early Game Example | `100 H + 50 He` -> `119 Dust` | `100 H + 50 He` -> `28 Dust` | `100 H + 50 He` -> `78 Dust` |
| Mid Game Example | `200 H + 150 O + 50 Ne` -> `1345 Dust` | `200 H + 150 O + 50 Ne` -> `255 Dust` | `200 H + 150 O + 50 Ne` -> `805 Dust` |
| Late Game Example | `300 H + 200 C + 150 Fe + 25 Au` -> `16,107 Dust` | `300 H + 200 C + 150 Fe + 25 Au` -> `1304 Dust` | `300 H + 200 C + 150 Fe + 25 Au` -> `3895 Dust` |
| Automation Example Over Time | If auto-conversion runs once per minute on `200 H + 150 O + 50 Ne`, it yields `1345 Dust/min`. After 10 minutes, that is `13,450 Dust` if supply holds. | If auto-conversion runs once per minute on `200 H + 150 O + 50 Ne`, it yields `255 Dust/min`. After 10 minutes, that is `2,550 Dust` if supply holds. | If auto-conversion runs once per minute on `200 H + 150 O + 50 Ne`, it yields `805 Dust/min`. After 10 minutes, that is `8,050 Dust` if supply holds. |
| Main Advantage | It respects the "don't overproduce early" rule while still giving a clear sense of improving Dust efficiency later. | Best balance profile while still rewarding mixed and higher-tier batches. | Most interesting and expressive for players who like optimization. |
| Main Drawback | Still needs careful automation tuning once the player starts feeding high-tier ingredients into it. | Harder to explain cleanly without a preview readout in the UI. | Hardest to balance and most likely to need iteration after playtesting. |
| Recommended If | You want Dust to start conservative, then feel more powerful later without immediately overpaying. | You want Dust to stay meaningful over a long progression arc, including after automation. | You want the Elements menu and later automation systems to become a real batch-building puzzle. |

## Shared Definitions

- `q_e`: quantity of element `e` consumed
- `w_e`: atomic weight proxy for element `e` based on its `index`
- `D`: number of different element types used in the batch
- `M = sum(q_e * w_e)`
- `highest_weight`: highest atomic weight among the elements in the batch
- `pivot_weight`: the tier scale that controls how quickly the exponential ramp grows
- `set_bonus`: fixed bonus awarded when the batch reaches certain diversity thresholds
- Proton is excluded from Dust conversion

## Revised Findings

- Method 1 now follows the updated design goal much better: it no longer overpays early, but it still creates a clear sense of Dust conversion improving later.
- Method 2 remains the safest long-term economy option, especially once automation is introduced.
- Method 3 remains the most strategic option, but it is still better suited for a recipe-optimization system than a first implementation.

## Method 1 Breakpoints

Using the current Method 1 defaults:

- `early_scalar = 0.55`
- `growth_base = 1.6`
- `pivot_weight = 30`
- `diversity_bonus = 0.05`

The effective multiplier over raw input mass is:

`Dust / Mass = 0.55 * 1.6^(highest_weight / 30) * (1 + 0.05 * (D - 1))`

This means Method 1 should stay conservative in the early game, cross above parity around the mid game, and become clearly profitable later without becoming purely runaway on its own.

| Progression Point | Example Highest Weight | Example Diversity (`D`) | Approx. Dust / Mass | What It Means |
| --- | --- | --- | --- | --- |
| Early section cap | `10` | `3` | `0.71x` | Dust remains below raw mass and feels restrained. |
| Early-mid transition | `30` | `4` | `1.01x` | Dust reaches near-parity around the first major tier pivot. |
| Mid game | `54` | `6` | `1.58x` | Dust begins to feel meaningfully more rewarding than raw mass. |
| Late game | `79` | `8` | `2.33x` | High-tier batches give strong returns without being absurd yet. |
| Endgame cap | `118` | `10` | `3.79x` | Endgame Dust is several times input mass, but still mostly driven by throughput. |

Under this tuning, endgame numbers should get large mainly because the player is feeding very large batches through the system repeatedly, not because the multiplier itself is exploding uncontrollably. In practice, that suggests:

- early Dust should stay comfortably below raw input mass
- mid game Dust should hover around parity to modest profit
- late and endgame Dust should likely land in the `2x` to `4x` mass range for strong batches
- total Dust per minute will mostly be determined by automation speed and batch size

## Recommendation With Automation In Mind

If the immediate goal is "Dust should not overproduce early," then Methods 1 and 2 are now the strongest candidates.

- choose Method 1 if you want a clearer feeling of late-game Dust acceleration
- choose Method 2 if you want the most reliable long-term automation balance

At this point, Method 2 still looks like the safest production candidate, but the revised Method 1 is now much closer to your updated design target than the previous version was.
