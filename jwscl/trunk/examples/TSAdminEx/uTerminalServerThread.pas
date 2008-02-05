unit uTerminalServerThread;

interface

uses
  Classes, Messages, SysUtils,
  VirtualTrees, //uTerminalServerThreadMsg,
  JwaWindows, JwsclTerminalServer;

{$IFDEF MSWINDOWS}
type
  TThreadNameInfo = record
    FType: LongWord;     // must be 0x1000
    FName: PChar;        // pointer to name (in user address space)
    FThreadID: LongWord; // thread ID (-1 indicates caller thread)
    FFlags: LongWord;    // reserved for future use, must be zero
  end;
{$ENDIF}

const
  TM_THREAD_RUNNING = WM_USER + 1;
  TM_ENUM_SESSIONS = WM_USER + 2;
  TM_ENUM_PROCESSES = WM_USER + 3;
  TM_ENUM_SESSIONS_SUCCESS = WM_USER + 4;
  TM_ENUM_PROCESSES_SUCCESS = WM_USER + 5;
  TM_ENUM_SESSIONS_FAIL = WM_USER + 6;
  TM_ENUM_PROCESSES_FAIL = WM_USER + 7;
  TM_THREAD_STOP = WM_USER + 255;
    
type
  PTerminalServerThread = ^TTerminalServerThread;
  TTerminalServerThread = class(TJwThread)
  private
    { Private declarations }
  protected
    FCriticalSection: RTL_CRITICAL_SECTION;
    FNode: PVirtualNode;
    FTerminalServer: TJwTerminalServer;
    FProcessListCopy: TJwWTSProcessList;
    FSessionListCopy: TJwWTSSessionList;
    procedure EnumSessions;
    procedure EnumProcesses;
    procedure Execute; override;
  public
    constructor Create(const Server: string; const Node: PVirtualNode;
      const cs: RTL_CRITICAL_SECTION);
    destructor Destroy; override;
    property Node: PVirtualNode read FNode write FNode;
    property ProcessList: TJwWTSProcessList read FProcessListCopy write FProcessListCopy;
    property SessionList: TJwWTSSessionList read FSessionListCopy write FSessionListCopy;
  end;

implementation

uses uMain;

{ EnumerateThread }
constructor TTerminalServerThread.Create(const Server: string;
  const Node: PVirtualNode; const cs: RTL_CRITICAL_SECTION);
begin
  inherited Create(False, Format('%s (%s)', [ClassName, Server]));

  OutputDebugString('TERMINALSERVERTHREAD CREATED');
  FreeOnTerminate := False;

  // Store CRITICAL_SECTION
  FCriticalSection := cs;
  FNode := Node;

  FTerminalServer := TJwTerminalServer.Create;
  FTerminalServer.Server := Server;
end;

procedure TTerminalServerThread.Execute;
var
  Msg: tagMsg;
begin
  // Force Message Queue Creation
  PeekMessage(Msg, 0, WM_USER, WM_USER, PM_NOREMOVE);

  // Inform the main thread that we are alive!
  SendMessage(MainForm.Handle, TM_THREAD_RUNNING, Integer(FNode), 0);

  // Run until terminated
  while not Terminated do
  begin

    OutputDebugString('Entering getmessage');

    if GetMessage(@Msg, 0, 0, 0) then
    begin
      OutputDebugString(PChar(Format('Thread Message: %d', [Msg.message])));

      case Msg.message of
        TM_ENUM_SESSIONS: EnumSessions;
        TM_ENUM_PROCESSES: EnumProcesses;
        TM_THREAD_STOP: Terminate;
        else begin
          TranslateMessage(@Msg);
          DispatchMessage(@Msg);
        end;
      end;
    end;
  end;
end;

procedure TTerminalServerThread.EnumSessions;
var
  Res: Boolean;
  LastError: DWORD;
begin

  // Create a sessionslist (we do not own the objects because we are going
  // to assign them to the list in the main thread later on...
  Res := False;

  try
    Res := FTerminalServer.EnumerateSessions;
  finally
    LastError := GetLastError;
  end;

  if Res then
  begin

    // Make a copy of the Sessionlist
    FSessionListCopy := TJwWTSSessionList.Create(True);
    FSessionListCopy.Assign(FTerminalServer.Sessions);

    // This instance no longer owns the objects
    FTerminalServer.Sessions.OwnsObjects := False;
    // Clear the sessionlist
    FTerminalServer.Sessions.Clear;

    // Inform main tread that we have enumerated
    SendMessage(MainForm.Handle, TM_ENUM_SESSIONS_SUCCESS,
      Integer(FNode), 0);
  end
  else begin
    SendMessage(MainForm.Handle, TM_ENUM_SESSIONS_FAIL, Integer(FNode), LastError);
  end;

end;

procedure TTerminalServerThread.EnumProcesses;
var
  Res: Boolean;
  LastError: DWORD;
begin

  Res := False;

  try
    Res := FTerminalServer.EnumerateProcesses;
  finally
    LastError := GetLastError;
  end;

  if not Terminated then
  begin

    if Res then
    begin

      // Make a copy of the Processlist
      FProcessListCopy := TJwWTSProcessList.Create(True);
      FProcessListCopy.Assign(FTerminalServer.Processes);

      // Set Ownsobject to false and clear
      FTerminalServer.Processes.OwnsObjects := False;
      FTerminalServer.Processes.Clear;

      // Inform main tread that we have enumerated
      SendMessage(MainForm.Handle, TM_ENUM_PROCESSES_SUCCESS,
        Integer(FNode), 0);
    end
    else begin
      SendMessage(MainForm.Handle, TM_ENUM_PROCESSES_FAIL, Integer(FNode), LastError);
    end;

  end;

end;

destructor TTerminalServerThread.Destroy;
var
  i: Integer;
begin

  FreeAndNil(FProcessListCopy);
  FreeAndNil(FSessionListCopy);
  FreeAndNil(FTerminalServer);

  inherited Destroy;
end;

end.
