# 1. Check UEFI db Certificate
$dbObj = Get-SecureBootUEFI -Name db -ErrorAction SilentlyContinue 2>$null
$DB = if ($dbObj) { [System.Text.Encoding]::ASCII.GetString($dbObj.Bytes) -match 'Windows UEFI CA 2023' } else { $false }

# 2. Check UEFI KEK Certificate
$kekObj = Get-SecureBootUEFI -Name KEK -ErrorAction SilentlyContinue 2>$null
$KEK = if ($kekObj) { [System.Text.Encoding]::ASCII.GetString($kekObj.Bytes) -match 'KEK 2K CA 2023' } else { $false }

# 3. Verify Registry Path Existence
$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing'
$keyExists = Test-Path $regPath -ErrorAction SilentlyContinue

# 4. Fetch Registry Values safely
$UEFICA2023Status = if ($keyExists) { Get-ItemPropertyValue -Path $regPath -Name 'UEFICA2023Status' -ErrorAction SilentlyContinue 2>$null } else { $null }
$UEFICA2023Error  = if ($keyExists) { Get-ItemPropertyValue -Path $regPath -Name 'UEFICA2023Error' -ErrorAction SilentlyContinue 2>$null } else { $null }

# 5. Get Last Boot Time
$osObj = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue 2>$null
$LastBoot = if ($osObj) { $osObj.LastBootUpTime } else { $null }

# 6. Output Results
[PSCustomObject]@{
    DB                  = $DB
    KEK                 = $KEK
    UEFICA2023Status    = $UEFICA2023Status
    UEFICA2023Error     = $UEFICA2023Error
    LastBoot            = $LastBoot
}
