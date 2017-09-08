#-------------------------------------------------------------------------------------
#author : Sunil Chauhan
#This script converts results from "vssadmin list shadowStorage" CMD into to a table
#-------------------------------------------------------------------------------------
#Get Vssadmin list shadow storage to an array
$data = vssadmin list shadowStorage
$newData=$data[3..($data).count]

#Seprate data for each column type.
$volume=$newdata | ? {$_ -match "For Volume"}
$ShadowStoragepath=$newdata | ? {$_ -match "Shadow Copy Storage volume"}
$UsedShadowSpace=$newdata | ? {$_ -match "Used Shadow"}
$AllocatedShadow=$newdata | ? {$_ -match "Allocated Shadow"}
$MaximumShadow=$newdata | ? {$_ -match "Maximum Shadow"}

#Remove the unwanted data.
$n=0 ; $Vf = $volume | % {$volume[$n].split("(")[1].split(")")[0];$n++}
$n=0 ; $SSn= $ShadowStoragepath | % {$ShadowStoragepath[$n].split("(")[1].split(")")[0];$n++}

#Table section --------------------
$Table=@()
$no=0

foreach ($vol in $volume) {

#more clean process for each item.

$Volumevalue=$vf[$no]
$SS=$SSn[$no]
$USS=$UsedShadowSpace[$no].split(":")[1]
$AS=$AllocatedShadow[$no].split(":")[1]
$ms=$MaximumShadow[$no].split(":")[1]

$Volumevalue=$Volumevalue.replace("F:\Exchange Logs\","")
$Volumevalue=$Volumevalue.replace("F:\Exchange Databases\","")

$ss=$SS.replace("F:\Exchange Databases\","")
$ss=$SS.replace("F:\Exchange Logs\","")

$Volumevalue=$Volumevalue.replace("\","")
$ss=$SS.replace("\","")

#Table - Raw entry starts

$r = New-Object system.object
$r | Add-Member -MemberType NoteProperty -Name Volume -Value $Volumevalue
$r | Add-Member -MemberType NoteProperty -Name ShadowStoragepath -Value $SS
$r | Add-Member -MemberType NoteProperty -Name UsedShadowSpace -Value $USS
$r | Add-Member -MemberType NoteProperty -Name AllocatedShadow -Value $AS
$r | Add-Member -MemberType NoteProperty -Name MaximumShadow -Value $ms

#add data to Table.
$table+=$r
$no++
}
#return full table.
$table
