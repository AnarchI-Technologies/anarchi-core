# ================================================================================
# ANARCHI PROTOCOL // MODULAR CORE MACHINE ENGINE v1.2.0 (CLI EDITION)
# ================================================================================

# 1. CROSS-PLATFORM SECURITY & ELEVATION LAYER
$RunningOnLinux = $false
$Global:StressTesting = $env:ANARCHI_STRESS_TEST -eq '1'

if ($PSEdition -eq "Core" -and $null -eq $PID) {
    $RunningOnLinux = $true
} else {
    try {
        if ((Get-Command uname -ErrorAction SilentlyContinue) -and ((uname -s) -eq "Linux")) {
            $RunningOnLinux = $true
        }
    } catch {
        $RunningOnLinux = $false
    }
}
if (-not $RunningOnLinux) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        $Arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
        Start-Process -FilePath "powershell.exe" -ArgumentList $Arguments -Verb RunAs
        Exit
    }
    $OSArchitecture = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
} else {
    $isAdmin = ([Environment]::UserName -eq "root") -or (id -u -eq 0)
    if (-not $isAdmin) {
        Write-Error "[CRITICAL ERROR] Access Denied. Sudo or Root clearance mandatory."
        Pause; Exit
    }
    $OSArchitecture = [Environment]::Is64BitOperatingSystem ? "64-bit" : "32-bit"
}

# 2. DYNAMIC HARDWARE ANALYSIS
try { $ScriptHash = (Get-FileHash -Path $PSCommandPath -Algorithm SHA256).Hash } catch { $ScriptHash = "INTEGRITY_READ_FAILED" }

if (-not $RunningOnLinux) {
    try {
        $RawMemoryBytes = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum
        $TotalRAM = [Math]::Round($RawMemoryBytes / 1GB, 2)
    } catch { $TotalRAM = 4.00 }
} else {
    try {
        $MemInfo = Get-Content /proc/meminfo | Select-String "MemTotal"
        $RawMemoryKB = [regex]::Match($MemInfo, '\d+').Value
        $TotalRAM = [Math]::Round($RawMemoryKB / 1024 / 1024, 2)
    } catch { $TotalRAM = 4.00 }
}

$StatusMsg = if ($TotalRAM -le 4.10) { "Optimizing constrained resources..." } else { "Balanced allocation active..." }

$ConfigPath = Join-Path (Split-Path $PSCommandPath) "config.json"

function Show-Header {
    Clear-Host
    Write-Output '================================================================================'
    Write-Output '      [A]narch[I] // Modular Core Machine Engine v1.2.0'
    Write-Output "[STATUS] $StatusMsg"
    Write-Output '================================================================================'
    Write-Output "  [VERIFY] SHA-256 INTEGRITY : $ScriptHash"
    Write-Output "  [SYSTEM] HOST ENVIRONMENT  : $(if($RunningOnLinux){'Linux'}else{'Windows'}) ($OSArchitecture)"
    Write-Output "  [CAP] TOTAL RAM CAPACITY   : $TotalRAM GB"
    Write-Output '================================================================================'
}

# 4. UNIVERSAL DISCOVERY
function Get-DefaultBrowserPath {
    if (-not $RunningOnLinux) {
        $RegPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\brave.exe",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe"
        )
        foreach ($Path in $RegPaths) { if (Test-Path $Path) { return (Get-ItemProperty -Path $Path)."(default)" } }
        return "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    } else {
        $Binaries = @("brave-browser", "google-chrome", "chromium-browser", "firefox", "microsoft-edge")
        foreach ($Bin in $Binaries) { $Path = (Get-Command $Bin -ErrorAction SilentlyContinue).Source; if ($Path) { return $Path } }
        return "xdg-open"
    }
}

function Get-PersistentCacheDir ($Url) {
    $CacheRoot = if (-not $RunningOnLinux) { "$env:LOCALAPPDATA\AnarchI\Cache" } else { "$HOME/.cache/anarchi" }
    $UrlHash = ([System.Security.Cryptography.SHA256]::Create()).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Url)) | ForEach-Object { $_.ToString("x2") } | Out-String
    $CachePath = Join-Path $CacheRoot ($UrlHash -replace "\s+","").Substring(0, 16)
    if (-not (Test-Path $CachePath)) { New-Item -ItemType Directory -Path $CachePath -Force | Out-Null }
    return $CachePath
}

# 5. PLUGIN SYSTEM
function Get-PluginsDir {
    $plugins = Join-Path (Split-Path $PSCommandPath) "plugins"
    if (-not (Test-Path $plugins)) { New-Item -ItemType Directory -Path $plugins -Force | Out-Null }
    return $plugins
}

function Import-Plugin {
    $pluginsDir = Get-PluginsDir
    $pluginFiles = Get-ChildItem -Path $pluginsDir -Filter "*.ps1" -File -ErrorAction SilentlyContinue
    $script:ANARCHI_PLUGINS = @()
    foreach ($p in $pluginFiles) {
        try {
            . $p.FullName
            $script:ANARCHI_PLUGINS += @{ Path = $p.FullName }
        } catch { Write-Warning "Failed to load plugin $($p.Name)" }
    }
}

function Invoke-PluginHook($hookName, $payload) {
    if (-not $script:ANARCHI_PLUGINS) { return }
    foreach ($pl in $script:ANARCHI_PLUGINS) {
        try { if (Get-Command -Name $hookName -ErrorAction SilentlyContinue) { & $hookName $payload } } catch {}
    }
}

