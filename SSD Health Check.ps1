try {
    Import-Module Storage -ErrorAction Stop

    $results = Get-PhysicalDisk |
        Get-StorageReliabilityCounter |
        Select-Object DeviceId, Wear, ReadErrorsTotal, WriteErrorsTotal

    if ($results) {
        return $results
    }
    else {
        return "No reliability data"
    }
}
catch {
    return "Error: $($_.Exception.Message)"
}