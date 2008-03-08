{@abstract(Contains well known sids)
@author(Christian Wimmer)
@created(03/23/2007)
@lastmod(09/10/2007)

Project JEDI Windows Security Code Library (JWSCL)

The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy of the
License at http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
ANY KIND, either express or implied. See the License for the specific language governing rights
and limitations under the License.

Alternatively, the contents of this file may be used under the terms of the  
GNU Lesser General Public License (the  "LGPL License"), in which case the   
provisions of the LGPL License are applicable instead of those above.        
If you wish to allow use of your version of this file only under the terms   
of the LGPL License and not to allow others to use your version of this file 
under the MPL, indicate your decision by deleting  the provisions above and  
replace  them with the notice and other provisions required by the LGPL      
License.  If you do not delete the provisions above, a recipient may use     
your version of this file under either the MPL or the LGPL License.          
                                                                             
For more information about the LGPL: http://www.gnu.org/copyleft/lesser.html 

The Original Code is JwsclKnownSid.pas.

The Initial Developer of the Original Code is Christian Wimmer.
Portions created by Christian Wimmer are Copyright (C) Christian Wimmer. All rights reserved.

Description:

}
{$IFNDEF SL_OMIT_SECTIONS}
unit JwsclKnownSid;
// Last modified: $Date: 2007-09-10 10:00:00 +0100 $
{$INCLUDE Jwscl.inc}

interface

uses SysUtils, Classes,
  jwaWindows,
  JwaVista,
  JwsclResource,
  JwsclSid, JwsclToken, JwsclUtils,
  JwsclTypes, JwsclExceptions,
  JwsclVersion, JwsclConstants, 
  JwsclStrings; //JwsclStrings, must be at the end of uses list!!!
{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_IMPLEMENTATION_SECTION}
type
  TJwSecurityKnownSID = class(TJwSecurityId)
  public
     (*@Name frees a known security instance.
       Do not call!
     *)
    procedure Free;


    function IsStandardSIDEx(const aSID: TJwSecurityId): boolean;
      reintroduce; overload; virtual;

    function IsStandardSID: boolean;  override;
  end;

   (*@Name is a class that describes the current user that is running
    the current thread or process.
    Because the user must not be neccessary the current logged on user
    it is called that way.
    Use the var JwSecurityProcessUserSID to get its date. But don't free it.
   *)
  TJwSecurityThreadUserSID = class(TJwSecurityKnownSID)
  protected
    fIsStandard : Boolean;
  public
    constructor Create; overload;
    procedure Free;

    function IsStandardSID: boolean;  override;
  end;


const JwLowIL = 'S-1-16-4096';
      JwMediumIL = 'S-1-16-8192';
      JwHighIL = 'S-1-16-12288';
      JwSystemIL = 'S-1-16-16384';
      JwProtectedProcessIL = 'S-1-16-20480';
