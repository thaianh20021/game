# Manual Playtest Packet

Draft only: this file helps a human tester run and record evidence; it does not record release evidence.
Release evidence only counts after the record commands are run with actual human notes.

Status: evidence_required
Next action: Next Action: Record playtest notes | seed/class/mode/animation/polygon/wave/HUD/audio evidence

## Required Playtest Notes

Command:
```powershell
godot --headless --path . --script res://scripts/tools/record_playtest_notes_evidence.gd -- --seed=<seed> --class_id=<class_id> --mode=<mode> --replay_last_run_result=<replay_last_run_result> --daily_fingerprint_hash=<daily_fingerprint_hash> --pace_avg_sec=<pace_avg_sec> --pace_boss_sec=<pace_boss_sec> --asset_animation_notes=<asset_animation_notes> --polygon_collision_notes=<polygon_collision_notes> --wave_hud_audio_notes=<wave_hud_audio_notes> --blocker_screenshot_or_seed=<blocker_screenshot_or_seed> --release_decision=<release_decision>
```

Dry Run Command:
```powershell
godot --headless --path . --script res://scripts/tools/record_playtest_notes_evidence.gd -- --seed=420101 --class_id=blade_warden --mode=normal --replay_last_run_result=dry_run_replay_check --daily_fingerprint_hash=dry_run_hash_420101 --pace_avg_sec=40 --pace_boss_sec=90 --asset_animation_notes=dry_run_animation_notes --polygon_collision_notes=dry_run_polygon_notes --wave_hud_audio_notes=dry_run_wave_hud_audio_notes --blocker_screenshot_or_seed=none_dry_run --release_decision=hold --dry-run=true
```

Fields:
- seed
- class_id
- mode
- replay_last_run_result
- daily_fingerprint_hash
- pace_avg_sec
- pace_boss_sec
- asset_animation_notes
- polygon_collision_notes
- wave_hud_audio_notes
- blocker_screenshot_or_seed
- release_decision

Notes Skeleton:
asset_animation_notes=<human animation notes> | polygon_collision_notes=<human polygon notes> | wave_hud_audio_notes=<human wave hud audio notes>

Final Notes:
```powershell
godot --headless --path . --script res://scripts/tools/record_playtest_notes_evidence.gd -- --seed=420101 --class_id=blade_warden --mode=normal --replay_last_run_result=<human result> --daily_fingerprint_hash=<daily hash> --pace_avg_sec=<avg sec> --pace_boss_sec=<boss sec> --asset_animation_notes=<human animation notes> --polygon_collision_notes=<human polygon notes> --wave_hud_audio_notes=<human wave hud audio notes> --blocker_screenshot_or_seed=<screenshot or seed> --release_decision=<hold or ready>
```

Playtest Notes Draft:
```powershell
godot --headless --path . --script res://scripts/tools/record_playtest_notes_evidence.gd -- --seed=420101 --class_id=blade_warden --mode=normal --replay_last_run_result=<human result> --daily_fingerprint_hash=<daily hash> --pace_avg_sec=<avg sec> --pace_boss_sec=<boss sec> --asset_animation_notes=<human animation notes> --polygon_collision_notes=<human polygon notes> --wave_hud_audio_notes=<human wave hud audio notes> --blocker_screenshot_or_seed=<screenshot or seed> --release_decision=<hold or ready>
```
Draft scenario: 1 | seed 420101 | mode normal | class blade_warden | clear floor 1 and choose one upgrade

Asset notes must include asset_animation_notes and polygon_collision_notes.
Issue types: polygon_collision, asset_animation, missing_asset_source, combat_readability, balance_pace, ui_overlap
Issue aliases: poligon -> polygon_collision, polygon -> polygon_collision, collision -> polygon_collision, animation -> asset_animation

## Wave/HUD/Audio Live Check

During combat rooms, verify:
- HUD objective shows Wave x/y and enemies_left as enemies die.
- WaveStartCue appears when wave 2/3 or 3/3 begins.
- WaveStartSfx plays or records placeholder metadata.
- objective_context_changed updates HUD without rebinding.

## Manual Scenarios

Manual Scenario List:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -List
```

Next Missing Launch Dry Run:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -Next -DryRun
```

Next Missing Launch:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -Next
```

Manual Progress
# | Status | Seed | Mode | Class | Next
1 | missing | 420101 | normal | blade_warden | launch
2 | missing | 420102 | boss_rush | bulwark | launch
3 | missing | 420103 | endless | arcanist | launch
4 | missing | 420104 | hardcore | nightblade | launch
5 | missing | 420105 | elemental_chaos | ranger | launch
6 | missing | 420106 | balance_lab | gunner | launch

### Scenario 1

- Seed: 420101
- Mode: normal
- Class: blade_warden
- Goal: clear floor 1 and choose one upgrade
- Status: missing

Suggested Screenshot:
```text
C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_1.png
```

Capture Screenshot:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $bounds.Width,$bounds.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size); $bmp.Save('C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_1.png',[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); Write-Output 'C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_1.png'"
```

Launch Dry Run:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 1 -Detached -DryRun
```

Launch:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 1 -Detached
```

