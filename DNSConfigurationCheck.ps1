$ErrorActionPreference = 'Stop'

try {
    $rows = @()

    # Pre-fetch NIC configs for DHCP + IP info
    $nicConfigs = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True"

    $adapters = Get-DnsClientServerAddress -AddressFamily IPv4 |
        Where-Object { $_.ServerAddresses -and $_.ServerAddresses.Count -gt 0 }

    foreach ($a in $adapters) {
        $sa  = @($a.ServerAddresses)
        $nic = $nicConfigs | Where-Object { $_.InterfaceIndex -eq $a.InterfaceIndex }

        # Filter to IPv4 only (exclude anything with a colon, i.e. IPv6)
        $ipv4 = if ($nic -and $nic.IPAddress) {
            @($nic.IPAddress | Where-Object { $_ -notmatch ':' })
        } else { @() }

        $rows += [PSCustomObject]@{
            InterfaceAlias = $a.InterfaceAlias
            InterfaceIndex = $a.InterfaceIndex
            IPv4Address    = if ($ipv4.Count -gt 0) { $ipv4[0] } else { $null }
            AllIPv4        = if ($ipv4.Count -gt 0) { $ipv4 -join ', ' } else { $null }
            DHCPEnabled    = if ($nic) { $nic.DHCPEnabled } else { $null }
            DHCPServer     = if ($nic) { $nic.DHCPServer } else { $null }
            PrimaryDNS     = $sa[0]
            SecondaryDNS   = if ($sa.Count -ge 2) { $sa[1] } else { $null }
            AllDNS         = ($sa -join ', ')
            DnsCount       = $sa.Count
        }
    }

    # IMPORTANT: Always return at least one object with the same columns
    if ($rows.Count -eq 0) {
        [PSCustomObject]@{
            InterfaceAlias = $null
            InterfaceIndex = $null
            IPv4Address    = $null
            AllIPv4        = $null
            DHCPEnabled    = $null
            DHCPServer     = $null
            PrimaryDNS     = $null
            SecondaryDNS   = $null
            AllDNS         = $null
            DnsCount       = 0
        }
    }
    else {
        $rows
    }
}
catch {
    # Still return an object (consistent schema) so validation doesn't choke
    [PSCustomObject]@{
        InterfaceAlias = $null
        InterfaceIndex = $null
        IPv4Address    = $null
        AllIPv4        = $null
        DHCPEnabled    = $null
        DHCPServer     = $null
        PrimaryDNS     = $null
        SecondaryDNS   = $null
        AllDNS         = "ERROR: $($_.Exception.Message)"
        DnsCount       = -1
    }
}