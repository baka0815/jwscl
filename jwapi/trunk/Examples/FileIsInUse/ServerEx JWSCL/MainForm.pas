unit MainForm;

interface

{Define this switch to use the definition of the IFileIsInUse interface from
 the JEDI API units.
 Undefine it, to use it from the file here.
}
{$DEFINE JWA_BUILTIN_IFILEISINUSE}

uses
  ActiveX, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComObj, StdCtrls, ExtCtrls, Registry,

  JwaWindows, //just make sure JwaWindows or JwaActiveX is following ActiveX
  JwsclComSecurity,
  JwsclAcl,
  JwsclDescriptor,
  JwsclToken,
  JwsclTypes,
  JwsclConstants,
  JwsclExceptions,
  JwsclVersion,
  JwsclSecureObjects,
  JwsclKnownSid,
  JwsclMapping,
  JwsclSecurityDialogs,
  JwsclStrings, ComCtrls;

//You can use 3 ways of setting process COM Security; see TFormMain.InitSecurity
{$DEFINE SECURITY_APPID} //Use the security settings in Software\Classes\AppID\{APP_ID}
{.$DEFINE SECURITY_SD} //Use a security descriptor created at startup of process
{.$DEFINE SECURITY_IACCESSCONTROL} //Use callback interface each time DCOM is used


const
  APP_ID : TGUID = '{62F9FFB4-D7C5-451D-B284-9B8FFF1BD003}';


type
  //If there is a problem with IDropTarget, then you have to use the newest release
  //or trunk (developer) version of Jwa where IDropTarget is defined now.
  TFormMain = class(TForm, IDropTarget, IFileIsInUse, IAccessControl)
    btnOpen: TButton;
    btnClose: TButton;
    rg1: TRadioGroup;
    rbHigh: TRadioButton;
    Label1: TLabel;
    rbLow: TRadioButton;
    OpenDialog1: TOpenDialog;
    edtFileName: TEdit;
    rbMedium: TRadioButton;
    mmoLog: TMemo;
    btnClear: TButton;
    StaticText1: TStaticText;
    StatusBar1: TStatusBar;
    btnRegister: TButton;
    btnRegister1: TButton;
    btnRegisterRegSecurity: TButton;
    btnUnRegisterRegSecurity: TButton;
    Label2: TLabel;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnRegister1Click(Sender: TObject);
    procedure btnRegisterClick(Sender: TObject);
    procedure btnRegisterRegSecurityClick(Sender: TObject);
    procedure btnUnRegisterRegSecurityClick(Sender: TObject);
    procedure Label2Click(Sender: TObject);
  private
    { Private-Deklarationen }
    fFile : TFileStream;  //our file locking class
    FRefCount : Integer; //IUnknown reference count
    fDropHelper : IDropTargetHelper; //A helper that implements details for drag and drop
    ROTCookie : Integer; //A handle to the running object table
    fAccess : TJwServerAccessControl; //A class that handles

    procedure OnSetSecurity(Sender: TJwSecurityDescriptorDialog;
        SecurityType: TJwSecurityInformationFlagSet;
        SecurityDialogFlags: TJwSecurityDialogFlags;
        SecurityResetTypes: TJwSecurityResetTypes;
        Settings: TJwSecurityDescriptorControlSet;
        NewSecurityDescriptor, MergedSecurityDescriptor
        : TJwSecurityDescriptor;
        var bSuccess: boolean);
  public
    { Interface-Deklarationen }

    function GetAppName(out ppszName: LPWSTR) : HRESULT; stdcall;
    function GetUsage(out pfut : FILE_USAGE_TYPE) : HRESULT; stdcall;
    function GetCapabilities(out pdwCapFlags : DWORD) : HRESULT; stdcall;
    function GetSwitchToHWND(out phwnd : HWND) : HRESULT; stdcall;
    function CloseFile() : HRESULT; stdcall;

    function DragEnter(const dataObj: IDataObject; grfKeyState: DWORD;
      pt: TPoint; var dwEffect: DWORD): HResult; stdcall;

    function DragOver(grfKeyState: DWORD; pt: TPoint;
      var dwEffect: DWORD): HResult; reintroduce; stdcall;
    function DragLeave: HResult; stdcall;
    function Drop(const dataObj: IDataObject; grfKeyState: DWORD; pt: TPoint;
      var dwEffect: DWORD): HResult; stdcall;

    function QueryInterface(const IID: TGUID; out Obj): HResult; override; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

    function GrantAccessRights(pAccessList: PACTRL_ACCESSW): HRESULT; stdcall;
    function SetAccessRights(pAccessList: PACTRL_ACCESSW): HRESULT; stdcall;
    function SetOwner(pOwner: PTRUSTEEW; pGroup: PTRUSTEEW): HRESULT; stdcall;
    function RevokeAccessRights(lpProperty: LPWSTR; cTrustees: ULONG; prgTrustees: PTRUSTEEW): HRESULT; stdcall;
    function GetAllAccessRights(lpProperty: LPWSTR; var ppAccessList: PACTRL_ACCESSW_ALLOCATE_ALL_NODES; var ppOwner, ppGroup: PTRUSTEEW): HRESULT; stdcall;
    function IsAccessAllowed(pTrustee: PTRUSTEEW; lpProperty: LPWSTR; AccessRights: ACCESS_RIGHTS; var pfAccessAllowed: BOOL): HRESULT; stdcall;
  public
    procedure InitSecurity;
    procedure RegisterObjectInROT(const FileName : String);
    procedure OpenFile(const FileName : String);
    procedure CloseTheFile;

    procedure UpdateStatus;

    procedure RegisterAppID;
    procedure UnRegisterAppID;
  end;