var
   JwIntegrityLabelSID : array[TJwIntegrityLabelType] of TJwSecurityKnownSID;
    {@Name defines the current user SID that started the process.
     You need to call JwInitWellknownSIDs before accessing this variable!
     Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwSecurityProcessUserSID;
      ...
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwSecurityProcessUserSID, false)); //see?: false
    #)
    }
  JwSecurityProcessUserSID,


    {@Name defines the local administrator group
     Do not free!!
     You need to call JwInitWellknownSIDs before accessing this variable!

     Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwAdministratorsSID;
      ...
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwSecurityCurrentThreadUserSID, false)); //see?: false
     #)
    }
  JwAdministratorsSID,
    {@Name defines the local user group
     You need to call JwInitWellknownSIDs before accessing this variable!
    
     Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwUsersSID;
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwSecurityCurrentThreadUserSID, false)); //see?: false
     #)
    }
  JwUsersSID,
    {@Name defines the local power user group - legacy in Vista
     You need to call JwInitWellknownSIDs before accessing this variable!

     Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwPowerUsersSID;
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwPowerUsersSID, false)); //see?: false
     #)
    }
  JwPowerUsersSID,
    {@Name defines the local guest group
     You need to call JwInitWellknownSIDs before accessing this variable!
    
     Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwGuestsSID;
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwGuestsSID, false)); //see?: false
     #)
    }
  JwGuestsSID,
    {@Name defines the local system account
     You need to call JwInitWellknownSIDs before accessing this variable!

     Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwLocalSystemSID;
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwLocalSystemSID, false)); //see?: false
     #)
    }
  JwLocalSystemSID,
    {@Name defines the group that allows remote interaction with the machine
     You need to call JwInitWellknownSIDs before accessing this variable!
    
    Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwRemoteInteractiveLogonSID;
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwRemoteInteractiveLogonSID, false)); //see?: false
     #)
    }
  JwRemoteInteractiveLogonSID,
    {@Name defines the NULL Logon SID
     You need to call JwInitWellknownSIDs before accessing this variable!

     Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwNullSID;
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwNullSID, false)); //see?: false
     #)
    }
  JwNullSID,
    {@Name defines the Everybody group
     You need to call JwInitWellknownSIDs before accessing this variable!

     Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwWorldSID;
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwWorldSID, false)); //see?: false
     #)
    }
  JwWorldSID,
    {@Name defines the local group
     You need to call JwInitWellknownSIDs before accessing this variable!

     Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwLocalGroupSID;
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwLocalGroupSID, false)); //see?: false
     #)
    }
  JwLocalGroupSID,

  {@Name defines the network service group
     You need to call JwInitWellknownSIDs before accessing this variable!

    Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwLocalGroupSID;
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwNetworkServiceSID, false)); //see?: false
     #)
    }
  JwNetworkServiceSID,

  {@Name defines the local service group
     You need to call JwInitWellknownSIDs before accessing this variable!

    Use:
     @longcode(#
      SD : TJwSecurityDescriptor;
      ...
      SD.OwnOwner := false;
      SD.Owner := JwLocalGroupSID;
      SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwLocalServiceSID, false)); //see?: false
     #)
    }
  JwLocalServiceSID,

  JwPrincipalSid    : TJwSecurityKnownSID;

  {@Name contains a set of known sids. It is (partly) initialized
   by a call to JwInitWellKnownSIDsEx.
  }
  JwKnownSid : array[TWellKnownSidType] of TJwSecurityKnownSID;


//    LocalAdministratorSID : TJwSecurityKnownSID;

