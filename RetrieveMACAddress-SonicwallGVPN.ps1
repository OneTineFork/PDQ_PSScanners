$adapter = Get-NetAdapter -IncludeHidden |
    Where-Object {
        $_.InterfaceDescription -match "SonicWall" -or
        $_.Name -match "SonicWall"
    } |
    Select-Object -First 1

if ($adapter) {
    [PSCustomObject]@{
        Name   = $adapter.Name
        Status = $adapter.Status
        MAC    = $adapter.MacAddress
    }
}
else {
    [PSCustomObject]@{
        Name   = "Not Found"
        Status = "N/A"
        MAC    = "N/A"
    }
}