# Define the events we are hunting for
$Queries = @(
    @{ LogName = 'System'; Id = 26 },
    @{ LogName = 'System'; Id = 50 },
    @{ LogName = 'Microsoft-Windows-Resource-Exhaustion-Detector/Operational'; Id = 1201 },
    @{ LogName = 'Microsoft-Windows-Resource-Exhaustion-Detector/Operational'; Id = 1202 }
)

$Results = foreach ($Q in $Queries) {
    try {
        # Look back 7 days to keep scan times fast and data relevant
        Get-WinEvent -FilterHashtable @{
            LogName   = $Q.LogName
            Id        = $Q.Id
            StartTime = (Get-Date).AddDays(-7)
        } -ErrorAction SilentlyContinue | ForEach-Object {
            [PSCustomObject]@{
                TimeCreated = $_.TimeCreated
                EventID     = $_.Id
                LogName     = $_.LogName
                Message     = $_.Message -replace "`r`n", " " # Flattens message for easier reading in PDQ
                Source      = $_.ProviderName
            }
        }
    } catch {
        # Explicitly ignore logs that don't exist on older OS versions
    }
}

if ($Results) {
    $Results | Sort-Object TimeCreated -Descending
} else {
    # Keeps PDQ happy by returning an empty structure if clean
    [PSCustomObject]@{
        TimeCreated = "N/A"
        EventID     = "None"
        LogName     = "None"
        Message     = "No corruption or resource exhaustion events found in the last 7 days."
        Source      = "None"
    }
}