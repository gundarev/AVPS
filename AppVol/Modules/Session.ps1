Function Open-AppVolSession

{
	
    [CmdletBinding(DefaultParameterSetName = 'AppVolSession')]
    [OutputType([bool])]
    param(
        [Parameter(ParameterSetName = 'AppVolSession',Position = 1,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({([System.URI]$_).IsAbsoluteUri})]
        [Uri]$Uri,
	
        [Parameter(ParameterSetName = 'AppVolSession',Position = 2,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
	
        [Parameter(ParameterSetName = 'AppVolSession',Position = 3,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Password,
        
        [Parameter(Mandatory=$false)]
        [Switch]$PassThru=$false
    )
    begin
    {
        $result=$false
        $ApiUri="$($Uri)cv_api/sessions"
        $AdminCredentials = (@{ 'username' = $($Username); 'password' = $($Password)})|ConvertTo-Json
        try
        {
            $WebRequestResult= Invoke-WebRequest -Uri $ApiUri -SessionVariable session -Method Post -Body $AdminCredentials -ContentType 'application/json'|ConvertFrom-Json
            if ($WebRequestResult.success)
            {
            
                $Global:GlobalSession = New-Object Vmware.Appvolumes.Session
                $Global:GlobalSession.WebRequestSession = $session
                $Global:GlobalSession.Uri = $Uri
                $Global:GlobalSession.Version = Get-AppVolVersion
                $Global:GlobalSession.SessionStart = $session.Cookies.GetCookies($(([uri]$Uri).AbsoluteUri))['_session_id'].TimeStamp
                Write-Host  'Session opened'
                $result= $true
            }
        }
        catch
        {
            Write-Warning $_.exception.message
            if ($_.Exception.Response)
            {
                $WebRequestResult = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($WebRequestResult)
                $reader.BaseStream.Position = 0
			
                $responseBody = [System.Web.HttpUtility]::HtmlDecode($reader.ReadToEnd())|ConvertFrom-Json
			
			
                Write-Warning $responseBody.error
            }
            
        }
        if($PassThru) {return $result}
    }
	
	
	
}

Function Close-AppVolSession
{
    [OutputType([bool])]

    param
    (        
        [Parameter(Mandatory=$false)]
        [Switch]$PassThru=$false
    )
    process
    {
        $result=$false
        Test-AppVolSession
        try
        {
            $ApiUri="$($Global:GlobalSession.Uri)cv_api/sessions"
            $WebRequestResult= Invoke-WebRequest -Uri $ApiUri -WebSession $Global:GlobalSession.WebRequestSession -Method Delete -ContentType 'application/json'
            $resultcontent= $WebRequestResult.content|convertfrom-json
        
            if ($resultcontent.success)
            {
                $Global:GlobalSession = $null
                Write-Warning $resultcontent.success
                $result= $true
            }
            elseif ($resultcontent.warning)
            {
		    
                Write-Warning $resultcontent.warning
                
            }
        }
        catch
        {
            Write-Warning $_.Exception
            
        }
        if($PassThru) {return $result}
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
        Write-Error  'No open App Volumes Manager session available!'
        break
    }
	
}