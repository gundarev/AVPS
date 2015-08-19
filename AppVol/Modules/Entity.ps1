Function Get-AppVolEntity
{
    [CmdletBinding(DefaultParameterSetName='None')]
    param(
        [Parameter(Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = 'Enter one or more AppStack IDs separated by commas.')]
	
        [AllowNull()]
        [int]$Id,
	
        [ValidateNotNull()] 
        [string]$SamAccountName,

        [ValidateNotNull()] 
        [string]$Domain,
	
        [ValidateNotNull()] 
        [string]$DisplayName,
	
        [ValidateNotNull()] 
        [int]$AppStacksAssigned,
	
        [ValidateNotNull()]
        [DateTime]$LastLogin,
	
        [ValidateNotNull()]
        [VMware.AppVolumes.EntityType]$EntityType,
	    
        [ValidateNotNull()]
        [VMware.AppVolumes.ProvisioningStatus]$ProvisioningStatus,
	
        [ValidateNotNull()]
        [switch]$Enabled,
	
        [ValidateNotNull()] 
        [int]$WritablesAssigned,
	
        [ValidateNotNull()] 
        [int]$AppStacksAttached,
	
        [ValidateNotNull()] 
        [int]$NumLogins,
	
        [ValidateNotNull()] 
        [string]$AgentVersion,
	
        [ValidateNotNull()] 
        [VMware.AppVolumes.ComputerType]$ComputerType,
	
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
        [Vmware.Appvolumes.Entity []]$OnlineEntities = $null
        $ComputersUri = "$($Global:GlobalSession.Uri)cv_api/computers"
        $UsersUri = "$($Global:GlobalSession.Uri)cv_api/users"
        $OrgUnitsUri = "$($Global:GlobalSession.Uri)cv_api/org_units"
        $GroupsUri = "$($Global:GlobalSession.Uri)cv_api/groups"
        [regex]$GroupParser= '(?:<.*/directory#/Groups/)(?<id>\d*)(?:.*title=")(?<displayname>.*)(?:".*>)(?<upn>.*)(?:<.*>)'
        [regex]$computerParser= '(?:<.*/directory#/Computers/)(?<id>\d*)(?:.*>)(?<upn>.*)(?:<.*>)'
        [regex]$userParser= '(?:<.*/directory#/Users/)(?<id>\d*)(?:.*title=")(?<displayname>.*)(?:".*>)(?<upn>.*)(?:<.*>)'
        [regex]$OrgUnitParser= '(?:<.*/directory#/Org_units/)(?<id>\d*)(?:.*title=")(?<displayname>.*)(?:".*>)(?<upn>.*)(?:<.*>)'
        [regex]$OnlineEntitiesParser = '(?:<a\shref=\"/[a-z]*#/)(?<EntityType>[A-z]*)(?:/)(?<Id>[0-9]*)(?:\"\stitle=\")(?<DisplayName>.*)(?:\">)(?<Domain>.*)(?:[\\]|[\s])(?<SamAccountName>.*)(?:</a>)'
    
        $ProvisionersUri = "$($Global:GlobalSession.Uri)cv_api/provisioners"
        $AllProvisioners = Internal-RestGet -Uri $ProvisionersUri -Object 'provisioners' 
        $OnlineEntitiesUri = "$($Global:GlobalSession.Uri)cv_api/online_entities"
        $AllOnlineEntities = Internal-RestGet -Uri $OnlineEntitiesUri -Object 'online.records' 
        
        foreach ($UnparsedEntity in $AllOnlineEntities)
        {
            
            $LocalEntity= New-Object -TypeName Vmware.Appvolumes.Entity
            $LocalEntity.Id = [regex]::Matches($UnparsedEntity.entity_name,$OnlineEntitiesParser)[0].Groups['Id'].Value
            $LocalEntity.EntityType=$UnparsedEntity.entity_type
            $LocalEntity.AgentStatus = $UnparsedEntity.agent_status -replace '-', ''
            if ([regex]::IsMatch($UnparsedEntity.details,$OnlineEntitiesParser))
            {
                $LastComputerId = [regex]::Matches($UnparsedEntity.details,$OnlineEntitiesParser)[0].Groups['Id'].value
                if ($LastComputerId)
                {
                    $lastcomputer = New-Object -TypeName VMware.AppVolumes.Entity
                    $lastcomputer.Id =$LastComputerId
                    $LocalEntity.LastComputer = $lastcomputer
                }
            }
            if ($UnparsedEntity.details.startswith('IP:')) {$LocalEntity.IPAddress = $(($UnparsedEntity.details) -replace 'IP: ', '')}
            if ($UnparsedEntity.connection_time) {$LocalEntity.ConnectionTime = $UnparsedEntity.connection_time }
            $OnlineEntities += $LocalEntity
            
            
        }
        
    }
    process
    {
        if (($PsCmdlet.ParameterSetName -eq 'None'))
        {
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'Computer'))
            {
                $AllComputers = Internal-RestGet -Uri $ComputersUri
                foreach ($LocalInstance in $AllComputers)
                {
                    $LocalEntity= New-Object -TypeName Vmware.Appvolumes.Entity
                    PopulateEntity $computerParser  'upn' 'Computer'
                    if((($id) -and ($LocalEntity.Id -eq $id)) -or (!$id))
                    {
                        $provisioner = $AllProvisioners|Where-Object {$_.id -eq $LocalEntity.Id}
                        if ($provisioner)
                        {
                            $LocalEntity.ProvisioningStatus = $provisioner.status -replace '\s', ''
                            if ($provisioner.uuid) {$LocalEntity.uuid = $provisioner.uuid}
                        }
                        $onliner=$OnlineEntities|Where-Object {($_.id -eq $LocalEntity.Id) -and ($_.$EntityType -eq $LocalEntity.EntityType) }
                        if($onliner)
                        {
                            $LocalEntity.AgentStatus = $onliner.AgentStatus
                            $LocalEntity.IPAddress = $onliner.IPAddress
                            $LocalEntity.ConnectionTime = $onliner.ConnectionTime
                            
                        }
                        $Entities += $LocalEntity
                    }
                } 
            }
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'User'))
            {
                $AllUsers = Internal-RestGet -Uri $UsersUri
                foreach ($LocalInstance in $AllUsers)
                {
                    $LocalEntity= New-Object -TypeName Vmware.Appvolumes.Entity
                    PopulateEntity $UserParser  'upn_link' 'User'
                    if((($id) -and ($LocalEntity.Id -eq $id)) -or (!$id))
                    {
                          $onliner=$OnlineEntities|Where-Object {($_.id -eq $LocalEntity.Id) -and ($_.EntityType -eq $LocalEntity.EntityType) }
                        if($onliner)
                        {
                            $LocalEntity.AgentStatus = $onliner.AgentStatus
                            if ($onliner.LastComputer)
                            {
                                $LocalEntity.LastComputer = Get-AppVolEntity -Id $onliner.LastComputer.Id -EntityType:Computer
                            }
                            $LocalEntity.ConnectionTime = $onliner.ConnectionTime
                            
                        }
                        $Entities += $LocalEntity
                    }
                } 
            }
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'OrgUnit'))
            {
                $AllOrgUnits = Internal-RestGet -Uri $OrgUnitsUri -Object 'org_units'
                foreach ($LocalInstance in $AllOrgUnits)
                {
                    $LocalEntity= New-Object -TypeName Vmware.Appvolumes.Entity
                    PopulateEntity $OrgUnitParser  'upn' 'OrgUnit'
                    if((($id) -and ($LocalEntity.Id -eq $id)) -or (!$id))
                    {
                        $Entities += $LocalEntity
                    }
                } 
            }
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'Group'))
            {
                $AllGroups = Internal-RestGet -Uri $GroupsUri -Object 'groups'
                foreach ($LocalInstance in $AllGroups)
                {
                    $LocalEntity= New-Object -TypeName Vmware.Appvolumes.Entity
                    PopulateEntity $GroupParser  'upn' 'Group'
                    if((($id) -and ($LocalEntity.Id -eq $id)) -or (!$id))
                    {
                        $Entities += $LocalEntity
                    }
                } 
            }

        }
    }
    end
    {
        return Internal-ReturnFiltered $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
    }
}


