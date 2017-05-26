$logFilepath = "C:\Users\sunil\Desktop\caslogs.txt"
$logdata = Get-Content $logfilepath

$CsvHeader=$logdata[3].Replace("#Fields: ","")
$EWSLogs=$logdata | ? {$_ -match "Labadmin" -and $_ -match "EWS"}

$FinalData=@()
$FinalData+=$CsvHeader
$FinalData+=$EWSLogs

$Report=@()
foreach ($line in $FinalData){
        $newline=$line.replace(" ",",")
        $Report+=$newline }

$table = Convertfrom-Csv $Report -UseCulture
$table | Group-Object -Property sc-status
