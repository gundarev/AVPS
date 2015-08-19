#.ExternalHelp AppVol.psm1-help.xml
Function Get-AppVolVersion
{
    [OutputType([VMware.AppVolumes.Version])]
    param()
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