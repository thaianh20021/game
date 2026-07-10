# Skill System Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move active skill behavior out of `Player` without changing existing gameplay.

**Architecture:** `Player` keeps input, resource cost, cooldown, and class state. `SkillRunner` maps `skill_id` to one focused skill script, and each skill script executes one active skill using a shared context dictionary.

**Tech Stack:** Godot 4.7, GDScript, existing `Player`, `Weapon`, `Projectile`, and smoke tests.

---

### Task 1: Refactor Smoke Test

**Files:**
- Create: `scripts/tests/skill_system_refactor_smoke.gd`

- [ ] **Step 1: Write failing test**

Test expects:

```gdscript
ResourceLoader.exists("res://scripts/skills/skill_runner.gd")
SkillRunner.has_skill("wind_edge")
SkillRunner.has_skill("element_orb")
SkillRunner.has_skill("arrow_rain")
```

It also instantiates player/enemy/projectile scenarios and verifies wind edge still damages nearby enemies, element orb still spawns a projectile, and arrow rain still damages after delay.

- [ ] **Step 2: Verify red**

Run:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/skill_system_refactor_smoke.gd
```

Expected: fail because `SkillRunner` does not exist.

### Task 2: Skill Runner And Scripts

**Files:**
- Create: `scripts/skills/skill_runner.gd`
- Create: `scripts/skills/wind_edge_skill.gd`
- Create: `scripts/skills/element_orb_skill.gd`
- Create: `scripts/skills/arrow_rain_skill.gd`
- Modify: `scripts/player/player.gd`

- [ ] **Step 1: Add focused skill scripts**

Each script exposes:

```gdscript
static func execute(ctx: Dictionary) -> void:
	pass
```

`ctx` contains `player`, `skill`, `base_damage`, `aim_dir`, `target_position`, `element`, and `scene`.

- [ ] **Step 2: Add runner**

`SkillRunner.execute(skill_id, ctx)` dispatches to a static script map. `SkillRunner.has_skill(skill_id)` is test-visible.

- [ ] **Step 3: Delegate from player**

`Player._try_skill()` keeps cost/cooldown behavior, builds context, and calls `SkillRunner.execute(str(skill["id"]), ctx)`.

### Task 3: Verification

**Files:**
- Do not push.
- Do not commit unless requested.

- [ ] **Step 1: Run editor import**

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --editor --path . --quit
```

- [ ] **Step 2: Run smoke tests**

Run the existing smoke suite plus `skill_system_refactor_smoke.gd`.

## Self-Review

Scope is one refactor only. No new skills or changed balance. Player retains resource/cooldown semantics.
