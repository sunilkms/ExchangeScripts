# Author : Sunil Chauhan
# Email: Sunilkms@gmail.com
# Example 1 -: Get-MessageTrace -Sender Sunil.chauhan@xyz.com -Recipient testuser@xyz.com
# Example 2 -: Get-MessageTrace -Sender Sunil.chauhan@xyz.com
# Example 3 -: Get-MessageTrace -Recipient testuser@xyz.com

# By Default only 24 hours of logs will be searched, for tracking last 3 Days

# Example 4 -: Get-MessageTrace -Sender Sunil@xyz.com -Recipient testuser@xyz.com -days 3
# Example 5 -: Get-MessageTrace -Sender Sunil.chauhan@xyz.com -days 3
# Example 6 -: Get-MessageTrace -Recipient Sunil.chauhan@xyz.com -days 3 

function Get-MessageTrace {
        param(
        $sender,
        $Recipients,
        $days= 1
        )
write-host "By Default only 24 hours of logs will be searched, you can use parameter '-days 3' to search 3 days old logs" -ForegroundColor Yellow

$days= "-" + $days
$TS = Get-TransportServer
$report=@()

#Recipient Search Block
if ($Recipients -ne $null -and $sender -eq $null)   
   {
        foreach ($Server in $ts) 
        {
        $Logs=Get-MessageTrackingLog -Recipients $Recipients -Start (get-date).AddDays($days) -Server $Server.Name -ResultSize unlimited
        $Report+=$logs        
        }
        if ($report)
             { 
             $report | Select Sender,Recipients,MessageSubject,EventId,Timestamp,RecipientStatus | sort timestamp -Descending
             } 
  }

#Sender Search Block
if ($sender -ne $null -and $Recipients -eq $null)
  { 
        foreach ($Server in $ts)         
        {
        $Logs=Get-MessageTrackingLog -Sender $sender -Start (get-date).AddDays($days) -Server $Server.Name -ResultSize unlimited
        $Report+=$logs
        }
        if ($report)
                 { 
                 $report | Select Sender,Recipients,MessageSubject,EventId,Timestamp,RecipientStatus | sort timestamp -Descending
                 }
  }

#Recipient & Sender Search Block
if ($Recipients -ne $null -and $sender -ne $null)      
  {
        foreach ($Server in $ts) 
        {
        $Logs=Get-MessageTrackingLog -Recipients $Recipients -Start (get-date).AddDays($days) -Server $Server.Name -ResultSize unlimited
        $Report+=$logs
        }
        if ($report)
                 { 
                 $report | ? {$_.Sender -like $sender }| Select Sender,Recipients,MessageSubject,EventId,Timestamp,RecipientStatus | sort timestamp -Descending
                 }
   }
}
