
<#
.SYNOPSIS
Show user access to a given folder including showing users that are part of security groups
.DESCRIPTION
    Show user access to a given folder including showing users that are part of security groups
.EXAMPLE
C:\> Get-FolderAccess -Path '\\server\share\'

Name           Rights
----           ------
user1          Modify, Synchronize
user2          Modify, Synchronize
user3          Modify, Synchronize

#>
function Get-FolderAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [string]$Domain
    )

$ErrorActionPreference = "SilentlyContinue"
Get-NTFSAccess -Path $Path | Select-Object Account,AccessRights | ForEach-Object {
    $Account = $_.Account.AccountName.ToString().Replace("$Domain\",'')
    $Members = $NULL
    $Members = Get-ADGroupMember -Identity $Account -ErrorAction SilentlyContinue | Select-Object -ExpandProperty SamAccountName
    if ($Members) {
        $Users = foreach ($Member in $Members) {
            $UserAccess = (Get-NTFSEffectiveAccess -Path $Path -Account $Account).AccessRights.ToString()
            [PSCustomObject]@{
                Name = $Member
                Rights = $UserAccess
            }
        }
    }
    else {
       $UserAccess = (Get-NTFSEffectiveAccess -Path $Path -Account $Account).AccessRights.ToString()
       $Users = [PSCustomObject]@{
               Name = $Account
               Rights = $UserAccess
           }
       }
       $Users
    } | Sort-Object -Property Name -Unique
}

