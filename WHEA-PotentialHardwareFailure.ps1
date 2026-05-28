# Define lookback window
$DaysBack = 14
$StartDate = (Get-Date).AddDays(-$DaysBack)

$FilterHashtable = @{
    LogName      = 'System'
    ProviderName = 'Microsoft-Windows-WHEA-Logger'
    Level        = 1, 2 # Critical and Error
    StartTime    = $StartDate
}

# Check if any matching events exist without triggering a terminating error
if (Get-WinEvent -FilterHashtable $FilterHashtable -ErrorAction SilentlyContinue) {
    
    # Events found, pull and output them
    $Events = Get-WinEvent -FilterHashtable $FilterHashtable
    foreach ($Event in $Events) {
        [PSCustomObject]@{
            TimeCreated = $Event.TimeCreated
            EventID     = $Event.Id
            Level       = $Event.LevelDisplayName
            Component   = $Event.Message.Split("`r`n")[0]
            Details     = $Event.Message
        }
    }
} else {
    # No events found - return the clean "Healthy" status you want
    [PSCustomObject]@{
        TimeCreated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        EventID     = 0
        Level       = "Healthy"
        Component   = "No WHEA errors detected."
        Details     = "Hardware reporting normal for the last $DaysBack days."
    }
}