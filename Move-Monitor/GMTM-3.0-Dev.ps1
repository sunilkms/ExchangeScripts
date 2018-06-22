# this function gets Mailbox to Move based on the size.
# GMTM-2.0.ps1
# Date = 23-May-17 : Now Skips Mailbox currently being moved.
#       . Sort is now Default
#       . paramiter can be used as switch no need to type True.         
#Example:
#       . check how many Mailbox will be moved when you select 200 GB
#       . GetMbxtoMovefromDB -SizeToMoveInGB 200 -sDB 20-DB44
#       . Place the Mailbox on Move "-BIL Default value set to 40" to make the pramiter optional
#       . GetMbxtoMovefromDB -SizeToMoveInGB 200 -sDB 20-DB44 -TDB 20-DB31 -MRS Sw20CAS03 -move
#       . Added DB check in advanced.
#       . added Post Move Size check to prevent the over move size requst.
#

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
try {
$dbcheck= Get-MailboxDatabase $db -ea stop
} catch {
Write-host "Database `'$db'` not Found, Please type the correct database name."
break
}

write-host "
Getting Mailbox to move Based on Size selected.."	
$mbxs=@()

if ($sort)
  {
    $allMbx=Get-Mailbox -Database $db -ResultSize Unlimited
    foreach ($user in $allMbx) 
    {        
        if (Get-MoveRequest $user -ErrorAction Silentlycontinue) {
        #"Mbx beeing moved" 
        }        
        else {
        $m=Get-MailboxStatistics $user;
        $mbxs+=$m
        } 
    }
   $mbxs = $mbxs | sort TotalItemSize
 }

# Empty array to Save Mailbox to Move
$MbxtoMove=@()

#Collect size in below container
$tempSize=@()

#Required Max Size in MB
[int]$SizetoMoveinMB=$SizeToMoveInGB*1024

$a=0

do {
 
 $tempsize += $mbxs[$a].TotalItemSize.Value.ToMb()
 $exception="InvokeMethodOnNull"
 
 if($Error) {
            if ($Error[0].FullyQualifiedErrorId -eq $exception) 
            {write-host "Not Enought Mailbox, please try with lower size." -f Yellow ;Break } 
            }

        $Tempsize = ($Tempsize | Measure-Object -Sum).Sum
        $A++
        if ($tempsize -lt $SizetoMoveinMB) { 	        
	    $MbxtoMove+=$mbxs[$a].DisplayName            
        } Else {
        $A--
	    $tempsize=($tempsize - $mbxs[$a].TotalItemSize.Value.ToMb())
        break
        }                      
  } while ($tempsize -lt $SizetoMoveinMB)

 $total = [math]::Round(($tempsize/1024),2)
 
 	if ($sort) {  
                write-host "No Of Mailbox Selected:"$(($MbxtoMove.count) - 1)
 			    write-host "TotalSize Selected:$total"GB
	           } 
    else  {
             write-host "No Of Mailbox Selected:"$(($MbxtoMove.count) - 1)
             write-host "TotalSize Selected:$total"GB -n
             Write-Host " Next Mailbox Size is" $mbxs[$a].TotalItemSize.Value.ToGB() "GB try `'-sort:`$true' switch to sort mbx based on size" -f Yellow
          }

$M = $MbxtoMove | select -index (0..$(($mbxtomove.count)-2)) | get-mailbox | ? {$_.Database -like $db -and $_.Name -notlike "SystemMailbox*"}

write-host "preparing list.."

$b=@()
foreach ($u in $M) {
#write-host "host" $u.Alias
$ff = Get-MailboxStatistics $u.Alias | select DisplayName, TotalITemSize, Database, @{n="alias";e={$U.alias}} 
$B += $ff
}

if (!$move) {
$b
Write-host "
To Move the above Mailbox add param `'-Move:`$True''-tdb exampleDB'`-MRS 'exampleSrv' `'-BIL 30'" -f Yellow			
	    } else {
        $TotalMovedSize=@()
		write-host "Placing selected Mailbox on moves"
		foreach ($user in $b) {		
        $m=	New-MoveRequest $user.Alias -TargetDatabase $TDB -MRSServer $MRS -BadItemLimit $BIL
        $m
        $TotalMovedSize+=$m.TotalMailboxSize.TOKB()
        $TMSGB=[math]::Round((($TotalMovedSize | measure -Sum).Sum/1024/1024))
        if ($TMSGB -gt $SizeToMoveInGB){"Already Reached the requested move size"; Break }
	   }
	}
""
Write-Host "Total Move Request Mailboxes Size:$TMSGB GB" -f green
Get-MoveRequest -MoveStatus Queued | Suspend-MoveRequest -Confirm:$false
}

#Cleanup Database--------------------------------------

function CleanUp-Database {
param ($database)
$Mailboxes = Get-MailboxStatistics -Database $database | where {$_.DisconnectReason -eq “SoftDeleted”}
if ($mailboxes -eq $null) {"no mailbox found in the db for cleanup"} else {
Write-host "Mailbox found for cleanup:"$Mailboxes.Count -f cyan
"cleaning..."
$Mailboxes | foreach {Remove-StoreMailbox -Database $_.database -Identity $_.mailboxguid -MailboxState SoftDeleted -Confirm:$False}
"done."
 }
}

Function CleanCompMoveRequest {

"Getting Completed Mailbox Move Request"
$completed = Get-MoveRequest -MoveStatus Completed
write-host "Found Completed move Request to remove:" $completed.count
$completed | Remove-MoveRequest -Confirm:$false
"Done"

}