Function New-AppVolEntity
{
	
    [OutputType([Vmware.Appvolumes.Entity []])]
	
    param(
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $TRUE)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
	
	
    )
	
    Test-AppVolSession
	
    $ApiUri = "$($Global:GlobalSession.Uri)computer-startup?osver=6.1.7601&sp=1.0&suite=256&product=1&arch=9&proc=1&agentver=AVMAINTENANCE"
	
    $tmp=Invoke-Command  -ComputerName $ComputerName -ScriptBlock {param($ApiUri) Invoke-WebRequest -Uri "$ApiUri"  -Credential $(new-object -typename System.Management.Automation.PSCredential ("AVMAINTENANCE\AVMAINTENANCE$",$(ConvertTo-SecureString 'NONE' -AsPlainText -Force)))} -ArgumentList $ApiUri
    if ($tmp.StatusCode -eq 200){
        $computerSamAccountName = $tmp.Content.Split("`n")[0].split('\')[1]
        $computerSamAccountName = $computerSamAccountName.Substring(0,$computerSamAccountName.Length -1)
        $computerDomainName = $tmp.Content.Split("`n")[0].split('\')[0].split(' ')[1]
		
        $MaintenanceComputer=Get-AppVolEntity -EntityType:Computer |Where-Object {($_.SamAccountName -eq $computerSamAccountName) -and ($_.Domain -eq $computerDomainName)}
		
    }
    return $MaintenanceComputer
	
	
	
	
}



Function PopulateEntity
{
    param ($parser, $upnattribute,$LocalEntityType)
    switch ($LocalEntityType)
    {
        'OrgUnit'
        {
            [string[]]$SplitChar=' OU:'

        }
        default
        {
            [string[]]$SplitChar = '\'
        }
    }
    $ParsedUpn=[regex]::Matches($LocalInstance.$upnattribute,$parser)[0]
    $LocalEntity.Id = $ParsedUpn.groups['id'].value
    $LocalEntity.SamAccountName=$ParsedUpn.groups['upn'].value.split($SplitChar,[System.StringSplitOptions]::None)[1]
    $LocalEntity.Domain=$ParsedUpn.groups['upn'].value.split($SplitChar,[System.StringSplitOptions]::None)[0]
    $LocalEntity.DisplayName= if ($ParsedUpn.groups['displayname'].value){$ParsedUpn.groups['displayname'].value} else{$ParsedUpn.groups['upn'].value}
    $LocalEntity.AppStacksAssigned=$LocalInstance.appstacks
    if ($LocalInstance.last_login) 
    {
        $LocalEntity.LastLogin = $($LocalInstance.last_login -replace ' UTC','Z')
    }
    $LocalEntity.EntityType= $LocalEntityType
    $LocalEntity.Enabled=$LocalInstance.enabled
    $LocalEntity.WritablesAssigned=$LocalInstance.writables
    $LocalEntity.AppStacksAttached=$LocalInstance.attachments
    $LocalEntity.NumLogins=$LocalInstance.logins
    $LocalEntity.AgentVersion=$LocalInstance.agent_version
    if ($LocalInstance.os) {$LocalEntity.ComputerType=$LocalInstance.os}
}

