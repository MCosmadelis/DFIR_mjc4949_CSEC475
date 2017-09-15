# Prompts the user to enter the CSV path then parses the
# CSV and grabs the filename, filepath and timestamps 
# associated with the file.
#
# Timestamps are then displayed for analysis of potetntial timestomping.
#
# By: Michael Cosmadelis 

$csvPath = Read-Host "Enter MFT CSV path: "

#List NTFS filestreams
Import-Csv -Path $csvPath -Delimiter "|" | select FilePath, FN_FileName, SI_CTime, SI_ATime, SI_MTime, SI_RTime, FN_CTime, FN_ATime, FN_MTime, FN_RTime

#dump the $DATA section of a particular file
$fileName = Read-Host "Enter filename to dump `$DATA section: "
Write-Host "Please wait..."
$filePath = Import-Csv -Path $csvPath -Delimiter "|" | where-object {$_.FN_FileName -eq $fileName} | select -ExpandProperty FilePath
$dataName = Import-Csv -Path $csvPath -Delimiter "|" | where-object {$_.FN_FileName -eq $fileName} | select -ExpandProperty DATA_Name

$drive = "C"
Get-Content -Path ($drive + $filePath) -Stream $dataName

#identify timestomping entries
#compare the FN time vs SN Time
Write-Host "`nIdentifying potential timestomping entries..."
Write-Host "Please wait..."
$fnTimes = Import-Csv -Path $csvPath -Delimiter "|" | where-object {$_.FN_FileName -eq $fileName} | select FN_CTime, FN_ATime, FN_MTime, FN_RTime
$siTimes = Import-Csv -Path $csvPath -Delimiter "|" | where-object {$_.FN_FileName -eq $fileName} | select SI_CTime, SI_ATime, SI_MTime, SI_RTime






