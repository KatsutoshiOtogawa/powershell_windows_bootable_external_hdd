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
