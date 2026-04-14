# TODO

[Back to Project Documentation](./README.md)

## Unimplemented systems

- `Shop` inventory and purchase flow. Current UI says inventory is not implemented yet.
- `Factory` menu and system. Current panel is placeholder only.
- `Collider` menu and system. Current panel is placeholder only.
- Future `Planet` branches beyond Planet A and Planet B.
- Future moon upgrade content beyond placeholder slots in `planet_menu.json`.
- Additional blessing content beyond placeholder entries.
- Future prestige nodes beyond current placeholder / early content.
- Future oblation recipes beyond current implemented recipes.

## UI and content gaps

- Replace placeholder panel text for `Shop`, `Factory`, `Collider` once real systems exist.
- Add richer world-view art / interactions for later planets.
- Add icon / preview assets for future planets and moon upgrades.
- Add final copy for stats screens once placeholder systems land.

## Data / state follow-ups

- Confirm every placeholder blessing, moon upgrade, and milestone has a documented unlock plan.
- Decide whether placeholder content should remain visible in UI or be hidden until activated.
- Add explicit docs for any new `effect_type` values before they ship.

## Workflow notes

- Keep new content data-driven when possible.
- Add regression tests whenever a new manager or save field lands.
- Update docs index whenever a new system or placeholder family is added.
- After big loader refactors, run dead-import / dead-wrapper scan before commit.

## Open refactor follow-up

- If `GameLoader::_ready()` grows again, split boot wiring into smaller helper instead of re-expanding loader.
- Keep `game_loader.gd` cleanup limited to verified dead code; do not prune imports by assumption.

## Related docs

- [Development Notes](./development_notes.md)
- [Change Log](./change_log.md)
- [Balancing](./Balancing.md)
- [Back to docs index](./README.md)