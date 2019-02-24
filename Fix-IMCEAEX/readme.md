
## Fix recipient for whome users are getting IMCEAEX NDR.

#### This Script can be used to get the correct X500 address from NDR copied to a txt file, and then X500 address can be added to user account automatically, once added the same can be varified.

### Useage Examples:
Copy and paste the entire NDR to a File
* To convert to x500 from Ndr file   : ``` .\Fix-IMCEAEX-From-NDR.ps1 -NDRFile File.txt ```
* To make changes to user Account :``` .\Fix-IMCEAEX-From-NDR.ps1 -NDRFile File.txt -edit True ```
* To Verify the Changes to Account :``` .\Fix-IMCEAEX-From-NDR.ps1 -NDRFile File.txt -CheckX500 True ```


 **NOTE:** This Script would need both Exchange and ActiveDirectory PowerShell, run the script in Exchange Management Shell and make sure AD module is Installed.
