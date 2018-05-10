#-------------------------------------------------------------------------------------------------
# Run us using the following.
# Convert-Mailbox-to-MailUser.ps1 -Mailbox USERID -ExternalEmailAddress "user1@externaldomain.com"
#---------------------------------------------------------------------------------------------------

Param ($Mailbox)
Param ($ExternalEmailAddress)
$Mbx = Get-Mailbox $Mailbox

#Get Emailaddress for mailbox 
$emailaddresses = $Mbx.EmailAddresses 
$primarySmtpaddress = $Mbx.PrimarySmtpAddress 
$userPrincipalName = $Mbx.UserPrincipalName 

#Remove Mailbox 
Disable-Mailbox $mbx -confirm:$false 

#Create MailUser
# if the external address already available filter it from the proxy using the below line of code.
#$ExternalEmailAddress=$mbx.EmailAddresses.smtpaddress | ? {$_ -like "*@externaldomain*"}

Enable-MailUser $mbx.Alias -ExternalEmailAddress $ExternalEmailAddress | Out-null

#set primary smtp and secondary emailaddresses
Set-MailUser $mbx.alias -EmailAddressPolicyEnabled $false
Set-MailUser $mbx.alias -PrimarySmtpAddress $primarySmtpaddress
Set-MailUser $mbx.alias -EmailAddresses $emailaddresses

Write-Host "Mailuser Conversion Competed for:" $mbx.PrimarySmtpAddress
