
function set-windows_format {
    #Requires -Version 7 -RunAsAdministrator
    #Requires -Modules Storage
    [CmdletBinding()]
    param (
        # UseMaximumSize
        [Parameter(Mandatory = $False)]
        [String]$UseSize = "-UseMaximumSize"
    )
    # -UseMaximumSizeか -Size か強制
    Set-Variable -Name UseSize -Scope local -Value "-UseMaximumSize" -Option Constant
    # -Size 500MB
    Set-Variable ErrorActionPreference -Scope local -Value "Stop"
    # use debugging
    # Set-StrictMode -Version 7.2
    # debugオプションのときにつける。
    # version指定も
    # Set-StrictMode -Version 7.2

    Set-Variable -Name efi -Scope local -Value "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -Option Constant
    Set-Variable -Name preseve -Scope local -Value "{e3c9e316-0b5c-4db8-817d-f92df00215ae}" -Option Constant
    Set-Variable -Name recovery -Scope local -Value "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}" -Option Constant

    # ディスク確認
    Get-Disk | Set-Variable disk_list -Scope local

    # ディスク選択
    New-Variable Disk -Scope local
    while ($true) {
        try {
            Write-Output $disk_list
            read-host "Select index for iniliaze disk installing windows?" | Set-Variable DiskNum -Scope local
            # ディスク存在確認なかったらループ
            Get-disk $DiskNum | Set-Variable Disk
            break;
        }catch{
            Write-Host "Select Existing disk in system."

        }
    }
    # ディスク初期化処理
    try {
        # $offlineにしとく。しないとディスクを変更できない。
        Write-Output $Disk | Set-Disk -IsOffline $false 
        Write-Output $Disk |
            Clear-Disk -Confirm:$false -RemoveData -PassThru |
            Initialize-Disk
    }catch{
        Write-Host "Cannot Format Disk"
    }

    try {

        # disk partition type 決定
        Write-Output $Disk |
            New-Partition -Size 500MB -GptType $efi -AssignDriveLetter |
            Format-Volume -FileSystem FAT32 -NewFileSystemLabel "SYSTEM" |
            Select-Object -ExpandProperty DriveLetter |
            Set-Variable BootDriveLetter -Scope local -Option Constant

        # 予約領域 (パーティションは勝手にされる。)
        Write-Output $Disk |
            New-Partition -Size 16MB -GptType $preserve

        # 回復パーティション
        Write-Output $Disk |
            New-Partition -Size 500MB -GptType $recovery |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel "Recovery patition"

        # Root filesystem.
        # usemaximum sizeを -size 500MBみたいにかけるようにする。
        # もっとパーティション分けたい場合は手動
        Write-Output $Disk |
            New-Partition $UseSize -AssignDriveLetter |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" |
            Set-Variable RootDriveLetter -Scope local -Option Constant

        # dual boot 以上の場合
        #

        # 連想配列で返す。
        return @{BootDriverLetter=$BootDriveLetter; RootDriveLetter= $RootDriveLetter }
    } catch {

    }
}

function copy_windows_image {
    #Requires -Version 7 -RunAsAdministrator
    #Requires -Modules Dism, Storage
    # 取り出す適菜名前にする。
    Set-Variable ErrorActionPreference -Scope local -Value "Stop"
    # use debugging
    # Set-StrictMode -Version 7.2

    Set-Variable -Name windowsIsoPath -Scope local -Value "C:\windows.iso" -Option Constant
    Set-Variable -Name destination -Scope local -Value "C:\Users\Administrator\" -Option Constant

    try {

        # windows iso fileをマウントしてやる。
        Resolve-Path $windowsIsoPath |
        Mount-DiskImage |
            Get-Volume |
            Select-Object -ExpandProperty DriveLetter |
            Set-Variable MountDriveLetter -Scope local -Option Constant

        Copy-Item "${MountDriveLetter}:\sources\install.wim" -Destination $destination
    } finally {

       # マウント解除
       # アンマウント済みでもエラーにならないのでとりあえず四読
       Resolve-Path $windowsIsoPath |
       DisMount-DiskImage | Out-Null
    }
}

