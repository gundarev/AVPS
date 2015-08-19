#.ExternalHelp AppVol.psm1-help.xml
Function Update-AppVolVolume
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(ParameterSetName = 'SelectedVolumeId',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
        [Alias('id')]
        [ValidateNotNull()]
        [int[]]$VolumeID,
	
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
	
        [VMware.AppVolumes.Volume[]]$Volume,

	
        [ValidateNotNull()]
        [string]$AppStackName,
	
	
        [ValidateNotNull()]
        [string]$AppStackDefaultPath,
	
	
        [ValidateNotNull()]
        [VMware.AppVolumes.DataStore]$TargetDataStore,
	
	
	
        [ValidateNotNull()]
        [string]$AppStackDescription,
	
	
        [ValidateNotNull()]
        [string]$Prefix
	
    )
    begin{
		
        Test-AppVolSession
        [VMware.AppVolumes.Volume[]]$Entities = $null
        [Vmware.Appvolumes.Volume[]]$EntitiesFiltered = $null
        $AppStacksUri = "$($Global:GlobalSession.Uri)cv_api/appstacks"
        
        $AllDataStores=Get-AppVolDataStore
		
        Test-AppVolSession
		
        [VMware.AppVolumes.DataStoreConfig] $config=Get-AppVolDataStoreConfig
		
        if ([string]::IsNullOrEmpty($AppStackDefaultPath)) {$AppStackDefaultPath=$config.AppStackDefaultPath}
        if (!$TargetDataStore) {$TargetDataStore=$config.AppStackDefaultStorage}
        if ([string]::IsNullOrEmpty($AppStackName) -and ([string]::IsNullOrEmpty($Prefix))) {$Prefix=Get-Date -Format u}
    }
    process {

        if  (($VolumeID) -or ($Volume))
        {           
            $LocalVolumeId = if ($VolumeID) {$VolumeID} else {$Volume.VolumeId}
            if ([string]::IsNullOrEmpty($AppStackName)){$LocalAppStackName="($Prefix) $($Volume.Name)"}else{$LocalAppStackName=$AppStackName}
            $postParams = @{
                name=$LocalAppStackName;
                description=$AppStackDescription;
                datacenter=$TargetDataStore.DatacenterName;
                datastore="$($TargetDataStore.Name)|$($TargetDataStore.DatacenterName)|$($TargetDataStore.MachineManager.MachineManagerId)";
                path=$AppStackDefaultPath;
                parent_appstack_id=$LocalVolumeId;
                bg=0
            }|ConvertTo-Json

			
			    
            $VolumeInstance= Internal-RestPost -Uri $AppStacksUri  -Body $postParams
            $LocalEntity= New-Object -TypeName Vmware.Appvolumes.Volume
            if ($VolumeInstance.appstack_id)
            {
                $Entities += Get-AppVolVolume -VolumeID $VolumeInstance.appstack_id -VolumeType:AppStack
            }
            
            
        }
    
		
			
			
			
		
		
    }
	
    end{
        return $Entities
		
    }
	
	
	
	
}

