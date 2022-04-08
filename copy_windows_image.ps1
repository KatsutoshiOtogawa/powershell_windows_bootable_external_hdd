function copy_windows_image {
    #Requires -Version 7 -RunAsAdministrator
    #Requires -Modules Storage
    [CmdletBinding()]
    param (
        # UseMaximumSize
        [Parameter(
            Mandatory = $True
            , HelpMessage = "Specifies the size of the partition to create. If not specified, then the units will default to Bytes . The acceptable value for this parameter is a positive number followed by the one of the following unit values: Bytes ,KB , MB , GB , or TB ."
        )]
        [string]$windowsIsoPath,

        [Parameter(
            Mandatory = $True
            ,HelpMessage = "Leave disk space."
        )]
        [string]$destination

    )
    Set-Variable ErrorActionPreference -Scope local -Value "Stop"
    # 使い方の例
    # copy_windows_image -windowsIsoPath "C:\windows.iso" -destination "C:\Users\Administrator\"
    # 取り出す適菜名前にする。

    # Set-Variable -Name windowsIsoPath -Scope local -Value "C:\windows.iso" -Option Constant
    # Set-Variable -Name destination -Scope local -Value "C:\Users\Administrator\" -Option Constant
    try {

        # windows iso fileをマウントしてやる。
        Resolve-Path $windowsIsoPath |
        Mount-DiskImage |
            Get-Volume |
            Select-Object -ExpandProperty DriveLetter |
            Set-Variable MountDriveLetter -Scope local -Option Constant

        Set-Variable wimPath -Scope local -Value "${MountDriveLetter}:\sources\install.wim" -Option Constant
        Copy-Item $wimPath -Destination $destination
    } finally {

       # マウント解除
       # アンマウント済みでもエラーにならないのでとりあえず四読
       Resolve-Path $windowsIsoPath |
        DisMount-DiskImage | 
        Out-Null
    }
}
