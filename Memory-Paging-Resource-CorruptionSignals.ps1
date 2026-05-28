# Define the events we are hunting for
$Queries = @(
    @{ LogName = 'System'; Id = 26 },
    @{ LogName = 'System'; Id = 50 },
    @{ LogName = 'Microsoft-Windows-Resource-Exhaustion-Detector/Operational'; Id = 1201 },
    @{ LogName = 'Microsoft-Windows-Resource-Exhaustion-Detector/Operational'; Id = 1202 }
)

# Loop through queries and gather results
$Results = foreach ($Q in $Queries) {
    # -ErrorAction SilentlyContinue safely ignores missing logs or empty queries
    Get-WinEvent -FilterHashtable @{
        LogName   = $Q.LogName
        Id        = $Q.Id
        StartTime = (Get-Date).AddDays(-7)
    } -ErrorAction SilentlyContinue | ForEach-Object {
        [PSCustomObject]@{
            TimeCreated = $_.TimeCreated
            EventID     = $_.Id
            LogName     = $_.LogName
            Message     = $_.Message -replace "`r`n", " " # Flattens message for PDQ
            Source      = $_.ProviderName
        }
    }
}

# Output results if found, otherwise output a schema-friendly "All Clear" status
if ($Results) {
    $Results | Sort-Object TimeCreated -Descending
} else {
    [PSCustomObject]@{
        TimeCreated = (Get-Date)  # Keeps the column typed as a Date/Time in PDQ (acts as Scan Time)
        EventID     = 0           # Keeps the column typed as an Integer
        LogName     = 'Status'
        Message     = 'No disk corruption or resource exhaustion events found in the last 7 days.'
        Source      = 'PDQ Scanner'
    }
}
