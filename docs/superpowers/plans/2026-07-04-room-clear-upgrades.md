# Room Clear Upgrades Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a roguelike loop where clearing a combat room offers 1 of 3 upgrades.

**Architecture:** `FloorController` emits a reward signal for combat-style room clears. `Main` rolls deterministic choices through `UpgradeDB`, pauses the player, shows `RunOverlay` choice buttons, applies the selected upgrade, then resumes play.

**Tech Stack:** Godot 4.7, GDScript, existing `Player`, `FloorController`, `RunOverlay`, headless smoke tests.

---

### Task 1: Smoke Test First

**Files:**
- Create: `scripts/tests/room_upgrade_smoke.gd`

- [ ] **Step 1: Write failing test**

Assert:

```gdscript
ResourceLoader.exists("res://scripts/progression/upgrade_db.gd")
UpgradeDB.roll_choices(123, 4, 1).size() == 3
UpgradeDB.apply_upgrade(player, "vital_core") changes max_hp
RunOverlay.show_upgrade_choices(...) creates three buttons and emits upgrade_chosen
FloorController emits room_reward_pending only for combat-style room types
```

- [ ] **Step 2: Verify red**

Run:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe" --headless --path . --script scripts/tests/room_upgrade_smoke.gd
```

Expected: fail because `UpgradeDB` and reward overlay APIs do not exist.

### Task 2: Upgrade Data And Application

**Files:**
- Create: `scripts/progression/upgrade_db.gd`

- [ ] **Step 1: Add upgrade pool**

Add six upgrades:

- `vital_core`: +20 max HP and current HP
- `power_rune`: +12% damage multiplier
- `swift_boots`: +8 move speed
- `dash_spring`: -10% dash cooldown
- `focus_cell`: +10 max resource and current resource
- `lucky_coin`: +15 gold

- [ ] **Step 2: Add deterministic roll**

`roll_choices(run_seed, room_id, floor_index, count := 3)` returns unique dictionaries.

### Task 3: Overlay And Floor Hook

**Files:**
- Modify: `scripts/ui/run_overlay.gd`
- Modify: `scripts/rooms/floor_controller.gd`
- Modify: `scripts/main.gd`

- [ ] **Step 1: Overlay choice buttons**

`RunOverlay.show_upgrade_choices(choices)` displays 3 buttons and emits `upgrade_chosen(id)`.

- [ ] **Step 2: Floor reward signal**

`FloorController.room_reward_pending(room_id, room_type)` emits for `COMBAT`, `ELITE`, and `MINIBOSS`.

- [ ] **Step 3: Main applies reward**

`Main` pauses player physics while choosing, applies selected upgrade through `UpgradeDB`, hides overlay, resumes player.

### Task 4: Full Verification

**Files:**
- Do not push.
- Do not commit unless requested.

- [ ] **Step 1: Editor import**

Run Godot editor import headless.

- [ ] **Step 2: Smoke suite**

Run all smoke tests plus `room_upgrade_smoke.gd`.

## Self-Review

Scope is room-clear upgrade choice only. No meta progression, save file, rarity UI, or full upgrade balancing in this slice.
