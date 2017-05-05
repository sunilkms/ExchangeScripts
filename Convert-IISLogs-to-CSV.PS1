$logFilepath = "C:\Users\sunil\Desktop\caslogs.txt"
$logfile = Get-Content $logfilepath

$CsvHeader=$logfile[3].Replace("#Fields: ","")
$EWSLogs=$logfile | ? {$_ -match "Labadmin" -and $_ -match "EWS"}

$FinalData=@()
$FinalData+=$CsvHeader
$FinalData+=$EWSLogs

$Report=@()
foreach ($line in $FinalData){
        $newline=$line.replace(" ",",")
        $Report+=$newline }

$table = Convertfrom-Csv $Report -UseCulture
$Table | Export-Csv "IIS-Logs.csv" -Notype
