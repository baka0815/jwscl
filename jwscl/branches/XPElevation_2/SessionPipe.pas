unit SessionPipe;

interface
uses SysUtils, JwaWindows, ComObj, ULogging, JwsclUtils, JwsclLogging, Classes,
    JwsclTypes,
    JwsclExceptions, JwsclComUtils;

type
  PClientBuffer = ^TClientBuffer;
  TClientBuffer = record
    Signature : array[0..15] of Char;
    UserName  :  array[0..UNLEN] of WideChar;
    Domain    : array[0..MAX_DOMAIN_NAME_LEN] of WideChar;
    Password  : array[0..MAX_PASSWD_LEN] of WideChar;
    Flags     : DWORD;
  end;

const CLIENT_START = $200000;

      CLIENT_CANCELED       = CLIENT_START;
      CLIENT_USECACHECREDS  = CLIENT_START shl 1;   //to server: use cached passw  ord
      CLIENT_CACHECREDS     = CLIENT_START shl 2;      //to server: save given password to cache
      CLIENT_CLEARCACHE     = CLIENT_START shl 3;      //to server: clear user password from cache
      CLIENT_DEBUGTERMINATE = CLIENT_START shl 4;

      SERVER_START = $1;
      SERVER_TIMEOUT        = SERVER_START;         //
      SERVER_USECACHEDCREDS = SERVER_START shl 1;  //
      SERVER_CACHEAVAILABLE = SERVER_START shl 2;  //to client: Password is available through cache
      SERVER_DEBUGTERMINATE = SERVER_START shl 3;


      ERROR_CREATEPROCESSASUSER_FAILED = 1;
      ERROR_INVALID_USER = 2;
      ERROR_ABORTBYUSER = 3;
      ERROR_LOGONUSERFAILED = 4;
      ERROR_LOADUSERPROFILE = 5;


      ERROR_TIMEOUT = 6;
      ERROR_SHUTDOWN = 7;
      ERROR_WIN32 = 8;
      ERROR_ABORT = 9;
      ERROR_GENERAL_EXCEPTION = 10;

      ERROR_NO_SUCH_LOGONSESSION = 11;

      ERROR_TOO_MANY_LOGON_ATTEMPTS = 12;
      ERROR_HASH_MISMATCH = 13;



type
  PServerBuffer = ^TServerBuffer;
  TServerBuffer = record
    Version : DWORD;
    Size : DWORD;

    Signature   : array[0..15] of Char;
    Application,
    Commandline : array[0..MAX_PATH] of WideChar;
    UserName    : array[0..UNLEN] of WideChar;
    Domain      : array[0..MAX_DOMAIN_NAME_LEN] of WideChar;
    ParentWindow : HWND;
    MaxLogonAttempts,
    TimeOut   : DWORD;
    UserRegKey : HKEY;
    ControlFlags,
    Flags     : DWORD;

    UserProfileImageType : array[0..31] of WideChar;
    UserProfileImageSize  : DWORD;
    UserProfileImageStart : DWORD;
  end;

  TSessionInfo = record
    Application,
    Commandline,
    UserName,
    Domain,
    Password  : WideString;
    ParentWindow : HWND;
    ControlFlags,
    Flags  : DWORD;
    UserRegKey : HKEY;
    MaxLogonAttempts,
    TimeOut : DWORD;
    UserProfileImage : TMemoryStream;
    UserProfileImageType : WideString;
  end;

  ETimeOutException = class(Exception);
  EShutdownException = class(Exception);

  TOnServiceProcessRequest = procedure (WaitForMessage: Boolean) of object;

  TSessionPipe = class(TObject)
  protected
    fPipe : HANDLE;
    fTimeOut : DWORD;
    fEvent : HANDLE;
  protected

  public
    constructor Create();
    destructor Destroy(); override;
    procedure Connect(const PipeName : WideString); virtual;

    class function IsValidPipe(const SessionPipe : TSessionPipe) : Boolean;

    function GetOverlappedResult(const lpOverlapped : TOverlapped; const Wait : Boolean) : DWORD;

    property ServerTimeOut : DWORD read fTimeOut;
    property Handle : HANDLE read fPipe;
  end;

  TClientSessionPipe = class(TSessionPipe)
  private
    { private-Deklarationen }

  protected
    { protected-Deklarationen }
  public
    { public-Deklarationen }
    constructor Create();
    destructor Destroy(); override;

    procedure ReadServerData(out SessionInfo : TSessionInfo);
    procedure SendClientData(const SessionInfo : TSessionInfo);

    procedure ReadServerProcessResult(out Value, LastError : DWORD;
        const StopEvent: HANDLE);
  published
    { published-Deklarationen }
  end;

  TServerSessionPipe = class(TSessionPipe)
  private
    { private-Deklarationen }

  protected
    { protected-Deklarationen }
  public
    { public-Deklarationen }
    constructor Create();
    destructor Destroy(); override;

    procedure Assign(const PipeHandle : THandle;
                    TimeOut : DWORD);

    function WaitForClientToConnect(const ProcessID, TimeOut: DWORD;
      const StopEvent, ProcessHandle: HANDLE): DWORD;

    function WaitForClientAnswer(const TimeOut: DWORD;
      const StopEvent: HANDLE): DWORD;


    procedure SendServerData(const SessionInfo : TSessionInfo);
    procedure SendServerResult(const Value, LastError : DWORD);

    procedure ReadClientData(out SessionInfo : TSessionInfo; const TimeOut: DWORD; const StopEvent: HANDLE);

