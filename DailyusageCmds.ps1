#Fetch task running under a specific account on multiple servers.
$("Server1","server2") | % {schtasks.exe /query /s $_ /V /FO CSV | ConvertFrom-Csv |  ? {$_.'<changeme | Svc ac>' } | select HostName,TaskName,Author,"Run As User"}

#check all TLS versions and their status.

Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols" | % {Get-ChildItem $_.pspath}

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

#Get Full Mailbox Access Report filter unwated objects.

Get-MailboxPermission SOC | ? {$_.IsInherited -ne "True" -or $_.user -notlike "*NT*"}

#get Mail queue
Get-TransportServer | Get-Queue | ? {$_.MessageCount -gt 10}

