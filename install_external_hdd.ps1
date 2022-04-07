



function set-windows_format {

    Set-Variable -Name efi -Value "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -Option Constant
    Set-Variable -Name preseve -Value "{e3c9e316-0b5c-4db8-817d-f92df00215ae}" -Option Constant
    Set-Variable -Name recovery -Value "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}" -Option Constant

    # ディスク確認
    Get-Disk | Set-Variable disk_list

    # ディスク選択
    $DiskNum;
    while ($true) {
        try {
            Write-Output $disk_list
            read-host "Select index for iniliaze disk installing windows?" | Set-Variable Disknum
            # ディスク存在確認なかったらループ
            Get-disk $DiskNum | Out-Null

            break;
        }catch{
            Write-Host "Select Existing disk in system."

        }
    }
    # ディスク初期化処理
    while ($true) {
        try {
            Set-Disk -IsOffline $false
            Clear-Disk $DiskNum -PassThru | Initialize-Disk
            break;
        }catch{

        }
    }
    try {

        # disk partition type 決定
        New-Partition -DiskNumber $DiskNum -Size 500MB -GptType $efi -AssignDriveLetter |
            Format-Volume -FileSystem FAT32 -NewFileSystemLabel "SYSTEM" |
            Select-Object -ExpandProperty DriveLetter |
            Set-Variable BootDriveLetter

        # 予約領域 (パーティションは勝手にされる。)
        New-Partition -DiskNumber $DiskNum -Size 16MB -GptType $preserve

        # 回復パーティション
        New-Partition -DiskNumber $DiskNum -Size 500MB -GptType $recovery |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel "Recovery patition"

        # Root filesystem.
        New-Partition -DiskNumber $DiskNum -UseMaximumSize -AssignDriveLetter |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" |
            Set-Variable RootDriveLetter

        # dual boot 以上の場合
        #

        # 連想配列で返す。
        return @{BootDriverLetter=$BootDriveLetter; RootDriveLetter= $RootDriveLetter }
    } finally {

    }
}


try {

    $windowsIsoPath = C:\windows.iso
    # windows iso fileをマウントしてやる。
    $MountDriveLetter = Mount-DiskImage (Resolve-Path $windowsIsoPath) | Get-Volume | Select-Object -ExpandProperty DriveLetter
    # image info image indexを調べる
    Get-WindowsImage -ImagePath "${MountDriveLetter}:\sources\install.wim" | Tee-Object -Variable windows_list

    while ($true){

        $indexNum = read-host "Select index for windows image index"

        # 
        Write-Output $windows_list | Where-Object{ $_.ImageIndex -eq $IndexNum}
    }


    # input from external
    Expand-WindowsImage -ImagePath ${MountDriveLetter}:\sources\install.wim -Index $IndexNum -ApplyPath ${RootDriveLetter}:\

    # set up for booting partition. 
    # cmdのコマンドを呼び出すときはInvoke-Expression使わないと書きづらい。
    Write-Host "${RootDriveLetter}:\Windows\System32\bcdboot.exe ${RootDriveLetter}:\Windows /s ${BootDriveLetter}: /f UEFI"

    $age = read-host " :[Y|n]"

    Invoke-expression "${RootDriveLetter}:\Windows\System32\bcdboot.exe ${RootDriveLetter}:\Windows /s ${BootDriveLetter}: /f UEFI"
}finally{

    # マウント解除
    # アンマウント済みでもエラーにならないのでとりあえず四読
    DisMount-DiskImage (Resolve-Path $windowsIsoPath) | Out-Null
}
