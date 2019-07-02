<#
.SYNOPSIS
    Disable Remote Desktop remotely
.EXAMPLE
    Disable-RDP -ComputerName test-1
#>
function Disable-RDP {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )

    process {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 1
        Netsh advfirewall firewall set rule group='remote desktop' new enable=no
        }
    }
}