{@abstract(This unit provides access to Terminal Server api functions)
@author(Remko Weijnen)
@created(10/26/2007)
@lastmod(10/26/2007)
This unit contains types that are used by the units of the Security Manager Suite


Project JEDI Windows Security Code Library (JWSCL)

The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy of the
License at http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
ANY KIND, either express or implied. See the License for the specific language governing rights
and limitations under the License.

The Original Code is JwsclTerminalServer.pas.

The Initial Developer of the Original Code is Remko Weijnen.
Portions created by Remko Weijnen are Copyright (C) Remko Weijnen. All rights reserved.
}
{$IFNDEF SL_OMIT_SECTIONS}
unit JwsclTerminalServer;
{$I Jwscl.inc}

interface

uses Classes, Contnrs, DateUtils, SysUtils,
{$IFDEF UNICODE}
  JclUnicode,
{$ENDIF UNICODE}
  JwaWindows,
  JwsclConstants, JwsclExceptions, JwsclResource, JwsclSid, JwsclTypes,
  JwsclVersion, JwsclStrings;

{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_IMPLEMENTATION_SECTION}
type

  { forward declarations }
  TJwTerminalServer = class;
  TJwWTSSession = class;
  TJwWTSSessionList = class;
  TJwWTSProcess = class;
  TJwWTSProcessList = class;

  TJwTerminalServer = class(TPersistent)
  private
    FConnected: Boolean;
    FServer: TJwString;
    FServerHandle: THandle;
    FServers: {$IFDEF UNICODE}TWideStringList{$ELSE}TStringList{$ENDIF UNICODE};
    FSessions: TJwWTSSessionList;
    FProcesses: TJwWTSProcessList;
    function GetServers: {$IFDEF UNICODE}TWideStringList{$ELSE}TStringList{$ENDIF UNICODE};
    procedure SetServer(const Value: TJwString);
  protected
    procedure Close;
    function Open: THandle;
  public
    property Connected: Boolean read FConnected;
    constructor Create;
    destructor Destroy; override;
    function EnumerateProcesses: boolean;
    function EnumerateServers: boolean;
    function EnumerateSessions: boolean;
    function FileTime2DateTime(FileTime: TFileTime): TDateTime;
    property Processes: TJwWTSProcessList read FProcesses;
    property Server: TJwString read FServer write SetServer;
    property ServerHandle: THandle read FServerHandle;
    property Servers: {$IFDEF UNICODE}TWideStringList{$ELSE}
      TStringList{$ENDIF UNICODE} read GetServers;
    property Sessions: TJwWTSSessionList read FSessions;
  end;

  TJwWTSSession = class(TPersistent)
  private
  protected
    //TODO: I usually do not comment these things because
    //they are already commented in the property declaration
    FApplicationName: TJwString;
    FClientAddress: TJwString;
    FClientBuildNumber: DWORD;
    FColorDepth: DWORD;
    FClientDirectory: TJwString;
    FClientHardwareId: DWORD;
//    FClientInfo  // Vista only!
    FClientName: TJwString;
    FClientProductId: WORD;
    FClientProtocolType: WORD;
    FClientProtocolStr: TJwString;
//    FOEMId // Currently not used, so not implemented
    FConnectState: TWtsConnectStateClass;
    FConnectStateStr: TJwString;
    FConnectTime: TDateTime;
    FCurrentTime: TDateTime;
    FDisconnectTime: TDateTime;
    FDomain: TJwString;
    FIdleTime: TDateTime;
    FIdleTimeStr: TJwString;
    FHorizontalResolution: DWORD;
    FInitialProgram: TJwString;
    FLastInputTime: TDateTime;
    FLogonTime: TDateTime;
    FLogonTimeStr: TJwString;
    FOwner: TJwWTSSessionList;
    FProtocolTypeStr: TJwString;
    FSessionId: TJwSessionId;
