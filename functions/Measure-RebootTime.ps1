#requires -modules PoshRSJob
function Measure-RebootTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName
    )
    $ComputerName | Start-RSJob -ScriptBlock {Get-RebootTime -ComputerName $_ } -Throttle 150 | Wait-RSJob | Get-RSJob | Receive-RSJob | select-object *
}
