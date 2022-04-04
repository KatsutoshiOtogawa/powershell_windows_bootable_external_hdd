

# /mnt/c /mnt/d
# ディスク確認
Get-Disk 

$DiskNum = 2
$windowsIsoPath = C:\windows.iso
Clear-Disk $DiskNum

# disk partition type 決定
Initialize-Disk $DiskNum 

New-Partition -DiskNumber $DiskNum -Size 500MB -GptType "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -AssignDriveLetter | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "SYSTEM" -Force
$BootDriveLetter
# 予約領域 (パーティションは勝手にされる。)
New-Partition -DiskNumber $DiskNum -Size 16MB -GptType "{e3c9e316-0b5c-4db8-817d-f92df00215ae}"
# 回復パーティション
New-Partition -DiskNumber $DiskNum -Size 500MB -GptType "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}" | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Recovery patition"

# Root filesystem.
New-Partition -DiskNumber $DiskNum  -GptType -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Windows" 
$RootDriveLetter

# windows iso fileをマウントしてやる。
Mount-DiskImage $windowsIsoPath  -pathtrhe | Set-Variable MountDriveLetter

# mount 先のパスを取得

# image info image indexを調べる
Get-WindowsImage -ImagePath $MountDriveLetter:\sources\install.wim
# tempfileに置く。
$tempfile

# input from external
$IndexNum

Expand-WindowsImage -ImagePath $MountDriveLetter:\sources\install.wim -Index $IndexNum -ApplyPath "$RootDriveLetter:\"

# set up for booting partition. 
$RootDriveLetter:\Windows\System32\bcdboot $RootDriveLetter:\Windows /s $BootDriveLetter: /f UEFI

DisMount-DiskImage $windowsIsoPath