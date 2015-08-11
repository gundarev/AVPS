﻿#region Internal Functions

#.ExternalHelp AppVol.psm1-help.xml
function Internal-GetOnlineEntity
{

  
  param(
  
  [Vmware.Appvolumes.AppVolumesEntity[]]$UpEntities

  )
  
    Test-AppVolSession
    $rooturi = "$($Global:GlobalSession.Uri)cv_api/online_entities"
    [regex]$parser = '(?:<a\shref=\"/[a-z]*#/)(?<EntityType>[A-z]*)(?:/)(?<EntityId>[0-9]*)(?:\"\stitle=\")(?<DisplayName>.*)(?:\">)(?<Domain>.*)(?:[\\]|[\s])(?<SamAccountName>.*)(?:</a>)'
            
    try
        {
            $UnparsedEntities = $(Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get).online.records
        }
    catch{}

    foreach ($UnparsedEntity in $UnparsedEntities)
        {
            $UnparsedEntityId = [regex]::Matches($UnparsedEntity.entity_name,$parser)[0].Groups['EntityId'].Value

            foreach ($UpEntity in $UpEntities){
            if (($UnparsedEntity.entity_type -eq $UpEntity.EntityType ) -and ($UpEntity.EntityId -eq [int]$UnparsedEntityId))
            {
                switch ($UnparsedEntity.agent_status)
                {
                    "red" {$UpEntity.AgentStatus = 'Red'}
                    "green" {$UpEntity.AgentStatus = 'Green'}
                    "good-c" {$UpEntity.AgentStatus = 'GoodC'}
                    "good-W" {$UpEntity.AgentStatus = 'GoodW'}
                }
                if ($UnparsedEntity.connection_time) {$UpEntity.ConnectionTime = $UnparsedEntity.connection_time }
                switch ($UpEntity.EntityType)
                {
                'Computer' {$UpEntity.IPAddress = $(($UnparsedEntity.details) -replace "IP: ", "")}
                'User' {$UpEntity.HostId = $([regex]::Matches($UnparsedEntity.details,$parser)[0].Groups['EntityId'].Value)}

                }
          }
        }
      }
   

}


