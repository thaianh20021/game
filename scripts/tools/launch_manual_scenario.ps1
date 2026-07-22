param(
  [Alias("scenario-index")]
  [int]$ScenarioIndex = 0,
  [string]$Element = "fire",
  [switch]$DryRun,
  [switch]$Detached,
  [switch]$List,
  [switch]$Next
)

$ErrorActionPreference = "Stop"

$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"
if (-not (Test-Path -LiteralPath $godot)) {
  throw "Godot console executable not found: $godot"
}
$godotGui = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64.exe"

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

$screenshotPath = Join-Path $env:TEMP ("dungeon_core_manual_scenario_{0}.png" -f $ScenarioIndex)
$captureCommandTemplate = 'powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $bounds.Width,$bounds.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size); $bmp.Save(''{0}'',[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); Write-Output ''{0}''"'
$captureCommand = [string]::Format($captureCommandTemplate, $screenshotPath)

Write-Host "Launching manual playtest scenario $ScenarioIndex ($Element)"
Write-Host "Manual Scenario Checklist:"
Write-Host "Manual Notes Required: animation, polygon, wave, HUD, audio"
Write-Host "Issue aliases: poligon -> polygon_collision, polygon -> polygon_collision, collision -> polygon_collision, animation -> asset_animation"
Write-Host "- Wave/HUD/Audio: verify Wave x/y, enemies_left, WaveStartCue, WaveStartSfx; record wave_hud_audio_notes."
Write-Host "- Asset notes: record asset_animation_notes and polygon_collision_notes after the run."
Write-Host "Notes Skeleton: asset_animation_notes=<human animation notes> | polygon_collision_notes=<human polygon notes> | wave_hud_audio_notes=<human wave hud audio notes>"
Write-Host "Suggested Screenshot: $screenshotPath"
Write-Host "Capture Screenshot: $captureCommand"
Write-Host "Final Notes: godot --headless --path . --script res://scripts/tools/record_playtest_notes_evidence.gd -- --seed=<seed> --class_id=<class_id> --mode=<mode> --replay_last_run_result=<human result> --daily_fingerprint_hash=<daily hash> --pace_avg_sec=<avg sec> --pace_boss_sec=<boss sec> --asset_animation_notes=<human animation notes> --polygon_collision_notes=<human polygon notes> --wave_hud_audio_notes=<human wave hud audio notes> --blocker_screenshot_or_seed=<screenshot or seed> --release_decision=<hold or ready>"
Write-Host "- Pass evidence: godot --headless --path . --script res://scripts/tools/record_manual_scenario_evidence.gd -- --scenario-index=$ScenarioIndex --result=pass --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human notes> --screenshot_or_seed=$screenshotPath"
Write-Host "- Record Issue: godot --headless --path . --script res://scripts/tools/record_manual_playtest_issue.gd -- --scenario-index=$ScenarioIndex --result=blocked --issue_type=<issue_type> --evidence_source=manual_playtest --confirm-human-playtest=true --notes=<human issue notes> --screenshot_or_seed=$screenshotPath"
Write-Host "- Resolve Issue: godot --headless --path . --script res://scripts/tools/resolve_manual_playtest_issue.gd -- --scenario-index=$ScenarioIndex --issue_type=<issue_type> --resolution_result=fixed_retest_pass --evidence_source=manual_playtest --confirm-human-retest=true --resolution_notes=<human retest notes> --screenshot_or_seed=$screenshotPath"
if ($DryRun) {
  Write-Host "Dry Run: --manual-scenario=$ScenarioIndex --element=$Element"
  if ($Detached) {
    Write-Host "Detached Launch: Start-Process '$godotGui' --path . -- --manual-scenario=$ScenarioIndex --element=$Element"
    Write-Host "Foreground: restore and focus the visible Godot window after launch"
  }
  Write-Host "No Godot window launched"
  exit 0
}
if ($Detached) {
  if (-not (Test-Path -LiteralPath $godotGui)) {
    throw "Godot visible executable not found: $godotGui"
  }
  $process = Start-Process -FilePath $godotGui -ArgumentList @('--path','.', '--', "--manual-scenario=$ScenarioIndex", "--element=$Element") -WorkingDirectory (Get-Location) -PassThru
  Add-Type @'
using System;
using System.Runtime.InteropServices;
public class ManualScenarioWindow {
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
}
'@
  for ($i = 0; $i -lt 24; $i++) {
    $process.Refresh()
    if ($process.MainWindowHandle -ne 0) { break }
    Start-Sleep -Milliseconds 250
  }
  if ($process.MainWindowHandle -ne 0) {
    $topmost = [IntPtr](-1)
    $notTopmost = [IntPtr](-2)
    [ManualScenarioWindow]::ShowWindow($process.MainWindowHandle, 9) | Out-Null
    [ManualScenarioWindow]::SetWindowPos($process.MainWindowHandle, $topmost, 80, 80, 1280, 720, 0x0040) | Out-Null
    [ManualScenarioWindow]::SetForegroundWindow($process.MainWindowHandle) | Out-Null
    [ManualScenarioWindow]::SetWindowPos($process.MainWindowHandle, $notTopmost, 0, 0, 0, 0, 0x0043) | Out-Null
  }
  exit 0
}
& $godot --path . -- "--manual-scenario=$ScenarioIndex" "--element=$Element"
exit $LASTEXITCODE
