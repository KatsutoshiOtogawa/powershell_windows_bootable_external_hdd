
function set-windows_multiboot_disk {
    #Requires -Version 7 -RunAsAdministrator
    #Requires -Modules Storage
    [CmdletBinding()]
    param (
        # UseMaximumSize
        [Parameter(
            Mandatory = $False
            , HelpMessage = "Specifies the size of the partition to create. If not specified, then the units will default to Bytes . The acceptable value for this parameter is a positive number followed by the one of the following unit values: Bytes ,KB , MB , GB , or TB ."
        )]
        [UInt64[]]$Size,

        [Parameter(
            Mandatory = $False
            ,HelpMessage = "Leave disk space."
        )]
        [Switch]$LeaveCapacity,

        [Parameter(
            Mandatory = $False
            ,HelpMessage = "パーティションがひとつのみの場合"
        )]
        [Switch]$UseSingleMaximumSize,
        [Parameter(
            Mandatory = $False
        )]
        [Switch]$PassThru
        
    )
    Set-Variable ErrorActionPreference -Scope local -Value "Stop"
    # 使い方の例
    # set-windows_format -Size @(50GB,60GB,70GB) -LeaveCapacity -PassThru
    # set-windows -Size @(50GB) -Leavecapacity
    # シングルブートのみでとりあえず空き領域全部使いたい場合
    # set-windows -UseSingleMaximumSize

    if ($UseSingleMaximumSize) {
        if ($LeaveCapacity -or (1 -le $Size.Count)) {
            Write-Error "UseSingle or at the same time"
        }
    } elseif (0 -eq $Size.Count -or $null -eq $Size){
        Write-Error "Size flag assigned value"
    }

    class DiskDriveLetter {
        [string] $BootDriverLetter
        [string[]] $WindowsDriveLetter
    }
    Set-Variable efi -Scope local -Value "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"
    Set-Variable recovery -Scope local -Value "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}"

    # ディスク確認
    Get-Disk | Set-Variable disk_list -Scope local

    # ディスク選択
    New-Variable Disk -Scope local
    while ($true) {
        try {
            Write-Output $disk_list | Out-Host
            read-host "Select index for iniliaze disk installing windows?" | Set-Variable DiskNum -Scope local
            # ディスク存在確認なかったらループ
            Get-disk $DiskNum | Set-Variable Disk
            break;
        }catch{
            $error[0] | Write-Error
        }
    }
    # ディスク初期化処理
    try {
        # onlineにしとく。しないとディスクを変更できない。
        Write-Output $Disk | Set-Disk -IsOffline $false 
        # Initializeでいい感じの予約領域のパーティションを作ってくれる。
        Write-Output $Disk |
            Clear-Disk -Confirm:$false -RemoveData -PassThru |
            Initialize-Disk
    }catch{
        $error[0] | Write-Error
    }

    try {

        # system領域(Bootローダーをインストールする領域)
        Write-Output $Disk |
            New-Partition -Size 500MB -GptType $efi -AssignDriveLetter |
            Format-Volume -FileSystem FAT32 -NewFileSystemLabel "SYSTEM" |
            Select-Object -ExpandProperty DriveLetter |
            Set-Variable BootDriveLetter -Scope local -Option Constant

        # 回復パーティション
        Write-Output $Disk |
            New-Partition -Size 500MB -GptType $recovery |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel "Recovery patition" |
            Out-Null

        # Windowsドライブ
        if ($UseSingleMaximumSize) {

            Write-Output $Disk | 
                New-Partition -UseMaximumSize -AssignDriveLetter |
                Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" |
                Select-Object -ExpandProperty DriveLetter |
                Set-Variable SingleWindowsDriveLetter -Scope local -Option Constant

            Set-Variable WindowsDriveLetter -Scope local -Value @($SingleWindowsDriveLetter) -Option Constant

        } else {

            Write-Output $Size | 
                ForEach-Object {
                    Write-Output $Disk | 
                        New-Partition -Size $_ -AssignDriveLetter
                } -End {
                    if(-not $LeaveCapacity){
                        Write-Output $Disk | 
                            New-Partition -UseMaximumSize -AssignDriveLetter
                    }
                } |
                ForEach-Object {
                    Write-Output $_ | 
                        Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" |
                        Select-Object -ExpandProperty DriveLetter 
                } |
                Set-Variable WindowsDriveLetter -Scope local -Option Constant
        }

        if ($PassThru) {
            New-Object DiskDriveLetter -Property @{BootDriverLetter=$BootDriveLetter; WindowsDriveLetter= $WindowsDriveLetter }
        }
    } catch {
        $error[0] | Write-Error

    }
}
