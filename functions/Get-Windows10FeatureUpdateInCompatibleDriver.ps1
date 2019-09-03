<#
.SYNOPSIS
    Find Windows 10 compatdata files and view drivers from Windows 10 feature update failures with PowerShell remoting. Idea from article https://4sysops.com/archives/feature-update-for-windows-10-failed-find-blocking-components/
.EXAMPLE
    Get-Windows10FeatureUpdateInCompadibleDriver -ComputerName test-1
#>
function Get-Windows10FeatureUpdateInCompatibleDriver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        if (Get-ChildItem 'C:\$WINDOWS.~BT\sources\Panther\CompatData*.xml' -ErrorAction SilentlyContinue){
            Get-ChildItem 'C:\$WINDOWS.~BT\sources\Panther\CompatData*.xml' | Select-String 'BlockMigration="True"' | Select-Object -ExpandProperty Line | ForEach-Object {
                Get-WindowsDriver -Driver ($_.Split('"')[1]) -Online
            }
        }
        else {
            "No CompatData files for $Env:ComputerName"
        }
    }
}
