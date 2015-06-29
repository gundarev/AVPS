function Open-AppVolSession

{

  [CmdletBinding(DefaultParameterSetName = "AppVolSession")]
  param(
    [Parameter(ParameterSetName = "AppVolSession",Position = 1,Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({([System.URI]$_).IsAbsoluteUri})]
    [Uri]$Uri,

    [Parameter(ParameterSetName = "AppVolSession",Position = 2,Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Username,

    [Parameter(ParameterSetName = "AppVolSession",Position = 3,Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Password
  )
  begin
  {
    $rooturi="$($Uri)cv_api/sessions"
    $admincredentials = (@{ 'username' = $($Username); 'password' = $($Password)})|ConvertTo-Json
    try
    {
        $result= Invoke-WebRequest -Uri $rooturi -SessionVariable session -Method Post -Body $admincredentials -ContentType "application/json"
        $Global:GlobalSession = New-Object Vmware.Appvolumes.AppVolumesSession
        $Global:GlobalSession.Session = $session
        $Global:GlobalSession.Uri = $Uri
        $version = Get-AppVolVersion
        $Global:GlobalSession.Version = $version.Version
        $Global:GlobalSession.SessionStart = $session.Cookies.GetCookies($(([uri]$Uri).AbsoluteUri))["_session_id"].TimeStamp

        return $Global:GlobalSession
    }
    catch
    {
        Write-Output "Invalid credentials or Uri"
        return $false
    }
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
 # Open the session with AppVolumes Manager
Open-AppVolSession -Uri http://manager.domain.com -Username admin -Password password1
 # Or you can omit the parameter names
Open-AppVolSession  http://manager.domain.com admin  password1

#>
}

function Test-AppVolSession
{
  if ($Global:GlobalSession)
  {
    return
  }
  else
  {
    Write-Output "No open App Volumes Manager session available!"
    break
  }
  <# 
 .SYNOPSIS
 Test Current App Volumes Manager Session
 .DESCRIPTION
 Test Current App Volumes Manager Session, does not return anything if session is open.
 .EXAMPLE
 Test-AppVolSession
 #>
}

function Close-AppVolSession
{
  Test-AppVolSession
  try
  {
    $uri = "$($Global:GlobalSession.Uri)logout"
    $tmp = Invoke-WebRequest -Uri $uri -Method Get -MaximumRedirection 0 -ErrorAction Ignore -WebSession $Global:GlobalSession.Session -Headers $Global:GlobalSession.Headers

    $Global:GlobalSession = $null
  }
  catch
  {
    Write-Output $_.Exception
    Remove-Variable GlobalSession= -Scope Global
  }
  Write-Output "Session Destroyed"

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
 Close-AppVolSession 
 
#>

}

function Get-AppVolVersion
{
  process
  {
    Test-AppVolSession
    $uri = "$($Global:GlobalSession.Uri)cv_api/version"
    try
    {
      $result = Internal-Rest -Uri $uri -Method Get -Session $Global:GlobalSession
      $tmp = New-Object -TypeName Vmware.Appvolumes.AppVolumesVersion
      $tmp.Version = $result.Version
      $tmp.InternalVersion = $result.internal
      $tmp.Copyright = $result.Copyright

      return $tmp
    }
    catch
    {
      Write-Error $_.Exception
    }
  }

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
 Get-AppVolVersion 
 
#>

}

function Get-AppVolAppStack
{
  [CmdletBinding(DefaultParameterSetName = "AllAppStacks")]
  param(
    [Parameter(ParameterSetName = "SelectedAppStack",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
    [Alias('id','AppStackId')]
    [ValidateNotNullOrEmpty()]
    [int[]]$VolumeID,
    
    [Parameter(ParameterSetName = "AllAppStacks",Position = 1,ValueFromPipeline = $false,Mandatory = $false)]
    [switch]$All,
    
    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$Name,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$Path,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$DataStore,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$FileName,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$Description,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [Vmware.Appvolumes.AppStackStatus]$Status,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [datetime]$CreatedAt,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [datetime]$MountedAt,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [int]$Size,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$TemplateVersion,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [int]$MountCount,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [int]$AssignmentsTotal,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [int]$LocationCount,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [int]$ApplicationCount,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [guid]$VolumeGuid,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$TemplateFileName,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$AgentVersion,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$CaptureVersion,

    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$Exact,
    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$Like,

    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$ge,
    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$le,

    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$gt,
    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$lt,

    [Parameter(Mandatory = $false,Position = 4)]
    [switch]$Not

  )
  begin
  {
    Test-AppVolSession

    [Vmware.Appvolumes.AppVolumesAppStack[]]$Appstacks = $null
    [Vmware.Appvolumes.AppVolumesAppStack[]]$AppstacksFiltered = $null
  }

  process
  {
    $rooturi = "$($Global:GlobalSession.Uri)cv_api/appstacks"
    switch ($PsCmdlet.ParameterSetName)
    {
      "AllAppStacks"
      {
        $AllApstacks = Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get
        foreach ($AppStackId in $AllApstacks.id)
        {
          $uri = "$rooturi/$AppStackId"
          $instance = (Internal-Rest -Session $Global:GlobalSession -Uri $uri -Method Get).appstack
          $Appstacks += Internal-PopulateAppStack $instance
        } 
      } 
      "SelectedAppStack"
      {
        foreach ($AppStackId in $VolumeID)
        {
          $uri = "$rooturi/$AppStackId"
          $instance = (Internal-Rest -Session $Global:GlobalSession -Uri $uri -Method Get).appstack

          $Appstacks += Internal-PopulateAppStack $instance
        }
      }
    }
    foreach ($AppStack in $Appstacks)
    {
      $AppstacksFiltered += Internal-FilterResults ($AppStack)
    }
  }

  end
  {
    if ($AppstacksFiltered) { return $AppstacksFiltered }
    else { return $Appstacks }
  }

  <# 
 .Synopsis
 Returns AppVolumes Manager AppStack(s).

 .Description
 Returns AppVolumes Manager AppStack(s).

 .Parameter Session
 App Volumes Manager Session.
 
 .Parameter All
 Return All AppStacks
 .Parameter VolumeID
 AppStack ID
 .Example
Open-AppVolSession http://appvol01.corp.itbubble.ru fdwl P@ssw0rd

 # Return all available AppStacks
Get-AppVolAppStack [-All] 

 # Return AppStacks with IDs 88 and 19
Get-AppVolAppStack -VolumeID 88,19 

 # Return AppStacks with IDs 88 and 19 thru the pipe
88,19|Get-AppVolAppStack 

 # Return all AppStacks where the name contains “office”
Get-AppVolAppStack -Name office 

 # Return all AppStacks where the name NOT contains “office”
Get-AppVolAppStack -Name office -Not  

 # Return all AppStacks where the name is exactly “office”
Get-AppVolAppStack -Name office  -Exact 

 # Return AppStacks that has “cloudvolumes” in the datastore path
Get-AppVolAppStack -Path "cloudvolumes" 

# Return AppStacks located on datastore iSCSI
Get-AppVolAppStack -DataStore iSCSI -Exact 

# Return AppStacks where vmdk name contains word office
Get-AppVolAppStack -FileName office 

# Return AppStacks created after or on 4/28/2015
Get-AppVolAppStack -CreatedAt "4/28/2015" –ge

# Return AppStacks created after but not on 4/28/2015
Get-AppVolAppStack -CreatedAt "4/28/2015" -gt  

 # Return AppStacks not mounted in past 30 days
Get-AppVolAppStack -MountedAt $((get-date).AddDays(-30)) -ge -Not  

 # Return AppStacks with template version 2.5.1
Get-AppVolAppStack -TemplateVersion "2.5.1" 

 # Return AppStacks that have 2 or more assignments
Get-AppVolAppStack -AssignmentsTotal 2 -ge  

 
#>

}

function Get-AppVolAssignment
{

  [CmdletBinding(DefaultParameterSetName = "AllAssignments")]
  param(
    [Parameter(ParameterSetName = "AllAssignments",Position = 1,ValueFromPipeline = $false,Mandatory = $false)]
    [switch]$All,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$EntityDn,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$EntitySamAccountName,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$EntityDomain,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [Vmware.Appvolumes.EntityType]$EntityType,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [datetime]$EventTime,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$MountPrefix,

    [Parameter(ParameterSetName = "SelectedAssignment",Mandatory = $false,Position = 1,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
    [Alias('id')]
    [ValidateNotNull()]
    [int]$VolumeId,

    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$VolumeName,
    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$Exact,
    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$Like,

    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$ge,
    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$le,

    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$gt,
    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$lt,

    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$Not

  )
  begin
  {
    Test-AppVolSession

    [Vmware.Appvolumes.AppVolumesAssignment[]]$Assignments = $null
    [Vmware.Appvolumes.AppVolumesAssignment[]]$AssignmentsFiltered = $null
    $Filtered = $false
  }
  process
  {

    $rooturi = "$($Global:GlobalSession.Uri)cv_api/assignments"
    switch ($PsCmdlet.ParameterSetName)
    {
      "AllAssignments"
      {
        $tmp = (Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get).assignments
        foreach ($Assignment in $tmp)
        {
          $Assignments += Internal-PopulateAssignment $Assignment
        }
      }
      "SelectedAssignment"
      {
        $tmp = (Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get).assignments
        foreach ($Assignment in $tmp)
        {
          $tmpAssignment = Internal-PopulateAssignment $Assignment
          if ($tmpAssignment.VolumeId -eq $VolumeId)
          {
            $Assignments += $tmpAssignment
          }
        }
      }
    }
    foreach ($Assignment in $Assignments)
    {
      $AssignmentsFiltered += Internal-FilterResults ($Assignment)
    }
  }
  end
  {
    if ($AssignmentsFiltered)
    {
      return $AssignmentsFiltered
    }
    else
    {
      return $Assignments
    }
  }

  <# 
 .Synopsis
 Returns AppVolumes Manager Assignment(s).

 .Description
 Returns AppVolumes Manager Assignment(s).

 .Parameter Session
 App Volumes Manager Session.
 
 .Parameter All
 Return All Assignments
 .Parameter AssignmentIds
 Assignment ID
 .Example
 Open-AppVolSession http://appvol01.corp.itbubble.ru fdwl P@ssw0rd
# Return all assignments
Get-AppVolAssignment [-all] 

# Return all assignments for appstacks that has “office” in the name
Get-AppVolAppStack -Name office |Get-AppVolAssignment  

# Return assignments for users in specific OU
Get-AppVolAssignment -EntityDn "cn=users,dc=domain,dc=com" 

# Return assignments for user “denis”
Get-AppVolAssignment -EntitySamAccountName denis -Exact 

# Return assignments for users in domain CORP
Get-AppVolAssignment -EntityDomain CORP 

# Return computer assignments
Get-AppVolAssignment -EntityType:Computer 

# Return OU assignments
Get-AppVolAssignment -EntityType:OrgUnit 

# Return # Return appstacks assigned to a user
Get-AppVolAssignment -EntitySamAccountName denis|Get-AppVolAppStack|ft 



#>

}

function Get-AppVolAppStackFile

{

  [CmdletBinding(DefaultParameterSetName = "AllAppStackFiles")]
  param(
    [Parameter(Mandatory = $false,Position = 1)]
    [Parameter(ParameterSetName = "SelectedAppStackFile",Mandatory = $true,Position = 1,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
    [Alias('id','VolumeId')]
    [ValidateNotNull()]
    [int[]]$VolumeID,
    [Parameter(Mandatory = $false,Position = 1)]
    [Parameter(ParameterSetName = "AllAppStackFiles",Position = 1,ValueFromPipeline = $false,Mandatory = $false)]
    [switch]$All,
    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [switch]$Missing,
    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [switch]$Reachable,
    [Parameter(Mandatory = $false,Position = 2)]
    [ValidateNotNull()]
    [string]$DataStore,
    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$Exact,
    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$Like,
    [Parameter(Mandatory = $false,Position = 3)]
    [switch]$Not
  )
  begin

  {
    Test-AppVolSession
    [Vmware.Appvolumes.AppVolumesAppStackFile[]]$AppStackFiles = $null
    [Vmware.Appvolumes.AppVolumesAppStackFile[]]$AppStackFilesFiltered = $null
  }

  process
  {
    switch ($PsCmdlet.ParameterSetName)
    {
      "SelectedAppStackFile"
      {
        foreach ($AppStackId in $VolumeID)
        {
          $rooturi = "$($Global:GlobalSession.Uri)cv_api/appstacks/$AppStackId/files"
          $instances = (Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get)
          foreach ($instance in $instances)
          {
            $AppStackFile = Internal-PopulateAppStackFile $instance
            $AppStackFile.AppStackId = $AppStackId
            $AppStackFiles += $AppStackFile
          }
        }
      }
      "AllAppStackFiles"
      {
        $AppStackFiles = Get-AppVolAppStack | Get-AppVolAppStackFile
      }
    }
    foreach ($AppStackFile in $AppStackFiles)
    {
      $AppStackFileFiltered += Internal-FilterResults ($AppStackFile)
    }
  }
  end
  {
    if ($AppStackFilesFiltered) { return $AppStackFilesFiltered }
    else { return $AppStackFiles }
  }

  <#
 .Synopsis
 Returns AppVolumes Manager AppStackFile(s).
 .Description
 Returns AppVolumes Manager AppStackFile(s).
 .Parameter Session
 App Volumes Manager Session.
 .Parameter All
 Return All AppStackFiles
 .Parameter AppStackFileId
 AppStackFile ID
 .Example
 $session=Open-AppVolSession http://appvol01.corp.itbubble.ru fdwl P@ssw0rd
 # Return file names for appstack with id 88
 Get-AppVolAppStackFile -VolumeID 88 

 # Returns a table with all appstacks that have files on datastore1
 Get-AppVolAppStackFile -DataStore datastore1|Get-AppVolAppStack|Format-Table
 
 # Returns all unreachable files
 Get-AppVolAppStackFile -Reachable -Not


#>

}

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
function Set-TODOAppStack
{

  [CmdletBinding(DefaultParameterSetName = "OneAppStack")]
  param(
    [Parameter(ParameterSetName = "OneAppStack",Position = 0,Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [pscustomobject]$Session,

    [Parameter(ParameterSetName = "OneAppStack",Position = 1,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName)]
    [Alias('id')]
    [ValidateNotNullOrEmpty()]
    [int[]]$AppStackId,
    [Parameter(ParameterSetName = "OneAppStack",Position = 2,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [string]$Property,
    [Parameter(ParameterSetName = "OneAppStack",Position = 2,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [string]$Value
  )
  process
  {

    $uri = "$($session.Uri)/cv_api/appstacks/$AppStackId"

    $uri = "$uri/$AppStackId"
    $result = (Internal-Rest -Session $Session -Uri $uri -Method Put).appstack

    return $result | ft


  }

}

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
function Add-TODOAppStackAssignment
{

  param(

    [pscustomobject]$Session,

    [int]$AppStack,
    [string]$ADObject
  )
  $uri = "$($session.Uri)/cv_api/assignments"

  $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
  $headers.Add("X-CSRF-Token",$Session.Token)
  $Search = New-Object DirectoryServices.DirectorySearcher ([adsi]“”)
  $Search.filter = “(&(sAMAccountName=$ADObject))”
  $ADResults = $Search.Findall()
  $assignments = @{

    entity_type = ($ADResults[0].Properties["objectclass"])[($ADResults[0].Properties["objectclass"]).Count - 1]
    path = $($ADResults[0].Properties["DistinguishedName"])


  }

  $json = @{

    "action_type" = "Assign"
    "id" = $AppStack
    "assignments" = @{

      "0" = $assignments

    }

    "rtime" = "false"
    "mount_prefix" = $null


  }

  $body = $json | ConvertTo-Json -Depth 3

  $result = Invoke-RestMethod -Uri $uri -Method post -WebSession $Session.Session -Headers $headers -Body $body -ContentType "application/json"
  [hashtable]$Return = @{

  }

  $Return.result = ($result | Get-Member -MemberType NoteProperty)[-1].Name
  $Return.message = $result.(($result | Get-Member -MemberType NoteProperty)[-1].Name)

  return $Return

}

function Internal-Rest
{

  param(
    [Parameter(Position = 1,Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [pscustomobject]$Session,

    [Parameter(Position = 2,Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({([System.URI]$_).IsAbsoluteUri})]
    [string]$Uri,

    [Parameter(Position = 3,Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

    [Parameter(Position = 4,Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Body

  )
  switch ([Microsoft.PowerShell.Commands.WebRequestMethod]$Method)
  {

    Put
    {$cmd ={Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.Session -Headers $Session.Headers -Body $Body -ContentType "application/json"}}
    Post
    {$cmd ={Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.Session -Headers $Session.Headers -Body $Body -ContentType "application/json"}}

    default
    {$cmd ={Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.Session -Headers $Session.Headers -ContentType "application/json"}}
  }
  try
  {
    return Invoke-Command $cmd
  }
  catch
  {
    return $null
  }
}

function Internal-FilterResults
{
  param(
    $Entity
  )
  $EntityList = $null
  foreach ($CurrentParameter in $($PSCmdlet.MyInvocation.BoundParameters.Keys))

  {
    if (-not (@('VolumeId','All','Not','VolumeID') -contains $CurrentParameter ) )
    {
      switch ($PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter].GetType().Name)
      {
        "String"
        {
          if ($Exact)
          {
            if ($Entity.$CurrentParameter -eq $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and (-not $Not))
            {
              $EntityList += $Entity
            }
            elseif ($Entity.$CurrentParameter -ne $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and ($Not))
            {
              $EntityList += $Entity
            }
          }
          if ($Like -or ((-not $Exact) -and (-not $Like) -and (-not $Exact)))
          {
            if ($Entity.$CurrentParameter -like "*" + $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] + "*" -and (-not $Not))
            {
              $EntityList += $Entity
            }
            elseif ($Entity.$CurrentParameter -notlike "*" + $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] + "*" -and ($Not))
            {
              $EntityList += $Entity
            }
          }
        }
        "AssignmentStatus"
        {
          if ($Entity.$CurrentParameter -eq $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and (-not $Not))
          {
            $EntityList += $Entity
          }
          elseif ($Entity.$CurrentParameter -ne $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and ($Not))
          {
            $EntityList += $Entity
          }
        }
        {($_ -match "Int") -or ($_ -eq "DateTime")}
        {
          if ($Exact -or ((-not $Exact) -and (-not $gt) -and (-not $lt) -and (-not $ge) -and (-not $le)))
          {
            if ($Entity.$CurrentParameter -eq $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and (-not $Not))
            {
              $EntityList += $Entity
            }
            elseif ($Entity.$CurrentParameter -ne $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and ($Not))
            {
              $EntityList += $Entity
            }
          }
          if ($gt)
          {
            if ($Entity.$CurrentParameter -gt $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and (-not $Not))
            {
              $EntityList += $Entity
            }
            elseif ($Entity.$CurrentParameter -le $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and ($Not))
            {
              $EntityList += $Entity
            }
          }
          if ($lt)
          {
            if ($Entity.$CurrentParameter -lt $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and (-not $Not))
            {
              $EntityList += $Entity
            }
            elseif ($Entity.$CurrentParameter -ge $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and ($Not))
            {
              $EntityList += $Entity
            }
          }
          if ($ge)
          {
            if ($Entity.$CurrentParameter -ge $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and (-not $Not))
            {
              $EntityList += $Entity
            }
            elseif ($Entity.$CurrentParameter -lt $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and ($Not))
            {
              $EntityList += $Entity
            }
          }
          if ($le)
          {
            if ($Entity.$CurrentParameter -le $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and (-not $Not))
            {
              $EntityList += $Entity
            }
            elseif ($Entity.$CurrentParameter -gt $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and ($Not))
            {
              $EntityList += $Entity
            }
          }
        }
        {($_ -eq "Guid") -or ($_ -eq "AppStackStatus")}
        {
          if ($Entity.$CurrentParameter -eq $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and (-not $Not))
          {
            $EntityList += $Entity
          }
          elseif ($Entity.$CurrentParameter -ne $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and ($Not))
          {
            $EntityList += $Entity
          }
        }
        "SwitchParameter"
        {
          if ($Entity.$CurrentParameter -eq $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and (-not $Not))
          {
            $EntityList += $Entity
          }
            elseif ($Entity.$CurrentParameter -ne $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] -and ($Not))
          {
            $EntityList += $Entity
          }
        }
      }
    }
  }

  return $EntityList

}

function Internal-PopulateAppStack

{

  param(
    $instance

  )
  $appStack = New-Object -TypeName Vmware.Appvolumes.AppVolumesAppStack
  $appStack.id = $instance.id
  $appStack.DataStore = $instance.datastore_name
  $appStack.Name = $instance.Name
  $appStack.path = $instance.path
  $appStack.FileName = $instance.FileName
  $appStack.Description = $instance.desctiption
  $appStack.Status = $instance.Status
  if ($instance.created_at)
  {

    $appStack.CreatedAt = $instance.created_at

  }

  if ($instance.mounted_at)
  {

    $appStack.MountedAt = $instance.mounted_at

  }

  $appStack.Size = $instance.size_mb
  $appStack.TemplateVersion = $instance.template_version
  $appStack.MountCount = $instance.mount_count
  $appStack.AssignmentsTotal = $instance.assignments_total
  $appStack.AttachmentsTotal = $instance.attachments_total
  $appStack.LocationCount = $instance.location_count
  $appStack.ApplicationCount = $instance.application_count
  if ($instance.volume_guid)

  {

    $appStack.VolumeGuid = $instance.volume_guid


  }

  $appStack.TemplateFileName = $instance.template_file_name
  $appStack.AgentVersion = $instance.agent_version
  $appStack.CaptureVersion = $instance.capture_version
  $os = New-Object -TypeName Vmware.Appvolumes.AppStackOs
  $os.id = $instance.primordial_os_id
  $os.Name = $instance.primordial_os_name
  $appStack.PrimordialOs = $os
  [Vmware.Appvolumes.AppStackOs[]]$oses = $null
  foreach ($tmpos in $instance.oses)

  {

    $tmpAsos = New-Object -TypeName Vmware.Appvolumes.AppStackOs
    $tmpAsos.Name = $tmpos.Name
    $tmpAsos.id = $tmpos.id
    $oses += $tmpAsos


  }

  $appStack.oses = $oses
  $appStack.ProvisonDuration = $instance.provision_duration
  return $appStack

}

function Internal-PopulateAssignment

{

  param(
    $instance

  )
  $Assignment = New-Object -TypeName Vmware.Appvolumes.AppVolumesAssignment
  $Assignment.EntityDn = $instance.entity_dn
  $Assignment.EntitySamAccountName = $instance.entity_upn.Split('\')[1]
  $Assignment.EntityDomain = $instance.entity_upn.Split('\')[0]
  $Assignment.EntityType = $instance.entityt
  $Assignment.EventTime = $instance.event_time
  $Assignment.MountPrefix = $instance.mount_prefix
  $Assignment.VolumeId = $instance.snapvol_id
  $Assignment.VolumeName = $instance.snapvol_name
  return $Assignment

}

function Internal-PopulateAppStackFile

{

  param(
    $instance

  )
  $AppStackFile = New-Object -TypeName Vmware.Appvolumes.AppVolumesAppStackFile
  $AppStackFile.Name = $instance.Name
  $AppStackFile.MachineManagerType = $instance.machine_manager_type
  $AppStackFile.MachineManagerHost = $instance.machine_manager_host
  if ($instance.created_at)
  {

    $AppStackFile.CreatedAt = $instance.created_at

  }

  $AppStackFile.Missing = $instance.Missing
  $AppStackFile.Reachable = $instance.Reachable

  $AppStackFile.path = $instance.path
  $AppStackFile.DataStore = $instance.storage_location
  return $AppStackFile

}

Add-Type -ReferencedAssemblies (Get-Module Microsoft.PowerShell.Utility).NestedModules[0].path @"
using System;
using Microsoft.PowerShell;
namespace Vmware.Appvolumes

{

 public class AppVolumesVersion
 
{

 public string Version;
 public string InternalVersion;
 public string Copyright;
 

}

 public class AppVolumesSession
 
{

 public System.Collections.Generic.Dictionary<string,string> Headers;
 public Microsoft.PowerShell.Commands.WebRequestSession Session;
 public DateTime SessionStart;
 public Uri Uri;
 public string Version;
 

}

 public class AppVolumesAppStack
 
{

 public int Id;
 public string Name;
 public string Path;
 public string DataStore;
 public string FileName;
 public string Description;
 public AppStackStatus Status;
 public DateTime CreatedAt;
 public DateTime MountedAt;
 public int Size;
 public string TemplateVersion;
 public int MountCount;
 public int AssignmentsTotal;
 public int AttachmentsTotal;
 public int LocationCount;
 public int ApplicationCount;
 public Guid VolumeGuid;
 public string TemplateFileName;
 public string AgentVersion;
 public string CaptureVersion;
 public AppStackOS PrimordialOs;
 public AppStackOS[] Oses;
 public string ProvisonDuration;
 

}

 public enum AppStackStatus
 
{

 Missing = 0,
 Enabled = 1,
 Unprovisioned = 2,
 Provisioning = 3,
 Orphaned = 4,
 Legacy = 5,
 Creating = 6,
 Canceled = 7,
 Disabled = 8,
 Reserved = 9,
 Failed = 10,
 Unreachable = 11,
 
 

}

 public enum EntityType
 
{

 User = 0,
 Computer = 1,
 Group = 2,
 OrgUnit = 3,
 
 

}

 public class AppStackOS
 
{

 public int Id;
 public string Name;
 

}

 public class AppVolumesAssignment
 
{

 
 public string EntityDn;
 public string EntitySamAccountName;
 public string EntityDomain;
 public EntityType EntityType;
 public DateTime EventTime;
 public String MountPrefix;
 public int VolumeId;
 public string VolumeName;
 
 

}

 public class AppVolumesAppStackFile
 
{

 public int AppStackId;
 public string Name;
 public string MachineManagerType;
 public string MachineManagerHost;
 public DateTime CreatedAt;
 public bool Missing;
 public string Path;
 public string DataStore;
 public bool Reachable;
 
 

}

}

"@

if ($PSVersionTable.PSVersion.Major -lt 3)
{

  throw New-Object System.NotSupportedException "PowerShell V3 or higher required."

}

Export-ModuleMember -Function *AppVol*






