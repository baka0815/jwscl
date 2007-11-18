{@abstract(This unit provides conversion functions from windows api constants to delphi enumeration types and vice versa.)
@author(Christian Wimmer)
@created(03/23/2007)
@lastmod(11/18/2007)

Project JEDI Windows Security Code Library (JWSCL)

The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy of the
License at http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
ANY KIND, either express or implied. See the License for the specific language governing rights
and limitations under the License.

The Original Code is JwsclEnumerations.pas.

The Initial Developer of the Original Code is Christian Wimmer.
Portions created by Christian Wimmer are Copyright (C) Christian Wimmer. All rights reserved.


Description:
This unit provides conversion functions from windows api constants to delphi enumeration types and vice versa.


}
{$IFNDEF SL_OMIT_SECTIONS}
unit JwsclEnumerations;
{$INCLUDE Compilers.inc}
// Last modified: $Date: 2007-09-10 10:00:00 +0100 $
//do not move header comment from above unit declaration!

interface

uses
  SysUtils,
  jwaWindows,
  jwaVista,
  JwsclTypes,
  JwsclConstants
  ;
{$ENDIF SL_OMIT_SECTIONS}
{$IFNDEF SL_IMPLEMENTATION_SECTION}

type
  {@Name provides class methods to convert windows api constants
   to delphi enumeration types and vice versa.
   There is no need to create an instance of it.}
  TJwEnumMap = class
  public
    class function ConvertInheritFlags(
      const FlagSet: TJwInheritFlagSet): Cardinal; overload; virtual;
    class function ConvertInheritFlags(
      const FlagBits: Cardinal): TJwInheritFlagSet; overload; virtual;

    
    class function ConvertSecurityInformation(
      const FlagSet: TJwSecurityInformationFlagSet): Cardinal;
      overload; virtual;
    class function ConvertSecurityInformation(
      const FlagBits: TSecurityInformation): TJwSecurityInformationFlagSet;
      overload; virtual;

    class function ConvertSecurityControl(const ControlSet:
      TJwSecurityDescriptorControlSet): jwaWindows.TSecurityDescriptorControl;
      overload; virtual;
    class function ConvertSecurityControl(const Control:
      jwaWindows.TSecurityDescriptorControl): TJwSecurityDescriptorControlSet;
      overload; virtual;

    class function ConvertFlags(FlagSet: TJwSecurityDialogFlags): Cardinal;
      overload; virtual;
    class function ConvertFlags(Flags: Cardinal): TJwSecurityDialogFlags;
      overload; virtual;

    {@Name converts a set of ACE flags to a bit combined Cardinal value.
     @param(AceFlags receives the set of flags to be converted. It can be emtpy [].
            See @link(TJwAceFlags) for more information.)
     @return(The return value contains the set as a value.)
    }
    class function ConvertAceFlags(const AceFlags: TJwAceFlags): Cardinal; overload; virtual;

    {@Name converts a cardianl value to set of ACE flags.
     @param(AceFlags receives the value to be converted to a set of flags.
            Unknown bits are ignored in the result. )
     @return(The return value contains the set of ace flags. See @link(TJwAceFlags) for more information.)
    }
    class function ConvertAceFlags(
      const AceFlags: Cardinal): TJwAceFlags; overload; virtual;

    class function ConvertToCredentialFlag(
      const CredFlags: Cardinal): TJwCredentialFlagSet; overload; virtual;
    class function ConvertToCredentialFlag(
      const CredFlags: TJwCredentialFlagSet): Cardinal; overload; virtual;

     class function ConvertProtectFlags(const Flags : DWORD)
      : TJwCryptProtectFlagSet; overload;
    class function ConvertProtectFlags(const Flags : TJwCryptProtectFlagSet)
      : DWORD; overload;


    class function ConvertProtectPromptFlags(const Flags : DWORD)
      : TJwCryptProtectOnPromptFlagSet; overload;
    class function ConvertProtectPromptFlags(const Flags : TJwCryptProtectOnPromptFlagSet)
      : DWORD; overload;

    class function ConvertProtectMemoryFlags(const Flags : DWORD)
      : TJwProtectMemoryFlagSet; overload;
    class function ConvertProtectMemoryFlags(const Flags : TJwProtectMemoryFlagSet)
      : DWORD; overload;


    class function ConvertAttributes(
      const Attributes: Cardinal): TJwSidAttributeSet; overload;
    class function ConvertAttributes(
      const Attributes: TJwSidAttributeSet): Cardinal; overload;

    class function ConvertKeylessHashAlgorithm(
      const Alg: TJwKeylessHashAlgorithm): DWORD; overload;
    class function ConvertKeylessHashAlgorithm(
      const Alg: DWORD): TJwKeylessHashAlgorithm; overload;

    class function ConvertCSPType(
      const CSPType: TJwCSPType): DWORD; overload;
    class function ConvertCSPType(
      const CSPType: DWORD): TJwCSPType; overload;

    class function ConvertCSPCreationFlags(
      const FlagSet: TJwCSPCreationFlagSet): Cardinal; overload;
    class function ConvertCSPCreationFlags(
      const FlagBits: Cardinal): TJwCSPCreationFlagSet; overload;
  end;


