
	
Function Select-FilteredResults 
{
    param (
        $ParamKeys, 
        $Entities
		
    )

        
    [regex] $RegexParams = '(?i)^(All|Filter|Exact|Not|Id|EntityType|MachineManagerId|Id|VolumeType|Volume|ErrorAction|WarningAction|Verbose|Debug|ErrorVariable|WarningVariable|OutVariable|OutBuffer|PipelineVariable)$'
    $FilteredParamKeys = $ParamKeys -notmatch $RegexParams
		

    if ($FilteredParamKeys.count -gt 0) 
    {
        $EntitiesFiltered = @()
        foreach ($Entity in $Entities)
        {
            foreach ($CurrentParameter in $($FilteredParamKeys))
		
            {
                $EntityList = @()
                switch ($PSCmdlet.MyInvocation.BoundParameters[$CurrentParameter].GetType().Name)
                {
                    {
                        ($_ -match 'String') -or ($_ -eq 'IPAddress')
                    }
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
                    
                    {
                        ($_ -match 'Int') -or ($_ -eq 'DateTime')
                    }
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
                   
                    {
                        (($_ -eq 'SwitchParameter') -and (-not (@('gt', 'ge', 'lt', 'le', 'Exact', 'Like', 'Not') -contains $CurrentParameter )))
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
                }
            }
            if ($EntityList.Count -ge 1)
            {
                $EntitiesFiltered += $EntityList
            }
        }
        return $EntitiesFiltered
    }
    else 
    {
        return $Entities
    }
}
	
Function Invoke-InternalRest
{
    param(
        [Parameter(Position = 1,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [VMware.AppVolumes.Session]$Session,
		
        [Parameter(Position = 2,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    ([System.URI]$_).IsAbsoluteUri
        })]
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
        {
            $cmd = {
                Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.WebRequestSession -Headers $Session.Headers -Body $Body -ContentType 'application/json'
            }
        }
        Post
        {
            $cmd = {
                $res = Invoke-WebRequest -Uri $Uri -TimeoutSec $([int]::MaxValue) -Method $Method -WebSession $Session.WebRequestSession -Headers $Session.Headers -Body $Body -ContentType 'application/json'
                try 
                {
                    return $res|ConvertFrom-Json
                }
                catch 
                {
                    return $res
                }
            }
        }
			
        default
        {
            $cmd = {
                Invoke-RestMethod -Uri $Uri -Method $Method -WebSession $Session.WebRequestSession -Headers $Session.Headers -ContentType 'application/json'
            }
        }
    }
    try
    {
        $WebRequestResult = Invoke-Command $cmd
        $message = @{
            WebRequestResult = $WebRequestResult
            Success          = $true
        }
        return $message
    }
    catch
    {
        $WebRequestResult = $_.Exception.Response.GetResponseStream()
        $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList ($WebRequestResult)
        $reader.BaseStream.Position = 0
        #$reader.DiscardBufferedData()
        $responseBody = [System.Web.HttpUtility]::HtmlDecode($reader.ReadToEnd())
        $message = @{
            error   = $_.Exception.Response.StatusCode.value__
            message = $responseBody
            Success = $false
        }
        return $message
    }
}
	
Function Invoke-InternalGetRest
{
    param(
        [Parameter(Position = 1,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    ([System.URI]$_).IsAbsoluteUri
        })]
        [string]$Uri,
        
        [Parameter(Position = 2,Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
		
        [string]$Object
    )
    $RestResult = Invoke-InternalRest -Uri $Uri -Method Get -Session $Global:GlobalSession
    if ($RestResult.Success)
    {
        $Result = if ($Object) 
        {
            $ObjectArray = $Object.Split('.')
            $cmd = "`$RestResult.WebRequestResult"
            foreach ($SubObject in $ObjectArray)
            {
                $cmd = $cmd +'.'+ $SubObject
            }
            $cmdscript = [scriptblock]::Create($cmd)
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
	
Function Invoke-InternalPostRest
{
    param(
        [Parameter(Position = 1,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    ([System.URI]$_).IsAbsoluteUri
        })]
        [string]$Uri,
        
        [Parameter(Position = 2,Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
		
        [string]$Object,

        [Parameter(Position = 3,Mandatory = $false)]
		
		
        [string]$Body
    )
    if ($Body) 
    {
        $RestResult = Invoke-InternalRest -Uri $Uri -Method Post   -Session $Global:GlobalSession -Body $Body
    }
    else 
    {
        $RestResult = Invoke-InternalRest -Uri $Uri -Method Post -Session $Global:GlobalSession
    }
    if ($RestResult.Success)
    {
        $Result = if ($Object) 
        {
            $ObjectArray = $Object.Split('.')
            $cmd = "`$RestResult.WebRequestResult"
            foreach ($SubObject in $ObjectArray)
            {
                $cmd = $cmd +'.'+ $SubObject
            }
            $cmdscript = [scriptblock]::Create($cmd)
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



	
	
	
Function Initialize-Assignment
{
    param(
        $instance
    )
		
    $splitChar = '\'
    $Assignment = New-Object -TypeName Vmware.Appvolumes.Assignment
    $Assignment.DistignushedName = $instance.entity_dn
    $Assignment.EntityType = $instance.entityt
    if ($Assignment.EntityType -eq 'OrgUnit') 
    {
        $splitChar = ' '
    }
    $Assignment.SamAccountName = $instance.entity_upn.Split($splitChar)[1]
    $Assignment.Domain = $instance.entity_upn.Split($splitChar)[0]
    $Assignment.EntityType = $instance.entityt
    $Assignment.EventTime = $instance.event_time
    $Assignment.MountPrefix = $instance.mount_prefix

    return $Assignment
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
        [ValidateScript({
                    $_.EntityType -eq 'Computer'
        })]
        [VMware.AppVolumes.Entity]$Computer,
	
        [Parameter(ParameterSetName = 'AppStackIdAndComputer',Mandatory = $false,Position = 1)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputerId',Mandatory = $false,Position = 1)]
	
        [int]$VolumeId,
        [ValidateNotNull()]
        [Parameter(ParameterSetName = 'AppStackAndComputerId',Mandatory = $false,Position = 2)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputerId',Mandatory = $false,Position = 2)]
        [ValidateNotNull()]
        [int]$ComputerId
    )
	
	
    Test-AppVolSession
	
    switch ($PSCmdlet.ParameterSetName)
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
            $AppStack = Get-AppVolVolume -Id $VolumeId
        }
        'AppStackIdAndComputerId'
        {
            $Computer = Get-AppVolComputer -Id $ComputerId
            $AppStack = Get-AppVolVolume -Id $VolumeId
        }  
    }
    
    $InuseProvisioners = Get-AppVolProvisioner | Where-Object -FilterScript {
        $_.ProvisioningStatus -eq 'InUse'
    } 


    $machineguid = $(Get-AppVolProvisioner|Where-Object -FilterScript {
            $_.Id -eq $Computer.Id
    }).uuid
    $ApiUri = "$($Global:GlobalSession.Uri)cv_api/provisions/$($AppStack.Id)/start"
    $postParams = @{
        computer_id = $Computer.Id
        uuid        = $machineguid
    }|ConvertTo-Json
    try
    {
        $response = Invoke-InternalRest -Session $Global:GlobalSession -Uri $ApiUri -Method Post -Body $postParams
        if ($response.Success)
        {
            $WebRequestResult = $response.WebRequestResult|ConvertFrom-Json
            return $WebRequestResult
        }
        else 
        {
            throw $response.message
        }
    }
    catch
    {
        Write-Error -Message $_.Exception.message
    }	
}


Function TODOGetAppVolAssignment
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(

        [Parameter(ParameterSetName = 'SelectedVolumeId',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
        [Alias('id')]
        [ValidateNotNull()]
        [int[]]$Id,
	
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
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
        if (($PSCmdlet.ParameterSetName -eq 'None') -and (!$Id) -and (!$Volume))
        {
            $AllAssignments = Invoke-InternalGetRest -Uri $ApiUri -Object 'assignments'
            foreach ($AssignmentInstance in $AllAssignments)
            {
                $Entities += Initialize-Assignment $Entity
            }
        }
        if  (($Id) -or ($Volume))
        {           
            $LocalVolumeId = if ($Id) 
            {
                $Id
            }
            else 
            {
                $Volume.Id
            }
            $AllAssignments = Invoke-InternalGetRest -Uri $ApiUri -Object 'assignments'
            foreach ($AssignmentInstance in $AllAssignments)
            {
                $LocalAssignment = Initialize-Assignment $Entity
                if ($LocalAssignment.Id -eq $Id)
                {
                    $Entities += $LocalAssignment
                }
            }
        }
    }
    end
    {
        return Select-FilteredResults $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
    }
}





Function StartAppVolVolumeMaintenance
{
    param(
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
	
        [Parameter(Mandatory = $true,Position = 1,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [VMware.AppVolumes.Volume]$Volume
	
    )
    $parentVolume = Get-AppVolVolume -Id $Volume.Parent -VolumeType:AppStack
    if ($parentVolume.PrimordialOs)
    {
        $osver = $AppVolOSDictionary.$($parentVolume.PrimordialOs.Name)
    }
    if ($parentVolume.AgentVersion)
    {
        $agentver = $parentVolume.AgentVersion
    }
    if ($parentVolume.CaptureVersion)
    {
        $agentver = $parentVolume.CaptureVersion
    }


    [ScriptBlock]$ScriptBlock = {
        param($osver,$agentver)
        Register-WmiEvent -Class win32_VolumeChangeEvent -SourceIdentifier volumeChange
        $message = $null


        $newEvent = Wait-Event -SourceIdentifier volumeChange
        $eventType = $newEvent.SourceEventArgs.NewEvent.EventType
 
        if ($eventType -eq 2)
        {
            $driveLetter = $newEvent.SourceEventArgs.NewEvent.DriveName
            $driveLabel = ([wmi]"Win32_LogicalDisk='$driveLetter'").VolumeName
            $partitionobject = Get-WmiObject -Query "Associators of {Win32_LogicalDisk.DeviceID=""$driveLetter""} WHERE AssocClass = Win32_LogicalDiskToPartition"
            $diskIndex = $partitionobject.DiskIndex
            $partitionIndex = $partitionobject.Index
            $rootDirectoryObject = Get-WmiObject -Query "Associators of {Win32_LogicalDisk.DeviceID=""$driveLetter""} WHERE AssocClass = Win32_LogicalDiskRootDirectory"
            $rootDirectory = $rootDirectoryObject.Name
            $rootDirectoryEscaped = $rootDirectory -replace '\\', '\\'
            $shareobject = Get-WmiObject -Query "select * from win32_share where Path='$rootDirectoryEscaped'"
            $share = "\\$($shareobject.PSComputerName)\$($shareobject.name)"
            $templateversion = $(Get-Content -Path "$($rootDirectory)version.txt").Split('=')[1]
            $properties = @{
                'driveLetter'   = $driveLetter
                'driveLabel'    = $driveLabel
                'diskIndex'     = $diskIndex
                'partitionIndex' = $partitionIndex
                'rootDirectory' = $rootDirectory
                'share'         = $share
                'templateversion' = $templateversion
                'osver'         = $osver
                'agentver'      = $agentver
            }
            $Object = New-Object -TypeName PSObject -Property $properties
        }
        Remove-Event -SourceIdentifier volumeChange
    
   
        Unregister-Event -SourceIdentifier volumeChange
        return $Object
    }
    $Computer = $(Get-AppVolProvisioner -Filter $ComputerName) |
    Where-Object -FilterScript {
        $_.SamAccountname -eq "$($ComputerName)$"
    }|
    Select-Object -First 1
    $volumejob = Invoke-Command -ComputerName $ComputerName  -ScriptBlock $ScriptBlock -ArgumentList $osver, $agentver -AsJob

    $null = Start-AppVolProvisioning -AppStack $Volume -Computer $Computer
    $Result = Receive-Job -Job $volumejob -Wait
    #$result.version=
    return $Result
}


function Select-FileDialog

{
    param([string]$Title,[string]$Directory,[string]$Filter = 'All Files (*.*)|*.*', [bool]$MultiSelect = $true)

    $null = [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')

    $objForm = New-Object -TypeName System.Windows.Forms.OpenFileDialog

    $objForm.ShowHelp = $true

    $objForm.InitialDirectory = $Directory

    $objForm.Filter = $Filter

    $objForm.Title = $Title
    $objForm.Multiselect = $MultiSelect
    $objForm
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

    $owner = New-Object -TypeName Win32Window -ArgumentList ([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle)

    $Show = $objForm.ShowDialog($owner)

    If ($Show -eq 'OK')

    {
        Return $objForm.FileNames
    }

    Else

    {
        Write-Error -Message 'Operation cancelled by user.'
    }
}
function Select-FolderDialog

{
    param([string]$Title,[string]$Directory,[string]$Filter = 'All Files (*.*)|*.*', [bool]$MultiSelect = $true)

    $null = [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')

    $objForm = New-Object -TypeName System.Windows.Forms.FolderBrowserDialog
    $objForm.Description = $Title
    $objForm.SelectedPath = $Directory
    $objForm.ShowNewFolderButton = $true

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

    $owner = New-Object -TypeName Win32Window -ArgumentList ([System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle)

    $Show = $objForm.ShowDialog($owner)

    If ($Show -eq 'OK')

    {
        Return $objForm.SelectedPath
    }

    Else

    {
        Write-Error -Message 'Operation cancelled by user.'
    }
}






<# 
        .Synopsis
        Modifies AppVolumes Manager AppStack(s).
	
        .Description
        Modifies AppVolumes Manager AppStack(s).
	
        .Parameter Session
        App Volumes Manager Session.
	
        .Parameter VolumeId
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
	
        [Parameter(ParameterSetName = 'OneAppStack',Position = 1,ValueFromPipeline = $true,ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [ValidateNotNullOrEmpty()]
        [int[]]$VolumeId,
        [Parameter(ParameterSetName = 'OneAppStack',Position = 2,ValueFromPipeline = $true,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Property,
        [Parameter(ParameterSetName = 'OneAppStack',Position = 2,ValueFromPipeline = $true,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    process
    {
		
        $Uri = "$($Session.Uri)/cv_api/appstacks/$VolumeId"
		
        $Uri = "$Uri/$VolumeId"
        $WebRequestResult = $(Invoke-InternalRest -Session $Session -Uri $Uri -Method Put).appstack
		
        return $WebRequestResult | Format-Table
		
		
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
    $Uri = "$($Session.Uri)/cv_api/assignments"
	
    $headers = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
    $headers.Add('X-CSRF-Token',$Session.Token)
    $Search = New-Object -TypeName DirectoryServices.DirectorySearcher -ArgumentList ([adsi]'')
    $Search.filter = "(&(sAMAccountName=$ADObject))"
    $ADWebRequestResults = $Search.Findall()
    $assignments = @{
        entity_type = ($ADWebRequestResults[0].Properties['objectclass'])[($ADWebRequestResults[0].Properties['objectclass']).Count - 1]
        path        = $($ADWebRequestResults[0].Properties['DistinguishedName'])
    }
	
    $json = @{
        'action_type' = 'Assign'
        'id'         = $AppStack
        'assignments' = @{
            '0' = $assignments
        }
        'rtime'      = 'false'
        'mount_prefix' = $null
    }
	
    $Body = $json | ConvertTo-Json -Depth 3
	
    $WebRequestResult = Invoke-RestMethod -Uri $Uri -Method post -WebSession $Session.Session -Headers $headers -Body $Body -ContentType 'application/json'
    [hashtable]$Return = @{
		
    }
	
    $Return.WebRequestResult = ($WebRequestResult | Get-Member -MemberType NoteProperty)[-1].Name
    $Return.message = $WebRequestResult.(($WebRequestResult | Get-Member -MemberType NoteProperty)[-1].Name)
	
    return $Return
}



[VMware.AppVolumes.OS[]]$Global:AppVolOSDictionary = $null
$Global:AppVolOSDictionary += New-Object -TypeName VMware.AppVolumes.OS -Property @{
    OSName = 'Windows 8.1 (x86)'
    OSInfo = New-Object -TypeName VMware.AppVolumes.OSInfo -Property @{
        OSVerMajor = 6
        OSVerMinor = 3
        OSArch     = 0
        OSType     = 1
    }
}
$Global:AppVolOSDictionary += New-Object -TypeName VMware.AppVolumes.OS -Property @{
    OSName = 'Windows 8.1 (x64)'
    OSInfo = New-Object -TypeName VMware.AppVolumes.OSInfo -Property @{
        OSVerMajor = 6
        OSVerMinor = 3
        OSArch     = 9
        OSType     = 1
    }
}
$Global:AppVolOSDictionary += New-Object -TypeName VMware.AppVolumes.OS -Property @{
    OSName = 'Windows 8 (x86)'
    OSInfo = New-Object -TypeName VMware.AppVolumes.OSInfo -Property @{
        OSVerMajor = 6
        OSVerMinor = 2
        OSArch     = 0
        OSType     = 1
    }
}
$Global:AppVolOSDictionary += New-Object -TypeName VMware.AppVolumes.OS -Property @{
    OSName = 'Windows 8 (x64)'
    OSInfo = New-Object -TypeName VMware.AppVolumes.OSInfo -Property @{
        OSVerMajor = 6
        OSVerMinor = 2
        OSArch     = 9
        OSType     = 1
    }
}
$Global:AppVolOSDictionary += New-Object -TypeName VMware.AppVolumes.OS -Property @{
    OSName = 'Windows 7 (x86)'
    OSInfo = New-Object -TypeName VMware.AppVolumes.OSInfo -Property @{
        OSVerMajor = 6
        OSVerMinor = 1
        OSArch     = 0
        OSType     = 1
    }
}
$Global:AppVolOSDictionary += New-Object -TypeName VMware.AppVolumes.OS -Property @{
    OSName = 'Windows 7 (x64)'
    OSInfo = New-Object -TypeName VMware.AppVolumes.OSInfo -Property @{
        OSVerMajor = 6
        OSVerMinor = 1
        OSArch     = 9
        OSType     = 1
    }
}
$Global:AppVolOSDictionary += New-Object -TypeName VMware.AppVolumes.OS -Property @{
    OSName = 'Windows Server 2012 R2 (x64)'
    OSInfo = New-Object -TypeName VMware.AppVolumes.OSInfo -Property @{
        OSVerMajor = 6
        OSVerMinor = 3
        OSArch     = 9
        OSType     = 3
    }
}
$Global:AppVolOSDictionary += New-Object -TypeName VMware.AppVolumes.OS -Property @{
    OSName = 'Windows Server 2012 (x64)'
    OSInfo = New-Object -TypeName VMware.AppVolumes.OSInfo -Property @{
        OSVerMajor = 6
        OSVerMinor = 2
        OSArch     = 9
        OSType     = 3
    }
}
$Global:AppVolOSDictionary += New-Object -TypeName VMware.AppVolumes.OS -Property @{
    OSName = 'Windows Server 2008 R2 (x64)'
    OSInfo = New-Object -TypeName VMware.AppVolumes.OSInfo -Property @{
        OSVerMajor = 6
        OSVerMinor = 1
        OSArch     = 9
        OSType     = 3
    }
}
$Global:AppVolOSDictionary += New-Object -TypeName VMware.AppVolumes.OS -Property @{
    OSName = 'Windows Server 2008 (x86)'
    OSInfo = New-Object -TypeName VMware.AppVolumes.OSInfo -Property @{
        OSVerMajor = 6
        OSVerMinor = 0
        OSArch     = 0
        OSType     = 3
    }
}

$Global:AppVolOSDictionary += New-Object -TypeName VMware.AppVolumes.OS -Property @{
    OSName = 'Windows Server 2008 (x64)'
    OSInfo = New-Object -TypeName VMware.AppVolumes.OSInfo -Property @{
        OSVerMajor = 6
        OSVerMinor = 0
        OSArch     = 9
        OSType     = 3
    }
}







#requires -Version 3 
Function Start-AppVolVolumeMaintenance
{
    [outputtype([VMware.AppVolumes.VolumeMaintenance])]
    [CmdletBinding(DefaultParameterSetName = 'AppStackAndComputer')]
    param(
        [Parameter(ParameterSetName = 'AppStackAndComputer',Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'AppStackAndComputerName',Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [VMware.AppVolumes.Volume]$Volume,
	
        [Parameter(ParameterSetName = 'AppStackAndComputer',Mandatory = $true,Position = 1)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputer',Mandatory = $true,Position = 1)]
        [ValidateScript({
                    $_.EntityType -eq 'Computer'
        })]
        [VMware.AppVolumes.Entity]$Computer,
	
        [Parameter(ParameterSetName = 'AppStackIdAndComputer',Mandatory = $true,Position = 1)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputerName',Mandatory = $true,Position = 1)]
	
        [int]$VolumeId,
        [ValidateNotNull()]

        [Parameter(ParameterSetName = 'AppStackAndComputerName',Mandatory = $true,Position = 2)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputerName',Mandatory = $true,Position = 2)]
        [ValidateNotNull()]
        [string]$ComputerName
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'AppStackAndComputer'
        {
            $ComputerName = $Computer.SamAccountName.TrimEnd('$')
        }
        'AppStackAndComputerName'
        {
            $Computer = Get-AppVolEntity -SamAccountName "$($ComputerName)$" -Exact -EntityType:Computer
        }
        'AppStackIdAndComputer'
        {
            $Volume = Get-AppVolVolume -Id $VolumeId -VolumeType:AppStack
        }
        'AppStackIdAndComputerName'
        {
            $Computer = Get-AppVolEntity -SamAccountName "$($ComputerName)$" -Exact -EntityType:Computer
            $Volume = Get-AppVolVolume -Id $VolumeId -VolumeType:AppStack
        }  
    }
    
    [ScriptBlock]$ScriptBlock = {
        $Shares = Get-WmiObject -Class Win32_Share |
        Where-Object -FilterScript {
            $_.Name -eq 'appvolumestemp'
        }|
        ForEach-Object -Process {
            $_.Delete()
        }

    
       
        Register-WmiEvent -Query "Select * From __InstanceCreationEvent within 3 Where TargetInstance ISA 'Win32_Volume'" -SourceIdentifier event 
        $Result = Wait-Event -SourceIdentifier event
        $Method = 'Create'
        $sd = ([WMIClass] 'Win32_SecurityDescriptor').CreateInstance()
        $ACE = ([WMIClass] 'Win32_ACE').CreateInstance()
        $Trustee = ([WMIClass] 'Win32_Trustee').CreateInstance()
        $Trustee.Name = 'Everyone'
        $Trustee.Domain = 'NT Authority'
        $ACE.AccessMask = 2032127
        $ACE.AceFlags = 3
        $ACE.AceType = 0
        $ACE.Trustee = $Trustee 
        $sd.DACL += $ACE.psObject.baseobject   
        $mc = [WmiClass]'Win32_Share'
        $InParams = $mc.psbase.GetMethodParameters($Method)
        $InParams.Access = $sd
        $InParams.Description = 'App Volumes Temporary share'
        $InParams.MaximumAllowed = $null
        $InParams.Name = 'appvolumestemp'
        $InParams.Password = $null
        $InParams.Path = $Result.SourceEventArgs.NewEvent.TargetInstance.DeviceID.Replace('?','.')
        $InParams.Type = [uint32]0

        $R = $mc.PSBase.InvokeMethod($Method, $InParams, $null)
        return $R
    }
    
    
    $RemoteJob = Invoke-Command  -ScriptBlock $ScriptBlock  -AsJob -ComputerName $ComputerName

    $null = Start-AppVolProvisioning -Volume $Volume -Computer $Computer
    if (Receive-Job -Job $RemoteJob -Wait) 
    {
        $Result = New-Object  -TypeName VMware.AppVolumes.VolumeMaintenance
        $Result.Entity = $Computer
    
        
       

        $Result.Share = Get-Item -Path "\\$($ComputerName)\appvolumestemp" 
        $Result.TemplateVersion = $(Get-Content -Path "$($Result.Share.FullName)\version.txt" -ErrorAction:SilentlyContinue).Split('=')[1] 
        $Result.Metadata = Get-AppVolMetadata -Root  $Result.Share
        $Result.Volume = $Volume
        $Result.AgentVersion = $Computer.AgentVersion
        if ($Volume.Parent) 
        {
            $parentVolume = Get-AppVolVolume -Id $Volume.Parent -VolumeType:AppStack
            if ($parentVolume.PrimordialOs) 
            {
                $Result.PrimordialOs = $parentVolume.PrimordialOs
            }
            if ($parentVolume.CaptureVersion) 
            {
                $Result.CaptureVersion = $parentVolume.CaptureVersion
            }
        }

        return $Result
    }
}

Function Stop-AppVolVolumeMaintenance
{
    [outputtype([bool])]
    param(
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [VMware.AppVolumes.VolumeMaintenance]$VolumeMaintenance
	
        
	
    )
    $ComputerName = $VolumeMaintenance.Entity.SamAccountName.TrimEnd('$')
    
    $Result = Get-WmiObject -Class Win32_Share -ComputerName $ComputerName |
    Where-Object -FilterScript {
        $_.Name -eq 'appvolumestemp'
    }|
    ForEach-Object -Process {
        $_.Delete()
    }

      
    
    if ($Result) 
    {
        Stop-AppVolProvisioning -Volume $VolumeMaintenance.Volume 
        Remove-Item -Path $VolumeMaintenance.Metadata.Directory -Force -Recurse
        return $true
    } 
    else 
    {
        return $false
    }
}

Function Complete-AppVolVolumeMaintenance
{
    [outputtype([VMware.AppVolumes.Volume])]
    param(
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [VMware.AppVolumes.VolumeMaintenance]$VolumeMaintenance
	
        
	
    )
    $ComputerName = $VolumeMaintenance.Entity.SamAccountName.TrimEnd('$')
    
    $osv = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName
    $cpu = Get-WmiObject -Class Win32_processor -ComputerName $ComputerName
    $deviceId = $(Get-WmiObject -Class Win32_Share -ComputerName $ComputerName| Where-Object -FilterScript {
            $_.Name -eq 'appvolumestemp'
    }).Path.replace('.','?')
    $remotevolume = Get-WmiObject -ComputerName pvs009 -Class win32_volume | Where-Object -FilterScript {
        $_.Deviceid -eq $deviceId
    }
    
    $name = 'svservice'
    $uuid = $VolumeMaintenance.Entity.uuid.ToString()
    $status = 0
    $osver = $osv.Version
    $sp = "$($osv.ServicePackMajorVersion).$($osv.ServicePackMinorVersion)"
    $suite = $osv.OSProductSuite
    $product = $osv.ProductType
    $arch = $cpu.Architecture
    $proc = $cpu.NumberOfLogicalProcessors
    $agentver = $VolumeMaintenance.AgentVersion
    #$domain='AVMAINTENANCE'
    $Domain = $VolumeMaintenance.Entity.Domain
    $workstation = $ComputerName
    $volver = $VolumeMaintenance.CaptureVersion
    # $volguid=[System.Guid]::NewGuid().ToString()
    $volguid = [System.Web.HttpUtility]::UrlEncode("{$([Guid]::NewGuid())}")
    $freebytes = $remotevolume.FreeSpace
    $totalbytes = $remotevolume.Capacity

    $idstring = "name=$name&uuid=$uuid&status=$status&$osver=osver&sp=$sp&suite=$suite&product=$product&arch=$arch&proc=$proc&agentver=$agentver&domain=$Domain&workstation=$workstation&volver=$volver&volguid=$volguid&freebytes=$freebytes&totalbytes=$totalbytes"
    #$idstring="status=$status&$osver=osver&sp=$sp&suite=$suite&product=$product&arch=$arch&proc=$proc&agentver=$agentver&volver=$volver&volguid=$volguid&freebytes=$freebytes&totalbytes=$totalbytes"
    

 
   
    
    $UpdateUri = "$($Global:GlobalSession.Uri)update-volume-files?$idstring"
    $ProvisionUri = "$($Global:GlobalSession.Uri)provisioning-complete?$idstring&meta_file=META.ZIP"
   
    $fileBin = [IO.File]::ReadAllBytes($VolumeMaintenance.Metadata)
   
    $boundary = '==CF8F81018C504EBEAC6FB2B3CF53660A=='
    $LF = "`r`n"
    $bodyLinesstart = "--$boundary$($LF)Content-Disposition: form-data; name=`"meta`"; filename=`"META.ZIP`"$($LF)Content-Type: application/x-zip-compressed$LF$LF"
        
    $bodyLinesend = "$LF--$boundary--$LF"
    
    $Body = [text.encoding]::UTF8.getbytes($bodyLinesstart)+$fileBin+[text.encoding]::ASCII.getbytes($bodyLinesend)
    $credentials = $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("$($VolumeMaintenance.Entity.Domain)\$($VolumeMaintenance.Entity.SamAccountName)", $(ConvertTo-SecureString -String 'NONE' -AsPlainText -Force)))
    
    [ScriptBlock]$ScriptBlock = {
        param($UpdateUri,$ProvisionUri,$boundary, $bodyLinesstart,$bodyLinesend, $fileBin,$credentials)
        
       
        
        [System.Net.HttpWebRequest]$Provisionrequest = [System.Net.HttpWebRequest]::CreateHttp($ProvisionUri)
        $Provisionrequest.ContentType = "multipart/form-data; boundary=$boundary"
        $Provisionrequest.Method = 'POST'
        #$Provisionrequest.Credentials= $(new-object -typename System.Management.Automation.PSCredential ('AVMAINTENANCE\AVMAINTENANCE',$(ConvertTo-SecureString 'NONE' -AsPlainText -Force)))
        $Provisionrequest.Credentials = $credentials
        $Provisionrequest.ServicePoint.Expect100Continue = $false
        $Provisionrequest.UserAgent = 'svservice'
        #$Provisionrequest.UseDefaultCredentials=$true
        
        

    
        [System.Net.HttpWebRequest]$Updaterequest = [System.Net.HttpWebRequest]::Create($UpdateUri)
        
        $Updaterequest.Method = 'GET'
        $Updaterequest.Credentials = $credentials
       
        $bufferstart = [text.encoding]::UTF8.getbytes($bodyLinesstart)
        $bufferend = [text.encoding]::ASCII.getbytes($bodyLinesend)
        $reqst = $Provisionrequest.getRequestStream()
        $reqst.write($bufferstart, 0, $bufferstart.length)
        $reqst.write($fileBin, 0, $fileBin.length)
        $reqst.write($bufferend, 0, $bufferend.length)
        $reqst.flush()
        $reqst.close()
       
        
            
        try
        {
            $Updaterequest.GetResponse()
            [net.httpWebResponse] $res = $Provisionrequest.getResponse()
        }
        catch 
        {
            $res = $_.Exception.InnerException.Response
        }
        finally
        {
            $resst = $res.getResponseStream()
            $sr = New-Object -TypeName IO.StreamReader -ArgumentList ($resst)
            $Result = $sr.ReadToEnd()
            $res.close()
        }
        return $Result
    }
    return Invoke-Command -ComputerName $ComputerName  -ScriptBlock $ScriptBlock -ArgumentList $UpdateUri, $ProvisionUri, $boundary, $bodyLinesstart, $bodyLinesend, $fileBin, $credentials
}


Function Get-AppVolVolumeFile
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
       
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
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
        $AllDataStores = Get-AppVolDataStore
        $AllVolumes = Get-AppVolVolume
        $AllMachineManagers = Get-AppVolMachineManager
        		
    }
	
    process
    {
        if ( (!$VolumeId) -and (!$Volume))
        {
            $Entities = $AllVolumes | Get-AppVolVolumeFile
        }
        Else
        {           
            $LocalVolumeId = $Volume.Id
            switch ($Volume.VolumeType)
            {
                'AppStack'
                {
                    $VolumeUri = "$($Global:GlobalSession.Uri)cv_api/appstacks/$LocalVolumeId/files"
                    $FileInstances = Invoke-InternalGetRest -Uri $VolumeUri 
                    foreach ($FileInstance in $FileInstances)
                    {
                        $AppStackFile = New-Object -TypeName Vmware.Appvolumes.VolumeFile
                        $AppStackFile.Name = $FileInstance.Name
                        if ($FileInstance.created_at) 
                        {
                            $AppStackFile.CreatedAt = $FileInstance.created_at
                        }
		
                        $AppStackFile.Missing = $FileInstance.Missing
                        $AppStackFile.Reachable = $FileInstance.Reachable
                        $AppStackFile.path = $FileInstance.path
                        $AppStackFile.Volume = $AllVolumes|
                        Where-Object -FilterScript {
                            ($_.Id -eq $LocalVolumeId) -and ($_.VolumeType -eq 'AppStack')
                        } |
                        Select-Object -First 1 
                        $AppStackFile.DataStore = $AllDataStores|
                        Where-Object -FilterScript {
                            $_.Name -eq $FileInstance.storage_location
                        } |
                        Select-Object -First 1
                        $AppStackFile.MachineManager = $AllMachineManagers |Where-Object -FilterScript {
                            ($_.Type -eq $FileInstance.machine_manager_type) -and ($_.Name -eq $FileInstance.machine_manager_host)
                        }
                        $Entities += $AppStackFile
                    }
                }
                'Writable' 
                {
                    $AppStackFile = New-Object -TypeName Vmware.Appvolumes.VolumeFile
                    $AppStackFile.Name = $Volume.FileName
                    $AppStackFile.CreatedAt = $Volume.CreatedAt
                    $AppStackFile.Path = $Volume.Path
		
                    $AppStackFile.Volume = $Volume
                    $AppStackFile.DataStore = $Volume.DataStore
                    $AppStackFile.MachineManager = $Volume.DataStore.MachineManager
                    $Entities += $AppStackFile
                }
            }
        }
	
    }
    end
    {
        return Select-FilteredResults $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
    }
}


function Set-AppVolVolume
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(ParameterSetName = 'SelectedVolumeId',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]

        [ValidateNotNull()]
        [int[]]$Id,
	
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
	
        [VMware.AppVolumes.Volume[]]$Volume,

        [ValidateNotNull()]
        [string]$AppStackDescription,
	
	
        [ValidateNotNull()]
        [string]$Prefix,
        [ValidateNotNull()]
        [string]$Suffix
	
    )
    begin{
		
        Test-AppVolSession
        [VMware.AppVolumes.Volume[]]$Entities = $null
        [Vmware.Appvolumes.Volume[]]$EntitiesFiltered = $null
        $AppStacksUri = "$($Global:GlobalSession.Uri)cv_api/appstacks"
        
        $AllDataStores = Get-AppVolDataStore
		
        Test-AppVolSession
		
        [VMware.AppVolumes.DataStoreConfig] $config = Get-AppVolDataStoreConfig
		
        if ([string]::IsNullOrEmpty($AppStackDefaultPath)) 
        {
            $AppStackDefaultPath = $config.AppStackDefaultPath
        }
        if (!$TargetDataStore) 
        {
            $TargetDataStore = $config.AppStackDefaultStorage
        }
        if ([string]::IsNullOrEmpty($AppStackName) -and ([string]::IsNullOrEmpty($Prefix))-and ([string]::IsNullOrEmpty($Suffix))) 
        {
            $Prefix = "$(Get-Date -Format u)-"
        }
    }
    process {

        if  (($Id) -or ($Volume))
        {           
            $LocalVolumeId = if ($Id) 
            {
                $Id
            }
            else 
            {
                $Volume.Id
            }
            if ([string]::IsNullOrEmpty($AppStackName))
            {
                $LocalAppStackName = "$Prefix$($Volume.Name)$Suffix"
            }
            else
            {
                $LocalAppStackName = $AppStackName
            }
            $postParams = @{
                name               = $LocalAppStackName
                description        = $AppStackDescription
                datacenter         = $TargetDataStore.DatacenterName
                datastore          = "$($TargetDataStore.Name)|$($TargetDataStore.DatacenterName)|$($TargetDataStore.MachineManager.Id)"
                path               = $AppStackDefaultPath
                parent_appstack_id = $LocalVolumeId
                bg                 = 0
            }|ConvertTo-Json

			
			    
            $VolumeInstance = Invoke-InternalPostRest -Uri $AppStacksUri  -Body $postParams
            $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Volume
            if ($VolumeInstance.appstack_id)
            {
                $Entities += Get-AppVolVolume -Id $VolumeInstance.appstack_id -VolumeType:AppStack
            }
        }
    
		
			
			
			
		
		
    }
	
    end{
        return $Entities
		
    }
}

Function Update-AppVolVolume
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(ParameterSetName = 'SelectedVolumeId',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]

        [ValidateNotNull()]
        [int[]]$Id,
	
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
	
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
        [string]$Prefix,
        [ValidateNotNull()]
        [string]$Suffix
	
    )
    begin{
		
        Test-AppVolSession
        [VMware.AppVolumes.Volume[]]$Entities = $null
        [Vmware.Appvolumes.Volume[]]$EntitiesFiltered = $null
        $AppStacksUri = "$($Global:GlobalSession.Uri)cv_api/appstacks"
        
        $AllDataStores = Get-AppVolDataStore
		
        Test-AppVolSession
		
        [VMware.AppVolumes.DataStoreConfig] $config = Get-AppVolDataStoreConfig
		
        if ([string]::IsNullOrEmpty($AppStackDefaultPath)) 
        {
            $AppStackDefaultPath = $config.AppStackDefaultPath
        }
        if (!$TargetDataStore) 
        {
            $TargetDataStore = $config.AppStackDefaultStorage
        }
        if ([string]::IsNullOrEmpty($AppStackName) -and ([string]::IsNullOrEmpty($Prefix))-and ([string]::IsNullOrEmpty($Suffix))) 
        {
            $Prefix = "$(Get-Date -Format u)-"
        }
    }
    process {

        if  (($Id) -or ($Volume))
        {           
            $LocalVolumeId = if ($Id) 
            {
                $Id
            }
            else 
            {
                $Volume.Id
            }
            if ([string]::IsNullOrEmpty($AppStackName))
            {
                $LocalAppStackName = "$Prefix$($Volume.Name)$Suffix"
            }
            else
            {
                $LocalAppStackName = $AppStackName
            }
            $postParams = @{
                name               = $LocalAppStackName
                description        = $AppStackDescription
                datacenter         = $TargetDataStore.DatacenterName
                datastore          = "$($TargetDataStore.Name)|$($TargetDataStore.DatacenterName)|$($TargetDataStore.MachineManager.Id)"
                path               = $AppStackDefaultPath
                parent_appstack_id = $LocalVolumeId
                bg                 = 0
            }|ConvertTo-Json

			
			    
            $VolumeInstance = Invoke-InternalPostRest -Uri $AppStacksUri  -Body $postParams
            $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Volume
            if ($VolumeInstance.appstack_id)
            {
                $Entities += Get-AppVolVolume -Id $VolumeInstance.appstack_id -VolumeType:AppStack
            }
        }
    
		
			
			
			
		
		
    }
	
    end{
        return $Entities
		
    }
}

Function Get-AppVolVolume
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    [OutputType([VMware.AppVolumes.Volume[]])]
    param(
        [Parameter(ParameterSetName = 'SelectedVolumeId',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
        
        [ValidateNotNull()]
        [int[]]$Id,
	
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [VMware.AppVolumes.Volume[]]$Volume,


        [ValidateNotNull()]
        [string]$name,
	
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
	
        [Vmware.Appvolumes.VolumeStatus]$status,
	
        [ValidateNotNull()]
        [datetime]$CreatedAt,
	
        [ValidateNotNull()]
        [datetime]$MountedAt,
	
        [ValidateNotNull()]
        [int]$Size,
	
        [ValidateNotNull()]
        [string]$templateversion,
	
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
        $AllDataStores = Get-AppVolDataStore
		
		
    }
    process
    {
        if (($PSCmdlet.ParameterSetName -eq 'None') -and (!$Id) -and (!$Volume))
        {
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('VolumeType')) -or ($VolumeType -eq 'AppStack'))
            {
                $AllAppStackVolumes = Invoke-InternalGetRest -Uri $AppStacksUri 
                foreach ($VolumeIdInstance in $AllAppStackVolumes.id)
                {
                    $VolumeUri = "$AppStacksUri/$VolumeIdInstance"
                    
                    $VolumeInstance = Invoke-InternalGetRest -Uri $VolumeUri -Object 'appstack'
                    if ($VolumeInstance.id)
                    {
                        $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Volume
                        ZGet-InternalSharedVolumeProperties
                        ZGet-InternalAppStackVolumeProperties
                        $Entities += $LocalEntity
                    }
                }
            }
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('VolumeType')) -or ($VolumeType -eq 'Writable'))
            {
                $AllWritableVolumes = Invoke-InternalGetRest -Uri $WritablesUri -Object 'datastores.writable_volumes'
                foreach ($VolumeIdInstance in $AllWritableVolumes.id)
                {
                    $VolumeUri = "$WritablesUri/$VolumeIdInstance"
                    $VolumeInstance = Invoke-InternalGetRest -Uri $VolumeUri -Object 'writable'
                    if ($VolumeInstance.id)
                    {
                        $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Volume
                        ZGet-InternalSharedVolumeProperties
                        ZGet-InternalWritableVolumeProperties
                        $Entities += $LocalEntity
                    }
                }
            }
        }
        if  (($Id) -or ($Volume))
        {           
            $LocalVolumeId = if ($Id) 
            {
                $Id
            }
            else 
            {
                $Volume.Id
            }
            
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('VolumeType')) -or ($VolumeType -eq 'AppStack'))
            {
                $VolumeUri = "$AppStacksUri/$LocalVolumeId"
                $VolumeInstance = Invoke-InternalGetRest -Uri $VolumeUri -Object 'appstack'
                if ($VolumeInstance.id)
                {
                    $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Volume
                    ZGet-InternalSharedVolumeProperties
                    ZGet-InternalAppStackVolumeProperties
                    $Entities += $LocalEntity
                }
            }
            if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('VolumeType')) -or ($VolumeType -eq 'Writable'))
            {
                $VolumeUri = "$WritablesUri/$LocalVolumeId"
                $VolumeInstance = Invoke-InternalGetRest -Uri $VolumeUri -Object 'writable_volumes'
                if ($VolumeInstance.id)
                {
                    $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Volume
                    ZGet-InternalSharedVolumeProperties
                    ZGet-InternalWritableVolumeProperties
                    $Entities += $LocalEntity
                }
            }
        }

    }
    end
    {
        if ($Entities.Count -ge 1) 
        {
            $filteredEntities = Select-FilteredResults $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
            if ($filteredEntities.Count -ge 1) 
            {
                return $filteredEntities
            } 
        }
    }
}


Function New-AppVolVolume
{
    [CmdletBinding(DefaultParameterSetName = 'AppStack')]
    [OutputType([VMware.AppVolumes.Volume[]])]
    param(
        [Parameter(ParameterSetName = 'AppStack',Mandatory = $true,Position = 0,ValueFromPipeline = $true,ValueFromRemainingArguments = $false)]
        [Parameter(ParameterSetName = 'Writable',Mandatory = $true,Position = 0,ValueFromPipeline = $true,ValueFromRemainingArguments = $false)]
        [ValidateNotNull()]
        [Vmware.Appvolumes.Template]$Template,
	
        [Parameter(ParameterSetName = 'AppStack',Mandatory = $true,Position = 0)]
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
        [VMware.AppVolumes.VolumeType]$VolumeType = [VMware.AppVolumes.VolumeType]::AppStack,


        [Parameter(ParameterSetName = 'Writable',Mandatory = $false,Position = 4)]
        [ValidateNotNull()]
        [bool]$BlockLogin = $false,

        [Parameter(ParameterSetName = 'Writable',Mandatory = $false,Position = 5)]
        [ValidateNotNull()]
        [string]$MountPrefix,

        [Parameter(ParameterSetName = 'Writable',Mandatory = $false,Position = 6)]
        [ValidateNotNull()]
        [bool]$DeferCreate = $false,
    
        [Parameter(ParameterSetName = 'Writable',Mandatory = $true,Position = 7,ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [VMware.AppVolumes.Entity]$Entity




    )

    
    
    begin{
	
	
	
        Test-AppVolSession
        switch ($VolumeType)
        {
            'Writable'
            {
                $ApiUri = "$($Global:GlobalSession.Uri)cv_api/writables"
	
                if ([string]::IsNullOrEmpty($VolumePath)) 
                {
                    $config = Get-AppVolDataStoreConfig
                    $VolumePath = $config.AppStackDefaultPath
                }
                $entityRest = @{
                    entity_type = $Entity.EntityType.ToString()
                    name        = $Entity.DisplayName
                    path        = $Entity.DistignushedName
                }
                $entityArray = @{
                    '0' = $entityRest
                }
               
                $postParams = @{
                    create_for    = $entityArray
                    datastore     = $Template.DataStore.Name
                    uniq_string   = "$($Template.DataStore.Name)|$($Template.DataStore.DatacenterName)|$($Template.DataStore.MachineManager.Id)"
                    path          = $VolumePath
                    template_path = $Template.Path
                    template_name = $Template.Name
                    defer_create  = [int]$DeferCreate
                    block_login   = [int]$BlockLogin
                    mount_prefix  = $MountPrefix
                    bg            = 0
                }|ConvertTo-Json -Depth 3
	
                $response = Invoke-InternalPostRest -Uri $ApiUri -Body $postParams
		
                if ($response.succeses)
                {
                    return Get-AppVolVolume -VolumeType:Writable |
                    Where-Object  -FilterScript {
                        $_.Owner -eq "$($Entity.Domain)\$($Entity.SamAccountName)"
                    }|
                    Select-Object -Last 1
                }
                
                else
                {
                    return $response
                }
            }
        
            'AppStack'
            {
                $ApiUri = "$($Global:GlobalSession.Uri)cv_api/appstacks"
	
                if ([string]::IsNullOrEmpty($VolumePath)) 
                {
                    $config = Get-AppVolDataStoreConfig
                    $VolumePath = $config.WritableDefaultPath
                }
                $postParams = @{
                    name          = $VolumeName
                    description   = $VolumeDescription
                    datacenter    = $Template.DataStore.DatacenterName
                    datastore     = "$($Template.DataStore.Name)|$($Template.DataStore.DatacenterName)|$($Template.DataStore.MachineManager.Id)"
                    path          = $VolumePath
                    template_path = $Template.Path
                    template_name = $Template.Name
                    bg            = 0
                }|ConvertTo-Json
	
                $response = Invoke-InternalPostRest -Uri $ApiUri -Body $postParams
		
                if ($response.appstack_id)
                {
                    return Get-AppVolVolume -Id $response.appstack_id -VolumeType:AppStack
                }
                else
                {
                    return $response
                }
            }
        }
	
	
	
	
    }
}
function ZGet-InternalSharedVolumeProperties
{
    $LocalEntity.Id = $VolumeInstance.id
    $LocalEntity.Name = $VolumeInstance.name
    $LocalEntity.Path = $VolumeInstance.path
    $LocalEntity.DataStore = $AllDataStores|
    Where-Object -FilterScript {
        $_.Name -eq $VolumeInstance.datastore_name
    } |
    Select-Object -First 1
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
    $LocalEntity.Oses = $oses
}

Function ZGet-InternalAppStackVolumeProperties
{
    $LocalEntity.ApplicationCount = $VolumeInstance.application_count
    $LocalEntity.LocationCount = $VolumeInstance.location_count
    if ($VolumeInstance.volume_guid) 
    {
        $LocalEntity.VolumeGuid = $VolumeInstance.volume_guid
    }
    $LocalEntity.AgentVersion = $VolumeInstance.agent_version
    $LocalEntity.CaptureVersion = $VolumeInstance.capture_version
    
    [regex]$parser = '(?:<.*a href="/volumes#/AppStacks/)(?<id>\d*)(?:".*title=")(?<displayname>.*)(?:".*>)(?<upn>.*)(?:<.*>)'
    if ([regex]::IsMatch($VolumeInstance.parent_snapvol,$parser))
        
    {
        $LocalEntity.Parent = [regex]::Matches($VolumeInstance.parent_snapvol,$parser)[0].groups['id'].value
    }
   

    $LocalEntity.ProvisonDuration = $VolumeInstance.provision_duration
    if ($VolumeInstance.provision_computer)
    {
        [regex]$parser = '(?:<.*>)(?<computer>.*)(?:<.*>)'
        if ([regex]::IsMatch(($VolumeInstance.provision_computer, $parser)))
        
        {
            $LocalEntity.ProvisioningComputer = [regex]::Matches($VolumeInstance.provision_computer,$parser)[0].groups['computer'].value
        }
    }
     
    $LocalEntity.VolumeType = 'AppStack'
}
Function ZGet-InternalWritableVolumeProperties
{
    if ($VolumeInstance.owner)
    {
        [regex]$parser = '(?:<.*>)(?<owner>.*)(?:<.*>)'
        if ([regex]::IsMatch(($VolumeInstance.owner, $parser)))
       
        {
            $LocalEntity.Owner = [regex]::Matches($VolumeInstance.owner,$parser)[0].groups['owner'].value
        }
    }
    
    if ($VolumeInstance.owner_type) 
    {
        $LocalEntity.OwnerType = $VolumeInstance.owner_type
    }
    $LocalEntity.FreeSpace = $VolumeInstance.free_mb
    $LocalEntity.BlockLogin = $VolumeInstance.block_login
    $LocalEntity.DeferCreate = $VolumeInstance.defer_create
    $LocalEntity.MountPrefix = $VolumeInstance.mount_prefix
    $LocalEntity.Protected = $VolumeInstance.protected
    $LocalEntity.VolumeType = 'Writable'
}


Function Get-AppVolVersion
{
    [OutputType([VMware.AppVolumes.Version])]
    param()
    process
    {
#        Test-AppVolSession
        $ApiUri = "$($Global:GlobalSession.Uri)cv_api/version"
        $response = Invoke-InternalGetRest -Uri $ApiUri 
        $Version = New-Object -TypeName Vmware.Appvolumes.Version
        $Version.CurrentVersion = $response.version
        $Version.InternalVersion = $response.internal
        $Version.Copyright = $response.copyright
        return $Version
		
    }
}


Function Select-AppVolFiles
{
    [outputtype([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory = $false,Position = 0,ValueFromPipeline = $true)]

        [string]$FolderName,
        
        [Switch]
        $Folder
    )
    $TempDirName = [System.Guid]::NewGuid().ToString()
    $tempDir = New-Item -Type Directory -Name $TempDirName -Path  $env:temp -Force
    [System.IO.FileInfo[]]$filearray = $null
    if ($Folder) 
    {
        $Sourcefolder = Select-FolderDialog -Title 'Select Folder' -Directory $FolderName |
        Get-Item -Force |
        Get-ChildItem -Force
        foreach ($file in $Sourcefolder) 
        {
            $null = Copy-Item  -Path $file.FullName -Destination $tempDir -Recurse -Container -Force
        }
    } 
    else 
    {
        $files = Select-FileDialog -Title 'Select Files' -Directory $FolderName -MultiSelect:$true|Get-Item
        
        foreach ($file in $files) 
        {
            $null = Copy-Item  -Path $file.FullName -Destination $tempDir -Force
        }
    }
    
   
    return $tempDir|Get-ChildItem -Force
}



Function Get-AppVolMachineManager
{
    [OutputType([VMware.AppVolumes.MachineManager[]])]
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(ParameterSetName = 'SelectedMachineManagerId',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
        
        [ValidateNotNull()]
        [int[]]$Id,
	
        [Parameter(ParameterSetName = 'SelectedName',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [string[]]$name,

        [switch]$Exact,
        [switch]$Like,
	
        [switch]$Not
	
    )
    begin
    {
        Test-AppVolSession
        [VMware.AppVolumes.MachineManager[]]$Entities = $null
		
        $ApiUri = "$($Global:GlobalSession.Uri)cv_api/machine_managers"
        $AllMachineManagers = Invoke-InternalGetRest -Uri $ApiUri -Object 'machine_managers'
    }
    process
    {
        $AllMachineManagers = if ($Id) 
        {
            $AllMachineManagers|Where-Object -FilterScript {
                $_.id -eq $Id
            } 
        }
        else 
        {
            $AllMachineManagers
        } 
            
        foreach ($MachineManagerIdInstance in $AllMachineManagers)
        {
            $MachineManagerUri = "$ApiUri/$($MachineManagerIdInstance.id)"
            $MachineManagerInstance = Invoke-InternalGetRest -Uri $MachineManagerUri -Object 'machine_manager'
               
            $LocalEntity = New-Object -TypeName VMware.AppVolumes.MachineManager
            $LocalEntity.AdapterType = $MachineManagerInstance.adapter_type
            $LocalEntity.Connected = $MachineManagerInstance.is_connected
            $LocalEntity.Description = $MachineManagerInstance.description
            $LocalEntity.Id = $MachineManagerInstance.id
            $LocalEntity.MountOnHost = $MachineManagerInstance.mount_on_host
            $LocalEntity.Name = $MachineManagerInstance.host
            $LocalEntity.Type = $MachineManagerInstance.type
            $LocalEntity.UseLocalVolumes = $MachineManagerInstance.use_local_volumes
            $LocalEntity.ManageAcl = $MachineManagerInstance.manage_sec
            $LocalEntity.UserName = $MachineManagerInstance.username
            $LocalEntity.HostUserName = $MachineManagerInstance.host_username
            $Entities += $LocalEntity
        }
        
        
    }
    end
    {
		
        return Select-FilteredResults $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
    }
}

#requires -Version 3 

Function Get-AppVolDataStore
{
    [OutputType([Vmware.Appvolumes.DataStore []])]
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
     
        [Parameter(ParameterSetName = 'SelectedEntity',Mandatory = $false,Position = 0,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = 'Enter one or more AppStack IDs separated by commas.')]
	
        [AllowNull()]
        [int]$Id,
	
	
	
        [ValidateNotNull()]
        [switch]$Accessible,
	
        [ValidateNotNull()] 
        [VMware.AppVolumes.DataStoreCategory]$DataStoreCategory,
	
        [ValidateNotNull()]
        [string]$DataCenterName,
	
        [ValidateNotNull()]
        [int]$DataCenterId,
	
        [ValidateNotNull()]
        [string]$name,
	
	
        [switch]$Exact,
        [switch]$Like,
	
	
        [switch]$Not
	
    )
    begin
    {
        Test-AppVolSession
        [Vmware.Appvolumes.DataStore []]$Entities = $null
        $AllMachineManagers = Get-AppVolMachineManager 
		
        $ApiUri = "$($Global:GlobalSession.Uri)cv_api/datastores"
       
            
        $Datastores = Invoke-InternalGetRest -Uri $ApiUri -Object 'datastores'
     
            
        
    }
    process
    {
        $Datastores = if ($Id) 
        {
            $Datastores|Where-Object -FilterScript {
                $_.id -eq $Id
            } 
        }
        else 
        {
            $Datastores
        } 
                
        foreach ($Entity in $Datastores)
        {
            $LocalEntity = New-Object -TypeName Vmware.Appvolumes.DataStore
		
            if ($Entity.accessible) 
            {
                $LocalEntity.Accessible = $Entity.accessible
            }
            if ($Entity.category) 
            {
                $LocalEntity.DatastoreCategory = $Entity.category
            }
            if ($Entity.uniq_string) 
            {
                $managerId = [int]$($Entity.uniq_string).Split('|')[2]

                $LocalEntity.MachineManager = $AllMachineManagers|Where-Object -FilterScript {
                    $_.Id -eq $managerId
                }
            }
            if ($Entity.datacenter) 
            {
                $LocalEntity.DatacenterName = $Entity.datacenter
            }
            if ($Entity.description) 
            {
                $LocalEntity.Description = $Entity.description
            }
            if ($Entity.display_name) 
            {
                $LocalEntity.DisplayName = $Entity.display_name
            }
            if ($Entity.host) 
            {
                $LocalEntity.HostName = $Entity.host
            }
            if ($Entity.id) 
            {
                $LocalEntity.Id = $Entity.id
            }
            if ($Entity.identifier) 
            {
                $LocalEntity.TextIdentifier = $Entity.identifier
            }
            if ($Entity.name) 
            {
                $LocalEntity.Name = $Entity.name
            }
            if ($Entity.note) 
            {
                $LocalEntity.Note = $Entity.note
            }

            $Entities += $LocalEntity
        }
            
        
    }
    end
    {

		
        return Select-FilteredResults $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
    }
}


Function Select-AppVolDataStore
{
    return Get-AppVolDataStore|Out-GridView -OutputMode:Single -Title 'Select DataStore'
}



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
        [string]$name,
        
        [ValidateNotNull()]
        [VMware.AppVolumes.VolumeType]$VolumeType
	
    )
    begin
	
    {
        Test-AppVolSession
        [Vmware.Appvolumes.Template[]]$Entities = $null
        $config = Get-AppVolDataStoreConfig
		
		
    }
	
    process
    {
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('VolumeType')) -or ($VolumeType -eq 'AppStack'))
        {
            if (!$DataStore) 
            {
                $LocalDataStore = $config.AppStackDefaultStorage
            }
            else
            {
                $LocalDataStore = $DataStore
            }
		
            if([string]::IsNullOrEmpty($Path)) 
            {
                $LocalPath = $config.AppStackDefaultPath
            }
            else 
            {
                $LocalPath = $Path
            }
            if ([string]::IsNullOrEmpty($TemplatePath)) 
            {
                $LocalTemplatePath = $config.AppStackTemplatePath
            }
            else 
            {
                $LocalTemplatePath = $TemplatePath
            }
            $LocalPath = [System.Web.HttpUtility]::UrlEncode($LocalPath)
            $LocalTemplatePath = [System.Web.HttpUtility]::UrlEncode($LocalTemplatePath)
            $LocalDataStoreText = [System.Web.HttpUtility]::UrlEncode("$($LocalDataStore.Name)|$($LocalDataStore.DatacenterName)|$($LocalDataStore.MachineManager.Id)")
            $ApiUri = "$($Global:GlobalSession.Uri)cv_api/templates?datastore=$LocalDataStoreText&path=$LocalPath&templates_path=$LocalTemplatePath"
            $TemplateInstances = Invoke-InternalGetRest -Uri $ApiUri -Object 'templates'
            foreach ($templateInstance in $TemplateInstances)
            {
                $tmpInstance = New-Object -TypeName Vmware.Appvolumes.Template
                $tmpInstance.Name = $templateInstance.name
                $tmpInstance.Path = $templateInstance.path
                $tmpInstance.Sep = $templateInstance.sep
                $tmpInstance.Uploading = $templateInstance.uploading
                $tmpInstance.DataStore = $LocalDataStore
                if ($name)
                {
                    if ($tmpInstance.Name.StartsWith($name))
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
            if (!$DataStore) 
            {
                $LocalDataStore = $config.WritableDefaultStorage
            }
            else
            {
                $LocalDataStore = $DataStore
            }
		
            if([string]::IsNullOrEmpty($Path)) 
            {
                $LocalPath = $config.WritableDefaultPath
            }
            else 
            {
                $LocalPath = $Path
            }
            if ([string]::IsNullOrEmpty($TemplatePath)) 
            {
                $LocalTemplatePath = $config.WritableTemplatePath
            }
            else 
            {
                $LocalTemplatePath = $TemplatePath
            }
            $LocalPath = [System.Web.HttpUtility]::UrlEncode($LocalPath)
            $LocalTemplatePath = [System.Web.HttpUtility]::UrlEncode($LocalTemplatePath)
            $LocalDataStoreText = [System.Web.HttpUtility]::UrlEncode("$($LocalDataStore.Name)|$($LocalDataStore.DatacenterName)|$($LocalDataStore.MachineManager.Id)")
            $ApiUri = "$($Global:GlobalSession.Uri)cv_api/templates?datastore=$LocalDataStoreText&path=$LocalPath&templates_path=$LocalTemplatePath"
            $TemplateInstances = Invoke-InternalGetRest -Uri $ApiUri -Object 'templates'
            foreach ($templateInstance in $TemplateInstances)
            {
                $tmpInstance = New-Object -TypeName Vmware.Appvolumes.Template
                $tmpInstance.Name = $templateInstance.name
                $tmpInstance.Path = $templateInstance.path
                $tmpInstance.Sep = $templateInstance.sep
                $tmpInstance.Uploading = $templateInstance.uploading
                $tmpInstance.DataStore = $LocalDataStore
						
                if ($name)
                {
                    if ($tmpInstance.Name.StartsWith($name))
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


Function Select-AppVolTemplate

{
    [OutputType([Vmware.Appvolumes.Template])]
	
    [CmdletBinding(DefaultParameterSetName = 'AppStack')]
    param(
        [Parameter(ParameterSetName = 'Template',Mandatory = $true,Position = 0,ValueFromPipeline = $true,ValueFromRemainingArguments = $false)]
        [ValidateNotNull()]
        [Vmware.Appvolumes.Template[]]$Template = $( if (!$Template) 
            {
                Get-AppVolTemplate
            }
        )
    )
    begin
    {
        [Vmware.Appvolumes.Template[]]$TemplateCollection = $null
    }  
    process
    {
        $TemplateCollection += $Template
    }
    end
    {

        $allTemplates = $TemplateCollection|Select-Object -Property @{
            Label      = 'Machine Manager'
            Expression = {
                $_.Datastore.MachineManager.name
            }
        }, @{
            Label      = 'Path'
            Expression = {
                '['+$_.Datastore.name+']'+$_.Path+'/'+$_.Name
            }
        }

        $selectedTemplate = $allTemplates|Out-GridView -OutputMode:Single -Title 'Select template' 
        $templateObject = $TemplateCollection|Where-Object -FilterScript {
            ($_.Datastore.MachineManager.name -eq $selectedTemplate.'Machine Manager') -and ($_.Datastore.name -eq $selectedTemplate.Path.TrimStart('[').split(']')[0]) -and (($selectedTemplate.Path.TrimStart('[').split(']')[1]).startswith($_.path)) -and  (($selectedTemplate.Path.TrimStart('[').split(']')[1]).endswith($_.Name))
        }
        return $templateObject
    }
}

#requires -Version 3 
Function Open-AppVolSession

{
    [CmdletBinding(DefaultParameterSetName = 'AppVolSession')]
    [OutputType([bool])]
    param(
        [Parameter(ParameterSetName = 'AppVolSession',Position = 1,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                    ([System.URI]$_).IsAbsoluteUri
        })]
        [Uri]$Uri,
	
        [Parameter(ParameterSetName = 'AppVolSession',Position = 2,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
	
        [Parameter(ParameterSetName = 'AppVolSession',Position = 3,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Password,
        
        [Parameter(Mandatory = $false)]
        [Switch]$PassThru = $false
    )
    begin
    {
        $Result = $false
        $ApiUri = "$($Uri)cv_api/sessions"
        $AdminCredentials = (@{
                'username' = $($Username)
                'password' = $($Password)
        })|ConvertTo-Json
        try
        {
            $WebRequestResult = Invoke-WebRequest -Uri $ApiUri -SessionVariable session -Method Post -Body $AdminCredentials -ContentType 'application/json'|ConvertFrom-Json
            if ($WebRequestResult.success)
            {
                $Global:GlobalSession = New-Object -TypeName Vmware.Appvolumes.Session
                $Global:GlobalSession.WebRequestSession = $Session
                $Global:GlobalSession.Uri = $Uri
                $Global:GlobalSession.Version = Get-AppVolVersion
                $Global:GlobalSession.SessionStart = $Session.Cookies.GetCookies($(([uri]$Uri).AbsoluteUri))['_session_id'].TimeStamp
                Write-Host  -Object 'Session opened'
                $Result = $true
            }
        }
        catch
        {
            Write-Warning -Message $_.exception.message
            if ($_.Exception.Response)
            {
                $WebRequestResult = $_.Exception.Response.GetResponseStream()
                $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList ($WebRequestResult)
                $reader.BaseStream.Position = 0
			
                $responseBody = [System.Web.HttpUtility]::HtmlDecode($reader.ReadToEnd())|ConvertFrom-Json
			
			
                Write-Warning -Message $responseBody.error
            }
        }
        if($PassThru) 
        {
            return $Result
        }
    }
}

Function Close-AppVolSession
{
    [OutputType([bool])]

    param
    (        
        [Parameter(Mandatory = $false)]
        [Switch]$PassThru = $false
    )
    process
    {
        $Result = $false
        Test-AppVolSession
        try
        {
            $ApiUri = "$($Global:GlobalSession.Uri)cv_api/sessions"
            $WebRequestResult = Invoke-WebRequest -Uri $ApiUri -WebSession $Global:GlobalSession.WebRequestSession -Method Delete -ContentType 'application/json'
            $resultcontent = $WebRequestResult.content|ConvertFrom-Json
        
            if ($resultcontent.success)
            {
                $Global:GlobalSession = $null
                Write-Warning -Message $resultcontent.success
                $Result = $true
            }
            elseif ($resultcontent.warning)
            {
                Write-Warning -Message $resultcontent.warning
            }
        }
        catch
        {
            Write-Warning -Message $_.Exception
        }
        if($PassThru) 
        {
            return $Result
        }
    }
}

Function Test-AppVolSession
{
    if ($Global:GlobalSession)
    {
        return
    }
    else
    {
        Write-Warning   -Message 'No open App Volumes Manager session available!'
        break
    }
}


Function Start-AppVolProvisioning
{
    [CmdletBinding(DefaultParameterSetName = 'AppStackAndComputer')]
    param(
        [Parameter(ParameterSetName = 'AppStackAndComputer',Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
        [Parameter(ParameterSetName = 'AppStackAndComputerId',Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [VMware.AppVolumes.Volume]$Volume,
	
        [Parameter(ParameterSetName = 'AppStackAndComputer',Mandatory = $true,Position = 1)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputer',Mandatory = $true,Position = 1)]
        [ValidateScript({
                    $_.EntityType -eq 'Computer'
        })]
        [VMware.AppVolumes.Entity]$Computer,
	
        [Parameter(ParameterSetName = 'AppStackIdAndComputer',Mandatory = $true,Position = 1)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputerId',Mandatory = $true,Position = 1)]
	
        [int]$VolumeId,
        [ValidateNotNull()]
        [Parameter(ParameterSetName = 'AppStackAndComputerId',Mandatory = $true,Position = 2)]
        [Parameter(ParameterSetName = 'AppStackIdAndComputerId',Mandatory = $true,Position = 2)]
        [ValidateNotNull()]
        [int]$ComputerId
    )
	
	
    Test-AppVolSession
	
    switch ($PSCmdlet.ParameterSetName)
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
            $Volume = Get-AppVolVolume -Id $VolumeId -VolumeType:AppStack
        }
        'AppStackIdAndComputerId'
        {
            $Computer = Get-AppVolEntity -Id $ComputerId -EntityType:Computer
            $Volume = Get-AppVolVolume -Id $VolumeId -VolumeType:AppStack
        }  
    }
    $machineguid = $Computer.uuid
    $ApiUri = "$($Global:GlobalSession.Uri)cv_api/provisions/$($Volume.Id)/start"
    $postParams = @{
        computer_id = $Computer.Id
        uuid        = $machineguid
    }|ConvertTo-Json
   
    return Invoke-InternalPostRest -Uri $ApiUri -Body $postParams
}


Function Stop-AppVolProvisioning
{
    [CmdletBinding(DefaultParameterSetName = 'none')]
    param(
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
	
        [VMware.AppVolumes.Volume[]]$Volume,
	
	
        [Parameter(ParameterSetName = 'VolumeId',Mandatory = $true,Position = 1)]
	
        [int[]]$Id
	
    )
	
    begin
    {
        Test-AppVolSession
	
	   
    }
    process
    {
        if ($Volume -or $Id)
        {
            $LocalVolumeId = if ($Id) 
            {
                $Id
            }
            else 
            {
                $Volume.Id
            }
            $ApiUri = "$($Global:GlobalSession.Uri)cv_api/provisions/$LocalVolumeId/stop"
	
            return Invoke-InternalPostRest -Uri $ApiUri 
        }
    }
}


Function Complete-AppVolProvisioning
{
    [CmdletBinding(DefaultParameterSetName = 'none')]
    param(
        [Parameter(ParameterSetName = 'SelectedVolume',Mandatory = $false,Position = 0,ValueFromPipeline = $true)]
	
        [VMware.AppVolumes.Volume[]]$Volume,
	
	
        [Parameter(ParameterSetName = 'VolumeId',Mandatory = $true,Position = 1)]
	
        [int[]]$Id
	
    )
	
    begin
    {
        Test-AppVolSession
	
	   
    }
    process
    {
        if ($Volume -or $Id)
        {
            $LocalVolumeId = if ($Id) 
            {
                $Id
            }
            else 
            {
                $Volume.Id
            }
            $ApiUri = "$($Global:GlobalSession.Uri)cv_api/provisions/$LocalVolumeId/complete"
	
            return Invoke-InternalPostRest -Uri $ApiUri 
        }
    }
}

Function Get-AppVolMetadata
{
    param(
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.DirectoryInfo]$Root
    )
    $files = Get-ChildItem -Path "$($Root.FullName)\METADATA" -Force -ErrorAction:SilentlyContinue
    if ($files)
    {
        $TempDirName = [System.Guid]::NewGuid().ToString()
        $tempDir = New-Item -Type Directory -Name $TempDirName -Path  $env:temp -Force
        $metadatadir = New-Item -Type Directory -Name 'METADATA' -Path $tempDir -Force
        [System.IO.FileInfo[]]$filearray = $null
        foreach ($file in $files) 
        {
            $filearray += Copy-Item -LiteralPath $file.PSPath -Destination $metadatadir -Force -PassThru -Container
        }
        Add-Type -AssemblyName 'system.io.compression.filesystem'
        [io.compression.zipfile]::CreateFromDirectory($metadatadir, "$($tempDir)\META.zip",'Optimal',$true) 
        $metaFile = Get-Item -Path "$($tempDir)\META.zip"
    }
    return $metaFile
}

Function Submit-AppVolMetadata
{
    param(
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Volume
    )
    Test-AppVolSession
	
    
	
    #	$tmp=Invoke-Command  -ComputerName $volume.PSComputerName -ScriptBlock {param($ApiUri) Invoke-RestMethod -Uri "$ApiUri"  -Credential $(new-object -typename System.Management.Automation.PSCredential ("AVMAINTENANCE\AVMAINTENANCE$",$(ConvertTo-SecureString "NONE" -AsPlainText -Force)))} -ArgumentList $ApiUri
    #	if ($tmp.StatusCode -eq 200){
    $VolumeGuid = [System.Web.HttpUtility]::UrlEncode("{$([Guid]::NewGuid())}")
    $ApiUri = "$($Global:GlobalSession.Uri)provisioning-complete?osver=$($Volume.osver)&sp=1.0&suite=256&product=$($Volume.osver.Split('.')[3])&arch=$($Volume.osver.Split('.')[2])&proc=1&agentver=$($Volume.agentver)&volguid=$VolumeGuid&meta_file=META.ZIP&capturever=$($Volume.templateversion)"
    $metazip = Get-AppVolMetadataFromRoot -Path $Volume.share
    $fileBin = [IO.File]::ReadAllBytes($metazip)
    #$filestring=[System.Text.Encoding]::UTF8.GetString($fileBin)
    #$filebin=[System.Text.Encoding]::UTF8.GetBytes($filestring)
    #$enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
    #$fileEnc = $enc.GetString($fileBin)
    $boundary = '==CF8F81018C504EBEAC6FB2B3CF53660A=='
    $LF = "`r`n"
    $bodyLinesstart = "--$boundary$($LF)Content-Disposition: form-data; name=`"meta`"; filename=`"META.ZIP`"$($LF)Content-Type: application/x-zip-compressed$LF$LF"
        
    $bodyLinesend = "$LF--$boundary--$LF"
        
    [ScriptBlock]$ScriptBlock = {
        param($ApiUri,$boundary,$bodyLinesstart,$bodyLinesend,$fileBin)
        [System.Net.HttpWebRequest]$request = [System.Net.HttpWebRequest]::Create($ApiUri)
        $request.ContentType = "multipart/form-data; boundary=$boundary"
        $request.Method = 'POST'
        $request.Credentials = $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("AVMAINTENANCE\AVMAINTENANCE$", $(ConvertTo-SecureString -String 'NONE' -AsPlainText -Force)))
        $request.ServicePoint.Expect100Continue = $false
        #$request.ServicePoint.
        $bufferstart = [text.encoding]::UTF8.getbytes($bodyLinesstart)
        $bufferend = [text.encoding]::ASCII.getbytes($bodyLinesend)
        
        $reqst = $request.getRequestStream()
        $reqst.write($bufferstart, 0, $bufferstart.length)
        $reqst.write($fileBin, 0, $fileBin.length)
        $reqst.write($bufferend, 0, $bufferend.length)
        $reqst.flush()
        $reqst.close()
        try
        {
            [net.httpWebResponse] $res = $request.getResponse()
        }
        catch 
        {
            $res = $_.Exception.InnerException.Response
        }
        finally
        {
            $resst = $res.getResponseStream()
            $sr = New-Object -TypeName IO.StreamReader -ArgumentList ($resst)
            $Result = $sr.ReadToEnd()
            $res.close()
        }
        return $Result
    }
    $tmp = Invoke-Command  -ComputerName $Volume.PSComputerName -ScriptBlock $ScriptBlock -ArgumentList $ApiUri, $boundary, $bodyLinesstart, $bodyLinesend, $fileBin
    $MaintenanceComputer = Get-AppVolEntity -EntityType:Computer -AgentVersion 'AVMAINTENANCE'|Where-Object -FilterScript {
        $_.SamAccountName -eq $computerSamAccountName
    }
		
    #	}
}

#requires -Version 3 
Function Get-AppVolEntity
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory = $false,Position = 0,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true,ValueFromRemainingArguments = $false,HelpMessage = 'Enter one or more AppStack IDs separated by commas.')]
	
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
        $ProvisionersUri = "$($Global:GlobalSession.Uri)cv_api/provisioners"
        $OnlineEntitiesUri = "$($Global:GlobalSession.Uri)cv_api/online_entities"
      
        
        [regex]$GroupParser = '(?:<.*/directory#/Groups/)(?<id>\d*)(?:.*title=")(?<displayname>.*)(?:".*>)(?<upn>.*)(?:<.*>)'
        [regex]$computerParser = '(?:<.*/directory#/Computers/)(?<id>\d*)(?:.*>)(?<upn>.*)(?:<.*>)'
        [regex]$userParser = '(?:<.*/directory#/Users/)(?<id>\d*)(?:.*title=")(?<displayname>.*)(?:".*>)(?<upn>.*)(?:<.*>)'
        [regex]$OrgUnitParser = '(?:<.*/directory#/Org_units/)(?<id>\d*)(?:.*title=")(?<displayname>.*)(?:".*>)(?<upn>.*)(?:<.*>)'
        [regex]$OnlineEntitiesParser = '(?:<a\shref=\"/[a-z]*#/)(?<EntityType>[A-z]*)(?:/)(?<Id>[0-9]*)(?:\"\stitle=\")(?<DisplayName>.*)(?:\">)(?<Domain>.*)(?:[\\]|[\s])(?<SamAccountName>.*)(?:</a>)'
        
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'User')-or ($EntityType -eq 'Computer'))
        {
            $AllOnlineEntities = Invoke-InternalGetRest -Uri $OnlineEntitiesUri -Object 'online.records' 
            foreach ($UnparsedEntity in $AllOnlineEntities)
            {
                $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Entity
                $LocalEntity.Id = [regex]::Matches($UnparsedEntity.entity_name,$OnlineEntitiesParser)[0].Groups['Id'].Value
                $LocalEntity.EntityType = $UnparsedEntity.entity_type
                $LocalEntity.AgentStatus = $UnparsedEntity.agent_status -replace '-', ''
                if ([regex]::IsMatch($UnparsedEntity.details,$OnlineEntitiesParser))
                {
                    $LastComputerId = [regex]::Matches($UnparsedEntity.details,$OnlineEntitiesParser)[0].Groups['Id'].value
                    if ($LastComputerId)
                    {
                        $lastcomputer = New-Object -TypeName VMware.AppVolumes.Entity
                        $lastcomputer.Id = $LastComputerId
                        $LocalEntity.LastComputer = $lastcomputer
                    }
                }
                if ($UnparsedEntity.details.startswith('IP:')) 
                {
                    $LocalEntity.IPAddress = $(($UnparsedEntity.details) -replace 'IP: ', '')
                }
                if ($UnparsedEntity.connection_time) 
                {
                    $LocalEntity.ConnectionTime = $UnparsedEntity.connection_time
                }
                $OnlineEntities += $LocalEntity
            }
        }
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'User')-or ($EntityType -eq 'Computer')) 
        {
            $AllProvisioners = Invoke-InternalGetRest -Uri $ProvisionersUri -Object 'provisioners'
        }      
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'Computer'))
  
        {
            $AllComputers = Invoke-InternalGetRest -Uri $ComputersUri
        }
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'User'))
        {
            $AllUsers = Invoke-InternalGetRest -Uri $UsersUri
        }    
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'OrgUnit'))
        {
            $AllOrgUnits = Invoke-InternalGetRest -Uri $OrgUnitsUri -Object 'org_units'
        }   
            
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'Group'))
        {
            $AllGroups = Invoke-InternalGetRest -Uri $GroupsUri -Object 'groups'
        }
    }
    process
    {
       
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'Computer'))
        {
            $AllComputers = if ($Id) 
            {
                $AllComputers|Where-Object -FilterScript {
                    [regex]::Matches($_.upn,$computerParser)[0].groups['id'].value  -eq $Id
                }
            }
            else 
            {
                $AllComputers
            }

            foreach ($LocalInstance in $AllComputers)
            {
                $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Entity
                Get-EntityProperties $computerParser  'upn' 'Computer'
              
                $provisioner = $AllProvisioners|Where-Object -FilterScript {
                    $_.id -eq $LocalEntity.Id
                }
                if ($provisioner)
                {
                    $LocalEntity.ProvisioningStatus = $provisioner.status -replace '\s', ''
                    if ($provisioner.uuid) 
                    {
                        $LocalEntity.uuid = $provisioner.uuid
                    }
                }
                $onliner = $OnlineEntities|Where-Object -FilterScript {
                    ($_.id -eq $LocalEntity.Id) -and ($_.$EntityType -eq $LocalEntity.EntityType)
                }
                if($onliner)
                {
                    $LocalEntity.AgentStatus = $onliner.AgentStatus
                    $LocalEntity.IPAddress = $onliner.IPAddress
                    $LocalEntity.ConnectionTime = $onliner.ConnectionTime
                }
                $Entities += $LocalEntity
            } 
        }
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'User'))
        {
            $AllUsers = if ($Id) 
            {
                $AllUsers|Where-Object -FilterScript {
                    [regex]::Matches($_.upn_link,$userParser)[0].groups['id'].value  -eq $Id
                }
            }
            else 
            {
                $AllUsers
            }
            foreach ($LocalInstance in $AllUsers)
            {
                $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Entity
                Get-EntityProperties $userParser  'upn_link' 'User'
              
                $onliner = $OnlineEntities|Where-Object -FilterScript {
                    ($_.id -eq $LocalEntity.Id) -and ($_.EntityType -eq $LocalEntity.EntityType)
                }
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
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'OrgUnit'))
        {
            $AllOrgUnits = if ($Id) 
            {
                $AllOrgUnits|Where-Object -FilterScript {
                    [regex]::Matches($_.upn,$OrgUnitParser)[0].groups['id'].value -eq $Id
                } 
            }
            else 
            {
                $AllOrgUnits
            } 
            foreach ($LocalInstance in $AllOrgUnits)
            {
                $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Entity
                Get-EntityProperties $OrgUnitParser  'upn' 'OrgUnit'
               
                $Entities += $LocalEntity
            } 
        }
        if (!($PSCmdlet.MyInvocation.BoundParameters.Keys.Contains('EntityType')) -or ($EntityType -eq 'Group'))
        {
            $AllGroups = if ($Id) 
            {
                $AllGroups|Where-Object -FilterScript {
                    [regex]::Matches($_.upn,$GroupParser)[0].groups['id'].value -eq $Id
                } 
            }
            else 
            {
                $AllGroups
            } 
            foreach ($LocalInstance in $AllGroups)
            {
                $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Entity
                Get-EntityProperties $GroupParser  'upn' 'Group'
              
                $Entities += $LocalEntity
            } 
        }

        
    }
    end
    {
        return Select-FilteredResults $PSCmdlet.MyInvocation.BoundParameters.Keys $Entities
    }
}

Function Search-AppVolEntity
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
      
        [ValidateNotNull()] 
        [string]$Filter

    )
    begin
    {
        Test-AppVolSession
        [Vmware.Appvolumes.Entity []]$Entities = $null
        [Vmware.Appvolumes.Entity []]$OnlineEntities = $null
        
        $SearcherUri = "$($Global:GlobalSession.Uri)cv_api/writable_candidates?name=$Filter&filter=Contains"
        $AllObjects = Invoke-InternalGetRest -Uri $SearcherUri -Object 'create_for.ugc' 
        foreach ($LocalInstance in $AllObjects)
        {
            $LocalEntity = New-Object -TypeName Vmware.Appvolumes.Entity
            $LocalEntity.EntityType = $LocalInstance.entity_type
            $LocalEntity.WritablesAssigned = $LocalInstance.existing
            $LocalEntity.DisplayName = $LocalInstance.name
            $LocalEntity.DistignushedName = $LocalInstance.path
            switch ($LocalEntity.EntityType)
            {
                'OrgUnit'
                {
                    [string[]]$splitChar = ' OU:'
                }
                default
                {
                    [string[]]$splitChar = '\'
                }
            }
   
            $LocalEntity.SamAccountName = $LocalInstance.upn.split($splitChar,[System.StringSplitOptions]::None)[1]
            $LocalEntity.Domain = $LocalInstance.upn.split($splitChar,[System.StringSplitOptions]::None)[0]
           
            $Entities += $LocalEntity
        }
            
        
        
    }
    end
    {
        return  $Entities
    }
}



Function New-AppVolEntity
{
    [OutputType([Vmware.Appvolumes.Entity []])]
	
    param(
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
	
	
    )
	
    Test-AppVolSession
	
    $ApiUri = "$($Global:GlobalSession.Uri)computer-startup?osver=6.1.7601&sp=1.0&suite=256&product=1&arch=9&proc=1&agentver=AVMAINTENANCE"
	
    $tmp = Invoke-Command  -ComputerName $ComputerName -ScriptBlock {
        param($ApiUri) Invoke-WebRequest -Uri "$ApiUri"  -Credential $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("AVMAINTENANCE\AVMAINTENANCE$", $(ConvertTo-SecureString -String 'NONE' -AsPlainText -Force)))
    } -ArgumentList $ApiUri
    if ($tmp.StatusCode -eq 200)
    {
        $computerSamAccountName = $tmp.Content.Split("`n")[0].split('\')[1]
        $computerSamAccountName = $computerSamAccountName.Substring(0,$computerSamAccountName.Length -1)
        $computerDomainName = $tmp.Content.Split("`n")[0].split('\')[0].split(' ')[1]
		
        $MaintenanceComputer = Get-AppVolEntity -EntityType:Computer |Where-Object -FilterScript {
            ($_.SamAccountName -eq $computerSamAccountName) -and ($_.Domain -eq $computerDomainName)
        }
    }
    return $MaintenanceComputer
}



Function Get-EntityProperties
{
    param ($parser, $upnattribute,$LocalEntityType)
    switch ($LocalEntityType)
    {
        'OrgUnit'
        {
            [string[]]$splitChar = ' OU:'
        }
        default
        {
            [string[]]$splitChar = '\'
        }
    }
    $ParsedUpn = [regex]::Matches($LocalInstance.$upnattribute,$parser)[0]
    $LocalEntity.Id = $ParsedUpn.groups['id'].value
    $LocalEntity.SamAccountName = $ParsedUpn.groups['upn'].value.split($splitChar,[System.StringSplitOptions]::None)[1]
    $LocalEntity.Domain = $ParsedUpn.groups['upn'].value.split($splitChar,[System.StringSplitOptions]::None)[0]
    $LocalEntity.DisplayName = if ($ParsedUpn.groups['displayname'].value)
    {
        $ParsedUpn.groups['displayname'].value
    }
    else
    {
        $ParsedUpn.groups['upn'].value
    }
    $LocalEntity.AppStacksAssigned = $LocalInstance.appstacks
    if ($LocalInstance.last_login) 
    {
        $LocalEntity.LastLogin = $($LocalInstance.last_login -replace ' UTC', 'Z')
    }
    $LocalEntity.EntityType = $LocalEntityType
    $LocalEntity.Enabled = $LocalInstance.enabled
    $LocalEntity.WritablesAssigned = $LocalInstance.writables
    $LocalEntity.AppStacksAttached = $LocalInstance.attachments
    $LocalEntity.NumLogins = $LocalInstance.logins
    $LocalEntity.AgentVersion = $LocalInstance.agent_version
    if ($LocalInstance.os) 
    {
        $LocalEntity.ComputerType = $LocalInstance.os
    }
}

 
Function Get-AppVolDataStoreConfig
{
    [OutputType([Vmware.Appvolumes.DataStoreConfig])]
    param()
    begin
    {
        Test-AppVolSession
        $Entity = New-Object -TypeName  VMware.AppVolumes.DataStoreConfig
        $AllDataStores = Get-AppVolDataStore
        $AllMachineManagers = Get-AppVolMachineManager
         
        $ApiUri = "$($Global:GlobalSession.Uri)cv_api/datastores"
        $instance = Invoke-InternalGetRest -Uri $ApiUri
        $Entity.AppStackMachineManager = $AllMachineManagers |Where-Object -FilterScript {
            ($_.Id -eq [int]$($instance.appstack_storage).Split('|')[2])
        }
        $Entity.AppStackDefaultPath = $instance.appstack_path
        $Entity.AppStackDefaultStorage = $AllDataStores|Where-Object -FilterScript {
            ($_.Name -eq [string]$($instance.appstack_storage).Split('|')[0]) -and ($_.DatacenterName -eq [string]$($instance.appstack_storage).Split('|')[1] )-and ($_.MachineManager.Id -eq [int]$($instance.appstack_storage).Split('|')[2])
        }
        $Entity.AppStackTemplatePath = $instance.appstack_template_path
        $Entity.DatacenterName = $instance.datacenter
        $Entity.WritableMachineManager = $AllMachineManagers |Where-Object -FilterScript {
            ($_.Id -eq [int]$($instance.writable_storage).Split('|')[2])
        }
        $Entity.WritableDefaultPath = $instance.writable_path
        $Entity.WritableDefaultStorage = $AllDataStores |Where-Object -FilterScript {
            ($_.Name -eq [string]$($instance.writable_storage).Split('|')[0]) -and ($_.DatacenterName -eq [string]$($instance.writable_storage).Split('|')[1] )-and ($_.MachineManager.Id -eq [int]$($instance.writable_storage).Split('|')[2])
        }
        $Entity.WritableTemplatePath = $instance.writable_template_path

		
    }
	
    end
    {
		
        return $Entity
    }
}


if ($PSVersionTable.PSVersion.Major -lt 3)
{
    throw New-Object -TypeName System.NotSupportedException -ArgumentList 'PowerShell V3 or higher required.'
}


Export-ModuleMember -Function *AppVol*