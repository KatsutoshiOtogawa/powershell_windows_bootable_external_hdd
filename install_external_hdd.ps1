
function set-windows_format {
    #Requires -Version 7 -RunAsAdministrator
    #Requires -Modules Storage
    [CmdletBinding()]
    param (
        # UseMaximumSize
        [Parameter(
            Mandatory = $False
            , HelpMessage = "Specifies the size of the partition to create. If not specified, then the units will default to Bytes . The acceptable value for this parameter is a positive number followed by the one of the following unit values: Bytes ,KB , MB , GB , or TB ."
        )]
        [UInt64]$Size = 0,

        [Parameter(
            Mandatory = $False
            ,HelpMessage = "Creates the largest possible partition on the specified disk."
        )]
        [Switch]$UseMaximumSize
    )
    Set-Variable ErrorActionPreference -Scope local -Value "Stop"
    # -UseMaximumSizeとSize両方を選んだ場合はUseMaximumSize優先
    # もっとパーティション分けたい場合は手動

    if ($Size -eq 0 -and -not $UseMaximumSize) {
        Write-Error -Message "You must specify a size by using either the Size or the UseMaximumSize parameter. You can specify only one of these parameters at a time." `
                    -Category InvalidArgument
    }

    Set-Variable efi -Scope local -Value "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"
    Set-Variable recovery -Scope local -Value "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}"

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
        # onlineにしとく。しないとディスクを変更できない。
        Write-Output $Disk | Set-Disk -IsOffline $false 
        # Initializeでいい感じの予約領域のパーティションを作ってくれる。
        Write-Output $Disk |
            Clear-Disk -Confirm:$false -RemoveData -PassThru |
            Initialize-Disk
    }catch{
        Write-Host "Cannot Format Disk"
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

        Write-Output $Disk |
            ForEach-Object {
                if($UseMaximumSize){
                    $_ | New-Partition -UseMaximumSize -AssignDriveLetter
                }else{
                    $_ | New-Partition -Size $Size -AssignDriveLetter
                }
            } |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" |
            Select-Object -ExpandProperty DriveLetter |
            Set-Variable RootDriveLetter -Scope local -Option Constant

        # 連想配列で返す。
        return @{BootDriverLetter=$BootDriveLetter; RootDriveLetter= $RootDriveLetter }
    } catch {
        $error[0] | Write-Error

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
