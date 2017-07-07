param ($file)
############ Start Import the Exchange 2010 modules if available, otherwise import 2007.
if (Get-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -Registered -ErrorAction SilentlyContinue) {
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
} else {
    Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.Admin
}

############ Start Variables
[Int] $intSent = $intRec = 0
$emails= ipcsv $file
#$emails = Get-Mailbox
$StartDate = get-date -uformat "%m.01.%Y"  ## Be careful => English date format
$EndDate = get-date -uformat "%m.%d.%Y"    ## Be careful => English date format
$tab2 = @()
$tabInfo = @()
############ End variables

############ Start HTML Style
$head = @'
<style>
body { background-color:#FFFFFF;
       font-family:Tahoma;
       font-size:11pt; }
td, th { border:1px solid black; 
         border-collapse:collapse;
		 text-align:center;
		 background+color:#e0e0e0;
		 width:300px;}
th { color:#ffffff;
     background-color:#20a000;
	 text-align:center;}
table, tr, td, th { padding: 1px; margin: 0px }
table { margin-left:15px; }
</style>
'@
############ End HTML Style

############ Start retrieve email address + NB sent/received mails
foreach ($i in $emails) {

$intRec = 0                       #Number of received mails
$intSent = 0                      #Number of sent mails
$address = $i.PrimarySmtpAddress  #Email address
$address = $address.ToString()    #Email address to string
$object = new-object Psobject     #Create the object
$objectInfo = new-object Psobject  #Create the object info

############ Sent mails
Get-TransportServer | Get-MessageTrackingLog -ResultSize Unlimited -Start $StartDate -End $EndDate -Sender $address -EventID RECEIVE | ? {$_.Source -eq "STOREDRIVER"} | ForEach { $intSent++ }

############ Received mails
Get-TransportServer | Get-MessageTrackingLog -ResultSize Unlimited -Start $StartDate -End $EndDate -Recipients $address -EventID DELIVER | ForEach { $intRec++ }

############ Insert address + number of sent/received mails
$object | Add-member -Name "User" -Membertype "Noteproperty" -Value $address
$object | Add-member -Name "Received" -Membertype "Noteproperty" -Value $intRec
$object | Add-member -Name "Sent" -Membertype "Noteproperty" -Value $intSent
$tab2 += $object
}

############ Insert informations
$objectInfo | Add-member -Name "Title" -Membertype "Noteproperty" -Value "Stats Mails"
$objectInfo | Add-member -Name "Version" -Membertype "Noteproperty" -Value "v1.2"
$objectInfo | Add-member -Name "Author" -Membertype "Noteproperty" -Value "Nicolas Prigent [www.get-cmd.com]"
$tabInfo += $objectInfo

############ Sort by number of sent emails
$tab2 = $tab2 | Sort-Object Sent -descending

############ ConvertTo-HTML
$body =  $tabInfo | ConvertTo-HTML -head $head
$body += $tab2 | ConvertTo-HTML -head $head

############ Send emails with results
send-mailmessage -to "Your_Email@domain.com" -from "StatMails@exchange" -subject "Stats mails From $StartDate To $EndDate" -body ($body | out-string) -BodyAsHTML -SmtpServer "xxx.xxx.xxx.xxx:YY"

############ end of Script
