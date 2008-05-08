{
The contents of this file is released under the terms of the
GNU General Public License 3.0 (the  "GPL License").

For more information about the GPL: http://www.gnu.org/licenses/gpl-3.0.txt

Original author is: Christian Wimmer
This application is part of the JEDI API Project.
Visit at http://blog.delphi-jedi.net/

}
unit RunAsSysService;

interface

uses
  JWaWindows, JwsclToken, JwsclProcess,
  Jwscl, JwsclKnownSid, JwsclLogging, uLogging,
  Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs;

type
  TRunAsSysSvc3 = class(TService)
    procedure ServiceExecute(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
  private
    { Private-Deklarationen }
    procedure OnWinLogonFoundInSameSession(const Sender2 : TJwTerminalServer; var Process : TJwWTSProcess;
      var Cancel : Boolean; Data : Pointer);
  public
    function GetServiceController: TServiceController; override;
    { Public-Deklarationen }
    procedure DoExecute;
  end;

  TServiceApplicationEx = class(TServiceApplication)
  public
    procedure RegisterServices(Install, Silent: Boolean);
  end;

var
  RunAsSysSvc3 : TRunAsSysSvc3;

implementation

{$R *.DFM}

function GetParameterValue(const Name : AnsiString) : AnsiString;
begin
end;


type
  PInternalProcessData = ^TInternalProcessData;
  TInternalProcessData = record
    SessionID : DWORD;
  end;

procedure TRunAsSysSvc3.OnWinLogonFoundInSameSession(const Sender2 : TJwTerminalServer; var Process : TJwWTSProcess;
      var Cancel : Boolean; Data : Pointer);

var ProcessData : PInternalProcessData absolute Data;
begin
  Cancel :=
      {
        same session
      }
      (Process.SessionId = ProcessData.SessionID)

      {
        no idle process
      }
      and (Process.ProcessId > 0)
      {
        We have to check for system processes in that session.
        So we ignore them otherwise the user gets a system elevated process.
      }
      and (Assigned(Process.UserSid) and Process.UserSid.EqualSid(JwLocalSystemSID));
end;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  RunAsSysSvc3.Controller(CtrlCode);
end;


{ TServiceApplicationEx }

procedure TServiceApplicationEx.RegisterServices(Install, Silent: Boolean);
begin
  inherited;
end;

{ TRunAsSysSvc }

procedure TRunAsSysSvc3.DoExecute;
begin
  Self.ServiceExecute(nil);
end;

function TRunAsSysSvc3.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

{.$DEFINE CMD}
procedure TRunAsSysSvc3.ServiceExecute(Sender: TService);

function _ParamCount : Integer;
begin
{$IFDEF CMD}
  result := System.ParamCount;
{$ELSE}
  result := Self.ParamCount;
{$ENDIF}
end;

function _Param(index : Integer) : String;
begin
{$IFDEF CMD}
  result := System.ParamStr(Index);
{$ELSE}
  try
    result := Self.Param[Index];
  except
    result := '';
  end;
{$ENDIF}
end;

var
  UserToken : TJwSecurityToken;

  iP, i2 : Integer;
  Parameter : WideString;
  pParameter : PWideChar;

  StartupInfo : TStartupInfoW;
  ProcessInfo : TProcessInformation;

  P : Pointer;
  CmdLine : WideString;

  Data : TInternalProcessData;
  Meth : TMethod;
  Log : IJwLogClient;
  Flags : Cardinal;
begin
  Log := uLogging.LogServer.Connect(etThread, '','Service Execute','RunAsSysService.pas','Entering service main thread');

  //Sleep(10000);

  CmdLine := '';
  for iP := 0 to _ParamCount  do
  begin
    CmdLine := CmdLine + #13#10 + _Param(iP);
  end;
  Log.Log('Command line: '+CmdLine);

  LogMessage(CmdLine,EVENTLOG_INFORMATION_TYPE	,000,000);

  if (_ParamCount < 2) or (
      ((_ParamCount > 0) and (StrToIntDef(_Param(1),-1) < 0))) then
  begin
    Win32ErrCode := ERROR_INVALID_PARAMETER;
    Log.Log(lsError, 'Invalid Parameter count');
    exit;
  end;


  Data.SessionID := StrToIntDef(_Param(1), -1);

  if Data.SessionID = -1 then
  begin
    LogMessage('Given parameter SessionID is invalid',EVENTLOG_ERROR_TYPE);
    Win32ErrCode := ERROR_INVALID_PARAMETER;
    Log.Log(lsError, 'Invalid Parameter session');
    exit;
  end;

  try
    //UserToken := TJwSecurityToken.CreateWTSQueryUserTokenEx(nil, StrToIntDef(_Param(1),0));
    UserToken := JwGetTokenFromProcess (OnWinLogonFoundInSameSession, nil, @Data);
  except
    on E : Exception do
    begin
      LogMessage('Could not get token from user:'+E.Message,EVENTLOG_ERROR_TYPE);
      Win32ErrCode := ERROR_INVALID_DATA;
      exit;
    end;
  end;
  try
    Flags := CREATE_UNICODE_ENVIRONMENT or CREATE_NEW_CONSOLE;

    if not CreateEnvironmentBlock(@P, UserToken.TokenHandle, true) then
    begin
      Log.Log(lsError, 'Could not get user environment: '+IntToStr(GetLastError));
      P := nil;
      Flags := Flags and not CREATE_UNICODE_ENVIRONMENT;
    end;


    //get rest of parameters
    Parameter := _Param(2);

    if _ParamCount > 2 then
    begin
      CmdLine := '';
      for iP := 3 to _ParamCount-1 do
      begin
        CmdLine := CmdLine + ' ' + _Param(iP);
      end;
    end;


    ZeroMemory(@StartupInfo, sizeof(StartupInfo));
    StartupInfo.lpDesktop := ('winsta0\default');
    try
      Log.Log(lsMessage, 'Calling CreateProcessAsUser...');
      if not CreateProcessAsUserW(
            UserToken.TokenHandle,
                PWideCHAR(Parameter),
                PWideCHAR('"'+Parameter+'"'+CmdLine),
                nil,
                nil,
                true,
                Flags,
                P,
                nil,
                StartupInfo,//__in         LPSTARTUPINFO lpStartupInfo,
                ProcessInfo //__out        LPPROCESS_INFORMATION lpProcessInformation
            ) then
    RaiseLastOSError;
       Log.Log(lsMessage, 'Call to CreateProcessAsUser successful.');
     except
      on e: Exception do
      begin
        Log.Exception(E);
        LogMessage('Could not start process:'+E.Message,EVENTLOG_ERROR_TYPE);
      end;
    end;

    LogMessage('CreateProcess succeeded.');
    if P <> nil then
      DestroyEnvironmentBlock(P);
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  finally
    UserToken.Free;
  end;


end;

procedure TRunAsSysSvc3.ServiceStart(Sender: TService;
  var Started: Boolean);
begin
  Started := true;
end;

end.
