library JWSCLCom;

uses
  ComServ,
  JWSCLCom_TLB in 'JWSCLCom_TLB.pas',
  JwsclCoSid in 'JwsclCoSid.pas' {JwCoSid: CoClass},
  JwsclCOMExports in 'JwsclCOMExports.pas';

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer,
  JwOleRaise,
  JwHasException
  ;



{$R *.TLB}

{$R *.RES}

begin
end.
