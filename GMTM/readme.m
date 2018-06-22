# this script contains many function to help you move mailboxes in bulk, gets Mailbox to Move based on the size.
# GMTM-3.0-Dev.ps1
# Date = 23-May-17 : Now Skips Mailbox currently being moved.
#       . Sort is now Default
#       . paramiter can be used as switch no need to type True.         
#Example:
#       . check how many Mailbox will be moved when you select 200 GB
#       . GetMbxtoMovefromDB -SizeToMoveInGB 200 -sDB DB44
#       . Place the Mailbox on Move "-BIL (BadItemLitmit) Default value set to 40" to make the pramiter optional
#       . GetMbxtoMovefromDB -SizeToMoveInGB 200 -sDB DB44 -TDB DB31 -MRS CAS03 -move
#       . Added DB check in advanced.
#       . added Post Move Size check to prevent the over move size requst.
#
