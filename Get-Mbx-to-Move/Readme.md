Author : Sunil Chauhan
Blog : http://www.sunilchauhan.info/2017/02/powershell-script-for-exchange-admins.html

This function gets Mailbox to Move based on the size.
 
Date = 23-May-17 : 
 * Now Skips Mailbox currently being moved.
 * Sort is now Default
 * paramiter can be used as switch no need to type True.
 * "-BIL Default value set to 40" to make the pramiter optional

Example:
###        check how many Mailbox will be moved when you select 200 GB
>        GetMbxtoMovefromDB -SizeToMoveInGB 200 -sDB DB20
###        Place Mailboxes on Move use "-Move" parameter
"-MRS" is a required parameter, a default value could be set in the scirpt.
>        GetMbxtoMovefromDB -SizeToMoveInGB 200 -sDB DB20 -TDB DB31 -MRS CAS03 -move
