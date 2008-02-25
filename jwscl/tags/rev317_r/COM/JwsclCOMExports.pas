unit JwsclCOMExports;

interface
uses
  ComObj,
  ActiveX,
  Sysutils,
  Classes,
  Dialogs,
  JwsclSid,
  JwaWindows,
  JWSCLCoException,
  JwsclExceptions,
  JWSCLCom_TLB;

procedure JwOleRaise(const Res : HRESULT); stdcall;
function JwHasException(const Res : HRESULT) : BOOL; stdcall;

implementation


function JwHasException(const Res : HRESULT) : BOOL; stdcall;
begin
  result := Res = E_EXCEPTION;
end;

procedure JwOleRaise(const Res : HRESULT);
var Err : IErrorInfo;
    Desc,
    Position : WideString;
    Exc : Exception;
    JExc : EJwsclSecurityException;
    List : TStringList;

begin
  if Succeeded(res) then
    exit;
    
  if Res = E_EXCEPTION then
  begin
    OleCheck(GetErrorInfo(0,Err));

    OleCheck(Err.GetDescription(Desc));
    List := TStringList.Create;
    List.CommaText := Desc;



    Exc := JwCreateException(List.Values[SJWEXCEPTIONNAME]).Create('');
    Exc.Message := List.Values[SJWMESSAGE];

    if Exc is EJwsclSecurityException then
    begin
      JExc := Exc as EJwsclSecurityException;

      JExc.SourceProc := List.Values[SJWMETHODNAME];
      JExc.SourceClass := List.Values[SJWCLASSNAME];
      JExc.SourceFile := List.Values[SJWSOURCEFILE];
      JExc.SourceLine := StrToIntDef(List.Values[SJWSOURCELINE],0);
      JExc.LastError := StrToIntDef(List.Values[SJWGETLASTERROR],0);
      JExc.WinCallName := List.Values[SJWWINCALLNAME];

      Position := Position + 'JWSCL:'+List.Values[SJWCLASSNAME]+'::'+List.Values[SJWMETHODNAME]+'('+
        List.Values[SJWSOURCEFILE]+':'+List.Values[SJWSOURCELINE]+')'
    end;

    try
      OleCheck(Err.GetSource(Position));
      Exc.Message := Exc.Message + #13#10+Position;
    except
      Exc.Message := Exc.Message + #13#10+'(No COM Class information provided)';
    end;


    List.Free;
    raise Exc;

  end
  else
    OleError(Res);
end;

end.
