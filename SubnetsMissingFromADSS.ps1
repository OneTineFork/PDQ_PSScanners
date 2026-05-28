$logPath = "$env:SystemRoot\debug\netlogon.log"

if (-not (Test-Path $logPath)) {
    [PSCustomObject]@{
        Timestamp = $null
        IPAddress = $null
        Subnet    = $null
        Status    = "Log not found"
    }
    return
}

$results = @()

# Read tail
$lines = Get-Content $logPath -Tail 2000

# Reverse manually (PS 5.1 compatible)
[array]::Reverse($lines)

foreach ($line in $lines) {

    if ($line -match "NO_CLIENT_SITE") {

        $ip = $null
        $subnet = $null

        if ($line -match "(\d{1,3}\.){3}\d{1,3}") {
            $ip = $Matches[0]

            $octets = $ip.Split(".")
            if ($octets.Count -eq 4) {
                $subnet = "$($octets[0]).$($octets[1]).$($octets[2]).0/24"
            }
        }

        $timestamp = ($line -split "\s+")[0,1] -join " "

        $results += [PSCustomObject]@{
            Timestamp = $timestamp
            IPAddress = $ip
            Subnet    = $subnet
        }
    }

    if ($results.Count -ge 100) { break }
}

# ✅ Stream properly formatted rows to PDQ
if ($results.Count -gt 0) {
    $results | Select-Object Timestamp, IPAddress, Subnet
}
else {
    [PSCustomObject]@{
        Timestamp = $null
        IPAddress = $null
        Subnet    = $null
        Status    = "No matches found"
    }
}