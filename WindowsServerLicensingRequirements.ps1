# Detect if VM
$cs = Get-CimInstance Win32_ComputerSystem
if ($cs.Model -match "Virtual|VMware|Hyper-V") {
    return  # Skip VMs entirely
}

# CPU / core data
$cpu = Get-CimInstance Win32_Processor
$PhysicalCores = ($cpu | Measure-Object -Property NumberOfCores -Sum).Sum
$Sockets = @($cpu).Count

# Apply licensing minimums
$MinCoresPerCPU = 8
$MinCoresPerServer = 16

$AdjustedCores = $PhysicalCores

# Server minimum
if ($AdjustedCores -lt $MinCoresPerServer) {
    $AdjustedCores = $MinCoresPerServer
}

# Per-socket minimum
$MinBySocket = $Sockets * $MinCoresPerCPU
if ($AdjustedCores -lt $MinBySocket) {
    $AdjustedCores = $MinBySocket
}

# VM count (Hyper-V only)
$VMCount = 0
if (Get-Command Get-VM -ErrorAction SilentlyContinue) {
    # Silently suppress errors if the cmdlet exists but fails due to permissions or service status
    $vms = Get-VM -ErrorAction SilentlyContinue
    
    if ($null -ne $vms) {
        $VMCount = @($vms).Count
    } elseif ($Host.Name -and $LASTEXITCODE -ne 0) {
        # If the command failed entirely, mark as unable to query
        $VMCount = -1
    }
}

# Licensing math (Standard Edition assumption)
$VMsPerLicenseSet = 2

if ($VMCount -le 0) {
    $LicenseSets = 1
} else {
    $LicenseSets = [math]::Ceiling($VMCount / $VMsPerLicenseSet)
}

$TotalCoreLicenses = $AdjustedCores * $LicenseSets

# Datacenter heuristic (optional)
$DatacenterCandidate = $VMCount -ge 6

# Output
[PSCustomObject]@{
    DeviceName           = $env:COMPUTERNAME
    PhysicalCores         = $PhysicalCores
    AdjustedCores         = $AdjustedCores
    SocketCount           = $Sockets
    RunningVMs            = $VMCount
    LicenseSetsRequired   = $LicenseSets
    TotalCoreLicenses     = $TotalCoreLicenses
    DatacenterCandidate   = $DatacenterCandidate
}