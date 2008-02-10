program Test1;

{$APPTYPE CONSOLE}

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
  JWSCLCom_TLB in '..\JWSCLCom_TLB.pas';


procedure JwOleRaise(const Res : HRESULT); stdcall; external '..\JWSCLCom.dll';

function JwCoConvertSid(const SidPtr : TJwSecurityId) : PCoSid;
var Data : PSID;
begin
  Data := SidPtr.CreateCopyOfSID;
  result := CoTaskMemAlloc(SECURITY_MAX_SID_SIZE);
  CopyMemory(result, Data, SECURITY_MAX_SID_SIZE);

  SidPtr.FreeSID(Data);
end;



var CoSid : IJwCoSid;
    Sid : TJwSecurityId;
    CoSidData : PCoSid;

    CoSidList : IJwCoSidList;

begin
  CoInitialize(0);



  try
    Sid := TJwSecurityId.Create('S-1-1-0');
    CoSidData := JwCoConvertSid(Sid);

    CoSid := CoJwCoSid.Create;
    JwOleRaise(CoSid.InitBySid(PCoSid(CoSidData)));
    //JwOleRaise(CoSid.InitBySid(nil));
    CoTaskMemFree(CoSidData);

   { CoSidList := CoJwCoSidList.Create;
    CoSidList.Init;
    CoSidList.Add(CoSid);}


    CoSid._Release;

  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;     
end.
