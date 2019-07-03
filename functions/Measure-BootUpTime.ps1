<#
.SYNOPSIS
    Measure Bootup time remotely by rebooting machine and waiting for connectivity through WMI
#>
function Measure-BootUpTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    process {
        Try {
            $Time = Measure-Command {
                Restart-Computer -ComputerName $ComputerName -Wait -For powershell -Timeout 1200 -ErrorAction Stop
            } | Select-Object -ExpandProperty TotalMinutes
            $RoundedTime = [math]::Round($Time,2)
            [PSCustomObject]@{
                ComputerName = $ComputerName
                Time = $RoundedTime
          }
        }
        catch {
            Write-Output "$ComputerName failed"
            $ErrorMessage = $_.Exception.Message
            $ErrorMessage
        }
    }
}