//    procedure SendServerProcessResult(const Value, LastError : DWORD);


  end;

//function StringCbLengthHelper(
//    {__in}const psz : STRSAFE_LPCTSTR;
//    {__in}cbMax : size_t) : Size_t;

function StringCbLengthHelperA(
    {__in}const psz : STRSAFE_LPCSTR;
    {__in}cbMax : size_t) : Size_t;

function StringCbLengthHelperW(
    {__in}const psz : STRSAFE_LPCWSTR;
    {__in}cbMax : size_t) : Size_t;

function StringCchLengthHelperA(
    {__in}const psz : STRSAFE_LPCSTR;
    {__in}cchMax : size_t) : Size_t;

function StringCchLengthHelperW(
    {__in}const psz : STRSAFE_LPCWSTR;
    {__in}cchMax : size_t) : Size_t;

//function StringCchLengthHelper(
//    {__in}const psz : STRSAFE_LPCTSTR;
//    {__in}cchMax : size_t) : Size_t;

function CheckPipe(const Value : Boolean) : Boolean;

implementation


{ TClientSessionPipe }



constructor TClientSessionPipe.Create();
begin
  inherited;
end;

destructor TClientSessionPipe.Destroy;
begin

  inherited;
end;


function CheckPipe(const Value : Boolean) : Boolean;
begin
  result := (Value )
      or (not Value and (GetLastError() = ERROR_IO_PENDING));
end;

procedure TClientSessionPipe.ReadServerData(out SessionInfo: TSessionInfo);
var ServerBuffer : PServerBuffer;
    lpNumberOfBytesRead,
    nNumberOfBytesToRead : DWORD;

    Log : IJwLogClient;
    Size : DWORD;
    P : Pointer;
   { OvLapped : TOverlapped;}
   AA : Array[0..1000] of char absolute P;
   LogServer : IJwLogServer;
