#
# This script would recreate a corrupted mailbox and will keep the the old proxy
# Warrning!! -- It does not backup any Mailbox Data and the old mailbox would be deleted.
#
#USAGE .\Script.ps1 -Mbx USERID -$database (Database where the mailbox to be setup)
#
param ($mbx,$database)

$mailbox = Get-Mailbox -Identity $mbx
$db = Get-MailboxDatabase $database   
if (!$db) { Write-host "Invalid Database Name: $database" -ForegroundColor Yellow ; break }

if ($mailbox ) {

#$ProxyAddresses = $mailbox.EmailAddresses
Write-host "Disabling the Current Mailbox" -ForegroundColor Cyan
Disable-Mailbox $mailbox.Alias -confirm:$false

Write-host "Enabling the Mailbox on new Database"($database) -ForegroundColor Cyan
Enable-Mailbox $mailbox.UserPrincipalName -Database $database
""
Write-Host "Setting up Proxy Addresses" -ForegroundColor Cyan
"setting policy"
Set-Mailbox $mailbox.UserPrincipalName -EmailAddressPolicyEnabled:$false
"Adding proxy"

Set-Mailbox $mailbox.UserPrincipalName -EmailAddresses $mailbox.EmailAddresses 

"Validating the Mailbox"

$newmbx=Get-mailbox $mailbox.UserPrincipalName

    if ($newmbx)

        {

        $newmbx | fl Name, Database
        write-host "Mailbox Has been Recreated Successfully" -ForegroundColor Green
           
        }

} else { "Mailbox Not Found" }
