#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolTemplate
{
    [OutputType([Vmware.Appvolumes.Template[]])]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
	
	
        [Parameter(ParameterSetName = 'Specific',Position = 0,ValueFromPipeline = $true,Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Vmware.Appvolumes.DataStore]$DataStore,

        [Parameter(ParameterSetName = 'Specific',Position = 1,ValueFromPipeline = $false,Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(ParameterSetName = 'Specific',Position = 2,ValueFromPipeline = $false,Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$TemplatePath,
        [Parameter(ParameterSetName = 'Specific',Position = 3,ValueFromPipeline = $false,Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [ValidateNotNull()]
        [VMware.AppVolumes.VolumeType]$VolumeType
	
    )
    begin
	
    {
        Test-AppVolSession
        [Vmware.Appvolumes.Template[]]$Entities = $null
        $config=Get-AppVolDataStoreConfig
		
		
    }
	
    process
    {
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('VolumeType')) -or ($VolumeType -eq 'AppStack'))
        {

            if (!$DataStore) {$LocalDataStore=$config.AppStackDefaultStorage} else{$LocalDataStore=$DataStore}
		
            if([string]::IsNullOrEmpty($Path)) {$LocalPath=$config.AppStackDefaultPath} else {$LocalPath=$Path}
            if ([string]::IsNullOrEmpty($TemplatePath)) {$LocalTemplatePath = $config.AppStackTemplatePath} else {$LocalTemplatePath=$TemplatePath}
            $LocalPath=[System.Web.HttpUtility]::UrlEncode($LocalPath)
            $LocalTemplatePath = [System.Web.HttpUtility]::UrlEncode($LocalTemplatePath)
            $LocalDataStoreText=[System.Web.HttpUtility]::UrlEncode("$($LocalDataStore.Name)|$($LocalDataStore.DatacenterName)|$($LocalDataStore.MachineManager.MachineManagerId)")
            $ApiUri = "$($Global:GlobalSession.Uri)cv_api/templates?datastore=$LocalDataStoreText&path=$LocalPath&templates_path=$LocalTemplatePath"
            $TemplateInstances= Internal-RestGet -Uri $ApiUri -Object 'templates'
            foreach ($templateInstance in $TemplateInstances)
            {
                $tmpInstance = New-Object -TypeName Vmware.Appvolumes.Template
                $tmpInstance.Name =$templateInstance.name
                $tmpInstance.Path =$templateInstance.path
                $tmpInstance.Sep =$templateInstance.sep
                $tmpInstance.Uploading =$templateInstance.uploading
                $tmpInstance.DataStore= $LocalDataStore
                if ($Name)
                {
                    if ($tmpInstance.Name.StartsWith($Name))
                    {
                        $Entities += $tmpInstance
                    }
                }
                else
                {
                    $Entities += $tmpInstance
                }
               					
                
            }
        }
        
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('VolumeType')) -or ($VolumeType -eq 'Writable'))
        {

            if (!$DataStore) {$LocalDataStore=$config.WritableDefaultStorage}else{$LocalDataStore=$DataStore}
		
            if([string]::IsNullOrEmpty($Path)) {$LocalPath=$config.WritableDefaultPath} else {$LocalPath=$Path}
            if ([string]::IsNullOrEmpty($TemplatePath)) {$LocalTemplatePath = $config.WritableTemplatePath} else {$LocalTemplatePath=$TemplatePath}
            $LocalPath=[System.Web.HttpUtility]::UrlEncode($LocalPath)
            $LocalTemplatePath = [System.Web.HttpUtility]::UrlEncode($LocalTemplatePath)
            $LocalDataStoreText=[System.Web.HttpUtility]::UrlEncode("$($LocalDataStore.Name)|$($LocalDataStore.DatacenterName)|$($LocalDataStore.MachineManager.MachineManagerId)")
            $ApiUri = "$($Global:GlobalSession.Uri)cv_api/templates?datastore=$LocalDataStoreText&path=$LocalPath&templates_path=$LocalTemplatePath"
            $TemplateInstances= Internal-RestGet -Uri $ApiUri -Object 'templates'
            foreach ($templateInstance in $TemplateInstances)
            {
                $tmpInstance = New-Object -TypeName Vmware.Appvolumes.Template
                $tmpInstance.Name =$templateInstance.name
                $tmpInstance.Path =$templateInstance.path
                $tmpInstance.Sep =$templateInstance.sep
                $tmpInstance.Uploading =$templateInstance.uploading
                $tmpInstance.DataStore= $LocalDataStore
						
                  if ($Name)
                {
                    if ($tmpInstance.Name.StartsWith($Name))
                    {
                        $Entities += $tmpInstance
                    }
                }
                else
                {
                    $Entities += $tmpInstance
                }
               

            }
        }	
    }
    end
    {
        return  $Entities
    }
}

#.ExternalHelp AppVol.psm1-help.xml
Function Select-AppVolTemplate

{
    [OutputType([Vmware.Appvolumes.Template])]
	
    [CmdletBinding(DefaultParameterSetName = 'AppStack')]
    param(
        [Parameter(ParameterSetName = 'Template',Mandatory = $true,Position = 0,ValueFromPipeline = $TRUE,ValueFromRemainingArguments = $false)]
        [ValidateNotNull()]
        [Vmware.Appvolumes.Template[]]$Template=$( if (!$template) {Get-AppVolTemplate})
    )
    begin
    {
        [Vmware.Appvolumes.Template[]]$TemplateCollection=$null
    }  
    process
    {
        $TemplateCollection +=$Template
    }
    end
    {

        $allTemplates=$TemplateCollection|Select-Object -Property @{Label='Machine Manager';Expression={$_.Datastore.MachineManager.name}}, @{Label='Path';Expression={'['+$_.Datastore.name+']'+$_.Path+'/'+$_.Name}}

        $selectedTemplate=$allTemplates|Out-GridView -OutputMode:Single -Title 'Select template' 
        $templateObject = $TemplateCollection|Where-Object -FilterScript {($_.Datastore.MachineManager.name -eq $selectedTemplate.'Machine Manager') -and ($_.Datastore.name -eq $selectedTemplate.Path.TrimStart('[').split(']')[0]) -and (($selectedTemplate.Path.TrimStart('[').split(']')[1]).startswith($_.path)) -and  (($selectedTemplate.Path.TrimStart('[').split(']')[1]).endswith($_.Name))}
        return $templateObject
    }
}
