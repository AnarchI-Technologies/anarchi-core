$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root "anarchi_core.ps1")

function Assert-Equal($Actual, $Expected, $Name) {
    if ($Actual -ne $Expected) {
        throw "$Name expected '$Expected' but got '$Actual'"
    }
}

# Phase 1: baseline safe dry-run.
$baseline = Invoke-AnarchICore -Action "status" -Target "demo" -Risk 10
Assert-Equal $baseline.Gate.Route "dry-run" "baseline route"
Assert-Equal $baseline.Target.Kind "label" "baseline target"

# Phase 2: stricter high-risk event must not execute.
$strict = Invoke-AnarchICore -Action "deploy" -Target "https://example.com" -Risk 80 -Execute
Assert-Equal $strict.Gate.Route "review" "strict route"
Assert-Equal $strict.Gate.CanExecute $false "strict can execute"

# Phase 3: adversarial sensitive target is rejected.
$adversarial = Invoke-AnarchICore -Action "open" -Target "C:\secret-token.txt" -Risk 1 -Execute
Assert-Equal $adversarial.Gate.Route "reject" "adversarial route"
Assert-Equal $adversarial.Target.Safe $false "adversarial safety"

Write-Output "AnarchI Core tests passed."
