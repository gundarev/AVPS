#region Classes
Import-Module  Microsoft.PowerShell.Utility
if (-not $(Test-Path "$psScriptRoot\AppVol.dll")) 
{
Add-Type -OutputAssembly "$psScriptRoot\AppVol.dll" -OutputType:Library -ReferencedAssemblies (Get-Module Microsoft.PowerShell.Utility).NestedModules[0].path @"
using System;
using System.Net;

namespace VMware.AppVolumes
{
    public class AppVolumesVersion
    {
        public string Copyright;
        public string InternalVersion;
        public string Version;
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
        public string AgentVersion;
        public int ApplicationCount;
        public int AssignmentsTotal;
        public int AttachmentsTotal;
        public string CaptureVersion;
        public DateTime CreatedAt;
        public string DataStore;
        public string Description;
        public string FileName;
        public int LocationCount;
        public int MountCount;
        public DateTime MountedAt;
        public string Name;
        public AppStackOS[] Oses;
        public string Path;
        public AppStackOS PrimordialOs;
        public string ProvisonDuration;
        public int Size;
        public AppStackStatus Status;
        public string TemplateFileName;
        public string TemplateVersion;
        public Guid VolumeGuid;
        public int VolumeId;
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
        Unreachable = 11
    }

    public enum EntityType
    {
        User = 0,
        Computer = 1,
        Group = 2,
        OrgUnit = 3
    }

    public class AppStackOS
    {
        public int Id;
        public string Name;
    }

    public enum ComputerType
    {
        Unknown = 0,
        Desktop = 1,
        Server = 2,
        TServer = 3
    }
    public class AppVolumesAssignment
    {
        public string DistignushedName;
        public string Domain;
        public EntityType EntityType;
        public DateTime EventTime;
        public string MountPrefix;
        public string SamAccountName;
        public int VolumeId;
        public string VolumeName;
    }

    public class AppVolumesAppStackFile
    {
        public DateTime CreatedAt;
        public string DataStore;
        public string MachineManagerHost;
        public string MachineManagerType;
        public bool Missing;
        public string Name;
        public string Path;
        public bool Reachable;
        public int VolumeId;
    }

    public enum AgentStatus
    {
        Red=0,
        Green=1,
        GoodC=2,
        GoodW=3

    }
    public class AppVolumesEntity
    {
        public int EntityId;
        public EntityType EntityType;
        public bool Enabled;
        public DateTime LastLogin;
        public int NumLogins;
        public string DisplayName;
        public string SamAccountName;
        public string Domain;
        public int WritablesAssigned;
        public int AppStacksAssigned;
        public int AppStacksAttached;
        public string AgentVersion;
        public ComputerType ComputerType;
        public DateTime ConnectionTime;
        public AgentStatus AgentStatus;
        public IPAddress IPAddress;
        public int HostId;




    }
}
"@
}
#endregion Classes

Add-Type -LiteralPath "$psScriptRoot\AppVol.dll" 