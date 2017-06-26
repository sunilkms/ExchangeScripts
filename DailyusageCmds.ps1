
#Check Server Helth on a Remote Host
Test-ServiceHealth -Server LABHUB01
#start a Service on a Remote host
Invoke-Command -ComputerName LABHUB01 -ScriptBlock {Start-Service -ServiceName MSExchangeTransport }

#Genrate Random Password
$s = 33,35,36,37,38,42 | % {[char]$_}
$n = 49..57 | % {[char]$_}
$l = 97..122| % {[char]$_}
$c = 65..90 | % {[char]$_}

$password = -join (($l + $c | Get-Random -Count 6) + ( $s | Get-Random -Count 1 ) + ($n | Get-Random -Count 1))

Move All Mounted Database to a Specific host.

Get-MailboxDatabaseCopyStatus -Server DAG03 | ? {$_.Status -eq "Mounted"} | % {
Move-ActiveMailboxDatabase -ActivateOnServer DAG04 -Confirm:$false -Identity $_.DatabaseName }

#Get Role Group Member.

Get-RoleGroup | ? {$_.RoleAssignments -match "Export"} | %{Get-RoleGroupMember -Identity $_.Name}

