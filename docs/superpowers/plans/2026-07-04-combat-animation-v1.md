# Combat Animation V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add visual-only combat animation polish: slash, muzzle flash, dash ghost, and telegraph FX.

**Architecture:** Add `CombatFx` as a focused helper for transient Godot shape/tween effects. Existing gameplay classes call it only after already-valid events so damage math and state timing stay unchanged. Tests assert FX nodes spawn and clean up without needing unlicensed external assets.

**Tech Stack:** Godot 4.7, GDScript, existing 0x72 DungeonTilesetII sprites, headless smoke tests.

---

### Task 1: Combat FX Helper

**Files:**
- Create: `scripts/fx/combat_fx.gd`
- Test: `scripts/tests/combat_animation_smoke.gd`

- [ ] **Step 1: Write the failing test**

Add `scripts/tests/combat_animation_smoke.gd` with these checks:

```gdscript
extends SceneTree

const CombatFxScript := preload("res://scripts/fx/combat_fx.gd")

func _init() -> void:
	var failures: Array[String] = []
	await _check_direct_fx_spawns(failures)
	if failures.is_empty():
		print("Combat animation smoke OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_direct_fx_spawns(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)
	CombatFxScript.spawn_slash(parent, Vector2(10, 10), Vector2.RIGHT)
	CombatFxScript.spawn_muzzle_flash(parent, Vector2(20, 10), Vector2.RIGHT)
	CombatFxScript.spawn_dash_ghost(parent, null, Vector2(30, 10), false)
	CombatFxScript.spawn_telegraph(parent, Vector2(40, 10), Vector2.RIGHT, 24.0, 0.2)
	await process_frame
	if parent.get_node_or_null("CombatFxSlash") == null:
		failures.append("spawn_slash should create CombatFxSlash")
	if parent.get_node_or_null("CombatFxMuzzleFlash") == null:
		failures.append("spawn_muzzle_flash should create CombatFxMuzzleFlash")
	if parent.get_node_or_null("CombatFxDashGhost") == null:
		failures.append("spawn_dash_ghost should create CombatFxDashGhost")
	if parent.get_node_or_null("CombatFxTelegraph") == null:
		failures.append("spawn_telegraph should create CombatFxTelegraph")
	await create_timer(0.45).timeout
	if parent.get_node_or_null("CombatFxSlash") != null:
		failures.append("CombatFxSlash should clean itself up")
	parent.free()
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/combat_animation_smoke.gd
```

Expected: fail because `res://scripts/fx/combat_fx.gd` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `CombatFx` with static methods:

```gdscript
class_name CombatFx
extends RefCounted

static func spawn_slash(parent: Node, origin: Vector2, dir: Vector2, color := Color(1.0, 0.92, 0.55, 0.9)) -> Node2D:
	var root := Node2D.new()
	root.name = "CombatFxSlash"
	parent.add_child(root)
	root.global_position = origin
	root.rotation = dir.angle()
	var arc := Line2D.new()
	arc.points = PackedVector2Array([Vector2(2, -9), Vector2(12, -4), Vector2(18, 0), Vector2(12, 4), Vector2(2, 9)])
	arc.width = 3.0
	arc.default_color = color
	root.add_child(arc)
	_lifetime(root, 0.18)
	return root
```

Also implement `spawn_muzzle_flash`, `spawn_dash_ghost`, `spawn_telegraph`, and `_lifetime` using shape nodes plus short tweens.

- [ ] **Step 4: Run test to verify it passes**

Run the same Godot command. Expected: `Combat animation smoke OK`.

### Task 2: Weapon And Dash Hooks

**Files:**
- Modify: `scripts/weapons/weapon.gd`
- Modify: `scripts/player/player.gd`
- Test: `scripts/tests/combat_animation_smoke.gd`

- [ ] **Step 1: Extend the failing test**

Add checks that instantiate `player.tscn`, apply `blade_warden`, fire a melee weapon, then equip a ranged weapon and fire again. Assert `CombatFxSlash`, `CombatFxMuzzleFlash`, and `CombatFxDashGhost` appear under `root`.

- [ ] **Step 2: Run test to verify it fails**

Expected: direct FX checks pass, but gameplay hook checks fail because weapon/dash do not call `CombatFx`.

- [ ] **Step 3: Implement hooks**

In `weapon.gd`, preload `CombatFx`, and after cooldown succeeds call:

```gdscript
if is_melee():
	CombatFx.spawn_slash(get_tree().current_scene, origin + aim * melee_reach() * 0.45, aim)
	_melee_hit(origin, aim)
else:
	CombatFx.spawn_muzzle_flash(get_tree().current_scene, origin + aim * 10.0, aim)
	_fire_projectile(origin, aim)
```

In `player.gd`, preload `CombatFx`, and in `_start_dash()` call:

```gdscript
CombatFx.spawn_dash_ghost(get_tree().current_scene, _sprite, global_position, _sprite.flip_h if _sprite != null else false)
```

- [ ] **Step 4: Run test to verify it passes**

Run the combat animation smoke test. Expected: `Combat animation smoke OK`.

### Task 3: Enemy Telegraph Hooks

**Files:**
- Modify: `scripts/enemies/enemy.gd`
- Modify: `scripts/enemies/boss_golem.gd`
- Test: `scripts/tests/combat_animation_smoke.gd`

- [ ] **Step 1: Extend the failing test**

Instantiate `enemy.tscn`, set `kind = "melee_charger"`, assign a nearby dummy target, step physics long enough to enter telegraph, and assert `CombatFxTelegraph` exists.

- [ ] **Step 2: Run test to verify it fails**

Expected: enemy enters telegraph behavior but no telegraph FX node exists.

- [ ] **Step 3: Implement hooks**

In `enemy.gd`, preload `CombatFx`, add `_show_telegraph_fx(dir, radius, duration)`, and call it exactly when `_state` changes into `telegraph` or `fuse`.

In `boss_golem.gd`, call `_show_telegraph_fx()` when phases 1 and 3 enter `telegraph`.

- [ ] **Step 4: Run test to verify it passes**

Run the combat animation smoke test. Expected: `Combat animation smoke OK`.

### Task 4: Full Verification And Push

**Files:**
- Stage only touched source, test, spec, and plan files.

- [ ] **Step 1: Run editor import**

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --editor --path . --quit
```

- [ ] **Step 2: Run smoke tests**

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/sprite_db_smoke.gd
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/visual_sprite_smoke.gd
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/camera_sprite_polish_smoke.gd
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/gameplay_polish_smoke.gd
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/ten_class_roster_smoke.gd
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/combat_animation_smoke.gd
```

Expected: all tests exit 0.

- [ ] **Step 3: Commit and push**

```powershell
git add docs/superpowers/specs/2026-07-04-combat-animation-v1-design.md docs/superpowers/plans/2026-07-04-combat-animation-v1.md scripts/fx/combat_fx.gd scripts/tests/combat_animation_smoke.gd scripts/weapons/weapon.gd scripts/player/player.gd scripts/enemies/enemy.gd scripts/enemies/boss_golem.gd
git commit -m "Add combat animation polish"
git push
```
