# this function gets Mailbox to Move based on the size.
# GMTM-3.0-Dev.ps1
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