Dry Run before recording:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=1 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=animation stable polygon collision matched wave HUD audio clear --screenshot_or_seed=seed_420101_dry_run --dry-run=true
```

Record only after a real human pass:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=1 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run blocker/bug command:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=1 --result=blocked --issue_type=polygon_collision --evidence_source=manual_playtest --confirm-human-playtest=true --notes=dry_run_issue_notes --screenshot_or_seed=seed_420101_dry_run --dry-run=true
```

Record blocker/bug after a real human fail:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=1 --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run resolution command:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=1 --issue_type=polygon_collision --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=dry_run_retest_notes --screenshot_or_seed=seed_420101_dry_run --dry-run=true
```

Resolve only after fix and human retest:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=1 --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=<screenshot or seed>
```

Issue types: polygon_collision, asset_animation, missing_asset_source, combat_readability, balance_pace, ui_overlap
Issue aliases: poligon -> polygon_collision, polygon -> polygon_collision, collision -> polygon_collision, animation -> asset_animation

Human notes placeholder: actual human result, blockers, screenshot path or seed, feel notes

### Scenario 2

- Seed: 420102
- Mode: boss_rush
- Class: bulwark
- Goal: survive boss phase shift and enrage
- Status: missing

Suggested Screenshot:
```text
C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_2.png
```

