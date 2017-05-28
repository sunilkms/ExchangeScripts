#Recreate Database in Exchange Server 2010 Environment
#

function Delete-Database-Copies {

Param ($dbToBeRecreated)

Write-host "DB selected for Recreation:" -n
Write-host $dbtoberecreated -f Cyan
sleep 2
"Pre recreation Check Bagens..."

Write-host "Test:1 - Checking if DB has any mailbox:" -NoNewline
sleep 2
$mbx = Get-Mailbox -Database $dbtoberecreated

if ($mbx) {
            Write-Host "FAILED" -ForegroundColor Red
	        Write-host "DB recreation can not be Continue, as DB still contains the Mailboxes" -ForegroundColor Yellow
            Write-host "No of Mailbox in DB:" -n
            Write-host $($mbx.count) -f Cyan
           "Please move the Mailbox and try again"
	        break
	     }
    Else {
            Write-Host "PASS" -ForegroundColor Green
	        Write-Host "Test:2 - Checking if Circulerlogging in enabled:" -NoNewline
		    sleep 2		 
			if ((get-Mailboxdatabase $dbtoberecreated).CircularLoggingEnabled) 
					  {
					    Write-Host "FAILED" -ForegroundColor Red
                        Write-Host "Circulerlogging is Eanbled on the Database." -ForegroundColor Yellow
                        Write-Host "Disabling Circulerlogging:" -NoNewline
						Set-Mailboxdatabase $dbtoberecreated -CircularLoggingEnabled:$false
						Write-Host "Disabled." -ForegroundColor Cyan
					 }
				else {
                        Write-Host "PASS" -ForegroundColor Green
					 }

#Step 3
        Write-Host "Test:3 - Checking if Backup is in progress:" -NoNewline
		sleep 2

        if (!(Get-MailboxDatabase -Status -Identity $dbToBeRecreated).BackupInProgress) 
             {Write-Host "PASS" -ForegroundColor Green}
        Else {        
                Write-Host "Failed" -ForegroundColor Green
                sleep 2
                Write-Host "Backup for the Database is currently in progress."
                "Please try Recration of the DAtabase once the Backup is finished."
	            break        
             }
        Write-host "DB Recreation process begen.." -f Yellow
		Write-Host "Step:1 - Remove DB copies.."
        Write-Host "Next Step will Remove Copies for DB:" -n
        Write-Host $dbToBeRecreated -ForegroundColor Cyan
        Read-Host  "Press Enter To Contine.. or Press Ctrl + C to Exit"

        $databaseAllCopies = Get-MailboxDatabaseCopyStatus $dbtoberecreated
 	$databasepassiveCopies = $databaseAllCopies | ? {$_.Status -like "Healthy"}
		      
        #$databasepassiveCopies | Remove-MailboxDatabaseCopy -WhatIf
        Write-Host "Step:2 - Removing EDB file and Log Files of Database Copies.."
		
			foreach ($databaseCopy in $databasepassiveCopies)
					{
					
                    Write-Host "Getting Path for Logfile and EDB"
					$server = $databaseCopy.Mailboxserver
					write-host "DB Copy Located on Server:" -n
					write-host $server -f Cyan
					$db = get-Mailboxdatabase $dbtoberecreated
					$DatabaseEDBfilepath = $db.EdbfilePath.PathName
					$DatabaseLogfolderpath = $db.LogFolderPath.PathName
                    Write-Host "Step 2A - Remove EDB file"
					"Converting to UNC Path to access EDB file"
		    
					$driveL=$DatabaseEDBfilepath.split("\")[0]
					$driveL=$driveL.replace(":","$")
                    #$edbpath="\\"+"$server"+"\"+  $driveL + "$($DatabaseEDBfilepath.split("\")[1])"+ "\" + "$($($DatabaseEDBfilepath.split('\')[2]))"
	                $edbpath="\\"+"$server"+"\"+  $driveL + "$($DatabaseEDBfilepath.split(":")[1])"
                    $allFiles = Get-ChildItem $edbpath
			$edbname=(Get-ChildItem $edbpath).Name.tostring()
			$edbpath=$edbpath.Replace($edbname,"")                           

		    Write-Host "Path:"-NoNewline
            Write-Host $edbpath -f Yellow
          
                    if (Test-Path $edbpath) 
                        {
                            Set-Location $edbpath
                            Write-Host "Now Will Delete The EDB File."
                            $allFiles = Get-ChildItem $edbpath
                            $EDB = $allFiles | ? {$_.Name -like "*.EDB"}
                            Write-Host "Deleting EDB:" -NoNewline
                            Write-Host $edb.Name -f Cyan
                            Write-Warning "Next Step will Remove EDB"
                            Read-Host  "Press Enter To Contine.. or Press Ctrl + C to Exit"                                                                                  
                        }
                    Else
                        {
                            Write-Host "Step 2a - Failed" -ForegroundColor Red
                            Write-Host "EDB File Path Was Not Found"
                            Write-Host "Please check if the Path is accessable"
                            "Path : $edbpath"
                            Write-Host "Step 2a - Failed" -ForegroundColor Red
                        }

                    Write-Host "Step 2B - Cleanup LogDrive"
                    Write-host "Converting to UNC Path to access Log DIR:" -NoNewline
                    Write-Host $DatabaseLogfolderpath -ForegroundColor Cyan
					$driveL=$DatabaseLogfolderpath.split("\")[0]
					$driveL=$driveL.replace(":","$\")
                    $LogPath="\\"+"$server"+"\"+"$($DatabaseLogfolderpath.split("\")[1])"+ "\" + "$($($DatabaseLogfolderpath.split('\')[2]))"
                 
                    Write-Host "Now Will Delete The log File."
					if (Test-Path $logpath)

                        {
                            #Set-Location $logpath
                            Write-Host "Now Will Delete The EDB File."
                            $allFiles = Get-ChildItem $logpath
                            Write-Host $allfiles.count
                            Write-Warning "Next Step will Remove all LogFiles from:$logpath"
                            Read-Host  "Press Enter To Contine.. or Press Ctrl + C to Exit"
                            Write-Host "Deleting Logfiles:"
                            #$allFiles | Remove-Item				
					   }		 
	             }
		
		Write-Host "Step 3 - Dismount Active Database copy"
		# Get-Active Datbase Copy
		if (!(Get-Mailbox -Database $dbtoberecreated)) {
				"PreDismount Check Passed, No Mailbox Found"
				"Datbase will be dismounted."
			    Dismount-Database $dbtoberecreated -WhatIf
		      }
		if (!(Get-MailboxDatabase $dbtoberecreated -Status).Mounted) 
			{
				"Successfully Dismounted the DB."
				Write-Host "Step 4 - Remove EDB and Log Files of Active DB."
				Write-Host "Step 4a - Remove EDB of Active DB."
				$server=((Get-MailboxDatabase $dbtoberecreated).Server.Name)

				$driveL=$Database.EDBfilepath.split("\")[0]
				$driveL=$driveL.replace(":","$\")
                $edbpath="\\"+"$server"+"\"+  $driveL + "$($DatabaseEDBfilepath.split("\")[1])"+ "\" + "$($($DatabaseEDBfilepath.split('\')[2]))"
                Write-Host "Path:"-NoNewline
                Write-Host $edbpath -f Yellow
				
				if (Test-Path $edbpath) 
                        {
                            #$Set-Location $edbpath
                            Write-Host "Now Will Delete The EDB File."
                            $allFiles=Get-ChildItem $edbpath
                            $EDB = $allFiles | ? {$_.Name -like "*.EDB"}
                            Write-Host "Deleting EDB:" -NoNewline
                            Write-Host $edb.Name -f Cyan
                            Write-Warning "Next Step will Remove EDB"
                            Read-Host  "Press Enter To Contine.. or Press Ctrl + C to Exit"
                            # $EDB | Remove-Item                                                       
                        }
                    Else
                        {
                            Write-Host "Step 4a - Failed" -ForegroundColor Red
                            Write-Host "EDB File Path Was Not Found"
                            Write-Host "Please check if the Path is accessable"
                            "Path : $edbpath"
                            Write-Host "Step 4a - Failed" -ForegroundColor Red
                        }		
				
			 $driveL=$DatabaseLogfolderpath.split("\")[0]
			 $driveL=$driveL.replace(":","$\")
             $LogPath="\\"+"$server"+"\"+"$($DatabaseLogfolderpath.split("\")[1])"+ "\" + "$($($DatabaseLogfolderpath.split('\')[2]))"                 
             Write-Host "Now Will Delete The log File."

			 if (Test-Path $logpath)

                        {
                            #Set-Location $logpath
                            Write-Host "Now Will Delete The EDB File."
                            $allFiles = Get-ChildItem $logpath
                            Write-Host $allfiles.count
                            Write-Warning "Next Step will Remove all LogFiles from:$logpath"
                            Read-Host  "Press Enter To Contine.. or Press Ctrl + C to Exit"
                            Write-Host "Deleting Logfiles:"
                            #$allFiles | Remove-Item				
					   }				
			}
	   else {
			  "DB Dismounted unsuccessfull"; 
			   Break
			}			 
       }
}

#Revelidate 



if ($SetupCopies){



}

#recreate Sequence
#0 - Validate if DB can be recreated - completed.
#1 - Remove DB copies First - Completed.
#2 - Remove Logfile and Edb files foreach copy
#3 - Dismound The Active DB
#4 - Remove edb and logs
#$database = 
