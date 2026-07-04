# Ten Class Roster Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all 10 GDD base classes selectable and run-startable in the Godot MVP.

**Architecture:** Keep class data in `data/classes.json`; `PlayerClassDB` continues to load it without API changes. Update `ClassSelectScreen` layout only, then map starter weapons in `main.gd`.

**Tech Stack:** Godot 4.7, GDScript, JSON class data, headless smoke tests.

---

### Task 1: Roster Smoke Test

**Files:**
- Create: `scripts/tests/ten_class_roster_smoke.gd`

- [ ] Write a failing smoke test for 10 unique classes, required data keys, scrollable class grid, and `Player.apply_class()` for every class.
- [ ] Run the smoke test and confirm it fails because only 3 classes exist and the UI has no class grid.

### Task 2: Data And UI

**Files:**
- Modify: `data/classes.json`
- Modify: `scripts/ui/class_select.gd`
- Modify: `scripts/main.gd`

- [ ] Add the 7 missing class records from the GDD.
- [ ] Replace the horizontal class button row with a named `ScrollContainer` + `GridContainer`.
- [ ] Add starter weapon mappings for the 7 new classes.
- [ ] Run the smoke test and confirm it passes.

### Task 3: Verification And Push

**Files:**
- Stage touched source, data, docs, tests, and new test `.uid`.

- [ ] Run editor import.
- [ ] Run existing smoke tests plus `ten_class_roster_smoke.gd`.
- [ ] Run headless launch.
- [ ] Commit and push `feature/godot-mvp-scaffold`.
