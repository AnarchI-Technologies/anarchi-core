param(
    [string]$Action = "status",
    [string]$Target = "",
    [int]$Risk = 0,
    [switch]$Execute
)

$ErrorActionPreference = "Stop"

function New-AnarchIContext {
    param(
        [string]$Name = "anarchi-core",
        [string]$Mode = "dry-run"
    )

    [pscustomobject]@{
        Name      = $Name
        Mode      = $Mode
        StartedAt = (Get-Date).ToUniversalTime().ToString("o")
        Principle = "Deterministic systems first; AI only when required."
    }
}

function Test-AnarchIRisk {
    param(
        [int]$Risk,
        [switch]$Execute
    )

    if ($Risk -lt 0 -or $Risk -gt 100) {
        return [pscustomobject]@{ Route = "reject"; CanExecute = $false; Reason = "risk must be between 0 and 100" }
    }

    if ($Risk -ge 75) {
        return [pscustomobject]@{ Route = "review"; CanExecute = $false; Reason = "high risk requires operator review" }
    }

    if (-not $Execute) {
        return [pscustomobject]@{ Route = "dry-run"; CanExecute = $false; Reason = "execute switch not supplied" }
    }

    return [pscustomobject]@{ Route = "execute"; CanExecute = $true; Reason = "risk gate cleared" }
}

function Resolve-AnarchITarget {
    param([string]$Target)

    if ([string]::IsNullOrWhiteSpace($Target)) {
        return [pscustomobject]@{ Kind = "none"; Value = ""; Safe = $true }
    }

    $isUrl = $Target -match '^https?://'
    $isLocalPath = $Target -match '^[a-zA-Z]:\\' -or $Target.StartsWith(".\")

    if ($Target -match '(?i)(token|secret|password|private_key)') {
        return [pscustomobject]@{ Kind = "blocked"; Value = $Target; Safe = $false }
    }

    if ($isUrl) {
        return [pscustomobject]@{ Kind = "url"; Value = $Target; Safe = $true }
    }

    if ($isLocalPath) {
        return [pscustomobject]@{ Kind = "path"; Value = $Target; Safe = $true }
    }

    return [pscustomobject]@{ Kind = "label"; Value = $Target; Safe = $true }
}

function Invoke-AnarchICore {
    param(
        [string]$Action = "status",
        [string]$Target = "",
        [int]$Risk = 0,
        [switch]$Execute
    )

    $context = New-AnarchIContext
    $riskGate = Test-AnarchIRisk -Risk $Risk -Execute:$Execute
    $resolvedTarget = Resolve-AnarchITarget -Target $Target

    if (-not $resolvedTarget.Safe) {
        $riskGate = [pscustomobject]@{ Route = "reject"; CanExecute = $false; Reason = "target contains sensitive-keyword pattern" }
    }

    [pscustomobject]@{
        Context = $context
        Action  = $Action
        Target  = $resolvedTarget
        Gate    = $riskGate
    }
}

if ($MyInvocation.InvocationName -ne ".") {
    Invoke-AnarchICore -Action $Action -Target $Target -Risk $Risk -Execute:$Execute | ConvertTo-Json -Depth 6
}