begin
  if not Assigned(ULogging.LogServer) then
    LogServer := CreateLogServer(nil, LogEventTypes, nil);

  Log := uLogging.LogServer.Connect(etMethod,ClassName,
          'ReadServerData','ElevationHandler.pas','');

  //get record size        
  if not CheckPipe(ReadFile(
    fPipe,//__in         HANDLE hFile,
    @Size,//__out        LPVOID lpBuffer,
    sizeof(Size),//__in         DWORD nNumberOfBytesToRead,
    @lpNumberOfBytesRead,//__out_opt    LPDWORD lpNumberOfBytesRead,
    nil//@OvLapped//__inout_opt  LPOVERLAPPED lpOverlapped
  )) then
    LogAndRaiseLastOsError(Log,ClassName, 'ReadServerData::(Winapi)ReadFile','SessionPipe.pas');

  GetMem(ServerBuffer, Size);
  TJwAutoPointer.Wrap(ServerBuffer, Size, ptGetMem);

  {ZeroMemory(@OvLapped, sizeof(OvLapped));
  OvLapped.hEvent := TJwAutoPointer.Wrap(CreateEvent(nil, false, false, nil)).GetHandle;
  }
  if not CheckPipe(ReadFile(
    fPipe,//__in         HANDLE hFile,
    ServerBuffer,//__out        LPVOID lpBuffer,
    Size,//__in         DWORD nNumberOfBytesToRead,
    @lpNumberOfBytesRead,//__out_opt    LPDWORD lpNumberOfBytesRead,
    nil//@OvLapped//__inout_opt  LPOVERLAPPED lpOverlapped
  )) then
    LogAndRaiseLastOsError(Log,ClassName, 'ReadServerData::(Winapi)ReadFile','SessionPipe.pas');

  if (lpNumberOfBytesRead < sizeof(TServerBuffer)) or
     (ServerBuffer.Size <> Size) then
  begin
    SetLastError(ERROR_BAD_FORMAT);
    Log.Log(lsError, 'ReadFile returned invalid buffer size.');
    LogAndRaiseLastOsError(Log,ClassName, 'ReadClientDataReadServerData','SessionPipe.pas');
  end;

  if ServerBuffer.Signature <> 'server' then
  begin
    SetLastError(ERROR_INVALID_SIGNATURE);
    Log.Log(lsError, 'ReadFile returned invalid signature.');
    LogAndRaiseLastOsError(Log,ClassName, 'ReadClientDataReadServerData','SessionPipe.pas');
  end;

 
  ZeroMemory(@SessionInfo, sizeof(SessionInfo));
  SessionInfo.Application := ServerBuffer.Application;
  SessionInfo.Commandline := ServerBuffer.Commandline;

  SessionInfo.UserName  := ServerBuffer.UserName;
  SessionInfo.Domain    := ServerBuffer.Domain;

  SessionInfo.Flags     := ServerBuffer.Flags;
  SessionInfo.ControlFlags     := ServerBuffer.ControlFlags;
  SessionInfo.ParentWindow := ServerBuffer.ParentWindow;


  SessionInfo.TimeOut     := ServerBuffer.TimeOut;
  SessionInfo.UserRegKey  := ServerBuffer.UserRegKey;
  SessionInfo.MaxLogonAttempts     := ServerBuffer.MaxLogonAttempts;

  if (ServerBuffer.UserProfileImageSize > 0) then
  begin
    SessionInfo.UserProfileImageType := ServerBuffer.UserProfileImageType;

    P := ServerBuffer;

    Inc(Integer(P), ServerBuffer.UserProfileImageStart);
    SessionInfo.UserProfileImage := TMemoryStream.Create;
    //SessionInfo.UserProfileImage.SetSize(ServerBuffer.UserProfileImageSize);
    SessionInfo.UserProfileImage.Write(P^, ServerBuffer.UserProfileImageSize);
    SessionInfo.UserProfileImage.Position := 0;

    if SessionInfo.UserProfileImage.Size <> ServerBuffer.UserProfileImageSize then
      FreeAndNil(SessionInfo.UserProfileImage);


    //Assert(SessionInfo.UserProfileImage.Size = ServerBuffer.UserProfileImageSize);
  end;



  fTimeOut := ServerBuffer.TimeOut;

  ZeroMemory(@ServerBuffer, sizeof(ServerBuffer));
end;

procedure TClientSessionPipe.ReadServerProcessResult(out Value,
  LastError: DWORD; const StopEvent: HANDLE);
var 
  ClientBuffer : TClientBuffer;
  NumBytesRead : DWORD;
  Log : IJwLogClient;

  Data, P : Pointer;
  LogServer : IJwLogServer;
begin
  if not Assigned(ULogging.LogServer) then
    LogServer := CreateLogServer(nil, LogEventTypes, nil);

  Log := uLogging.LogServer.Connect(etMethod,ClassName,
          'ReadServerProcessResult','ElevationHandler.pas','');
  ZeroMemory(@ClientBuffer, sizeof(ClientBuffer));

  GetMem(Data, sizeof(Value) + sizeof(LastError));
  try
    if not CheckPipe(ReadFile(
       fPipe,//__in         HANDLE hFile,
       Pointer(Data),//__out        LPVOID lpBuffer,
       sizeof(Value) + sizeof(LastError),//__in         DWORD nNumberOfBytesToRead,
       @NumBytesRead,//__out_opt    LPDWORD lpNumberOfBytesRead,
       nil//@OvLapped//__inout_opt  LPOVERLAPPED lpOverlapped
        )) then
    begin
      LogAndRaiseLastOsError(Log,ClassName, 'ReadServerProcessResult::(Winapi)ReadFile','SessionPipe.pas');
    end;


    {if JwWaitForMultipleObjects([OvLapped.hEvent, StopEvent],false,INFINITE) =
      WAIT_OBJECT_0 + 1 then
        raise EShutdownException.Create('');

    }
    if NumBytesRead < sizeof(Value) + sizeof(LastError) then
    begin
      SetLastError(ERROR_INVALID_DATA);
      LogAndRaiseLastOsError(Log,ClassName, 'ReadServerProcessResult::(Winapi)ReadFile','SessionPipe.pas');
    end;

    CopyMemory(@Value, Data, sizeof(Value));
    P := Data;
    Inc(DWORD(P), sizeof(LastError));
    CopyMemory(@LastError, P, sizeof(LastError));

  finally
    FreeMem(Data);
  end;
