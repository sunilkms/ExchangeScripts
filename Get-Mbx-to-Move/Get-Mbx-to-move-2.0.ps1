# Author : Sunil Chauhan
# Blog : http://www.sunilchauhan.info/2017/02/powershell-script-for-exchange-admins.html
#
# This function gets Mailbox to Move based on the size.
# GMTM-2.0.ps1
# Date = 23-May-17 : Now Skips Mailbox currently being moved.
#       . Sort is now Default
#       . paramiter can be used as switch no need to type True.       
#
#Example:
#       . check how many Mailbox will be moved when you select 200 GB
#       . GetMbxtoMovefromDB -SizeToMoveInGB 200 -sDB DB20
#       . Place the Mailbox on Move "-BIL Default value set to 40" to make the pramiter optional
#       . GetMbxtoMovefromDB -SizeToMoveInGB 200 -sDB DB20 -TDB DB31 -MRS CAS03 -move 

function GetMbxtoMovefromDB {

      param(
 		            [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=0)]		    
		            [int]$SizeToMoveInGB,
		            $sDB,
		            [switch]$sort=$true,
		            $TDB,
                [switch]$move=$false,
		            $MRS,
		            $BIL=40                             
     	      )

$db=$sdb
write-host "
Getting Mailbox to move Based on Size selected.."	
$mbxs=@()

if ($sort)
  {
    $allMbx=Get-Mailbox -Database $db -ResultSize Unlimited
    foreach ($user in $allMbx) 
        {        
          if (Get-MoveRequest $user -ErrorAction Silentlycontinue) 
            {
             #"Mbx beeing moved" 
            }        
          else {$m=Get-MailboxStatistics $user;$mbxs+=$m} 
        }
   $mbxs=$mbxs | sort TotalItemSize
 }

#Empty array to Save Mailbox to Move
$MbxtoMove=@()

#Collect size in below container
$tempSize=@()

#Required Max Size in MB
[int]$SizetoMoveinMB=$SizeToMoveInGB*1024 
$a=0
do { 
 $tempsize += $mbxs[$a].TotalItemSize.Value.ToMb()
 $Tempsize = ($Tempsize | Measure-Object -Sum).Sum
 $A++
        if ($tempsize -lt $SizetoMoveinMB) { 	        
	    $MbxtoMove+=$mbxs[$a].DisplayName            
        } Else {
        $A--
        #Remove Last Name
        #$MbxtoMove -= $mbxs[$a].DisplayName
	      $tempsize = ($tempsize - $mbxs[$a].TotalItemSize.Value.ToMb())
        break
        }                      
  } while ($tempsize -lt $SizetoMoveinMB)

 $total = [math]::Round(($tempsize/1024),2)
 
 	if ($sort) 
      {  
			 write-host "No Of Mailbox Selected:"$(($MbxtoMove.count) - 1)
 			 write-host "TotalSize Selected:$total"GB
	    } 
   else  
     {
		   write-host "No Of Mailbox Selected:"$(($MbxtoMove.count) - 1)
       write-host "TotalSize Selected:$total"GB -n
       Write-Host " Next Mailbox Size is" $mbxs[$a].TotalItemSize.Value.ToGB() "GB try `'-sort:`$true' switch to sort mbx based on size" -f Yellow 
     }

$M = $MbxtoMove | select -index (0..$(($mbxtomove.count)-2)) | get-mailbox | ? {$_.Database -like $db -and $_.Name -notlike "SystemMailbox*"}

write-host "preparing list.."
$b=@()
foreach ($u in $M) 
   {
    #write-host "host" $u.Alias
    $ff = Get-MailboxStatistics $u.Alias | select DisplayName, TotalITemSize, Database, @{n="alias";e={$U.alias}} 
    $B += $ff
  }

if (!$move) 
  {
    $b
    Write-host "
    To Move the above Mailbox add param `'-Move:`$True''-tdb exampleDB'`-MRS 'exampleSrv' `'-BIL 30'" -f Yellow			
	  } else {
		write-host "Placing selected Mailbox on moves"
		foreach ($user in $b) {		
		New-MoveRequest $user.Alias -TargetDatabase $TDB -MRSServer $MRS -BadItemLimit $BIL
	  }
  }	
}
