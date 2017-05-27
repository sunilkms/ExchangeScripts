# Move-Moniter-6.0.ps1
# Author: Sunil Chauhan

# This Script moniters Mailbox logdrive space and mailbox move and takes required action suspened or resume the move automatically.
# Version 1.0 ::: Moniter Log drive space and if it less then 55% suspend moves.
# Version 1.5 ::: Target DB Circuler Logging check added, Enable or Disable if required.
# Version 2.5 ::: Auto Resume Feature Added for suspened and failed moves as well.
# Version 3.5 ::: Less CPU overhead, only Queary Log space for DB which is beeing monitored.
#                 DATAbase Size info added.
# Version 4.5 ::: Email Reporting Added.
# Version 5.5 ::: Post Move taskes Added, Auto disable circuler loggin if log drive free 90%
#                 Auto Clean Move Requests, Auto DB Cleanup
# Version 6.0 ::: Add throtteling upto 5 mbx, when resuming mailbox
#

cls
"start move Monitor.."
$DiskTh="55"
$sDiskTh="95"
$skipDb=@()
$ExitCode="FORCE"
#====Edit Recipient Details for Notification=====================
$to="Sunil.chauhan@xyz.com","nerajendra-c@xyz.com"
$From="Sunil.chauhan@xyz.com"
$Smtp="smtpserver"
#================================================================ 

