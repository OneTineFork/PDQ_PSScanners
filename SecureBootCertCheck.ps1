try {
    $dbBytes = (Get-SecureBootUEFI -Name db).Bytes
    $DB = ([System.Text.Encoding]::ASCII.GetString($dbBytes) -match 'Windows UEFI CA 2023')
} catch {
    $DB = $false
}

try {
    $kekBytes = (Get-SecureBootUEFI -Name KEK).Bytes
    $KEK = ([System.Text.Encoding]::ASCII.GetString($kekBytes) -match 'KEK 2K CA 2023')
} catch {
    $KEK = $false
}

try {
    $UEFICA2023Status = Get-ItemPropertyValue `
        -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing' `
        -Name 'UEFICA2023Status' `
        -ErrorAction Stop
} catch {
    $UEFICA2023Status = $null
}

try {
    $LastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
} catch {
    $LastBoot = $null
}

[PSCustomObject]@{
    DB                  = $DB
    KEK                 = $KEK
    UEFICA2023Status    = $UEFICA2023Status
    LastBoot            = $LastBoot
}