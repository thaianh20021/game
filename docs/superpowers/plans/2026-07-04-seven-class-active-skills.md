# Seven Class Active Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the first active skill for the seven classes not covered by the MVP skill refactor.

**Architecture:** Keep `Player` unchanged. Add one focused script per `skill_id` and register each script in `SkillRunner`. Skill scripts use the existing context dictionary: `player`, `base_damage`, `aim_dir`, `target_position`, `element`, and `scene`.

**Tech Stack:** Godot 4.7, GDScript, existing `SkillRunner`, existing smoke tests.

---

### Task 1: Smoke Test First

**Files:**
- Modify: `scripts/tests/skill_system_refactor_smoke.gd`

- [ ] **Step 1: Extend failing test**

Add expected skill ids:

```gdscript
const REMAINING_SKILLS := [
	"earthbreaker",
	"shadow_step",
	"shield_bastion",
	"rolling_grenade",
	"summon_wisp",
	"light_ray",
	"mini_turret",
]
```

Assert each id exists in `SkillRunner`, then run one behavior check per skill.

- [ ] **Step 2: Verify red**

Run:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/skill_system_refactor_smoke.gd
```

Expected: fail because the seven skills are not registered.

### Task 2: Implement Skill Scripts

**Files:**
- Create: `scripts/skills/earthbreaker_skill.gd`
- Create: `scripts/skills/shadow_step_skill.gd`
- Create: `scripts/skills/shield_bastion_skill.gd`
- Create: `scripts/skills/rolling_grenade_skill.gd`
- Create: `scripts/skills/summon_wisp_skill.gd`
- Create: `scripts/skills/light_ray_skill.gd`
- Create: `scripts/skills/mini_turret_skill.gd`
- Modify: `scripts/skills/skill_runner.gd`

- [ ] **Step 1: Add scripts**

Each script exposes `static func execute(ctx: Dictionary) -> void`.

- [ ] **Step 2: Register scripts**

Add preloads and map entries to `SkillRunner.SKILLS`.

- [ ] **Step 3: Verify green**

Run `scripts/tests/skill_system_refactor_smoke.gd`.

### Task 3: Full Verification

**Files:**
- Do not push.
- Do not commit unless requested.

- [ ] **Step 1: Editor import**

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --editor --path . --quit
```

- [ ] **Step 2: Smoke suite**

Run all existing smoke tests plus `skill_system_refactor_smoke.gd`.

## Self-Review

Scope is first active skill only for the seven remaining classes. No second active skills, passives, ultimates, or balance tuning in this slice.