function Internal-CheckFilter
{
param ($params)
[regex] $RegexParams = '(?i)^(All|EntityId|VolumeId|ErrorAction|WarningAction|Verbose|Debug|ErrorVariable|WarningVariable|OutVariable|OutBuffer|PipelineVariable)$'
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
    if (-not (@('VolumeId','All','Not','VolumeID','EntityId') -contains $CurrentParameter ) )
    {
      switch ($PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter].GetType().Name)
      {
         {($_ -match "String") -or ($_ -eq "IPAddress")}
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
        "DatastoreCategory"
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
        {($_ -eq "Guid") -or ($_ -eq "AppStackStatus") -or  ($_ -eq "ComputerType")-or  ($_ -eq "AgentStatus")}
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

function Internal-PopulateDatastore

{

  param(
    $instance

  )
  $LocalEntity = New-Object -TypeName Vmware.Appvolumes.AppVolumesDataStore

if ($instance.accessible) {$LocalEntity.Accessible = $instance.accessible}


if ($instance.category) {$LocalEntity.DatastoreCategory = $instance.category}
if ($instance.uniq_string) {$LocalEntity.MachineManager = [int]$($instance.uniq_string).Split("|")[2]}

if ($instance.datacenter) {$LocalEntity.DatacenterName = $instance.datacenter}
if ($instance.description) {$LocalEntity.Description = $instance.description}
if ($instance.display_name) {$LocalEntity.DisplayName = $instance.display_name}
if ($instance.host) {$LocalEntity.HostName = $instance.host}
if ($instance.id) {$LocalEntity.DatastoreId = $instance.id}
if ($instance.identifier) {$LocalEntity.TextIdentifier = $instance.identifier}
if ($instance.name) {$LocalEntity.Name = $instance.name}
if ($instance.note) {$LocalEntity.Note = $instance.note}


  
  return $LocalEntity

}
function Internal-PopulateEntity

{

  param(
    $instance

  )
  $LocalEntity = New-Object -TypeName Vmware.Appvolumes.AppVolumesEntity

[regex]$parser = '(?:<a\shref=\"/[a-z]*#/)(?<EntityType>[A-z]*)(?:/)(?<EntityId>[0-9]*)(?:\"\stitle=\")(?<DisplayName>.*)(?:\">)(?<Domain>.*)(?:[\\]|[\s])(?<SamAccountName>.*)(?:</a>)'
try
{
if ($instance.upn_link) {$upn_link= $instance.upn_link} else {$upn_link= $instance.upn}
$EntityType = [regex]::Matches($upn_link,$parser)[0].Groups['EntityType'].Value
$EntityId = [regex]::Matches($upn_link,$parser)[0].Groups['EntityId'].Value
$DisplayName = [regex]::Matches($upn_link,$parser)[0].Groups['DisplayName'].Value
$Domain = [regex]::Matches($upn_link,$parser)[0].Groups['Domain'].Value
$SamAccountName = [regex]::Matches($upn_link,$parser)[0].Groups['SamAccountName'].Value

}
catch
{
}


if ($instance.enabled) {$LocalEntity.Enabled = $instance.enabled}
if ($instance.last_login) 
{
    $LocalEntity.LastLogin = $($instance.last_login -replace " UTC","Z")
    }
if ($instance.logins) {$LocalEntity.NumLogins = $instance.logins}

if ($DisplayName) {$LocalEntity.DisplayName = $DisplayName }
if ($SamAccountName) {$LocalEntity.SamAccountName = $SamAccountName }
if ($Domain) {$LocalEntity.Domain = $Domain }
if ($EntityId) {$LocalEntity.EntityId = $EntityId }




if ($instance.writables) {$LocalEntity.WritablesAssigned = $instance.writables}
if ($instance.appstacks) {$LocalEntity.AppStacksAssigned = $instance.appstacks}
if ($instance.attachments) {$LocalEntity.AppStacksAttached = $instance.attachments}

if ($instance.agent_version) {$LocalEntity.AgentVersion = $instance.agent_version}
if ($instance.os) {$LocalEntity.ComputerType = $instance.os}
switch ($EntityType)
{
"Users" 
    {
        $LocalEntity.EntityType = 'User'
        
    }
"Computers" 
    {
        $LocalEntity.EntityType = 'Computer'
    }
"Groups" {$LocalEntity.EntityType = 'Group'}
"Org_units" {$LocalEntity.EntityType = 'OrgUnit'}
}
  
  return $LocalEntity

}
function Internal-PopulateAssignment

{

  param(
    $instance

  )
  $splitChar= '\'
  $Assignment = New-Object -TypeName Vmware.Appvolumes.AppVolumesAssignment
  $Assignment.DistignushedName = $instance.entity_dn
  $Assignment.EntityType = $instance.entityt
  if ($Assignment.EntityType -eq 'OrgUnit') {$splitChar= ' '}
  $Assignment.SamAccountName = $instance.entity_upn.Split($splitChar)[1]
  $Assignment.Domain = $instance.entity_upn.Split($splitChar)[0]
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
function Get-AppVolDataStoreConfig
{

  
  begin
  {
    Test-AppVolSession
    [Vmware.Appvolumes.AppVolumesDataStore []]$Entities = $null
    
    $rooturi = "$($Global:GlobalSession.Uri)cv_api/datastores"
    switch ($PsCmdlet.ParameterSetName)
    {
      "AllEntities"
      {
        $tmp = Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get
        foreach ($Entity in $($tmp.datastores))
        {
          $Entities += Internal-PopulateDatastore $Entity
        }
      }
      }
  }
  process
  {
   switch ($PsCmdlet.ParameterSetName)
    {
      "SelectedEntity"
      {
        $tmp = $(Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get).datastores
        foreach ($Entity in $tmp)
        {
          $tmpEntity = Internal-PopulateDatastore $Entity
          if ($tmpEntity.EntityId -eq $EntityId)
          {
            $Entities += $tmpEntity
          }
        }
      }
    }
  }
  end
  {
  #Internal-GetOnlineEntity ($Entities)
 
   return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
  }

  

}




#.ExternalHelp AppVol.psm1-help.xml
function Get-AppVolDataStore
{

  [CmdletBinding(DefaultParameterSetName = "AllEntities")]
  param(
    [Parameter(ParameterSetName = "AllEntities",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
    [switch]$All,
    [Parameter(ParameterSetName = "SelectedEntity",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
    [Alias('id')]
    [AllowNull()]
    [int]$DatastoreId,

    

[ValidateNotNull()]
[switch]$Accessible,

[ValidateNotNull()] 
[VMware.AppVolumes.DataStoreCategory]$DataStoreCategory,

[ValidateNotNull()]
[string]$DataCenterName,

[ValidateNotNull()]
[int]$DataCenterId,

[ValidateNotNull()]
[string]$Name,


    [switch]$Exact,
    [switch]$Like,

  
    [switch]$Not

  )
  begin
  {
    Test-AppVolSession
    [Vmware.Appvolumes.AppVolumesDataStore []]$Entities = $null
    
    $rooturi = "$($Global:GlobalSession.Uri)cv_api/datastores"
    switch ($PsCmdlet.ParameterSetName)
    {
      "AllEntities"
      {
        $tmp = Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get
        foreach ($Entity in $($tmp.datastores))
        {
          $Entities += Internal-PopulateDatastore $Entity
        }
      }
      }
  }
  process
  {
   switch ($PsCmdlet.ParameterSetName)
    {
      "SelectedEntity"
      {
        $tmp = $(Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get).datastores
        foreach ($Entity in $tmp)
        {
          $tmpEntity = Internal-PopulateDatastore $Entity
          if ($tmpEntity.EntityId -eq $EntityId)
          {
            $Entities += $tmpEntity
          }
        }
      }
    }
  }
  end
  {
  #Internal-GetOnlineEntity ($Entities)
 
   return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
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
    [Parameter(ParameterSetName = "SelectedVolume",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
    [Alias('id')]
    [AllowNull()]
    [int]$VolumeID,
    
    [Parameter(ParameterSetName = "AllAppStackFiles",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
    [switch]$All,
    
    [ValidateNotNull()]
    [switch]$Missing,
    [ValidateNotNull()]
    [switch]$Reachable,
    [ValidateNotNull()]
    [string]$DataStore,
   
    [switch]$Exact,
    [switch]$Like,
    [switch]$Not
  )
  begin

  {
    Test-AppVolSession
    [Vmware.Appvolumes.AppVolumesAppStackFile[]]$Entities = $null
     switch ($PsCmdlet.ParameterSetName)
    {
    "AllAppStackFiles"
      {
        $Entities = Get-AppVolAppStack | Get-AppVolAppStackFile
      }
    }
  }

  process
  {
        foreach ($AppStackId in $VolumeID)
        {
          $rooturi = "$($Global:GlobalSession.Uri)cv_api/appstacks/$AppStackId/files"
          $instances = (Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get)
          foreach ($instance in $instances)
          {
            $AppStackFile = Internal-PopulateAppStackFile $instance
            $AppStackFile.VolumeId = $AppStackId
            $Entities += $AppStackFile
          }
        }
  
  }
  end
  {
    return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
  }
}




#.ExternalHelp AppVol.psm1-help.xml
function Get-AppVolUser
{

  [CmdletBinding(DefaultParameterSetName = "AllEntities")]
  param(
    [Parameter(ParameterSetName = "AllEntities",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
    [switch]$All,
    [Parameter(ParameterSetName = "SelectedEntity",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
    [Alias('id')]
    [AllowNull()]
    [int]$EntityId,

    

[ValidateNotNull()]
[switch]$Enabled,

[ValidateNotNull()]
[DateTime]$LastLogin,


[ValidateNotNull()] 
[int]$NumLogins,

[ValidateNotNull()] 
[string]$DisplayName,

[ValidateNotNull()] 
[string]$SamAccountName,

[ValidateNotNull()] 
[string]$Domain,

[ValidateNotNull()] 
[int]$WritablesAssigned,

[ValidateNotNull()] 
[int]$AppStacksAssigned,

[ValidateNotNull()] 
[int]$AppStacksAttached,

[ValidateNotNull()] 
[int]$HostId,


[ValidateNotNull()]
[DateTime]$ConnectionTime,

[ValidateNotNull()] 
[VMware.AppVolumes.AgentStatus]$AgentStatus,


   
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
    [Vmware.Appvolumes.AppVolumesEntity []]$Entities = $null
    
    $rooturi = "$($Global:GlobalSession.Uri)cv_api/users"
    switch ($PsCmdlet.ParameterSetName)
    {
      "AllEntities"
      {
        $tmp = Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get
        foreach ($Entity in $tmp)
        {
          $Entities += Internal-PopulateEntity $Entity
        }
      }
      }
  }
  process
  {
   switch ($PsCmdlet.ParameterSetName)
    {
      "SelectedEntity"
      {
        $tmp = Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get
        foreach ($Entity in $tmp)
        {
          $tmpEntity = Internal-PopulateEntity $Entity
          if ($tmpEntity.EntityId -eq $EntityId)
          {
            $Entities += $tmpEntity
          }
        }
      }
    }
  }
  end
  {
  Internal-GetOnlineEntity ($Entities)
   return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
  }

  

}

#.ExternalHelp AppVol.psm1-help.xml
function Get-AppVolComputer
{

  [CmdletBinding(DefaultParameterSetName = "AllEntities")]
  param(
    [Parameter(ParameterSetName = "AllEntities",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
    [switch]$All,
    [Parameter(ParameterSetName = "SelectedEntity",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
    [Alias('id')]
    [AllowNull()]
    [int]$EntityId,

    

[ValidateNotNull()]
[switch]$Enabled,

[ValidateNotNull()]
[DateTime]$LastLogin,

[ValidateNotNull()]
[DateTime]$ConnectionTime,

[ValidateNotNull()] 
[int]$NumLogins,

[ValidateNotNull()] 
[string]$DisplayName,

[ValidateNotNull()] 
[string]$SamAccountName,

[ValidateNotNull()] 
[string]$Domain,

[ValidateNotNull()] 
[int]$WritablesAssigned,

[ValidateNotNull()] 
[int]$AppStacksAssigned,

[ValidateNotNull()] 
[int]$AppStacksAttached,

[ValidateNotNull()] 
[string]$AgentVersion,

[ValidateNotNull()] 
[VMware.AppVolumes.ComputerType]$ComputerType,

[ValidateNotNull()] 
[ipaddress]$IpAddress,

[ValidateNotNull()] 
[VMware.AppVolumes.AgentStatus]$AgentStatus,


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
    [Vmware.Appvolumes.AppVolumesEntity []]$Entities = $null
    
    $rooturi = "$($Global:GlobalSession.Uri)cv_api/computers"
    switch ($PsCmdlet.ParameterSetName)
    {
      "AllEntities"
      {
        $tmp = Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get
        foreach ($Entity in $tmp)
        {
          $Entities += Internal-PopulateEntity $Entity
        }
      }
      }
  }
  process
  {
   switch ($PsCmdlet.ParameterSetName)
    {
      "SelectedEntity"
      {
        $tmp = Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get
        foreach ($Entity in $tmp)
        {
          $tmpEntity = Internal-PopulateEntity $Entity
          if ($tmpEntity.EntityId -eq $EntityId)
          {
            $Entities += $tmpEntity
          }
        }
      }
    }
  }
  end
  {
  Internal-GetOnlineEntity ($Entities)
 
   return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
  }

  

}


#.ExternalHelp AppVol.psm1-help.xml
function Get-AppVolGroup
{

  [CmdletBinding(DefaultParameterSetName = "AllEntities")]
  param(
    [Parameter(ParameterSetName = "AllEntities",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
    [switch]$All,
    [Parameter(ParameterSetName = "SelectedEntity",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
    [Alias('id')]
    [AllowNull()]
    [int]$EntityId,

    

[ValidateNotNull()]
[DateTime]$LastLogin,


[ValidateNotNull()] 
[string]$DisplayName,

[ValidateNotNull()] 
[string]$SamAccountName,

[ValidateNotNull()] 
[string]$Domain,

[ValidateNotNull()] 
[int]$AppStacksAssigned,


   
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
    [Vmware.Appvolumes.AppVolumesEntity []]$Entities = $null
    
    $rooturi = "$($Global:GlobalSession.Uri)cv_api/groups"
    switch ($PsCmdlet.ParameterSetName)
    {
      "AllEntities"
      {
        $tmp = $(Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get).groups
        foreach ($Entity in $tmp)
        {
          $Entities += Internal-PopulateEntity $Entity
        }
      }
      }
  }
  process
  {
   switch ($PsCmdlet.ParameterSetName)
    {
      "SelectedEntity"
      {
        $tmp = $(Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get).groups
        foreach ($Entity in $tmp)
        {
          $tmpEntity = Internal-PopulateEntity $Entity
          if ($tmpEntity.EntityId -eq $EntityId)
          {
            $Entities += $tmpEntity
          }
        }
      }
    }
  }
  end
  {
   return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
  }

  

}

#.ExternalHelp AppVol.psm1-help.xml
function Get-AppVolOrgUnit
{

  [CmdletBinding(DefaultParameterSetName = "AllEntities")]
  param(
    [Parameter(ParameterSetName = "AllEntities",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
    [switch]$All,
    [Parameter(ParameterSetName = "SelectedEntity",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
    [Alias('id')]
    [AllowNull()]
    [int]$EntityId,

    

[ValidateNotNull()]
[DateTime]$LastLogin,


[ValidateNotNull()] 
[string]$DisplayName,

[ValidateNotNull()] 
[string]$SamAccountName,

[ValidateNotNull()] 
[string]$Domain,

[ValidateNotNull()] 
[int]$AppStacksAssigned,


   
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
    [Vmware.Appvolumes.AppVolumesEntity []]$Entities = $null
    
    $rooturi = "$($Global:GlobalSession.Uri)cv_api/org_units"
    switch ($PsCmdlet.ParameterSetName)
    {
      "AllEntities"
      {
        $tmp = $(Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get).org_units
        foreach ($Entity in $tmp)
        {
          $Entities += Internal-PopulateEntity $Entity
        }
      }
      }
  }
  process
  {
   switch ($PsCmdlet.ParameterSetName)
    {
      "SelectedEntity"
      {
        $tmp = $(Internal-Rest -Session $Global:GlobalSession -Uri $rooturi -Method Get).org_units
        foreach ($Entity in $tmp)
        {
          $tmpEntity = Internal-PopulateEntity $Entity
          if ($tmpEntity.EntityId -eq $EntityId)
          {
            $Entities += $tmpEntity
          }
        }
      }
    }
  }
  end
  {
   return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
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





