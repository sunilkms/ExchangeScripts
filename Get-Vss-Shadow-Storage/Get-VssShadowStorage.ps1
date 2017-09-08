$data = vssadmin list shadowStorage
$newData=$data[3..($data).count]

$volume=$newdata | ? {$_ -match "For Volume"}
$ShadowStoragepath=$newdata | ? {$_ -match "Shadow Copy Storage volume"}
$UsedShadowSpace=$newdata | ? {$_ -match "Used Shadow"}
$AllocatedShadow=$newdata | ? {$_ -match "Allocated Shadow"}
$MaximumShadow=$newdata | ? {$_ -match "Maximum Shadow"}

$n=0 ; $Vf = $volume | % {$volume[$n].split("(")[1].split(")")[0];$n++}
$n=0 ; $SSn= $ShadowStoragepath | % {$ShadowStoragepath[$n].split("(")[1].split(")")[0];$n++}

$Table=@()

$no=0

foreach ($vol in $volume) {

#if (!$Volvalue){$Volvalue=$vol.substring(($volumeFor[1].indexof("(")+1),2)} 
#if (!$ss){$ss=$ShadowStoragesize[$no].substring(($volumeFor[1].indexof("(")+1),2)} 

$Volumevalue=$vf[$no]
$SS=$SSn[$no]
$USS=$UsedShadowSpace[$no].split(":")[1]
$AS=$AllocatedShadow[$no].split(":")[1]
$ms=$MaximumShadow[$no].split(":")[1]

#$r = New-Object -TypeName PSobject

$Volumevalue=$Volumevalue.replace("F:\Exchange Logs\","")
$Volumevalue=$Volumevalue.replace("F:\Exchange Databases\","")

$ss=$SS.replace("F:\Exchange Databases\","")
$ss=$SS.replace("F:\Exchange Logs\","")

$Volumevalue=$Volumevalue.replace("\","")
$ss=$SS.replace("\","")

$r = New-Object system.object
$r | Add-Member -MemberType NoteProperty -Name Volume -Value $Volumevalue
$r | Add-Member -MemberType NoteProperty -Name ShadowStoragepath -Value $SS
$r | Add-Member -MemberType NoteProperty -Name UsedShadowSpace -Value $USS
$r | Add-Member -MemberType NoteProperty -Name AllocatedShadow -Value $AS
$r | Add-Member -MemberType NoteProperty -Name MaximumShadow -Value $ms
$table+=$r
$no++
}
$table
