
#Check Server Helth on a Remote Host
Test-ServiceHealth -Server LABHUB01
#start a Service on a Remote host
Invoke-Command -ComputerName LABHUB01 -ScriptBlock {Start-Service -ServiceName MSExchangeTransport }
