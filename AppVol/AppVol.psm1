
#region Internal Functions
	
#.ExternalHelp AppVol.psm1-help.xml

	
Function Internal-ReturnFiltered 
{
    param (
        $ParamKeys, 
        $Entities
		
    )

        
    [regex] $RegexParams = '(?i)^(All|Exact|Not|Id|EntityType|MachineManagerId|VolumeId|VolumeType|Volume|ErrorAction|WarningAction|Verbose|Debug|ErrorVariable|WarningVariable|OutVariable|OutBuffer|PipelineVariable)$'
    $FilteredParamKeys = $ParamKeys -notmatch $RegexParams
		

    if ($FilteredParamKeys.count -gt 0) 
    {
        $EntitiesFiltered=@()
        foreach ($Entity in $Entities)
        {
        
            foreach ($CurrentParameter in $($FilteredParamKeys))
		
            {
                $EntityList = @()
                switch ($PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter].GetType().Name)
                {
                    {($_ -match 'String') -or ($_ -eq 'IPAddress')}
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
                            if ($Entity.$CurrentParameter -like '*' + $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] + '*' -and (-not $Not))
                            {
                                $EntityList += $Entity
                            }
                            elseif ($Entity.$CurrentParameter -notlike '*' + $PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter] + '*' -and ($Not))
                            {
                                $EntityList += $Entity
                            }
                        }
                    }
                    {
                        ($_ -match 'AssignmentStatus') -or 
                        ($_ -eq 'ProvisioningStatus')-or 
                        ($_ -eq 'DatastoreCategory') -or
                        ($_ -eq 'Guid') -or 
                        ($_ -eq 'VolumeStatus') -or  
                        ($_ -eq 'ComputerType')-or  
                        ($_ -eq 'AgentStatus')
                    }
                   
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
                    
                    {($_ -match 'Int') -or ($_ -eq 'DateTime')}
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
                   
                    {(($_ -eq 'SwitchParameter') -and (-not (@('gt','ge','lt','le', 'Exact', 'Like', 'Not') -contains $CurrentParameter )))}
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
            if ($EntityList.Count -ge 1){
                $EntitiesFiltered += $EntityList
            }
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
        {$cmd ={Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.WebRequestSession -Headers $Session.Headers -Body $Body -ContentType 'application/json'}}
        Post
        {$cmd ={Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.WebRequestSession -Headers $Session.Headers -Body $Body -ContentType 'application/json' }}
			
        default
        {$cmd ={Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.WebRequestSession -Headers $Session.Headers -ContentType 'application/json'}}
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
            
        $Result= if ($Object) 
        {
            $ObjectArray=$Object.Split('.')
            $cmd=  "`$RestResult.WebRequestResult"
            foreach ($SubObject in $ObjectArray)
            {
                $cmd= $cmd +'.'+ $SubObject
            }
            $cmdscript=[scriptblock]::Create($cmd)
            Invoke-Command $cmdscript
        } 
        else 
        {
            $RestResult.WebRequestResult
        }
        return $Result
    }
    else
    {
        Write-Warning -Message $RestResult.message 
    }

}
	
