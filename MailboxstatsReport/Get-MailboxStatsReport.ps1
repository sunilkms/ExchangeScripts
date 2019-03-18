#
#
#
#

$mbx = get-mailbox -Server <Server>
$MbxSts = $mbx | Get-MailboxStatistics | Select DisplayName,ServerName,DatabaseName, MailboxTypeDetail,LastLogonTime, `
@{N="TotalSizeInGB";E={$_.TotalItemSize.Value.togb()}},ItemCount
$mbxsts | export-csv "MailboxStsReport.csv"
