﻿if ($PSVersionTable.PSVersion.Major -lt 3) {
    throw New-Object System.NotSupportedException "PowerShell V3 or higher required."
}
<# 
.Synopsis
  Creates a new AppVolumes Manager Session.

.Description
  Creates a new AppVolumes Manager Session.

.Parameter Uri
  App Volumes Manager URL.

.Parameter Username
  Administrator username.

.Parameter Password
  Administrator password.
.INPUTS
            None. You cannot pipe objects to Open-AppVolSession
.OUTPUTS
Session Object
.Example
   # Login to the App Volumes manager.
   Open-AppVolSession -Uri "http://appvol.domain.com" -Username "admin" -Password "P@ssw0rd"
    
#>
function Open-AppVolSession
{
  [CmdletBinding(DefaultParameterSetName = "AppVolSession")]
  param(
    [Parameter(ParameterSetName = "AppVolSession",Position = 1,Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ ([System.URI]$_).IsAbsoluteUri })]
    [string]$Uri,

    [Parameter(ParameterSetName = "AppVolSession",Position = 2,Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Username,
    [Parameter(ParameterSetName = "AppVolSession",Position = 3,Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Password
  )

try 
{
    $result1 = Invoke-WebRequest -Uri $Uri/login -Method Get -SessionVariable session
    $authentity_token = @( $result1.ParsedHtml.getElementsByName("authenticity_token")).value
    $admincredentials = @{ 'user[account_name]' = $($Username); 'user[password]' = $($Password); 'authentity_token' = $($authentity_token) }
    $result = Invoke-WebRequest -Uri $Uri/login -Method POST -SessionVariable session -Body $admincredentials
    $csrf_token = @( $result.ParsedHtml.getElementsByName("csrf-token")).content
    if (-Not ([string]::IsNullOrEmpty($csrf_token)))
    {
        
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("X-CSRF-Token",$csrf_token)
        return [pscustomobject]@{ 'Headers' = $headers; 'Session' = $session; 'Uri' = $Uri }
    }
    else 
    {
        Write-Output "Invalid credentials or Uri"
        return $null
    }
}
catch
{
    Write-Output $_.Exception
    return $null
}
}
Export-ModuleMember Open-AppVolSession

<# 
.Synopsis
  Closes an existing AppVolumes Manager Session.

.Description
  Closes an existing AppVolumes Manager Session.

.Parameter Session
  App Volumes Manager Sesion Object.

.OUTPUTS
None
.Example
   # Login to the App Volumes manager.
   $session=Open-AppVolSession -Uri "http://appvol.domain.com" -Username "admin" -Password "P@ssw0rd"
   # Logoff from the App Volumes manager.
   Close-AppVolSession -Session $session
    
#>
function Close-AppVolSession
{
  [CmdletBinding(DefaultParameterSetName = "AppVolSession")]
  param(
    [Parameter(ParameterSetName = "AppVolSession",Position = 1,Mandatory = $true,ValueFromPipeline=$True)]
    [ValidateNotNullOrEmpty()]
    [PSCustomObject]$Session

  )
process{
try 
{
    $uri=$Session.Uri+'/logout'
    Invoke-WebRequest -Uri $uri -Method Get -MaximumRedirection 0 -ErrorAction Ignore -WebSession $Session.Session -Headers $Session.Headers
    
    
    
}
catch
{
    Write-Output $_.Exception
    
}
}
}
Export-ModuleMember Close-AppVolSession


<# 
 .Synopsis
  Returns AppVolumes Manager Version.

 .Description
  Returns AppVolumes Manager Version.

 .Parameter Session
  App Volumes Manager Session.


 .Example
   # Login to the App Volumes manager.
   $session=New-AppVolSession -Uri "http://appvol.domain.com" -Username "admin" -Password "P@ssw0rd"
   Get-AppVolVersion -Session $session
    
#>
function Get-AppVolVersion{
param(
    [Parameter(ParameterSetName = "AppVolSession",Position = 1,Mandatory = $true,ValueFromPipeline=$True)]
    [ValidateNotNullOrEmpty()]
    [PSCustomObject]$Session
    )
    process{
        $uri = "$($session.Uri)/cv_api/version"
        try 
        {
            $result=Internal-Rest -Uri $uri -Method Get -Session $Session 
            
            return [pscustomobject]@{ 'Version' = $result.version; 'InternalVersion' = $result.internal; 'Copyright' = $result.copyright }
        }
        catch
        {
            Write-Output $_.Exception
        }
    }
}
Export-ModuleMember Get-AppVolVersion
<# 
 .Synopsis
  Returns AppVolumes Manager AppStack(s).

 .Description
  Returns AppVolumes Manager AppStack(s).

 .Parameter Session
  App Volumes Manager Session.
 
 .Parameter All
  Return All AppStacks
 .Parameter AppStackIds
  AppStack ID
 .Example
  $session=Open-AppVolSession http://appvol01.corp.itbubble.ru fdwl P@ssw0rd
Get-AppVolAppStack -Session $session|
Where-Object {$_.status -ne "enabled"} |
Select-Object -Property id|
Get-AppVolAppStack -Session $session|
Select-Object -Property name,file_location
    
#>
function Get-AppVolAppStack{
    [CmdletBinding(DefaultParameterSetName = "AllAppStacks")]
    param(
        [Parameter(ParameterSetName = "AllAppStacks",Position = 1,Mandatory = $true,ValueFromPipeline=$false)]
        [Parameter(ParameterSetName = "OneAppStack",Position = 1,Mandatory = $true,ValueFromPipeline=$false)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Session,
        [Parameter(ParameterSetName = "AllAppStacks",Position = 2,ValueFromPipeline=$false)]
        [switch] $All,
        [Parameter(ParameterSetName = "OneAppStack",Mandatory = $true,Position = 2,ValueFromPipeline=$TRUE,ValueFromPipelineByPropertyName=$true, ValueFromRemainingArguments=$false)]
        [Alias('id')]
          [ValidateNotNull()]
        [int[]]$AppStackIds
    )
    begin{

[Object[]] $result=$null
}

    process{
    $rooturi = "$($session.Uri)/cv_api/appstacks"
    switch ($PsCmdlet.ParameterSetName){ 
        "AllAppStacks"{
            $result=(Internal-Rest -Session $Session -Uri $rooturi -Method Get) 
            
            }
        "OneAppStack"{
        foreach ($AppStackId in $AppStackIds){
            $uri="$rooturi/$AppStackId"
            $instance=(Internal-Rest -Session $Session -Uri $uri -Method Get).appstack
            $result+=$instance
           
            }
            }
        }
    }  
end{
$table=$result
    return $table

    }
    }
Export-ModuleMember Get-AppVolAppStack


<# 
 .Synopsis
  Modifies AppVolumes Manager AppStack(s).

 .Description
  Modifies AppVolumes Manager AppStack(s).

 .Parameter Session
  App Volumes Manager Session.
 
 .Parameter AppStackId
  AppStack ID
 .Example
  $session=Open-AppVolSession http://appvol01.corp.itbubble.ru fdwl P@ssw0rd

    
#>
function Set-AppVolAppStack{
    [CmdletBinding(DefaultParameterSetName = "OneAppStack")]
    param(
        [Parameter(ParameterSetName = "OneAppStack",Position = 0,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Session,
       
        [Parameter(ParameterSetName = "OneAppStack",Position = 1,ValueFromPipeline=$TRUE,ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [ValidateNotNullOrEmpty()]
        [int[]]$AppStackId,
        [Parameter(ParameterSetName = "OneAppStack",Position = 2,ValueFromPipeline=$TRUE,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Property,
        [Parameter(ParameterSetName = "OneAppStack",Position = 2,ValueFromPipeline=$TRUE,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    process{
    $uri = "$($session.Uri)/cv_api/appstacks/$AppStackId"
   
  
            $uri="$uri/$AppStackId"
            $result=(Internal-Rest -Session $Session -Uri $uri -Method Put).appstack
      
        
      

    return $result|ft
    }
    }
Export-ModuleMember Set-AppVolAppStack

   

<# 
 .Synopsis
  Assigns AppVolumes Manager AppStack(s).

 .Description
  Assigns AppVolumes Manager AppStack(s).

 .Parameter Session
  App Volumes Manager Session.
 
 .Parameter AppStack
  AppStack ID
 .Parameter ADObject
  SamAccountName
 .Example
   # Login to the App Volumes manager.
   $session=New-AppVolSession -Uri "http://appvol.domain.com" -Username "admin" -Password "P@ssw0rd"
   Add-AppVolAppStackAssignment -Session $session -AppStack 1

    
#>
function Add-AppVolAppStackAssignment{
param(

    [PSCustomObject]$Session,
    
    [int]$AppStack,
    [string]$ADObject
)
$uri = "$($session.Uri)/cv_api/assignments"

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-CSRF-Token",$Session.Token)
$Search = New-Object DirectoryServices.DirectorySearcher([ADSI]“”)
$Search.filter = “(&(sAMAccountName=$ADObject))”
$ADResults=$Search.Findall()
$assignments=@{
entity_type=($ADResults[0].Properties["objectclass"])[($ADResults[0].Properties["objectclass"]).Count-1]
path=$($ADResults[0].Properties["DistinguishedName"])
}

$json = @{
        "action_type"= "Assign"
        "id"=$AppStack
        "assignments"=@{"0"=$assignments}
        "rtime"= "false"
        "mount_prefix"= $null
    }
    $body=$json|ConvertTo-Json -Depth 3
#$result=Invoke-RestMethod -Uri $uri -Method post -WebSession $Session.Session -Headers $headers -Body $json 
$result=Invoke-RestMethod -Uri $uri -Method post -WebSession $Session.Session -Headers $headers -Body $body -ContentType "application/json" 
[hashtable]$Return = @{} 
$Return.result=($result|Get-Member -MemberType NoteProperty)[-1].Name
$Return.message=$result.(($result|Get-Member -MemberType NoteProperty)[-1].Name)

return $Return

}
Export-ModuleMember Add-AppVolAppStackAssignment
Function Internal-Rest {
 param(
        [Parameter(Position = 1,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Session,

        [Parameter(Position = 2,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ ([System.URI]$_).IsAbsoluteUri })]
        [string]$Uri,
        
        [Parameter(Position = 3,Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,
        
        [Parameter(Position = 4,Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Body
        
        )
        switch ([Microsoft.PowerShell.Commands.WebRequestMethod]$Method) {
         
         Put {$cmd = {Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.Session -Headers $Session.Headers -Body $Body -ContentType "application/json"}}
         Post {$cmd = {Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.Session -Headers $Session.Headers -Body $Body -ContentType "application/json"}}
         default { $cmd = {Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.Session -Headers $Session.Headers -ContentType "application/json"}}
        }

    try{

        return Invoke-Command $cmd
    }
    catch{
    return $null
    }
}

