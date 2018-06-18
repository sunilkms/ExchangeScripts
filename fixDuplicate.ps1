param ($user)

$type = Get-ADUser -Filter {mail -like $user} -Properties *
$Recipients = Get-Recipient $user

if ($type.count -gt 1) 
        {

        "Multiple IDs found, Getting user type"

        $users = $type | % { Get-user $_.SamaccountName}
        $users
        
        if ($users.RecipientType -like "User") 
                {
                Write-Host "One of Duplicate user type Object is 'User'" -ForegroundColor Yellow
                $users
                $u = $users | ? {$_.RecipientType -like "user"}

                ""
                Write-Host "Fixing the object:" $u.Identity -ForegroundColor Cyan
                Set-ADUser $u.SamaccountName -EmailAddress $null
                "Done"
                }

        } else {"No Duplicate Found with 'Get-AdUser'"}

# Checking duplicate with Get-Recipient Cmd
""
write-host "Now Checking with 'Get-Recipient' cmd" -ForegroundColor Cyan

if ($Recipients) {

if ($Recipients.count -gt 1) {

Write-Host "There are Multiple ID Matching: $user" -ForegroundColor Yellow
write-host "No of recipients Mathing:" $Recipients.count
""
$Recipients | % { Write-Host "Recipient TYPE :($($_.RecipientTypeDetails)) IDENTITY : ($($_.Identity))" -ForegroundColor Cyan }
""
Write-Host "Getting The Old or Invalid Recipeint" -ForegroundColor Yellow

$old=$Recipients | ? {$_.Identity -match "Disabled"}
if ($old.RecipientTypeDetails -like "UserMailbox") {
$old = $old | get-Mailbox 
}

if ($old.RecipientTypeDetails -like "mailuser") {
$old = $old | get-mailuser
}

if(!$old) { $old = $Recipients.Alias | % {Get-ADUser $_ -Properties *} ;

$old = $old | ? {$_.Description -notlike "Mim*"}
$old = Get-Recipient $old.SamaccountName
if ($old.RecipientTypeDetails -like "RemoteUserMailbox") {$old = Get-RemoteMailbox $old.SamaccountName }
}

Write-Host "Old Id has been Identified to be:" $old.Name -ForegroundColor Cyan
""
Write-host "Analyzing the Attribute to be fixed" -ForegroundColor Yellow

#Attribute Validation

write-host "Validating the EmailAddresses"

if ($old.EmailAddresses -eq $user) 
        { 
            write-host "Attribute Matching, and should be replaced" -ForegroundColor Green
            "Removing the proxy address entry"
            
            if ($old.RecipientTypeDetails -like "MailUser") {

            "RecipientType is MailUser"
                      
            Set-AdUser $old.alias -Remove @{proxyAddresses=$user}            
            $newp= "SMTP:" + "$($old.UserPrincipalName)"              
            Set-Mailuser $old.alias -EmailAddresses @{add=$newp} -EmailAddressPolicyEnabled:$false
              
              if ($error[0].Exception -match "no primary SMTP") {
              
              Write-Host "Setting a Differnt Primary SMTP"
              #Set-Mailuser $old.alias -PrimarySmtpAddress $old.UserPrincipalName -EmailAddressPolicyEnabled:$false
              
              $newp= "SMTP:" + "$($old.UserPrincipalName)"              
              Set-Mailuser $old.alias -EmailAddresses @{add=$newp,$user} -EmailAddressPolicyEnabled:$false
              
              Write-Host "Removing smtp" $user 
              Set-Mailuser $old.alias -EmailAddresses @{Remove=$user} -EmailAddressPolicyEnabled:$false            
              }            
            } 

            if ($old.RecipientTypeDetails -like "RemoteUserMailbox") {
            
            "RecipientType is RemoteUserMailbox"
            $newp= "SMTP:" + "$($old.UserPrincipalName)"
            Set-RemoteMailbox $old.alias -EmailAddresses @{add=$newp} -EmailAddressPolicyEnabled:$false
            Write-Host "Removing smtp" $user 
            
            Set-RemoteMailbox $old.alias -EmailAddresses @{Remove=$user} -EmailAddressPolicyEnabled:$false
            
            }

            if ($old.RecipientTypeDetails -like "UserMailbox") {
            
            "RecipientType is UserMailbox"

            Set-Mailbox $old.alias -EmailAddresses @{Remove=$user} -EmailAddressPolicyEnabled:$false
            
            if ($error[0].Exception -match "no primary SMTP") {
              
              Write-Host "Setting a Differnt Primary SMTP"
              
              $newp= "SMTP:" + "$($old.UserPrincipalName)"
              Set-Mailbox $old.alias -EmailAddresses @{add=$newp,$user} -EmailAddressPolicyEnabled:$false
              Write-Host "Removing smtp" $user  
              Set-Mailbox $old.alias -EmailAddresses @{Remove=$user} -EmailAddressPolicyEnabled:$false            
              }            
            }

        } Else { "Attribute OK, Not matching" }

""
write-host "Validating the WindowsEmailAddress:" $old.WindowsEmailAddress  -ForegroundColor Cyan

if ($old.WindowsEmailAddress -eq $user) 
        {   write-host "Attribute Matching, and should be replaced" -ForegroundColor Green 
            $newsmtp = ($old.alias) + "@shire.com"
            Write-host "Replacing with" $newsmtp
            Set-MailUser $old.alias -WindowsEmailAddress $newsmtp -EmailAddressPolicyEnabled:$false
        }
 Else {"Attribute OK, Not matching"}

""

write-host "Validating the PrimarySmtpAddress" $old.PrimarySmtpAddress -ForegroundColor cyan
if ($old.PrimarySmtpAddress -match $user) 
            { 
             write-host "Attribute Matching, and should be replaced" -ForegroundColor Green 
             $newsmtp = ($old.alias) + "@shire.com"

             if ($old.RecipientTypeDetails -like "MailUser") {
             
             Write-host "Replacing with" $newsmtp
             Set-MailUser $old.alias -PrimarySmtpAddress $newsmtp -EmailAddressPolicyEnabled:$false 
             
             }
             
            if ($old.RecipientTypeDetails -like "RemoteUserMailbox") {
            
            "RecipientType is RemoteUserMailbox"            
            Set-RemoteMailbox $old.alias -PrimarySmtpAddress $newsmtp -EmailAddressPolicyEnabled:$false
            
            }
            
            if ($old.RecipientTypeDetails -like "UserMailbox") {
            
            "RecipientType is UserMailbox"
            Write-host "Replacing with" $newsmtp
            Set-Mailbox $old.alias -PrimarySmtpAddress $newsmtp -EmailAddressPolicyEnabled:$false -force
            
               }          
            
            
            } 
       Else {"Attribute OK, Not matching"}
""

} else {
""
"No Recipient Matching"
""
"Checking user case"

$DisabledUser= $type | ? {$_.CanonicalName -match "Disab"}

if ($DisabledUSEr) {
Write-Host "Fixing the object:" $DisabledUSEr.Name -ForegroundColor Cyan
Set-ADUser $DisabledUSEr.SamaccountName -EmailAddress $null
if ($DisabledUSEr.Description -match "Mim") {

Write-Host "User $($DisabledUSEr.SamaccountName) is Mim Managed, To Avoide writeback, make the change from MIM Portal" }

 } else {

"No Duplicate found for the ID" }
    } 
 } else {

"No Duplicate found for the ID" } 