end;

procedure TClientSessionPipe.SendClientData(const SessionInfo: TSessionInfo);
var 
  ClientBuffer : TClientBuffer;
  nNumberOfBytesToWritten : DWORD;
  Log : IJwLogClient;

  LogServer : IJwLogServer;
begin
  if not Assigned(ULogging.LogServer) then
    LogServer := CreateLogServer(nil, LogEventTypes, nil);

  Log := uLogging.LogServer.Connect(etMethod,ClassName,
          'SendClientData','ElevationHandler.pas','');

  ZeroMemory(@ClientBuffer, sizeof(ClientBuffer));

  ClientBuffer.Signature := 'client';
  try
    OleCheck(StringCbCopyW(ClientBuffer.UserName, sizeof(ClientBuffer.UserName),
      PWideChar(SessionInfo.UserName)));
    //lstrcpynW(@ClientBuffer.UserName, PWideChar(SessionInfo.UserName), sizeof(ClientBuffer.UserName)-1);

    OleCheck(StringCbCopyW(ClientBuffer.Domain, sizeof(ClientBuffer.Domain),
      PWideChar(SessionInfo.Domain)));
    //lstrcpynW(@ClientBuffer.Domain, PWideChar(SessionInfo.Domain), sizeof(ClientBuffer.Domain)-1);

    OleCheck(StringCbCopyW(ClientBuffer.Password, sizeof(ClientBuffer.Password),
      PWideChar(SessionInfo.Password)));
    //lstrcpynW(@ClientBuffer.Password, PWideChar(SessionInfo.Password), sizeof(ClientBuffer.Password)-1);


    ClientBuffer.Flags := SessionInfo.Flags;


    if not WriteFile(
      fPipe,//__in         HANDLE hFile,
      @ClientBuffer,//__out        LPVOID lpBuffer,
      sizeof(ClientBuffer),//__in         DWORD nNumberOfBytesToRead,
      @nNumberOfBytesToWritten,//
      nil//@OvLapped//
    ) then
    begin
      LogAndRaiseLastOsError(Log,ClassName, 'Connect::(Winapi)WriteFile','SessionPipe.pas');
    end;
  finally
    ZeroMemory(@ClientBuffer, sizeof(ClientBuffer));
  end;

end;

{ TSessionPipe }

procedure TSessionPipe.Connect(const PipeName: WideString);
var NewMode : DWORD;
    Log : IJwLogClient;

begin
  if uLogging.LogServer <> nil then
    Log := uLogging.LogServer.Connect(etMethod,ClassName,
            'Connect','ElevationHandler.pas','');

  fPipe := CreateFileW(
    PWideChar(PipeName),//__in      LPCTSTR lpFileName,
    GENERIC_READ or GENERIC_WRITE or SYNCHRONIZE,//__in      DWORD dwDesiredAccess,
    0,//__in      DWORD dwShareMode,
    nil,//__in_opt  LPSECURITY_ATTRIBUTES lpSecurityAttributes,
    OPEN_EXISTING,//__in      DWORD dwCreationDisposition,
    FILE_FLAG_OVERLAPPED,//__in      DWORD dwFlagsAndAttributes,
    0//__in_opt  HANDLE hTemplateFile
   );
  if fPipe = INVALID_HANDLE_VALUE then
  begin
    LogAndRaiseLastOsError(Log,ClassName, 'Connect::(Winapi)CreateFileW','SessionPipe.pas');
  end;


  try
    NewMode := PIPE_READMODE_MESSAGE or PIPE_WAIT;
    if not JwaWindows.SetNamedPipeHandleState(
      fPipe,//hNamedPipe: HANDLE;
      @NewMode,//lpMode: LPDWORD;
      nil,//lpMaxCollectionCount: LPDWORD;
      nil//lpCollectDataTimeout: LPDWORD
      ) then
      LogAndRaiseLastOsError(Log,ClassName, 'Connect::(Winapi)SetNamedPipeHandleState','SessionPipe.pas');
  except
    CloseHandle(fPipe);
    raise;
  end;
