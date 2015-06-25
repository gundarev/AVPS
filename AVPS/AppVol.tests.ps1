#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#
Import-Module C:\source\AVPS\AVPS\AppVol.psd1
Describe "Open-AppVolSession" {

		It "returns version"{
		Open-AppVolSession -Uri http://appvol01.corp.itbubble.ru fdwl P@ssw0rd|Should be "2.9.0.1343" 
		
			}

	
}