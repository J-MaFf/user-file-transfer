param (
    [string]$SourceComputer,
    [string]$TargetComputer,
    [string]$User
)

# Define the folders to transfer
$folders = @('Desktop', 'Documents', 'Downloads', 'Pictures', 'Videos')

# Check if the user folder exists on the source computer & target computer
Test-Folders

# Transfer each folder
Move-Folders

Write-Output 'File transfer completed.'

function Test-Folders {
    $sourceUserPath = "\\$SourceComputer\C$\Users\$User"
    $targetUserPath = "\\$TargetComputer\C$\Users\$User"
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
    foreach ($folder in $folders) {
        $sourcePath = Join-Path -Path $sourceUserPath -ChildPath $folder
        $targetPath = "\\$TargetComputer\C$\Users\$User\$folder"
    
        if (Test-Path $sourcePath) {
            Write-Output "Transferring $folder from $SourceComputer to $TargetComputer..."
            Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
            Write-Output "$folder transferred successfully."
        }
        else {
            Write-Output "$folder not found on source computer: $sourcePath"
        }
    }
}