end;

constructor TSessionPipe.Create;
begin
  inherited;
  fPipe := INVALID_HANDLE_VALUE;
end;

destructor TSessionPipe.Destroy;
begin
  if (fPipe <> INVALID_HANDLE_VALUE) and
     (fPipe <> 0) then
    CloseHandle(fPipe);
  inherited;
end;

function TSessionPipe.GetOverlappedResult(const lpOverlapped: TOverlapped;
  const Wait: Boolean): DWORD;
begin
  if not JwaWindows.GetOverlappedResult(fPipe, lpOverlapped, result, Wait) then
    RaiseLastOSError;
end;

class function TSessionPipe.IsValidPipe(
  const SessionPipe: TSessionPipe): Boolean;
begin
  result := Assigned(SessionPipe) and
          (SessionPipe.fPipe <> INVALID_HANDLE_VALUE) and
          (SessionPipe.fPipe <> 0);
end;

{ TServerSessionPipe }

procedure TServerSessionPipe.Assign(const PipeHandle: THandle;
    TimeOut : DWORD);
begin
  fPipe := PipeHandle;
  fTimeOut := TimeOut;
end;

constructor TServerSessionPipe.Create;
begin

end;

destructor TServerSessionPipe.Destroy;
begin

  inherited;
end;

procedure TServerSessionPipe.ReadClientData(
  out SessionInfo: TSessionInfo;const TimeOut: DWORD; const StopEvent: HANDLE);
var 
  ClientBuffer : TClientBuffer;
  NumBytesRead : DWORD;
  Log : IJwLogClient;
  res : DWORD;
  OvLapped : TOverlapped;
  LogServer : IJwLogServer;
begin
  if not Assigned(ULogging.LogServer) then
    LogServer := CreateLogServer(nil, LogEventTypes, nil);

  Log := uLogging.LogServer.Connect(etMethod,ClassName,
          'ReadClientData','ElevationHandler.pas','');
  ZeroMemory(@ClientBuffer, sizeof(ClientBuffer));

  ZeroMemory(@OvLapped, sizeof(OvLapped));
  OvLapped.hEvent := TJwAutoPointer.Wrap(CreateEvent(nil, false, false, nil)).GetHandle;
  try
    if not CheckPipe(ReadFile(
       fPipe,//__in         HANDLE hFile,
       Pointer(@ClientBuffer),//__out        LPVOID lpBuffer,
       sizeof(TClientBuffer),//__in         DWORD nNumberOfBytesToRead,
       @NumBytesRead,//__out_opt    LPDWORD lpNumberOfBytesRead,
       @OvLapped//__inout_opt  LPOVERLAPPED lpOverlapped
        )) then
    begin
      LogAndRaiseLastOsError(Log,ClassName, 'ReadClientData::(Winapi)ReadFile','SessionPipe.pas');
    end;

    res := JwWaitForMultipleObjects([OvLapped.hEvent, StopEvent], false, TimeOut);
    if res = WAIT_TIMEOUT then
      raise ETimeOutException.Create('');
    
    if res = WAIT_OBJECT_0 + 1 then
      raise EShutdownException.Create('');

    if GetOverlappedResult(OvLapped, false) < sizeof(TClientBuffer) then
    begin
      SetLastError(ERROR_BAD_FORMAT);
      Log.Log(lsError, 'ReadFile returned invalid buffer size.');
      LogAndRaiseLastOsError(Log,ClassName, 'ReadClientData','SessionPipe.pas');
    end;


    if ClientBuffer.Signature <> 'client' then
    begin
      SetLastError(ERROR_INVALID_SIGNATURE);
      Log.Log(lsError, 'ReadFile returned invalid signature.');
      LogAndRaiseLastOsError(Log,ClassName, 'ReadClientDataReadServerData','SessionPipe.pas');
    end;

    if ClientBuffer.Flags and CLIENT_CANCELED <> CLIENT_CANCELED then
    begin
      SessionInfo.UserName := ClientBuffer.UserName;
      SessionInfo.Domain := ClientBuffer.Domain;
      SessionInfo.Password := ClientBuffer.Password;
    end;

    SessionInfo.Flags := ClientBuffer.Flags;
  finally
    ZeroMemory(@ClientBuffer, sizeof(ClientBuffer));
  end;
