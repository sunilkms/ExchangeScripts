#Get-PSSnapin -Registered
Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.SnapIn
Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.Support

function GetDatabase-DiskStats 
{
Param ($DB)
#$dbcopy = get-mailboxdatabase $DB | Get-MailboxDatabaseCopyStatus
$dbcopy = get-mailboxdatabase $DB
    foreach ($server in $dbcopy) 
            {
            Write-Host $db #"Server: $($server.MailboxServer)"
            $dbinfo = get-mailboxdatabase $DB
            $EDB=$dbinfo.edbfilepath.pathname.split("\")[2]            
            $DBDRiveS=Get-WmiObject -ComputerName $server.Server -Class win32_volume | Select Capacity,FreeSpace,Label
            $DBD=@()
            $edbs=$DBDRiveS | ? {$_.Label -eq $edb } | Select @{n="Database";E={$_.Label}},
             @{n="Capacity GB";E={[math]::round($_.Capacity / 1073741824)}}, 
            @{n="FreeSpace GB";E={[math]::round($_.FreeSpace / 1073741824)}}, @{Name="Free(%)"; `
            expression={[math]::round(((($_.FreeSpace / 1073741824)/($_.Capacity / 1073741824))* 100),0)}}
            $dbd += $edbs            
            $dbd
            }
}

$dbs=Get-MailboxDatabase -IncludePreExchange2013 -Status | ? {$_.recovery -ne "True" -and $_.name -notlike "*Mailbox*"} | select Name, AvailableNewMailboxSpace
$ALLDbstats=@()

foreach ($db in $dbs) {

$DBstats = GetDatabase-DiskStats -DB $db.name | select Database,
@{n="Mailbox";e={(get-mailbox -Database $db.name -ResultSize 2000).count}},
"Capacity GB",
@{n="ActualDBSize GB";e={GetTotalDBSize $db.Name}},
@{n="WhiteSpaceGB";E={$db.AvailableNewMailboxSpace.toGB()}},
"FreeSpace GB","Free(%)"
$ALLDbstats+=$DBstats
$DBstats

}

$Table=$ALLDbstats | sort -Property White* -Descending

$lowDb=$Table | ? {$_."free(%)" -lt 15}
$highDb=$Table | ? {$_."free(%)" -gt 50}

$SW30=$lowDb | ? {$_.Database -like "30*"}
$SW20=$lowDb | ? {$_.Database -like "20*"}

$hSW30=$highDb | ? {$_.Database -like "30*"}
$hSW20=$HighDb | ? {$_.Database -like "20*"}

$a = "<style>"
$a = $a + "BODY{background-color:white;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;border-spacing: 10px;width:60%;}"
$a = $a + "TH{border-width: 2px;padding: 2px;border-style: solid;border-color: black;background-color:#d5ebf5;text-align:center;}"
$a = $a + "TD{border-width: 2px;padding: 2px;border-style: solid;border-color: black;background-color:#f8faf6;text-align:center;}"
$a = $a + "</style>"

$ab = "<style>"
$ab = $ab + "BODY{background-color:white;}"
$ab = $ab + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;border-spacing: 0px;width:60%;}"
$ab = $ab + "TH{border-width: 0px;padding: 2px;border-style: solid;border-color: black;background-color:#ffcc99;text-align:center;}"
$ab = $ab + "TD{border-width: 0px;padding: 2px;border-style: solid;border-color: black;background-color:#f8faf6;text-align:center;}"
$ab = $ab + "</style>"

if ($sw30) {

$SW30Boday=@"
<div style="background-color:#DCDCDC;color:#191970;padding:40px;text-align:center;width:80%;font-family:Georgia;">
$($SW30 | ConvertTo-HTML -PreContent "       
        <h3>Below Databases are found to be having space less than 15% For Exchange Site SW30</h3>" `
        -Head $a `
        -PostContent "<h3>Suggested Destination Database to Move Mailboxes</h3>" | Out-String)

   $($hSW30 | sort -Property free* -Descending | ConvertTo-HTML -Head $ab | Out-String)
   </Div>

"@ } else {

$SW30Boday=@"

"<h3>No Database found to be having space less than 15% For Exchange Site SW30</h3>"

"@
  }

$body=@"

<div style="background-color:#DCDCDC;color:#191970;padding:40px;text-align:center;width:80%;font-family:Georgia;">
<header>
   <h2 style=color:Black;><u>Shire Exchange Database low space Report</u></h2>
</header>
$($SW20 | ConvertTo-HTML -PreContent "<h3>Below Databases are found to be having space less than 15% For Exchange Site SW20</h3>" -Head $a `
        -PostContent "<h3>Suggested Destination Databases to Move Mailboxes</h3>" | Out-String)
$($hSW20 | sort -Property free* -Descending | ConvertTo-HTML -Head $ab | Out-String)
</Div>

$SW30Boday

"@

$to="sunil.chauhan@xyz.com"
#$to="sunil.chauhan@xyz.com"
$from="Mailbox-Move-Plan@xyz.com"
$subject="Exchange Database low space notification"

Send-MailMessage -From $from -To $to -Subject $subject -Smtpserver "Smtp.xyz.com" -body $body -BodyAsHtml
