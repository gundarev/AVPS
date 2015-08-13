

#region Internal Functions
	
	#.ExternalHelp AppVol.psm1-help.xml
	Function Internal-GetOnlineEntity
	{
		param(
		[Vmware.Appvolumes.Entity[]]$UpEntities
		)
		
		Test-AppVolSession
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/online_entities"
		[regex]$parser = '(?:<a\shref=\"/[a-z]*#/)(?<EntityType>[A-z]*)(?:/)(?<Id>[0-9]*)(?:\"\stitle=\")(?<DisplayName>.*)(?:\">)(?<Domain>.*)(?:[\\]|[\s])(?<SamAccountName>.*)(?:</a>)'
		try
		{
			$response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
			if ($response.Success) 
			{
				$UnparsedEntities = $response.WebRequestResult.online.records
			}
			else {throw $response.message}
			
		}
		catch
		{
			Write-Error $_.Exception.message
		}
		
		foreach ($UnparsedEntity in $UnparsedEntities)
		{
			$UnparsedEntityId = [regex]::Matches($UnparsedEntity.entity_name,$parser)[0].Groups['Id'].Value
			
			foreach ($UpEntity in $UpEntities){
				if (($UnparsedEntity.entity_type -eq $UpEntity.EntityType ) -and ($UpEntity.Id -eq [int]$UnparsedEntityId))
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
						'User' {$UpEntity.HostId = $([regex]::Matches($UnparsedEntity.details,$parser)[0].Groups['Id'].Value)}
					}
				}
			}
		}
		
		
	}
	
	
	Function Internal-CheckFilter
	{
		param ($params)
		[regex] $RegexParams = '(?i)^(All|Id|VolumeId|Volume|ErrorAction|WarningAction|Verbose|Debug|ErrorVariable|WarningVariable|OutVariable|OutBuffer|PipelineVariable)$'
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
				$EntitiesFiltered += Internal-FilterWebRequestResults ($Entitity)
				
			}
			return $EntitiesFiltered
		}
		else { return $Entities }
	}
	
	Function Internal-Rest
	{
		
		param(
		[Parameter(Position = 1,Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[VMware.AppVolumes.Session]$Session,
		
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
			{$cmd ={Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.WebRequestSession -Headers $Session.Headers -Body $Body -ContentType "application/json"}}
			Post
			{$cmd ={Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.WebRequestSession -Headers $Session.Headers -Body $Body -ContentType "application/json" }}
			
			default
			{$cmd ={Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.WebRequestSession -Headers $Session.Headers -ContentType "application/json"}}
		}
		try
		{
			
			$WebRequestResult= Invoke-Command $cmd
			$message = @{ 
				WebRequestResult=$WebRequestResult;
			Success=$true}
			return $message
		}
		catch
		{
			$WebRequestResult = $_.Exception.Response.GetResponseStream()
			$reader = New-Object System.IO.StreamReader($WebRequestResult)
			$reader.BaseStream.Position = 0
			#$reader.DiscardBufferedData()
			$responseBody = [System.Web.HttpUtility]::HtmlDecode($reader.ReadToEnd())
			$message = @{ error=$_.Exception.Response.StatusCode.value__;
				message=$responseBody;
			Success=$false}
			return $message
		}
	}
	
    Function Internal-RestGet
    {
        param(
        [Parameter(Position = 1,Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({([System.URI]$_).IsAbsoluteUri})]
		[string]$Uri,
        
        [Parameter(Position = 2,Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		
		[string]$Object
        )
        $RestResult=Internal-Rest -Uri $Uri -Method Get -Session $Global:GlobalSession
        if ($RestResult.Success)
        {
            
            $Result= if ($Object) {$RestResult.WebRequestResult.$Object} else {$RestResult.WebRequestResult}
            return $Result
        }
        else
        {
            Write-Warning -Message $RestResult.message 
        }

    }

	Function Internal-FilterWebRequestResults
	{
		param(
		$Entity
		)
		$EntityList = $null
		foreach ($CurrentParameter in $($PSCmdlet.MyInvocation.BoundParameters.Keys))
		
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
					{($_ -eq "Guid") -or ($_ -eq "VolumeStatus") -or  ($_ -eq "ComputerType")-or  ($_ -eq "AgentStatus")}
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
		
		return $EntityList
		
	}
	
	Function Internal-PopulateVolume
	{
		param(
		$instance
		)
        if ($instance.id)
        {
            $Volume = New-Object -TypeName Vmware.Appvolumes.Volume
		    $Volume.VolumeId = $instance.id
		
		    $Volume.Name = $instance.Name
		    $Volume.Path = $instance.path
		    $Volume.FileName = $instance.FileName
		    $Volume.Description = $instance.description
		    $Volume.Status = $instance.Status
		    if ($instance.created_at)
		    {
			    $Volume.CreatedAt = $instance.created_at
		    }
		
		    if ($instance.mounted_at)
		    {
			    $Volume.MountedAt = $instance.mounted_at
		    }
		
		    $Volume.Size = $instance.size_mb
		    $Volume.TemplateVersion = $instance.template_version
		    $Volume.MountCount = $instance.mount_count
		    $Volume.AssignmentsTotal = $instance.assignments_total
		    $Volume.AttachmentsTotal = $instance.attachments_total
		    $Volume.LocationCount = $instance.location_count
		    $Volume.ApplicationCount = $instance.application_count
		    if ($instance.volume_guid)
		
		    {
			    $Volume.VolumeGuid = $instance.volume_guid
		    }
		
		    $Volume.TemplateFileName = $instance.template_file_name
		    $Volume.AgentVersion = $instance.agent_version
		    $Volume.CaptureVersion = $instance.capture_version
		    $os = New-Object -TypeName Vmware.Appvolumes.OperatingSystem
		    $os.id = $instance.primordial_os_id
		    $os.Name = $instance.primordial_os_name
		    $Volume.PrimordialOs = $os
		    [Vmware.Appvolumes.OperatingSystem[]]$oses = $null
		    foreach ($tmpos in $instance.oses)
		
		    {
			
			    $tmpAsos = New-Object -TypeName Vmware.Appvolumes.OperatingSystem
			    $tmpAsos.Name = $tmpos.Name
			    $tmpAsos.id = $tmpos.id
			    $oses += $tmpAsos
		    }
		
		    $Volume.oses = $oses
		    $Volume.ProvisonDuration = $instance.provision_duration
		    return $Volume
        }
		
	}
	
	Function Internal-PopulateDatastore
	{
		param(
		$instance
		)
		$LocalEntity = New-Object -TypeName Vmware.Appvolumes.DataStore
		
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
	
	Function Internal-PopulateEntity
	{
		param(
		$instance
		)
		$LocalEntity = New-Object -TypeName Vmware.Appvolumes.Entity
		
		[regex]$parser = '(?:<a\shref=\"/[a-z]*#/)(?<EntityType>[A-z]*)(?:/)(?<Id>[0-9]*)(?:\"\stitle=\")(?<DisplayName>.*)(?:\">)(?<Domain>.*)(?:[\\]|[\s])(?<SamAccountName>.*)(?:</a>)'
		try
		{
			if ($instance.upn_link) {$upn_link= $instance.upn_link} else {$upn_link= $instance.upn}
			$EntityType = [regex]::Matches($upn_link,$parser)[0].Groups['EntityType'].Value
			$Id = [regex]::Matches($upn_link,$parser)[0].Groups['Id'].Value
			$DisplayName = [regex]::Matches($upn_link,$parser)[0].Groups['DisplayName'].Value
			$Domain = [regex]::Matches($upn_link,$parser)[0].Groups['Domain'].Value
			$SamAccountName = [regex]::Matches($upn_link,$parser)[0].Groups['SamAccountName'].Value
		}
		catch
		{
#			write-error $_.Exception
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
		if ($Id) {$LocalEntity.Id = $Id }
		if ($instance.writables) {$LocalEntity.WritablesAssigned = $instance.writables}
		if ($instance.appstacks) {$LocalEntity.AppStacksAssigned = $instance.appstacks}
		if ($instance.attachments) {$LocalEntity.AppStacksAttached = $instance.attachments}
		
		if ($instance.agent_version) {$LocalEntity.AgentVersion = $instance.agent_version}
		if ($instance.os) {$LocalEntity.ComputerType = $instance.os}
		switch ($EntityType)
		{
			"Users" {$LocalEntity.EntityType = 'User'}
			"Computers" {$LocalEntity.EntityType = 'Computer'}
			"Groups" {$LocalEntity.EntityType = 'Group'}
			"Org_units" {$LocalEntity.EntityType = 'OrgUnit'}
		}
		if ($instance.uuid)
		{
			$LocalEntity.Domain =$instance.upn.split("\")[0]
			$LocalEntity.SamAccountName=$instance.upn.split("\")[1]
			$LocalEntity.Id = $instance.id
			if($instance.status -eq "Available") {$LocalEntity.AgentStatus="GoodC"}
			$LocalEntity.uuid=$instance.uuid
			$LocalEntity.Enabled=$instance.selectable
			$LocalEntity.EntityType = 'Computer'
            $LocalEntity.ProvisioningStatus=$($instance.status -replace '\s','')
		}
		if ($LocalEntity.EntityType -ne "Unknown") {return $LocalEntity}
	}
	
	Function Internal-PopulateAssignment
	{
		
		param(
		$instance
		)
		
		$splitChar= '\'
		$Assignment = New-Object -TypeName Vmware.Appvolumes.Assignment
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
	
	Function Internal-PopulateVolumeFile
	
	{
		
		param(
		$instance
		
		)
		$AppStackFile = New-Object -TypeName Vmware.Appvolumes.VolumeFile
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
Function Open-AppVolSession

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
		$ApiUri="$($Uri)cv_api/sessions"
		$AdminCredentials = (@{ 'username' = $($Username); 'password' = $($Password)})|ConvertTo-Json
		try
		{
			$WebRequestResult= Invoke-WebRequest -Uri $ApiUri -SessionVariable session -Method Post -Body $AdminCredentials -ContentType "application/json"
			$Global:GlobalSession = New-Object Vmware.Appvolumes.Session
			$Global:GlobalSession.WebRequestSession = $session
			$Global:GlobalSession.Uri = $Uri
			$Global:GlobalSession.Version = Get-AppVolVersion
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
Function Test-AppVolSession
{
	if ($Global:GlobalSession)
	{
		return
	}
	else
	{
		Write-Error  "No open App Volumes Manager session available!"
		break
	}
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Close-AppVolSession
{
	Test-AppVolSession
	try
	{
		$ApiUri="$($Global:GlobalSession.Uri)cv_api/sessions"
		$WebRequestResult= Invoke-WebRequest -Uri $ApiUri -WebSession $Global:GlobalSession.Session -Method Delete -ContentType "application/json"
		$Global:GlobalSession = $null
		return ($WebRequestResult.content)|ConvertFrom-Json
	}
	catch
	{
		Write-Output $_.Exception
	}
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolVersion
{
	process
	{
		Test-AppVolSession
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/version"
        $Response = Internal-RestGet -Uri $ApiUri 
        $Version = New-Object -TypeName Vmware.Appvolumes.Version
        $Version.CurrentVersion = $Response.version
		$Version.InternalVersion = $Response.internal
		$Version.Copyright = $Response.copyright
        return $Version
		
	}
}


#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolDataStoreConfig
{
	
	
	begin
	{
		Test-AppVolSession
		$Entity = New-Object -TypeName  Vmware.Appvolumes.AppVolumesDataStoreConfig
		
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/datastores"
		try
		{
			$response= Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
			if ($response.Success) {
				$instance=$response.WebRequestResult
				$allDataStores=Get-AppVolDataStore 
				$Entity.AppStackMachineManager=[int]$($instance.appstack_storage).Split("|")[2]
				$Entity.AppStackDefaultPath=$instance.appstack_path
				$Entity.AppStackDefautStorage=  $allDataStores|Where-Object {($_.Name -eq [string]$($instance.appstack_storage).Split("|")[0]) -and ($_.DatacenterName -eq [string]$($instance.appstack_storage).Split("|")[1] )-and ($_.MachineManager.MachineManagerId -eq [int]$($instance.appstack_storage).Split("|")[2])}
				$Entity.AppStackTemplatePath=$instance.appstack_template_path
				$Entity.DatacenterName=$instance.datacenter
				$Entity.WritableMachineManager=[int]$($instance.writable_storage).Split("|")[2]
				$Entity.WritableDefaultPath=$instance.writable_path
				$Entity.WritableDefaultStorage=$allDataStores |Where-Object {($_.Name -eq [string]$($instance.writable_storage).Split("|")[0]) -and ($_.DatacenterName -eq [string]$($instance.writable_storage).Split("|")[1] )-and ($_.MachineManager.MachineManagerId -eq [int]$($instance.writable_storage).Split("|")[2])}
				$Entity.WritableTemplatePath=$instance.writable_template_path
			}
			else {throw $response.message}
		}
		catch
		{
			Write-Error $_.Exception.message
		}
		
	}
	
	end
	{
		#Internal-GetOnlineEntity ($Entities)
		
		return $Entity
	}
	
	
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolDataStore
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
		[Vmware.Appvolumes.DataStore []]$Entities = $null
		
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/datastores"
		switch ($PsCmdlet.ParameterSetName)
		{
			"AllEntities"
			{
				$Datastores= Internal-RestGet -Uri $ApiUri -Object "datastores"
                foreach ($Entity in $($Datastores))
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
				$Datastores= Internal-RestGet -Uri $ApiUri
                foreach ($Entity in $($Datastores))
				{
					$LocalEntity = Internal-PopulateDatastore $Entity
                    if ($LocalEntity.Id -eq $Id)
                    {
                        $Entities += $LocalEntity
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
Function Add-AppVolAppStack
{
	[CmdletBinding(DefaultParameterSetName = "Template")]
	param(
	[Parameter(ParameterSetName = "Template",Mandatory = $true,Position = 0,ValueFromPipeline = $TRUE,ValueFromRemainingArguments = $false)]
	[ValidateNotNull()]
	[Vmware.Appvolumes.Template]$Template,
	
	[Parameter(ParameterSetName = "Template",Mandatory = $true,Position = 0)]
	[ValidateNotNull()]
	[string]$AppStackName,
	[Parameter(ParameterSetName = "Template",Mandatory = $false,Position = 1)]
	[ValidateNotNull()]
	[string]$AppStackDefaultPath,
	
	[Parameter(ParameterSetName = "Template",Mandatory = $false,Position = 2)]
	[ValidateNotNull()]
	[string]$AppStackDescription
	
	
	)
	
	Test-AppVolSession
	
	$ApiUri = "$($Global:GlobalSession.Uri)cv_api/appstacks"
	
	if ([string]::IsNullOrEmpty($AppStackDefaultPath)) {
		$config=Get-AppVolDataStoreConfig
		$AppStackDefaultPath=$config.AppStackDefaultPath
	}
	$postParams = @{
		name=$AppStackName;
		description=$AppStackDescription;
		datacenter=$Template.DataStore.DatacenterName;
		datastore="$($Template.DataStore.Name)|$($Template.DataStore.DatacenterName)|$($Template.DataStore.MachineManager.MachineManagerId)";
		path=$AppStackDefaultPath;
		template_path=$Template.Path;
		template_name=$Template.Name;
		bg=0
	}|ConvertTo-Json
	try
	{
		$response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Post -Body $postParams
		if ($response.Success)
		{
			$Appstack  =$response.WebRequestResult
			if ($Appstack.appstack_id)
			{
				return Get-AppVolAppStack -VolumeID $Appstack.appstack_id
			}
			else{
				return $Appstack
			}
		}
		else {throw $response.message}    
	}
	catch
	{
		Write-Error $_.Exception.message
	}
	return $AllApstacks
	
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Update-AppVolAppStack
{
	[CmdletBinding(DefaultParameterSetName = "AppStack")]
	param(
	[Parameter(ParameterSetName = "AppStack",Mandatory = $true,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelinebyPropertyName=$true)]
	[AllowNull()]
	[VMware.AppVolumes.AppVolumesAppStack[]]$AppStack,
	
	[Parameter(ParameterSetName = "AppStack",Mandatory = $false,Position = 0)]
	[ValidateNotNull()]
	[string]$AppStackName,
	
	[Parameter(ParameterSetName = "AppStack",Mandatory = $false,Position = 1)]
	[ValidateNotNull()]
	[string]$AppStackDefaultPath,
	
	[Parameter(ParameterSetName = "AppStack",Mandatory = $false,Position = 2)]
	[ValidateNotNull()]
	[VMware.AppVolumes.DataStore]$TargetDataStore,
	
	
	[Parameter(ParameterSetName = "AppStack",Mandatory = $false,Position = 3)]
	[ValidateNotNull()]
	[string]$AppStackDescription,
	
	[Parameter(ParameterSetName = "AppStack",Mandatory = $false,Position = 4)]
	[ValidateNotNull()]
	[string]$Prefix
	
	)
	begin{
		
		Test-AppVolSession
		
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/appstacks"
		$config=Get-AppVolDataStoreConfig
		[Vmware.Appvolumes.AppVolumesAppStack[]]$Entities = $null
		if ([string]::IsNullOrEmpty($AppStackDefaultPath)) {$AppStackDefaultPath=$config.AppStackDefaultPath}
		if (!$TargetDataStore) {$TargetDataStore=$config.AppStackDefautStorage}
		if ([string]::IsNullOrEmpty($AppStackName) -and ([string]::IsNullOrEmpty($Prefix))) {$Prefix=Get-Date -Format u}
	}
	process {
		foreach ($instance in $AppStack){
			if ([string]::IsNullOrEmpty($AppStackName)){$LocalAppStackName="($Prefix) $($instance.name)"}else{$LocalAppStackName=$AppStackName}
			
			$postParams = @{
				name=$LocalAppStackName;
				description=$AppStackDescription;
				datacenter=$TargetDataStore.DatacenterName;
				datastore="$($TargetDataStore.Name)|$($TargetDataStore.DatacenterName)|$($TargetDataStore.MachineManager.MachineManagerId)";
				path=$AppStackDefaultPath;
				parent_appstack_id=$instance.VolumeId;
				bg=0
			}|ConvertTo-Json
			try
			{
				$response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Post -Body $postParams
				if ($response.Success)
				{
					$Appstack = $response.WebRequestResult
					if ($Appstack.appstack_id)
					{
						$Entities += Get-AppVolAppStack -VolumeID $Appstack.appstack_id
					}
				}
				else {throw $response.message}
			}
			catch
			{
				Write-Error $_.Exception.message
			}
		}
	}
	
	end{
		return $Entities
		
	}
	
	
	
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolAppStack
{
	[CmdletBinding(DefaultParameterSetName="None")]
	param(
	[Parameter(ParameterSetName = "SelectedVolumeId",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
	[Alias('id','AppStackId')]
	[ValidateNotNull()]
	[int[]]$VolumeID,
	
	[Parameter(ParameterSetName = "SelectedVolume",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
	[ValidateNotNull()]
	[VMware.AppVolumes.Volume[]]$Volume,


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
	
	[Vmware.Appvolumes.VolumeStatus]$Status,
	
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
		[VMware.AppVolumes.Volume[]]$Entities = $null
		[Vmware.Appvolumes.Volume[]]$EntitiesFiltered = $null
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/appstacks"
        $AllDataStores=Get-AppVolDataStore
		
		
	}
	process
	{
        if (($PsCmdlet.ParameterSetName -eq "None") -and (!$VolumeID) -and (!$Volume))
		{
            $AllVolumes = Internal-RestGet -Uri $ApiUri 
            foreach ($VolumeIdInstance in $AllVolumes.id)
            {
                $VolumeUri = "$ApiUri/$VolumeIdInstance"
                $VolumeInstance= Internal-RestGet -Uri $VolumeUri -Object "appstack"
                $LocalEntity = Internal-PopulateVolume $VolumeInstance
                if ($LocalEntity)
                {
                    $LocalEntity.DataStore = $AllDataStores|Where-Object {$_.Name -eq $instance.datastore_name} |Select-Object -First 1
                    $Entities += $LocalEntity
                }
            }
		}
        if  (($VolumeID) -or ($Volume))
        {           
            $LocaclVolumeId = if ($VolumeID) {$VolumeID} else {$Volume.VolumeId}
            
			
			$VolumeUri = "$ApiUri/$LocaclVolumeId"
            $VolumeInstance= Internal-RestGet -Uri $VolumeUri -Object "appstack"
            $LocalEntity = Internal-PopulateVolume $VolumeInstance
            if ($LocalEntity)
            {
                $LocalEntity.DataStore = $AllDataStores|Where-Object {$_.Name -eq $instance.datastore_name} |Select-Object -First 1
                $Entities += $LocalEntity
            }
        }
	}
	end
	{
		
		return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
	}
	
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Start-AppVolAppStackProvisioning
{
	[CmdletBinding(DefaultParameterSetName = "AppStackAndComputer")]
	param(
	[Parameter(ParameterSetName = "AppStackAndComputer",Mandatory = $true,Position = 0)]
	[Parameter(ParameterSetName = "AppStackAndComputerId",Mandatory = $true,Position = 0)]
	[ValidateNotNull()]
	[VMware.AppVolumes.AppVolumesAppStack]$AppStack,
	
	[Parameter(ParameterSetName = "AppStackAndComputer",Mandatory = $true,Position = 1)]
	[Parameter(ParameterSetName = "AppStackIdAndComputer",Mandatory = $true,Position = 1)]
	[ValidateScript({$_.EntityType -eq "Computer"})]
	[VMware.AppVolumes.Entity]$Computer,
	
	[Parameter(ParameterSetName = "AppStackIdAndComputer",Mandatory = $true,Position = 1)]
	[Parameter(ParameterSetName = "AppStackIdAndComputerId",Mandatory = $true,Position = 1)]
	
	[int]$AppStackId,
	[ValidateNotNull()]
	[Parameter(ParameterSetName = "AppStackAndComputerId",Mandatory = $true,Position = 2)]
	[Parameter(ParameterSetName = "AppStackIdAndComputerId",Mandatory = $true,Position = 2)]
	[ValidateNotNull()]
	[int]$ComputerId
	)
	
	
	Test-AppVolSession
	
	switch ($PsCmdlet.ParameterSetName)
	{
		"AppStackAndComputer"
		{
			
		}
		"AppStackAndComputerId"
		{
			$Computer = Get-AppVolComputer -Id $ComputerId
		}
		"AppStackIdAndComputer"
		{
			$AppStack = Get-AppVolAppStack -VolumeID $AppStackId
		}
		"AppStackIdAndComputerId"
		{
			$Computer = Get-AppVolComputer -Id $ComputerId
			$AppStack = Get-AppVolAppStack -VolumeID $AppStackId
		}  
	}
	$machineguid=$(Get-AppVolProvisioner|Where-Object {$_.Id -eq $Computer.Id}).uuid
	$ApiUri = "$($Global:GlobalSession.Uri)cv_api/provisions/$($AppStack.VolumeId)/start"
	$postParams = @{
		computer_id=$Computer.Id;
		uuid=$machineguid
	}|ConvertTo-Json
    try
    {
        $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Post -Body $postParams
        if ($response.Success)
        {
            $WebRequestResult = $response.WebRequestResult|ConvertFrom-Json
            return $WebRequestResult
        }
        else {throw $response.message}
    }
    catch
    {
        Write-Error $_.Exception.message
    }	
}

Function Get-TODOAppVolAppStackProvisioning
{
	[CmdletBinding(DefaultParameterSetName = "AppStackAndComputer")]
	param(
	[Parameter(ParameterSetName = "AppStackAndComputer",Mandatory = $false,Position = 0)]
	[Parameter(ParameterSetName = "AppStackAndComputerId",Mandatory = $false,Position = 0)]
	[ValidateNotNull()]
	[VMware.AppVolumes.AppVolumesAppStack]$AppStack,
	
	[Parameter(ParameterSetName = "AppStackAndComputer",Mandatory = $false,Position = 1)]
	[Parameter(ParameterSetName = "AppStackIdAndComputer",Mandatory = $false,Position = 1)]
	[ValidateScript({$_.EntityType -eq "Computer"})]
	[VMware.AppVolumes.Entity]$Computer,
	
	[Parameter(ParameterSetName = "AppStackIdAndComputer",Mandatory = $false,Position = 1)]
	[Parameter(ParameterSetName = "AppStackIdAndComputerId",Mandatory = $false,Position = 1)]
	
	[int]$AppStackId,
	[ValidateNotNull()]
	[Parameter(ParameterSetName = "AppStackAndComputerId",Mandatory = $false,Position = 2)]
	[Parameter(ParameterSetName = "AppStackIdAndComputerId",Mandatory = $false,Position = 2)]
	[ValidateNotNull()]
	[int]$ComputerId
	)
	
	
	Test-AppVolSession
	
	switch ($PsCmdlet.ParameterSetName)
	{
		"AppStackAndComputer"
		{
			
		}
		"AppStackAndComputerId"
		{
			$Computer = Get-AppVolComputer -Id $ComputerId
		}
		"AppStackIdAndComputer"
		{
			$AppStack = Get-AppVolAppStack -VolumeID $AppStackId
		}
		"AppStackIdAndComputerId"
		{
			$Computer = Get-AppVolComputer -Id $ComputerId
			$AppStack = Get-AppVolAppStack -VolumeID $AppStackId
		}  
	}
    
    $InuseProvisioners =Get-AppVolProvisioner | Where-Object {$_.ProvisioningStatus -eq "InUse"} 


	$machineguid=$(Get-AppVolProvisioner|Where-Object {$_.Id -eq $Computer.Id}).uuid
	$ApiUri = "$($Global:GlobalSession.Uri)cv_api/provisions/$($AppStack.VolumeId)/start"
	$postParams = @{
		computer_id=$Computer.Id;
		uuid=$machineguid
	}|ConvertTo-Json
    try
    {
        $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Post -Body $postParams
        if ($response.Success)
        {
            $WebRequestResult = $response.WebRequestResult|ConvertFrom-Json
            return $WebRequestResult
        }
        else {throw $response.message}
    }
    catch
    {
        Write-Error $_.Exception.message
    }	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolAssignment
{
	
	[CmdletBinding(DefaultParameterSetName = "AllAssignments")]
	param(
	[Parameter(ParameterSetName = "AllAssignments",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
	[switch]$All,
	[Parameter(ParameterSetName = "SelectedVolumeId",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
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
		[Vmware.Appvolumes.Assignment []]$Entities = $null
		
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/assignments"
		switch ($PsCmdlet.ParameterSetName)
		{
			"AllAssignments"
			{
                try
                {
                    $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
                    if ($response.Success)
                    {
                        $tmp = $response.WebRequestResult.assignments
                        foreach ($Entity in $tmp)
				        {
					        $Entities += Internal-PopulateAssignment $Entity
				        }
                    }
                    else {throw $response.message}
                }
                catch
                {
                    Write-Error $_.Exception.message
                }
				
			}
		}
	}
	process
	{
		try
        {
            $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
            if ($response.Success)
            {
                $tmp = $response.WebRequestResult.assignments
                foreach ($Entity in $tmp)
		        {
			        $tmpAssignment = Internal-PopulateAssignment $Entity
			        if ($tmpAssignment.VolumeId -eq $VolumeId)
			        {
				        $Entities += $tmpAssignment
			        }
		        }
            }
            else {throw $response.message}
        }
        catch
        {
            Write-Error $_.Exception.message
        }
		
		
	}
	end
	{
		return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
	}
	
	
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolAppStackFile
{
	
	[CmdletBinding(DefaultParameterSetName = "AllAppStackFiles")]
	param(
	[Parameter(ParameterSetName = "SelectedVolumeId",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
	# [Alias('id')]
	[AllowNull()]
	[int[]]$VolumeID,
	
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
		[Vmware.Appvolumes.VolumeFile[]]$Entities = $null
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
			$ApiUri = "$($Global:GlobalSession.Uri)cv_api/appstacks/$AppStackId/files"
			try
            {
                $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
                if ($response.Success)
                {
                    $instances = $response.WebRequestResult
			        foreach ($instance in $instances)
			        {
				        $AppStackFile = Internal-PopulateVolumeFile $instance
				        $AppStackFile.VolumeId = $AppStackId
				        $Entities += $AppStackFile
			        }
                }
                else {throw $response.message}
            }
            catch
            {
                Write-Error $_.Exception.message
            }
            
            
            
		}
		
	}
	end
	{
		return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
	}
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolAppStackTemplate
{
	
	[CmdletBinding(DefaultParameterSetName = "Default")]
	param(
	
	[Parameter(ParameterSetName = "Default",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
	[switch]$All,
	
	[Parameter(ParameterSetName = "Specific",Position = 0,ValueFromPipeline = $true,Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[Vmware.Appvolumes.DataStore]$DataStore,
	[Parameter(ParameterSetName = "Specific",Position = 1,ValueFromPipeline = $false,Mandatory = $false)]
	[ValidateNotNullOrEmpty()]
	[string]$Path,
	[Parameter(ParameterSetName = "Specific",Position = 2,ValueFromPipeline = $false,Mandatory = $false)]
	[ValidateNotNullOrEmpty()]
	[string]$TemplatePath
	)
	begin
	
	{
		Test-AppVolSession
		[Vmware.Appvolumes.Template[]]$Entities = $null
		$config=Get-AppVolDataStoreConfig
		if (!$DataStore) {$DataStore=$config.AppStackDefautStorage}
		
		if([string]::IsNullOrEmpty($Path)) {$Path=$config.AppStackDefaultPath}
		if ([string]::IsNullOrEmpty($TemplatePath)) {$TemplatePath = $config.AppStackTemplatePath}
		$Path=[System.Web.HttpUtility]::UrlEncode($Path)
		$TemplatePath = [System.Web.HttpUtility]::UrlEncode($TemplatePath)
		
		
		
	}
	
	process
	{
		foreach ($DataStoreEntry in $DataStore)
		{        $DataStoreText= [System.Web.HttpUtility]::UrlEncode("$($DataStore.Name)|$($DataStore.DatacenterName)|$($DataStore.MachineManager.MachineManagerId)")
			
			
			$ApiUri = "$($Global:GlobalSession.Uri)cv_api/templates?datastore=$DataStoreText&path=$Path&templates_path=$TemplatePath"
			try
			{
				$response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
				if ($response.Success) {
					$instances  =$response.WebRequestResult
					foreach ($Instance in $instances.templates)
					{
						$tmpInstance = New-Object -TypeName Vmware.Appvolumes.Template
						$tmpInstance.Name =$Instance.name
						$tmpInstance.Path =$Instance.path
						$tmpInstance.Sep =$Instance.sep
						$tmpInstance.Uploading =$Instance.uploading
						$tmpInstance.DataStore= $DataStore
						
						$Entities += $tmpInstance
					}
				}
				else {throw $response.message}
			}
			catch
			{
				Write-Error $_.Exception.message
			}
		}
		
	}
	end
	{
		return  $Entities
	}
}

#.ExternalHelp AppVol.psm1-help.xml
Function Select-AppVolAppStackTemplate
{
	return Get-AppVolAppStackTemplate|Out-GridView -OutputMode:Single -Title "Select template" 
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolUser
{
	
	[CmdletBinding(DefaultParameterSetName = "AllEntities")]
	param(
	[Parameter(ParameterSetName = "AllEntities",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
	[switch]$All,
	[Parameter(ParameterSetName = "SelectedEntity",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
	[Alias('id')]
	[AllowNull()]
	[int]$Id,
	
	
	
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
		[Vmware.Appvolumes.Entity []]$Entities = $null
		
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/users"
		switch ($PsCmdlet.ParameterSetName)
		{
			"AllEntities"
			{
                try
                {
                    $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
                    if ($response.Success)
                    {
                        $tmp = $response.WebRequestResult
				        foreach ($Entity in $tmp)
				        {
					        $Entities += Internal-PopulateEntity $Entity
				        }
                    }
                }
                catch{Write-Error $_.Exception.message}

				
			}
		}
	}
	process
	{
		switch ($PsCmdlet.ParameterSetName)
		{
			"SelectedEntity"
			{
				try
                {
                    $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
                    if ($response.Success)
                    {
                        $tmp = $response.WebRequestResult
				        foreach ($Entity in $tmp)
				        {
					        $tmpEntity = Internal-PopulateEntity $Entity
					        if ($tmpEntity.Id -eq $Id)
					        {
						        $Entities += $tmpEntity
					        }
				        }
                    }
                    else {throw $response.message}
                }
                catch{Write-Error $_.Exception.message}
                
                
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
Function Get-AppVolComputer
{
	
	[CmdletBinding(DefaultParameterSetName = "AllEntities")]
	param(
	[Parameter(ParameterSetName = "AllEntities",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
	[switch]$All,
	[Parameter(ParameterSetName = "SelectedEntity",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
	[Alias('id')]
	[AllowNull()]
	[int]$Id,
	
	
	
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
		[Vmware.Appvolumes.Entity []]$Entities = $null
		
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/computers"
		switch ($PsCmdlet.ParameterSetName)
		{
			"AllEntities"
			{
                try
                {
                    $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
                    if ($response.Success)
                    {
                        $tmp = $response.WebRequestResult
				        foreach ($Entity in $tmp)
				        {
					        $Entities += Internal-PopulateEntity $Entity
				        }
                    }
                    else {throw $response.message}
                }
                catch{Write-Error $_.Exception.message}
				
			}
		}
	}
	process
	{
		switch ($PsCmdlet.ParameterSetName)
		{
			"SelectedEntity"
			{
                try
                {
                    $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
                    if ($response.Success)
                    {
                        $tmp =$response.WebRequestResult
				        foreach ($Entity in $tmp)
				        {
					        $tmpEntity = Internal-PopulateEntity $Entity
					        if ($tmpEntity.Id -eq $Id)
					        {
						        $Entities += $tmpEntity
					        }
				        }
                    }
                    else {throw $response.message}
                }
                catch{Write-Error $_.Exception.message}
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
Function Get-AppVolProvisioner
{
	
	[CmdletBinding(DefaultParameterSetName = "AllEntities")]
	param(
	[Parameter(ParameterSetName = "AllEntities",Position = 0,ValueFromPipeline = $true,Mandatory = $false)]
	[string]$Filter
	
	)
	begin
	{
		Test-AppVolSession
		[Vmware.Appvolumes.Entity []]$Entities = $null
		
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/provisioners?filter=$Filter"
		try
        {
             $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
             if ($response.Success)
            {
                $tmp = $response.WebRequestResult
		        foreach ($Entity in $tmp.provisioners)
		        {
			        $Entities += Internal-PopulateEntity $Entity
		        }
            }
            else {throw $response.message}
        }
        catch{Write-Error $_.Exception.message}
	
		return  $($Entities|Where-Object {$_.SamAccountName -like "*$Filter*"})
	}
	
	
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolMaintenanceComputer
{
	
	[CmdletBinding(DefaultParameterSetName = "AllEntities")]
	param(
	[Parameter(ParameterSetName = "AllEntities",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
	[switch]$All,
	[Parameter(ParameterSetName = "SelectedEntity",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
	[Alias('id')]
	[AllowNull()]
	[int]$Id,
	
	
	
	[ValidateNotNull()]
	[switch]$Enabled,
	
	[ValidateNotNull()] 
	[string]$DisplayName,
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
		[Vmware.Appvolumes.Entity []]$Entities = $null
		$allMaintenanceComputers=Get-AppVolComputer -AgentVersion "AVMAINTENANCE"
		switch ($PsCmdlet.ParameterSetName)
		{
			"AllEntities"
			{
				$Entities =$allMaintenanceComputers
			}
		}
	}
	process
	{
		switch ($PsCmdlet.ParameterSetName)
		{
			"SelectedEntity"
			{
				foreach ($Entity in $allMaintenanceComputers)
				{
					
					if ($Entity.Id -eq $Id)
					{
						$Entities = $Entity
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

Function Add-AppVolMaintenanceComputer
{
	
	
	param(
	[Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $TRUE)]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName
	
	
	)
	
	Test-AppVolSession
	
	$ApiUri = "$($Global:GlobalSession.Uri)computer-startup?osver=6.1.7601&sp=1.0&suite=256&product=1&arch=9&proc=1&agentver=AVMAINTENANCE"
	
	$tmp=Invoke-Command  -ComputerName $ComputerName -ScriptBlock {param($ApiUri) Invoke-WebRequest -Uri "$ApiUri"  -Credential $(new-object -typename System.Management.Automation.PSCredential ("AVMAINTENANCE\AVMAINTENANCE$",$(ConvertTo-SecureString "NONE" -AsPlainText -Force)))} -ArgumentList $ApiUri
	if ($tmp.StatusCode -eq 200){
		$computerSamAccountName= $tmp.Content.Split("\")[1]    
		
		$MaintenanceComputer=Get-AppVolComputer -AgentVersion "AVMAINTENANCE"|Where-Object {$_.SamAccountName -eq $computerSamAccountName}
		
	}
	return $MaintenanceComputer
	
	
	
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolGroup
{
	
	[CmdletBinding(DefaultParameterSetName = "AllEntities")]
	param(
	[Parameter(ParameterSetName = "AllEntities",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
	[switch]$All,
	[Parameter(ParameterSetName = "SelectedEntity",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
	[Alias('id')]
	[AllowNull()]
	[int]$Id,
	
	
	
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
		[Vmware.Appvolumes.Entity []]$Entities = $null
		
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/groups"
		switch ($PsCmdlet.ParameterSetName)
		{
			"AllEntities"
			{
                try
                {
                    $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
                    if ($response.Success)
                    {
                        $tmp = $response.WebRequestResult.groups
				        foreach ($Entity in $tmp)
				        {
					        $Entities += Internal-PopulateEntity $Entity
				        }
                    }
                    else {throw $response.message}
                }
                catch{Write-Error $_.Exception.message}


				
			}
		}
	}
	process
	{
		switch ($PsCmdlet.ParameterSetName)
		{
			"SelectedEntity"
			{
                try
                {
                    $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
                    if ($response.Success)
                    {
                        $tmp = $response.WebRequestResult.groups
				        foreach ($Entity in $tmp)
				        {
					        $tmpEntity = Internal-PopulateEntity $Entity
					        if ($tmpEntity.Id -eq $Id)
					        {
						        $Entities += $tmpEntity
					        }
				        }
                    }
                    else {throw $response.message}

                }
                catch{Write-Error $_.Exception.message}


				
			}
		}
	}
	end
	{
		return Internal-ReturnGet $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
	}
	
	
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolOrgUnit
{
	
	[CmdletBinding(DefaultParameterSetName = "AllEntities")]
	param(
	[Parameter(ParameterSetName = "AllEntities",Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
	[switch]$All,
	[Parameter(ParameterSetName = "SelectedEntity",Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = "Enter one or more AppStack IDs separated by commas.")]
	[Alias('id')]
	[AllowNull()]
	[int]$Id,
	
	
	
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
		[Vmware.Appvolumes.Entity []]$Entities = $null
		
		$ApiUri = "$($Global:GlobalSession.Uri)cv_api/org_units"
		switch ($PsCmdlet.ParameterSetName)
		{
			"AllEntities"
			{
                try
                {
                    $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
                    if ($response.Success)
                    {
                        $tmp = $response.WebRequestResult.org_units
				        foreach ($Entity in $tmp)
				        {
					        $Entities += Internal-PopulateEntity $Entity
				        }
                    }
                    else {throw $response.message}
                }
                catch{Write-Error $_.Exception.message}
				
			}
		}
	}
	process
	{
		switch ($PsCmdlet.ParameterSetName)
		{
			"SelectedEntity"
			{
				
                try
                {
                    $response = Internal-Rest -Session $Global:GlobalSession -Uri $ApiUri -Method Get
                    if ($response.Success)
                    {
                        $tmp = $response.WebRequestResult.org_units
				        foreach ($Entity in $tmp)
				        {
					        $tmpEntity = Internal-PopulateEntity $Entity
					        if ($tmpEntity.Id -eq $Id)
					        {
						        $Entities += $tmpEntity
					        }
				        }
                    }
                    else {throw $response.message}
                }
                catch{Write-Error $_.Exception.message}
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
Function Set-TODOAppStack
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
		$WebRequestResult = (Internal-Rest -Session $Session -Uri $uri -Method Put).appstack
		
		return $WebRequestResult | ft
		
		
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
Function Add-TODOAppStackAssignment
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
	$ADWebRequestResults = $Search.Findall()
	$assignments = @{
		
		entity_type = ($ADWebRequestResults[0].Properties["objectclass"])[($ADWebRequestResults[0].Properties["objectclass"]).Count - 1]
		path = $($ADWebRequestResults[0].Properties["DistinguishedName"])
		
		
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
	
	$WebRequestResult = Invoke-RestMethod -Uri $uri -Method post -WebSession $Session.Session -Headers $headers -Body $body -ContentType "application/json"
	[hashtable]$Return = @{
		
	}
	
	$Return.WebRequestResult = ($WebRequestResult | Get-Member -MemberType NoteProperty)[-1].Name
	$Return.message = $WebRequestResult.(($WebRequestResult | Get-Member -MemberType NoteProperty)[-1].Name)
	
	return $Return
	
}


if ($PSVersionTable.PSVersion.Major -lt 3)
{
	
	throw New-Object System.NotSupportedException "PowerShell V3 or higher required."
	
}

Export-ModuleMember -Function *AppVol*






