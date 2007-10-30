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

uses Classes, Contnrs, SysUtils, DateUtils,
  JwaWindows, 
  JwsclResource, JwsclExceptions, JwsclConstants, JwsclTypes, JwsclStrings;

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
    FSessions: TJwWTSSessionList;
    procedure SetServer(const Value: TJwString);
  protected
    procedure Close;
    function Open: THandle;
  public
    property Connected: Boolean read FConnected;
    constructor Create; virtual;
    function ConnectStateToStr(AConnectState: TWtsConnectStateClass): TJwString;
    function Enumerate: boolean;
    function FileTime2DateTime(FileTime: FileTime): TDateTime;
    property Server: TJwString read FServer write SetServer;
    property ServerHandle: THandle read FServerHandle;
    property Sessions: TJwWTSSessionList read FSessions;
  end;

  TJwWTSSession = class(TPersistent)
  private
  protected
    FApplicationName: TJwString;
    FClientAddress: TJwString;
    FClientBuildNumber: DWORD;
    FClientDirectory: TJwString;
    FHorizontalResolution: DWORD;
    FVerticalResolution: DWORD;
    FColorDepth: DWORD;
    FClientHardwareId: DWORD;
//    FClientInfo  // Vista only!
    FClientName: TJwString;
    FClientProductId: WORD;
    FClientProtocolType: WORD;
    FInitialProgram: TJwString;
//    FOEMId // Currently not used, so not implemented
    FWorkingDirectory: TJwString;
    FConnectStateStr: TJwString;
    FConnectTime: TDateTime;
    FCurrentTime: TDateTime;
    FDisconnectTime: TDateTime;
    FIdleTime: TDateTime;
    FIdleTimeStr: TJwString;
    FLastInputTime: TDateTime;
    FLogonTime: TDateTime;
    FLogonTimeStr: TJwString;
    FDomain: TJwString;
    FOwner: TJwWTSSessionList;
    FSessionId: TJwSessionId;
//    FState: TJwState;
    FConnectState: TWtsConnectStateClass;
    FUsername: TJwString;
    FWinStationName: TJwString;
    function GetClientAddress: TJwString;
    procedure GetIdleTime;
  public
    constructor Create(const AOwner: TJwWTSSessionList;
      const ASessionId: TJwSessionId; const AWinStationName: TJwString;
      const AConnectState: TWtsConnectStateClass); reintroduce;
    procedure GetClientDisplay;
    function GetOwner: TJwWTSSessionList; reintroduce;
    function GetServerHandle: THandle;
    function GetSessionInfoDWORD(const WTSInfoClass: WTS_INFO_CLASS): DWORD;
    function GetSessionInfoStr(const WTSInfoClass: WTS_INFO_CLASS): TJwString;
    procedure GetSessionInfoPtr(const WTSInfoClass: WTS_INFO_CLASS;
      var ABuffer: Pointer);
    property ApplicationName: TJwString read FApplicationName;
    property ClientAddress: TJwString read FClientAddress;
    property ClientBuildNumber: DWORD read FClientBuildNumber;
    property ClientDirectory: TJwString read FClientDirectory;
    property ClientHardwareId: DWORD read FClientHardwareId;
    property ClientName: TJwString read FClientName;
    property ClientProductId: WORD read FClientProductId;
    property ClientProtocolType: WORD read FClientProtocolType;
    property ColorDepth: DWORD read FColorDepth;
    property ConnectStateStr: TJwString read FConnectStateStr;
    property ConnectTime: TDateTime read FConnectTime;
    property CurrentTime: TDateTime read FCurrentTime;
    property DisconnectTime: TDateTime read FDisconnectTime;
    property Domain: TJwString read FDomain;
    property HorinzontalResolution: DWORD read FHorizontalResolution;
    property IdleTimeStr: TJwString read FIdleTimeStr;
    property InitialProgram: TJwString read FInitialProgram;
    property LastInputTime: TDateTime read FLastInputTime;
    property LogonTime: TDateTime read FLogonTime;
    property LogonTimeStr: TJwString read FLogonTimeStr;
    property SessionId: TJwSessionId read FSessionId;
//    property State: TJwState read FState;
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
    procedure SetItem(Index: Integer; AObject: TJwWTSSession);
  public
    function Add(ASession: TJwWTSSession): Integer;
    function Remove(ASession: TJwWTSSession): Integer;
    function IndexOf(ASession: TJwWTSSession): Integer;
    procedure Insert(Index: Integer; ASession: TJwWTSSession);
    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
    property Items[Index: Integer]: TJwWTSSession read GetItem write SetItem; default;
    procedure SetOwner(const Value: TJwTerminalServer);
    property Owner: TJwTerminalServer read FOwner write SetOwner;
  end;

  TJwWTSProcess = class(TPersistent)
  private
  protected
    FOwner: TJwWTSProcessList;
    FSessionId: TJwSessionID;
    FProcessId: TJwProcessID;
    FProcessName: TJwString;
  public
  end;

  TJwWTSProcessList = class(TPersistent)
  protected
//    function GetItem(AIndex: integer): TJwWTSProcess;
//    function GetOwner: TJwTerminalServer; override;
  public