var
  FormMain: TFormMain;

const
  PARAM_UNREGISTER = '/unregister';
  PARAM_REGISTER = '/register';

  ClassesAppId = 'Software\Classes\AppID\';

implementation

{$R *.dfm}


{ TForm3 }


procedure TFormMain.btnCloseClick(Sender: TObject);
begin
  CloseFile;
end;

procedure TFormMain.btnOpenClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    OpenFile(OpenDialog1.FileName);
  end;
end;

procedure TFormMain.btnClearClick(Sender: TObject);
begin
  mmoLog.Clear;
end;

procedure TFormMain.btnRegisterClick(Sender: TObject);
begin
  RegisterAppID;
  Sleep(500); //Looks like as if the reg must be flushed back first, otherwise we get old values
  UpdateStatus;
end;

procedure TFormMain.OnSetSecurity(Sender: TJwSecurityDescriptorDialog;
  SecurityType: TJwSecurityInformationFlagSet;
  SecurityDialogFlags: TJwSecurityDialogFlags;
  SecurityResetTypes: TJwSecurityResetTypes;
  Settings: TJwSecurityDescriptorControlSet; NewSecurityDescriptor,
  MergedSecurityDescriptor: TJwSecurityDescriptor; var bSuccess: boolean);
var i : Integer;
begin
  //
  bSuccess := true;

  if Assigned(NewSecurityDescriptor) and Assigned(NewSecurityDescriptor.DACL) then
  begin
    i := MergedSecurityDescriptor.DACL.FindSID(JwWorldSID);
    if i >= 0 then
    begin
      case MessageDlg('Do you really want to open the process COM security to the world? I could change it at least to authenticated users?', mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
        mrYes:
          begin
            MergedSecurityDescriptor.DACL[i].SID.Free;
            MergedSecurityDescriptor.DACL[i].SID := JwAuthenticatedUserSID;
          end;
      end;

    end;
    for i := 0 to NewSecurityDescriptor.DACL.Count-1 do
    begin
      if NewSecurityDescriptor.DACL[i].AccessMask <> COM_RIGHTS_EXECUTE then
        bSuccess := false;
    end;

    if not bSuccess then
      case MessageDlg('One or more Access Rights are different from COM_RIGHTS_EXECUTE. COM will fail if it finds another access right for the process. Continue?', mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
        IDYES : bSuccess := true;
      end;
  end;
end;

procedure TFormMain.btnRegisterRegSecurityClick(Sender: TObject);
var
  R : TJwComRegistrySecurity;
  Dlg : TJwSecurityDescriptorDialog;
  SD : TJwSecurityDescriptor;
  Key : TRegistry;
begin
  Key := TRegistry.Create(KEY_ALL_ACCESS);
  Key.RootKey := HKEY_LOCAL_MACHINE;
  try
    if Key.KeyExists(ClassesAppId+GUIDToString(APP_ID)) and
       not Key.OpenKey(ClassesAppId+GUIDToString(APP_ID), false) then
      case MessageDlg('Could not open App key in registry for write access. Do you want to restart with administrative rights?', mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
        mrYes:
          begin
            if ShellExecute(Handle, 'runas', PChar(ParamStr(0)), '', '', SW_SHOWNORMAL) <= 32 then
              MessageDlg('Could not elevate.', mtError, [mbOK], 0)
            else
              Application.Terminate;
            exit;
          end;
        mrCancel : exit;
      end;
  finally
    Key.Free;
  end;

  try
    R := TJwComRegistrySecurity.Create(APP_ID, false, rhLocal, ptAuto);
    try
      Dlg := TJwSecurityDescriptorDialog.Create(Handle);
      try
        Dlg.PageTitle := GUIDToString(APP_ID);
        Dlg.ObjectName := Caption;
        Dlg.Flags := [sdfAdvanced,sdfEditDacl, sdfEditOwner];
        Dlg.Mapping := TJwSecurityCOMMapping;
        Dlg.OnSetSecurity := OnSetSecurity;
        try
          Dlg.SecurityDescriptor := R.AccessPermission;
          //R.LaunchPermission -- ignored here
        except
          on E : EJwsclRegistryException do
          begin
            SD := TJwSecurityDescriptor.Create(JwTightCOMSecuritySettings.SDDL);
            try
              Dlg.SecurityDescriptor := SD;
            finally
              SD.Free;
            end;
          end;
        end;

        if Dlg.ShowModal then
        begin
          //ShowMessage(Dlg.SecurityDescriptor.GetTextMap(TJwSecurityCOMMapping));
          R.AccessPermission := Dlg.SecurityDescriptor;
          R.LaunchPermission := Dlg.SecurityDescriptor;
        end;
      finally
        Dlg.Free;
      end;

    finally
      R.Free;
    end;
  except
    on E : EJwsclInvalidRegistryPath do
      MessageDlg('App is not registered. Please register first.', mtError, [mbOK], 0);

  end;
end;

procedure TFormMain.btnUnRegisterRegSecurityClick(Sender: TObject);
var
  R : TJwComRegistrySecurity;
  Dlg : TJwSecurityDescriptorDialog;
  SD : TJwSecurityDescriptor;
  Key : TRegistry;
begin
  Key := TRegistry.Create(KEY_ALL_ACCESS);
  Key.RootKey := HKEY_LOCAL_MACHINE;
  try
    if Key.KeyExists(ClassesAppId+GUIDToString(APP_ID)) and
       not Key.OpenKey(ClassesAppId+GUIDToString(APP_ID), false) then
      case MessageDlg('Could not open App key in registry for write access. Do you want to restart with administrative rights?', mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
        mrYes:
          begin
            if ShellExecute(Handle, 'runas', PChar(ParamStr(0)), '', '', SW_SHOWNORMAL) <= 32 then
              MessageDlg('Could not elevate.', mtError, [mbOK], 0)
            else
              Application.Terminate;
            exit;
          end;
        mrCancel : exit;
      end;
    if not Key.DeleteValue('AccessPermission') or not
          Key.DeleteValue('LaunchPermission') then
    begin
      MessageDlg(Format('Could not remove permission from registry.'+#13+#10+'%s',[SysErrorMessage(GetLastError)]), mtError, [mbOK], 0);
    end;
  finally
    Key.Free;
  end;

end;




procedure TFormMain.btnRegister1Click(Sender: TObject);
begin
  UnRegisterAppID;
  Sleep(500); //Looks like as if the reg must be flushed back first, otherwise we get old values
  UpdateStatus;
end;

procedure TFormMain.CloseTheFile;
var
  ROT : ActiveX.IRunningObjectTable;
begin
  FreeAndNil(fFile);
  edtFileName.Clear;

  GetRunningObjectTable(0, ROT);
  if Assigned(ROT) and (ROTCookie <> 0) then
  begin
    ROT.Revoke(ROTCookie);
    ROTCookie := 0;
  end;
end;

function TFormMain.CloseFile: HRESULT;
begin
  CloseTheFile;
  result := S_OK;
end;


procedure TFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CloseTheFile;
end;

procedure TFormMain.InitSecurity;
var SD : TJwSecurityDescriptor;
begin
  {We only can change the security wide security settings for COM here
   because our COM object added to the ROT is not really an object known to COM.
   To secure a COM object the class must be registered in registry (with its
   security settings) but we just provide a pointer to our object.
   As soon as a client calls ROT.GetObject COM tries to bind our object and
   retrieves a pointer in memory relative to the client's memory (marshalled).
   This call into our process is secured, but not the object itself.
   (If you find another solution, mail to mail(@t)delphi-jedi(d0t)net)
  }

{$IFDEF SECURITY_APPID}
// Provides a security descriptor in the registry LOCAL_MACHINE\Software\Classes\AppID
// otherwise default from COM
  TJwComProcessSecurity.Initialize(APP_ID, []);
{$ENDIF SECURITY_APPID}

{$IFDEF SECURITY_SD}
// ....OR USE....
  SD := TJwSecurityDescriptor.Create(JwTightCOMSecuritySettings.SDDL);
  SD.DACL.Add(TJwDiscretionaryAccessControlEntryAllow.Create(nil, [], COM_RIGHTS_EXECUTE, JwLocalSystemSID));
  SD.DACL.Add(TJwDiscretionaryAccessControlEntryAllow.Create(nil, [], COM_RIGHTS_EXECUTE, JwAuthenticatedUserSID));
  SD.DACL.Add(TJwDiscretionaryAccessControlEntryAllow.Create(nil, [], COM_RIGHTS_EXECUTE, JwSecurityProcessUserSID));

// Provides a static security setting for the COM process
  TJwComProcessSecurity.Initialize(SD, calConnect, cilIdentify, []);
{$ENDIF SECURITY_SD}

{$IFDEF SECURITY_IACCESSCONTROL}
// ....OR USE....
// Provides initialization using dynamic IAccessControl implementation
  TJwComProcessSecurity.Initialize(Self, calConnect, cilIdentify, []);

// All implementations of IAccessControl here are send to fAccess
  fAccess := TJwServerAccessControl.Create;
  fAccess.SecurityDescriptor.DACL.Add(TJwDiscretionaryAccessControlEntryAllow.Create(nil, [], COM_RIGHTS_EXECUTE, JwLocalSystemSID));
  fAccess.SecurityDescriptor.DACL.Add(TJwDiscretionaryAccessControlEntryAllow.Create(nil, [], COM_RIGHTS_EXECUTE, JwAuthenticatedUserSID));
  fAccess.SecurityDescriptor.DACL.Add(TJwDiscretionaryAccessControlEntryAllow.Create(nil, [], COM_RIGHTS_EXECUTE, JwSecurityProcessUserSID));
{$ENDIF SECURITY_IACCESSCONTROL}
end;


procedure TFormMain.FormCreate(Sender: TObject);
  procedure SetButtonsShields;
  var i : Integer;
  begin
    for i := 0 to ComponentCount-1 do
    begin
      if Components[i] is TButton then
      begin
        if (Components[i] as TButton).ElevationRequired then
          (Components[i] as TButton).ElevationRequired := not JwCheckAdministratorAccess;
      end;
    end;
  end;
var Token : TJwSecurityToken;
begin
  SetButtonsShields;

  fDropHelper := CreateComObject(CLSID_DragDropHelper) as IDropTargetHelper;

  RegisterDragDrop(Handle, Self);
  ROTCookie := 0;

  Token := TJwSecurityToken.CreateTokenEffective(TOKEN_ALL_ACCESS);
  try
    rbHigh.Checked := Token.TokenIntegrityLevelType = iltHigh;
    rbLow.Checked := Token.TokenIntegrityLevelType = iltLow;
    rbMedium.Checked := Token.TokenIntegrityLevelType = iltMedium;
  finally
    Token.Free;
  end;

  UpdateStatus;

  if ParamStr(1) = PARAM_UNREGISTER then
  begin
    UnRegisterAppID;
    Visible := false;
    Application.Terminate;
  end
  else
  if ParamStr(1) = PARAM_REGISTER then
  begin
    RegisterAppID;
    Visible := false;
    Application.Terminate;
  end;

  try
    InitSecurity;
  except
    on E : EJwsclComException do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  fAccess.Free;
end;




procedure TFormMain.OpenFile(const FileName: String);
begin
  fFile.Free;
  fFile := TFileStream.Create(FileName, fmOpenRead or fmShareExclusive);
  edtFileName.Text := FileName;
  try
    RegisterObjectInROT(FileName);
  except
    CloseTheFile;
    raise;
  end;
end;

procedure TFormMain.UpdateStatus;
begin
  if TJwComRegistrySecurity.CheckROTAnyClientPermission(APP_ID) then
  begin
    StatusBar1.Color := clGreen;
    StatusBar1.SimpleText := 'Any Client is allowed to connect to ROT';
  end
  else
  begin
    StatusBar1.Color := clRed;
    StatusBar1.SimpleText := 'Only clients of same user and integrity level will see this class in ROT. Register Class to remedy that.';
  end;
  StatusBar1.Update;
end;

procedure TFormMain.RegisterAppID;
var
  Reg : TRegistry;
begin
  if not JwCheckAdministratorAccess and TJwWindowsVersion.IsWindowsVista(true) then
  begin
    if ShellExecute(Handle, 'runas', PChar(ParamStr(0)), PChar(PARAM_REGISTER), '', SW_SHOWNORMAL) <= 32 then
      MessageDlg('Could not elevate.', mtError, [mbOK], 0);
    exit;
  end;

  Reg := TRegistry.Create(KEY_ALL_ACCESS);
  Reg.RootKey := HKEY_LOCAL_MACHINE;

  if Reg.OpenKey(ClassesAppId+GUIDToString(APP_ID), true) then
  begin
    Reg.WriteString('RunAs', 'Interactive User');
    MessageDlg('App was registered successfully.', mtInformation, [mbOK], 0);
  end
  else
     MessageDlg(Format('Could not register App.'+#13+#10+'%s',[SysErrorMessage(GetLastError)]), mtError, [mbOK], 0);

  Reg.Free;
end;


procedure TFormMain.UnRegisterAppID;
var
  Reg : TRegistry;
begin
  if not JwCheckAdministratorAccess and TJwWindowsVersion.IsWindowsVista(true) then
  begin
    if ShellExecute(Handle, 'runas', PChar(ParamStr(0)), PChar(PARAM_UNREGISTER), '', SW_SHOWNORMAL) <= 32 then
      MessageDlg('Could not elevate.', mtError, [mbOK], 0);
    exit;
  end;

  Reg := TRegistry.Create(KEY_ALL_ACCESS);
  Reg.RootKey := HKEY_LOCAL_MACHINE;

  if not Reg.DeleteKey(ClassesAppId+GUIDToString(APP_ID)) then
  begin
    MessageDlg(Format('Could not unregister App.'+#13+#10+'%s',[SysErrorMessage(GetLastError)]), mtError, [mbOK], 0);
  end
  else
    MessageDlg('App was unregistered successfully.', mtInformation, [mbOK], 0);

  Reg.Free;
end;


procedure TFormMain.RegisterObjectInROT(const FileName : String);
var
  ROT : ActiveX.IRunningObjectTable;
  FileMoniker : ActiveX.IMoniker;
  hres : HRESULT;
begin
  OleCheck(GetRunningObjectTable(0, ROT)); //get ROT table handle
  OleCheck(CreateFileMoniker(PWideChar(FileName), FileMoniker)); //create file moniker to be used

  hres := ROT.Register(ROTFLAGS_REGISTRATIONKEEPSALIVE or ROTFLAGS_ALLOWANYCLIENT, Self, FileMoniker, ROTCookie); //register our object (Self) in ROT
  if (hres = CO_E_WRONG_SERVER_IDENTITY) then //This happens if we didn't register our App in registry; omit ROTFLAGS_ALLOWANYCLIENT
  begin
    OleCheck(ROT.Register(ROTFLAGS_REGISTRATIONKEEPSALIVE, Self, FileMoniker, ROTCookie));
  end
  else
    OleCheck(hres);
end;


// **** Implementation of IFileIsInUse

function TFormMain.GetAppName(out ppszName: LPWSTR): HRESULT;
begin
  //Create COM memory to copy our name
  ppszName := LPWSTR(CoTaskMemAlloc(Length(Self.Caption) * sizeof(WCHAR)));
  result := StringCchCopy(ppszName, Length(Self.Caption) * sizeof(WCHAR), PWideChar(Self.Caption));
  if Failed(result) then
  begin
    CoTaskMemFree(ppszName);
    ppszName := nil;
  end;
end;

function TFormMain.GetCapabilities(out pdwCapFlags: DWORD): HRESULT;
begin
  pdwCapFlags := OF_CAP_CANSWITCHTO or OF_CAP_CANCLOSE;
  result := S_OK;
end;

function TFormMain.GetSwitchToHWND(out phwnd: HWND): HRESULT;
begin
  phwnd := Handle;
  result := S_OK;
end;

function TFormMain.GetUsage(out pfut: FILE_USAGE_TYPE): HRESULT;
begin
  pfut := FUT_EDITING;
  result := S_OK;
end;

// **** Implementation of IAccessControl

function Logging(const S : String) : String;
begin
  result := '['+TimeToStr(Now)+'] '+ S;
end;

function TFormMain.RevokeAccessRights(lpProperty: LPWSTR; cTrustees: ULONG;
  prgTrustees: PTRUSTEEW): HRESULT;
begin
  mmoLog.Lines.Add(Logging('RevokeAccessRights'));
  result := E_ACCESSDENIED; //don't allow external write access to security descriptor
end;

function TFormMain.SetAccessRights(pAccessList: PACTRL_ACCESSW): HRESULT;
begin
  mmoLog.Lines.Add(Logging('SetAccessRights'));
  result := E_ACCESSDENIED; //don't allow external write access to security descriptor
end;

function TFormMain.SetOwner(pOwner, pGroup: PTRUSTEEW): HRESULT;
begin
  mmoLog.Lines.Add(Logging('SetOwner'));
  result := E_ACCESSDENIED; //don't allow external write access to security descriptor
end;

function TFormMain.GetAllAccessRights(lpProperty: LPWSTR;
  var ppAccessList: PACTRL_ACCESSW_ALLOCATE_ALL_NODES; var ppOwner,
  ppGroup: PTRUSTEEW): HRESULT;
begin
  mmoLog.Lines.Add(Logging('GetAllAccessRights'));
  result := fAccess.GetAllAccessRights(lpProperty, ppAccessList, ppOwner, ppGroup);
end;

function TFormMain.GrantAccessRights(pAccessList: PACTRL_ACCESSW): HRESULT;
begin
  mmoLog.Lines.Add(Logging('GrantAccessRights'));
  result := E_ACCESSDENIED; //don't allow external write access to security descriptor
end;


function TFormMain.IsAccessAllowed(pTrustee: PTRUSTEEW; lpProperty: LPWSTR;
  AccessRights: ACCESS_RIGHTS; var pfAccessAllowed: BOOL): HRESULT;
begin
  mmoLog.Lines.Add(Logging('IsAccessAllowed'));
  result := fAccess.IsAccessAllowed(pTrustee, lpProperty, AccessRights, pfAccessAllowed);
end;



procedure TFormMain.Label2Click(Sender: TObject);
begin

end;

// *** Implementation of IDropTarget

function TFormMain.DragEnter(const dataObj: IDataObject; grfKeyState: DWORD;
  pt: TPoint; var dwEffect: DWORD): HResult;
begin
  result := fDropHelper.DragEnter(Handle, dataObj, pt, dwEffect or DROPEFFECT_COPY or DROPEFFECT_LINK or DROPEFFECT_MOVE);
end;

function TFormMain.DragLeave: HResult;
begin
  result := fDropHelper.DragLeave;
end;

function TFormMain.DragOver(grfKeyState: DWORD; pt: TPoint;
  var dwEffect: DWORD): HResult;
begin
  result := fDropHelper.DragOver(pt, dwEffect);
end;

function TFormMain.Drop(const dataObj: IDataObject; grfKeyState: DWORD;
  pt: TPoint; var dwEffect: DWORD): HResult;
var
  aFmtEtc   : JwaWindows.TFORMATETC;
  aStgMed   : JwaWindows.TSTGMEDIUM;

  szBuffer  : array[0..MAX_PATH] of Char;

begin
  fDropHelper.Drop(dataObj, pt, dwEffect);

  with aFmtEtc do
  begin
    cfFormat := CF_HDROP;
    ptd      := nil;
    dwAspect := DVASPECT_CONTENT;
    lindex   := -1;
    tymed    := TYMED_HGLOBAL;
  end;

  OleCheck(dataObj.GetData(aFmtEtc, aStgMed));
  try
    FillChar(szBuffer, SizeOf(szBuffer), #0);
    DragQueryFile(aStgMed.hGlobal, $FFFFFFFF, @szBuffer, MAX_PATH);

    DragQueryFile(aStgMed.hGlobal, 0, @szBuffer, MAX_PATH);

    OpenFile(szBuffer);
  finally
    ReleaseStgMedium(aStgMed);
  end;

  Result := S_OK;
end;



// *** Implementation of IUnknown

function TFormMain.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  result := inherited;
end;

function TFormMain._AddRef: Integer;
begin
  Result := InterlockedIncrement(FRefCount);
end;

function TFormMain._Release: Integer;
begin
  Result := InterlockedDecrement(FRefCount);
  if Result = 0 then
    Destroy;
end;




end.