end;

procedure TServerSessionPipe.SendServerResult(const Value, LastError : DWORD);
var 
  NumBytesWritten: DWORD;
  Log : IJwLogClient;
  A : Array[0..1] of DWORD;
  LogServer : IJwLogServer;
begin
  if not Assigned(ULogging.LogServer) then
    LogServer := CreateLogServer(nil, LogEventTypes, nil);

  Log := uLogging.LogServer.Connect(etMethod,ClassName,
          'SendServerResult','ElevationHandler.pas','');

  A[0] := Value;
  A[1] := LastError;
  try
    if not WriteFile(
         fPipe,//hFile: HANDLE;
         Pointer(@A),//lpBuffer: LPCVOID;
         sizeof(A),//nNumberOfBytesToWrite: DWORD;
         @NumBytesWritten,//lpNumberOfBytesWritten: LPDWORD;
         nil//@OvLapped//lpOverlapped: LPOVERLAPPED
         ) then
    begin
      LogAndRaiseLastOsError(Log,ClassName, 'SendServerResult::(Winapi)WriteFile','SessionPipe.pas');
    end;
  finally
  end;
end;

procedure TServerSessionPipe.SendServerData(const SessionInfo: TSessionInfo);
var 
  ServerBuffer : PServerBuffer;
  Size : DWORD;
  NumBytesWritten: DWORD;
  Log : IJwLogClient;
  P : Pointer;

//    AA : Array[0..1000] of char absolute P;
  LogServer : IJwLogServer;
begin
  if not Assigned(ULogging.LogServer) then
    LogServer := CreateLogServer(nil, LogEventTypes, nil);

  Log := uLogging.LogServer.Connect(etMethod,ClassName,
          'SendServerData','ElevationHandler.pas','');

  Size := sizeof(TServerBuffer)+4;
  if Assigned(SessionInfo.UserProfileImage) then
    Inc(Size, SessionInfo.UserProfileImage.Size);

  GetMem(ServerBuffer, Size);
  TJwAutoPointer.Wrap(ServerBuffer, Size,ptGetMem);

  ZeroMemory(ServerBuffer, Size);
  try
    OleCheck(StringCbCopyA(ServerBuffer.Signature, sizeof(ServerBuffer.Signature),
        PChar('server')));

    ServerBuffer.Version := 1;
    ServerBuffer.Size := Size;

    ServerBuffer.Flags := 0;

    ServerBuffer.ControlFlags := SessionInfo.ControlFlags;
    ServerBuffer.TimeOut := SessionInfo.TimeOut;

    OleCheck(StringCbCopyW(ServerBuffer.Application, sizeof(ServerBuffer.Application),
       PWideChar(WideString(SessionInfo.Application))));

    OleCheck(StringCbCopyW(ServerBuffer.Commandline, sizeof(ServerBuffer.Commandline),
       PWideChar(WideString(SessionInfo.Commandline))));


    OleCheck(StringCbCopyW(ServerBuffer.UserName, sizeof(ServerBuffer.UserName),
       PWideChar(WideString(SessionInfo.UserName))));

    OleCheck(StringCbCopyW(ServerBuffer.Domain, sizeof(ServerBuffer.Domain),
       PWideChar(WideString(SessionInfo.Domain))));

    ServerBuffer.Flags := SessionInfo.Flags;
    ServerBuffer.MaxLogonAttempts := SessionInfo.MaxLogonAttempts;
    ServerBuffer.ParentWindow := SessionInfo.ParentWindow;
    ServerBuffer.UserRegKey  := SessionInfo.UserRegKey;

    if Assigned(SessionInfo.UserProfileImage) then
    begin
      OleCheck(StringCbCopyW(ServerBuffer.UserProfileImageType, sizeof(ServerBuffer.UserProfileImageType),
         PWideChar(WideString(SessionInfo.UserProfileImageType))));

      ServerBuffer.UserProfileImageSize  := SessionInfo.UserProfileImage.Size;
      ServerBuffer.UserProfileImageStart := sizeof(TServerBuffer)+2;

      P := ServerBuffer;
      Inc(Integer(P), ServerBuffer.UserProfileImageStart);

      //CopyMemory(P, SessionInfo.UserProfileImage.Memory,SessionInfo.UserProfileImage.Size);
      SessionInfo.UserProfileImage.Position := 0;
      SessionInfo.UserProfileImage.Read(P^, SessionInfo.UserProfileImage.Size);
    end;

    if not WriteFile(
         fPipe,//hFile: HANDLE;
         @Size,//lpBuffer: LPCVOID;
         sizeof(Size),//nNumberOfBytesToWrite: DWORD;
         @NumBytesWritten,//lpNumberOfBytesWritten: LPDWORD;
         nil//@OvLapped//lpOverlapped: LPOVERLAPPED
         ) then
    begin
      LogAndRaiseLastOsError(Log,ClassName, 'SendServerData::(Winapi)WriteFile','SessionPipe.pas');
    end;

    if not WriteFile(
         fPipe,//hFile: HANDLE;
         Pointer(ServerBuffer),//lpBuffer: LPCVOID;
         Size,//nNumberOfBytesToWrite: DWORD;
         @NumBytesWritten,//lpNumberOfBytesWritten: LPDWORD;
         nil//@OvLapped//lpOverlapped: LPOVERLAPPED
         ) then
    begin
      LogAndRaiseLastOsError(Log,ClassName, 'SendServerData::(Winapi)WriteFile','SessionPipe.pas');
    end;
  finally
    ZeroMemory(@ServerBuffer, sizeof(ServerBuffer));
  end;
