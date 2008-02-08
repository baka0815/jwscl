{@abstract(This unit provides access to Terminal Server api functions through it's
 key object TJwTerminalServer)
@author(Remko Weijnen)
@created(10/26/2007)
@lastmod(10/26/2007)

Project JEDI Windows Security Code Library (JWSCL)

The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy of the
License at http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
ANY KIND, either express or implied. See the License for the specific language governing rights
and limitations under the License.

Alternatively, the contents of this file may be used under the terms of the
GNU Lesser General Public License (the  "LGPL License"), in which case the   
provisions of the LGPL License are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms   
of the LGPL License and not to allow others to use your version of this file 
under the MPL, indicate your decision by deleting  the provisions above and  
replace  them with the notice and other provisions required by the LGPL
License.  If you do not delete the provisions above, a recipient may use
your version of this file under either the MPL or the LGPL License.          

For more information about the LGPL: http://www.gnu.org/copyleft/lesser.html 

The Original Code is JwsclTerminalServer.pas.

The Initial Developer of the Original Code is Remko Weijnen.
Portions created by Remko Weijnen are Copyright (C) Remko Weijnen. All rights reserved.
}
{$IFNDEF SL_OMIT_SECTIONS}
unit JwsclTerminalServer;
{$I Jwscl.inc}

interface

uses Classes, Contnrs, DateUtils, SysUtils,
  JwaWindows,
  JwsclExceptions, JwsclResource, JwsclSid, JwsclTypes,
  JwsclUtils, JwsclToken,
  JwsclVersion, JwsclStrings;

{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_IMPLEMENTATION_SECTION}
type

  { forward declarations }
  TJwTerminalServer = class;
  TJwTerminalServerList = class;
  TJwWTSEventThread = class;
  TJwWTSEnumServersThread = class;
  TJwWTSSessionShadow = class;
  TJwWTSSession = class;
  TJwWTSSessionList = class;
  TJwWTSProcess = class;
  TJwWTSProcessList = class;

  {@Name is a pointer to a TJwTerminalServer instance}
  PJwTerminalServer = ^TJwTerminalServer;
  {@Abstract(@Name is the central object of JwsclTerminalServer and holds the session- and processlist.)

   @Name offers connection to a Terminal Server which you can specify with the
   Server property. Key functions of @Name are:@br
   @unorderedList(
   @item(EnumerateSessions enumerates all Terminal Server sessions into a
   TJwSessionList which can be accessed by the Sessions property.)
   @Item(EnumerateProcesses enumerates all Terminal Server processes into a
   TJwProcessList which can be accessed by the Processes property.)
   @Item(EnumerateServers enumerates all Terminal Servers in a domain.)
   @Item(Shutdown Shuts down and optionally restarts the specified
   Terminal Server.)
   )
   @br
   @Name also offers Events to monitor Terminal Server activity such as
   OnSessionConnect, OnSessionCreate, OnSessionLogon and OnSessionLogoff.@br
   @br@br
   The schema belows shows the relations between TJwTerminalServer,
   the TJwWTSSessionList with TJwWTSSessions and the TJwWTSProcessList with
   TjwWTSSessions.@br
   @br
   @image(.\..\documentation\TJwTerminalServer-Hierarchy.png)
  }
  TJwTerminalServer = class(TObject)
  protected
    {@exclude}
    FComputerName: TJwString;
    {@exclude}
    FConnected: Boolean;
    {@exclude}
    FData: Pointer;
    {@exclude}
    FEnumServersThread: TJwWTSEnumServersThread;
    {@exclude}
    FIdleProcessName: TJwString;
    {@exclude}
    FLastEventFlag: DWORD;
    {@exclude}
    FOnServersEnumerated: TNotifyEvent;
    {@exclude}
    FOnSessionConnect: TNotifyEvent;
    {@exclude}
    FOnSessionCreate: TNotifyEvent;
    {@exclude}
    FOnSessionDelete: TNotifyEvent;
    {@exclude}
    FOnSessionDisconnect: TNotifyEvent;
    {@exclude}
    FOnSessionEvent: TNotifyEvent;
    {@exclude}
    FOnLicenseStateChange: TNotifyEvent;
    {@exclude}
    FOnSessionLogon: TNotifyEvent;
    {@exclude}
    FOnSessionLogoff: TNotifyEvent;
    {@exclude}
    FOnSessionStateChange: TNotifyEvent;
    {@exclude}
    FOnWinStationRename: TNotifyEvent;
    {@exclude}
    FServerHandle: THandle;
    {@exclude}
