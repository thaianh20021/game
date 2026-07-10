# Soul-Like Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local-only Soul-like prototype pass: traps, breakable props, special rooms, weapon patterns, boss floating guns, and HUD room objective text.

**Architecture:** Add focused Godot nodes for hazards, props, interactables, and boss pressure, then let `RoomRenderer` compose them per room type. Keep tests headless and shape-based so no unlicensed reference asset enters committed gameplay.

**Tech Stack:** Godot 4.7, GDScript, existing project data/assets, headless smoke tests.

---

### Task 1: Smoke Test First

**Files:**
- Create: `scripts/tests/soul_like_expansion_smoke.gd`

- [ ] **Step 1: Write failing test**

Create a test that preloads the wished-for feature scripts, instantiates each public node, and asserts behavior:

```gdscript
extends SceneTree

const TrapScript := preload("res://scripts/rooms/trap.gd")
const BreakablePropScript := preload("res://scripts/rooms/breakable_prop.gd")
const RoomInteractableScript := preload("res://scripts/rooms/room_interactable.gd")
const FloatingGunScript := preload("res://scripts/enemies/floating_gun.gd")

func _init() -> void:
	var failures: Array[String] = []
	await _check_traps_and_props(failures)
	await _check_interactables(failures)
	await _check_renderer_room_features(failures)
	_check_weapon_patterns(failures)
	await _check_boss_floating_guns(failures)
	if failures.is_empty():
		print("Soul-like expansion smoke OK")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)
```

- [ ] **Step 2: Verify red**

Run:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/soul_like_expansion_smoke.gd
```

Expected: fail because the feature scripts do not exist.

### Task 2: Room Feature Nodes

**Files:**
- Create: `scripts/rooms/trap.gd`
- Create: `scripts/rooms/breakable_prop.gd`
- Create: `scripts/rooms/room_interactable.gd`
- Modify: `scripts/rooms/room_renderer.gd`

- [ ] **Step 1: Implement focused nodes**

`Trap` exposes `configure(kind, damage, cooldown, telegraph_time)` and `apply_to(target, now)`.
`BreakableProp` exposes `configure(kind, hp, drop_data, player)` and `hit(amount)`.
`RoomInteractable` exposes `configure(kind, player)` and `use()`.

- [ ] **Step 2: Compose in rooms**

Add `room_type` to `RoomRenderer.setup`. Spawn:

- combat/elite/miniboss/boss: traps and props
- treasure: chest
- heal: shrine
- shop: vending machine

- [ ] **Step 3: Verify green for room systems**

Run the soul-like smoke test. Expected: room feature checks pass.

### Task 3: Weapon Pattern V2

**Files:**
- Modify: `scripts/weapons/weapon.gd`

- [ ] **Step 1: Add pattern helpers**

Add `projectile_count()`, `burst_count()`, and `_aim_variants(aim)` using existing weapon `group`, `speed`, and `range` values.

- [ ] **Step 2: Fire variants**

`try_attack()` keeps current damage math but ranged weapons can fire spread or burst variants. Melee remains one hit arc.

- [ ] **Step 3: Verify green for weapon patterns**

Run the soul-like smoke test. Expected: pattern helper checks pass.

### Task 4: Boss Floating Guns

**Files:**
- Create: `scripts/enemies/floating_gun.gd`
- Modify: `scripts/enemies/boss_golem.gd`

- [ ] **Step 1: Add floating gun node**

`FloatingGun` orbits an owner, tracks a target, and fires simple visible projectiles on cooldown.

- [ ] **Step 2: Spawn from boss**

`BossGolem.spawn_floating_guns(count)` adds guns to the boss once and reuses the existing boss target.

- [ ] **Step 3: Verify green for boss pressure**

Run the soul-like smoke test. Expected: floating gun checks pass.

### Task 5: HUD Room Objective

**Files:**
- Modify: `scripts/ui/hud.gd`
- Modify: `scripts/rooms/floor_controller.gd`

- [ ] **Step 1: Emit room updates**

Expose current room type text through `FloorController` state changes.

- [ ] **Step 2: Render compact objective**

HUD shows room type and objective: clear enemies, open chest, heal, shop, find exit.

- [ ] **Step 3: Verify existing UI smoke remains green**

Run gameplay polish and soul-like smoke tests.

### Task 6: Full Local Verification

**Files:**
- Do not stage `_reference_unlicensed/`.
- Do not push to GitLab.

- [ ] **Step 1: Editor import**

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --editor --path . --quit
```

- [ ] **Step 2: Smoke tests**

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/sprite_db_smoke.gd
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/visual_sprite_smoke.gd
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/camera_sprite_polish_smoke.gd
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/gameplay_polish_smoke.gd
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/ten_class_roster_smoke.gd
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/combat_animation_smoke.gd
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/soul_like_expansion_smoke.gd
```

Expected: all exit 0.

- [ ] **Step 3: Local-only status**

Run `git status --short`. Report changed files. Do not commit or push unless the user asks.

## Self-Review

Spec coverage maps to Tasks 1-6. No placeholder steps. Public method names are consistent across tasks and tests.
