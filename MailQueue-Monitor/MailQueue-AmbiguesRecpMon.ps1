###############################################
#MailQueue Ambiguous recipiets Monitor
#Author:Sunil Chauhan
#Email:Sunilkms@gmail.com
#site=sunil-chauhan.blogspot.com
#This scripts gets reports on Message stuck in Mail Queue due to Ambuguous Address Status.
#420 4.2.0 RESOLVER.ADR.Ambiguous; ambiguous address
#
###############################################

#Get all the Messages in Message Queue 

param ($EmailReport)

$to="to@domain.com"
$from="from@domain.com"
$smtp="mysmtpserver"
$csv="AmbiguousAdd.csv"
$Sub="RESOLVER.ADR.Ambiguous report"

$Msg = Get-TransportServer | Get-Queue | ? {$_.Messagecount -gt 0} | Get-Message -IncludeRecipientInfo
$dup = $msg | ? {$_.LastError -like "*420*"}
$details = $dup | select Status,FromAddress, @{n="Emailto";e={$_.Recipients | select -ExpandProperty Address}},LastError
$new = $details | select -Unique Emailto
$rec = $new | % {Get-Recipient $_.Emailto }
$report = $rec |select DisplayName,RecipientTypeDetails,SamAccountName,PrimarySmtpAddress,OrganizationalUnit,WhenCreated,WhenChanged
$report | Export-csv $csv -notype
ipcsv $CSV | ft -auto

if ($emailReport)
{
	$a = "<style>"
	$a = $a + "BODY{background-color:white;}"
	$a = $a + "TABLE{border-width: 20px;border-style: solid;border-color: black;border-collapse: collapse;border-spacing: 15px;}"
	$a = $a + "TH{border-width: 2px;padding: 8px;border-style: solid;border-color: black;background-color:#d5ebf5;text-align:center;}"
	$a = $a + "TD{border-width: 2px;padding: 8px;border-style: solid;border-color: black;background-color:#f8faf6;text-align:center;}"
	$a = $a + "</style>"

	$sub="RESOLVER.ADR.Ambiguous Report"
$body=@"
	<p>RESOLVER.ADR.Ambiguous Report</p>
	<p>Total Emails Stuck in Queue with Ambiguous Error Status= $(($Details).count)</p>
	<p>Total unique recipiets = $(($new).count)</p>
	$($details | ConvertTo-Html -head $a -PreContent "<p>Below Mails are stuck in the Queues with RESOLVER.ADR.Ambiguous Status.</p>"| Out-String)
	</br>
	<p>For more details on Recipients, please find the attached report and fix the recipients.</p>
"@
	
Send-MailMessage -To $to -From $from -SmtpServer $smtp -Subject $sub  -body $body -BodyasHTML -Attachments $CSV
}