Function Internal-RestPost
{
    param(
        [Parameter(Position = 1,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({([System.URI]$_).IsAbsoluteUri})]
        [string]$Uri,
        
        [Parameter(Position = 2,Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
		
        [string]$Object,

        [Parameter(Position = 3,Mandatory = $false)]
		
		
        [string]$Body
    )
    if ($Body) {$RestResult=Internal-Rest -Uri $Uri -Method Post -Session $Global:GlobalSession -Body $Body} else {$RestResult=Internal-Rest -Uri $Uri -Method Post -Session $Global:GlobalSession }
    if ($RestResult.Success)
    {
            
        $Result= if ($Object) 
        {
            $ObjectArray=$Object.Split('.')
            $cmd=  "`$RestResult.WebRequestResult"
            foreach ($SubObject in $ObjectArray)
            {
                $cmd= $cmd +'.'+ $SubObject
            }
            $cmdscript=[scriptblock]::Create($cmd)
            Invoke-Command $cmdscript
        } 
        else 
        {
            $RestResult.WebRequestResult
        }
        return $Result
    }
    else
    {
        Write-Warning -Message $RestResult.message 
    }

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

    return $Assignment
		
}
	
	
	
#endregion


. $psScriptRoot\Modules\Session.ps1
. $psScriptRoot\Modules\Volume.ps1
. $psScriptRoot\Modules\Template.ps1
. $psScriptRoot\Modules\Version.ps1
. $psScriptRoot\Modules\Entity.ps1






#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolDataStoreConfig
{
	
	
    begin
    {
        Test-AppVolSession
        $Entity = New-Object -TypeName  VMware.AppVolumes.DataStoreConfig
        $allDataStores=Get-AppVolDataStore
        $AllMachineManagers=Get-AppVolMachineManager
         
        $ApiUri = "$($Global:GlobalSession.Uri)cv_api/datastores"
        $instance=Internal-RestGet -Uri $ApiUri
        $Entity.AppStackMachineManager=$AllMachineManagers |Where-Object {($_.MachineManagerId -eq [int]$($instance.appstack_storage).Split('|')[2])}
        $Entity.AppStackDefaultPath=$instance.appstack_path
        $Entity.AppStackDefaultStorage=  $allDataStores|Where-Object {($_.Name -eq [string]$($instance.appstack_storage).Split('|')[0]) -and ($_.DatacenterName -eq [string]$($instance.appstack_storage).Split('|')[1] )-and ($_.MachineManager.MachineManagerId -eq [int]$($instance.appstack_storage).Split('|')[2])}
        $Entity.AppStackTemplatePath=$instance.appstack_template_path
        $Entity.DatacenterName=$instance.datacenter
        $Entity.WritableMachineManager=$AllMachineManagers |Where-Object {($_.MachineManagerId -eq [int]$($instance.writable_storage).Split('|')[2])}
        $Entity.WritableDefaultPath=$instance.writable_path
        $Entity.WritableDefaultStorage=$allDataStores |Where-Object {($_.Name -eq [string]$($instance.writable_storage).Split('|')[0]) -and ($_.DatacenterName -eq [string]$($instance.writable_storage).Split('|')[1] )-and ($_.MachineManager.MachineManagerId -eq [int]$($instance.writable_storage).Split('|')[2])}
        $Entity.WritableTemplatePath=$instance.writable_template_path

		
    }
	
    end
    {
		
        return $Entity
    }
	
	
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolDataStore
{
	
    [CmdletBinding(DefaultParameterSetName = 'AllEntities')]
    param(
        [Parameter(ParameterSetName = 'AllEntities',Position = 0,ValueFromPipeline = $false,Mandatory = $false)]
        [switch]$All,
        [Parameter(ParameterSetName = 'SelectedEntity',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = 'Enter one or more AppStack IDs separated by commas.')]
	
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
        $allMachineManagers=Get-AppVolMachineManager 
		
        $ApiUri = "$($Global:GlobalSession.Uri)cv_api/datastores"
        switch ($PsCmdlet.ParameterSetName)
        {
            'AllEntities'
            {
                $Datastores= Internal-RestGet -Uri $ApiUri -Object 'datastores'
                foreach ($Entity in $($Datastores))
                {
                    $LocalEntity = New-Object -TypeName Vmware.Appvolumes.DataStore
		
                    if ($Entity.accessible) {$LocalEntity.Accessible = $Entity.accessible}
                    if ($Entity.category) {$LocalEntity.DatastoreCategory = $Entity.category}
                    if ($Entity.uniq_string) 
                    {
                        $managerId= [int]$($Entity.uniq_string).Split('|')[2]

                        $LocalEntity.MachineManager = $allMachineManagers|Where-Object {$_.MachineManagerId -eq $managerId}
                    }
                    if ($Entity.datacenter) {$LocalEntity.DatacenterName = $Entity.datacenter}
                    if ($Entity.description) {$LocalEntity.Description = $Entity.description}
                    if ($Entity.display_name) {$LocalEntity.DisplayName = $Entity.display_name}
                    if ($Entity.host) {$LocalEntity.HostName = $Entity.host}
                    if ($Entity.id) {$LocalEntity.DatastoreId = $Entity.id}
                    if ($Entity.identifier) {$LocalEntity.TextIdentifier = $Entity.identifier}
                    if ($Entity.name) {$LocalEntity.Name = $Entity.name}
                    if ($Entity.note) {$LocalEntity.Note = $Entity.note}

                    $Entities +=  $LocalEntity 
                }
            }
        }
    }
    process
    {
        switch ($PsCmdlet.ParameterSetName)
        {
            'SelectedEntity'
            {
                $Datastores= Internal-RestGet -Uri $ApiUri  -Object 'datastores'
                foreach ($Entity in $($Datastores))
                {
				
                    if ($Entity.id -eq $DatastoreId)
                    {
                        $LocalEntity = New-Object -TypeName Vmware.Appvolumes.DataStore
		
                        if ($Entity.accessible) {$LocalEntity.Accessible = $Entity.accessible}
                        if ($Entity.category) {$LocalEntity.DatastoreCategory = $Entity.category}
                        if ($Entity.uniq_string) 
                        {
                            $managerId= [int]$($Entity.uniq_string).Split('|')[2]

                            $LocalEntity.MachineManager = $allMachineManagers|Where-Object {$_.MachineManagerId -eq $managerId}
                        }if ($Entity.datacenter) {$LocalEntity.DatacenterName = $Entity.datacenter}
                        if ($Entity.description) {$LocalEntity.Description = $Entity.description}
                        if ($Entity.display_name) {$LocalEntity.DisplayName = $Entity.display_name}
                        if ($Entity.host) {$LocalEntity.HostName = $Entity.host}
                        if ($Entity.id) {$LocalEntity.DatastoreId = $Entity.id}
                        if ($Entity.identifier) {$LocalEntity.TextIdentifier = $Entity.identifier}
                        if ($Entity.name) {$LocalEntity.Name = $Entity.name}
                        if ($Entity.note) {$LocalEntity.Note = $Entity.note}

                        $Entities +=  $LocalEntity 
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



#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolMachineManager
{
    [CmdletBinding(DefaultParameterSetName='None')]
    param(
        [Parameter(ParameterSetName = 'SelectedMachineManagerId',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
        [Alias('id')]
        [ValidateNotNull()]
        [int[]]$MachineManagerId,
	
        [Parameter(ParameterSetName = 'SelectedName',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
        [ValidateNotNull()]
        [string[]]$Name,

        [switch]$Exact,
        [switch]$Like,
	
        [switch]$Not
	
    )
    begin
    {
        Test-AppVolSession
        [VMware.AppVolumes.MachineManager[]]$Entities = $null
		
        $ApiUri = "$($Global:GlobalSession.Uri)cv_api/machine_managers"
    }
    process
    {
        if (($PsCmdlet.ParameterSetName -eq 'None') -and (!$MachineManagerId) )
        {
            $AllMachineManagers = Internal-RestGet -Uri $ApiUri -Object 'machine_managers'
            foreach ($MachineManagerIdInstance in $AllMachineManagers.id)
            {
                $MachineManagerUri = "$ApiUri/$MachineManagerIdInstance"
                $MachineManagerInstance= Internal-RestGet -Uri $MachineManagerUri -Object 'machine_manager'
                if ($MachineManagerInstance.id)
                {
                    $LocalEntity= New-Object -TypeName VMware.AppVolumes.MachineManager
                    $LocalEntity.AdapterType=$MachineManagerInstance.adapter_type
                    $LocalEntity.Connected=$MachineManagerInstance.is_connected
                    $LocalEntity.Description=$MachineManagerInstance.description
                    $LocalEntity.MachineManagerId = $MachineManagerInstance.id
                    $LocalEntity.MountOnHost=$MachineManagerInstance.mount_on_host
                    $LocalEntity.Name=$MachineManagerInstance.host
                    $LocalEntity.Type=$MachineManagerInstance.type
                    $LocalEntity.UseLocalVolumes=$MachineManagerInstance.use_local_volumes
                    $LocalEntity.ManageAcl=$MachineManagerInstance.manage_sec
                    $LocalEntity.UserName=$MachineManagerInstance.username
                    $LocalEntity.HostUserName=$MachineManagerInstance.host_username
                    $Entities += $LocalEntity
                }

               
               
            }
        }
        if  ($MachineManagerId)
        {
            $MachineManagerUri = "$ApiUri/$MachineManagerIdInstance"
            $MachineManagerInstance= Internal-RestGet -Uri $MachineManagerUri -Object 'machine_manager'
            if ($MachineManagerInstance.id)
            {
                $LocalEntity= New-Object -TypeName VMware.AppVolumes.MachineManager
                $LocalEntity.AdapterType=$MachineManagerInstance.adapter_type
                $LocalEntity.Connected=$MachineManagerInstance.is_connected
                $LocalEntity.Description=$MachineManagerInstance.description
                $LocalEntity.MachineManagerId = $MachineManagerInstance.id
                $LocalEntity.MountOnHost=$MachineManagerInstance.mount_on_host
                $LocalEntity.Name=$MachineManagerInstance.host
                $LocalEntity.Type=$MachineManagerInstance.type
                $LocalEntity.UseLocalVolumes=$MachineManagerInstance.use_local_volumes
                $LocalEntity.ManageAcl=$MachineManagerInstance.manage_sec
                $LocalEntity.UserName=$MachineManagerInstance.username
                $LocalEntity.HostUserName=$MachineManagerInstance.host_username
                $Entities += $LocalEntity
            }           
            
        }
        
    }
    end
    {
		
        return Internal-ReturnFiltered $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
    }
	
	
}


#.ExternalHelp AppVol.psm1-help.xml


#.ExternalHelp AppVol.psm1-help.xml
Function Start-AppVolProvisioning
{
    [CmdletBinding(DefaultParameterSetName = 'AppStackAndComputer')]
    param(
        [Parameter(ParameterSetName = 'AppStackAndComputer',Mandatory = $true,Position = 0,ValueFromPipeline = $TRUE)]
        [Parameter(ParameterSetName = 'AppStackAndComputerId',Mandatory = $true,Position = 0,ValueFromPipeline = $TRUE)]
        [ValidateNotNull()]
        [VMware.AppVolumes.Volume]$AppStack,
	
        [Parameter(ParameterSetName = 'AppStackAndComputer',Mandatory = $true,Position = 1)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputer',Mandatory = $true,Position = 1)]
        [ValidateScript({$_.EntityType -eq 'Computer'})]
        [VMware.AppVolumes.Entity]$Computer,
	
        [Parameter(ParameterSetName = 'AppStackIdAndComputer',Mandatory = $true,Position = 1)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputerId',Mandatory = $true,Position = 1)]
	
        [int]$AppStackId,
        [ValidateNotNull()]
        [Parameter(ParameterSetName = 'AppStackAndComputerId',Mandatory = $true,Position = 2)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputerId',Mandatory = $true,Position = 2)]
        [ValidateNotNull()]
        [int]$ComputerId
    )
	
	
    Test-AppVolSession
	
    switch ($PsCmdlet.ParameterSetName)
    {
        'AppStackAndComputer'
        {
			
        }
        'AppStackAndComputerId'
        {
            $Computer = Get-AppVolEntity -Id $ComputerId -EntityType:Computer
        }
        'AppStackIdAndComputer'
        {
            $AppStack = Get-AppVolVolume -VolumeID $AppStackId -VolumeType:AppStack
        }
        'AppStackIdAndComputerId'
        {
            $Computer = Get-AppVolEntity -Id $ComputerId -EntityType:Computer
            $AppStack = Get-AppVolVolume -VolumeID $AppStackId -VolumeType:AppStack
        }  
    }
    $machineguid=$(Get-AppVolProvisioner|Where-Object {$_.Id -eq $Computer.Id}).uuid
    $ApiUri = "$($Global:GlobalSession.Uri)cv_api/provisions/$($AppStack.VolumeId)/start"
    $postParams = @{
        computer_id=$Computer.Id;
        uuid=$machineguid
    }|ConvertTo-Json
   
    return Internal-RestPost -Uri $ApiUri -Body $postParams
        
    
}

#.ExternalHelp AppVol.psm1-help.xml
Function Stop-AppVolProvisioning
{
    [CmdletBinding(DefaultParameterSetName = 'none')]
    param(
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
	
        [VMware.AppVolumes.Volume[]]$Volume,
	
	
        [Parameter(ParameterSetName = 'AppStackId',Mandatory = $true,Position = 1)]
	
        [int[]]$VolumeId
	
    )
	
    begin
    {
        Test-AppVolSession
	
	   
    }
    process
    {
        if ($Volume -or $VolumeId)
        {
            $localVolumeId= if ($VolumeId) {$VolumeId} else {$Volume.VolumeId}
            $ApiUri = "$($Global:GlobalSession.Uri)cv_api/provisions/$localVolumeId/stop"
	
            return Internal-RestPost -Uri $ApiUri 
        }
    }    
    
}


Function TODOGetAppVolAppStackProvisioning
{
    [CmdletBinding(DefaultParameterSetName = 'AppStackAndComputer')]
    param(
        [Parameter(ParameterSetName = 'AppStackAndComputer',Mandatory = $false,Position = 0)]
        [Parameter(ParameterSetName = 'AppStackAndComputerId',Mandatory = $false,Position = 0)]
        [ValidateNotNull()]
        [VMware.AppVolumes.AppVolumesAppStack]$AppStack,
	
        [Parameter(ParameterSetName = 'AppStackAndComputer',Mandatory = $false,Position = 1)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputer',Mandatory = $false,Position = 1)]
        [ValidateScript({$_.EntityType -eq 'Computer'})]
        [VMware.AppVolumes.Entity]$Computer,
	
        [Parameter(ParameterSetName = 'AppStackIdAndComputer',Mandatory = $false,Position = 1)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputerId',Mandatory = $false,Position = 1)]
	
        [int]$AppStackId,
        [ValidateNotNull()]
        [Parameter(ParameterSetName = 'AppStackAndComputerId',Mandatory = $false,Position = 2)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputerId',Mandatory = $false,Position = 2)]
        [ValidateNotNull()]
        [int]$ComputerId
    )
	
	
    Test-AppVolSession
	
    switch ($PsCmdlet.ParameterSetName)
    {
        'AppStackAndComputer'
        {
			
        }
        'AppStackAndComputerId'
        {
            $Computer = Get-AppVolComputer -Id $ComputerId
        }
        'AppStackIdAndComputer'
        {
            $AppStack = Get-AppVolVolume -VolumeID $AppStackId
        }
        'AppStackIdAndComputerId'
        {
            $Computer = Get-AppVolComputer -Id $ComputerId
            $AppStack = Get-AppVolVolume -VolumeID $AppStackId
        }  
    }
    
    $InuseProvisioners =Get-AppVolProvisioner | Where-Object {$_.ProvisioningStatus -eq 'InUse'} 


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
Function TODOGetAppVolAssignment
{
	
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(

        [Parameter(ParameterSetName = 'SelectedVolumeId',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
        [Alias('id')]
        [ValidateNotNull()]
        [int[]]$VolumeID,
	
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
        [ValidateNotNull()]
        [VMware.AppVolumes.Volume[]]$Volume,
	
	
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
        $ApiUri = "$($Global:GlobalSession.Uri)cv_api/assignments"
        [Vmware.Appvolumes.Assignment []]$Entities = $null
        $AllAppStacks

    }
    process
    {
        if (($PsCmdlet.ParameterSetName -eq 'None') -and (!$VolumeID) -and (!$Volume))
        {
            $AllAssignments = Internal-RestGet -Uri $ApiUri -Object 'assignments'
            foreach ($AssignmentInstance in $AllAssignments)
            {
                $Entities += Internal-PopulateAssignment $Entity
                
            }
        }
        if  (($VolumeID) -or ($Volume))
        {           
            $LocalVolumeId = if ($VolumeID) {$VolumeID} else {$Volume.VolumeId}
            $AllAssignments = Internal-RestGet -Uri $ApiUri -Object 'assignments'
            foreach ($AssignmentInstance in $AllAssignments)
            {
                $LocalAssignment = Internal-PopulateAssignment $Entity
                if ($LocalAssignment.VolumeId -eq $VolumeId)
                {
                    $Entities += $LocalAssignment
                }
            }
            
        }
    }
    end
    {
        return Internal-ReturnFiltered $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
    }
	
	
	
}

#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolFile
{
	
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(ParameterSetName = 'SelectedVolumeId',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
        [Alias('id')]
        [ValidateNotNull()]
        [int[]]$VolumeID,
	
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
        [ValidateNotNull()]
        [VMware.AppVolumes.Volume[]]$Volume,

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
        $AllDataStores=Get-AppVolDataStore
        $AllVolumes=Get-AppVolVolume
        $AllMachineManagers=Get-AppVolMachineManager
        		
    }
	
    process
    {
        if (($PsCmdlet.ParameterSetName -eq 'None') -and (!$VolumeID) -and (!$Volume))
        {
            $Entities = Get-AppVolVolume | Get-AppVolFile
        }
        if  (($VolumeID) -or ($Volume))
        {           
            $LocalVolumeId = if ($VolumeID) {$VolumeID} else {$Volume.VolumeId}
            $VolumeUri = "$($Global:GlobalSession.Uri)cv_api/appstacks/$LocalVolumeId/files"
            $FileInstances= Internal-RestGet -Uri $VolumeUri 
            foreach ($FileInstance in $FileInstances)
            {
                $AppStackFile = New-Object -TypeName Vmware.Appvolumes.VolumeFile
                $AppStackFile.Name = $FileInstance.Name
                if ($FileInstance.created_at) {$AppStackFile.CreatedAt = $FileInstance.created_at}
		
                $AppStackFile.Missing = $FileInstance.Missing
                $AppStackFile.Reachable = $FileInstance.Reachable
                $AppStackFile.path = $FileInstance.path
                $AppStackFile.Volume = $AllVolumes|Where-Object {$_.VolumeId -eq $LocalVolumeId} |Select-Object -First 1 
                $AppStackFile.DataStore = $AllDataStores|Where-Object {$_.Name -eq $FileInstance.storage_location} |Select-Object -First 1
                $AppStackFile.MachineManager= $AllMachineManagers |Where-Object {($_.Type -eq $FileInstance.machine_manager_type) -and ($_.Name -eq $FileInstance.machine_manager_host)}
                $Entities += $AppStackFile
            }
            
        }
	
    }
    end
    {
        return Internal-ReturnFiltered $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
    }
}


#.ExternalHelp AppVol.psm1-help.xml
Function Select-AppVolDataStore
{
    return Get-AppVolDataStore|Out-GridView -OutputMode:Single -Title 'Select DataStore' 
	
}



Function Start-AppVolVolumeMaintenance
{
    param(
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
	
        [Parameter(Mandatory = $true,Position = 1,ValueFromPipeline = $TRUE)]
        [ValidateNotNullOrEmpty()]
        [VMware.AppVolumes.Volume]$Volume
	
    )
    $parentVolume=Get-AppVolVolume -VolumeID $Volume.Parent -VolumeType:AppStack
    if ($parentVolume.PrimordialOs)
    {
        $osver=$AppVolOSDictionary.$($parentVolume.PrimordialOs.Name)
    }
    if ($parentVolume.AgentVersion)
    {
        $agentver=$parentVolume.AgentVersion
    }
    if ($parentVolume.CaptureVersion)
    {
        $agentver=$parentVolume.CaptureVersion
    }


    [ScriptBlock]$ScriptBlock= {
        param($osver,$agentver)
        Register-WmiEvent -Class win32_VolumeChangeEvent -SourceIdentifier volumeChange
        $message = $null


        $newEvent = Wait-Event -SourceIdentifier volumeChange
        $eventType = $newEvent.SourceEventArgs.NewEvent.EventType
 
        if ($eventType -eq 2)
        {
            $driveLetter = $newEvent.SourceEventArgs.NewEvent.DriveName
            $driveLabel = ([wmi]"Win32_LogicalDisk='$driveLetter'").VolumeName
            $partitionobject=Get-WmiObject -Query "Associators of {Win32_LogicalDisk.DeviceID=""$driveLetter""} WHERE AssocClass = Win32_LogicalDiskToPartition"
            $diskIndex=$partitionobject.DiskIndex
            $partitionIndex=$partitionobject.Index
            $rootDirectoryObject=Get-WmiObject -Query "Associators of {Win32_LogicalDisk.DeviceID=""$driveLetter""} WHERE AssocClass = Win32_LogicalDiskRootDirectory"
            $rootDirectory=$rootDirectoryObject.Name
            $rootDirectoryEscaped = $rootDirectory -replace '\\', '\\'
            $shareobject= Get-WmiObject -Query "select * from win32_share where Path='$rootDirectoryEscaped'"
            $share= "\\$($shareobject.PSComputerName)\$($shareobject.name)"
            $templateversion=$(get-content "$($rootDirectory)version.txt").Split('=')[1]
            $properties = @{
                'driveLetter'=$driveLetter;
                'driveLabel'=$driveLabel;
                'diskIndex'=$diskIndex;
                'partitionIndex'=$partitionIndex;
                'rootDirectory'=$rootDirectory;
                'share'=$share;
                'templateversion'=$templateversion;
                'osver'=$osver;
                'agentver'=$agentver
            }
            $object = New-Object –TypeName PSObject –Prop $properties
        }
        Remove-Event -SourceIdentifier volumeChange
    
   
        Unregister-Event -SourceIdentifier volumeChange
        return $object
    }
    $computer=$(Get-AppVolProvisioner -Filter $ComputerName) |Where-Object {$_.SamAccountname -eq "$($computername)$"}|Select-Object -First 1
    $volumejob=Invoke-Command -ComputerName $ComputerName  -ScriptBlock $ScriptBlock -ArgumentList $osver, $agentver -AsJob

    Start-AppVolProvisioning -AppStack $Volume -Computer $Computer|Out-Null
    $result = Receive-Job -Job $volumejob -Wait
    #$result.version=
    return $result
	

}

Function Get-AppVolMaintenanceFiles
{
    [OutputType([System.IO.FileInfo[]])]
    param(
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FolderName
    )
    $files= SelectFileDialog -Title 'Select Files' -Directory $FolderName -MultiSelect:$true
    $TempDirName = [System.Guid]::NewGuid().ToString()
    $tempDir = New-Item -Type Directory -Name $TempDirName -Path  $env:temp -Force
    [System.IO.FileInfo[]]$filearray = $null
    foreach ($file in $files) 
    {
        $filearray += Copy-Item -Path $file -Destination $tempDir -Force -PassThru
 
    }
    return $filearray
}
function SelectFileDialog

{

    param([string]$Title,[string]$Directory,[string]$Filter='All Files (*.*)|*.*', [bool]$MultiSelect=$true)

    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null

    $objForm = New-Object System.Windows.Forms.OpenFileDialog

    $objForm.ShowHelp = $true

    $objForm.InitialDirectory = $Directory

    $objForm.Filter = $Filter

    $objForm.Title = $Title
    $objForm.Multiselect= $MultiSelect
    Add-Type -TypeDefinition @"
using System;
using System.Windows.Forms;
 
public class Win32Window : IWin32Window
{
   private IntPtr _hWnd;
   
   public Win32Window(IntPtr handle)
   {
       _hWnd = handle;
   }
 
   public IntPtr Handle
   {
       get { return _hWnd; }
   }
}
"@ -ReferencedAssemblies 'System.Windows.Forms.dll'

    $owner = New-Object Win32Window -ArgumentList ([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle)

    $Show = $objForm.ShowDialog($owner)

    If ($Show -eq 'OK')

    {

        Return $objForm.FileNames

    }

    Else

    {

        Write-Error 'Operation cancelled by user.'

    }

}



Function Get-AppVolMaintenanceMetaData
{
    param(
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $TRUE)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    $files=Get-ChildItem -Path "$($Path)\METADATA"
    $TempDirName = [System.Guid]::NewGuid().ToString()
    $tempDir = New-Item -Type Directory -Name $TempDirName -Path  $env:temp -Force
    $metadatadir= New-Item -Type Directory -Name 'METADATA' -Path $tempDir -Force
    [System.IO.FileInfo[]]$filearray = $null
    foreach ($file in $files) 
    {
        $filearray += Copy-Item -LiteralPath $file.PSPath -Destination $metadatadir -Force -PassThru
 
    }
    Add-Type -assembly 'system.io.compression.filesystem'
    [io.compression.zipfile]::CreateFromDirectory($metadatadir, "$($tempDir)\META.zip",'Optimal',$true) 
    return Get-Item "$($tempDir)\META.zip"
    
}

Function Complete-AppVolVolumeMaintenance
{
    param(
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $TRUE)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$volume
    )
    Test-AppVolSession
	
    $ApiUri = "$($Global:GlobalSession.Uri)update-volume-files?osver=$($volume.osver)&sp=1.0&suite=256&product=$($volume.osver.Split('.')[3])&arch=$($volume.osver.Split('.')[2])&proc=1&agentver=$($volume.agentver)"
	
    #	$tmp=Invoke-Command  -ComputerName $volume.PSComputerName -ScriptBlock {param($ApiUri) Invoke-RestMethod -Uri "$ApiUri"  -Credential $(new-object -typename System.Management.Automation.PSCredential ("AVMAINTENANCE\AVMAINTENANCE$",$(ConvertTo-SecureString "NONE" -AsPlainText -Force)))} -ArgumentList $ApiUri
    #	if ($tmp.StatusCode -eq 200){
    $volumeGuid=[System.Web.HttpUtility]::UrlEncode("{$([Guid]::NewGuid())}")
    $ApiUri = "$($Global:GlobalSession.Uri)provisioning-complete?osver=$($volume.osver)&sp=1.0&suite=256&product=$($volume.osver.Split('.')[3])&arch=$($volume.osver.Split('.')[2])&proc=1&agentver=$($volume.agentver)&volguid=$volumeGuid&meta_file=META.ZIP&capturever=$($volume.templateversion)"
    $metazip=Get-AppVolMaintenanceMetaData -Path $volume.share
    $fileBin = [IO.File]::ReadAllBytes($metazip)
    #$filestring=[System.Text.Encoding]::UTF8.GetString($fileBin)
    #$filebin=[System.Text.Encoding]::UTF8.GetBytes($filestring)
    #$enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
    #$fileEnc = $enc.GetString($fileBin)
    $boundary = '==CF8F81018C504EBEAC6FB2B3CF53660A=='
    $LF = "`r`n"
    $bodyLinesstart = "--$boundary$($LF)Content-Disposition: form-data; name=`"meta`"; filename=`"META.ZIP`"$($LF)Content-Type: application/x-zip-compressed$LF$LF"
        
    $bodyLinesend = "$LF--$boundary--$LF"
        
    [ScriptBlock]$ScriptBlock={
        param($ApiUri,$boundary,$bodyLinesstart,$bodyLinesend,$fileBin)
        [System.Net.HttpWebRequest]$request = [System.Net.HttpWebRequest]::CreateHttp($ApiUri)
        $request.ContentType="multipart/form-data; boundary=$boundary"
        $request.Method='POST'
        $request.Credentials=$(new-object -typename System.Management.Automation.PSCredential ("AVMAINTENANCE\AVMAINTENANCE$",$(ConvertTo-SecureString 'NONE' -AsPlainText -Force)))
        $request.ServicePoint.Expect100Continue=$false
        #$request.ServicePoint.
        $bufferstart = [text.encoding]::UTF8.getbytes($bodyLinesstart)
        $bufferend = [text.encoding]::ASCII.getbytes($bodyLinesend)
        
        $reqst = $request.getRequestStream()
        $reqst.write($bufferstart, 0, $bufferstart.length)
        $reqst.write($fileBin, 0, $fileBin.length)
        $reqst.write($bufferend, 0, $bufferend.length)
        $reqst.flush()
        $reqst.close()
        try{
            [net.httpWebResponse] $res = $request.getResponse()
        }
        catch 
        {
            $res = $_.Exception.InnerException.Response
        }
        finally{
            $resst = $res.getResponseStream()
            $sr = new-object IO.StreamReader($resst)
            $result = $sr.ReadToEnd()
            $res.close()
        
        }
        return $result
    }
    $tmp=Invoke-Command  -ComputerName $volume.PSComputerName -ScriptBlock $ScriptBlock -ArgumentList $ApiUri,$boundary, $bodyLinesstart,$bodyLinesend, $fileBin
    $MaintenanceComputer=Get-AppVolEntity -EntityType:Computer -AgentVersion 'AVMAINTENANCE'|Where-Object {$_.SamAccountName -eq $computerSamAccountName}
		
    #	}
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
	
    [CmdletBinding(DefaultParameterSetName = 'OneAppStack')]
    param(
        [Parameter(ParameterSetName = 'OneAppStack',Position = 0,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [pscustomobject]$Session,
	
        [Parameter(ParameterSetName = 'OneAppStack',Position = 1,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [ValidateNotNullOrEmpty()]
        [int[]]$AppStackId,
        [Parameter(ParameterSetName = 'OneAppStack',Position = 2,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Property,
        [Parameter(ParameterSetName = 'OneAppStack',Position = 2,ValueFromPipeline = $TRUE,ValueFromPipelineByPropertyName)]
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
Function TODOAddAppStackAssignment
{
	
    param(
	
        [pscustomobject]$Session,
	
        [int]$AppStack,
        [string]$ADObject
    )
    $uri = "$($session.Uri)/cv_api/assignments"
	
    $headers = New-Object 'System.Collections.Generic.Dictionary[[String],[String]]'
    $headers.Add('X-CSRF-Token',$Session.Token)
    $Search = New-Object DirectoryServices.DirectorySearcher ([adsi]'')
    $Search.filter = “(&(sAMAccountName=$ADObject))”
    $ADWebRequestResults = $Search.Findall()
    $assignments = @{
		
        entity_type = ($ADWebRequestResults[0].Properties['objectclass'])[($ADWebRequestResults[0].Properties['objectclass']).Count - 1]
        path = $($ADWebRequestResults[0].Properties['DistinguishedName'])
		
		
    }
	
    $json = @{
		
        'action_type' = 'Assign'
        'id' = $AppStack
        'assignments' = @{
			
            '0' = $assignments
			
        }
		
        'rtime' = 'false'
        'mount_prefix' = $null
		
		
    }
	
    $body = $json | ConvertTo-Json -Depth 3
	
    $WebRequestResult = Invoke-RestMethod -Uri $uri -Method post -WebSession $Session.Session -Headers $headers -Body $body -ContentType 'application/json'
    [hashtable]$Return = @{
		
    }
	
    $Return.WebRequestResult = ($WebRequestResult | Get-Member -MemberType NoteProperty)[-1].Name
    $Return.message = $WebRequestResult.(($WebRequestResult | Get-Member -MemberType NoteProperty)[-1].Name)
	
    return $Return
	
}


if ($PSVersionTable.PSVersion.Major -lt 3)
{
	
    throw New-Object System.NotSupportedException 'PowerShell V3 or higher required.'
	
}


Export-ModuleMember -Function *AppVol*
$Global:AppVolOSDictionary= @{

    'Windows 8.1 (x86)'='6.3.0.1';
    'Windows 8.1 (x64)'='6.3.9.1';
    'Windows 8 (x86)'='6.2.0.1';
    'Windows 8 (x64)'='6.2.9.1';
    'Windows 7 (x86)'='6.1.0.1';
    'Windows 7 (x64)'='6.1.9.1';
    'Windows Server 2012 R2 (x64)'='6.3.9.3';
    'Windows Server 2012 (x64)'='6.2.9.3';
    'Windows Server 2008 R2 (x64)'='6.1.9.3';
    'Windows Server 2008 (x86)'='6.0.0.3';
    'Windows Server 2008 (x64)'='6.0.9.3'
}






