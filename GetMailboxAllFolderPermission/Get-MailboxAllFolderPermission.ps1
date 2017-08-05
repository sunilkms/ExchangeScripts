param ($mailbox)

$AllMbxFolders=Get-MailboxFolderStatistics $mailbox | Select Name, ContainerClass,folderid
$FilteredFolders=$AllMbxFolders | ? { ` # Add or remove the filter for folder in the below list.
$_.ContainerClass -eq "IPF.Note" -or `
$_.ContainerClass -like "IPF.Appointment" -and `
$_.Name -notlike "*Clatter*" -and `
$_.Name -notlike "*DR*" -and ` 
$_.Name -notlike "*Junk*" -and `
$_.Name -notlike "*Sync I*"
}

foreach ($folder in $FilteredFolders) {Get-MailboxFolderPermission -Identity $($mailbox + ":$($folder.FolderID)") -ea SilentlyContinue}