end;



{procedure TServerSessionPipe.SendServerProcessResult(const Value, LastError: DWORD);
var
  ServerBuffer : TServerBuffer;
  NumBytesWritten: DWORD;
  Log : IJwLogClient;
  Data, P : Pointer;
  LogServer : IJwLogServer;
begin
  if not Assigned(ULogging.LogServer) then
    LogServer := CreateLogServer(nil, LogEventTypes, nil);

  Log := uLogging.LogServer.Connect(etMethod,ClassName,
          'SendServerProcessResult','ElevationHandler.pas','');

  GetMem(Data, sizeof(Value) + sizeof(Lasterror));
  CopyMemory(Data, @Value, sizeof(Value));
  P := Data;
  Inc(DWORD(P), sizeof(Value));
  CopyMemory(P, @LastError, sizeof(LastError));


  //if Assigned(ServerPipe) then

  ZeroMemory(@ServerBuffer, sizeof(ServerBuffer));
  try

    if not WriteFile(
         fPipe,//hFile: HANDLE;
         Pointer(@Data),//lpBuffer: LPCVOID;
         sizeof(Value) + sizeof(Lasterror),//nNumberOfBytesToWrite: DWORD;
         @NumBytesWritten,//lpNumberOfBytesWritten: LPDWORD;
         @OvLapped//lpOverlapped: LPOVERLAPPED
         ) then
    begin
      try
        LogAndRaiseLastOsError(Log,ClassName, 'SendServerProcessResult::(Winapi)WriteFile','SessionPipe.pas');
      except
      end;
    end;
  finally
    FreeMem(Data);
  end;
end; }

function TServerSessionPipe.WaitForClientAnswer(const TimeOut: DWORD;

      const StopEvent: HANDLE): DWORD;
var NumBytesRead,
    NumBytesToBeRead,
    Timer : DWORD;
    Data : DWORD;
    TimeOutInt64 : LARGE_INTEGER;
    fTimer : THANDLE;
    Ar: Array[0..2] of THandle;
    Log : IJwLogClient;

  LogServer : IJwLogServer;