#Function to Get Database Free Space
function GetDBFreeSpace {
		Param ($DB)		
		$dbinfo = get-mailboxdatabase $DB
		$server = $dbinfo.server
		$EDB=$dbinfo.edbfilepath.pathname.split("\")[2]
		$log=$dbinfo.logfolderpath.pathname.split("\")[2]
		$DBDRiveS=Get-WmiObject -ComputerName $server -Class win32_volume | Select Capacity,FreeSpace,Label
		$DBD=@()

$edbs=$DBDRiveS | ? {$_.Label -eq $edb } | Select Label, @{n="Capacity GB";E={[math]::round($_.Capacity / 1073741824)}}, 
@{n="FreeSpace GB";E={[math]::round($_.FreeSpace / 1073741824)}}, @{Name="Free(%)" `
;expression={[math]::round(((($_.FreeSpace / 1073741824)/($_.Capacity / 1073741824)) * 100),0)}}
$dbd += $edbs
$log=$DBDRiveS | ? {$_.Label -eq $log } | Select Label, @{n="Capacity GB";E={[math]::round($_.Capacity / 1073741824)}}, 
@{n="FreeSpace GB";E={[math]::round($_.FreeSpace / 1073741824)}}, @{Name="Free(%)"; `
expression={[math]::round(((($_.FreeSpace / 1073741824)/($_.Capacity / 1073741824)) * 100),0)}}
$dbd += $log
$dbd
}

#Function To Remove Mailbox data from the Database
function CleanUp-Database 
{
param ($database)
$Mailboxes = Get-MailboxStatistics -Database $database | where {$_.DisconnectReason -eq “SoftDeleted”}
                if ($mailboxes -eq $null)
                      {
                      Write-Host "no mailbox found in the db for cleanup"
	      	      } 
                 else 
                     { 
                      Write-host "Mailbox found for cleanup:"$Mailboxes.Count -f cyan
		      Write-Host "cleaning..."
		      $Mailboxes | % {
		      Remove-StoreMailbox -Database $_.database -Identity $_.mailboxguid -MailboxState SoftDeleted -Confirm:$False
		        }
		        Write-Host "done."
		     }
}

#Function to Cleanup Completed Move Requests
Function CleanCompMoveRequest 
{
 write-host "Getting Completed Mailbox Move Request"
 $completed = Get-MoveRequest -MoveStatus Completed -ResultSize Unlimited

 if ($completed) 
 {
		write-host "Found Completed move Request to remove:" $completed.count
		$completed | Remove-MoveRequest -Confirm:$false
		write-host "DOne" } else {"ALL clear, No completed Move Request found."}
 }
 
#Mail Loop
DO {
Clear-Content "movemonlog-test.txt"
#ALL Queued Mailbox Move Request
$queued=Get-MoveRequest -MoveStatus Queued

#All inprogress Move Requests
$MoveRequest=Get-MoveRequest -moveStatus Inprogress -ResultSize Unlimited

#All Suspend Move Requests
$SmoveRequest=Get-MoveRequest -moveStatus Suspended

#Get unique DB for Monitor 
$DataBasetoMonitor=$moveRequest | Select TargetDatabase -Unique
$SdatabaseToMonitor=$smoveRequest | Select TargetDatabase -Unique

if ($DataBasetoMonitor -eq $null -and $SdatabaseToMonitor -eq $null) 
   {
    $ExitCode="NORMAL"
    "No Mailbox move in progress, Monitor will terminate.." 
    Break
   } 
Else
   {
   	Write-Host "
    Mailbox Move InProgress:" -n
	  Write-host "" $MoveRequest.Count -f cyan -n
	  Write-host " Queued:" -n

#Display Suspend Move info only if there are Suspend Moves
    if ($sDataBasetoMonitor)
	   {
		Write-Host "" $Queued.count -f Yellow -NoNewline
		Write-host " Suspended:" -n
		Write-host ""$SmoveRequest.count -ForegroundColor Yellow
	   }
	else 
	   {Write-Host "" $Queued.count -f Yellow}
       
       if ($DataBasetoMonitor.count -gt 1) { $dtmc = $DataBasetoMonitor.count} else {$dtmc=1}
       Write-Host "Total DB to monitor" $dtmc -f cyan      
      }
	    Add-Content -Value "Mailbox Move InProgress:$($MoveRequest.Count) Queued:$($Queued.count)" -Path "movemonlog-test.txt"
      Add-Content -Value "Total DB to monitor:$dtmc" -Path "movemonlog-test.txt"

if ($DataBasetoMonitor) {

#Get the Logfiles disk space stats
foreach ($Sdb in $DataBasetoMonitor)
     {
      
      $db=($Sdb).TargetDatabase.Name
      $ldn=$(Get-MailboxDatabase $db).Logfolderpath.PathName.split("\")[2]
      
      #Circular Logging Status of Database
	    $CLstatus = (Get-MailboxDatabase $db).CircularLoggingEnabled
      $CLvalueG = "Green" 
      $CLvalueR = "REd"
      $CL = if ($clstatus -eq "true") { $CLvalueG } else {$CLvalueR}
      
	    ""
      Write-host "**************************************************"
      Add-Content -Value "**************************************************" -Path "movemonlog-test.txt"

      Write-Host $DB":" -f yellow -NoNewline
      Add-Content -Value "$DB" -Path "movemonlog-test.txt"
      write-host " Free Space in DB:" -n
      Write-host $(GetDBFreespace $DB)[0].'Free(%)' -f cyan -NoNewline
      Write-host "(%)"
      Write-host "CircularLoggingEnabled: " -n
      Write-host $CLstatus -f $cL
      Add-Content -Value "Free Space in DB:$($(GetDBFreespace $DB)[0].'Free(%)') %" -Path "movemonlog-test.txt"
      
      #Block To Enable Circuler Logging on the Database
	    if ($clstatus -eq 0)
            {
	            Write-host "Enabling Circular Logging for DB" $db
              Set-MailboxDatabase $db -CircularLoggingEnabled:$True
              Add-Content -Value "Enabling Circular Logging for DB:$db" -Path "movemonlog-test.txt"
	          }
            
      $Move = Get-MoveRequest -TargetDatabase $db -ResultSize Unlimited
      Add-Content -Value "Total Mailbox Move to Target DB:$($move.count)" -Path "movemonlog-test.txt"
      
      $comp = $move | ? {$_.Status -like "Completed"}
      $compinp = $move | ? {$_.Status -like "inprog*"}
      $failed = $move | ? {$_.Status -like "Fail*"}
      $SourceDB = $move | select SourceDatabase -Unique
      
      Write-host "Source Database:" $SourceDB.SourceDatabase.Name
      Add-Content -Value "Source Database:$($SourceDB.SourceDatabase.Name)" -Path "movemonlog-test.txt"
	    Write-host "MoveRequest Completed:" -n
      Write-Host $($Comp.count)"" -f cyan -n
      Add-Content -Value "MoveRequest Completed:$($Comp.count)" -Path "movemonlog-test.txt"
	    Write-Host "Inprogress:" -n
      Add-Content -Value "Inprogress:$($compinp.count)" -Path "movemonlog-test.txt"
      
      if ($failed) { Write-Host $($compinp.count) -n -f Cyan
      
      Add-Content -Value "Failed:$($Failed.count)" -Path "movemonlog-test.txt"
	    Write-Host " Failed:" -n -f Cyan
      Write-Host $($Failed.count) -f yellow
      
	    Write-Host "Resumeing Failed Moves.."
      Add-Content -Value "Resumeing Failed Moves.." -Path "movemonlog-test.txt"
      Get-MoveRequest -targetDatabase $db -moveStatus "Failed" | Resume-MoveRequest -Confirm:$false
      } else {Write-Host $($compinp.count) -f Cyan}
 
      $Free=$(GetDBFreespace $DB)[1].'Free(%)'

#Suspened Move Request	
if ($free -lt $DiskTh) {
		 Add-Content -Value "Log drive space Free(%):$free" -Path "movemonlog-test.txt"
		 Write-Host "Log Drive space seems to be high for DB:$db" " Free(%):$Free" -f Yellow
		 Write-Host "Move Monitor will suspend Mailbox moves for:$db" -f Yellow
		 Add-Content -Value "Log Drive space seems to be high for DB:$db" -Path "movemonlog-test.txt"
     Add-Content -Value "`nMove Monitor will suspend Mailbox moves for:$db" -Path "movemonlog-test.txt"			
		 $TotMove=Get-MoveRequest -TargetDatabase $db -moveStatus Inprogress
		 Write-Host "Total Move in progress:"$($totMove.count)
			
		 #Suspend Mailbox Move
		 $TotMove | Suspend-MoveRequest -confirm:$false
		 $n=Get-MoveRequest -TargetDatabase $db -moveStatus Inprogress
		 $ns=
		 Write-Host "Move Suspended:"($totMove.count - $n.count)
     Add-Content -Value "`nMove Suspended:$($totMove.count - $n.count)" -Path "movemonlog-test.txt"
     Add-Content -Value "**************************************************" -Path "movemonlog-test.txt"
			
		 #Send Notification
		 $suspendSub="Mailbox Move Monitor: Move Suspended for:$DB"
		 Send-MailMessage -to $to -From $From -Subject $suspendSub -SmtpServer $smtp
	} 
else 
   {
		 Write-host "Log drive space Free(%):" -n
		 Write-host $Free  -f Green
		 Add-Content -Value "Log drive space Free(%):$free" -Path "movemonlog-test.txt"
		 Write-host "**************************************************"
     Add-Content -Value "**************************************************" -Path "movemonlog-test.txt"
	 } 
 }
}

#Monitor Suspending Move Request
if ($sDataBasetoMonitor) 
	{
      Write-Host "**************************************************"
			Write-Host "Suspened MoveRequest Found:"$SmoveRequest.count -ForegroundColor Cyan
			Write-Host "Checking if MoveRequest can be Resume."
      Add-Content -Value "Suspened MoveRequest Found:$($SmoveRequest.count)" -Path "movemonlog-test.txt"
      Add-Content -Value "Checking if MoveRequest can be Resume." -Path "movemonlog-test.txt"
	    foreach ($susDB in $sDataBasetoMonitor) 
			{                             
       $db=($Susdb).TargetDatabase.Name
       if ($skipDb | ? {$_ -like $db}) {write-host "DB is on Skip List, Move Will not be resumed for DB"$db}
       else {                
             $Free = $(GetDBFreespace $DB)[1].'Free(%)'                                
				    if ($free -gt $sDiskTh) 
				       {
                Add-Content -Value "$db" -Path "movemonlog-test.txt"
					      Write-Host "LogDrive space seems to be normal now for DB:" -n
					      Write-Host $db -f yellow -NoNewline
					      Write-Host " Free(%):" -NoNewline
					      write-host $Free -f Yellow
					      write-host "MoveMonitor will Resume Mailbox move for DB:"$db -f Green
                Write-Host "**************************************************"
                Add-Content -Value "LogDrive space seems to be normal now,LogDrive free(%):$free" -Path "movemonlog-test.txt"
                Add-Content -Value "`nResuming Mailbox move Requests." -Path "movemonlog-test.txt"
                Add-Content -Value "`nonly first 5 mailbox will be resume at a time." -Path "movemonlog-test.txt"

                if ($SmoveRequest.count -gt 5)
                   {
                    Get-MoveRequest -TargetDatabase $DB -moveStatus Suspended | select -First 5 | Resume-MoveRequest -Confirm:$false }
                else {Get-MoveRequest -TargetDatabase $DB -moveStatus Suspended | Resume-MoveRequest -Confirm:$false}

                Add-Content -Value "`nMailbox Move Has been Resumed." -Path "movemonlog-test.txt"
                Add-Content -Value "**************************************************" -Path "movemonlog-test.txt"
					      $sub="MoveMoniter:Mailbox Move has been Resumed for:$DB"
                Send-MailMessage -to $to -From $from -Subject $sub -SmtpServer $smtp
					}
				else{
				     write-host "DB size still high, MoveMonitor will auto resume Mailbox Moves when LogDrive has 90% Free Space."
             write-host "Currently Free(%):" -n
             Write-Host $Free -ForegroundColor Cyan
             Write-Host "**************************************************"
             Add-Content -Value "DB size still high, MoveMonitor will auto resume Mailbox Moves when LogDrive has 90% Free Space." -Path "movemonlog-test.txt"
             Add-Content -Value "Currently Free(%):$free" -Path "movemonlog-test.txt"
             Add-Content -Value "**************************************************" -Path "movemonlog-test.txt"
					 }       
         } 
       }
	}

#Write progress for waiting time..
$suspendSub="Mailbox Move Monitor-status"
Send-MailMessage -to $to -From $From -Subject $suspendSub -SmtpServer $smtp -Body (cat movemonlog-test.txt | Out-String)
"SLEEP FOR 5 MIN"
0..50 | % {sleep $(300/50); Write-Host "*" -n -f Yellow}    
cls
} until ($moveRequest -eq 0 -and $sDataBasetoMonitor -eq 0)

#post Move Completion Tasks
if ($ExitCode -eq "NORMAL") 
	{
        write-host "PostMove Tasks Begins.."
		    write-host "Getting SourceDatabase for Cleanup."
        Add-Content -Value "" -Path "movemonlog-test.txt"
        Add-Content -Value "PostMove Tasks Begens.." -Path "movemonlog-test.txt"
		    $completedmoveRequest = Get-MoveRequest -moveStatus Completed -ResultSize Unlimited
		    $SourceDataBase = $completedmoveRequest | Select SourceDatabase -Unique
        $TargetDataBase = $completedmoveRequest | Select TargetDatabase -Unique

if ($SourceDataBase) 
		    {	
			   foreach ($sdb in $SourceDataBase) 
				  {
					$db=($sdb).SourceDatabase.Name
					write-host "Cleaning up SourceDatabase:"$db
          Add-Content -Value "Cleaning up SourceDatabase:$db" -Path "movemonlog-test.txt"
					CleanUp-Database $db
		      }
			}
else{
		    write-host "No SourceDatabase found for Cleanup."
        Add-Content -Value "No SourceDatabase found for Cleanup." -Path "movemonlog-test.txt"
			}
		  if ($TargetDataBase)            
            {
             foreach ($tdb in $TargetDataBase) 
                    {
                     $db=($tdb).TargetDatabase.Name
		                 write-host "Checking if Circular Logging can be disabled for DB"$db
                     Add-Content -Value "------------------------------------------------------------------------" -Path "movemonlog-test.txt"
                     Add-Content -Value "Checking if Circular Logging can be disabled for DB:$db" -Path "movemonlog-test.txt"
                     $Free=$(GetDBFreespace $DB)[1].'Free(%)'
                     if ($free -gt 80) 
			                  {				
                        write-host "Circular Logging has been disabled for Target DB"$db
				                Set-MailboxDatabase $db -CircularLoggingEnabled:$false
                        Add-Content -Value "`nCircular Logging has been disabled for Target DB:$db" -Path "movemonlog-test.txt"
                        Add-Content -Value "------------------------------------------------------------------------" -Path "movemonlog-test.txt"
			                  } 
			               else
			                  { 
		                    write-host "LogDrive Space is still less then 80% Circular Logging will be kept Enabled For the moment"-f yellow	
                        Add-Content -Value "`nLogDrive Space is still less then 80%" -Path "movemonlog-test.txt"
                        Add-Content -Value "Circular Logging will be kept Enabled For the moment" -Path "movemonlog-test.txt"				
			                  }
                     } 
            }
	
       write-host "Removing Completed Move Request."
       Add-Content -Value "`nRemoved Completed Move Request" -Path "movemonlog-test.txt"
       CleanCompMoveRequest
       $suspendSub="Mailbox Move Monitor-Post Move Completion Tasks Status"
       Send-MailMessage -to $to -From $From -Subject $suspendSub -SmtpServer $smtp -Body (cat "movemonlog-test.txt"| Out-String)
    }