//    FServerList: TStringList;
    {@exclude}
    FServers: TStringList;
    {@exclude}
    FSessions: TJwWTSSessionList;
    {@exclude}
    FProcesses: TJwWTSProcessList;
    {@exclude}
    FTerminalServerEventThread: TJwWTSEventThread;
    {@exclude}
    FServer: TJwString;
    {@exclude}
    FTag: Integer;

    {@exclude}
    function GetIdleProcessName: TJwString;
    {@exclude}
    function GetServers: TStringList;
    {@exclude}
    function GetServer: TJwString;
    {@exclude}
    function GetWinStationName(const SessionId: DWORD): TJwString;
    {@exclude}
    procedure OnEnumServersThreadTerminate(Sender: TObject);
    {@exclude}
    procedure SetServer(const Value: TJwString);
    {@exclude}
    procedure FireEvent(EventFlag: DWORD);
  public

    {@Name sets up the connection with the Terminal Server.@br
     The Connected property can be used to check if we're already connected.
     @raises(EJwsclWinCallFailedException will be raised if the connection
     attempt was unsuccessfull)
     @br@br
     @bold(Remarks:) EnumerateSessions and EnumerateProcesses will automatically
     connected to the Terminal Server when needed.
     }
    procedure Connect;

    {@Name allows storage of a pointer to user specific data and can be freely
     used.@br
     @br
     Example:
     @longcode(#
     var
       ATerminalServer: TJwTerminalServer;
     begin
       s: String;
       s := 'Remember this text';

       ATerminalServer.Data := PChar(s);
       s := '';
       ...
       s := ATerminalServer.Data;

       ATerminalServer.Free;
     end
     #)
     }
    property Data: Pointer read FData write FData;

    {@Name will disconnect an existing connection to the Terminal Server.@br
     The Connected property can be used to check if we're already connected.
     @bold(Remarks:) Disconnecting will prevent receiving session events!
     }
    procedure Disconnect;

    {@Name returns the local computername
    }
    property ComputerName: TJwString read FComputerName;

    {@Name indicates if we are connected to the Terminal Server
    }
    property Connected: Boolean read FConnected;

    {@Name Creates a TJwTerminalServer instance.@br
     @br
     Example:
     @longcode(#
     var
       ATerminalServer: TJwTerminalServer;
       i: Integer;
     begin
       ATerminalServer := TjwTerminalServer.Create;
       ATerminalServer.Server := 'TS001';

       if ATerminalServer.EnumerateProcesses then
       begin

         for i := 0 to ATerminalServer.Processes.Count - 1 do
         begin
           Memo1.Lines.Add(ATerminalServer.Sessions[i].Username);
         end;

         end;
     end;
    #)
    }
    constructor Create;
    destructor Destroy; override;

    {@Name Enumerates all processes on the Terminal Server and fills the
     Processes property with a TJwProcessList. This list contains all processes
     and their properties such as Process Name, Process Id, Username, Memory
     Usage and so on.
    }
    function EnumerateProcesses: Boolean;

    {@Name Enumerates all Terminal Servers in the specified domain.
     @Param(ADomain name of the Domain to be queried, if empty string is
     specified the current domain is queried)
     @br@br
     @bold(Remarks:) This functions enumerates all Terminal Servers that
     advertise themselves on the network. By default only Terminal Servers in
     Application Mode advertise themselves. You can override this behaviour by
     modifying the following registry key:
     @longcode(#
     HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server
     "TSAdvertise" = REG_DWORD:1
     #)
     @br
     @br@br
     Please note that enumerating Terminal Servers in large environments might
     take some time (especially over slow WAN links). Therefore this function
     runs in a seperate thread and signals the OnServersEnumerated Event.@br
     The enumerated servers can be retreived by reading the Servers property.@br
     @br
     If the TJwTerminalServer Instance is destroyed and the enumeration thread
     is still busy, the TJwTerminalServer will wait max. 1 second for the thread
     to finish and then terminates it.
    }
    function EnumerateServers(ADomain: String):Boolean;

    {@Name Enumerates all sessions on the Terminal Server and fills the
     Sessions property with a TJwSessionList. This list contains all sessions
     and their properties such as Username, Session Id, Connection State, Idle
     Time and son on.
    }
    function EnumerateSessions: boolean;
    {@exclude}
    function FileTime2DateTime(FileTime: TFileTime): TDateTime;
    {@exclude}
    property IdleProcessName: TJwString read GetIdleProcessName;
    {@exclude}
    property LastEventFlag: DWORD read FLastEventFlag;

    {The @Name event signals that the Server Enumeration thread has finished.@br
     The Enumerated Servers can be read through the Servers property
    }
    property OnServersEnumerated: TNotifyEvent read FOnServersEnumerated write FOnServersEnumerated;

    {The @Name is a generic event which is fired if anything happens that is
     session related, like statechange, logon/logoff, disconnect and (re)connect.
     @br@br
     The table below shows which Terminal Server event triggers which event:@br
     @image(.\..\documentation\TJwWTSEvents-Table.png)
    }
    property OnSessionEvent: TNotifyEvent read FOnSessionEvent write FOnSessionEvent;

    {The @Name event is fired when a client connected to a session
     @seealso(OnSessionEvent for an overview of which events are triggered and
     when)
    }
    property OnSessionConnect: TNotifyEvent read FOnSessionConnect write FOnSessionConnect;

    {The @Name event is fired when a session is created
     @seealso(OnSessionEvent for an overview of which events are triggered and
     when)
    }
    property OnSessionCreate: TNotifyEvent read FOnSessionCreate write FOnSessionCreate;

    {The @Name event is fired when a session is deleted
     @seealso(OnSessionEvent for an overview of which events are triggered and
     when)
    }
    property OnSessionDelete: TNotifyEvent read FOnSessionDelete write FOnSessionDelete;

    {The @Name event is fired when a session is disconnected
     @seealso(OnSessionEvent for an overview of which events are triggered and
     when)
    }
    property OnSessionDisconnect: TNotifyEvent read FOnSessionDisconnect write FOnSessionDisconnect;

    {The @Name event is fired when when a license is added or deleted using
     License Manager.
     @seealso(OnSessionEvent for an overview of which events are triggered and
     when)
    }
    property OnLicenseStateChange: TNotifyEvent read FOnLicenseStateChange write FOnLicenseStateChange;

    {The @Name event is fired when a client logs on either through the console
     or a session
     @seealso(OnSessionEvent for an overview of which events are triggered and
     when)
    }
    property OnSessionLogon: TNotifyEvent read FOnSessionLogon write FOnSessionLogon;

    {The @Name event is fired when a client logs off either from the console
     or a session
     @seealso(OnSessionEvent for an overview of which events are triggered and
     when)
    }
    property OnSessionLogoff: TNotifyEvent read FOnSessionLogoff write FOnSessionLogoff;

    {The @Name event is fired when an existing session has been renamed
     @seealso(OnSessionEvent for an overview of which events are triggered and
     when)
    }
    property OnWinStationRename: TNotifyEvent read FOnWinStationRename write FOnWinStationRename;

    {The @Name event is fired when the connectstate of a session has changed
     @seealso(OnSessionEvent for an overview of which events are triggered and
     when)
    }
    property OnSessionStateChange: TNotifyEvent read FOnSessionStateChange write FOnSessionStateChange;

    {@Name contains a TJwWTSProcessList of which each item contains a
     TJwWTSProcess. This processlist contains all enumerated processes
     and their properties such as Process Name, Process Id, Username, Memory
     Usage and so on.
     @br@br
     @bold(Remarks:) The Processlist is filled by calling the EnumerateProcesses
     function.
    }
    property Processes: TJwWTSProcessList read FProcesses write FProcesses;

    {@Name the netbios name of the Terminal Server.@br
     @br
     @bold(Remarks:) If you want to connect to a Terminal Server locally
     you should not specify the server name. Please note that in the case of a
     local connection this property @bold(will return the computername))
     @br@br
     Note that Windows XP SP 2 by default does not allow remote
     RPC connection to Terminal Server (enumerating sessions and processes).@br
     You can change this behaviour by creating the following registry entry
     on the XP machine:@br
     @br
     @longcode(#
     HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server
     "AllowRemoteRPC" = REG_DWORD:1
     #)
     @br
     Also make sure that the Windows firewall on the client is configured to
     allow File and Print sharing, as well as Remote Desktop.
    }
    property Server: TJwString read GetServer write SetServer;
    {@exclude}
    property ServerHandle: THandle read FServerHandle;

    {@Name Contains the list of Enumerated Terminal Servers
     @seealso(EnumerateServers)
     }
    property Servers: TStringList read GetServers;

    {@Name contains a TJwWTSSessionList of which each item contains a
     TJwWTSSession. This sessionlist contains all enumerated sessions
     and their properties such as Username, Connection State, Idle Time and so
     on.
     @br@br
     @bold(Remarks:) The Sessionlist is filled by calling the EnumerateSessions
     function.
    }
    property Sessions: TJwWTSSessionList read FSessions write FSessions;
    {@Name shuts down (and optionally restarts) the specified terminal server.@br
     @Param AShutdownFlag can be one of the following values:
     @table(
     @rowHead(  @cell(Value) @cell(Meaning))
      @row(     @cell(WTS_WSD_LOGOFF) @cell(Forces all client sessions to log off (except the session calling WTSShutdownSystem) and disables any subsequent remote logons. This can be used as a preliminary step before shutting down. Logons will be re-enabled when the terminal services service is restarted. Use this value only on the Terminal Services console.))
      @row(     @cell(WTS_WSD_POWEROFF) @cell(Shuts down the system on the terminal server and, on computers that support software control of AC power, turns off the power. This is equivalent to calling ExitWindowsEx with EWX_SHUTDOWN and EWX_POWEROFF. The calling process must have the SE_SHUTDOWN_NAME privilege enabled.))
      @row(     @cell(WTS_WSD_REBOOT) @cell(Shuts down and then restarts the system on the terminal server. This is equivalent to calling ExitWindowsEx with EWX_REBOOT. The calling process must have the SE_SHUTDOWN_NAME privilege enabled.))
      @row(     @cell(WTS_WSD_SHUTDOWN) @cell(Shuts down the system on the terminal server. This is equivalent to calling the ExitWindowsEx function with EWX_SHUTDOWN. The calling process must have the SE_SHUTDOWN_NAME privilege enabled.))
      @row(     @cell(WTS_WSD_FASTREBOOT) @cell(This value is not supported currently.))
      )
    }
    function Shutdown(AShutdownFlag: DWORD): Boolean;

    {@Name has no predefined meaning. The Tag property is provided for the
     convenience of developers. It can be used for storing an additional integer
     value or it can be typecast to any 32-bit value such as a component
     reference or a pointer.
    }
    property Tag: Integer read FTag write FTag;
  end;

  {@Name is a pointer to a TJwTerminalServerList}
  PJwTerminalServerList = ^TJwTerminalServerList;
  {@Abstract(@Name is a List of TJwTerminalServer Objects.)

   Each item in the list points to a TJwTerminalServer object that can be queried
   and manipulated.@br
   The list can be filled by adding TJwTerminalServer instances.@br
   Example:
   @longcode(#
   var
     ATerminalServerList : TjwTerminalServerList;
     ATerminalServer : TJwTerminalServer;
   begin
     ATerminalServerList := TjwTerminalServerList.Create;

     ATerminalServer := TJwTerminalServer.Create;
     ATerminalServerList.Add(ATerminalServer);

     ATerminalServerList.Free;
   end;
   #)
  }
  TJwTerminalServerList = class(TObjectList)
  protected
    FOwnsObjects: Boolean;
    FOwner: TComponent;
  protected
    function GetItem(Index: Integer): TJwTerminalServer;
    procedure SetItem(Index: Integer; ATerminalServer: TJwTerminalServer);
    procedure SetOwner(const Value: TComponent);
  public
    destructor Destroy; reintroduce;
    function Add(ATerminalServer: TJwTerminalServer): Integer;
    {@Name Looks up a Terminal Server in the List by Servername}
    function FindByServer(const ServerName: WideString; const IgnoreCase: boolean = False): TJwTerminalServer;
    function IndexOf(ATerminalServer: TJwTerminalServer): Integer;
    procedure Insert(Index: Integer; ATerminalServer: TJwTerminalServer);
    property Items[Index: Integer]: TJwTerminalServer read GetItem write SetItem; default;
    property Owner: TComponent read FOwner write SetOwner;
    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
    function Remove(ATerminalServer: TJwTerminalServer): Integer;
  end;


   {@Abstract(The @Name Thread waits for Terminal Server Events and notifies the
    caller by firing Events.)

    It's not necessary to manually create an @Name Thread because
    TJwTerminalServer does this automatically after a successfull call to the
    EnumerateSessions function.@br
    @br
    @Name is Owned by a TJwTerminalServer instance
    @br@br
    @bold(Remarks:) @Name uses the WTSWaitSystemEvent API Call which can hang
    on Windows Vista after sending a WTS_FLUSH event. The bug was first
    corrected in winsta.dll version 6.0.6000.20664.@br
    @br
    See also: http://www.remkoweijnen.nl/blog/2008/01/25/using-wtswaitsystemevent/
  }
  TJwWTSEventThread = class(TJwThread)
  protected
    FOwner: TJwTerminalServer;
    FEventFlag: DWORD;
    procedure DispatchEvent;
  public
    {Call @Name to create a @classname Thread.
     @Param(CreateSuspended If CreateSuspended is False, Execute is called
     immediately. If CreateSuspended is True, Execute won't be called until
     after Resume is called.)
     @Param(Owner Specifies the TJwTerminalServer instance that owns the thread)
    }
    constructor Create(CreateSuspended: Boolean; AOwner: TJwTerminalServer);
    procedure Execute; override;
  end;

  {@Abstract(@Name is a Thread that enumerates all Terminal Server in the
   specified domain.)

   The Enumeration is done from a thread because it can take some time to
   enumerate all server, especially over a slow WAN connection.@br
   @br
   The thread is created by calling the EnumerateServers procedure from a
   TJwTerminalServer instance. Although allowed you normally don't create
   a TJwWTSEnumServersThread manually.
   @br@br
   Enumerated servers are returned by firing the OnServerEnumerated Event
   from the parent TJwTerminalServer instance.
   @br@br
   A TJwWTSEnumServersThread is owned by a TJwTerminalServer instance.
   }
  TJwWTSEnumServersThread = class(TJwThread)
  protected
    FDomain: TJwString;
    FOwner: TJwTerminalServer;
    FServer: TJwString;
    FTerminatedEvent: THandle;
    procedure AddToServerList;
    procedure ClearServerList;
    procedure DispatchEvent;
  public
    {Call @Name to create a @classname Thread.
     @Param(CreateSuspended If CreateSuspended is False, Execute is called
     immediately. If CreateSuspended is True, Execute won't be called until
     after Resume is called.)
     @Param(Owner Specifies the TJwTerminalServer instance that owns the thread)
     @Param(Domain Specifies the Domain that should be Enumerated. if you want
     to Enumerate the current domain (from a domain member) you can specify an
     empty string)
    }
    constructor Create(CreateSuspended: Boolean; Owner: TJwTerminalServer;
      Domain: TJwString);
    procedure Execute; override;
//    procedure Wait;
//    function WaitFor: LongWord;
  end;

  {@Name is a pointer to a TJwWTSSession}
  PJwWTSSession = ^TJwWTSSession;

  {@abstract(@Name is a Class that encapsulates a Terminal Server session and
   it's properties)

   A session is uniquely identified with a SessionID, this is a number
   between 0 and 65535.@br
   @br
   A TJwWTSSession is owned by a JTwWTSSessionList.
   }
  TJwWTSSession = class(TObject)
  protected
    {@exclude}
    FApplicationName: TJwString;
    {@exclude}
    FClientAddress: TJwString;
    {@exclude}
    FClientBuildNumber: DWORD;
    {@exclude}
    FColorDepth: DWORD;
    {@exclude}
    FClientDirectory: TJwString;
    {@exclude}
    FClientHardwareId: DWORD;
    {@exclude}
    FClientName: TJwString;
    {@exclude}
    FClientProductId: WORD;
    {@exclude}
    FClientProtocolType: WORD;
    {@exclude}
    FClientProtocolStr: TJwString;
    {@exclude}
    FCompressionRatio: TJwString;
    {@exclude}
    FConnectState: TWtsConnectStateClass;
    {@exclude}
    FConnectStateStr: TJwString;
    {@exclude}
    FConnectTime: TDateTime;
    {@exclude}
    FCurrentTime: TDateTime;
    {@exclude}
    FDisconnectTime: TDateTime;
    {@exclude}
    FDomain: TJwString;
    {@exclude}
    FIdleTime: Int64;
    {@exclude}
    FIdleTimeStr: TJwString;
    {@exclude}
    FIncomingBytes: DWORD;
    {@exclude}
    FIncomingCompressedBytes: DWORD;
    {@exclude}
    FIncomingFrames: DWORD;
    {@exclude}
    FHorizontalResolution: DWORD;
    {@exclude}
    FInitialProgram: TJwString;
    {@exclude}
    FLastInputTime: TDateTime;
    {@exclude}
    FLogonTime: Int64;
    {@exclude}
    FLogonTimeStr: TJwString;
    {@exclude}
    FOwner: TJwWTSSessionList;
    {@exclude}
    FOutgoingBytes: DWORD;
    {@exclude}
    FOutgoingCompressBytes: DWORD;
    {@exclude}
    FOutgoingFrames: DWORD;
    {@exclude}
    FProtocolTypeStr: TJwString;
    {@exclude}
    FRemoteAddress: TJwString;
    {@exclude}
    FRemotePort: WORD;
    {@exclude}
    FSessionId: TJwSessionId;
    {@exclude}
    FUsername: TJwString;
    {@exclude}
    FVerticalResolution: DWORD;
    {@exclude}
    FWdFlag: DWORD;
    {@exclude}
    FWdName: TJwString;
    {@exclude}
    FWinStationName: TJwString;
    {@exclude}
    FWorkingDirectory: TJwString;
    {@exclude}
    FShadow : TJwWTSSessionShadow;
    {@exclude}

    {@exclude}
    FToken : TJwSecurityToken;
    {@exclude}
    FUserSid : TJwSecurityID;

    {@exclude}
    procedure GetClientDisplay;
    {@exclude}
    function GetServer: TJwString;
    {@exclude}
    function GetSessionInfoDWORD(const WTSInfoClass: WTS_INFO_CLASS): DWORD;
    {@exclude}
    procedure GetSessionInfoPtr(const WTSInfoClass: WTS_INFO_CLASS;
      var ABuffer: Pointer);
    {@exclude}
    function GetSessionInfoStr(const WTSInfoClass: WTS_INFO_CLASS): TJwString;
    {@exclude}
    procedure GetWinStationInformation;
    {@exclude}
    procedure GetWinStationDriver;

    {@exclude}
    function GetToken : TJwSecurityToken;
    {@exclude}
    function GetUserSid : TJwSecurityID;

  public
    {The @Name constructor creates a TJwWTSSession instance and allocates memory for it
     @Param(Owner Specifies the TJwTerminalServer instance that owns the session)
     @Param(SessionId The Session Identifier)
     @Param(WinStationName The Session Name)
     @Param(ConnectState The current connection state of the session)
     @br@br
     @bold(Remarks:) It's not necessary to manually create a session instance.
     Enumerating sessions with the EnumerateSessions function will create a
     SessionList filled with Sessions.
     @seealso(EnumerateSessions)
    }
    constructor Create(const Owner: TJwWTSSessionList;
      const SessionId: TJwSessionId; const WinStationName: TJwString;
      const ConnectState: TWtsConnectStateClass);

    {The @Name destructor disposes the Session object.
     @br@br
     @bold(Remarks:) Since a session is Owned by a SessionList by default
     @bold(you should not destroy/free a session manually). The only scenario
     where a sessions would need to be freed is when you manually create a
     sessionlist and specify False for the OwnsObject parameter.
    }
    destructor Destroy; override;

    {@Name returns the the startup application as specified in the
     Terminal Server client. If no startup application was specified
     an empty string is returned.
     @br@br
     @bold(Remarks:) Console sessions always returns empty value.
     }
    property ApplicationName: TJwString read FApplicationName;

    {@Name returns the Client IP Address as string. This is the local IP
     address of a client as reported by the Terminal Server Client
     @br@br
     @bold(Remarks:) Console sessions always returns empty value.
     }
    property ClientAddress: TJwString read FClientAddress;

    {@Name returns the version number of the Terminal Server Client
     @br@br
     @bold(Remarks:) Console sessions always returns empty value.
     @seealso(RemoteAddress)
     @seealso(RemotePort)
     }
     property ClientBuildNumber: DWORD read FClientBuildNumber;

    {@Name returns the version number of the Terminal Server Client
     @br@br
     @bold(Remarks:) Console sessions always returns empty value.
     }
    property ClientDirectory: TJwString read FClientDirectory;

    {@Name returns a client-specific hardware identifier
     @br@br
     @bold(Remarks:) Console sessions always returns empty value.
     }
    property ClientHardwareId: DWORD read FClientHardwareId;

    {@Name returns the local computer name of the client
     @br@br
     @bold(Remarks:) Console sessions always returns empty value.
     }
    property ClientName: TJwString read FClientName;

    {@Name returns a client-specific product identifier.
     @br@br
     @bold(Remarks:) Console sessions always returns empty value.
     }
    property ClientProductId: WORD read FClientProductId;

    {@Name returns a value that indicates the protocol type
     This is one of the following values:
     @table(
     @rowHead(  @cell(ClientProtocolType) @cell(Meaning))
      @row(     @cell(WTS_PROTOCOL_TYPE_CONSOLE) @cell(The Console session))
      @row(     @cell(WTS_PROTOCOL_TYPE_ICA) @cell(The ICA protocol))
      @row(     @cell(WTS_PROTOCOL_TYPE_RDP) @cell(The RDP protocol))
      )
     @seealso(ClientProtocolStr)
     @seealso(RemoteAddress)
     @seealso(RemotePort)
      }
    property ClientProtocolType: WORD read FClientProtocolType;

    {@Name returns a string  that indicates the protocol type
     This is one of the following values:
     @table(
     @rowHead(  @cell(ClientProtocolType) @cell(Value))
      @row(     @cell(WTS_PROTOCOL_TYPE_CONSOLE) @cell(Console))
      @row(     @cell(WTS_PROTOCOL_TYPE_ICA) @cell(ICA))
      @row(     @cell(WTS_PROTOCOL_TYPE_RDP) @cell(RDP))
      )
     @seealso(ClientProtocolType)
     @seealso(RemoteAddress)
     @seealso(RemotePort)
      }
    property ClientProtocolStr: TJwString read FClientProtocolStr;

    property ColorDepth: DWORD read FColorDepth;

    {@Name returns the current compression ratio as string with 2 decimals.
     Compression Ratio equals OutgoingCompressBytes / OutgoingBytescompressed
     Console sessions always returns empty value.
     @br@br
     @seealso(IncomingBytes)
     @seealso(OutgoingBytes)
    }
    property CompressionRatio: TJwString read FCompressionRatio;

    {@Name returns the connection state of the session. Which can be one of the
     following values:
     @unorderedList(
      @itemSpacing Compact
      @item(WTSActive)
      @item(WTSConnected)
      @item(WTSConnectQuery)
      @item(WTSShadow)
      @item(WTSDisconnected)
      @item(WTSIdle)
      @item(WTSListen)
      @item(WTSReset)
      @item(WTSDown)
      @item(WTSInit)
     )
     @br
     @bold(Remarks:) On Windows XP, however, the state for session 0 can be
     misleading because it will be WTSDisconnected even if there is no user
     logged on. To accurately determine if a user has logged on to session 0,
     you can use the Username property
    @br
    http://support.microsoft.com/kb/307642/en-us
    }
    property ConnectState: TWtsConnectStateClass read FConnectState;
    {@Name returns a localised connection state string.
     }
    property ConnectStateStr: TJwString read FConnectStateStr;

    {@Name The most recent client connection time.
     }
    property ConnectTime: TDateTime read FConnectTime;

    {@Name The time that the TJwWTSSession info was queried. This can be
     used to calculate time differences such as idle time
     }
    property CurrentTime: TDateTime read FCurrentTime;

    {The @Name function disconnects the logged-on user
     from the specified Terminal Services session without closing the session.
     If the user subsequently logs on to the same terminal server, the user is
     reconnected to the same session.
     @param(bWait Indicates whether the operation is synchronous. Specify TRUE
     to wait for the operation to complete, or FALSE to return immediately.)
     @returns(If the function fails you can use GetLastError to get extended
     error information)
     }
    function Disconnect(bWait: Boolean): Boolean;

    {@Name The last client disconnection time.
    }
    property DisconnectTime: TDateTime read FDisconnectTime;
    {@Name the domain of the logged-on user
    }
    property Domain: TJwString read FDomain;

    {@exclude}
    function GetClientAddress: TJwString;

    {@exclude}
    function GetServerHandle: THandle;
    property HorizontalResolution: DWORD read FHorizontalResolution;

    {@Name The elapsed time (relative to CurrentTime) since last user input in
     the session expressed in the number of 100-nanosecond intervals since
     January 1, 1601 (TFileTime).
     @br@br
     @bold(Remarks:) Please note the following remarks about Idle Time:@br
     A disconnected session is Idle since DisconnectTime. A session without a
     user is never idle, usually these are special sessions like Listener,
     Services or console session.@br
     IdleTimeStr returns a convenient formatted idle time string
     which can be used for displaying. This value is more convenient however for
     calculations such as sorting or comparing idle times.
     @seealso(IdleTimeStr)
    }
    property IdleTime: Int64 read FIdleTime;

    {@Name The elapsed time (relative to CurrentTime) since last user input in
     the session as formatted string. The string is formatted according to the
     table below:
     @table(
     @rowHead(  @cell(days) @cell(hours) @cell(minutes) @cell(value))
      @row(     @cell(> 0)  @cell(any)   @cell(any)     @cell(+d+hh:mm))
      @row(     @cell(0)    @cell(>0)    @cell(any)     @cell(hh:mm))
      @row(     @cell(0)    @cell(0)     @cell(any)     @cell(mm))
      @row(     @cell(0)    @cell(0)     @cell(0)       @cell(.))
      )
     @br@br
     @bold(Remarks:) Please note the following remarks about Idle Time:@br
     A disconnected session is Idle since DisconnectTime. A session without a
     user is never idle, usually these are special sessions like Listener,
     Services or console session.
     @seealso(IdleTimeStr)
     @seealso(CurrentTime)
    }
    property IdleTimeStr: TJwString read FIdleTimeStr;

    {@Name Uncompressed Remote Desktop Protocol (RDP) data from the client
     to the server.
     @bold(Remarks:) This value is not returned for console sessions.
     @seealso(OutgoingBytes)
     @seealso(CompressionRatio)
    }
    property IncomingBytes: DWORD read FIncomingBytes;

    {@Name string containing the name of the initial program that
     Terminal Services runs when the user logs on.
    }
    property InitialProgram: TJwString read FInitialProgram;

    {@Name The time of the last user input in the session.
    }
    property LastInputTime: TDateTime read FLastInputTime;

    {The @Name function logs off a specified Terminal Services session
     @param(bWait Indicates whether the operation is synchronous. Specify TRUE
     to wait for the operation to complete, or FALSE to return immediately.)
     @returns(If the function fails you can use GetLastError to get extended
     error information)
     }
    function Logoff(bWait: Boolean): Boolean;

    {@Name The time that the user logged on to the session in the number
     of 100-nanosecond intervals since January 1, 1601 (TFileTime).
     @seealso(LogonTimeStr)
    }
    property LogonTime: Int64 read FLogonTime;

    {@Name The time that the user logged on to the session as a localised
     Date Time string.
     @seealso(LogonTime)
    }
    property LogonTimeStr: TJwString read FLogonTimeStr;

    {@Name of this session object, which can only be a TJwWTSSessionList
    }
    property Owner: TJwWTSSessionList read FOwner write FOwner;
    {@Name Uncompressed RDP data from the server to the client.
     @br@br
     @bold(Remarks:) This value is not returned for console sessions.
     @seealso(IncomingBytes)
     @seealso(CompressionRatio)
    }
    property OutgoingBytes: DWORD read FOutgoingBytes;

    {The @Name function displays a message box on the client desktop.
     @param(AMessage: string that contains the message to be displayed)
     @param(ACaption: string that contains the dialog box title.)
     @param(uType: Specifies the contents and behavior of the message box.
     This value is typically MB_OK. For a complete list of values, see the
     uType parameter of the MessageBox function.)
     @br
     @returns(If the function fails you can use GetLastError to get extended
     error information)
     @br@br
     @bold(Remarks:) PostMessage does not wait for the user to respond.
     @seealso(SendMessage)
    }
    function PostMessage(const AMessage: TJwString; const ACaption: TJwString;
      const uType: DWORD): DWORD;

    {@exclude}
    function ProtocolTypeToStr(const AProtocolType: DWORD): TJwString;

    {@Name returns the real IP Address that is connected to the Terminal Server.
     @br@br
     @bold(Remarks:) @Name returns the IP address that is actually connected
     to the Terminal Server (as opposed to ClientAddress which returns the
     address as reported by the client which is usually just it's local ip
     address).@br
     @Name is the same adddress you will see when you examine netstat output@br
     @longcode(#
     C:\Documents and Settings\Remko>netstat -n | find /i "3389"
     TCP    192.168.2.2:3389       192.168.2.3:4096       ESTABLISHED
     #)
     In the output above, 192.168.2.2 is the IP Address of the Terminal Server
     which listens on port 3389. It has currently one Session from Remote IP
     192.168.2.3 on TCP port 4096. The @Name property is usefull because netstat
     cannot relate a connection to a Session Id.@br
     If you want to convert the to IP Address to a sockaddr structure you can
     use the WSAStringToAddress API.
     @seealso(RemotePort)
    }
    property RemoteAddress: TJwString read FRemoteAddress;

    {@Name returns the Remote Port number which is is connected to the
     Terminal Server. The Terminal Server listens (by default) on port 3389
     but the client connects with a random available port.
     @Name is the same port number you will see when you examine netstat output@br
     @longcode(#
     C:\Documents and Settings\Remko>netstat -n | find /i "3389"
     TCP    192.168.2.2:3389       192.168.2.3:4096       ESTABLISHED
     #)
     In the output above, 192.168.2.2 is the IP Address of the Terminal Server
     which listens on port 3389. It has currently one Session from Remote IP
     192.168.2.3 on TCP port 4096. The RemoteAddress and @Name properties are
     usefull because netstat cannot relate a connection to a Session Id.@br
     @seealso(RemoteAddress)
    }
    property RemotePort: WORD read FRemotePort;

    {The @Name function displays a message box on the client desktop.
     @param(AMessage string that contains the message to be displayed.)
     @param(ACaption string that contains the dialog box title.)
     @param(uType Specifies the contents and behavior of the message box.
     This value is typically MB_OK. For a complete list of values, see the
     uType parameter of the MessageBox function.)
     @param(ATimeOut Specifies the time, in seconds, that the SendMessage
     function waits for the user's response. If the user does not respond within
     the time-out interval, the pResponse parameter returns IDTIMEOUT.
     If the Timeout parameter is zero, WTSSendMessage will wait indefinitely
     for the user to respond.)
     @return(@Name returns the user's response, which can be one of the
     following values:
     @table(
     @rowHead(  @cell(Value) @cell(Meaning))
      @row(     @cell(IDABORT) @cell(Abort button was selected.))
      @row(     @cell(IDCANCEL) @cell(Cancel button was selected.))
      @row(     @cell(IDIGNORE) @cell(Ignore button was selected.))
      @row(     @cell(IDNO) @cell(No button was selected.))
      @row(     @cell(IDRETRY) @cell(Retry button was selected.))
      @row(     @cell(IDYES) @cell(Yes button was selected.))
      @row(     @cell(IDASYNC) @cell(The bWait parameter was FALSE, so the function returned without waiting for a response.))
      @row(     @cell(IDTIMEOUT) @cell(The bWait parameter was TRUE and the time-out interval elapsed.))
      ))
     @br
     @returns(If the function fails you can use GetLastError to get extended
     error information)
     @br@br
     @bold(Remarks:) If you don't need to wait for the user's response you can
     use the PostMessage function
     @seealso(PostMessage)
    }
    function SendMessage(const AMessage: TJwString; const ACaption: TJwString;
      const uType: DWORD; const ATimeOut: DWORD): DWORD;

    {@Name the netbios name of the Terminal Server.
     @br@br
     @bold(Remarks:) If you want to connect to a Terminal Server locally
     you should not specify the server name. Please note that in the case of a
     local connection this property @bold(will return the computername))
    }
    property Server: TJwString read GetServer;

    {@Name the session identifier
    }
    property SessionId: TJwSessionId read FSessionId;
    {The @Name function starts the remote control of another Terminal Services
     session. You must call this function from a remote session.
     @Return(If the function fails, the return value is zero. To get extended
     error information, call GetLastError)
     @br@br
     @bold(Remarks:) By default the console session cannot be shadowed. You can
     change this by modifying the following registry keys:
     @longcode(#
     HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\Console
     "fInheritShadow" = REG_DWORD:1
     "Shadow" = REG_DWORD:1
     #)
     Where Shadow can be one of the TShadowMode values.
     @seealso(ShadowInformation)
     @seealso(TShadowMode)
     @see(TShadowState)
    }
    function Shadow: boolean;

    {@Name returns information about the Shadow State and Shadow Mode of
    a session.
    @br
    Shadow State shows if the session is shadowing another session or is being
    shadowed by another session.
    @br@br
    Shadow Mode queries the shadow permissions for this session.
    @seealso(Shadow)
    @seealso(TShadowMode)
    @see(TShadowState)
    }
    property ShadowInformation: TJwWTSSessionShadow read FShadow;

    {@Name the name of the user associated with the session.
    }
    property Username: TJwString read FUsername;

    property VerticalResolution: DWORD read FVerticalResolution;

    {WinStationDriver Flag (@Name) returns a value indicating the protocol and
     connection type. It's usefull for easy determination of console session.
     Possible values:
     @table(
     @rowHead(  @cell(Value) @cell(Meaning))
      @row(     @cell(WD_FLAG_CONSOLE_XP) @cell(XP Console sessions))
      @row(     @cell(WD_FLAG_CONSOLE) @cell(2003/2008 Console Session))
      @row(     @cell(WD_FLAG_RDP) @cell(RDP Session))
      @row(     @cell(WD_FLAG_ICA) @cell(ICA Session))
      ))
    }
    property WdFlag: DWORD read FWdFlag;

    {WinStationDriver Name (@Name) returns a value indicating the protocol and
     protocol type.
     Known Microsoft values:
     @table(
     @rowHead(  @cell(Operating System) @cell(Value))
      @row(     @cell(Windows 2000) @cell(Microsoft RDP 5.0))
      @row(     @cell(Windows XP) @cell(Microsoft RDP 5.1))
      @row(     @cell(Windows 2003) @cell(Microsoft RDP 5.2))
      @row(     @cell(Windows 2008/Vista) @cell(Microsoft RDP 6.0))
      )
     Known Citrix values:
     @table(
     @rowHead(  @cell(Version) @cell(Value))
      @row(     @cell(Citrix Presentation Server 4) @cell(Citrix ICA 3.0))
      )

    }
    property WinStationDriverName: TJwString read FWdName;

    {@Name returns the session name.
     @br@br
     @bold(Remarks:) Despite its name, specifying this property does not return
     the window station name. Rather, it returns the name of the Terminal
     Services session.@br
     For RDP this will be something like RDP-Tcp#023@br
     For ICA this will be something like ICA-tcp#014
         }
    property WinStationName: TJwString read FWinStationName;

    {@Name the default directory used when launching the initial program.}
    property WorkingDirectory: TJwString read FWorkingDirectory;

    {@Name returns the token of the session.
     This call needs the TCB privilege and the process must run under
     SYSTEM account; otherwise EJwsclPrivilegeCheckException,
     EJwsclWinCallFailedException is raised.
     The returned value is cached and must not be freed!



    }
    property Token : TJwSecurityToken read GetToken;

    {@Name returns the logged on User of the session.
    This call needs the TCB privilege and the process must run under
     SYSTEM account; otherwise EJwsclPrivilegeCheckException,
     EJwsclWinCallFailedException is raised.

     The returned value is cached and must not be freed!

     If the value cannot be obtained the return value is nil.
    }
    property UserSid : TJwSecurityID read GetUserSid;
  end;

  {@Name is a pointer to a TJwWTSSessionList}
  PJwWTSSessionList = ^TJwWTSSessionList;
  {@Abstract(@Name is a List of all Sessions running on the Terminal Server
   and their properties)

   Each item in the list points to a TJwWTSSession object that can be queried
   and manipulated.@br
   The list is filled by calling the EnumerateSessions function of the owning
   TJwTerminalServer instance.@br
   @br
   Example:
   @longCode(#
   var
     ATerminalServer : TjwTerminalServer;
   begin
     ATerminalServer := TjwTerminalServer.Create;
     ATerminalServer.Server := 'TS001';

     if ATerminalServer.EnumerateSessions then
     begin

       for i := 0 to ATerminalServer.Sessions.Count - 1 do
       begin
         Memo1.Lines.Add(ATerminalServer.Sessions[i].Username);
       end;

     end;

     ATerminalServer.Free;

   end;
   #)
  }
  TJwWTSSessionList = class(TObjectList)
  protected
    FOwner: TJwTerminalServer;

    function GetItem(Index: Integer): TJwWTSSession;
    procedure SetItem(Index: Integer; ASession: TJwWTSSession);

    procedure SetOwner(const Value: TJwTerminalServer);
  public
    destructor Destroy; reintroduce;
    function Add(ASession: TJwWTSSession): Integer;
    function IndexOf(ASession: TJwWTSSession): Integer;
    procedure Insert(Index: Integer; ASession: TJwWTSSession);
    property Items[Index: Integer]: TJwWTSSession read GetItem write SetItem; default;
    property Owner: TJwTerminalServer read FOwner write SetOwner;
    function Remove(ASession: TJwWTSSession): Integer;
  end;

  {@Abstract(@Name is the class that encapsulates a process that is running on
   a Terminal Server.)
   
   A process is uniquely identified by the Process Id (PID) in combination with
   it's Creation Time (the OS reused PID's).@br
   @br@br
   A @Name is owned by a TJwWTSProcessList.
   }
  TJwWTSProcess = class(TObject)
  protected
    {@exclude}
    FOwner: TJwWTSProcessList;
    {@exclude}
    FProcessAge: Int64;
    {@exclude}
    FProcessAgeStr: TJwString;
    {@exclude}
    FProcessCreateTime: TJwString;
    {@exclude}
    FProcessCPUTime: Int64;
    {@exclude}
    FProcessCPUTimeStr: TJwString;
    {@exclude}
    FProcessId: TJwProcessID;
    {@exclude}
    FProcessMemUsage: DWORD;
    {@exclude}
    FProcessName: TJwString;
    {@exclude}
    FProcessVMSize: DWORD;
    {@exclude}
    FSessionId: TJwSessionID;
    {@exclude}
    FUsername: TJwString;
    {@exclude}
    FWinStationName: TJwString;
    {@exclude}
    FToken : TJwSecurityToken;
    {@exclude}
    FUserSid : TJwSecurityID;
    {@exclude}
    function GetServer: TJwString;
    {@exclude}
    function GetToken : TJwSecurityToken;
    {@exclude}
    function GetUserSid : TJwSecurityID;
    function GetServerHandle: THandle; virtual;
  public
    {@Name create a TJwWTSProcess instance.
     @Param(Owner Specifies the TJwTerminalServer instance that owns the process.)
     @Param(SessionId The Session Identifier.)
     @Param(ProcessId The Process Identifier.)
     @Param(ProcessName The Process Name.)
    {@Param(Username the name of the user associated with the process.)
    }
    constructor Create(const Owner: TJwWTSProcessList;
      const SessionId: TJwSessionId; const ProcessID: TJwProcessId;
      const ProcessName: TJwString; const Username: TJwString);
    destructor Destroy; override;
  public
    {The @Name function terminates the specified process on the specified
     terminal server.
    }
    function Terminate: boolean; overload;
    {The @Name function terminates the specified process on the specified
     terminal server.
     @Param(dwExitCode Specifies the exit code for the terminated process.)
    }
    function Terminate(const dwExitCode: DWORD): boolean; overload;
  public
   {@Name Specifies the TJwTerminalServer instance that owns the session)
    }
    property Owner: TJwWTSProcessList read FOwner write FOwner;
    {@Name the session identifier
    }
    property SessionId: TJwSessionId read FSessionId;
    {@Name The elapsed time since the process was created in
     100-nanosecond intervals since January 1, 1601 (TFileTime).
     @seealso(ProcessAgeStr)
    }
    property ProcessAge: Int64 read FProcessAge;
    {@Name The elapsed time since the process was created as formatted
     string. The string is formatted according to the table below:
     @table(
     @rowHead(  @cell(days) @cell(hours) @cell(minutes) @cell(value))
      @row(     @cell(> 0)  @cell(any)   @cell(any)     @cell(+d+hh:mm))
      @row(     @cell(0)    @cell(>0)    @cell(any)     @cell(hh:mm))
      @row(     @cell(0)    @cell(0)     @cell(any)     @cell(mm))
      @row(     @cell(0)    @cell(0)     @cell(0)       @cell(.))
      )
     @seealso(ProcessAge)
    }
    property ProcessAgeStr: TJwString read FProcessAgeStr;

    {@Name The total CPU Time (Usertime + Kerneltime) for the given process
     in 100-nanosecond intervals since January 1, 1601 (TFileTime).@br
     @br@br
     @bold(Remarks:) This value matches the CPU Time column in Task Manager.
     @seealso(ProcessCPUTimeStr)
    }
    property ProcessCPUTime: Int64 read FProcessCPUTime;

    {@Name The total CPU Time (Usertime + Kerneltime) for the given process
     as formatted string. (On Delphi 7 and higher this is a localised string
     for older version it is fixed at hh:mm)@br
     @br@br
     @bold(Remarks:) This value matches the CPU Time column in Task Manager.
     @seealso(ProcessCPUTime)
    }
    property ProcessCPUTimeStr: TJwString read FProcessCPUTimeStr;

    {@Name The Process Creation Time formatted as localised string.
    }
    property ProcessCreateTime: TJwString read FProcessCreateTime;

    {@Name The Process Identifier or PID
    }
    property ProcessId: TJwProcessId read FProcessId;

    {@Name The Process Name
    }
    property ProcessName: TJwString read FProcessName;

    {@Name The Amount of memory in Bytes used by the process
     @br@br
     @bold(Remarks:) This value matches the Mem Usage column in Task Manager.
    }
    property ProcessMemUsage: DWORD read FProcessMemUsage;

    {@Name The Amount of Virtual memory in Bytes used by the process
     @br@br
     @bold(Remarks:) This value matches the VM Size column in Task Manager.
    }
    property ProcessVMSize: DWORD read FProcessVMSize;

    {@Name the netbios name of the Terminal Server.
     @br@br
     @bold(Remarks:) If you want to connect to a Terminal Server locally
     you should not specify the server name. Please note that in the case of a
     local connection this property @bold(will return the computername))
    }
    property Server: TJwString read GetServer;

    {@Name returns the token of the session.
     The returned value is cached and must not be freed!
     If the value cannot be obtained the return value is nil.
    }
    property Token : TJwSecurityToken read GetToken;

    {@Name returns the logged on User of the session.
    The returned value is cached and must not be freed!
    If the value cannot be obtained the return value is nil.
    }
    property UserSid : TJwSecurityID read GetUserSid;

    {@Name the name of the user associated with the process.
    }
    property Username: TJwString read FUsername;

    {@Name returns the session name.
     @br@br
     @bold(Remarks:) Despite its name, specifying this property does not return
     the window station name. Rather, it returns the name of the Terminal
     Services session.@br
     For RDP this will be something like RDP-Tcp#023@br
     For ICA this will be something like ICA-tcp#014
         }
    property WinStationName: TJwString read FWinStationname;
  end;

  {@Name is a pointer to a TJwWTSProcessList}
  PJwWTSProcessList = ^TJwWTSProcessList;

  {@Abstract(@Name is a List of all Processes running on the Terminal Server
   and their properties)

   Each item in the list points to a TJwWTSProcess object that can be queried
   and manipulated.@br
   The list is filled by calling the EnumerateProcesses function of the owning
   TJwTerminalServer instance.@br
   @br
   Example:
   @longCode(#
   var
     ATerminalServer: TjwTerminalServer;
   begin
     ATerminalServer := TjwTerminalServer.Create;
     ATerminalServer.Server := 'TS001';

     if ATerminalServer.EnumerateProcesses then
     begin

       for i := 0 to ATerminalServer.Processes.Count - 1 do
       begin
         Memo1.Lines.Add(ATerminalServer.Processes[i].ProcessName);
       end;

     end;

     ATerminalServer.Free;

   end;
   #)
  }
  TJwWTSProcessList = class(TObjectList)
  protected
    FOwner: TJwTerminalServer;

    function GetItem(Index: Integer): TJwWTSProcess;
    procedure SetItem(Index: Integer; AProcess: TJwWTSProcess);
    procedure SetOwner(const Value: TJwTerminalServer);
  public
    function Add(AProcess: TJwWTSProcess): Integer;
    function IndexOf(AProcess: TJwWTSProcess): Integer;
    procedure Insert(Index: Integer; AProcess: TJwWTSProcess);
    property Items[Index: Integer]: TJwWTSProcess read GetItem write SetItem; default;
    {@Name Specifies the TJwTerminalServer instance that owns the ProcessList
    }
    property Owner: TJwTerminalServer read FOwner write SetOwner;
    function Remove(AProcess: TJwWTSProcess): Integer;
  end;

  {@Name indicates the Shadow State of a session}
  TShadowState =
    (
     {@Name The session is not Shadowing or Being Shadowed}
     ssNone,// = 0,
     {@Name The session is not Shadowing another session}
     ssShadowing,// = 1,
     {@Name The session is being Shadowed by another session}
     ssBeingShadowed// = 2
  );

  {@Name indicates the Shadow Permissions of a session}
  TShadowMode = (
    {@Name The sessions cannot be shadowed}
    smNoneAllowed, // = 0,
    {@Name The sessions be shadowed but needs the user's permission}
    smFullControlWithPermission,// = 1,
    {@Name The sessions be shadowed without the user's permission}
    smFullControlWithoutPermission,// = 2,
    {@Name The sessions can be viewed but needs the user's permission}
    smViewOnlyWithPermission,// = 3,
    {@Name The sessions can be viewed without the user's permission}
    smViewOnlyWithoutPermission// = 4
  );

  {@Abstract(@Name class gives access to the ShadowState and Shadowmode of a
   session.)

   @br@bold(Remarks:) Please note that changing the shadow mode with the SetShadow
   function does not take affect until the sessions has been disconnected
   and reconnected.
   @seealso(TShadowMode)
   @seealso(TShadowState) 
  }
  TJwWTSSessionShadow = class
  private
    FWinStationShadowInformation : TWinStationShadowInformation;
    FOwner : TJwWTSSession;
  protected
    function GetShadowState : TShadowState;
    function GetShadowMode : TShadowMode;
    procedure SetShadowMode(const Value : TShadowMode);
    procedure UpdateShadowInformation(const Modify : Boolean);
  public
    constructor Create(AOwner : TJwWTSSession);
    property ShadowState : TShadowState read GetShadowState;
    property ShadowMode : TShadowMode read GetShadowMode write SetShadowMode;
  end;

{$ENDIF SL_IMPLEMENTATION_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}

implementation
{$ENDIF SL_OMIT_SECTIONS}

type
  { array of TWtsSessionInfoA }
  PJwWTSSessionInfoAArray = ^TJwWTSSessionInfoAArray;
  TJwWTSSessionInfoAArray = array[0..ANYSIZE_ARRAY-1] of TWtsSessionInfoA;

  { array of TWtsSessionInfoW }
  PJwWTSSessionInfoWArray = ^TJwWTSSessionInfoWArray;
  TJwWTSSessionInfoWArray = array[0..ANYSIZE_ARRAY-1] of TWtsSessionInfoW;

  { array of TWtsProcessInfoA }
  PJwWTSProcessInfoAArray = ^TJwWTSProcessInfoAArray;
  TJwWTSProcessInfoAArray = array[0..ANYSIZE_ARRAY-1] of TWtsProcessInfoA;

  { array of TWtsProcessInfoW }
  PJwWTSProcessInfoWArray = ^TJwWTSProcessInfoWArray;
  TJwWTSProcessInfoWArray = array[0..ANYSIZE_ARRAY-1] of TWtsProcessInfoW;

  { array of TWtsServerInfoA }
  PJwWtsServerInfoAArray = ^TJwWtsServerInfoAArray;
  TJwWtsServerInfoAArray = array[0..ANYSIZE_ARRAY-1] of TWtsServerInfoA;

  { array of TWtsServerInfoW }
  PJwWtsServerInfoWArray = ^TJwWtsServerInfoWArray;
  TJwWtsServerInfoWArray = array[0..ANYSIZE_ARRAY-1] of TWtsServerInfoW;


constructor TJwTerminalServer.Create;
begin
  inherited Create;
  OutputDebugString('TJwTerminalServer.Create');
  FSessions := TJwWTSSessionList.Create(True);
  FSessions.Owner := Self;

  FProcesses := TJwWTSProcessList.Create(True);
  FProcesses.Owner := Self;

  FTerminalServerEventThread := nil;
  FServers := TStringList.Create;

  FOnServersEnumerated := nil;
//  FServerLis := TStringList.Create;
end;

destructor TJwTerminalServer.Destroy;
var
  EventFlag: DWORD;
begin
  // Close connection
  if Assigned(FEnumServersThread) then
  begin
    // Don't handle any more events
    FOnServersEnumerated := nil;

    // Signal Termination to the thread
    FEnumServersThread.Terminate;

    // Wait a while, see if thread terminates
    if WaitForSingleObject(FEnumServersThread.Handle, 1000) = WAIT_TIMEOUT then
    begin
      // it didn't, so kill it (we don't want the user to wait forever)!
      // TSAdmin does it the same way...
      TerminateThread(FEnumServersThread.Handle, 0);
    end;

//    FEnumServersThread.Wait;
  end;

  // Terminate the Event Thread before closing the connection.
  if Assigned(FTerminalServerEventThread) then
  begin
    // Terminate Event Thread
    FTerminalServerEventThread.Terminate;

    // unblock the waiter
    WTSWaitSystemEvent(FServerHandle, WTS_EVENT_FLUSH, EventFlag);

    // wait for the thread to finish
    FTerminalServerEventThread.WaitFor;

    // Free
    FreeAndNil(FTerminalServerEventThread);
  end;

  if Connected then
  begin
    Disconnect;
  end;

    // Free the SessionList
    FreeAndNil(FSessions);

    // Free the ProcessList
    FreeAndNil(FProcesses);

  // Free the Serverlist
    FreeAndNil(FServers);

  // Free the Serverlist
//    FreeAndNil(FServerList);

  inherited;
end;


{
The following table lists the events that trigger the different flags.
Events are listed across the top and the flags are listed down the
left column. An �X� indicates that the event triggers the flag.
+-------------+------+------+------+-------+----------+-----+------+-------+
| EventFlag   |Create|Delete|Rename|Connect|Disconnect|Logon|Logoff|License|
+-------------+------+------+------+-------+----------+-----+------+-------+
| Create      | X    |      |      | X     |          |     |      |       |
+-------------+------+------+------+-------+----------+-----+------+-------+
| Delete      |      | X    |      |       |          |     | X    |       |
+-------------+------+------+------+-------+----------+-----+------+-------+
| Rename      |      |      | X    |       |          |     |      |       |
+-------------+------+------+------+-------+----------+-----+------+-------+
| Connect     |      |      |      | X     |          |     |      |       |
+-------------+------+------+------+-------+----------+-----+------+-------+
| Disconnect  |      |      |      |       | X        |     |      |       |
+-------------+------+------+------+-------+----------+-----+------+-------+
| Logon       |      |      |      |       |          | X   |      |       |
+-------------+------+------+------+-------+----------+-----+------+-------+
| Logoff      |      |      |      |       |          |     | X    |       |
+-------------+------+------+------+-------+----------+-----+------+-------+
| License     |      |      |      |       |          |     |      | X     |
+-------------+------+------+------+-------+----------+-----+------+-------+
| StateChange | X    | X    |      | X     | X        | X   | X    |       |
+-------------+------+------+------+-------+----------+-----+------+-------+
| All         | X    | X    | X    | X     | X        | X   | X    | X     |
+-------------+------+------+------+-------+----------+-----+------+-------+

An WinStation is created when a user connects. When a user logs off, the
Winstation is deleted. When a user logs on to a disconnected session, the
existing session is deleted and the Delete flag is triggered. When users
connect to a disconnected session from within a session, their session is
disconnected and the Disconnect flag is triggered instead of the Delete flag.}

procedure TJwTerminalServer.FireEvent(EventFlag: DWORD);
begin
  // Set LastEventFlag property
  FLastEventFlag := EventFlag;

  // The OnSessionEvent should be fired if anything happens that is session
  // related, like statechange, logon/logoff, disconnect and (re)connect.
  if (EventFlag > WTS_EVENT_CONNECT) and (EventFlag < WTS_EVENT_LICENSE) then
  begin
    if Assigned(FOnSessionEvent) then
    begin
      OnSessionEvent(Self);
    end;
  end;

  if (EventFlag and WTS_EVENT_LICENSE = WTS_EVENT_LICENSE) and
    Assigned(OnLicenseStateChange) then
  begin
    OnLicenseStateChange(Self);
  end;
  if (EventFlag and WTS_EVENT_STATECHANGE = WTS_EVENT_STATECHANGE) and
    Assigned(FOnSessionStateChange) then
  begin
    OnSessionStateChange(Self);
  end;
  if (EventFlag and WTS_EVENT_LOGOFF = WTS_EVENT_LOGOFF) and
    Assigned(FOnSessionLogoff) then
  begin
    OnSessionLogoff(Self);
  end;
  if (EventFlag and WTS_EVENT_LOGON = WTS_EVENT_LOGON) and
    Assigned(FOnSessionLogon) then
  begin
    OnSessionLogon(Self);
  end;
  if (EventFlag and WTS_EVENT_DISCONNECT = WTS_EVENT_DISCONNECT) and
    Assigned(FOnSessionDisconnect) then
  begin
    OnSessionDisconnect(Self);
  end;
  if (EventFlag and WTS_EVENT_CONNECT = WTS_EVENT_CONNECT) and
    Assigned(FOnSessionConnect) then
  begin
    OnSessionConnect(Self);
  end;
  if (EventFlag and WTS_EVENT_RENAME = WTS_EVENT_RENAME) and
    Assigned(FOnWinStationRename) then
  begin
    OnWinStationRename(Self);
  end;
  if (EventFlag and WTS_EVENT_DELETE = WTS_EVENT_DELETE) and
    Assigned(FOnSessionDelete) then
  begin
    OnSessionDelete(Self);
  end;
  if (EventFlag and WTS_EVENT_CREATE = WTS_EVENT_CREATE) and
    Assigned(FOnSessionCreate) then
  begin
    OnSessionCreate(Self);
  end;

end;

function TJwTerminalServer.GetServer: TJwString;
var nSize: DWORD;
  pComputerName: TJwPChar;
begin
  // If no server was specified we return the local computername
  // (we cache this in FComputerName)
  if FServer = '' then
  begin
    if FComputerName = '' then
    begin
      nSize := MAX_COMPUTERNAME_LENGTH + 1;
      GetMem(pComputerName, nSize * TJwCharSize);
{$IFDEF UNICODE}
      GetComputerNameW(pComputerName, nSize);
{$ELSE}
      GetComputerNameA(pComputerName, nSize);
{$ENDIF}
      FComputerName := pComputerName;
      FreeMem(pComputerName);
    end;
    Result := FComputerName;
  end
  else
  begin
    Result := FServer;
  end;
end;

function TJwTerminalServer.GetWinStationName(const SessionId: DWORD): TJwString;
var WinStationNamePtr: PWideChar;
begin
  // Get and zero memory (
  GetMem(WinStationNamePtr, WINSTATIONNAME_LENGTH * SizeOf(WideChar));
  try
    ZeroMemory(WinStationNamePtr, WINSTATIONNAME_LENGTH * SizeOf(WideChar));

    if WinStationNameFromLogonIdW(FServerHandle, SessionId,
      WinStationNamePtr) then
    begin
      Result := PWideCharToJwString(WinStationNamePtr);
    end;

    // Return disconnected if WinStationName = empty
    if Result = '' then
    begin
      Result := PWideCharToJwString(StrConnectState(WTSDisconnected, False));
    end;
  finally
    FreeMem(WinStationNamePtr);
  end;
end;

procedure TJwTerminalServer.OnEnumServersThreadTerminate(Sender: TObject);
begin
  // nil it!
  FEnumServersThread := nil;
  OutputDebugString('nil it!');
end;

procedure TJwTerminalServer.SetServer(const Value: TJwString);
begin
  FServer := Value;
  // Clear the computername variable (cache)
  FComputerName := '';
end;

function TJwTerminalServer.EnumerateProcesses: Boolean;
var Count: Integer;
  ProcessInfoPtr: PWINSTA_PROCESS_INFO_ARRAY;
  i: Integer;
  AProcess: TJwWTSProcess;
  strProcessName: TJwString;
  strUsername: TJwString;
  lpBuffer: PWideChar;
  DiffTime: TDiffTime;
//  strSid: TjwString;
begin
  ProcessInfoPtr := nil;
  Count := 0;

  FProcesses.Clear;

  if not Connected then
  begin
    Connect;
  end;

  ProcessInfoPtr := nil;

  Result := WinStationGetAllProcesses(FServerHandle, 0, Count, ProcessInfoPtr);
  if Result then
  begin
    for i := 0 to Count-1 do
    begin
      with ProcessInfoPtr^[i], ExtendedInfo^ do
      begin
        // System Idle Process
        if ProcessId = 0 then
        begin
          strProcessName := GetIdleProcessName;
          strUserName := 'SYSTEM';
        end
        else
        begin
          strProcessName := JwUnicodeStringToJwString(ProcessName);

          if IsValidSid(pUserSid) then
          begin
            with TJwSecurityID.Create(pUserSid) do
            begin
              strUsername := GetCachedUserFromSid;
//              strSid := StringSID;
              Free;
            end;
          end;
        end;

        AProcess := TJwWTSProcess.Create(FProcesses, SessionId,
          ProcessId, strProcessName, strUsername);
        with AProcess do
        begin
          FProcesses.Add(AProcess);

//          FSidStr := strSid;
          // Calculate Process Age
          CalculateElapsedTime(@CreateTime, DiffTime);

            // Reserve Memory
            GetMem(lpBuffer, ELAPSED_TIME_STRING_LENGTH * SizeOf(WCHAR));
          try
            // Format Elapsed Time String
            ElapsedTimeStringSafe(@DiffTime, False, lpBuffer,
                ELAPSED_TIME_STRING_LENGTH);
            FProcessAge := (DiffTime.wDays * SECONDS_PER_DAY) +
              (DiffTime.wHours * SECONDS_PER_HOUR) +
              (DiffTime.wMinutes * SECONDS_PER_MINUTE);
            FProcessAgeStr := PWideCharToJwString(lpBuffer);
          finally
            // Free mem
            FreeMem(lpBuffer);
            lpBuffer := nil;
          end;

          // Some of the used counters are explained here:
          // http://msdn2.microsoft.com/en-us/library/aa394372.aspx

          FProcessCreateTime :=
            TimeToStr(FileTime2DateTime(FILETIME(CreateTime)));
          // The CPU Time column in Taskmgr.exe is Usertime + Kerneltime
          // So we take the sum of it and call it ProcessCPUTime
          FProcessCPUTime := UserTime.QuadPart + KernelTime.QuadPart;

          FProcessCPUTimeStr := CPUTime2Str(
            LARGE_INTEGER(UserTime.QuadPart + KernelTime.QuadPart));
          // Amount of memory in bytes that a process needs to execute
          // efficiently. Maps to Mem Size column in Task Manager.
          // So we call it ProcessMemUsage
          FProcessMemUsage := VmCounters.WorkingSetSize;
          // Pagefileusage is the amount of page file space that a process is
          // using currently. This value is consistent with the VMSize value
          // in TaskMgr.exe. So we call it ProcessVMSize
          FProcessVMSize := VmCounters.PagefileUsage;
        end;
      end;
    end;
  end;
  // Cleanup
  if ProcessInfoPtr <> nil then
  begin
    WinStationFreeGAPMemory(0, ProcessInfoPtr, Count);
  end;

  ProcessInfoPtr := nil;
end;

function TJwTerminalServer.GetServers: {$IFDEF UNICODE}TWideStringList{$ELSE}TStringList{$ENDIF UNICODE};
begin
  // Create the list
  if not Assigned(FServers) then
  begin
{$IFDEF UNICODE}
    FServers := TWideStringList.Create;
{$ELSE}
    FServers := TStringList.Create;
{$ENDIF UNICODE}
    // The list was empty so fill it!
    EnumerateServers('');
  end;

  // Return the serverlist
  //TODO: Warning: User can free returned list (on purpose) this can
  //lead to problems in EnumerateServers
  Result := FServers;
end;

function TJwTerminalServer.EnumerateSessions: boolean;
var SessionInfoPtr: {$IFDEF UNICODE}PJwWTSSessionInfoWArray;
  {$ELSE}PJwWTSSessionInfoAArray;{$ENDIF UNICODE}
  pCount: DWORD;
  i: integer;
  Res: Longbool;
  ASession: TJwWTSSession;
begin
  if not Connected then
  begin
    Connect;
  end;

  // Clear the sessionslist
  FSessions.Clear;

  Res :=
{$IFDEF UNICODE}
    WTSEnumerateSessionsW(FServerHandle, 0, 1, PWTS_SESSION_INFOW(SessionInfoPtr),
      pCount);
{$ELSE}
    WTSEnumerateSessions(FServerHandle, 0, 1, PWTS_SESSION_INFOA(SessionInfoPtr),
      pCount);
{$ENDIF UNICODE}


  if not Res then begin
    raise EJwsclWinCallFailedException.CreateFmtWinCall(RsWinCallFailed,
      'EnumerateSessions', ClassName, RsUNTerminalServer, 923, True,
          'WTSEnumerateSessions', ['WTSEnumerateSessions']);
  end;

  // Add all sessions to the SessionList
  for i := 0 to pCount - 1 do
  begin
    ASession := TJwWTSSession.Create(FSessions, SessionInfoPtr^[i].SessionId,
      GetWinStationName(SessionInfoPtr^[i].SessionId),
      TWtsConnectStateClass(SessionInfoPtr^[i].State));
    FSessions.Add(ASession);
  end;

  // After enumerating we create an event thread to listen for session changes
  if FTerminalServerEventThread = nil then
  begin
    FTerminalServerEventThread := TJwWTSEventThread.Create(False, Self);
  end;


  WTSFreeMemory(SessionInfoPtr);
  SessionInfoPtr := nil;

  // Pass the result
  Result := Res;
end;

function TJwTerminalServer.EnumerateServers(ADomain: String): Boolean;
begin
  // Does the thread exist?
  if Assigned(FEnumServersThread) then
  begin
    OutputDebugString('thread is already assigned');
    Result := False;
  end
  else
  begin
    // Create the thread
    OutputDebugString('create thread');
    FEnumServersThread := TJwWTSEnumServersThread.Create(True, Self, ADomain);
    FEnumServersThread.OnTerminate := OnEnumServersThreadTerminate;
    FEnumServersThread.Resume;
    Result := True;
  end;
end;

procedure TJwTerminalServer.Connect;
begin
  if not FConnected then
  begin
    if FServer = '' then
    begin
      FServerHandle := WTS_CURRENT_SERVER_HANDLE;
      FConnected := True;
    end
    else
    begin
      FServerHandle :=
{$IFDEF UNICODE}
      WTSOpenServerW(PWideChar(WideString(FServer)));
{$ELSE}
      WTSOpenServerA(PChar(FServer));
{$ENDIF}
      // If WTSOpenServer fails the return value is 0
      if FServerHandle = 0 then
      begin
        raise EJwsclWinCallFailedException.CreateFmtWinCall(RsWinCallFailed,
          'WTSOpenServer', ClassName, RsUNTerminalServer, 1000, True,
          'WTSOpenServer', ['WTSOpenServer', FServer]);
      end
      else
      begin
        FConnected := True;
      end;
    end;

  end;
end;

procedure TJwTerminalServer.Disconnect;
begin

  if FServerHandle <> WTS_CURRENT_SERVER_HANDLE then
  begin
    WTSCloseServer(FServerHandle);
  end;

  FServerHandle := INVALID_HANDLE_VALUE;
  FConnected := False;
end;

function TJwTerminalServer.FileTime2DateTime(FileTime: _FILETIME): TDateTime;
var
  LocalFileTime: TFileTime;
  SystemTime: TSystemTime;
begin
  FileTimeToLocalFileTime(FileTime, LocalFileTime);
  FileTimeToSystemTime(LocalFileTime, SystemTime);
  Result := SystemTimeToDateTime(SystemTime);
end;

function TJwTerminalServer.Shutdown(AShutdownFlag: DWORD): Boolean;
begin
  Result := WTSShutdownSystem(FServerHandle, AShutdownFlag);
end;

constructor TJwWTSEventThread.Create(CreateSuspended: Boolean;
  AOwner: TJwTerminalServer);
begin
  inherited Create(CreateSuspended, Format('%s (%s)', [ClassName, AOwner.Server]));
  FreeOnTerminate := False;

  OutputDebugString('creating wtsevent thread');

  FOwner := AOwner;
end;



procedure TJwWTSEventThread.Execute;
begin
  inherited Execute;  

  while not Terminated do
  begin
    OutputDebugString('Entering WTSWaitSystemEvent');
    if WTSWaitSystemEvent(FOwner.ServerHandle, WTS_EVENT_ALL, FEventFlag) then
    begin
      if FEventFlag > WTS_EVENT_FLUSH then
      begin
        // Wait some time to prevent duplicate event dispatch
        OutputDebugString('Dispatching');
        Synchronize(DispatchEvent);
      end;
    end
    else begin
      OutputDebugString(PChar(Format('WTSWaitSystemEvent, False: %s', [SysErrorMessage(GetLastError)])));
    end;
    Sleep(0);
  end;
end;

procedure TJwWTSEventThread.DispatchEvent;
begin
  if FEventFlag > WTS_EVENT_NONE then 
  begin
    FOwner.FireEvent(FEventFlag);
    FEventFlag := WTS_EVENT_NONE;
  end;
end;

constructor TJwWTSEnumServersThread.Create(CreateSuspended: Boolean;
  Owner: TJwTerminalServer; Domain: TJwString);
begin
  JwRaiseOnNilParameter(Owner, 'Owner','Create', ClassName, RsUNTerminalServer);
  OutputDebugString('Creating EnumServers thread');

  inherited Create(CreateSuspended, Format('%s (%s)', [ClassName, Owner.Server]));

  FTerminatedEvent := CreateEvent(nil, False, False, nil);
  FOwner := Owner;
  FDomain := Domain;
  FreeOnTerminate := True;
end;

procedure TJwWTSEnumServersThread.Execute;
type
  PWTS_SERVER_INFO = {$IFDEF UNICODE}PWTS_SERVER_INFOW{$ELSE}PWTS_SERVER_INFOA{$ENDIF UNICODE};
var ServerInfoPtr: PJwWtsServerInfoAArray;
  pCount: DWORD;
  i: DWORD;
begin
  inherited Execute;

  OutputDebugString('thread is executing');
  // Clear the serverlist
  Synchronize(ClearServerList);

  ServerInfoPtr := nil;
  // Since we return to a Stringlist (which does not support unicode)
  // we only use WTSEnumerateServersA

  if {$IFDEF UNICODE}WTSEnumerateServersW{$ELSE}WTSEnumerateServersA{$ENDIF UNICODE}
   (TJwPChar(FDomain), 0, 1, PWTS_SERVER_INFO(ServerInfoPtr),
    pCount) then
  begin
    for i := 0 to pCount - 1 do
    begin
      // If the thread is terminated then leave the loop
      if Terminated then Break;
      FServer := ServerInfoPtr^[i].pServerName;
      Synchronize(AddToServerList);
    end;

    // Note that on failure of WTSEnumerateServers we don't produce an
    // exception but return an empty ServerList instead. This is by design

    // If we have not been terminated we fire the OnServersEnumerated Event
    if not Terminated then
    begin
      Synchronize(DispatchEvent);
    end;
  end;

  // Cleanup
  if ServerInfoPtr <> nil then
  begin
    WTSFreeMemory(ServerInfoPtr);
  end;

  // Signal Wait procedure that we are finished.
  SetEvent(FTerminatedEvent);
end;

procedure TJwWTSEnumServersThread.AddToServerList;
begin
  FOwner.Servers.Add(FServer);
end;

procedure TJwWTSEnumServersThread.ClearServerList;
begin
  FOwner.Servers.Clear;
end;

procedure TJwWTSEnumServersThread.DispatchEvent;
begin
  if Assigned(FOwner.OnServersEnumerated) then
  begin
    // Fire the OnServersEnumerated event
    FOwner.OnServersEnumerated(FOwner);
  end;
end;


{procedure TJwWTSEnumServersThread.Wait;
var Res: DWORD;
begin
  // we should wait only from the MainThreadId!
  if GetCurrentThreadID = MainThreadID then
  begin
    Res := WAIT_OBJECT_0+1;

    while (Res = WAIT_OBJECT_0+1) do
    begin
      // Wait for the thread to trigger the Terminated Event
      Res := WaitForSingleObject(FTerminatedEvent, INFINITE);
      OutputDebugString('WaitForSingleObject done');
    end;
  end;
end;}

// Borland's WaitFor procedure contains a bug when using Waitfor in combination
// with FreeOnTerminate := True; During the loop in WaitFor the TThread object
// can be freed and its Handle invalidated.  When MsgWaitForMultipleObjects()
// is called again, it fails, and then a call to CheckThreadError() afterwards
// throws on EOSError exception with an error code of 6 and an error message of
//  "the handle is invalid". http://qc.borland.com/wc/qcmain.aspx?d=6080
// Therefore we override the WaitFor function and Create an Exception
{function TJwWTSEnumServersThread.WaitFor: LongWord;
begin
  // Return error
  //Result := ERROR_NOT_SUPPORTED;

  raise EJwsclUnimplemented.CreateFmtWinCall(RsWinCallFailed,
    'WaitFor function is not supported, please use Wait instead', ClassName,
    RsUNTerminalServer, 1203, False,
    'WaitFor function is not supported, please use Wait instead',
    ['TJwWTSEnumServersThread.WaitFor']);
end;}

destructor TJwWTSSessionList.Destroy;
begin
  inherited Destroy;
end;

function TJwWTSSessionList.Add(ASession: TJwWTSSession): Integer;
begin
  Result := inherited Add(ASession);
end;

function TJwWTSSessionList.GetItem(Index: Integer): TJwWTSSession;
begin
  Result := TJwWTSSession(inherited Items[Index]);
end;

function TJwWTSSessionList.IndexOf(ASession: TJwWTSSession): Integer;
begin
  Result := inherited IndexOf(ASession);
end;

procedure TJwWTSSessionList.Insert(Index: Integer; ASession: TJwWTSSession);
begin
  inherited Insert(Index, ASession);
end;

function TJwWTSSessionList.Remove(ASession: TJwWTSSession): Integer;
begin
  Result := inherited Remove(ASession);
end;

procedure TJwWTSSessionList.SetItem(Index: Integer; ASession: TJwWTSSession);
begin
  inherited Items[Index] := ASession;
end;

procedure TJwWTSSessionList.SetOwner(const Value: TJwTerminalServer);
begin
  FOwner := Value;
end;

function TJwWTSProcessList.Add(AProcess: TJwWTSProcess): Integer;
begin
  Result := inherited Add(AProcess);
end;

function TJwWTSProcessList.GetItem(Index: Integer): TJwWTSProcess;
begin
  Result := TJwWTSProcess(inherited Items[Index]);
end;

function TJwWTSProcessList.IndexOf(AProcess: TJwWTSProcess): Integer;
begin
  Result := inherited IndexOf(AProcess);
end;

procedure TJwWTSProcessList.Insert(Index: Integer; AProcess: TJwWTSProcess);
begin
  inherited Insert(Index, AProcess);
end;

function TJwWTSProcessList.Remove(AProcess: TJwWTSProcess): Integer;
begin
  Result := inherited Remove(AProcess);
end;

procedure TJwWTSProcessList.SetItem(Index: Integer; AProcess: TJwWTSProcess);
begin
  inherited Items[Index] := AProcess;
end;

constructor TJwWTSSessionShadow.Create(AOwner : TJwWTSSession);
begin
  FOwner := AOwner;
end;

function TJwWTSSessionShadow.GetShadowMode;
begin
  UpdateShadowInformation(False);
  Result := TShadowMode(FWinStationShadowInformation.ShadowMode);
end;

function TJwWTSSessionShadow.GetShadowState : TShadowState;
begin
  UpdateShadowInformation(False);
  Result := TShadowState(FWinStationShadowInformation.CurrentShadowState);
end;

procedure TJwWTSSessionShadow.SetShadowMode(Const Value : TShadowMode);
begin
  FWinStationShadowInformation.ShadowMode := Ord(Value);
  UpdateShadowInformation(True);
end;

procedure TJwWTSSessionShadow.UpdateShadowInformation(const Modify : Boolean);
var
  ReturnedLength : DWORD;
begin
  if not Modify then
  begin
{    if not }WinStationQueryInformationW(FOwner.GetServerHandle, FOwner.SessionId,
     WinStationShadowInformation, @FWinStationShadowInformation,
     SizeOf(FWinstationShadowInformation), ReturnedLength);{ then
      raise EJwsclWinCallFailedException.CreateFmtWinCall(RsWinCallFailed,
       'UpdateShadowInformation', ClassName, RsUNTerminalServer, 0, True,
       'WinStationQueryInformationW', ['WinStationQueryInformationW']);}
  end
  else
    if not WinStationSetInformationW(FOwner.GetServerHandle, FOwner.SessionId,
     WinStationShadowInformation, @FWinStationShadowInformation,
     SizeOf(FWinstationShadowInformation)) then
      raise EJwsclWinCallFailedException.CreateFmtWinCall(RsWinCallFailed,
       'UpdateShadowInformation', ClassName, RsUNTerminalServer, 0, True,
       'WinStationSetInformationW', ['WinStationSetInformationW']);
end;

function TJwTerminalServer.GetIdleProcessName: TJwString;
var hModule: THandle;
  lpBuffer: PWideChar;
  nBufferMax: Integer;
begin
  // The "System Idle Process" name is language dependant, therefore
  // we obtain it from Taskmgr and cache it in IdleProcessName property
  if FIdleProcessName = '' then
  begin
    hModule := LoadLibrary('taskmgr.exe');
    if hModule > 0 then
    begin
      nBufferMax := 256;  // 256 Chars seems safe for a resource string
      GetMem(lpBuffer, nBufferMax * SizeOf(WCHAR));
      // Windows NT4 and Windows XP Taskmgr have the System Idle Process
      // as resource string 10005. Windows Vista has it in MUI file
      // taskmgr.exe.mui with same id
      if LoadStringW(hModule, 10005, lpBuffer, nBufferMax) > 0 then
      begin
        FIdleProcessName := PWideCharToJwString(lpBuffer);
      end;
      // Cleanup
      FreeMem(lpBuffer);
      FreeLibrary(hModule);
    end;
  end;
  Result := FIdleProcessName;
end;

function TJwTerminalServerList.FindByServer(const ServerName: WideString; const IgnoreCase: boolean = False): TJwTerminalServer;
var i: Integer;
begin
  Result := nil;
  for i := 0 to Count-1 do
  begin
    //if Items[i].Server = AServer then
    if JwCompareString(Items[i].Server,ServerName,IgnoreCase) = 0 then
    begin
      Result := Items[i];
      Break;
    end;
  end;
end;

function TJwTerminalServerList.GetItem(Index: Integer): TJwTerminalServer;
begin
  Result := TJwTerminalServer(inherited Items[Index]);
end;

function TJwTerminalServerList.Add(ATerminalServer: TJwTerminalServer): Integer;
begin
  Result := inherited Add(ATerminalServer);
end;

function TJwTerminalServerList.IndexOf(ATerminalServer: TJwTerminalServer): Integer;
begin
  Result := inherited IndexOf(ATerminalServer);
end;

function TJwTerminalServerList.Remove(ATerminalServer: TJwTerminalServer): Integer;
begin
  Result := inherited Remove(ATerminalServer);
end;

procedure TJwTerminalServerList.SetItem(Index: Integer; ATerminalServer: TJwTerminalServer);
begin
  inherited SetItem(Index, ATerminalServer);
end;

procedure TJwTerminalServerList.SetOwner(const Value: TComponent);
begin
  FOwner := Value;
end;

procedure TJwTerminalServerList.Insert(Index: Integer; ATerminalServer: TJwTerminalServer);
begin
  inherited Insert(Index, ATerminalServer);
end;

destructor TJwTerminalServerList.Destroy;
begin
  inherited Destroy;
end;

procedure TJwWTSProcessList.SetOwner(const Value: TJwTerminalServer);
begin
  FOwner := Value;
end;

function TJwWTSSession.ProtocolTypeToStr(const AProtocolType: DWORD): TJwString;
begin
  //TODO: use resource strings
  case AProtocolType of
    WTS_PROTOCOL_TYPE_CONSOLE: Result := 'Console';
    WTS_PROTOCOL_TYPE_ICA: Result := 'ICA';
    WTS_PROTOCOL_TYPE_RDP: Result := 'RDP';
  else
    Result := '';  // Should never happen
  end;
end;

procedure TJwWTSSession.GetSessionInfoPtr(const WTSInfoClass: _WTS_INFO_CLASS;
  var ABuffer: Pointer);
var dwBytesReturned: DWORD;
begin
  ABuffer := nil;
{$IFDEF UNICODE}
    WTSQuerySessionInformationW(GetServerHandle, FSessionId, WTSInfoClass,
      ABuffer, dwBytesReturned);
{$ELSE}
    WTSQuerySessionInformationA(GetServerHandle, FSessionId, WTSInfoClass,
      ABuffer, dwBytesReturned);
{$ENDIF}
end;

function TJwWTSSession.GetSessionInfoStr(const WTSInfoClass: _WTS_INFO_CLASS):
  TJwString;
var
  aBuffer: Pointer;
begin
  result := '';
  GetSessionInfoPtr(WTSInfoClass, aBuffer);
  if ABuffer <> nil then
  begin
    Result := TJwString(TJwPChar(aBuffer));
    WTSFreeMemory(aBuffer);
  end;
end;

function TJwWTSSession.GetSessionInfoDWORD(const WTSInfoClass: _WTS_INFO_CLASS): DWORD;
var ABuffer: Pointer;
begin
  result := 0;
  GetSessionInfoPtr(WTSInfoClass, aBuffer);
  if ABuffer <> nil then
  begin
    Result := PDWord(ABuffer)^;
    WTSFreeMemory(ABuffer);
  end;
end;

function TJwWTSSession.GetServerHandle;
begin
  // The ServerHandle is stored in TJwTerminalServer
  //TODO: Owner = nil? or Owner.Owner = nil ?
  JwRaiseOnNilMemoryBlock(Owner, 'GetServerHandle', ClassName, RsUNTerminalServer);
  JwRaiseOnNilMemoryBlock(Owner.Owner, 'GetServerHandle', ClassName, RsUNTerminalServer);

  Result := Owner.Owner.FServerHandle;
end;

procedure TJwWTSSession.GetWinStationDriver;
var WinStationDriver: _WD_CONFIGW;
  dwReturnLength: DWORD;
begin
  FWdName := '';
  FWdFlag := 0;
  // ZeroMemory
  ZeroMemory(@WinStationDriver, SizeOf(WinStationDriver));

  if WinStationQueryInformationW(GetServerHandle, FSessionId,
    WdConfig, @WinStationDriver, SizeOf(WinStationDriver),
    dwReturnLength) then
  begin
    FWdName := PWideCharToJwString(WinStationDriver.WdName);
    FWdFlag := WinStationDriver.WdFlag;
  end;
end;

// #todo Remove IdleTime helper from JwaWinsta
procedure TJwWTSSession.GetWinStationInformation;
var WinStationInfo: _WINSTATION_INFORMATIONW;
  dwReturnLength: DWORD;
  lpBuffer: PWideChar;
begin
  // ZeroMemory
  ZeroMemory(@WinStationInfo, SizeOf(WinStationInfo));
  lpBuffer := nil;

  if WinStationQueryInformationW(GetServerHandle, FSessionId,
    WinStationInformation, @WinStationInfo, SizeOf(WinStationInfo),
    dwReturnLength) then
  begin
    // Only Active Session has Logon Time
    if FConnectState = WTSActive then
    begin
      // Reserve memory
      GetMem(lpBuffer, MAX_PATH * SizeOf(WCHAR));
      try
        // Format LogonTime string
        DateTimeStringSafe(@WinStationInfo.LogonTime, lpBuffer, MAX_PATH);
        FLogonTimeStr := PWideCharToJwString(lpBuffer);
      finally
        FreeMem(lpBuffer);
        lpBuffer := nil;
      end;

      if FWdFlag > WD_FLAG_CONSOLE then
      begin
        // Counter values (Status from TSAdmin)
        FIncomingBytes := WinStationInfo.IncomingBytes;
        FIncomingCompressedBytes := WinStationInfo.IncomingCompressedBytes;
        FIncomingFrames := WinStationInfo.IncomingFrames;

        FOutgoingBytes := WinStationInfo.OutgoingBytes;
        FOutgoingCompressBytes := WinStationInfo.OutgoingCompressBytes;
        FOutgoingFrames := WinStationInfo.OutgoingFrames;

        // Calculate Compression ratio and store as formatted string
        if WinStationInfo.OutgoingBytes > 0 then // 0 division check
        begin
          FCompressionRatio := Format('%1.2f',
            [WinStationInfo.OutgoingCompressBytes /
            WinStationInfo.OutgoingBytes]);
        end
        else
          FCompressionRatio := '(inf)'; //infinite output
      end;
    end
    else if FConnectState = WTSDisconnected then
    begin
      // A disconnected session is Idle since DisconnectTime
      WinStationInfo.LastInputTime := WinStationInfo.DisconnectTime;
    end;

    if FUsername = '' then
    begin
      // A session without a user is not idle, usually these are special
      // sessions like Listener, Services or console session
      FIdleTimeStr := '.';
     // Store the IdleTime as elapsed seconds
      FIdleTime := 0;
    end
    else
    begin
      // Store the IdleTime as elapsed seconds
      FIdleTime := CalculateDiffTime(Int64(WinStationInfo.LastInputTime),
        Int64(WinStationInfo.CurrentTime));
      // Calculate & Format Idle Time String, DiffTimeString allocates the
      // memory for us
      DiffTimeString(WinStationInfo.LastInputTime, WinStationInfo.CurrentTime,
        lpBuffer);
      try
        FIdleTimeStr := PWideCharToJwString(lpBuffer);
      finally
        // We free the memory DiffTimeString has allocated for us
        FreeMem(lpBuffer);
      end;
    end;

    FConnectTime := FileTime2DateTime(WinStationInfo.ConnectTime);
    FDisconnectTime := FileTime2DateTime(WinStationInfo.DisconnectTime);
    // for A disconnected session LastInputTime has been set to DisconnectTime
    FLastInputTime := FileTime2DateTime(WinStationInfo.LastInputTime);
//    FLogonTime := FileTime2DateTime(WinStationInfo.LogonTime);
    FLogonTime := Int64(WinStationInfo.LogonTime);
    FCurrentTime := FileTime2DateTime(WinStationInfo.CurrentTime);
  end;

end;

function TJwWTSSession.GetClientAddress: TJwString;
var ClientAddressPtr: PWtsClientAddress;
begin
  GetSessionInfoPtr(WTSClientAddress, Pointer(ClientAddressPtr));
  if ClientAddressPtr <> nil then
  begin
    {Note that the first byte of the IP address returned in the ppBuffer
     parameter will be located at an offset of 2 bytes from the start of
     the Address member of the returned WTS_CLIENT_ADDRESS structure.}
    case ClientAddressPtr^.AddressFamily of
      AF_INET:
        Result := Format('%d.%d.%d.%d', [ClientAddressPtr^.Address[2],
          ClientAddressPtr^.Address[3], ClientAddressPtr^.Address[4],
          ClientAddressPtr^.Address[5]]);
      AF_INET6:
        Result := 'IPv6 address not yet supported';
      AF_IPX:
        Result := 'IPX is no longer supported';
      AF_NETBIOS:
        Result := 'NETBIOS is not supported';
      AF_UNSPEC:
        Result := '';
    end;

    // Cleanup
    WTSFreeMemory(ClientAddressPtr);
  end;
end;

procedure TJwWTSSession.GetClientDisplay;
var ClientDisplayPtr: PWtsClientDisplay;
begin
  GetSessionInfoPtr(WTSClientDisplay, Pointer(ClientDisplayPtr));
  if ClientDisplayPtr <> nil then
  begin
    FHorizontalResolution := ClientDisplayPtr^.HorizontalResolution;
    FVerticalResolution := ClientDisplayPtr^.VerticalResolution;
    FColorDepth := ClientDisplayPtr^.ColorDepth;
    // Cleanup
    WTSFreeMemory(ClientDisplayPtr);
  end;
end;


constructor TJwWTSSession.Create(const Owner: TJwWTSSessionList;
  const SessionId: TJwSessionId; const WinStationName: TJwString;
  const ConnectState: TWtsConnectStateClass);
var tempStr : String;
begin
  JwRaiseOnNilMemoryBlock(Owner, 'Create', ClassName, RsUNTerminalServer);
  JwRaiseOnNilMemoryBlock(Owner.Owner, 'Create', ClassName, RsUNTerminalServer);

  inherited Create;

  FOwner := Owner; // Session is owned by the SessionList
  // First store the SessionID
  FSessionId := SessionId;
  FShadow := TJwWTSSessionShadow.Create(Self); 
  FConnectState := ConnectState;
  FConnectStateStr := PWideCharToJwString(StrConnectState(FConnectState, False));
  FWinStationName := WinStationName;
  FApplicationName := GetSessionInfoStr(WTSApplicationName);
  FClientAddress := GetClientAddress;
  FClientBuildNumber := GetSessionInfoDWORD(WTSClientBuildNumber);
  FClientDirectory := GetSessionInfoStr(WTSClientDirectory);
  FClientHardwareId := GetSessionInfoDWORD(WTSClientHardwareId);
  FClientName := GetSessionInfoStr(WTSClientName);
  FClientProductId := GetSessionInfoDWORD(WTSClientProductId);
  FClientProtocolType := GetSessionInfoDWORD(WTSClientProtocolType);
  FClientProtocolStr := ProtocolTypeToStr(FClientProtocolType);
  FInitialProgram := GetSessionInfoStr(WTSInitialProgram);
  FWorkingDirectory := GetSessionInfoStr(WTSWorkingDirectory);
  FDomain := GetSessionInfoStr(WTSDomainName);
  FUsername := GetSessionInfoStr(WTSUsername);
  // This retreives WinStationDriver info
  GetWinStationDriver;
  // Retreive WinStationInformation
  GetWinStationInformation;
  // This function queries Terminal Server for the real remote ip address
  // and port (as opposed to WTSClientAddress which retreives the client's
  // local ip address

  tempStr := String(FRemoteAddress);
  WinStationGetRemoteIPAddress(GetServerHandle, SessionId, tempStr,
    FRemotePort);

  FRemoteAddress := WideString(tempStr);

  FToken := nil;
  FUserSid := nil;
end;

destructor TJwWTSSession.Destroy;
begin
  FreeAndNil(FShadow);
  FreeAndNil(FToken);
  FreeAndNil(FUserSid);
end;

function TJwWTSSession.GetToken : TJwSecurityToken;
begin
  result := FToken;
  if Assigned(FToken) then
    exit;

  result := nil;

  //session on another Server? : CreateWTSQueryUserTokenEx
  try
    FToken := TJwSecurityToken.CreateWTSQueryUserToken(FSessionId);
  except
    on E : EJwsclOpenProcessTokenException do
      FToken := nil;
  end;

  result := FToken;
end;

function TJwWTSSession.GetUserSid : TJwSecurityID;
begin
  GetToken;

  result := FUserSid;

  if Assigned(FUserSid) then
    exit;

  if Assigned(FToken) then
  begin
    try
      FUserSid := FToken.GetTokenUser;
    except
      on E : EJwsclSecurityException do
        FUserSid := nil;
    end;
  end
  else
    FUserSid  := nil;

  result := FUserSid;
end;

function TJwWTSSession.GetServer: TJwString;
begin
  //TODO: Owner = nil? or Owner.Owner = nil ?
  JwRaiseOnNilMemoryBlock(Owner, 'GetServerName', ClassName, RsUNTerminalServer);
  JwRaiseOnNilMemoryBlock(Owner.Owner, 'GetServerName', ClassName, RsUNTerminalServer);

  Result := Owner.Owner.Server;
end;

function TJwWTSSession.Logoff(bWait: Boolean): Boolean;
begin
  Result := WTSLogoffSession(GetServerHandle, FSessionId, bWait);
end;

function TJwWTSSession.Disconnect(bWait: Boolean): Boolean;
begin
  Result := WTSDisconnectSession(GetServerHandle, FSessionId, bWait);
end;

function TJwWTSSession.SendMessage(const AMessage: TJwString;
  const ACaption: TJwString; const uType: DWORD; const ATimeOut: DWORD): DWORD;
begin
{$IFDEF UNICODE}
  WTSSendMessageW(GetServerHandle, FSessionId, PWideChar(ACaption),
    Length(ACaption) * SizeOf(WCHAR), PWideChar(AMessage),
    Length(AMessage) * SizeOf(WCHAR), uType, ATimeOut, Result, ATimeOut <> 0);
{$ELSE}
  WTSSendMessageA(GetServerHandle, FSessionId, PChar(ACaption),
    Length(ACaption), PChar(AMessage), Length(AMessage), uType, ATimeOut,
    Result, ATimeOut <> 0);
{$ENDIF UNICODE}
end;

function TJwWTSSession.PostMessage(const AMessage: TJwString;
  const ACaption: TJwString; const uType: DWORD): DWORD;
begin
{$IFDEF UNICODE}
  WTSSendMessageW(GetServerHandle, FSessionId, PWideChar(ACaption),
    Length(ACaption) * SizeOf(WCHAR), PWideChar(AMessage),
    Length(AMessage) * SizeOf(WCHAR), uType, 0, Result, False);
{$ELSE}
    WTSSendMessageA(GetServerHandle, FSessionId, PChar(ACaption),
      Length(ACaption), PChar(AMessage), Length(AMessage), uType, 0,
      Result, False);
{$ENDIF UNICODE}
end;

function TJwWTSSession.Shadow: boolean;
begin
  // This function only exists in Unicode
  Result := WinStationShadow(GetServerHandle,
    PWideChar(WideString(GetServer)), FSessionId, VK_MULTIPLY,
    MOD_CONTROL);
end;

constructor TJwWTSProcess.Create(const Owner: TJwWTSProcessList;
  const SessionId: TJwSessionId; const ProcessID: TJwProcessId;
  const ProcessName: TJwString; const Username: TjwString);
begin
  JwRaiseOnNilParameter(Owner, 'Owner','TJwWTSProcess.Create', ClassName, RsUNTerminalServer);
  JwRaiseOnNilParameter(Owner.Owner, 'Owner.Owner','TJwWTSProcess.Create', ClassName, RsUNTerminalServer);

  inherited Create;

  FOwner := Owner;
  FSessionID := SessionId;

  FWinStationName := FOwner.Owner.GetWinStationName(SessionId);

  FProcessId := ProcessId;
  FProcessName := ProcessName;
  FUsername := Username;

  FToken := nil;
  FUserSid := nil;

end;

destructor TJwWTSProcess.Destroy;
begin
  FreeAndNil(FToken);
  FreeAndNil(FUserSid);
  inherited;
end;

function TJwWTSProcess.GetToken : TJwSecurityToken;
var hProc : HANDLE;
begin
  result := FToken;
  if Assigned(FToken) then
    exit;

  result := nil;
  JwEnablePrivilege(SE_DEBUG_NAME, pst_EnableIfAvail);

  SetLastError(0);
  hProc := OpenProcess(PROCESS_QUERY_INFORMATION, false, ProcessID);

  if hProc = 0 then
    exit;

  try
    FToken := TJwSecurityToken.CreateTokenByProcess(hProc, MAXIMUM_ALLOWED);
  except
    on E : EJwsclOpenProcessTokenException do
      FToken := nil;
  end;

  CloseHandle(hProc);

  result := FToken;
end;

function TJwWTSProcess.GetUserSid : TJwSecurityID;
begin
  GetToken;

  result := FUserSid;

  if Assigned(FUserSid) then
    exit;

  if Assigned(FToken) then
  begin
    try
      FUserSid := FToken.GetTokenUser;
    except
      on E : EJwsclSecurityException do
        FUserSid := nil;
    end;
  end
  else
    FUserSid  := nil;

  result := FUserSid;
end;

function TJwWTSProcess.GetServer;
begin
  JwRaiseOnNilMemoryBlock(Owner, 'GetServerName', ClassName, RsUNTerminalServer);
  JwRaiseOnNilMemoryBlock(Owner.Owner, 'GetServerName', ClassName, RsUNTerminalServer);

  // The Server is stored in TJwTerminalServer
  Result := Owner.Owner.Server;
end;

function TJwWTSProcess.GetServerHandle: THandle;
begin
  JwRaiseOnNilMemoryBlock(Owner, 'TJwWTSProcess.GetServerHandle', ClassName, RsUNTerminalServer);
  JwRaiseOnNilMemoryBlock(Owner.Owner, 'TJwWTSProcess.GetServerHandle', ClassName, RsUNTerminalServer);

  // The ServerHandle is stored in TJwTerminalServer
  Result := Owner.Owner.FServerHandle;
end;

function TjwWTSProcess.Terminate: Boolean;
begin
  Result := WTSTerminateProcess(GetServerHandle, ProcessId, 0);
end;

function TJwWTSProcess.Terminate(const dwExitCode: DWORD): Boolean;
begin
  Result := WTSTerminateProcess(GetServerHandle, ProcessId, dwExitCode);
end;

end.
