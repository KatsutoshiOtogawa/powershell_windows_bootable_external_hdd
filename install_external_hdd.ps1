

# /mnt/c /mnt/d
# ディスク確認
Get-Disk 

$DiskNum = 2
$windowsIsoPath = C:\windows.iso
Clear-Disk $DiskNum

# disk partition type 決定
Initialize-Disk $DiskNum 
$efi = "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}"
$preserve = "{e3c9e316-0b5c-4db8-817d-f92df00215ae}"
$recovery = "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}"

$BootDriveLetter = (New-Partition -DiskNumber $DiskNum -Size 500MB -GptType $efi -AssignDriveLetter | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "SYSTEM" | Select-Object -ExpandProperty DriveLetter)

# 予約領域 (パーティションは勝手にされる。)
New-Partition -DiskNumber $DiskNum -Size 16MB -GptType $preserve

# 回復パーティション
New-Partition -DiskNumber $DiskNum -Size 500MB -GptType $recovery | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Recovery patition"

# Root filesystem.
$RootDriveLetter = (New-Partition -DiskNumber $DiskNum -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows")

# windows iso fileをマウントしてやる。
Mount-DiskImage $windowsIsoPath  -PassThru | Set-Variable MountDriveLetter

# mount 先のパスを取得

# image info image indexを調べる
Get-WindowsImage -ImagePath "${MountDriveLetter}:\sources\install.wim"
# tempfileに置く。
$tempfile

$IndexNum
# input from external
Expand-WindowsImage -ImagePath ${MountDriveLetter}:\sources\install.wim -Index $IndexNum -ApplyPath ${RootDriveLetter}:\

# set up for booting partition. 
# cmdのコマンドを呼び出すときはInvoke-Expression使わないと書きづらい。
Invoke-expression "${RootDriveLetter}:\Windows\System32\bcdboot.exe ${RootDriveLetter}:\Windows /s ${BootDriveLetter}: /f UEFI" -Whatif

DisMount-DiskImage $windowsIsoPath