Capture Screenshot:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $bounds.Width,$bounds.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size); $bmp.Save('C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_2.png',[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); Write-Output 'C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_2.png'"
```

Launch Dry Run:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 2 -Detached -DryRun
```

Launch:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 2 -Detached
```

Dry Run before recording:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=2 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=animation stable polygon collision matched wave HUD audio clear --screenshot_or_seed=seed_420102_dry_run --dry-run=true
```

Record only after a real human pass:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=2 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run blocker/bug command:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=2 --result=blocked --issue_type=polygon_collision --evidence_source=manual_playtest --confirm-human-playtest=true --notes=dry_run_issue_notes --screenshot_or_seed=seed_420102_dry_run --dry-run=true
```

Record blocker/bug after a real human fail:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=2 --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run resolution command:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=2 --issue_type=polygon_collision --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=dry_run_retest_notes --screenshot_or_seed=seed_420102_dry_run --dry-run=true
```

Resolve only after fix and human retest:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=2 --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=<screenshot or seed>
```

Issue types: polygon_collision, asset_animation, missing_asset_source, combat_readability, balance_pace, ui_overlap
Issue aliases: poligon -> polygon_collision, polygon -> polygon_collision, collision -> polygon_collision, animation -> asset_animation

Human notes placeholder: actual human result, blockers, screenshot path or seed, feel notes

### Scenario 3

- Seed: 420103
- Mode: endless
- Class: arcanist
- Goal: reach post-finale biome transition
- Status: missing

Suggested Screenshot:
```text
C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_3.png
```

Capture Screenshot:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $bounds.Width,$bounds.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size); $bmp.Save('C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_3.png',[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); Write-Output 'C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_3.png'"
```

Launch Dry Run:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 3 -Detached -DryRun
```

Launch:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 3 -Detached
```

Dry Run before recording:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=3 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=animation stable polygon collision matched wave HUD audio clear --screenshot_or_seed=seed_420103_dry_run --dry-run=true
```

Record only after a real human pass:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=3 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run blocker/bug command:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=3 --result=blocked --issue_type=polygon_collision --evidence_source=manual_playtest --confirm-human-playtest=true --notes=dry_run_issue_notes --screenshot_or_seed=seed_420103_dry_run --dry-run=true
```

Record blocker/bug after a real human fail:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=3 --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run resolution command:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=3 --issue_type=polygon_collision --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=dry_run_retest_notes --screenshot_or_seed=seed_420103_dry_run --dry-run=true
```

Resolve only after fix and human retest:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=3 --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=<screenshot or seed>
```

Issue types: polygon_collision, asset_animation, missing_asset_source, combat_readability, balance_pace, ui_overlap
Issue aliases: poligon -> polygon_collision, polygon -> polygon_collision, collision -> polygon_collision, animation -> asset_animation

Human notes placeholder: actual human result, blockers, screenshot path or seed, feel notes

### Scenario 4

- Seed: 420104
- Mode: hardcore
- Class: nightblade
- Goal: verify lethal damage/readability feels fair
- Status: missing

Suggested Screenshot:
```text
C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_4.png
```

Capture Screenshot:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $bounds.Width,$bounds.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size); $bmp.Save('C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_4.png',[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); Write-Output 'C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_4.png'"
```

Launch Dry Run:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 4 -Detached -DryRun
```

Launch:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 4 -Detached
```

Dry Run before recording:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=4 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=animation stable polygon collision matched wave HUD audio clear --screenshot_or_seed=seed_420104_dry_run --dry-run=true
```

Record only after a real human pass:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=4 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run blocker/bug command:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=4 --result=blocked --issue_type=polygon_collision --evidence_source=manual_playtest --confirm-human-playtest=true --notes=dry_run_issue_notes --screenshot_or_seed=seed_420104_dry_run --dry-run=true
```

Record blocker/bug after a real human fail:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=4 --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run resolution command:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=4 --issue_type=polygon_collision --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=dry_run_retest_notes --screenshot_or_seed=seed_420104_dry_run --dry-run=true
```

Resolve only after fix and human retest:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=4 --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=<screenshot or seed>
```

Issue types: polygon_collision, asset_animation, missing_asset_source, combat_readability, balance_pace, ui_overlap
Issue aliases: poligon -> polygon_collision, polygon -> polygon_collision, collision -> polygon_collision, animation -> asset_animation

Human notes placeholder: actual human result, blockers, screenshot path or seed, feel notes

### Scenario 5

- Seed: 420105
- Mode: elemental_chaos
- Class: ranger
- Goal: verify element swaps and combo feedback
- Status: missing

Suggested Screenshot:
```text
C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_5.png
```

Capture Screenshot:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $bounds.Width,$bounds.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size); $bmp.Save('C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_5.png',[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); Write-Output 'C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_5.png'"
```

Launch Dry Run:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 5 -Detached -DryRun
```

Launch:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 5 -Detached
```

Dry Run before recording:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=5 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=animation stable polygon collision matched wave HUD audio clear --screenshot_or_seed=seed_420105_dry_run --dry-run=true
```

Record only after a real human pass:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=5 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run blocker/bug command:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=5 --result=blocked --issue_type=polygon_collision --evidence_source=manual_playtest --confirm-human-playtest=true --notes=dry_run_issue_notes --screenshot_or_seed=seed_420105_dry_run --dry-run=true
```

Record blocker/bug after a real human fail:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=5 --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run resolution command:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=5 --issue_type=polygon_collision --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=dry_run_retest_notes --screenshot_or_seed=seed_420105_dry_run --dry-run=true
```

Resolve only after fix and human retest:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=5 --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=<screenshot or seed>
```

Issue types: polygon_collision, asset_animation, missing_asset_source, combat_readability, balance_pace, ui_overlap
Issue aliases: poligon -> polygon_collision, polygon -> polygon_collision, collision -> polygon_collision, animation -> asset_animation

Human notes placeholder: actual human result, blockers, screenshot path or seed, feel notes

### Scenario 6

- Seed: 420106
- Mode: balance_lab
- Class: gunner
- Goal: record TTK/pace notes for weapon and economy tuning
- Status: missing

Suggested Screenshot:
```text
C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_6.png
```

Capture Screenshot:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $bounds.Width,$bounds.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size); $bmp.Save('C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_6.png',[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); Write-Output 'C:/Users/ADMIN/AppData/Local/Temp/dungeon_core_manual_scenario_6.png'"
```

Launch Dry Run:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 6 -Detached -DryRun
```

Launch:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 6 -Detached
```

Dry Run before recording:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=6 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=animation stable polygon collision matched wave HUD audio clear --screenshot_or_seed=seed_420106_dry_run --dry-run=true
```

Record only after a real human pass:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=6 --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run blocker/bug command:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=6 --result=blocked --issue_type=polygon_collision --evidence_source=manual_playtest --confirm-human-playtest=true --notes=dry_run_issue_notes --screenshot_or_seed=seed_420106_dry_run --dry-run=true
```

Record blocker/bug after a real human fail:
```powershell
godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=6 --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=<screenshot or seed>
```

Dry Run resolution command:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=6 --issue_type=polygon_collision --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=dry_run_retest_notes --screenshot_or_seed=seed_420106_dry_run --dry-run=true
```

Resolve only after fix and human retest:
```powershell
godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=6 --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=<screenshot or seed>
```

Issue types: polygon_collision, asset_animation, missing_asset_source, combat_readability, balance_pace, ui_overlap
Issue aliases: poligon -> polygon_collision, polygon -> polygon_collision, collision -> polygon_collision, animation -> asset_animation

Human notes placeholder: actual human result, blockers, screenshot path or seed, feel notes

## Asset Source Policy

Asset Sources: 0x72 -> project polygon -> procedural -> local asset -> free itch.io -> Godot Asset Library -> AI | Missing assets: existing/project -> local asset -> free itch.io -> Godot Asset Library -> AI | Fanmade refs: pattern only, no copy (CalvinWan0101/soul-knight, leoyin1127/Soul-knights) | Self-review: frame/fps/motion/origin/polygon before release

Asset Self-Review Commands:
```powershell
godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --kind=sprite
godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --kind=vfx
godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --kind=audio
godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --kind=collision
godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --kind=object_visual
godot --headless --path . --script res://scripts/tools/print_asset_replacement_plan.gd -- --kind=collision
godot --headless --path . --script res://scripts/tools/review_asset_candidate.gd -- --manifest=<manifest.json> [--source=<source_id>]
```

fanmade repos are reference-only for pattern study and must not be copied into runtime:
- CalvinWan0101/soul-knight
- leoyin1127/Soul-knights

If any animation, VFX, audio, object visual, or polygon is replaced, use licensed 0x72/free itch.io/Godot Asset Library/project-owned AI assets and review frame grid, motion, origin, polygon points, and polygon area before release.