function set-windows_Image {
    #Requires -Version 7 -RunAsAdministrator
    #Requires -Modules Dism
    # 取り出す適菜名前にする。
    Set-Variable ErrorActionPreference -Scope local -Value "Stop"
    # use debugging
    # Set-StrictMode -Version 7.2

    Set-Variable -Name image_path -Scope local -Value "C:\Users\Administrator\sources\install.wim" -Option Constant
    New-Variable windows_list -Scope local
    try {
        # image info image indexを調べる
        Get-WindowsImage -ImagePath $image_path |
            Set-Variable windows_list
    } catch {

        # imageがなかったらここで終わる
        return;
    }
    New-Variable select_windows -Scope local
    while ($true){

        try {
            Write-Output $windows_list
            Read-Host "Select index for windows image index?" |
                Set-Variable indexNum -Scope local
            # Image存在確認なかったらループ
            Get-WindowsImage -ImagePath $image_path -Index $indexNum |
                Set-Variable select_windows
            break;
        }catch{
            Write-Host "Select Existing windows image."

        }
    }
    try {

        # input from external
        Write-Output $select_windows |
            Expand-WindowsImage -ApplyPath "${RootDriveLetter}:\" 
        # Expand-WindowsImage -ImagePath ${MountDriveLetter}:\sources\install.wim -Index $IndexNum -ApplyPath ${RootDriveLetter}:\

        # set up for booting partition. 
        # Write-Host "${RootDriveLetter}:\Windows\System32\bcdboot.exe ${RootDriveLetter}:\Windows /s ${BootDriveLetter}: /f UEFI"

        Start-Process "${RootDriveLetter}:\Windows\System32\bcdboot.exe" `
            -ArgumentList "${RootDriveLetter}:\Windows",/s,"${BootDriveLetter}:",/f,UEFI `
            -Confirm 
        # Invoke-expression "${RootDriveLetter}:\Windows\System32\bcdboot.exe ${RootDriveLetter}:\Windows /s ${BootDriveLetter}: /f UEFI" 
    }catch{

    }
}

# function set-windows_Image {
#     Set-Variable ErrorActionPreference -Scope local -Value "Stop"

#     if ($PSVersionTable.PSVersion.Major -lt 7 -or $PSVersionTable.OS -notmatch "Windows") {

#         Write-Error -Category ResourceUnavailable -Message "required PSversion grater than 7 and OS is Windows"
#     }

#     Set-Variable -Name windowsIsoPath -Scope local -Value "C:\windows.iso" -Option Constant

#     New-Variable MountDriveLetter -Scope local
#     try {

#         # windows iso fileをマウントしてやる。
#         Resolve-Path $windowsIsoPath |
#         Mount-DiskImage |
#             Get-Volume |
#             Select-Object -ExpandProperty DriveLetter |
#             Set-Variable MountDriveLetter
#         New-Variable windows_list -Scope local

#         try {
#             # image info image indexを調べる
#             Get-WindowsImage -ImagePath "${MountDriveLetter}:\sources\install.wim" |
#                 Set-Variable windows_list
#         } catch {

#             # try catchの入れ子になるので避けたい。
#             return;
#         }
#         New-Variable select_windows -Scope local
#         while ($true){

#             try {
#                 Write-Output $windows_list
#                 Read-Host "Select index for windows image index?" |
#                     Set-Variable indexNum -Scope local
#                 # Image存在確認なかったらループ
#                 Get-WindowsImage -ImagePath "${MountDriveLetter}:\sources\install.wim" -Index $indexNum |
#                     Set-Variable select_windows
#                 break;
#             }catch{
#                 Write-Host "Select Existing windows image."

#             }
#         }
#         try {

#             # input from external
#             Write-Output $select_windows |
#                 Expand-WindowsImage -ApplyPath "${RootDriveLetter}:\" 
#             # Expand-WindowsImage -ImagePath ${MountDriveLetter}:\sources\install.wim -Index $IndexNum -ApplyPath ${RootDriveLetter}:\

#             # set up for booting partition. 
#             # Write-Host "${RootDriveLetter}:\Windows\System32\bcdboot.exe ${RootDriveLetter}:\Windows /s ${BootDriveLetter}: /f UEFI"

#             Start-Process "${RootDriveLetter}:\Windows\System32\bcdboot.exe" `
#                 -ArgumentList "${RootDriveLetter}:\Windows",/s,"${BootDriveLetter}:",/f,UEFI `
#                 -Confirm 
#             # Invoke-expression "${RootDriveLetter}:\Windows\System32\bcdboot.exe ${RootDriveLetter}:\Windows /s ${BootDriveLetter}: /f UEFI" 
#         }catch{

#         }
#     } finally {

#         # マウント解除
#         # アンマウント済みでもエラーにならないのでとりあえず四読
#         Resolve-Path $windowsIsoPath |
#         DisMount-DiskImage | Out-Null
#     }
# }
