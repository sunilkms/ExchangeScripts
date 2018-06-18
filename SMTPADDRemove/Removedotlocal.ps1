param ($file,$add)
$entry = gc $file
foreach ($user in $entry){
$mbx= Get-Mailbox $user
if ($mbx) {
	if ($add) {	
	Write-host "Adding the ProxyAddress"	
	$NewProxyAdd=
	} else {
		Write-host "Removing .local address" $mbx
		$RemoveSmtp=($mbx.EmailAddresses | ? {$_.smtpAddress -like "*.local"}).SmtpAddress
		Set-Mailbox $user -EmailAddresses @{remove=$RemoveSmtp}
	  }
      } else {
	Write-host "User Not Found" -f Yellow
      }
}
