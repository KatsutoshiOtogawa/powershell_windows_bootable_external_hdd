
function set-windows_Image {
    #Requires -Version 7 -RunAsAdministrator
    #Requires -Modules Dism
    [CmdletBinding()]
    param (
        # UseMaximumSize
        [Parameter(
            Mandatory = $True
            , HelpMessage = "Specifies the size of the partition to create. If not specified, then the units will default to Bytes . The acceptable value for this parameter is a positive number followed by the one of the following unit values: Bytes ,KB , MB , GB , or TB ."
        )]
        [string]$image_path,

        [Parameter(
            Mandatory = $True
            ,HelpMessage = "Leave disk space."
        )]
        [string]$BootDriveLetter,
        [Parameter(
            Mandatory = $True
            ,HelpMessage = "Leave disk space."
        )]
        [string]$WindowsDriveLetter,

        [Parameter(
            Mandatory = $False
        )]
        [Switch]$PassThru
        
    )
    # 取り出す適菜名前にする。
    Set-Variable ErrorActionPreference -Scope local -Value "Stop"

    New-Variable windows_list -Scope local
    try {
        # image info image indexを調べる
        Get-WindowsImage -ImagePath $image_path |
            Set-Variable windows_list
    } catch {
        $error[0] | Write-Error
    }
    New-Variable indexNum -Scope local
    while ($true){

        try {
            Write-Output $windows_list | Out-Host
            Read-Host "Select index for windows image index?" |
                Set-Variable indexNum
            # Image存在確認なかったらループ
            Get-WindowsImage -ImagePath $image_path -Index $indexNum |
                Out-Null
            break;
        }catch{

            $error[0] | Write-Error
        }
    }
    try {
        # input from external
        Expand-WindowsImage -ImagePath $image_path -Index $indexNum -ApplyPath "${WindowsDriveLetter}:\" 

        # set up for booting partition. 
        Start-Process "${WindowsDriveLetter}:\Windows\System32\bcdboot.exe" `
            -ArgumentList "${WindowsDriveLetter}:\Windows",/s,"${BootDriveLetter}:",/f,UEFI `
            -Confirm `
            -Wait
    }catch{

        $error[0] | Write-Error
    }
}
