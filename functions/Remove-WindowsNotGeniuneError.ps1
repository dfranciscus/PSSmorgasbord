#require -modules InvokeCommandAs
<#
.SYNOPSIS
    Fixes issue with Windows 7 showing non genuine caused by update kb971033
    Refernce - https://community.spiceworks.com/topic/2185234-kms-clients-windows-is-not-genuine
#>
function Remove-WindowsNotGeniuneError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    process {
        Invoke-CommandAs -ComputerName $ComputerName -ScriptBlock {
            wusa /uninstall /KB:971033 /quiet
        }
        Invoke-command -ComputerName $ComputerName -ScriptBlock {
            Stop-Service sppsvc -Verbose
            Remove-Item C:\Windows\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-0.C7483456-A289-439d-8115-601632D005A0 -Recurse -Force -Verbose
            Remove-Item C:\Windows\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-1.C7483456-A289-439d-8115-601632D005A0 -Recurse -Force -Verbose
            Remove-Item C:\Windows\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\tokens.dat -Force -Verbose
            Remove-Item C:\Windows\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\cache\cache.dat -Force -Verbose
            Start-Service sppsvc -Verbose
            C:\Windows\system32\slmgr /ckms
            C:\Windows\system32\slmgr /ato
            cscript C:\windows\system32\slmgr.vbs /dlv
        }
    }
}