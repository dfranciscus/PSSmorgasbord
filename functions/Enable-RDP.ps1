<#
.SYNOPSIS
    Enable Remote Desktop remotely
.EXAMPLE
    Enable-RDP -ComputerName test-1
#>
function Enable-RDP {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName,
        [string]$UserName
    )
    process {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
            Netsh advfirewall firewall set rule group='remote desktop' new enable=yes
        }
    }
}