{@Name gets the current owner or impersonated thread owner of the current thread
that is used to call this function.
The caller is responsible to free the SecurityID instance.

Use:
@longcode(#
SD : TJwSecurityDescriptor;
...
SD.OwnOwner := true;
SD.Owner := JwSecurityCurrentThreadUserSID;

SD.DACL.Add(TJwDiscretionaryAccessControlEntryDeny.Create(nil,[],FILE_EXECUTE,JwSecurityCurrentThreadUserSID, true)); //see?: true
#)

}
function JwSecurityCurrentThreadUserSID: TJwSecurityThreadUserSID;


{@Name gets the logon SID of the given window station.


Remark:
This function is useful if a new user must have access to the given windows station
 so she can create windows. One do not have to add the new user to the window station DACL.
This does not work if the user is not logged on as an interactive user.

@param hWinStation defines the window station that is used. If 0 the window station "WinSta0" is used. 
@return The logon SID.
@raises EJwsclWinCallFailedException will be raised if a call to GetUserObjectInformation failed.
}
function JwGetLogonSID(const hWinStation: HWINSTA{TWindowStation} = 0)
  : TJwSecurityId; overload;

function JwGetLogonSID(aToken: TJwSecurityToken): TJwSecurityId; overload;

 
{@Name returns a local or remote machine's SID.
Warning: This function may need some time on remote machines.

@param(ComputerOrDNS defines a DNS or NetBIOS name of the remote server.
      If empty the local machine is used)
@return(Returns an instance of TJwSecurityId which presents the machine)
@raises(EJwsclAccessDenied is raised if retrieving of the machine sid is denied.
 This usually occurs if a remote system could not authenticate the local one.)
@raises(EJwsclInvalidComputer is called if the system in parameter ComputerOrDNS
 could not be resolved.)
@raises(EJwsclWinCallFailedException is raised if a call to NetUserEnum failed.)
@raises(EJwsclNILParameterException is raied if data returned by NetUserEnum
  is nil.)
}
function JwGetMachineSid(const ComputerOrDNS : WideString = '') : TJwSecurityId;

{const
  AllWellKnownSid : TWellKnownSidTypeSet = ($FFFF);}

{@Name initializes the WellKnownSID variables.
 This function should not be called during initialization of
 a Jwscl-unit since it indirectly accesses various global variables,
 e.g. JwProcessHeap, which might not have been initialized yet.
}
procedure JwInitWellKnownSIDs;

{@Name works like @link(JwInitWellKnownSIDs) but also inits the array
JwKnownSid for additional known SIDs. It calls JwInitWellKnownSIDs automatically.

@param(Sids defines a set of SIDs of type TWellKnownSidType that ought to be
  initialized. The function can be called several times with more or the same
   parameter values.)
}
procedure JwInitWellKnownSIDsEx(const Sids : TWellKnownSidTypeSet);
procedure JwInitWellKnownSIDsExAll();


type
  PJwSidMap = ^TJwSidMap;

  {@Name defines a map between a name and its Sid instance.}
  TJwSidMap = record
    {@Name defines a name that is can be used for Sid retrieving.
     Searching is case insensitive.
    }
    Name,
    {@Name defines binary string Sid. It is converted to
     a TJwSecurity instance in JwInitMapping.
     Only used in JwSidMapDef.
     If @Name starts with "-", JwInitMapping will add the local machine Sid
     at front of it.
    }
    SidString : TJwString;

    {@Name defines the Sid instance. Can be nil.}
    Sid  : TJwSecurityId;
  end;

{@Name initialises Sid name mapping.
Must be called before using JwAddMapSid and JwSidMap.

@Name reads JwSidMapDef and adds it to the internal list of
name to Sid mappings.
If a mapping could not be made, JwSidMapDefErrors will contain the index
(JwSidMapDef) of the problem.

}
procedure JwInitMapping;

{@Name adds a string to the string Sid map list.
JwInitMapping must be called before.

@param(Name defines the name of the Sid to be used.
The name can be used for retrieving the Sid. It is case insensitive.)
@param(Sid defines the Sid instance that represents the name. Can not be nil)
@raises(EJwsclNILParameterException will be raised if Sid is nil or
 JwInitMapping was not called)
}
procedure JwAddMapSid(const Name : TJwString; const Sid : TJwSecurityID);

{
@Name returns a Sid instance that was connected to a name.
The advantage of this type is that names are not translated. They are always
the same.

JwInitMapping must be called before.

@param(Name defines the Sid name which is to be retrieved.
 It is case insensitive.)
@raises(EJwsclNILParameterException will be raised if JwInitMapping was not called)
}
function JwSidMap(const Name : TJwString) : TJwSecurityID;


var {@Name defines a list of mapped known Sids which are used
     to retrieve by JwSidMap.
     See TJwSidMap for more information
    }
    JwSidMapDef : array[0..10] of TJwSidMap = (
    (Name : 'Administrator';
     SidString : '-500'),
    (Name : 'Administrators';
     SidString : '1S-1-5-32-544'),
    (Name : 'Guest';
     SidString : '-501'),
    (Name : 'Guests';
     SidString : 'S-1-5-32-546'),
    (Name : '';
     SidString : ''),
    (Name : '';
     SidString : ''),
    (Name : '';
     SidString : ''),
    (Name : '';
     SidString : ''),
    (Name : '';
     SidString : ''),
    (Name : '';
     SidString : ''),
    (Name : '';
     SidString : '')
    );

    {@Name contains a list of numbers that defines which index
     in JwSidMapDef could not be resolved.
    }
    JwSidMapDefErrors : TList;

{$ENDIF SL_IMPLEMENTATION_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}
implementation

uses Dialogs, IniFiles;

{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_INTERFACE_SECTION}


var SidMaps : TList;

procedure JwInitMapping;
var i : Integer;
    LocalSid,
    Sid : TJwSecurityID;
    LocalSidStr,
    Str : TJwString;
    Map : PJwSidMap;
label RestartLoop;
begin
  if not Assigned(SidMaps) then
    SidMaps := TList.Create;
  SidMaps.Clear;

  LocalSid := JwGetMachineSid();
  LocalSidStr := LocalSid.StringSID;
  LocalSid.Free;


  if not Assigned(JwSidMapDefErrors) then
    JwSidMapDefErrors := TList.Create;
  JwSidMapDefErrors.Clear;

  i := low(JwSidMapDef);

  {We use goto here because
   a try/except within a loop can be really slow for
   many loops.
   However the solution creating a new procedure
   and call it recursively is also not a good idea
   because if many errors occur stack can become low of memory.
   So if we jump out of loop in case of exception
   we can simply jump back to next loop item. 
  }
RestartLoop:
  try
    while i <= high(JwSidMapDef) do
    begin
      if Length(JwSidMapDef[i].SidString) > 0 then
      begin
        Str := JwSidMapDef[i].SidString;
        if JwSidMapDef[i].SidString[1] = '-' then
          Str := LocalSidStr + Str;

        Sid := TJwSecurityID.Create(Str);

        New(Map);
        Map.Name := JwSidMapDef[i].Name;
        Map.SidString := Str;
        Map.Sid := Sid;
        SidMaps.Add(Map);
      end;
      Inc(i);
    end;
  except
    JwSidMapDefErrors.Add(Pointer(i));
    Inc(i);
  end;
  //also within loop!
  if i <= high(JwSidMapDef) then
    goto RestartLoop;

end;

procedure JwDoneMapping;
var i : Integer;
begin
  if not Assigned(SidMaps) then
    exit;

  for i := 0 to SidMaps.Count -1 do
  begin
    if SidMaps[i] <> nil then
      Dispose(PJwSidMap(SidMaps[i]))
  end;
  FreeAndNil(SidMaps);
  FreeAndNil(JwSidMapDefErrors);
end;

procedure JwAddMapSid(const Name : TJwString; const Sid : TJwSecurityID);
var Map : PJwSidMap;
begin
  JwRaiseOnNilParameter(SidMaps, 'JwInitMapping must be called.', 'JwAddMapSid','', RsUNKnownSid);
  JwRaiseOnNilParameter(Sid, 'Sid', 'JwAddMapSid','', RsUNKnownSid);

  New(Map);
  Map.Name := Name;
  Map.Sid := Sid;
  SidMaps.Add(Map);
end;

function JwSidMap(const Name : TJwString) : TJwSecurityID;
var i : Integer;
    Map : PJwSidMap;
begin
  JwRaiseOnNilParameter(SidMaps, 'JwInitMapping must be called.', 'JwAddMapSid','', RsUNKnownSid);

  result := nil;

  for i := 0 to SidMaps.Count-1 do
  begin
    if JwCompareString(Name, PJwSidMap(SidMaps.Items[i]).Name, true) = 0 then
    begin
      result := PJwSidMap(SidMaps.Items[i]).Sid;
      exit;
    end;
  end;

  raise EJwsclIndexOutOfBoundsException.Create('');
end;



function JwGetMachineSid(const ComputerOrDNS : WideString = '') : TJwSecurityId;
var Token : TJwSecurityToken;
    Sid{,Sid2} : TJwSecurityId;
    Arr : TJwSubAuthorityArray;
    Ident : TSidIdentifierAuthority;

    Data : PBYTE;
    UserInfo : PUSER_INFO_0;
    //UserInfo2 : PUSER_MODALS_INFO_2;

    res,
    entriesread,
    totalentries,
    resume_handle : DWORD;
begin
  Data := nil;

  //get local users
  res := NetUserEnum(
    PWideChar(ComputerOrDNS),
    0, //__in     DWORD level,
    FILTER_NORMAL_ACCOUNT,//__in     DWORD filter,
    Data,//__out    LPBYTE* bufptr,
    1,{read only one entry}//sizeof(USER_INFO_0),//MAX_PREFERRED_LENGTH,//__in     DWORD prefmaxlen,
    @entriesread,//__out    LPDWORD entriesread,
    @totalentries,//__out    LPDWORD totalentries,
    nil//__inout  LPDWORD resume_handle
  );

//  res := NetUserModalsGet(PWideChar(ComputerOrDNS), 2, Data);

  if (res <> NERR_Success) and (res <> ERROR_MORE_DATA) then
  begin
    case res of
      ERROR_ACCESS_DENIED :
        raise EJwsclAccessDenied.CreateFmtWinCall(
          RsAccessDenied,
          'JwGetMachineSid', '', RsUNKnownSid,
          0, false, 'NetUserEnum', []);
      53,
      NERR_InvalidComputer :
        raise EJwsclInvalidComputer.CreateFmtWinCall(
          RsInvalidComputer,
          'JwGetMachineSid', '', RsUNKnownSid,
          0, false, 'NetUserEnum', []);
      else
      begin
        SetLastError(res);
        raise EJwsclWinCallFailedException.CreateFmtWinCall(
          RsWinCallFailedWithNTStatus,
          'JwGetMachineSid', '', RsUNKnownSid,
          0, true, 'NetUserEnum', ['NetUserEnum',res]);
      end;
    end
  end;




  try
    if Data = nil then
      JwRaiseOnNilParameter(Data, 'NetUserEnum(..bufptr..)', 'JwGetMachineSid','', RsUNKnownSid);

    UserInfo := PUSER_INFO_0(Data);
  //  UserInfo2 := PUSER_MODALS_INFO_2(Data);


    //get sid of that user
    Sid := TJwSecurityId.Create(ComputerOrDNS,UserInfo.usri0_name);
  //  Sid := TJwSecurityId.Create(UserInfo2.usrmod2_domain_id);
    try
      Arr   := SID.SubAuthorityArray;
      Ident := SID.IdentifierAuthority;

      if Length(Arr) >= 5 then
        //strip the RID (last member)
        SetLength(Arr, High(Arr));
        
      result := TJwSecurityId.Create(Arr,Ident);
      //also copy cached system name
      result.CachedSystemName := SID.CachedSystemName;

      //ShowMessage(result.GetText(true));
    finally
      SID.Free;
    end;
  finally
    NetApiBufferFree(Data);
  end;
end;

var KnownSids : array[1..75] of AnsiString =
     ('S-1-0-0',
      'S-1-1-0',
      'S-1-2-0',
      'S-1-3-0',
      'S-1-3-1',
      'S-1-5',
      'S-1-5-1',
      'S-1-5-2',
      'S-1-5-3',
      'S-1-5-4',
      'S-1-5-5-Lhi-Llo',
      'S-1-5-6',
      'S-1-5-7',
      'S-1-5-8',
      'S-1-5-9',
      'S-1-5-10',
      'S-1-5-11',
      'S-1-5-12',
      'S-1-5-13',
      'S-1-5-14',
      'S-1-5-15',
      'S-1-5-16',
      'S-1-5-17',
      'S-1-5-18',
      'S-1-5-19',
      'S-1-5-20',
      'S-1-5-21',
      'S-1-5-32',
      'S-1-5-1000',
      'S-1-5-64-10',
      'S-1-5-64-14',
      'S-1-5-64-21',
//
      'S-1-5-#-500',
      'S-1-5-#-501',
      'S-1-5-#-502',
      'S-1-5-#-503',
      'S-1-5-#-504',
      'S-1-5-#-505',
      'S-1-5-#-506',
      'S-1-5-#-507',
      'S-1-5-#-508',
      'S-1-5-#-509',
      'S-1-5-#-510',
      'S-1-5-#-511',
      'S-1-5-#-512',
      'S-1-5-#-513',
      'S-1-5-#-514',
      'S-1-5-#-515',
      'S-1-5-#-516',
      'S-1-5-#-517',
      'S-1-5-#-518',
      'S-1-5-#-519',
      'S-1-5-#-520',
      'S-1-5-#-521',
      'S-1-5-#-533',
      'S-1-5-#-544',
      'S-1-5-#-545',
      'S-1-5-#-546',
      'S-1-5-#-547',
      'S-1-5-#-548',
      'S-1-5-#-549',
      'S-1-5-#-550',
      'S-1-5-#-551',
      'S-1-5-#-552',
      'S-1-5-#-553',
      'S-1-5-#-554',
      'S-1-5-#-555',
      'S-1-5-#-556',
      'S-1-5-#-557',
      'S-1-5-#-558',
      'S-1-5-#-559',
      'S-1-5-#-560',
      'S-1-5-#-561',
      'S-1-5-#-562',
      'S-1-5-#-563'
      );


procedure InitSid(const Idx : Integer; var SID : TJwSecurityKnownSID);
begin
  if not Assigned(SID) then
  try
    SID := TJwSecurityKnownSID.Create(KnownSids[Idx]);
  except
    On E : Exception do
    begin
{$IFDEF DEBUG}
      OutputDebugStringA(Pchar(Format('%s. Security id: %s ',[E.Message,KnownSids[Idx]])));
{$ENDIF DEBUG}
      SID := nil;
    end;
  end;
end;


var
  OnFinalization: boolean = False;
//fSecurityCurrentThreadUserSID : TJwSecurityThreadUserSID = nil;


function JwGetLogonSID(aToken: TJwSecurityToken): TJwSecurityId;
var
  i: integer;
  ptg: TJwSecurityIdList;
begin
  Result := nil;
  ptg := aToken.GetTokenGroups;

  // Loop through the groups to find the logon SID.
  for i := 0 to ptg.Count - 1 do
  begin
    if (ptg[i].Attributes and SE_GROUP_LOGON_ID) = SE_GROUP_LOGON_ID then
    begin
      // Found the logon SID; make a copy of it.
      Result := TJwSecurityId.Create(ptg[i].CreateCopyOfSID);
      Break;
    end;
  end;
end;

function JwGetLogonSID(const hWinStation: HWINSTA{TWindowStation})
: TJwSecurityId;
var
  hAWinst: HWINSTA;
  logonSID: PSID;
  dwSize: Cardinal;
begin
  haWinst := hWinStation;
  if (hWinStation = 0) or (hWinStation = INVALID_HANDLE_VALUE) then
    hAWinst := OpenWindowStation('winsta0',
      False, WINSTA_READATTRIBUTES
      );
  Result := nil;

  if (hAWinst = 0) then
    exit;

  if not GetUserObjectInformation(hAWinst, UOI_USER_SID, nil, 0, dwSize) then
  begin
    // GetUserObjectInformation returns required size
    GetMem(LogonSid, dwSize + 1);
    if not GetUserObjectInformation(hAWinst, UOI_USER_SID,
      LogonSid, dwSize, dwSize) then
    begin
      raise EJwsclWinCallFailedException.CreateFmtWinCall(
        RsWinCallFailed,
        'JwGetLogonSID', '', RsUNKnownSid,
        0, True, 'GetUserObjectInformation', ['GetUserObjectInformation']);
    end;
    if logonSID <> nil then
    begin
      Result := TJwSecurityId.Create(logonSID);
      FreeMem(logonSID);
    end;
  end;

  if (hWinStation = 0) and (hWinStation = INVALID_HANDLE_VALUE) then
    CloseWindowStation(hAWinst);
end;




function JwSecurityCurrentThreadUserSID: TJwSecurityThreadUserSID;
begin
  //if Assigned(fSecurityCurrentThreadUserSID) then
  //  fSecurityCurrentThreadUserSID.Free;

  //fSecurityCurrentThreadUserSID := TJwSecurityThreadUserSID.Create;
  //result := fSecurityCurrentThreadUserSID;
  Result := TJwSecurityThreadUserSID.Create;
end;

{ TJwSecurityThreadUserSID }

constructor TJwSecurityThreadUserSID.Create;
var
  token: TJwSecurityToken;
  s: TJwSecurityId;
begin
  fIsStandard := false;
  
  token := TJwSecurityToken.CreateTokenEffective(TOKEN_ALL_ACCESS);
  S := nil;
  try
    S := token.GetTokenUser;
    inherited Create(S);
  finally
    token.Free;
    S.Free;
  end;
end;

procedure TJwSecurityThreadUserSID.Free;
begin
  //if (not OnFinalization) and (JwSecurityProcessUserSID = Self) then
  //  raise EJwsclSecurityException.CreateFmtEx('Call to Free failed, because the var JwSecurityProcessUserSID cannot be freed manually.','Free',ClassName,'JwsclKnownSid.pas',0,false,[]);

  inherited;
end;

function TJwSecurityThreadUserSID.IsStandardSID: boolean;
begin
  Result := fIsStandard;
end;

{ TJwSecurityKnownSID }

procedure TJwSecurityKnownSID.Free;
begin
  inherited;
end;

function TJwSecurityKnownSID.IsStandardSIDEx(const aSID: TJwSecurityId): boolean;
begin
  Result := (aSID.ClassType = TJwSecurityThreadUserSID) or
    (aSID.ClassType = TJwSecurityThreadUserSID);
end;


procedure JwInitWellKnownSIDsExAll();
var i : TWellKnownSidType;
begin
  JwInitWellKnownSIDs;

  for i := low(TWellKnownSidType) to high(TWellKnownSidType) do
  begin
    try
      if not Assigned(JwKnownSid[i]) then
        JwKnownSid[i] := TJwSecurityKnownSID.
          CreateWellKnownSid(jwaVista.TWellKnownSidType(i));
    except
      JwKnownSid[i] := nil;
    end;
  end;
end;


procedure JwInitWellKnownSIDsEx(const Sids : TWellKnownSidTypeSet);
var i : TWellKnownSidType;
begin
  JwInitWellKnownSIDs;

  for i := low(TWellKnownSidType) to high(TWellKnownSidType) do
  begin
    if i in Sids then
    begin
      if not Assigned(JwKnownSid[i]) then
        JwKnownSid[i] := TJwSecurityKnownSID.
          CreateWellKnownSid(jwaVista.TWellKnownSidType(i));
    end;
  end;
end;

procedure JwInitWellKnownSIDs;
begin
  if not Assigned(JwAdministratorsSID) then
    JwAdministratorsSID := TJwSecurityKnownSID.Create('S-1-5-32-544');
  if not Assigned(JwUsersSID) then
    JwUsersSID := TJwSecurityKnownSID.Create('S-1-5-32-545');
  if not Assigned(JwGuestsSID) then
    JwGuestsSID := TJwSecurityKnownSID.Create('S-1-5-32-546');
  if not Assigned(JwPowerUsersSID) then
    JwPowerUsersSID := TJwSecurityKnownSID.Create('S-1-5-32-547');
  if not Assigned(JwLocalSystemSID) then
    JwLocalSystemSID := TJwSecurityKnownSID.Create('S-1-5-18');
  if not Assigned(JwRemoteInteractiveLogonSID) then
    JwRemoteInteractiveLogonSID := TJwSecurityKnownSID.Create('S-1-5-14');
  if not Assigned(JwNullSID) then
    JwNullSID := TJwSecurityKnownSID.Create('S-1-0-0');
  if not Assigned(JwWorldSID) then
    JwWorldSID := TJwSecurityKnownSID.Create('S-1-1-0');
  if not Assigned(JwLocalGroupSID) then
    JwLocalGroupSID := TJwSecurityKnownSID.Create('S-1-2-0');
  if not Assigned(JwNetworkServiceSID) then
    JwNetworkServiceSID := TJwSecurityKnownSID.Create('S-1-5-20');
  if not Assigned(JwLocalServiceSID) then
    JwLocalServiceSID := TJwSecurityKnownSID.Create('S-1-5-19');
  if not Assigned(JwPrincipalSid) then
    JwPrincipalSid := TJwSecurityKnownSID.Create('S-1-5-10');





  if not Assigned(JwSecurityProcessUserSID) then
    JwSecurityProcessUserSID := TJwSecurityThreadUserSID.Create;
  (JwSecurityProcessUserSID as TJwSecurityThreadUserSID).fIsStandard := true;

  JwIntegrityLabelSID[iltNone]       := nil;
  if not Assigned(JwIntegrityLabelSID[iltLow]) then
    JwIntegrityLabelSID[iltLow]       := TJwSecurityKnownSID.Create(JwLowIL);
  if not Assigned(JwIntegrityLabelSID[iltMedium]) then
    JwIntegrityLabelSID[iltMedium]    := TJwSecurityKnownSID.Create(JwMediumIL);
  if not Assigned(JwIntegrityLabelSID[iltHigh]) then
    JwIntegrityLabelSID[iltHigh]      := TJwSecurityKnownSID.Create(JwHighIL);
  if not Assigned(JwIntegrityLabelSID[iltSystem]) then
    JwIntegrityLabelSID[iltSystem]    := TJwSecurityKnownSID.Create(JwSystemIL);
  if not Assigned(JwIntegrityLabelSID[iltProtected]) then
    JwIntegrityLabelSID[iltProtected] := TJwSecurityKnownSID.Create(JwProtectedProcessIL);
end;

procedure DoneWellKnownSIDs;
var ilts : TJwIntegrityLabelType;
    i : TWellKnownSidType;
begin

  FreeAndNil(JwAdministratorsSID);
  FreeAndNil(JwUsersSID);
  FreeAndNil(JwGuestsSID);
  FreeAndNil(JwPowerUsersSID);
  FreeAndNil(JwLocalSystemSID);
  FreeAndNil(JwRemoteInteractiveLogonSID);
  FreeAndNil(JwNullSID);
  FreeAndNil(JwWorldSID);
  FreeAndNil(JwLocalGroupSID);
  FreeAndNil(JwNetworkServiceSID);
  FreeAndNil(JwLocalServiceSID);
  FreeAndNil(JwSecurityProcessUserSID);
  FreeAndNil(JwPrincipalSid);
  //  FreeAndNil(fSecurityCurrentThreadUserSID);

  for ilts := low(TJwIntegrityLabelType) to high(TJwIntegrityLabelType) do
    FreeAndNil(JwIntegrityLabelSID[ilts]);


  for i := low(TWellKnownSidType) to high(TWellKnownSidType) do
  begin
    FreeAndNil(JwKnownSid[i]);
  end;
end;

function TJwSecurityKnownSID.IsStandardSID: boolean;
begin
  Result := True;
end;

procedure NilWellKnownSid;
var i : TWellKnownSidType;
begin
  for i := low(TWellKnownSidType) to high(TWellKnownSidType) do
  begin
    JwKnownSid[i] := nil;
  end;
end;

{$ENDIF SL_INTERFACE_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}
initialization
{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_INITIALIZATION_SECTION}
  JwSecurityProcessUserSID := nil;
  JwAdministratorsSID := nil;
  JwUsersSID := nil;
  JwPowerUsersSID := nil;
  JwGuestsSID := nil;
  JwLocalSystemSID := nil;
  JwRemoteInteractiveLogonSID := nil;
  JwNullSID  := nil;
  JwWorldSID := nil;
  JwLocalGroupSID := nil;
  JwNetworkServiceSID := nil;
  JwLocalServiceSID := nil;
  JwPrincipalSid := nil;

  NilWellKnownSid;

{$ENDIF SL_INITIALIZATION_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}
finalization
{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_FINALIZATION_SECTION}
  OnFinalization := True;
  DoneWellKnownSIDs;
  JwDoneMapping;
{$ENDIF SL_FINALIZATION_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}
end.
{$ENDIF SL_OMIT_SECTIONS}