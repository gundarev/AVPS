Import-Module -Name "C:\temp\svcollector\appvol.psm1"
$session=New-AppVolSession -Uri "http://appvol01.corp.itbubble.ru" -Username:"fdwl" -Password:"P@ssw0rd"
$AppStack=Get-AppVolAppStack -Session $session -All
$AppStack=Get-AppVolAppStack -Session $session -AppStack 88
$result=Add-AppVolAppStackAssignment -Session $session -AppStack 19 -ADObject "fdwl"

Remove-Module -Name appvol