<#
.SYNOPSIS
    This script transfers user files from a source computer to a target computer.

.DESCRIPTION
    The script connects to the source and target computers using credentials retrieved from 1Password CLI.
    It then transfers specified user folders (Desktop, Documents, Downloads, Pictures, Videos) from the source computer to the target computer.

.PARAMETER Source
    The name of the source computer.

.PARAMETER Target
    The name of the target computer.

.PARAMETER User
    The user name whose files are to be transferred.

.PARAMETER domain
    The domain name to retrieve credentials from 1Password.

.EXAMPLE
    .\transfer-files.ps1 -Source "SourcePC" -Target "TargetPC" -User "jdoe" -domain "KFI"

.NOTES
    Author: Joey Maffiola
    Date: 1/14/25
#>

function Test-Domain {
    <#
    .SYNOPSIS
        Retrieves the UUID for a given domain.

    .PARAMETER domain
        The domain name to retrieve the UUID for.

    .OUTPUTS
        System.String

    .EXAMPLE
        $UUID = Test-Domain -domain "KFI"
    #>
    param (
        [string]$domain
    )
    if ($domain -eq 'KFI') {
        return 'xjc3zngxe44ouwnw2tqhlgdlvy'
    }
    if ($domain -eq 'JFC') {
        return 'qks77x6uti4rue6m7pc54tmcum'
    }
    if ($domain -eq 'KMS') {
        return 'h7sd3ebnf3wvrfusnev3ufhlze'
    }
}

function Move-Files {
    <#
    .SYNOPSIS
        Main function of the program.

    .PARAMETER Source
        The name of the source computer.

    .PARAMETER Target
        The name of the target computer.

    .PARAMETER User
        The user name whose files are to be transferred.

    .PARAMETER domain
        The domain name to retrieve credentials from 1Password.

    .EXAMPLE
        Move-Files -Source "SourcePC" -Target "TargetPC" -User "jdoe" -domain "KFI"
    #>
    param (
        [string]$Source,
        [string]$Target,
        [string]$User,
        [string]$domain
    )
    # If parameters are not provided, prompt the user to enter them
    if (-not $Source) {
        $Source = Read-Host 'Enter the source computer name'
    }
    if (-not $Target) {
        $Target = Read-Host 'Enter the target computer name'
    }
    if (-not $User) {
        $User = Read-Host 'Enter the user name'
    }
    if (-not $domain) {
        $domain = Read-Host 'Enter the domain name'
    }
    # Get 1P domain UUID
    $UUID = Test-Domain $domain

    # Retrieve credentials from 1Password CLI and create PSCredential object
    $opUsername = Invoke-Expression "op read op://employee/$UUID/username"
    $securePassword = ConvertTo-SecureString (Invoke-Expression "op read op://employee/$UUID/password") -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $opUsername, $securePassword

    # Remove existing network drives if they exist
    if (Get-PSDrive -Name 'SourceDrive' -ErrorAction SilentlyContinue) {
        Remove-PSDrive -Name 'SourceDrive'
    }
    if (Get-PSDrive -Name 'TargetDrive' -ErrorAction SilentlyContinue) {
        Remove-PSDrive -Name 'TargetDrive'
    }

    # Create temporary network drives
    New-PSDrive -Name 'SourceDrive' -PSProvider FileSystem -Root "\\$Source\C$" -Credential $Credential
    New-PSDrive -Name 'TargetDrive' -PSProvider FileSystem -Root "\\$Target\C$" -Credential $Credential

    $sourceUserPath = Join-Path -Path 'SourceDrive:\Users' -ChildPath $User
    $targetUserPath = Join-Path -Path 'TargetDrive:\Users' -ChildPath $User

    # Define the folders to transfer
    $folders = @('Desktop', 'Documents', 'Downloads', 'Pictures', 'Videos')

    # Check if the user folder exists on the source computer & target computer
    Test-Folders -sourceUserPath $sourceUserPath -targetUserPath $targetUserPath

    # Transfer each folder
    Move-Folders -sourceUserPath $sourceUserPath -targetUserPath $targetUserPath -folders $folders

    # Remove temporary network drives
    Remove-PSDrive -Name 'SourceDrive'
    Remove-PSDrive -Name 'TargetDrive'

    Write-Output 'File transfer completed.'
}

function Test-Folders {
    <#
    .SYNOPSIS
        Checks if the user folders exist on both the source and target computers.

    .PARAMETER sourceUserPath
        The path to the user folder on the source computer.

    .PARAMETER targetUserPath
        The path to the user folder on the target computer.

    .EXAMPLE
        Test-Folders -sourceUserPath "SourceDrive:\Users\jdoe" -targetUserPath "TargetDrive:\Users\jdoe"
    #>
    param (
        [string]$sourceUserPath,
        [string]$targetUserPath
    )
    if (-Not (Test-Path $sourceUserPath)) {
        Write-Output "User folder not found on source computer: $sourceUserPath"
        exit
    }
    elseif (-Not (Test-Path $targetUserPath)) {
        Write-Output "User folder not found on target computer: $targetUserPath"
        exit
    }
    Write-Output 'Both source and target user folders exist. Proceeding with file transfer...'
    
}

function Move-Folders {
    <#
    .SYNOPSIS
        Transfers specified folders from the source computer to the target computer.

    .PARAMETER sourceUserPath
        The path to the user folder on the source computer.

    .PARAMETER targetUserPath
        The path to the user folder on the target computer.

    .PARAMETER folders
        The list of folders to transfer.

    .EXAMPLE
        Move-Folders -sourceUserPath "SourceDrive:\Users\jdoe" -targetUserPath "TargetDrive:\Users\jdoe" -folders @('Desktop', 'Documents')
    #>
    param (
        [string]$sourceUserPath,
        [string]$targetUserPath,
        [array]$folders
    )
    foreach ($folder in $folders) {
        $sourcePath = Join-Path -Path $sourceUserPath -ChildPath $folder
        $targetPath = Join-Path -Path $targetUserPath
    
        if (Test-Path $sourcePath) {
            Write-Output "Transferring $folder from $Source to $Target..."
            try {
                Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force -ErrorAction Stop
                Write-Output "$folder transferred successfully."
            }
            catch {
                Write-Output "Access to the path '$sourcePath' is denied. Retrying with elevated permissions..."
                $elevatedCommand = "Copy-Item -Path `"$sourcePath`" -Destination `"$targetPath`" -Recurse -Force"
                Start-Process powershell -ArgumentList "-Command $elevatedCommand" -Verb RunAs -Wait
                Write-Output "$folder transferred successfully with elevated permissions."
            }
        }
        else {
            Write-Output "$folder not found on source computer: $sourcePath"
        }
    }
}

# Call the main function
Move-Files -Source $args[0] -Target $args[1] -User $args[2] -domain $args[3]

