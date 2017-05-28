#Author: Sunil Chauhan
#EMail: Sunilkms@gmail.com
#Blog: sunil-chauhan.blogspot.com
#Fix Recipient for whome you are getting IMCEAEX user not found NDR.
# Useage Examples:
# copy and paste the entire NDR to a File
#To convert to x500 from csv 		: .\Fix-IMCEAEX-From-NDR.ps1 -NDRFile File.txt
#To make changes to user Account	: .\Fix-IMCEAEX-From-NDR.ps1 -NDRFile File.txt -edit True
#To Verify the Changes to Account	: .\Fix-IMCEAEX-From-NDR.ps1 -NDRFile File.txt -CheckX500 True
# 

#"Note: This script useses ACtiveDirectory powershell Module please make sure the same in install"

param ($edit,$CheckX500="FALSE",$NdrFile)

$m=(Get-Module | ? {$_.Name -like "Activedirectory"})
if (!$m) {"Connecting AD"; Import-Module ACtiveDirectory} else {"Already Connnected AD Skip.."}

$ndr = get-content $NDRFile
$in = 0 ; foreach ($line in $ndr) { if ($line -match "Received:") {Break} else {$in++}}
$ndr = $ndr | select -Index (0..$in)
$inn = 0 ; foreach ($line in $ndr) { if ($line -match "admini") {Break} else {$inn++}}
$NameHeader= $ndr | select -Index (0..$inn)
$user=@();$n=0 ; foreach ($l in $NameHeader) {$n++ ; if ($NameHeader[$n] -match "helpdesk.") {$user+=$NameHeader[$n - 1]}}
$IMC = $ndr | ? {$_ -match "IMC"}

$file=@()
$c=0
if ($user.count -le 1) 
		{
			$newEntry = New-Object -TypeName PSObject
			$newEntry | Add-Member -MemberType NoteProperty -Name DisplayName -Value $user[0]
			$newEntry | Add-Member -MemberType NoteProperty -Name IMC -Value $IMC
			$file+=$newEntry
		}
  else {
		foreach ($u in $user) 
			{
				$newEntry = New-Object -TypeName PSObject
				$newEntry | Add-Member -MemberType NoteProperty -Name DisplayName -Value $u
				$newEntry | Add-Member -MemberType NoteProperty -Name IMC -Value $IMC[$c]
				$file+=$newEntry
				$c++
			}

	  }

if ($file.count -gt 2) {$file | ft -AutoSize } else {$file | fl}

Function CleanLegacyExchangeDN ([string]$imceaex) 
	
	{
			$imceaex = $imceaex.Replace("IMCEAEX-","")
			$imceaex = $imceaex.Replace("_","/")
			$imceaex = $imceaex.Replace("+5F","_")
			$imceaex = $imceaex.Replace("+20"," ")
			$imceaex = $imceaex.Replace("+28","(")
			$imceaex = $imceaex.Replace("+29",")")
			$imceaex = $imceaex.Replace("+2E",".")
			$imceaex = $imceaex.Replace("+2C",",")
			$imceaex = $imceaex.Replace("+21","!")
			$imceaex = $imceaex.Replace("+2B","+")
			$imceaex = $imceaex.Replace("+3D","=")
			$regex = New-Object System.Text.RegularExpressions.Regex('@.*')
			$imceaex = $regex.Replace($imceaex,"")
			$imceaex # return object
	}

function AddX500
	{	
	 param (
			 $user,
			 $X500
		   ) 
			Set-ADUser $user -Add @{proxyAddresses=$X500}
	}

$data=@()
foreach ($entry in $file) 
	{
		try {
			$us = Get-Recipient $Entry.DisplayName.replace("'","" ) -ErrorAction Stop
			if ($us.count -gt 1) 
					{ 
					write-host "Multiple Recipient found for user:" -n -f yellow
					write-host $Entry.DisplayName -f cyan -n
					write-host " Match SMTP from NDR" -f yellow
					Add-content -value $Entry.Displayname -path "log.txt"
					Add-content -value $(CleanLegacyExchangeDN $Entry.imc) -path "log.txt"
					$usr =$us[0].PrimarySmtpAddress.toString()
					}
			else 	{
					 $usr =$us.PrimarySmtpAddress.toString()
					}
			 
			$newEntry = New-Object -TypeName PSObject
			$newEntry | Add-Member -MemberType NoteProperty -Name user -Value $usr
			$newEntry | Add-Member -MemberType NoteProperty -Name X500 -Value $("X500:" + $(CleanLegacyExchangeDN $entry.IMC))
			$data += $newEntry
			}
	   catch{
			if ($error[0].exception -match "null-valued") 
					{                
                    write-host "Could'nt Catch Display Name From NDR." -f Red 
                    Write-host "Error Exception:" $error[0].Exception.Message
                    ""
					}
			else 	{
                write-host "Recipient Not Found or not in Correct Format" -f yellow -n 
		            ""        
					}
		   Add-content -value $error[0].Exception  -path "log.txt" 
		  }
	}

if ($data.count -gt 2) {$data | ft -AutoSize }else {$data | fl}
function getcuX500
	{
		 param ($id)
		(Get-Recipient $id).EmailAddresses | ? {$_.Prefix -match "X500"} | % {$_.ProxyAddressString}
	}

# Add X500 proxy address on user account
if ($edit) 
	{
	foreach ($u in $data) 
		{
		write-host "checking if X500 Already Exist " -f cyan
		$currentX500 = getcuX500 -id $u.User
		if ($currentX500 -like $u.x500) 
			{
			 Write-Host "X500 Already Exist for:"$u.User -f green
			}
    	else{	
			Write-host "Fixing:" $u.User
			Write-host "X500Add:" $u.X500
			Addx500 -user ((Get-Recipient $u.user).SamAccountName) -X500 $u.X500	
		    }	
	   }
	}

# Check X500 currently availble on user Acccount
if ($checkX500)
		{
		foreach ($u in $data) 
			{
			""
			write-host "Below are the currently Stampled X500 for:"$u.User -f Yellow
			$x=(Get-Recipient $u.User).EmailAddresses | ? {$_.Prefix -match "X500"} | % {$_.ProxyAddressString}
			if ($x -eq $null) 
					{
					Write-Host "No X500 Address found in Recipient ProxyAddresses List"-f cyan
					}
			else {$x}
			}
		}
