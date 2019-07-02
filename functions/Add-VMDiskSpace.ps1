
<#
.SYNOPSIS
    Add disk space to a VMware Windows VM in vCenter
.EXAMPLE
    Add-VMDiskSpace -VM test-1 -IncreaseSpaceGB 10
#>
function Add-VMDiskSpace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$VM,
        [Parameter(Mandatory=$true)]
        [string]$IncreaseSpaceGB,
        [Parameter(Mandatory=$true)]
        [string]$vCenterServer
    )

    process {
        Write-Output 'Connecting to vcenter'
        Connect-VIServer $vCenterServer | Out-Null

        #See if any disk is same size and if so exit
        $AllDisks = Get-VM $VM | ForEach-Object {$_.Guest.Disks} | Select-Object CapacityGB | Measure-Object | Select-Object count
        $UniqueDisks = Get-VM $VM | ForEach-Object {$_.Guest.Disks} | Select-Object CapacityGB -Unique  | Measure-Object | Select-Object count
        if ($AllDisks.Count -ne $UniqueDisks.Count) {
            Write-Output "VM has more disks that are the same size. Exiting"
            Return
        }

        #Get VM hard disks
        $HardDisks = Get-HardDisk -VM $VM | Select-Object name,capacitygb,parent

        #Get VM guest hard disks
        $Disks = Get-VM $VM | ForEach-Object {$_.Guest.Disks | ForEach-Object {
            $GuestCapacity = [math]::Round($_.CapacityGB)
            $HardDiskLabel = ''

            #Match Hard Disk with Guest Disk based on size rounded
            ForEach ($HardDisk in $HardDisks) {
                $HardDiskCapacity = [math]::Round($HardDisk.CapacityGB)
                If ($GuestCapacity -like $HardDiskCapacity) {
                    $HardDiskLabel = $HardDisk.Name
                }
            }
        #Create hashtable of each pipeline object
        $_ | Select-Object -Property Path,@{
                Name='CapacityGB';Expression={[math]::Round($_.CapacityGB)}},@{
                Name='FreeSpaceGB';Expression={[math]::Round($_.FreespaceGB)}},@{
                    Name='HardDiskName';Expression={$HardDiskLabel}},@{
                        Name='VM';Expression={$VM}
                    }
                }
            }
                Write-Output 'Disks available:'
                $Disks | Format-Table -Autosize

                #Type in hard disk name exactly to increase
                $HardDiskChoice = Read-Host -Prompt "**Specify hard disk by name to resize**"
                #Match answer to prompt with disk
                $Drive = ($Disks | Where-Object {$_.HardDiskName -eq $HardDiskChoice}).Path.Replace(':\','')
                if (!$Drive) {
                    Write-Verbose -Message 'Something went wrong while selecting drive letter'
                    Return
                }
                else {
                    Write-Verbose "$Drive letter selected to resize"
                }

                #Get current size of disk and increase it
                $Size = Get-HardDisk -Name $HardDiskChoice -VM $VM | Select-Object -ExpandProperty CapacityGB
                Write-Output  'Adding VM hard disk size'
                Get-HardDisk -Name $HardDiskChoice -VM $VM | Set-HardDisk -CapacityGB ($Size + $IncreaseSpaceGB) -Confirm:$False | Select-Object Parent,Name,CapacityGB | Format-Table -AutoSize

                #Remote into Windows computer
                Invoke-Command -ComputerName $VM -ArgumentList $Drive -ScriptBlock {
                    #"Rescan" shows the new increased drive in the Windows OS
                    "rescan" | diskpart | Out-Null
                    #Get supported size and then increase to max
                    Write-Output '**Resizing Windows partition'
                    $size = (Get-PartitionSupportedSize -DriveLetter $Using:Drive)
                    Resize-Partition -DriveLetter $Using:Drive -Size $size.SizeMax -Confirm:$False
                    Write-Output "**New Size for $Using:Drive"
                    Get-Partition -DriveLetter $Using:Drive | Select-Object Driveletter,@{Name="New Disk Size"; Expression={[math]::Round($_.Size/1GB)}} | Format-Table -AutoSize
                }
                Disconnect-VIServer -Confirm:$False
            }

}
