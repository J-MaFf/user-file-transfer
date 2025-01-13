param (
    [string]$Source,
    [string]$Target,
    [string]$User
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



# Define the folders to transfer
$folders = @('Desktop', 'Documents', 'Downloads', 'Pictures', 'Videos')

# Check if the user folder exists on the source computer & target computer
Test-Folders

# Transfer each folder
Move-Folders

Write-Output 'File transfer completed.'

<#
.SYNOPSIS
    Tests the existence of specified folders.

.DESCRIPTION
    The Test-Folders function checks if the specified folders exist and performs necessary actions based on the results.
#>
function Test-Folders {
    $sourceUserPath = "\\$SourceComputer\C$\Users\$User"
    $targetUserPath = "\\$target\C$\Users\$User"
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

<#
.SYNOPSIS
    Moves specified folders from the source computer to the target computer.
.DESCRIPTION
    The Move-Folders function copies the specified folders from the source computer to the target computer.
#>
function Move-Folders {
    foreach ($folder in $folders) {
        $sourcePath = Join-Path -Path $sourceUserPath -ChildPath $folder
        $targetPath = "\\$target\C$\Users\$User\$folder"
    
        if (Test-Path $sourcePath) {
            Write-Output "Transferring $folder from $SourceComputer to $target..."
            Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
            Write-Output "$folder transferred successfully."
        }
        else {
            Write-Output "$folder not found on source computer: $sourcePath"
        }
    }
}