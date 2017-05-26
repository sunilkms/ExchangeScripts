[Powershell Script] Get-MessageTrace For Exchange Server, {Powershell Script for Message Tracking on multiple Hub Transport Server}

Message Tracking in a large exchange environment is a tiring job, you will have to search message on each hub transport server one by one, to make this easy for myself I wrote this script function for myself, please feel free to leave your comments and feedback. 

(.) dot source the script in your PowerShell session to import the function

Example:

. .\Get-MessageTrace.ps1 <place a (.) and a space before the script> 

Example 1 -: Track Message based on Sender and Recipient

Get-MessageTrace -Sender Sunil.chauhan@xyz.com -Recipient testuser@xyz.com

Example 2 -: Track Message based on Recipient 

Get-MessageTrace -Recipient testuser@xyz.com

Example 3 -: Track Message based on Sender and Recipient

Get-MessageTrace -Sender Sunil.chauhan@xyz.com

Example 4 -: By Default script will only search for last 24 hours logs, for tracking emails over 24 hours or more period use "-Days" Parameter. 

Below example demonstrate searching for last 3 Day
# Get-MessageTrace -Sender Sunil.chauhan@xyz.com -Recipient testuser@xyz.com -days 3
# Get-MessageTrace -Sender Sunil.chauhan@xyz.com -days 3
# Get-MessageTrace -Recipient Sunil.chauhan@xyz.com -days 3