Function Get-AppVolVolume
{
    [CmdletBinding(DefaultParameterSetName='None')]
    [OutputType([VMware.AppVolumes.Volume[]])]
    param(
        [Parameter(ParameterSetName = 'SelectedVolumeId',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
        [Alias('id')]
        [ValidateNotNull()]
        [int[]]$VolumeID,
	
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $TRUE)]
        [ValidateNotNull()]
        [VMware.AppVolumes.Volume[]]$Volume,


        [ValidateNotNull()]
        [string]$Name,
	
        [ValidateNotNull()]
        [VMware.AppVolumes.VolumeType]$VolumeType,
	
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
        $AppStacksUri = "$($Global:GlobalSession.Uri)cv_api/appstacks"
        $WritablesUri = "$($Global:GlobalSession.Uri)cv_api/writables"
        $AllDataStores=Get-AppVolDataStore
		
		
    }
    process
    {
        if (($PsCmdlet.ParameterSetName -eq 'None') -and (!$VolumeID) -and (!$Volume))
        {
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('VolumeType')) -or ($VolumeType -eq 'AppStack'))
            {
                $AllAppStackVolumes = Internal-RestGet -Uri $AppStacksUri 
                foreach ($VolumeIdInstance in $AllAppStackVolumes.id)
                {
                    $VolumeUri = "$AppStacksUri/$VolumeIdInstance"
                    
                    $VolumeInstance= Internal-RestGet -Uri $VolumeUri -Object 'appstack'
                    if ($VolumeInstance.id){
                        $LocalEntity= New-Object -TypeName Vmware.Appvolumes.Volume
                        ZGet-InternalSharedVolumeProperties
                        ZGet-InternalAppStackVolumeProperties
                        $Entities += $LocalEntity
                    }
                
                }
            }
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('VolumeType')) -or ($VolumeType -eq 'Writable'))
            {
                $AllWritableVolumes = Internal-RestGet -Uri $WritablesUri -Object 'datastores.writable_volumes'
                foreach ($VolumeIdInstance in $AllWritableVolumes.id)
                {
                    $VolumeUri = "$WritablesUri/$VolumeIdInstance"
                    $VolumeInstance= Internal-RestGet -Uri $VolumeUri -Object 'writable'
                    if ($VolumeInstance.id){
                        $LocalEntity= New-Object -TypeName Vmware.Appvolumes.Volume
                        ZGet-InternalSharedVolumeProperties
                        ZGet-InternalWritableVolumeProperties
                        $Entities += $LocalEntity
                    }
                }
            }
        }
        if  (($VolumeID) -or ($Volume))
        {           
            $LocalVolumeId = if ($VolumeID) {$VolumeID} else {$Volume.VolumeId}
            
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('VolumeType')) -or ($VolumeType -eq 'AppStack'))
            {
                $VolumeUri = "$AppStacksUri/$LocalVolumeId"
                $VolumeInstance= Internal-RestGet -Uri $VolumeUri -Object 'appstack'
                if ($VolumeInstance.id){
                    $LocalEntity= New-Object -TypeName Vmware.Appvolumes.Volume
                    ZGet-InternalSharedVolumeProperties
                    ZGet-InternalAppStackVolumeProperties
                    $Entities += $LocalEntity
                }
            }
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('VolumeType')) -or ($VolumeType -eq 'Writable'))
            {
                $VolumeUri = "$WritablesUri/$LocalVolumeId"
                $VolumeInstance= Internal-RestGet -Uri $VolumeUri -Object 'writable_volumes'
                if ($VolumeInstance.id){
                    $LocalEntity= New-Object -TypeName Vmware.Appvolumes.Volume
                    ZGet-InternalSharedVolumeProperties
                    ZGet-InternalWritableVolumeProperties
                    $Entities += $LocalEntity
                }
            }
        }

    }
    end
    {
        if ($Entities.Count -ge 1) {

            $filteredEntities = Internal-ReturnFiltered $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
            if ($filteredEntities.Count -ge 1) {return $filteredEntities} 
        }
    }
	

}