# 6. RESOURCE ENGINE
function Invoke-SystemCull ($ProfileType) {
    Write-Output "`n[ANARCHI] Initializing Resource Cull..."
    if ($Global:StressTesting) { return }
    if (-not $RunningOnLinux) {
        Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
        net stop SysMain /y >$null 2>&1
        if ($ProfileType -eq "PROFILE_CORE_AGGRESSIVE") { Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue }
    } else {
        systemctl stop tracker-miner-fs-3.service >$null 2>&1
        if ($ProfileType -eq "PROFILE_CORE_AGGRESSIVE") { systemctl stop display-manager >$null 2>&1 }
    }
}

function Invoke-ResourceVirtualization ($ReqRAM, $ReqVRAM, $ApiKey) {
    Write-Output "`n[ANARCHI] Adjusting virtual hardware..."
    if ($Global:StressTesting) { return }
    $RamDeficit = $ReqRAM - $TotalRAM
    if ($RamDeficit -gt 0) {
        if (-not $RunningOnLinux) {
            Set-CimInstance -Query "Select * from Win32_ComputerSystem" -Property @{AutomaticManagedPagefile = $False} >$null 2>&1
            New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name="C:\pagefile.sys"; InitialSize=8192; MaximumSize=16384} -ErrorAction SilentlyContinue >$null
        } else {
            if (-not (Test-Path "/anarchi_swap")) {
                dd if=/dev/zero of=/anarchi_swap bs=1M count=8192 >$null 2>&1
                chmod 600 /anarchi_swap; mkswap /anarchi_swap >$null 2>&1; swapon /anarchi_swap >$null 2>&1
            }
        }
    }
}

function Invoke-TargetLaunch ($Target, $TotalRAM, $ReqRAM, $ReqVRAM, $ApiKey, $MaxHeap) {
    $IsUrl = $Target -like "http*"
    Invoke-PluginHook -hookName "OnPreLaunch" -payload @{ Target = $Target; IsUrl = $IsUrl }
    
    if ($IsUrl) {
        $BrowserPath = Get-DefaultBrowserPath
        $CachePath = Get-PersistentCacheDir $Target
        Write-Output "`n[EXECUTE] Launching Secure Browser -> $Target"
        
        if ($BrowserPath -like "*chrome*" -or $BrowserPath -like "*chromium*") {
            $browserArgs = @("--user-data-dir=$CachePath", "--js-flags=--max-old-space-size=$MaxHeap", "--app=$Target")
            Start-Process $BrowserPath -ArgumentList $browserArgs -ErrorAction SilentlyContinue
        } else {
            Start-Process $BrowserPath $Target -ErrorAction SilentlyContinue
        }
    } else {
        if (Test-Path $Target) {
            Write-Output "`n[EXECUTE] Launching App with Priority Boost -> $Target"
            $LaunchedApp = Start-Process $Target -PassThru -ErrorAction SilentlyContinue
            if ($LaunchedApp) {
                if (-not $RunningOnLinux) { (Get-Process -Id $LaunchedApp.Id).PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High }
                else { renice -n -15 -p $LaunchedApp.Id >$null 2>&1 }
            }
        }
    }
    Invoke-PluginHook -hookName "OnPostLaunch" -payload @{ Target = $Target }
}

# ==========================================
# MAIN CLI LOOP
# ==========================================
if (Test-Path $ConfigPath) {
    Show-Header
    $Config = Get-Content $ConfigPath | ConvertFrom-Json
    Import-Plugin
    Invoke-SystemCull $Config.system_preferences.default_execution_profile
    Invoke-TargetLaunch $Config.target_parameters.execution_vector $TotalRAM $Config.target_parameters.minimum_required_ram_gb $Config.target_parameters.minimum_required_vram_gb $Config.cloud_enclave_hooks.persistent_network_api_key $Config.system_preferences.chromium_js_heap_max_mb
    Write-Output "`n[SUCCESS] Environment locked."
    Pause; Exit
}

while ($true) {
    Show-Header
    Write-Output "  INITIALIZATION SELECTION:"
    Write-Output "  (1) STANDARD"
    Write-Output "  (2) AGGRESSIVE"
    Write-Output "  (3) RECOVERY"
    $Selection = Read-Host "Input [1-3]"
    
    if ($Selection -eq "3") {
        if (-not $RunningOnLinux) { net start SysMain >$null 2>&1 }
        else { systemctl start tracker-miner-fs-3.service >$null 2>&1 }
        Write-Output "Base reset complete."; Pause; Exit
    }
    
    if ($Selection -eq "1" -or $Selection -eq "2") {
        $TargetInput = Read-Host "Target (URL or Path)"
        $ReqRAM  = double")
        $ReqVRAM = double")
        $ApiKey  = Read-Host "API Key (Optional)"
        
        $ProfileName = if($Selection -eq "1") { "PROFILE_CORE_STANDARD" } else { "PROFILE_CORE_AGGRESSIVE" }
        
        $ConfigObject = @{
            target_parameters = @{ execution_vector = $TargetInput; minimum_required_ram_gb = $ReqRAM; minimum_required_vram_gb = $ReqVRAM }
            cloud_enclave_hooks = @{ persistent_network_api_key = $ApiKey }
            system_preferences = @{ default_execution_profile = $ProfileName; chromium_js_heap_max_mb = 3072 }
        }
        
        $ConfigObject | ConvertTo-Json -Depth 4 | Out-File -FilePath $ConfigPath -Force
        Import-Plugin
        Invoke-SystemCull $ProfileName
        Invoke-TargetLaunch $TargetInput $TotalRAM $ReqRAM $ReqVRAM $ApiKey 3072
        Pause; Exit
    }
}