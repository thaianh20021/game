$ErrorActionPreference = "Stop"

$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"
if (-not (Test-Path -LiteralPath $godot)) {
  throw "Godot console executable not found: $godot"
}

$tests = Get-ChildItem 'scripts/tests' -Filter '*.gd' | Sort-Object Name
$failed = @()
foreach ($test in $tests) {
  Write-Host "RUN $($test.Name)"
  & $godot --headless --path . --script "res://scripts/tests/$($test.Name)"
  if ($LASTEXITCODE -ne 0) {
    $failed += $test.Name
  }
}
if ($failed.Count -gt 0) {
  Write-Host "FAILED: $($failed -join ', ')"
  exit 1
}

Write-Host "ALL_SMOKE_OK $($tests.Count)"
& $godot --headless --path . --script res://scripts/tools/record_smoke_suite_evidence.gd -- "--count=$($tests.Count)"
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

& $godot --headless --path . --script res://scripts/tools/record_asset_self_review_evidence.gd
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

& $godot --headless --path . --script res://scripts/tools/record_headless_rehearsal_evidence.gd
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$packageExe = "build/windows/DungeonCoreElementalRebirth.exe"
$packagePck = "build/windows/DungeonCoreElementalRebirth.pck"
if ((Test-Path -LiteralPath $packageExe) -and (Test-Path -LiteralPath $packagePck)) {
  & $godot --headless --path . --script res://scripts/tools/record_export_package_evidence.gd
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} else {
  Write-Host "SKIP export package evidence: package not found"
}

exit 0
