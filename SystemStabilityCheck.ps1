[CmdletBinding()]
param (
    [UInt32]$Count = (24 * 7 * 4) 
)

# 1. Gather Reliability metrics
$StabilityMetrics = Get-CimInstance -ClassName Win32_ReliabilityStabilityMetrics -ErrorAction SilentlyContinue | Select-Object -First $Count

if (-not $StabilityMetrics) {
    return [PSCustomObject]@{
        Status   = "No Data"
        Summary  = "Reliability monitor data not available on this system."
    }
}

# 2. Generate Stats
$StabilityStats = $StabilityMetrics | Measure-Object -Average -Maximum -Minimum -Property SystemStabilityIndex
$LastMetric = $StabilityMetrics | Select-Object -First 1
$CurrentIndex = [math]::Round($LastMetric.SystemStabilityIndex, 2)

# 3. Define Health Status (using 'break' to prevent multiple values)
$Status = switch ($CurrentIndex) {
    { $_ -ge 9 } { "Excellent"; break }
    { $_ -ge 7 } { "Stable"; break }
    { $_ -ge 4 } { "Unstable"; break }
    Default      { "Critical" }
}

# 4. Output for PDQ Connect
[PSCustomObject]@{
    Status         = $Status
    CurrentIndex   = $CurrentIndex
    AverageIndex   = [math]::Round($StabilityStats.Average, 2)
    MinIndex       = [math]::Round($StabilityStats.Minimum, 2)
    LastUpdated    = [DateTime]$LastMetric.TimeGenerated
    Summary        = "System is $Status (Current: $CurrentIndex, Avg: $([math]::Round($StabilityStats.Average, 2)))"
}