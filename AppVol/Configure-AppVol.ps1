#region Classes
Import-Module  Microsoft.PowerShell.Utility
if (-not $(Test-Path "$psScriptRoot\AppVol.dll")) 
{
Add-Type -OutputAssembly "$psScriptRoot\AppVol.dll"  -OutputType:Library -ReferencedAssemblies (Get-Module Microsoft.PowerShell.Utility).NestedModules[0].path @"
using System;
using System.Net;

namespace VMware.AppVolumes
{
    public class Version
    {
        public string Copyright;
        public string InternalVersion;
        public string CurrentVersion;
    }
    public class Template
    {
        public string Name;
        public string Path;
        public string Sep;
        public bool Uploading;
        public DataStore DataStore;
        
    }
    public class Session
    {
        public Microsoft.PowerShell.Commands.WebRequestSession WebRequestSession;
        public DateTime SessionStart;
        public Uri Uri;
        public Version Version;
    }

        public class DataStoreConfig
    {
        public string AppStackDefaultPath;
        public DataStore AppStackDefautStorage;
        public string AppStackTemplatePath;
        public MachineManager AppStackMachineManager;
        public string DatacenterName;
        public string WritableDefaultPath;
        public DataStore WritableDefaultStorage;
        public string WritableTemplatePath;
        public MachineManager WritableMachineManager;
    }
    public class MachineManager
    {
     public static implicit operator MachineManager(int s)
    {
        return new MachineManager { MachineManagerId = s };
    }
  
        public string AdapterType;
        public string Description;
        public int MachineManagerId;
        public string Name;
        public bool Connected;
        public bool MountOnHost;
        public bool UseLocalVolumes;
        public bool ManageAcl;
        public string Type;
        public string UserName;
                
    }
    public class DataStore
    {
        public bool Accessible;
        public DatastoreCategory DatastoreCategory;
        public int DatastoreId;
        public string DatacenterName;
        public string Description;
        public string DisplayName;
        public string HostName;
        public MachineManager MachineManager;
        public string TextIdentifier;
        public string Name;
        public string Note;
        
    }
    public class Volume
    {
        public string AgentVersion;
        public int ApplicationCount;
        public int AssignmentsTotal;
        public int AttachmentsTotal;
        public string CaptureVersion;
        public DateTime CreatedAt;
        public DataStore DataStore;
        public string Description;
        public string FileName;
        public int LocationCount;
        public int MountCount;
        public DateTime MountedAt;
        public string Name;
        public OperatingSystem[] Oses;
        public string Path;
        public OperatingSystem PrimordialOs;
        public string ProvisonDuration;
        public int Size;
        public VolumeStatus Status;
        public string TemplateFileName;
        public string TemplateVersion;
        public Guid VolumeGuid;
        public int VolumeId;
    }

    public enum VolumeStatus
    {
	Unknown=0,
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
	Missing = 12
    }

    public enum EntityType
    {
	Unknown=0,
        User = 1,
        Computer = 2,
        Group = 3,
        OrgUnit = 4
    }

    public class OperatingSystem
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

    public enum DatastoreCategory
    {
        Unknown = 0,
        Local = 1,
        Shared = 2
        
    }
    public class Assignment
    {
        public DateTime EventTime;
        public string MountPrefix;
        public Volume Volume;
	public Entity Entity;
        
    }

    public class VolumeFile
    {
        public DateTime CreatedAt;
        public DataStore DataStore;
        public MachineManager MachineManager;
        public bool Missing;
        public string Name;
        public string Path;
        public bool Reachable;
        public Volume Volume;
    }

    public enum AgentStatus
    {
        Unknown=0,
        Green=1,
        GoodC=2,
        GoodW=3,
	Red=4
    }
    public enum ProvisioningStatus
    {
	Unknown=0,
	Available=1,
	PoweredOff=2, 
	Attached=3,
	InUse=4,
	Disabled=5,
	Inaccessible=6,
	Unlicensed=7
    }
    public class Entity
    {
        public int Id;
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
        public MachineManager MachineManager;
        public Guid uuid;
	public ProvisioningStatus ProvisioningStatus;
	public string DistignushedName;
    }
    public class Attachment
    {
	public AssignmentType AssignmentType;
	public Entity Computer;
	public Entity Entity;
	public DateTime AttachmentTime;
	public AttachmentType AttachmentType;
	public Volume AppStack;
	public VolumeFile File;
	
    }
    
    public enum	AttachmentType
    {
	Unknown=0,
	NonPersistent=1,
	Persistent=2
    }
    public enum AssignmentType
    {
	Unknown=0,
	Direct=1,
	Provisioning=2
	
    }
    
}
"@
}
#endregion Classes

Add-Type -LiteralPath "$psScriptRoot\AppVol.dll" 