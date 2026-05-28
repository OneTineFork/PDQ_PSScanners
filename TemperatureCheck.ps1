# 1. SSD Temp - Pulling directly from the StorageReliabilityCounter with a filter
$SSD = Get-PhysicalDisk | Get-StorageReliabilityCounter | Select-Object -First 1
$SSD_Temp = if ($SSD.Temperature -gt 0) { $SSD.Temperature } else { "N/A" }

# 2. CPU Temp - Since MSAcpi is blocked, we use the "Intel/Dell" Throttling Check
# This looks for how much the CPU is being limited (%) due to heat
$ThrottlingPercent = (Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_PerfFormattedData_PerfOS_Processor | 
                     Where-Object {$_.Name -eq "_Total"}).PercentPerformanceLimit

# 3. Deep Dive into the 5 Events you found
# We want to know exactly what triggered the thermal trip
$Events = Get-WinEvent -FilterHashtable @{
    LogName='System'; 
    Id=11,86; 
    StartTime=(Get-Date).AddDays(-7)
} -ErrorAction SilentlyContinue | Select-Object -First 5 -ExpandProperty Message

[PSCustomObject]@{
    SSD_Current_C       = $SSD_Temp
    CPU_Throttled_Pct   = if($ThrottlingPercent) { 100 - $ThrottlingPercent } else { 0 }
    Critical_Events_7d  = ($Events | Measure-Object).Count
    Last_Event_Details  = if($Events) { $Events[0].Substring(0,100) + "..." } else { "None" }
    Manufacturer        = "Dell"
}