{$ENDIF SL_IMPLEMENTATION_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}
implementation

{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_INTERFACE_SECTION}

{The following declarations are private.
If you decide to extend or change the delphi enumeration type
you must make sure that the map from enum typename to constant is correct.

I use comma in front of the enumerations because pasdoc can recognize
comments behind of declaration
}

const InheritFlagsValues : array[TJwInheritFlag] of Cardinal = (
        SEF_DACL_AUTO_INHERIT //ifDaclAutoInherit
        ,SEF_SACL_AUTO_INHERIT //ifSaclAutoInherit
        ,SEF_DEFAULT_DESCRIPTOR_FOR_OBJECT //ifDefaultDescriptor
        ,SEF_AVOID_PRIVILEGE_CHECK //ifAvoidPrivilegeCheck
        ,SEF_AVOID_OWNER_CHECK //ifAvoidOwnerCheck
        ,SEF_DEFAULT_OWNER_FROM_PARENT //ifDefaultOwnerFromPArent
        ,SEF_DEFAULT_GROUP_FROM_PARENT //ifDefaultGroupFromParent
        ,$100//SEF_MACL_NO_WRITE_UP //ifMaclNoWriteUp
        ,$200//SEF_MACL_NO_READ_UP //ifMaclNoReadUp
        ,$400//SEF_MACL_NO_EXECUTE_UP //ifMaclNoExecuteUp
        ,$1000//SEF_AVOID_OWNER_RESTRICTION //ifAvoidOwnerRestriction
        );

      SecurityInformationValues : array[TJwSecurityInformationFlag]
        of Cardinal = (
        OWNER_SECURITY_INFORMATION//siOwnerSecurityInformation
        ,GROUP_SECURITY_INFORMATION//siGroupSecurityInformation
        ,DACL_SECURITY_INFORMATION//siDaclSecurityInformation
        ,SACL_SECURITY_INFORMATION//siSaclSecurityInformation
        ,LABEL_SECURITY_INFORMATION//siLabelSecurityInformation
        ,PROTECTED_DACL_SECURITY_INFORMATION//siProtectedDaclSecurityInformation
        ,PROTECTED_SACL_SECURITY_INFORMATION//siProtectedSaclSecurityInformation
        ,UNPROTECTED_DACL_SECURITY_INFORMATION//siUnprotectedDaclSecurityInformation
        ,UNPROTECTED_SACL_SECURITY_INFORMATION//siUnprotectedSaclSecurityInformation
        );

      SecurityDescriptorControlValues : array[TJwSecurityDescriptorControl]
        of Cardinal = (
        SE_OWNER_DEFAULTED//sdcOwnerDefaulted
        ,SE_GROUP_DEFAULTED//sdcGroupDefaulted
        ,SE_DACL_PRESENT//sdcDaclPresent
        ,SE_DACL_DEFAULTED//sdcDaclDefaulted
        ,SE_SACL_PRESENT//sdcSaclPresent
        ,SE_SACL_DEFAULTED//sdcSaclDefaulted
        ,SE_DACL_AUTO_INHERIT_REQ//sdcDaclAutoInheritReq
        ,SE_SACL_AUTO_INHERIT_REQ//sdcSaclAutoInheritReq
        ,SE_DACL_AUTO_INHERITED//sdcDaclAutoInherited
        ,SE_SACL_AUTO_INHERITED//sdcSaclAutoInherited
        ,SE_DACL_PROTECTED//sdcDaclProtected
        ,SE_SACL_PROTECTED//sdcSaclProtected
        ,SE_RM_CONTROL_VALID//sdcRmControlValid
        ,SE_SELF_RELATIVE//sdcSelfRelative
        );

      SecurityDialogFlagValues : array[TJwSecurityDialogFlag]
        of Cardinal = (
        SI_EDIT_PERMS//sdfEditDacl
        ,SI_EDIT_AUDITS//sdfEditSacl
        ,SI_EDIT_OWNER//sdfEditOwner
        ,SI_CONTAINER//sdfContainer
        ,SI_READONLY//sdfReadOnly
        ,SI_ADVANCED//sdfAdvanced
        ,SI_RESET//sdfReset
        ,SI_OWNER_READONLY//sdfOwnerReadOnly
        ,SI_EDIT_PROPERTIES//sdfEditProperties
        ,SI_OWNER_RECURSE//sdfOwnerRecurse
        ,SI_NO_ACL_PROTECT//sdfNoAclProtect
        ,SI_NO_TREE_APPLY//sdfNoTreeApply
        ,SI_SERVER_IS_DC//sdfServerIsDc
        ,SI_RESET_DACL_TREE//sdfResetDaclTree
        ,SI_RESET_SACL_TREE//sdfResetSaclTree
        ,SI_OBJECT_GUID//sdfObjectGuid
        ,SI_EDIT_EFFECTIVE//sdfEditEffective
        ,SI_RESET_DACL//sdfResetDacl
        ,SI_RESET_SACL//sdfResetSacl
        ,SI_RESET_OWNER//sdfResetOwner
        ,SI_NO_ADDITIONAL_PERMISSION//sdfNoAdditionalPermission
        ,SI_MAY_WRITE//sdfMayWrite
        ,SI_PAGE_TITLE//sdfPageTitle
      );

      AceFlagValues : Array[TJwAceFlag] of Cardinal = (
        OBJECT_INHERIT_ACE//afObjectInheritAce
        ,CONTAINER_INHERIT_ACE//afContainerInheritAce
        ,NO_PROPAGATE_INHERIT_ACE//afNoPropagateInheritAce
        ,INHERIT_ONLY_ACE//afInheritOnlyAce
        ,INHERITED_ACE//afInheritedAce
        ,VALID_INHERIT_FLAGS//afValidInheritFlags
        ,SUCCESSFUL_ACCESS_ACE_FLAG//afSuccessfulAccessAceFlag
        ,FAILED_ACCESS_ACE_FLAG//afFailedAccessAceFlag
      );

      //TJwCredentialFlag    = (
      CredentialFlagValues : Array[TJwCredentialFlag] of Cardinal = (
        CREDUI_FLAGS_ALWAYS_SHOW_UI//cfFlagsAlwaysShowUi
        ,CREDUI_FLAGS_DO_NOT_PERSIST//cfFlagsDoNotPersist
        ,CREDUI_FLAGS_EXCLUDE_CERTIFICATES//cfFlagsExcludeCertificates
        ,CREDUI_FLAGS_EXPECT_CONFIRMATION//cfFlagsExpectConfirmation
        ,CREDUI_FLAGS_GENERIC_CREDENTIALS//cfFlagsGenericCredentials
        ,CREDUI_FLAGS_INCORRECT_PASSWORD//cfFlagsIncorrectPassword
        ,CREDUI_FLAGS_PERSIST//cfFlagsPersist
        ,CREDUI_FLAGS_REQUEST_ADMINISTRATOR//cfFlagsRequestAdministrator
        ,CREDUI_FLAGS_REQUIRE_CERTIFICATE//cfFlagsRequireCertificate
        ,CREDUI_FLAGS_REQUIRE_SMARTCARD//cfFlagsRequireSmartCard
        ,CREDUI_FLAGS_SERVER_CREDENTIAL//cfFlagsServerCredential
        ,CREDUI_FLAGS_SHOW_SAVE_CHECK_BOX//cfFlagsShowSaveCheckBox
        ,CREDUI_FLAGS_USERNAME_TARGET_CREDENTIALS//cfFlagsUserNameTargetCredentials
      );

      CryptProtectOnPromptFlagValues : Array[TJwCryptProtectOnPromptFlag] of Cardinal = (
        0
        ,CRYPTPROTECT_PROMPT_ON_PROTECT //cppf_PromptOnProtect
        ,CRYPTPROTECT_PROMPT_ON_UNPROTECT //cppf_PromptOnUnprotect
      );

      ProtectMemoryFlagSetValues : Array[TJwProtectMemoryFlag] of Cardinal = (
        CRYPTPROTECTMEMORY_SAME_PROCESS //pmSameProcess
        ,CRYPTPROTECTMEMORY_CROSS_PROCESS //pmCrossProcess
        ,CRYPTPROTECTMEMORY_SAME_LOGON //pmSameLogon
      );

      CryptProtectFlag : Array[TJwCryptProtectFlag] of Cardinal = (
        CRYPTPROTECT_LOCAL_MACHINE//cfLocalMachine
        ,CRYPTPROTECT_UI_FORBIDDEN//cfUiFobidden
        //Vista only 
       { ,CRYPTPROTECT_AUDIT//cfAudit
        CRYPTPROTECT_VERIFY_PROTECTION//cfVerifyProtection }
      );

      KeylessHashAlgorithmValues: array[TJwKeylessHashAlgorithm] of Cardinal = (
        CALG_MD2
       ,CALG_MD4
       ,CALG_MD5
       ,CALG_SHA
       );

      CSPTypeValues: array[TJwCSPType] of Cardinal = (
        PROV_RSA_FULL
       ,PROV_RSA_SIG
       ,PROV_RSA_SCHANNEL
       ,PROV_DSS
       ,PROV_DSS_DH
       ,PROV_DH_SCHANNEL
       ,PROV_FORTEZZA
       ,PROV_MS_EXCHANGE
       ,PROV_SSL
       );

      CSPCreationFlagValues: array[TJwCSPCreationFlag] of Cardinal = (
        CRYPT_VERIFYCONTEXT
       ,CRYPT_NEWKEYSET
       ,CRYPT_MACHINE_KEYSET
       //, CRYPT_DELETEKEYSET
       ,CRYPT_SILENT
       );


{ TJwEnumMap }

class function TJwEnumMap.ConvertInheritFlags(
  const FlagSet: TJwInheritFlagSet): Cardinal;
var I : TJwInheritFlag;
begin
  result := 0;
  for I := Low(TJwInheritFlag) to High(TJwInheritFlag) do
  begin
    if I in FlagSet then
      result := result or InheritFlagsValues[I];
  end;
end;

class function TJwEnumMap.ConvertInheritFlags(
  const FlagBits: Cardinal): TJwInheritFlagSet;
var I : TJwInheritFlag;
begin
  result := [];
  for I := Low(TJwInheritFlag) to High(TJwInheritFlag) do
  begin
    if (FlagBits and InheritFlagsValues[I]) = InheritFlagsValues[I] then
      Include(result, I);
  end;
end;


class function TJwEnumMap.ConvertSecurityInformation(
  const FlagSet: TJwSecurityInformationFlagSet): Cardinal;
var I : TJwSecurityInformationFlag;
begin
  result := 0;
  for I := Low(TJwSecurityInformationFlag) to High(TJwSecurityInformationFlag) do
  begin
    if I in FlagSet then
      result := result or SecurityInformationValues[I];
  end;
end;

class function TJwEnumMap.ConvertSecurityInformation(
  const FlagBits: TSecurityInformation): TJwSecurityInformationFlagSet;
var I : TJwSecurityInformationFlag;
begin
  result := [];
  for I := Low(TJwSecurityInformationFlag) to High(TJwSecurityInformationFlag) do
  begin
    if (FlagBits and SecurityInformationValues[I]) = SecurityInformationValues[I] then
      Include(result, I);
  end;
end;

class function TJwEnumMap.ConvertSecurityControl(
  const ControlSet: TJwSecurityDescriptorControlSet): jwaWindows.TSecurityDescriptorControl;
var I : TJwSecurityDescriptorControl;
begin
  result := 0;
  for I := Low(TJwSecurityDescriptorControl) to High(TJwSecurityDescriptorControl) do
  begin
    if I in ControlSet then
      result := result or SecurityDescriptorControlValues[I];
  end;
end;

class function TJwEnumMap.ConvertSecurityControl(
  const Control: TSecurityDescriptorControl): TJwSecurityDescriptorControlSet;
var I : TJwSecurityDescriptorControl;
begin
  result := [];
  for I := Low(TJwSecurityDescriptorControl) to High(TJwSecurityDescriptorControl) do
  begin
    if (Control and SecurityDescriptorControlValues[I]) = SecurityDescriptorControlValues[I] then
      Include(result, I);
  end;
end;

class function TJwEnumMap.ConvertFlags(
  FlagSet: TJwSecurityDialogFlags): Cardinal;
var I : TJwSecurityDialogFlag;
begin
  result := 0;
  for I := Low(TJwSecurityDialogFlag) to High(TJwSecurityDialogFlag) do
  begin
    if I in FlagSet then
      result := result or SecurityDialogFlagValues[I];
  end;
end;

class function TJwEnumMap.ConvertFlags(
  Flags: Cardinal): TJwSecurityDialogFlags;
var I : TJwSecurityDialogFlag;
begin
  result := [];
  for I := Low(TJwSecurityDialogFlag) to High(TJwSecurityDialogFlag) do
  begin
    if (Flags and SecurityDialogFlagValues[I]) = SecurityDialogFlagValues[I] then
      Include(result, I);
  end;
end;


class function TJwEnumMap.ConvertAceFlags(
  const AceFlags: TJwAceFlags): Cardinal;
var I : TJwAceFlag;
begin
  result := 0;
  for I := Low(TJwAceFlag) to High(TJwAceFlag) do
  begin
    if I in AceFlags then
      result := result or AceFlagValues[I];
  end;
end;

class function TJwEnumMap.ConvertAceFlags(
  const AceFlags: Cardinal): TJwAceFlags;
var I : TJwAceFlag;
begin
  result := [];
  for I := Low(TJwAceFlag) to High(TJwAceFlag) do
  begin
    if (AceFlags and AceFlagValues[I]) = AceFlagValues[I] then
      Include(result, I);
  end;
end;

class function TJwEnumMap.ConvertToCredentialFlag(
  const CredFlags: Cardinal): TJwCredentialFlagSet;
var I : TJwCredentialFlag;
begin
  result := [];
  for I := Low(TJwCredentialFlag) to High(TJwCredentialFlag) do
  begin
    if (CredFlags and CredentialFlagValues[I]) = CredentialFlagValues[I] then
      Include(result, I);
  end;
end;

class function TJwEnumMap.ConvertToCredentialFlag(
  const CredFlags: TJwCredentialFlagSet): Cardinal;
var I : TJwCredentialFlag;
begin
  result := 0;
  for I := Low(TJwCredentialFlag) to High(TJwCredentialFlag) do
  begin
    if I in CredFlags then
      result := result or CredentialFlagValues[I];
  end;
end;






class function TJwEnumMap.ConvertProtectFlags(
  const Flags: DWORD): TJwCryptProtectFlagSet;
var I : TJwCryptProtectFlag;
begin
  result := [];
  for I := Low(TJwCryptProtectFlag) to High(TJwCryptProtectFlag) do
  begin
    if (Flags and CryptProtectFlag[I]) = CryptProtectFlag[I] then
      Include(result, I);
  end;
end;

class function TJwEnumMap.ConvertProtectFlags(
  const Flags: TJwCryptProtectFlagSet): DWORD;
var I : TJwCryptProtectFlag;
begin
  result := 0;
  for I := Low(TJwCryptProtectFlag) to High(TJwCryptProtectFlag) do
  begin
    if I in Flags then
      result := result or CryptProtectFlag[I];
  end;
end;

class function TJwEnumMap.ConvertProtectMemoryFlags(
  const Flags: DWORD): TJwProtectMemoryFlagSet;
var I : TJwProtectMemoryFlag;
begin
  result := [];
  for I := Low(TJwProtectMemoryFlag) to High(TJwProtectMemoryFlag) do
  begin
    if (Flags and ProtectMemoryFlagSetValues[I]) = ProtectMemoryFlagSetValues[I] then
      Include(result, I);
  end;
end;


class function TJwEnumMap.ConvertProtectMemoryFlags(
  const Flags: TJwProtectMemoryFlagSet): DWORD;
var I : TJwProtectMemoryFlag;
begin
  result := 0;
  for I := Low(TJwProtectMemoryFlag) to High(TJwProtectMemoryFlag) do
  begin
    if I in Flags then
      result := result or ProtectMemoryFlagSetValues[I];
  end;
end;

class function TJwEnumMap.ConvertProtectPromptFlags(
  const Flags: DWORD): TJwCryptProtectOnPromptFlagSet;
var I : TJwCryptProtectOnPromptFlag;
begin
  result := [];
  for I := Low(TJwCryptProtectOnPromptFlag) to High(TJwCryptProtectOnPromptFlag) do
  begin
    if (Flags and CryptProtectOnPromptFlagValues[I]) = CryptProtectOnPromptFlagValues[I] then
      Include(result, I);
  end;
end;

class function TJwEnumMap.ConvertProtectPromptFlags(
  const Flags: TJwCryptProtectOnPromptFlagSet): DWORD;
var I : TJwCryptProtectOnPromptFlag;
begin
  result := 0;
  for I := Low(TJwCryptProtectOnPromptFlag) to High(TJwCryptProtectOnPromptFlag) do
  begin
    if I in Flags then
      result := result or CryptProtectOnPromptFlagValues[I];
  end;
end;

class function TJwEnumMap.ConvertKeylessHashAlgorithm(
  const Alg: TJwKeylessHashAlgorithm): DWORD;
begin
  Result:=KeylessHashAlgorithmValues[Alg];
end;

class function TJwEnumMap.ConvertKeylessHashAlgorithm(
  const Alg: DWORD): TJwKeylessHashAlgorithm;
var i: TJwKeylessHashAlgorithm;
begin
  for i := Low(TJwKeylessHashAlgorithm) to High(TJwKeylessHashAlgorithm) do
    if KeylessHashAlgorithmValues[i] = Alg then
    begin
      Result := i;
      Break;
    end;
end;

class function TJwEnumMap.ConvertCSPType(
  const CSPType: TJwCSPType): DWORD;
begin
  Result := CSPTypeValues[CSPType];
end;

class function TJwEnumMap.ConvertCSPType(
  const CSPType: DWORD): TJwCSPType;
var i: TJwCSPType;
begin
  for i := Low(TJwCSPType) to High(TJwCSPType) do
    if CSPTypeValues[i] = CSPType then
    begin
      Result := i;
      Break;
    end;
end;

class function TJwEnumMap.ConvertCSPCreationFlags(
  const FlagSet: TJwCSPCreationFlagSet): Cardinal;
var I : TJwCSPCreationFlag;
begin
  result := 0;
  for I := Low(TJwCSPCreationFlag) to High(TJwCSPCreationFlag) do
  begin
    if I in FlagSet then
      result := result or CSPCreationFlagValues[I];
  end;
end;

class function TJwEnumMap.ConvertCSPCreationFlags(
  const FlagBits: Cardinal): TJwCSPCreationFlagSet;
var I : TJwCSPCreationFlag;
begin
  result := [];
  for I := Low(TJwCSPCreationFlag) to High(TJwCSPCreationFlag) do
  begin
    if (FlagBits and CSPCreationFlagValues[I]) = CSPCreationFlagValues[I] then
      Include(result, I);
  end;
end;

{$ENDIF SL_INTERFACE_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}



class function TJwEnumMap.ConvertAttributes(
  const Attributes: Cardinal): TJwSidAttributeSet;
begin
  Result := [];
  if Attributes and SE_GROUP_MANDATORY = SE_GROUP_MANDATORY then
    Include(Result, sidaGroupMandatory);

  if Attributes and SE_GROUP_ENABLED_BY_DEFAULT =
    SE_GROUP_ENABLED_BY_DEFAULT then
    Include(Result, sidaGroupEnabledByDefault);

  if Attributes and SE_GROUP_ENABLED = SE_GROUP_ENABLED then
    Include(Result, sidaGroupEnabled);

  if Attributes and SE_GROUP_OWNER = SE_GROUP_OWNER then
    Include(Result, sidaGroupOwner);

  if Attributes and SE_GROUP_USE_FOR_DENY_ONLY =
    SE_GROUP_USE_FOR_DENY_ONLY then
    Include(Result, sidaGroupUseForDenyOnly);

  if Attributes and SE_GROUP_LOGON_ID = SE_GROUP_LOGON_ID then
    Include(Result, sidaGroupLogonId);

  if Attributes and SE_GROUP_RESOURCE = SE_GROUP_RESOURCE then
    Include(Result, sidaGroupResource);


  if Attributes and SE_GROUP_INTEGRITY = SE_GROUP_INTEGRITY then
    Include(Result, sidaGroupIntegrity);

  if Attributes and SE_GROUP_INTEGRITY_ENABLED = SE_GROUP_INTEGRITY_ENABLED then
    Include(Result, sidaGroupIntegrityEnabled);

end;

class function TJwEnumMap.ConvertAttributes(
  const Attributes: TJwSidAttributeSet): Cardinal;
begin
  Result := 0;
  if sidaGroupMandatory in Attributes then
    Result := Result or SE_GROUP_MANDATORY;

  if sidaGroupEnabledByDefault in Attributes then
    Result := Result or SE_GROUP_ENABLED_BY_DEFAULT;

  if sidaGroupEnabled in Attributes then
    Result := Result or SE_GROUP_ENABLED;

  if sidaGroupOwner in Attributes then
    Result := Result or SE_GROUP_OWNER;

  if sidaGroupUseForDenyOnly in Attributes then
    Result := Result or SE_GROUP_USE_FOR_DENY_ONLY;

  if sidaGroupLogonId in Attributes then
    Result := Result or SE_GROUP_LOGON_ID;

  if sidaGroupResource in Attributes then
    Result := Result or SE_GROUP_RESOURCE;


  if sidaGroupIntegrity in Attributes then
    Result := Result or SE_GROUP_INTEGRITY;

  if sidaGroupIntegrityEnabled in Attributes then
    Result := Result or SE_GROUP_INTEGRITY_ENABLED;

end;

initialization
{$ENDIF SL_OMIT_SECTIONS}



{$IFNDEF SL_INITIALIZATION_SECTION}
{$ENDIF SL_INITIALIZATION_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}
end.
{$ENDIF SL_OMIT_SECTIONS}
