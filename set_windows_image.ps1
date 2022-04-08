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