//    constructor Create(AOwner: TPersistent);
//    procedure Delete(Index: integer);
//    procedure Refresh;
//    function GetProcess(AProcessName: TJwString): TJwWTSProcess; overload;
//    function GetProcess(AProcessId: DWORD): TJwWTSProcess; overload;
//    property Items[AIndex: integer]: TJwWTSProcess read GetItem; default;
  end;

  _WINSTATIONQUERYINFORMATIONW = record
    State: DWORD;
    WinStationName: array[0..10] of WideChar;
    Unknown1: array[0..10] of byte;
    Unknown3: array[0..10] of WideChar;
    Unknown2: array[0..8] of byte;
    SessionId: Longint;
    Reserved2: array[0..3] of byte;
    ConnectTime: FILETIME;
    DisconnectTime: FILETIME;
    LastInputTime: FILETIME;
    LogonTime: FILETIME;
    Reserved3: array[0..1011] of byte;
    Domain: array[0..17] of WideChar;
    Username: array[0..22] of WideChar;
    CurrentTime: FILETIME;
  end;

  PJwWTSSessionInfoAArray = ^TJwWTSSessionInfoAArray;
  TJwWTSSessionInfoAArray = array[0..ANYSIZE_ARRAY-1] of WTS_SESSION_INFOA;

  PJwWTSSessionInfoWArray = ^TJwWTSSessionInfoWArray;
  TJwWTSSessionInfoWArray = array[0..ANYSIZE_ARRAY-1] of WTS_SESSION_INFOW;

{$ENDIF SL_IMPLEMENTATION_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}

implementation
{$ENDIF SL_OMIT_SECTIONS}

constructor TJwTerminalServer.Create;
begin
  inherited Create;
  FSessions := TJwWTSSessionList.Create;
  FSessions.Owner := Self;
end;

procedure TJwTerminalServer.SetServer(const Value: TJwString);
begin
  FServer := Value;
end;

function TJwTerminalServer.Enumerate: boolean;
var SessionInfoPtr: {$IFDEF UNICODE}PJwWTSSessionInfoWArray;
  {$ELSE}PJwWTSSessionInfoAArray;{$ENDIF UNICODE}
  pCount: Cardinal;
  i: integer;
  Res: Longbool;
  aSession: TJwWTSSession;
begin
  Open;
  Res :=
{$IFDEF UNICODE}
    WTSEnumerateSessionsW(FhServer, 0, 1, PWTS_SESSION_INFOW(SessionInfoPtr),
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
    aSession := TJwWTSSession.Create(FSessions, SessionInfoPtr^[i].SessionId,
      SessionInfoPtr^[i].pWinStationName, TWtsConnectStateClass(SessionInfoPtr^[i].State));
    FSessions.Add(aSession);
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

function TJwTerminalServer.ConnectStateToStr(AConnectState: TWtsConnectStateClass): TJwString;
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

function TJwTerminalServer.FileTime2DateTime(FileTime: _FILETIME): TDateTime;
var
  LocalFileTime: TFileTime;
  SystemTime: TSystemTime;
begin
  FileTimeToLocalFileTime(FileTime, LocalFileTime);
  FileTimeToSystemTime(LocalFileTime, SystemTime);
  Result := SystemTimeToDateTime(SystemTime);
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

procedure TJwWTSSessionList.SetItem(Index: Integer; AObject: TJwWTSSession);
begin
  inherited Items[Index] := AObject;
end;

procedure TJwWTSSessionList.SetOwner(const Value: TJwTerminalServer);
begin
  FOwner := Value;
end;

function TJwWTSSession.GetOwner;
begin
  Result := FOwner;
end;

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
    Result := TJwString(TJwPChar(aBuffer));
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
  Result := GetOwner.Owner.ServerHandle;
end;

procedure TJwWTSSession.GetIdleTime;
var Days, Hours, Minutes: Word;
{$IFDEF COMPILER7_UP}
  FS: TFormatSettings;
{$ENDIF COMPILER7_UP}
begin
{$IFDEF COMPILER7_UP}
  GetLocaleFormatSettings(LOCALE_SYSTEM_DEFAULT, FS);
{$ENDIF COMPILER7_UP}
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
      Result := 'Unspecified Address';
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
var
  // #todo: reverse _WINSTATIONQUERYINFORMATIONA structure?
  WinStationInfoPtr: _WINSTATIONQUERYINFORMATIONW;
  dwReturnLength: DWORD;
begin
  FOwner := AOwner;

  FSessionId := ASessionId;
  FWinStationName := AWinStationName;
//  FState := Cardinal(AState);
  FConnectState := AConnectState;

  FConnectStateStr := GetOwner.Owner.ConnectStateToStr(FConnectState);

  if WinStationQueryInformationW(GetServerHandle, ASessionId,
    WinStationInformation, @WinStationInfoPtr, SizeOf(WinStationInfoPtr),
    dwReturnLength) then
  begin
    FApplicationName := GetSessionInfoStr(WTSApplicationName);

    FClientAddress := GetClientAddress;

    FClientBuildNumber := GetSessionInfoDWORD(WTSClientBuildNumber);
    FClientDirectory := GetSessionInfoStr(WTSClientDirectory);
    FClientHardwareId := GetSessionInfoDWORD(WTSClientHardwareId);
    FClientName := GetSessionInfoStr(WTSClientName);
    FClientProductId := GetSessionInfoDWORD(WTSClientProductId);
    FClientProtocolType := GetSessionInfoDWORD(WTSClientProtocolType);
    FInitialProgram := GetSessionInfoStr(WTSInitialProgram);
    FWorkingDirectory := GetSessionInfoStr(WTSWorkingDirectory);
    FDomain := WinStationInfoPtr.Domain;
    FUsername := WinStationInfoPtr.Username;
    FConnectTime := FileTime2DateTime(WinStationInfoPtr.ConnectTime);
    FDisconnectTime := FileTime2DateTime(WinStationInfoPtr.DisconnectTime);
    FLastInputTime := FileTime2DateTime(WinStationInfoPtr.LastInputTime);
    FLogonTime := FileTime2DateTime(WinStationInfoPtr.LogonTime);
    FCurrentTime := FileTime2DateTime(WinStationInfoPtr.CurrentTime);

    GetIdleTime;
  end;
end;

end.