#.ExternalHelp AppVol.psm1-help.xml
Function New-AppVolVolume
{
    [CmdletBinding(DefaultParameterSetName = 'AppStack')]
    [OutputType([VMware.AppVolumes.Volume[]])]
    param(
        [Parameter(ParameterSetName = 'AppStack',Mandatory = $true,Position = 0,ValueFromPipeline = $TRUE,ValueFromRemainingArguments = $false)]
        [Parameter(ParameterSetName = 'Writable',Mandatory = $true,Position = 0,ValueFromPipeline = $TRUE,ValueFromRemainingArguments = $false)]
        [ValidateNotNull()]
        [Vmware.Appvolumes.Template]$Template,
	
        [Parameter(Mandatory = $true,Position = 0)]
        [ValidateNotNull()]
        [string]$VolumeName,
        [Parameter(Mandatory = $false,Position = 1)]
        [ValidateNotNull()]
        [string]$VolumePath,
	
        [Parameter(ParameterSetName = 'AppStack',Mandatory = $false,Position = 2)]
        [ValidateNotNull()]
        [string]$VolumeDescription,
	
        [Parameter(ParameterSetName = 'AppStack',Mandatory = $false,Position = 3)]
        [Parameter(ParameterSetName = 'Writable',Mandatory = $false,Position = 3)]
        [ValidateNotNull()]
        [VMware.AppVolumes.VolumeType]$VolumeType=[VMware.AppVolumes.VolumeType]::AppStack,


        [Parameter(ParameterSetName = 'Writable',Mandatory = $false,Position = 4)]
        [ValidateNotNull()]
        [bool]$BlockLogin=$false,

        [Parameter(ParameterSetName = 'Writable',Mandatory = $false,Position = 5)]
        [ValidateNotNull()]
        [string]$MountPrefix,

        [Parameter(ParameterSetName = 'Writable',Mandatory = $false,Position = 6)]
        [ValidateNotNull()]
        [bool]$DeferCreate=$false,
    
        [Parameter(ParameterSetName = 'Writable',Mandatory = $true,Position = 7)]
        [ValidateNotNull()]
        [VMware.AppVolumes.Entity]$Entity




    )

    
    
    begin{
	
	
	
        Test-AppVolSession
        switch ($VolumeType)
        {
            'AppStack'
            {

                $ApiUri = "$($Global:GlobalSession.Uri)cv_api/appstacks"
	
                if ([string]::IsNullOrEmpty($VolumePath)) {
                    $config=Get-AppVolDataStoreConfig
                    $VolumePath=$config.AppStackDefaultPath
                }
                $postParams = @{
                    name=$VolumeName;
                    description=$VolumeDescription;
                    datacenter=$Template.DataStore.DatacenterName;
                    datastore="$($Template.DataStore.Name)|$($Template.DataStore.DatacenterName)|$($Template.DataStore.MachineManager.MachineManagerId)";
                    path=$VolumePath;
                    template_path=$Template.Path;
                    template_name=$Template.Name;
                    bg=0
                }|ConvertTo-Json
	
                $response = Internal-RestPost -Uri $ApiUri -Body $postParams
		
                if ($response.appstack_id)
                {
                    return Get-AppVolVolume -VolumeID $response.appstack_id -VolumeType:AppStack
                }
                else{
                    return $response
                }
	
            }
        }
        'Writable'
        {
        Write-Error 'TODO'
        }
    }
	
	
	
	
}

   function ZGet-InternalSharedVolumeProperties
    {

        $LocalEntity.VolumeId = $VolumeInstance.id
        $LocalEntity.Name = $VolumeInstance.name
        $LocalEntity.Path = $VolumeInstance.path
        $LocalEntity.DataStore = $AllDataStores|Where-Object {$_.Name -eq $VolumeInstance.datastore_name} |Select-Object -First 1
        $LocalEntity.FileName = $VolumeInstance.filename
        $LocalEntity.Description = $VolumeInstance.description
        if ($VolumeInstance.created_at)
        {
            $LocalEntity.CreatedAt = $VolumeInstance.created_at
        }
		
        if ($VolumeInstance.mounted_at)
        {
            $LocalEntity.MountedAt = $VolumeInstance.mounted_at
        }
        $LocalEntity.Status = $VolumeInstance.status
        $LocalEntity.Size = $VolumeInstance.size_mb
        $LocalEntity.TemplateVersion = $VolumeInstance.template_version
        $LocalEntity.MountCount = $VolumeInstance.mount_count
        $LocalEntity.AssignmentsTotal = $VolumeInstance.assignments_total
        $LocalEntity.AttachmentsTotal = $VolumeInstance.attachments_total		
        $LocalEntity.TemplateFileName = $VolumeInstance.template_file_name

        $os = New-Object -TypeName Vmware.Appvolumes.OperatingSystem
        $os.id = $VolumeInstance.primordial_os_id
        $os.Name = $VolumeInstance.primordial_os_name
        $LocalEntity.PrimordialOs = $os
        [Vmware.Appvolumes.OperatingSystem[]]$oses = $null
        foreach ($tmpos in $VolumeInstance.oses)
        {
            $tmpAsos = New-Object -TypeName Vmware.Appvolumes.OperatingSystem
            $tmpAsos.Name = $tmpos.Name
            $tmpAsos.id = $tmpos.id
            $oses += $tmpAsos
        }
        $LocalEntity.Oses=$oses
    }

    Function ZGet-InternalAppStackVolumeProperties
    {
        $LocalEntity.ApplicationCount = $VolumeInstance.application_count
        $LocalEntity.LocationCount = $VolumeInstance.location_count
        if ($VolumeInstance.volume_guid) {$LocalEntity.VolumeGuid = $VolumeInstance.volume_guid}
        $LocalEntity.AgentVersion = $VolumeInstance.agent_version
        $LocalEntity.CaptureVersion = $VolumeInstance.capture_version
        try
        {
            [regex]$parser='(?:<.*a href="/volumes#/AppStacks/)(?<id>\d*)(?:".*title=")(?<displayname>.*)(?:".*>)(?<upn>.*)(?:<.*>)'
            $LocalEntity.Parent =[regex]::Matches($VolumeInstance.parent_snapvol,$parser)[0].groups['id'].value
        }
        catch {}

        $LocalEntity.ProvisonDuration = $VolumeInstance.provision_duration
        if ($VolumeInstance.provision_computer)
        {
            try
            {
                [regex]$parser='(?:<.*>)(?<computer>.*)(?:<.*>)'
                $LocalEntity.ProvisioningComputer =[regex]::Matches($VolumeInstance.provision_computer,$parser)[0].groups['computer'].value
            }
            catch{}
        }
     
        $LocalEntity.VolumeType='AppStack'
    }
    Function ZGet-InternalWritableVolumeProperties
    {
        if ($VolumeInstance.owner)
        {
            try
            {
                [regex]$parser='(?:<.*>)(?<owner>.*)(?:<.*>)'
                $LocalEntity.Owner =[regex]::Matches($VolumeInstance.owner,$parser)[0].groups['owner'].value
            }
            catch {}
        }
    
        if ($VolumeInstance.owner_type) {$LocalEntity.OwnerType = $VolumeInstance.owner_type}
        $LocalEntity.FreeSpace = $VolumeInstance.free_mb
        $LocalEntity.BlockLogin = $VolumeInstance.block_login
        $LocalEntity.DeferCreate = $VolumeInstance.defer_create
        $LocalEntity.MountPrefix = $VolumeInstance.mount_prefix
        $LocalEntity.Protected = $VolumeInstance.protected
        $LocalEntity.VolumeType='Writable'
    }

    	