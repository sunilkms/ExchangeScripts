# This script will cleanup the messages older then One day from the Shedow Queue
Param(
[Parameter(Mandatory=$True)]
[string]$server
)

$queues = @()
$messages = @()
$currentdate =  (get-date(get-date -Format G)).AddDays(-1)

#Get shadow redundancy queues which are on the server
$queues = get-queue -server $server|where {$_.DeliveryType -eq "ShadowRedundancy" -AND $_.MessageCount -gt "0" }

#Find messages in the shadow redundancy that are older then one day and remove them without confirmation
Foreach ($queue in $queues)
        {
         $messages = @(get-message -queue $queue.Identity|where {$_.DateReceived -lt $currentdate}|select Identity)
	 If ($messages -ne $null){											
		   		  Write-Host "Messages found in queue" $queue.identity":" $messages.count -ForegroundColor Red       
                                  Foreach ($message in $messages)
                                                                {
								 Remove-message -identity $message.Identity -WithNDR $false -Confirm:$False
								 }
								 
				   Write-Host "Cleanup of shadow redundancy queue" $queue.identity "completed" -ForegroundColor Green
				   Write-Host ""
				   }
	 else {
	       Write-Host "No messages where found to cleanup in shadow redundancy queue" $queue.identity -ForegroundColor Green
	       Write-Host ""
	       }
       }
							
