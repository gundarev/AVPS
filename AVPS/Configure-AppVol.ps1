#region Classes
Import-Module  Microsoft.PowerShell.Utility
if (-not $(Test-Path "$psScriptRoot\AppVol.dll")) 
{
Add-Type -OutputAssembly "$psScriptRoot\AppVol.dll" -OutputType:Library -ReferencedAssemblies (Get-Module Microsoft.PowerShell.Utility).NestedModules[0].path @"
using System;
using Microsoft.PowerShell;
namespace Vmware.Appvolumes

{


 public class AppVolumesVersion
 
{

 public string Version;
 public string InternalVersion;
 public string Copyright;
 

}

 public class AppVolumesSession
 
{

 
 public Microsoft.PowerShell.Commands.WebRequestSession Session;
 public DateTime SessionStart;
 public Uri Uri;
 public string Version;
 

}

 public class AppVolumesAppStack
 
{

 public int VolumeId;
 public string Name;
 public string Path;
 public string DataStore;
 public string FileName;
 public string Description;
 public AppStackStatus Status;
 public DateTime CreatedAt;
 public DateTime MountedAt;
 public int Size;
 public string TemplateVersion;
 public int MountCount;
 public int AssignmentsTotal;
 public int AttachmentsTotal;
 public int LocationCount;
 public int ApplicationCount;
 public Guid VolumeGuid;
 public string TemplateFileName;
 public string AgentVersion;
 public string CaptureVersion;
 public AppStackOS PrimordialOs;
 public AppStackOS[] Oses;
 public string ProvisonDuration;
 

}

 public enum AppStackStatus
 
{

 Missing = 0,
 Enabled = 1,
 Unprovisioned = 2,
 Provisioning = 3,
 Orphaned = 4,
 Legacy = 5,
 Creating = 6,
 Canceled = 7,
 Disabled = 8,
 Reserved = 9,
 Failed = 10,
 Unreachable = 11,
 
 

}

 public enum EntityType
 
{

 User = 0,
 Computer = 1,
 Group = 2,
 OrgUnit = 3,
 
 

}

 public class AppStackOS
 
{

 public int Id;
 public string Name;
 

}

 public class AppVolumesAssignment
 
{

 
 public string DistignushedName;
 public string SamAccountName;
 public string Domain;
 public EntityType EntityType;
 public DateTime EventTime;
 public String MountPrefix;
 public int VolumeId;
 public string VolumeName;
 
 

}

 public class AppVolumesAppStackFile
 
{

 public int VolumeId;
 public string Name;
 public string MachineManagerType;
 public string MachineManagerHost;
 public DateTime CreatedAt;
 public bool Missing;
 public string Path;
 public string DataStore;
 public bool Reachable;
 
 

}

}

"@
}
#endregion Classes

Add-Type -LiteralPath "$psScriptRoot\AppVol.dll" 