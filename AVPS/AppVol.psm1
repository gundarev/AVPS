#region Internal Functions
function Internal-CheckFilter
{
param ($params)
[regex] $RegexParams = '(?i)^(All|VolumeId|ErrorAction|WarningAction|Verbose|Debug|ErrorVariable|WarningVariable|OutVariable|OutBuffer|PipelineVariable)$'
if ($($params -notmatch $RegexParams).count -gt 0){return $true}else{return $false}
}

Function Internal-ReturnGet 
{
	 param (
        $ParamKeys, 
        $Entities
		
	)
  if (Internal-CheckFilter $ParamKeys) 
   {

   $EntitiesFiltered=@()
   foreach ($Entitity in $Entities)
    {
      $EntitiesFiltered += Internal-FilterResults ($Entitity)
      
    }
    return $EntitiesFiltered
   }
    
    
    else { return $Entities }
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
        {(($_ -eq "SwitchParameter") -and (-not (@('gt','ge','lt','le', 'Exact', 'Like', 'Not') -contains $CurrentParameter )))}
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
  $appStack.VolumeId = $instance.id
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
  $Assignment.DistignushedName = $instance.entity_dn
  $Assignment.SamAccountName = $instance.entity_upn.Split('\')[1]
  $Assignment.Domain = $instance.entity_upn.Split('\')[0]
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

#endregion


#.ExternalHelp AppVol.psm1-help.xml
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

#.ExternalHelp AppVol.psm1-help.xml
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
 
}

#.ExternalHelp AppVol.psm1-help.xml
function Close-AppVolSession
{
    Test-AppVolSession
    try
    {
        $rooturi="$($Global:GlobalSession.Uri)cv_api/sessions"
        $result= Invoke-WebRequest -Uri $rooturi -WebSession $Global:GlobalSession.Session -Method Delete -ContentType "application/json"
        $Global:GlobalSession = $null
        return ($result.content)|ConvertFrom-Json
    }
    catch
    {
        Write-Output $_.Exception
    }
}

#.ExternalHelp AppVol.psm1-help.xml
function Get-AppVolVersion
{
  process
  {
    Test-AppVolSession
    $rooturi = "$($Global:GlobalSession.Uri)cv_api/version"
    try
    {
      $result = Internal-Rest -Uri $rooturi -Method Get -Session $Global:GlobalSession
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
}

#.ExternalHelp AppVol.psm1-help.xml
function Get-AppVolAppStack
{
  [CmdletBinding(DefaultParameterSetName = "AllAppStacks")]
  param(
    [Parameter(ParameterSetName = "SelectedAppStack",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
    [Alias('id','AppStackId')]
    [AllowNull()]
    [int[]]$VolumeID,
    
    [Parameter(ParameterSetName = "AllAppStacks",Position = 0)]
    [switch]$All,
    
    [ValidateNotNull()]
    [string]$Name,

    [ValidateNotNull()]
    [string]$Path,

    [ValidateNotNull()]
    [string]$DataStore,

    [ValidateNotNull()]
    [string]$FileName,

    [ValidateNotNull()]
    [string]$Description,

    [ValidateNotNull()]
    [Vmware.Appvolumes.AppStackStatus]$Status,

    [ValidateNotNull()]
    [datetime]$CreatedAt,

    [ValidateNotNull()]
    [datetime]$MountedAt,

    [ValidateNotNull()]
    [int]$Size,

    [ValidateNotNull()]
    [string]$TemplateVersion,

    [ValidateNotNull()]
    [int]$MountCount,

    [ValidateNotNull()]
    [int]$AssignmentsTotal,

    [ValidateNotNull()]
    [int]$LocationCount,

    [ValidateNotNull()]
    [int]$ApplicationCount,

    [ValidateNotNull()]
    [guid]$VolumeGuid,

    [ValidateNotNull()]
    [string]$TemplateFileName,

    [ValidateNotNull()]
    [string]$AgentVersion,

    [ValidateNotNull()]
    [string]$CaptureVersion,

    [switch]$Exact,
    [switch]$Like,

    [switch]$ge,
    [switch]$le,
    [switch]$gt,
    [switch]$lt,

    [switch]$Not

  )
  begin
  {
    Test-AppVolSession
    [Vmware.Appvolumes.AppVolumesAppStack[]]$Entities = $null
    [Vmware.Appvolumes.AppVolumesAppStack[]]$EntitiesFiltered = $null
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
          $Entities += Internal-PopulateAppStack $instance
        } 
      } 
      
  }
  }
  process
  {
    
     foreach ($AppStackId in $VolumeID)
        {
          $uri = "$rooturi/$AppStackId"
          $instance = (Internal-Rest -Session $Global:GlobalSession -Uri $uri -Method Get).appstack

          $Entities += Internal-PopulateAppStack $instance
        }
        
        
   
  }
  end
  {
  
 return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
 }
  

}

#.ExternalHelp AppVol.psm1-help.xml
function Get-AppVolAssignment
{

  [CmdletBinding(DefaultParameterSetName = "AllAssignments")]
  param(
    [Parameter(ParameterSetName = "AllAssignments",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
    [switch]$All,
    [Parameter(ParameterSetName = "SelectedVolume",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
    [Alias('id')]
    [AllowNull()]
    [int]$VolumeId,

    
    [ValidateNotNull()]
    [string]$DistignushedName,

    [ValidateNotNull()]
    [string]$SamAccountName,

    [ValidateNotNull()]
    [string]$Domain,

    [ValidateNotNull()]
    [Vmware.Appvolumes.EntityType]$EntityType,

    [ValidateNotNull()]
    [datetime]$EventTime,

    [ValidateNotNull()]
    [string]$MountPrefix,

    
    [ValidateNotNull()]
    [string]$VolumeName,
   
    [switch]$Exact,
    [switch]$Like,

    [switch]$ge,
    [switch]$le,
    [switch]$gt,
    [switch]$lt,

    [switch]$Not

  )
  begin
  {
    Test-AppVolSession
    [Vmware.Appvolumes.AppVolumesAssignment []]$Entities = $null
    
    $rooturi = "$($Global:GlobalSession.Uri)cv_api/assignments"
    switch ($PsCmdlet.ParameterSetName)
    {
      "AllAssignments"
      {
        $tmp = (Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get).assignments
        foreach ($Entity in $tmp)
        {
          $Entities += Internal-PopulateAssignment $Entity
        }
      }
      }
  }
  process
  {
   
        $tmp = (Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get).assignments
        foreach ($Entity in $tmp)
        {
          $tmpAssignment = Internal-PopulateAssignment $Entity
          if ($tmpAssignment.VolumeId -eq $VolumeId)
          {
            $Entities += $tmpAssignment
          }
        }
  }
  end
  {
   return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
  }

  

}

#.ExternalHelp AppVol.psm1-help.xml
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


if ($PSVersionTable.PSVersion.Major -lt 3)
{

  throw New-Object System.NotSupportedException "PowerShell V3 or higher required."

}

Export-ModuleMember -Function *AppVol*






