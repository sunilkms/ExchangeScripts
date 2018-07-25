#############################################################################
# Author : Sunil Chauhan
# Monitor Mail Queue on All hub server, This script genrate an HTML report
# http://www.sunilchauhan.info
#############################################################################

Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.SnapIn
Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.Support

$a = "<style>"
$a = $a + "BODY{background-color:white;}"
$a = $a + "TABLE{border-width: 20px;border-style: solid;border-color: black;border-collapse: collapse;border-spacing: 15px;}"
$a = $a + "TH{border-width: 2px;padding: 8px;border-style: solid;border-color: black;background-color:#d5ebf5;text-align:center;}"
$a = $a + "TD{border-width: 2px;padding: 8px;border-style: solid;border-color: black;background-color:#f8faf6;text-align:center;}"
$a = $a + "</style>"

$queue = Get-TransportService | Get-queue | ? {$_.MessageCount -gt 5} | sort MessageCount -Descending | Select `
Identity,MessageCount,Status,NExtHopDomain
$max = ($queue | measure MessageCount -Maximum).Maximum
$body=@"
$($queue | ConvertTo-HTML -head $a -PostContent "<p>Note: Mail Queues where MessageCount is less then 5 will not be reported.</p>"| Out-String)
"@

# 
$to="messaging-team@xyz.com"
$from="messaging-team@xyz.com"
$subject="Highest Mail Queue count - $Max"

if ($max -gt 10) {
Send-MailMessage -From $from -To $to -Subject $subject -Smtpserver "SW20" -body $body -BodyAsHtml 
}
