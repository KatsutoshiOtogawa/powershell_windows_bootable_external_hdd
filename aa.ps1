
[zenn](https://zenn.dev/cumet04/articles/windows-on-external-disk)
[pwsh](https://tech.guitarrapc.com/entry/2016/05/28/173049)
[](https://docs.microsoft.com/ja-jp/windows-hardware/manufacture/desktop/use-dism-in-windows-powershell-s14?view=windows-11)
[bcdboot](https://windowscmd.com/bcdboot/)
# /mnt/c /mnt/d
# ディスク確認
Get-Disk 

$DiskNum = 2
Clear-Disk $DiskNum

# disk partition type 決定
Initialize-Disk $DiskNum 

[Pwsh docs](https://docs.microsoft.com/en-us/powershell/module/storage/new-partition?view=windowsserver2022-ps)
New-Partition -DiskNumber $DiskNum -Size 500MB -GptType "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -AssignDriveLetter | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "SYSTEM" -Force
# 予約領域
New-Partition -DiskNumber $DiskNum -Size 16MB -GptType "{e3c9e316-0b5c-4db8-817d-f92df00215ae}"
# 回復パーティション
New-Partition -DiskNumber $DiskNum -Size 500MB -GptType "{de94bba4-06d1-4d40-a16a-bfd50179d6ac}" | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Recovery patition"
New-Partition -DiskNumber $DiskNum  -GptType -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel "root filesystem" 

# windows iso fileをマウントしてやる。
Mount-DiskImage C:\windows.iso
# image info image indexを調べる
Get-WindowsImage -ImagePath F:\sources\install.wim
Expand-WindowsImage -ImagePath F:\sources\install.wim -Index 2 -ApplyPath "E:\"

# set up for booting partition. 
E:\Windows\System32\bcdboot E:\Windows /s F: /f UEFI
