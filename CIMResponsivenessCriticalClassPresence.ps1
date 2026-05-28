$errors = @()

$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
if (-not $os) { $errors += "CIM Win32_OperatingSystem failed" }

$netIpClass = Get-CimClass -Namespace root/StandardCimv2 -ClassName MSFT_NetIPAddress -ErrorAction SilentlyContinue
if (-not $netIpClass) { $errors += "Missing/broken MSFT_NetIPAddress in root/StandardCimv2" }

[pscustomobject]@{
  Check  = "CIM_CoreAndNetTCPIP"
  Status = if ($errors.Count -eq 0) { "OK" } elseif (-not $netIpClass) { "FAIL" } else { "WARN" }
  Detail = if ($errors.Count -eq 0) { "CIM OK; NetTCPIP classes present." } else { ($errors -join " | ") }
}
