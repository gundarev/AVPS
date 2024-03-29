#region Classes
Import-Module  Microsoft.PowerShell.Utility
if (-not $(Test-Path "$psScriptRoot\AppVol.dll")) 
{
Add-Type -OutputAssembly "$psScriptRoot\AppVol.dll"  -OutputType:Library -ReferencedAssemblies (Get-Module Microsoft.PowerShell.Utility).NestedModules[0].path @"
using System;
using System.Net;
using System.IO;

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

	public class VolumeMaintenance
	{
		public Entity Entity;
		public Volume Volume;
		public DirectoryInfo Share;
		public FileInfo Metadata;
		public string AgentVersion;
		public string CaptureVersion;
		public string TemplateVersion;
		public OperatingSystem PrimordialOs;
     
       
	}
	
        public class DataStoreConfig
    {
        public string AppStackDefaultPath;
        public DataStore AppStackDefaultStorage;
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
        return new MachineManager { Id = s };
    }
  
        public string AdapterType;
        public string Description;
        public int Id;
        public string Name;
        public bool Connected;
        public bool MountOnHost;
        public bool UseLocalVolumes;
        public bool ManageAcl;
        public string Type;
        public string UserName;
	public string HostUserName;
    }
    public class DataStore
    {
        public bool Accessible;
        public DatastoreCategory DatastoreCategory;
        public int Id;
        public string DatacenterName;
        public string Description;
        public string DisplayName;
        public string HostName;
        public MachineManager MachineManager;
        public string TextIdentifier;
        public string Name;
        public string Note;
        
    }
    public enum VolumeType
    {
	Unknown=0,
	AppStack=1,
	Writable=2
    }
    public class Volume
    {
        //Writable
	public string Owner;
	public EntityType OwnerType;
        public int FreeSpace;
	public bool BlockLogin;
	public bool DeferCreate;
        public string MountPrefix;
	public bool Protected;
	
	
	//AppStack
	public int ApplicationCount;
        public int LocationCount;
        public Guid VolumeGuid;
	public string AgentVersion;
        public string CaptureVersion;
        public string Parent;
	public string ProvisonDuration;
	public string ProvisioningComputer;
	
	//Shared
	public int Id;
	public string Name;
	public string Path;
        public DataStore DataStore;
        public string FileName;
	public string Description;
	public DateTime CreatedAt;
        public DateTime MountedAt;
        public VolumeStatus Status;
        public int Size;
        public string TemplateVersion;
        public int MountCount;
        public int AttachmentsTotal;
        public int AssignmentsTotal;
        public string TemplateFileName;
	public OperatingSystem[] Oses;
        public OperatingSystem PrimordialOs;
        public VolumeType VolumeType;
        
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
	//Shared
        public int Id;
 	public string SamAccountName;
        public string Domain;
        public string DisplayName;
        public int AppStacksAssigned;
        public DateTime LastLogin;
        public EntityType EntityType;
	public IntPtr Pointer;
	
	//  
	//ComputerUser
	public bool Enabled;
        public int WritablesAssigned;
        public int AppStacksAttached;
        public int NumLogins;
        
	//User
        
	//Computer
	public string AgentVersion;
        public ComputerType ComputerType;
	
	//Online
	public DateTime ConnectionTime;
        public AgentStatus AgentStatus;
        public IPAddress IPAddress;
        public Entity LastComputer;
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
    public enum OS
    {
Windows81x86,
Windows8x86,
WindowsServer2012R2x64,
WindowsServer2008x86,
Windows8x64,
WindowsServer2008R2x64,
Windows7x64,
WindowsServer2012x64,
Windows81x64,
Windows7x86,
WindowsServer2008x64

    }
}
"@
}
#endregion Classes

#Add-Type -LiteralPath "$($psScriptRoot)\AppVol.dll" 