# Dust Scaling Comparison

This revision replaces the older three-method comparison with the six formulas currently under consideration.

All six formulas are built around the same design requirements:

1. Dust can never exceed the elements consumed.
2. Variety must increase Dust output.
3. A 10-element batch with `1,000,000` of each element should land around the `100k` Dust range.
4. The formula must be non-linear.
5. The formula must be explainable to the player.

## Shared Terms

- `q_i`: amount of element `i` consumed
- `Q = Σ q_i`: total elements consumed
- `D`: number of distinct elements in the batch
- `a_i`: atomic number / element index of element `i`
- `A`: highest atomic number currently unlocked
- `avg_atomic = Σ(q_i * a_i) / Q`
- `q_min`: smallest non-zero selected element amount
- `s_i`: normalized stability score for element `i`, derived from binding energy per nucleon and scaled to `0..1`
- `t_i = sqrt(a_i / A)`: normalized tier score
- `T = 0.5 + 0.5 * sqrt(avg_atomic / A)`: simple tier bonus used by the first family of formulas
- `h_i = 0.65 * s_i + 0.35 * t_i`: hybrid material quality score used by the second family
- `avg_h = Σ(q_i * h_i) / Q`: weighted average hybrid quality

All six formulas use the same hard cap:

```text
Dust = min(Q, floor(raw_dust))
```

That cap is the final step and enforces the "never more Dust than elements consumed" rule.

## Benchmark Scenario

Unless otherwise stated, the benchmark used below is:

- first 10 real elements selected
- `1,000,000` of each
- `Q = 10,000,000`
- `D = 10`
- first-family tier factor `T ≈ 0.871`
- second-family average hybrid score `avg_h ≈ 0.60`

The benchmark numbers are approximate and intended for comparison, not final balance values.

## Formula Families

- Formulas 1-3 use element quantity, section tier, and variety only.
- Formulas 4-6 add normalized nuclear stability as part of the element quality score.

## Comparison Table

| Category | Formula 1: Saturating Efficiency | Formula 2: Power-Law Throughput | Formula 3: Matched Stack | Formula 4: Weighted Contribution Sum | Formula 5: Batch Power Hybrid | Formula 6: Matched Set Hybrid |
| --- | --- | --- | --- | --- | --- | --- |
| Core Idea | Total elements drive Dust, but efficiency saturates and variety adds a readable multiplier. | Treat the whole batch as a sublinear throughput curve with variety and tier layered on top. | Reward balanced multi-element batches by keying off the smallest stack and strong variety scaling. | Sum per-element contributions using a hybrid of stability and tier, then apply a variety bonus. | Evaluate the whole batch with sublinear total quantity, variety power scaling, and weighted hybrid quality. | Reward matched sets using the smallest stack, strong variety scaling, and hybrid element quality. |
| Formula | `raw_dust = Q * 0.011 * (Q / (Q + 5000))^(1/3) * (ln(1 + D) / ln(11)) * T` | `raw_dust = 0.023 * Q^0.90 * (1 + 0.16 * (D - 1)) * T` | `raw_dust = 0.00073 * q_min * D^2.2 * T` | `raw_dust = 0.15 * (1 + 0.12 * ln(1 + D)) * Σ(q_i^0.82 * h_i)` | `raw_dust = 0.024 * Q^0.90 * D^0.55 * avg_h` | `raw_dust = 0.063 * q_min^0.78 * D^1.75 * avg_h` |
| Main Non-Linearity | Saturating quantity term `((Q / (Q + 5000))^(1/3))` | Total quantity power term `Q^0.90` | Variety power `D^2.2` and dependence on `q_min` | Per-element diminishing returns `q_i^0.82` | Total quantity power `Q^0.90` and variety power `D^0.55` | Smallest-stack power `q_min^0.78` and variety power `D^1.75` |
| Variety Scaling | `ln(1 + D) / ln(11)` | `1 + 0.16 * (D - 1)` | `D^2.2` | `1 + 0.12 * ln(1 + D)` | `D^0.55` | `D^1.75` |
| Tier / Stability Input | Simple tier factor `T` | Simple tier factor `T` | Simple tier factor `T` | Per-element hybrid score `h_i = 0.65 * s_i + 0.35 * t_i` | Weighted batch average `avg_h` | Average hybrid score across selected elements |
| Benchmark Output | `~96k Dust` | `~97k Dust` | `~101k Dust` | `~96k Dust` | `~102k Dust` | `~101k Dust` |
| Player-Facing Display | `Dust = Total Elements × Quantity Efficiency × Variety Bonus × Tier Bonus` | `Dust = Total Elements^0.90 × Variety Bonus × Tier Bonus` | `Dust = Smallest Stack × Variety Bonus × Tier Bonus` | `Dust = Sum of Element Contributions × Variety Bonus` | `Dust = Total Elements^0.90 × Variety Bonus × Material Quality` | `Dust = Matched Stack^0.78 × Variety Bonus × Material Quality` |
| User Readability | High | Medium | High | Medium-High | Medium | High |
| Recipe Sensitivity | Medium | Low-Medium | High | Medium-High | Medium | High |
| Automation Stability | High | High | Medium | High | High | Medium |
| Main Strength | Best general-purpose formula if the player should understand why a batch is good. | Easiest to implement and tune with a small number of parameters. | Strong identity if Dust should reward well-balanced sets. | Best way to make individual elements matter while still keeping the formula explainable. | Smoothest hybrid option for automation and balancing. | Strongest "recipe-building" hybrid formula. |
| Main Risk | The quantity saturation term may feel opaque without a preview. | Can feel too abstract because element-specific contributions are hidden inside the batch average. | Punishes uneven batches hard. | Slightly more computationally involved and harder to explain than Formula 1. | Less expressive per element than Formula 4. | Can frustrate players if one lagging element collapses the whole batch. |
| Best Fit | Default candidate if the system should be readable and robust. | Best if simplicity and stable automation behavior matter most. | Best if Dust should feel like assembling a matched set. | Best if Dust should reflect both recipe quality and real element identity. | Best hybrid formula for long-term balance and automation. | Best hybrid formula if Dust conversion should become a deeper optimization puzzle. |

