# Define the lookback period and the error threshold per device
$DaysToLookBack = 7
$ErrorThreshold = 5
$StartTime = (Get-Date).AddDays(-$DaysToLookBack)

# Base Filter Hashtable for speed
$FilterHashtable = @{
    LogName   = 'Microsoft-Windows-Kernel-PnP/Operational'
    Id        = @(219, 400, 410)
    StartTime = $StartTime
    Level     = @(3, 4) # Warning and Information
}

try {
    # Fetch events efficiently
    $Events = Get-WinEvent -FilterHashtable $FilterHashtable -ErrorAction Stop
}
catch {
    # Catch log missing or empty log scenarios gracefully
    $Events = @()
}

$FlaggedDevices = @()

if ($Events) {
    # Parse the events safely
    $ParsedEvents = foreach ($Event in $Events) {
        try {
            $Xml = [xml]$Event.ToXml()
            $UserData = $Xml.Event.UserData.ChildNodes
            
            # Extract Device Instance ID and Name dynamically from the XML structure
            $DeviceInstanceId = ($UserData | Where-Object { $_.DeviceInstanceId }).DeviceInstanceId
            $DeviceName = ($UserData | Where-Object { $_.DeviceDescription -or $_.DeviceName })
            $DeviceNameString = if ($DeviceName.DeviceDescription) { $DeviceName.DeviceDescription } else { $DeviceName.DeviceName }

            if ($DeviceInstanceId) {
                [PSCustomObject]@{
                    TimeCreated      = $Event.TimeCreated
                    DeviceName       = if ($DeviceNameString) { $DeviceNameString } else { "Unknown USB Device" }
                    DeviceInstanceId = $DeviceInstanceId
                }
            }
        }
        catch {
            # Skip any individually malformed events
            continue
        }
    }

    # Group and filter based on threshold
    if ($ParsedEvents) {
        $FlaggedDevices = $ParsedEvents | 
            Group-Object DeviceInstanceId | 
            Where-Object { $_.Count -ge $ErrorThreshold } | 
            ForEach-Object {
                $Group = $_
                [PSCustomObject]@{
                    Status              = "Issue Detected"
                    GlitchesInLast7Days = $Group.Count
                    DeviceName          = $Group.Group[0].DeviceName
                    DeviceInstanceId    = $Group.Name
                    LastSeenGlitching   = ($Group.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1).TimeCreated
                }
            }
    }
}

# CRITICAL FOR PDQ: Always output an object so the scanner registers a clean run
if ($FlaggedDevices) {
    return $FlaggedDevices
} else {
    return [PSCustomObject]@{
        Status              = "Healthy"
        GlitchesInLast7Days = 0
        DeviceName          = "None"
        DeviceInstanceId    = "None"
        LastSeenGlitching   = (Get-Date)
    }
}