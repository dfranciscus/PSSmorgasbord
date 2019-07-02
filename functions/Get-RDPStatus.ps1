<#
.SYNOPSIS
    View Remote Desktop status remotely
.EXAMPLE
    Get-RDPStatus -ComputerName test-1
#>
function Get-RDPStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )
    process {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            if ((Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' | Select-Object -Expand fDenyTSConnections) -eq 0){
                $Registry = 'Open'
            }
            else {
                $Registry = 'Closed'
            }
            if (netstat -ab | Select-String -Pattern '0.0.0.0:3389'){
                $Firewall = 'Open'
            }
            else{
                $Firewall = 'Closed'
            }

            [PSCustomObject]@{
                ComputerName = $Env:COMPUTERNAME
                Registry = $Registry
                Firewall = $Firewall
              }
        } | Select-Object ComputerName,Registry,Firewall
    }
}