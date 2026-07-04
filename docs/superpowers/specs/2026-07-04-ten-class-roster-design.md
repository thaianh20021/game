# Ten Class Roster Design

## Scope

Expose all 10 GDD base classes as selectable run starters while keeping combat implementation limited to the current MVP systems. New classes receive stats, resource type, preferred weapons, two active metadata entries, two passive metadata entries, and an ultimate metadata entry.

## Behavior

`data/classes.json` becomes the source of truth for 10 classes: Blade Warden, Breaker, Nightblade, Bulwark, Arcanist, Ranger, Gunner, Soulbinder, Lightkeeper, and Tinkerer. The existing 3 classes keep their current active skill behavior. The 7 new classes can start a run with valid stats and a matching starter weapon, but their unique actives are metadata until their mechanics are implemented in later slices.

The class select UI changes from one horizontal row to a scrollable grid so 10 class buttons fit on the first screen. Element selection and start behavior stay unchanged.

## Testing

Add a smoke test that verifies 10 unique class records, required fields for every class, `Player.apply_class()` works for every class, and the class select UI contains a scrollable grid with one button per class.
