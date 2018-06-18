Param ($no)
$d=1
$domain="@test.com"
$log="D:\sunil\myscripts\migtestusers.txt"

$s = 33,35,36,37,38,42 | % {[char]$_}
$n = 49..57 | % {[char]$_}
$l = 97..122| % {[char]$_}
$c = 65..90 | % {[char]$_}
$c = 65..90 | % {[char]$_}
$c = 65..90 | % {[char]$_}

$no=(2..$no)

foreach ($i in $no) {

				$displayName = "MigTest User-$d"
				Write-host "A Test Account and a Mailbox Will be created for: $displayName" -f Yellow

				$givenName = "MigTest"
				$Surname = "User$d"
				$password = -join (($l + $c | Get-Random -Count 6) + ( $s | Get-Random -Count 1 ) + ($n | Get-Random -Count 1))
				$UPN = -join ($givenName + "." + $surname + $domain)
				$sam ="Migtestuser$d" 
				$path = "OU=Standard-Users,OU=Domain-Users,DC=corp,DC=shire,DC=com"
				
				add-content -path $log -value ""
				add-content -path $log -value "DisplayName :$displayName"
				add-content -path $log -value "UPN: $UPN"
				add-content -path $log -value "Domain: CORP\$sam"
				add-content -path $log -value "Password: $password"

				New-Mailbox -Password (ConvertTo-SecureString -AsPlainText $password -Force) -DisplayName $displayName -UserPrincipalName $upn `
				-LastName $Surname -FirstName $givenName -SamAccountName $sam -PrimarySmtpAddress $upn -OrganizationalUnit $path -Name $displayName			        
				#Set-ADUser $sam -Description "Requested by Nimesh Desai for Migration Testing"
				$d++
		 }