## Requirement Check

| Requirement | Formula 1 | Formula 2 | Formula 3 | Formula 4 | Formula 5 | Formula 6 |
| --- | --- | --- | --- | --- | --- | --- |
| Never exceed input | Yes, by final cap | Yes, by final cap | Yes, by final cap | Yes, by final cap | Yes, by final cap | Yes, by final cap |
| Variety increases Dust | Yes | Yes | Yes | Yes | Yes | Yes |
| Around `100k` on `10 x 1,000,000` | Yes, `~96k` | Yes, `~97k` | Yes, `~101k` | Yes, `~96k` | Yes, `~102k` | Yes, `~101k` |
| Non-linear | Yes | Yes | Yes | Yes | Yes | Yes |
| Can be shown to player | Yes | Yes | Yes | Yes | Yes | Yes |

## Stability Data Note

Formulas 4-6 require a per-element stability table. A gameplay-ready representation would look like:

```json
{
  "ele_H":  { "isotope": "1H",  "be_per_nucleon_mev": 0.000, "stability_norm": 0.000 },
  "ele_He": { "isotope": "4He", "be_per_nucleon_mev": 7.074, "stability_norm": 0.804 },
  "ele_Li": { "isotope": "7Li", "be_per_nucleon_mev": 5.606, "stability_norm": 0.637 }
}
```

Representative first-section values discussed so far:

| Element | Example isotope | Approx. BE / nucleon (MeV) | `stability_norm` |
| --- | --- | ---: | ---: |
| H | `1H` | `0.000` | `0.000` |
| He | `4He` | `7.074` | `0.804` |
| Li | `7Li` | `5.606` | `0.637` |
| Be | `9Be` | `6.463` | `0.734` |
| B | `11B` | `6.928` | `0.787` |
| C | `12C` | `7.680` | `0.873` |
| N | `14N` | `7.476` | `0.850` |
| O | `16O` | `7.976` | `0.907` |
| F | `19F` | `7.780` | `0.884` |
| Ne | `20Ne` | `8.032` | `0.913` |

These stability values should be treated as tunable gameplay inputs until they are pulled from a finalized authoritative data pass.

## Recommendation

If Dust should stay understandable and easy to tune, start with **Formula 1: Saturating Efficiency**.

If Dust should incorporate real element identity and still remain stable under automation, start with **Formula 5: Batch Power Hybrid**.

If Dust should become a stronger recipe-building system, keep **Formula 3** or **Formula 6** in reserve for a later iteration.
