param(
  [Alias("scenario-index")]
  [int]$ScenarioIndex = 0,
  [string]$Element = "fire",
  [switch]$DryRun,
  [switch]$List,
  [switch]$Next
)

$ErrorActionPreference = "Stop"

$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"
if (-not (Test-Path -LiteralPath $godot)) {
  throw "Godot console executable not found: $godot"
}

if ($List) {
  Write-Host "Manual Scenarios"
  & $godot --headless --path . --script res://scripts/tools/print_manual_scenario_list.gd
  exit $LASTEXITCODE
}

if ($Next) {
  $nextOutput = & $godot --headless --path . --script res://scripts/tools/print_next_manual_scenario.gd 2>&1
  $nextText = $nextOutput -join "`n"
  if ($LASTEXITCODE -ne 0) {
    Write-Host $nextText
    exit $LASTEXITCODE
  }
  if ($nextText -notmatch "NEXT_MANUAL_SCENARIO_INDEX=(\d+)") {
    Write-Host $nextText
    throw "Could not resolve next missing manual scenario"
  }
  $ScenarioIndex = [int]$Matches[1]
  if ($ScenarioIndex -lt 1) {
    Write-Host "No missing manual scenarios"
    exit 0
  }
  Write-Host $nextText
}

if ($ScenarioIndex -lt 1 -or $ScenarioIndex -gt 6) {
  Write-Host "Usage: powershell -ExecutionPolicy Bypass -File scripts/tools/launch_manual_scenario.ps1 -ScenarioIndex 1..6 [-Element fire|ice|lightning|poison] [-DryRun] [-List] [-Next]"
  & $godot --headless --path . --script res://scripts/tools/release_candidate_status.gd
  exit 1
}

if (@("fire", "ice", "lightning", "poison") -notcontains $Element) {
  throw "Invalid element: $Element"
}

Write-Host "Launching manual playtest scenario $ScenarioIndex ($Element)"
Write-Host "Manual Scenario Checklist:"
Write-Host "Manual Notes Required: animation, polygon, wave, HUD, audio"
Write-Host "Issue aliases: poligon -> polygon_collision, polygon -> polygon_collision, collision -> polygon_collision, animation -> asset_animation"
Write-Host "- Wave/HUD/Audio: verify Wave x/y, enemies_left, WaveStartCue, WaveStartSfx; record wave_hud_audio_notes."
Write-Host "- Asset notes: record asset_animation_notes and polygon_collision_notes after the run."
Write-Host "Notes Skeleton: asset_animation_notes=<human animation notes> | polygon_collision_notes=<human polygon notes> | wave_hud_audio_notes=<human wave HUD audio notes>"
Write-Host "Final Notes: godot --headless --path . --script res://scripts/tools/record_playtest_notes_evidence.gd -- --seed=<seed> --class_id=<class_id> --mode=<mode> --replay_last_run_result=<human result> --daily_fingerprint_hash=<daily hash> --pace_avg_sec=<avg sec> --pace_boss_sec=<boss sec> --asset_animation_notes=<human animation notes> --polygon_collision_notes=<human polygon notes> --wave_hud_audio_notes=<human wave HUD audio notes> --blocker_screenshot_or_seed=<screenshot or seed> --release_decision=<hold or ready>"
Write-Host "- Pass evidence: godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=$ScenarioIndex --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=<screenshot or seed>"
Write-Host "- Record Issue: godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=$ScenarioIndex --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=<screenshot or seed>"
Write-Host "- Resolve Issue: godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=$ScenarioIndex --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=<screenshot or seed>"
if ($DryRun) {
  Write-Host "Dry Run: --manual-scenario=$ScenarioIndex --element=$Element"
  Write-Host "No Godot window launched"
  exit 0
}
& $godot --path . -- "--manual-scenario=$ScenarioIndex" "--element=$Element"
exit $LASTEXITCODE
