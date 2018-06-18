param(
$MemberListFile,
[switch]$validate=$false
)

Import-Module activeDirectory
$DL=$memberListFile.Replace(".txt","")
$DL= $DL.Replace(".\","")
$distValidate = Get-DistributionGroup $DL
Clear-Content "Notfound.txt"

if ($distValidate)
    {Write-host "DL Found:$($distValidate.Name)" -ForegroundColor Green}
else {"DL $DL was not found";Break}

$users  = Gc $memberListFile

if ($(Get-Recipient $users[0]) -eq $null) { "Input fine is in Invalid format" ; Break }

if (!$validate) {

$members=@()
$logMultipleUser=@()
$notFound=@()

Write-Host "Validating Members to be Added" -f Yellow
foreach ($user in $users) 
    {

        $u = Get-ADUser -Filter {Mail -like $user} -Properties *
        if ($u -eq $null)
            {
            Write-host "User not found:$($user)"
            $notFound+=$($user)
            }      
        elseif ($u.count -gt 1)
            { 
            Write-host "Multiple User Found matching this user:$($user)"
            $logMultipleUser+=$($u)
            }
        else {$members+=$($u.Mail)}
    }

$logMultipleUser | export-csv "Multipleusers.csv" -NoTypeInformation
$notFound >> Notfound.txt

Write-Host "Member Validation Completed" -f Yellow

    if ($members) 
        {
        Write-Host "Total Member to be added:" $members.count
        if ($members.count -gt 10000) 
            {
                Write-Host "Total Member to be added:" $members.count
                foreach ($member in $members) 
                    {
                    "Adding $member"
                    Add-DistributionGroupMember -Identity $DL -Member $member 
                    }
            }
        else{

                "Updating DL.."
                read-host "Note: This operation will over write the existing members, update the input file and try again,
                Press CTRL + C to cancel the update, or hit ENTER to continue.
                "
                Update-DistributionGroupMember -Identity $DL -Members $members      
            } 
        }
    } else {

$members=@()
$logMultipleUser=@()
$notFound=@()

Write-Host "Validating Only:$($users.count)" -ForegroundColor Cyan
Write-Host "Validating Members to be Added" -f Yellow
foreach ($user in $users) 
    {

        $u = Get-ADUser -Filter {Mail -like $user} -Properties *
        if ($u -eq $null)
            {
            Write-host "User not found:$($user)"
            $notFound+=$($user)
            }      
        elseif ($u.count -gt 1)
            { 
            Write-host "Multiple User Found matching this user:$($user)"
            $logMultipleUser+=$($u)
            }
        else {$members+=$($u.Mail)}
    }

$logMultipleUser | export-csv "Multipleusers.csv" -NoTypeInformation
$notFound >> "Notfound.txt"  

Write-Host "Member Validation Completed" -f Yellow   
    
    }