begin
  if not Assigned(ULogging.LogServer) then
    LogServer := CreateLogServer(nil, LogEventTypes, nil);

  Log := uLogging.LogServer.Connect(etMethod,ClassName,
          'WaitForClientAnswer','ElevationHandler.pas','');

  ZeroMemory(@TimeOutInt64,sizeof(TimeOutInt64));
  TimeOutInt64.HighPart := -1;
  TimeOutInt64.LowPart := high(TimeOutInt64.LowPart) - (Int64(TimeOut) * 1 * 100000)+1 ;

  fTimer := CreateWaitableTimer(nil, TRUE, PChar('WFClient_'+IntToStr(GetCurrentThreadId)));
  if fTimer = 0 then
  begin
    LogAndRaiseLastOsError(Log,ClassName, 'WaitForClientAnswer::(Winapi)CreateWaitableTimer','SessionPipe.pas');
  end;

  try
    if not SetWaitableTimer(fTimer, TimeOutInt64, 0, nil, nil, false) then
    begin
      LogAndRaiseLastOsError(Log,ClassName, 'WaitForClientAnswer::(Winapi)SetWaitableTimer','SessionPipe.pas');
    end;

    
    while (NumBytesToBeRead < sizeof(TClientBuffer)) do
    begin
      NumBytesToBeRead := 0;
      PeekNamedPipe(
        fPipe,//__in       HANDLE hNamedPipe,
        @Data,//__out_opt  LPVOID lpBuffer,
        sizeof(Data),//__in       DWORD nBufferSize,
        @NumBytesRead,//__out_opt  LPDWORD lpBytesRead,
        @NumBytesToBeRead,//__out_opt  LPDWORD lpTotalBytesAvail,
        nil//@OvLapped//__out_opt  LPDWORD lpBytesLeftThisMessage
      );

      {wait for 50msec or event
        0 : StopEvent - Server shuts down
        1 : connection timeout occured
      }
      result := JwWaitForMultipleObjects([StopEvent, fTimer], false, 50);
      if result = WAIT_OBJECT_0+1 then
      begin
        Log.Log(lsWarning,'Server timeout limit reached. Aborting elevation...');
        raise ETimeOutException.Create('');
      end;
      if result = WAIT_OBJECT_0 then
      begin
        Log.Log(lsWarning,'Server shutdown introduced...');
        raise EShutdownException.Create('');
      end;

    end;
  finally
    CloseHandle(fTimer);
  end;
end;


{returns
0 - Server shuts down
1 - client connects to pipe
}
function TServerSessionPipe.WaitForClientToConnect(const ProcessID,
  TimeOut: DWORD; const StopEvent, ProcessHandle: HANDLE): DWORD;
var NumBytesRead,
    NumBytesToBeRead,

    WaitResult,
    Data : DWORD;
    TimeOutInt64 : LARGE_INTEGER;
    fTimer : THANDLE;
    Log : IJwLogClient;

    OvLapped : TOverlapped;
    Msg : TMsg;

  LogServer : IJwLogServer;
begin
  if not Assigned(ULogging.LogServer) then
    LogServer := CreateLogServer(nil, LogEventTypes, nil);

  Log := uLogging.LogServer.Connect(etMethod,ClassName,
          'WaitForClientToConnect','ElevationHandler.pas','');

  ZeroMemory(@OvLapped, sizeof(OvLapped));
//error
   OvLapped.hEvent := TJwAutoPointer.Wrap(CreateEvent(nil, false, false, nil)).GetHandle;

    if not ConnectNamedPipe(fPipe, @OvLapped) then
      if (GetLastError() <> ERROR_IO_PENDING) and
         (GetLastError() <> ERROR_PIPE_CONNECTED) then
        LogAndRaiseLastOsError(Log, ClassName, 'WaitForClientToConnect','ElevationHandler.pas');

    repeat
      if WaitResult = WAIT_OBJECT_0 + 2 then
        PeekMessage(Msg, 0, 0, 0, PM_NOREMOVE);
      result := JwWaitForMultipleObjects([StopEvent,OvLapped.hEvent, ProcessHandle], false, TimeOut);

      if result = WAIT_FAILED then
        LogAndRaiseLastOsError(Log, ClassName, 'WaitForClientToConnect','ElevationHandler.pas');
      if result = WAIT_TIMEOUT then
        break;
    until result <> WAIT_OBJECT_0+3;

end;



function StringCbLengthHelperA(
    {__in}const psz : STRSAFE_LPCSTR;
    {__in}cbMax : size_t) : Size_t;
begin
  OleCheck(StringCbLengthA(psz, cbMax, @result));
end;

function StringCbLengthHelperW(
    {__in}const psz : STRSAFE_LPCWSTR;
    {__in}cbMax : size_t) : Size_t;
begin
  OleCheck(StringCbLengthW(psz, cbMax, @result));
end;

function StringCchLengthHelperA(
    {__in}const psz : STRSAFE_LPCSTR;
    {__in}cchMax : size_t) : Size_t;
begin
  OleCheck(StringCchLengthA(psz, cchMax, @result));
end;

function StringCchLengthHelperW(
    {__in}const psz : STRSAFE_LPCWSTR;
    {__in}cchMax : size_t) : Size_t;
begin
  OleCheck(StringCchLengthW(psz, cchMax, @result));
end;


end.