//    FState: TJwState;
    FUsername: TJwString;
    FVerticalResolution: DWORD;
    FWinStationName: TJwString;
    FWorkingDirectory: TJwString;

    //TODO: this func should be documented but not so detailed because of protected
    procedure GetClientDisplay;
    procedure CalculateIdleTime;
    function GetSessionInfoDWORD(const WTSInfoClass: WTS_INFO_CLASS): DWORD;
    procedure GetSessionInfoPtr(const WTSInfoClass: WTS_INFO_CLASS;
      var ABuffer: Pointer);
    function GetSessionInfoStr(const WTSInfoClass: WTS_INFO_CLASS): TJwString;
  public
    {TODO: @Name create a new session here. <add here more information>

     Maybe some sample code to show problems or so ("#" is neccessary)
     @longcode(#
      var P : TJwWTSSession;
      begin
      end;
     #)

     Lists:
     @unorderedlist(
      @item(item1)
      @item(items2)
     )
     @orderedlist(
      @item(item1)
      @item(items2)
     )

     Find out more here: http://pasdoc.sipsolutions.net/SupportedTags

     <Properties do no have the following tags:>

     @param(AOwner receives the owner session list. It will be available
        through the property Owner. This parameter must not be nil.
        <Always adda precondition. like: must not be nil or zero.
        A precondition is tested in the function and a exception is raised.>
        )
     @param(ASessionId ...)
     <@return(Return value makes bla - only functions. Say something
      about the value semantic. Maybe : return of 0 means something special.
      Or the return value must be/must not be freed by the caller.
      )>

     @raises(EJwSecurityException <Show here the reason for that exception type.
        Also for every failed precondition >)
     @raises(EJwsclTerminalServerException < Create your own  >)
     @raises(EJwsclTerminalSessionException < dito>)
     @raises(EJwsclWinCallFailedException <winAPI call failed. Its always called that!>)
     @raises(EJwsclNILParameterException <a parameter is nil. Search for
      that exception in other classes for an example>)


  }
    constructor Create(const AOwner: TJwWTSSessionList;
      const ASessionId: TJwSessionId; const AWinStationName: TJwString;
      const AConnectState: TWtsConnectStateClass); reintroduce;
    property ApplicationName: TJwString read FApplicationName;
    property ClientAddress: TJwString read FClientAddress;
    property ClientBuildNumber: DWORD read FClientBuildNumber;
    property ClientDirectory: TJwString read FClientDirectory;
    property ClientHardwareId: DWORD read FClientHardwareId;
    property ClientName: TJwString read FClientName;
    property ClientProductId: WORD read FClientProductId;
    property ClientProtocolType: WORD read FClientProtocolType;
    property ClientProtocolStr: TJwString read FClientProtocolStr;
    property ColorDepth: DWORD read FColorDepth;
    property ConnectStateStr: TJwString read FConnectStateStr;
    function ConnectStateToStr(AConnectState: TWtsConnectStateClass): TJwString;
    property ConnectTime: TDateTime read FConnectTime;
    property CurrentTime: TDateTime read FCurrentTime;
    function Disconnect(bWait: Boolean): Boolean;
    property DisconnectTime: TDateTime read FDisconnectTime;
    property Domain: TJwString read FDomain;
    function GetClientAddress: TJwString;
    function GetServerHandle: THandle;
    function GetServerName: TJwString;
    property HorizontalResolution: DWORD read FHorizontalResolution;
    property IdleTimeStr: TJwString read FIdleTimeStr;
    property InitialProgram: TJwString read FInitialProgram;
    property LastInputTime: TDateTime read FLastInputTime;
    function Logoff(bWait: Boolean): Boolean;
    property LogonTime: TDateTime read FLogonTime;
    property LogonTimeStr: TJwString read FLogonTimeStr;
    property Owner: TJwWTSSessionList read FOwner;
    function PostMessage(const AMessage: TJwString; const ACaption: TJwString;
      const uType: DWORD): DWORD;
    function ProtocolTypeToStr(AProtocolType: DWORD): TJwString;
    function SendMessage(const AMessage: TJwString; const ACaption: TJwString;
      const uType: DWORD; const ATimeOut: DWORD): DWORD;
    property SessionId: TJwSessionId read FSessionId;
    function Shadow: boolean;
    property Username: TJwString read FUsername;
    property VerticalResolution: DWORD read FVerticalResolution;
    property WinStationName: TJwString read FWinStationName;
    property WorkingDirectory: TJwString read FWorkingDirectory;
  end;

  { List Of TJwWTSSession Objects }
  TJwWTSSessionList = class(TObjectList)
  private
    FOwnsObjects: Boolean;
    FOwner: TJwTerminalServer;
  protected
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
    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
    function Remove(ASession: TJwWTSSession): Integer;
  end;

  TJwWTSProcess = class(TPersistent)
  private
  protected
    FOwner: TJwWTSProcessList;
    FSessionId: TJwSessionID;
    FProcessId: TJwProcessID;
    FProcessName: TJwString;
    FUsername: TJwString;
    FWinStationName: TJwString;
  public
    constructor Create(const AOwner: TJwWTSProcessList;
      const ASessionId: TJwSessionId; const AProcessID: TJwProcessId;
      const AProcessName: TJwString; const AUsername: TJwString); reintroduce;
    function GetServerHandle: THandle;
    property Owner: TJwWTSProcessList read FOwner;
    property SessionId: TJwSessionId read FSessionId;
    property ProcessId: TJwProcessId read FProcessId;
    property ProcessName: TJwString read FProcessName;
    property Username: TJwString read FUsername;
    property WinStationName: TJwString read FWinStationname;
  end;

  { List Of TJwWTSProcess Objects }
  TJwWTSProcessList = class(TObjectList)
  private
    FOwnsObjects: Boolean;
    FOwner: TJwTerminalServer;
  protected
    function GetItem(Index: Integer): TJwWTSProcess;
    procedure SetItem(Index: Integer; AProcess: TJwWTSProcess);
    procedure SetOwner(const Value: TJwTerminalServer);
  public
    function Add(AProcess: TJwWTSProcess): Integer;
    function IndexOf(AProcess: TJwWTSProcess): Integer;
    procedure Insert(Index: Integer; AProcess: TJwWTSProcess);
    property Items[Index: Integer]: TJwWTSProcess read GetItem write SetItem; default;
    property Owner: TJwTerminalServer read FOwner write SetOwner;
    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
    function Remove(AProcess: TJwWTSProcess): Integer;
  end;

  { array of TWtsSessionInfoA }
  PJwWTSSessionInfoAArray = ^TJwWTSSessionInfoAArray;
  TJwWTSSessionInfoAArray = array[0..ANYSIZE_ARRAY-1] of TWtsSessionInfoA;

  { array of TWtsSessionInfoA }
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
{$ENDIF SL_IMPLEMENTATION_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}

implementation
{$ENDIF SL_OMIT_SECTIONS}
constructor TJwTerminalServer.Create;
begin
  inherited Create;
  FSessions := TJwWTSSessionList.Create(True);
  FSessions.Owner := Self;
  FProcesses := TJwWTSProcessList.Create(True);
  FProcesses.Owner := Self;
end;

destructor TJwTerminalServer.Destroy;
begin
  // Close connection
  if Connected then
  begin
    Close;
  end;

  // Free the SessionList
  if Assigned(FSessions) then
  begin
    FSessions.Free;
  end;

    // Free the ProcessList
  if Assigned(FProcesses) then
  begin
    FProcesses.Free;
  end;

  // Free the Serverlist
  if Assigned(FServers) then
  begin
    FServers.Free;
  end;

  inherited;
end;

procedure TJwTerminalServer.SetServer(const Value: TJwString);
begin
  FServer := Value;
end;

function TJwTerminalServer.EnumerateProcesses;
var Res: Bool;
  pCount: Cardinal;
  Sid: TJwSecurityId;
  Username: TJwString;
  ProcessInfoPtr:
{$IFDEF UNICODE}
  PJwWtsProcessInfoWArray;
{$ELSE}
  PJwWtsProcessInfoAArray;
{$ENDIF UNICODE}
  i: Integer;
  AProcess: TJwWTSProcess;
  cbUserName: DWORD;
  pwUserName: PWideChar;
begin
  FProcesses.Clear;
  Open;
  if not Connected then
  begin
    Result := False;
    Exit;
  end;
  Res :=
{$IFDEF UNICODE}
  WTSEnumerateProcessesW(FServerHandle, 0, 1, PWTS_PROCESS_INFOW(ProcessInfoPtr),
    pCount);
{$ELSE}
  WTSEnumerateProcessesA(FServerHandle, 0, 1, PWTS_PROCESS_INFOA(ProcessInfoPtr),
    pCount);
{$ENDIF UNICODE}
  if Res then
  begin
    for i := 0 to pCount - 1 do
    begin
      if ProcessInfoPtr^[i].ProcessId = 0 then
      begin
        ProcessInfoPtr^[i].pProcessName := 'System Idle Process';
        Username := 'SYSTEM';
      end;
      if ProcessInfoPtr^[i].pUserSid <> nil then
      begin
{        with TJwSecurityID.Create(ProcessInfoPtr^[i].pUserSid) do
        begin
          Username := GetChachedUserFromSid;
          Free;
        end;}
        cbUserName := UNLen * SizeOf(WCHAR);
        GetMem(pwUserName, cbUserName);
        CachedGetUserFromSid(ProcessInfoPtr^[i].pUserSid, pwUsername,
          cbUsername);
        if pwUserName <> nil then
        begin
          Username := TJwString(pwUserName);
        end;
        FreeMem(pwUserName);
      end;
      AProcess := TJwWTSProcess.Create(FProcesses, ProcessInfoPtr^[i].SessionId,
        ProcessInfoPtr^[i].ProcessId, ProcessInfoPtr^[i].pProcessName,
        Username);
      FProcesses.Add(AProcess);
    end;
    WTSFreeMemory(ProcessInfoPtr);
  end;
  Result := Res;
end;

function TJwTerminalServer.GetServers: {$IFDEF UNICODE}TWideStringList{$ELSE}TStringList{$ENDIF UNICODE};
begin
  // Create the list
  if not assigned(FServers) then
  begin
{$IFDEF UNICODE}
    FServers := TWideStringList.Create;
{$ELSE}
    FServers := TStringList.Create;
{$ENDIF UNICODE}
    // The list was empty so fill it!
    EnumerateServers;
  end;

  // Return the serverlist
  Result := FServers;
end;

function TJwTerminalServer.EnumerateServers: Boolean;
var Res: Bool;
  ServerInfoPtr:
{$IFDEF UNICODE}
  PJwWtsServerInfoWArray;
{$ELSE}
  PJwWtsServerInfoAArray;
{$ENDIF UNICODE}
  pCount: DWORD;
  i: DWORD;
begin
  // Clear the Serverlist
  FServers.Clear;
  Res :=
{$IFDEF UNICODE}
  WTSEnumerateServersW(nil, 0, 1, PWTS_SERVER_INFOW(ServerInfoPtr), pCount);
{$ELSE}
  WTSEnumerateServersA(nil, 0, 1, PWTS_SERVER_INFOA(ServerInfoPtr), pCount);
{$ENDIF UNICODE}
  if Res then
  begin
    for i := 0 to pCount - 1 do
    begin
      FServers.Add(ServerInfoPtr^[i].pServerName);
    end;
  end
  else begin
    MessageBox(0, PChar(SysErrorMessage(hResult(GetLastError))), 'WTSEnumerateServers', MB_OK);
  end;

  if ServerInfoPtr <> nil then
  begin
    WTSFreeMemory(ServerInfoPtr);
  end;
  Result := Res;
end;

function TJwTerminalServer.EnumerateSessions: boolean;
var SessionInfoPtr: {$IFDEF UNICODE}PJwWTSSessionInfoWArray;
  {$ELSE}PJwWTSSessionInfoAArray;{$ENDIF UNICODE}
  pCount: Cardinal;
  i: integer;
  Res: Longbool;
  ASession: TJwWTSSession;
begin
  Open;
  if not Connected then
  begin
    Result := False;
    Exit;
  end;

  Res :=
{$IFDEF UNICODE}
    WTSEnumerateSessionsW(FServerHandle, 0, 1, PWTS_SESSION_INFOW(SessionInfoPtr),
      pCount);
{$ELSE}
    WTSEnumerateSessions(FServerHandle, 0, 1, PWTS_SESSION_INFOA(SessionInfoPtr),
      pCount);
{$ENDIF UNICODE}

  // Clear the sessionslist
  FSessions.Clear;

  // Add all sessions to the SessionList
  for i := 0 to pCount - 1 do
  begin
    ASession := TJwWTSSession.Create(FSessions, SessionInfoPtr^[i].SessionId,
      SessionInfoPtr^[i].pWinStationName, TWtsConnectStateClass(SessionInfoPtr^[i].State));
    FSessions.Add(ASession);
  end;

  // Pass the result
  Result := Res;
  Close;
end;

function TJwTerminalServer.Open: THandle;
begin
  if FServer = '' then
  begin
    Result := WTS_CURRENT_SERVER_HANDLE;
    FConnected := True;
  end
  else
  begin
{$IFDEF UNICODE}
    Result := WTSOpenServerW(PWideChar(WideString(FServer)));
{$ELSE}
    Result := WTSOpenServer(PChar(FServer));
{$ENDIF}
    FConnected := Result > 0;
  end;
end;

procedure TJwTerminalServer.Close;
begin
  if FServerHandle <> WTS_CURRENT_SERVER_HANDLE then
  begin
    WTSCloseServer(FServerHandle);
  end;
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

procedure TJwWTSProcessList.SetOwner(const Value: TJwTerminalServer);
begin
  FOwner := Value;
end;

function TJwWTSSession.ConnectStateToStr(AConnectState: TWtsConnectStateClass): TJwString;
begin
  case AConnectState of
    WTSActive: Result := 'Active';
    WTSConnected: Result := 'Connected';
    WTSConnectQuery: Result := 'ConnectQuery';
    WTSShadow: Result := 'Shadowing';
    WTSDisconnected: Result := 'Disconnected';
    WTSIdle: Result := 'Idle';
    WTSListen: Result := 'Listening';
    WTSReset: Result := 'Reset';
    WTSDown: Result := 'Down';
    WTSInit: Result := 'Init';
  else
    Result := 'Unidentified state';  // should never happen
  end;
end;

function TJwWTSSession.ProtocolTypeToStr(AProtocolType: Cardinal): TJwString;
begin
  case AProtocolType of
    WTS_PROTOCOL_TYPE_CONSOLE: Result := 'Console';
    WTS_PROTOCOL_TYPE_ICA: Result := 'ICA';
    WTS_PROTOCOL_TYPE_RDP: Result := 'RDP';
  else
    Result := '';  // Should never happen
  end;
end;

{function TJwWTSSession.GetOwner;
begin
  Result := FOwner;
end;}

procedure TJwWTSSession.GetSessionInfoPtr(const WTSInfoClass: _WTS_INFO_CLASS;
  var ABuffer: Pointer);
var dwBytesReturned: DWORD;
  Res: Bool;
begin
  Res :=
{$IFDEF UNICODE}
    WTSQuerySessionInformationW(GetServerHandle, FSessionId, WTSInfoClass,
      ABuffer, dwBytesReturned);
{$ELSE}
    WTSQuerySessionInformationA(GetServerHandle, FSessionId, WTSInfoClass,
      ABuffer, dwBytesReturned);
{$ENDIF}
  // function always returns an error 997: overlapped IO on session 0
  if (not Res) and (FSessionId <> 0) then
  begin
    raise EJwsclWinCallFailedException.CreateFmtWinCall(RsWinCallFailed,
      'WTSQuerySessionInformation', ClassName, RSUNTerminalServer, 0, True,
      'WTSQuerySessionInformation', ['WTSQuerySessionInformation']);
  end;
end;

function TJwWTSSession.GetSessionInfoStr(const WTSInfoClass: _WTS_INFO_CLASS):
  TJwString;
var
  dwBytesReturned: DWORD;
  aBuffer: Pointer;
  Res: Bool;
begin
  ABuffer := nil;
  Result := '';
  Res :=
{$IFDEF UNICODE}
    WTSQuerySessionInformationW(GetServerHandle, FSessionId, WTSInfoClass,
      ABuffer, dwBytesReturned);
{$ELSE}
    WTSQuerySessionInformationA(GetServerHandle, FSessionId, WTSInfoClass,
      ABuffer, dwBytesReturned);
{$ENDIF UNICODE}
  // function always returns an error 997: overlapped IO on session 0
  if (not Res) and (FSessionId <> 0) then
  begin
    raise EJwsclWinCallFailedException.CreateFmtWinCall(RsWinCallFailed,
      'WTSQuerySessionInformation', ClassName, RSUNTerminalServer, 0, True,
      'WTSQuerySessionInformation', ['WTSQuerySessionInformation']);
  end
  else if ABuffer <> nil then
  begin
    Result :=
{$IFDEF UNICODE}
    TJwString(PWideChar(aBuffer));
{$ELSE}
    TJwString(PChar(aBuffer));
{$ENDIF UNICODE}
    WTSFreeMemory(aBuffer);
  end;
end;

function TJwWTSSession.GetSessionInfoDWORD(const WTSInfoClass: _WTS_INFO_CLASS): DWORD;
var dwBytesReturned: DWORD;
  ABuffer: Pointer;
  Res: Bool;
begin
  ABuffer := nil;
  Result := 0;
  Res :=
{$IFDEF UNICODE}
    WTSQuerySessionInformationW(GetServerHandle, FSessionId, WTSInfoClass,
      ABuffer, dwBytesReturned);
{$ELSE}
    WTSQuerySessionInformationA(GetServerHandle, FSessionId, WTSInfoClass,
      ABuffer, dwBytesReturned);
{$ENDIF}
  // function always returns an error 997: overlapped IO on session 0
  if (not Res) and (FSessionId <> 0) then
  begin
    raise EJwsclWinCallFailedException.CreateFmtWinCall(RsWinCallFailed,
      'WTSQuerySessionInformation', ClassName, RSUNTerminalServer, 0, True,
      'WTSQuerySessionInformation', ['WTSQuerySessionInformation']);
  end
  else if ABuffer <> nil then
  begin
    Result := PDWord(ABuffer)^;
    WTSFreeMemory(ABuffer);
  end;
end;

function TJwWTSSession.GetServerHandle;
begin
  // The ServerHandle is stored in TJwTerminalServer
  Result := Owner.Owner.FServerHandle;
end;

// #todo Remove IdleTime helper from JwaWinsta
procedure TJwWTSSession.CalculateIdleTime;
var Days, Hours, Minutes: Word;
  // #todo: reverse _WINSTATIONQUERYINFORMATIONA structure?
  WinStationInfoPtr: _WINSTATIONQUERYINFORMATIONW;
  dwReturnLength: DWORD;
{$IFDEF COMPILER7_UP}
  FS: TFormatSettings;
{$ENDIF COMPILER7_UP}
begin
{$IFDEF COMPILER7_UP}
  GetLocaleFormatSettings(LOCALE_SYSTEM_DEFAULT, FS);
{$ENDIF COMPILER7_UP}

  ZeroMemory(@WinStationInfoPtr, SizeOf(WinStationInfoPtr));

  if WinStationQueryInformationW(GetServerHandle, FSessionId,
    WinStationInformation, @WinStationInfoPtr, SizeOf(WinStationInfoPtr),
    dwReturnLength) then
  begin
    FConnectTime := FileTime2DateTime(WinStationInfoPtr.ConnectTime);
    FDisconnectTime := FileTime2DateTime(WinStationInfoPtr.DisconnectTime);
    FLastInputTime := FileTime2DateTime(WinStationInfoPtr.LastInputTime);
    FLogonTime := FileTime2DateTime(WinStationInfoPtr.LogonTime);
    FCurrentTime := FileTime2DateTime(WinStationInfoPtr.CurrentTime);

    if YearOf(FLogonTime) = 1601 then
    begin
      FLogonTimeStr := '';
    end
    else begin
    {$IFDEF COMPILER7_UP}
      FLoginTimeStr := DateTimeToStr(FLogonTime, FS);
    {$ELSE}
      FLogonTimeStr := DateTimeToStr(FLogonTime);
    {$ENDIF COMPILER7_UP}
    end;

    // Disconnected session = idle since DisconnectTime
    if YearOf(FLastInputTime) = 1601 then
    begin
      FLastInputTime := FDisconnectTime;
    end;

    FIdleTime := FLastInputTime - FCurrentTime;
    Days := Trunc(FIdleTime);
    Hours := HourOf(FIdleTime);
    Minutes := MinuteOf(FIdleTime);
    if Days > 0 then begin
      FIdleTimeStr := Format('%dd %d:%1.2d', [Days, Hours, Minutes]);
    end
    else if Hours > 0 then begin
      FIdleTimeStr := Format('%d:%1.2d', [Hours, Minutes]);
    end
    else if Minutes > 0 then begin
      FIdleTimeStr := IntToStr(Minutes);
    end
    else begin
      FIdleTimeStr := '.';
    end;
    if YearOf(FLogonTime) = 1601 then
    begin
      FIdleTimeStr := '.';
    end;
  end;
end;

function TJwWTSSession.GetClientAddress: TJwString;
var ClientAddressPtr: PWtsClientAddress;
begin
  GetSessionInfoPtr(WTSClientAddress, Pointer(ClientAddressPtr));
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
      Result := 'IPX is not supported';
    AF_NETBIOS:
      Result := 'NETBIOS is not supported';
    AF_UNSPEC:
      Result := '';
  end;
  WTSFreeMemory(ClientAddressPtr);
end;

procedure TJwWTSSession.GetClientDisplay;
var ClientDisplayPtr: PWtsClientDisplay;
begin
  GetSessionInfoPtr(WTSClientDisplay, Pointer(ClientDisplayPtr));
  FHorizontalResolution := ClientDisplayPtr^.HorizontalResolution;
  FVerticalResolution := ClientDisplayPtr^.VerticalResolution;
  FColorDepth := ClientDisplayPtr^.ColorDepth;
  WTSFreeMemory(ClientDisplayPtr);
end;

constructor TJwWTSSession.Create(const AOwner: TJwWTSSessionList;
  const ASessionId: TJwSessionId; const AWinStationName: TJwString;
  const AConnectState: TWtsConnectStateClass);
begin
  FOwner := AOwner; // Session is owned by the SessionList
  // First store the SessionID
  FSessionId := ASessionId;
  FConnectState := AConnectState;
  FConnectStateStr := ConnectStateToStr(FConnectState);
  FWinStationName := AWinStationName;

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
  FDomain := GetSessionInfoStr(WTSDomainName); // Documented way:
  // FDomain := WinStationInfoPtr.Domain; // Undocumented way:
  FUsername := GetSessionInfoStr(WTSUsername); // Documented way:
  // FUsername := WinStationInfoPtr.Username; // Undocumented way:

//  if TJwWindowsVersion.IsWindowsVista(True) then
//  begin
    // Status: Not implemented yet}
    { Vista SP1 has a documented way of retrieving idle time, although
      the documentation is preliminary and is subject to change
      see here: http://msdn2.microsoft.com/en-us/library/bb736370.aspx}
//  end
//  else begin
    { Use undocumented API to retrieve Idle and LoginTime }
    { this is for Windows 2000, Windows XP and Windows 2003 }
    { Might work on Windows Vista and Windows Server 2008 (not tested) }
    { not expected to work on Windows NT 4 (not tested) }
    CalculateIdleTime;
//  end;
end;

function TJwWTSSession.GetServerName: TJwString;
begin
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
    PWideChar(WideString(GetServerName)), FSessionId, VK_MULTIPLY,
    MOD_CONTROL);
end;

constructor TJwWTSProcess.Create(const AOwner: TJwWTSProcessList;
  const ASessionId: TJwSessionId; const AProcessID: TJwProcessId;
  const AProcessName: TJwString; const AUsername: TjwString);
var pWinStationName:{$IFDEF UNICODE}PWideChar{$ELSE}PAnsiChar{$ENDIF UNICODE};
begin
  FOwner := AOwner;
  FSessionID := ASessionId;
{$IFDEF UNICODE}
  GetMem(pWinStationName, WINSTATIONNAME_LENGTH * SizeOf(WideChar));
  if WinStationNameFromLogonIdW(GetServerHandle, FSessionId,
    pWinStationName) then
  begin

  end
  else begin
    MessageBox(0, PChar(SysErrorMessage(GetLastError)), 'WinstationName', MB_OK);
  end;
{$ELSE}
  GetMem(pWinStationName, WINSTATIONNAME_LENGTH);
  WinStationNameFromLogonIdA(GetServerHandle, FSessionId,
    pWinStationName);
{$ENDIF UNICODE}
  FWinstationName := pWinStationName;
  FreeMem(pWinStationName);
  FProcessId := AProcessId;
  FProcessName := AProcessName;
  FUsername := AUsername;
end;

function TJwWTSProcess.GetServerHandle: THandle;
begin
  // The ServerHandle is stored in TJwTerminalServer
  Result := Owner.Owner.FServerHandle;
end;

end.
