{@abstract(Provides access to security token objects)
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

The Original Code is JwsclToken.pas.

The Initial Developer of the Original Code is Christian Wimmer.
Portions created by Christian Wimmer are Copyright (C) Christian Wimmer. All rights reserved.

Description:
This unit contains ansi- and unicode string types that are used by the units of JWSCL.
You can define UNICODE to use unicode strings. Otherwise ansicode will be used.

TODO:
use
@longcode(#
CheckTokenHandle('SetfTokenDefaultDacl');
CheckTokenAccessType(TOKEN_ADJUST_DEFAULT, 'TOKEN_ADJUST_DEFAULT',
    'SetfTokenDefaultDacl');
#)
for all token methods.


}
{$IFNDEF SL_OMIT_SECTIONS}
unit JwsclToken;
{$INCLUDE Jwscl.inc}
// Last modified: $Date: 2007-09-10 10:00:00 +0100 $

interface

uses SysUtils, Contnrs, Classes,
  Windows, Dialogs,
  jwaWindows, JwsclResource, JwsclUtils, JwaVista,
  JwsclTypes, JwsclExceptions, JwsclSid, JwsclAcl,
  JwsclDescriptor,
  JwsclVersion, JwsclConstants, JwsclProcess,
  JwsclStrings; //JwsclStrings, must be at the end of uses list!!!
{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_IMPLEMENTATION_SECTION}
type
  TJwPrivilegeSet = class;
  TJwPrivilege    = class;
  TJwSecurityTokenStatistics = class;


     {@Name administers a token (impersonated or primary)
      All token information are retrieved dynamically.
      The token handle is closed on instance destroying if Shared is set to false.

      A token is a security card that gives the logged on user the right to do things (like start processes a.s.o).
      Without a token the user would have to prove his/her security state to the system every time.

      The system creates a process token for the process that it can use to get its security constraints.
      A process token is also called primary token. The process can create threads and decrement their security
      state by copying the primary token and remove privileges and/or add restrictions. However a thread
      cannot use a process/primary token. Instead it can only use a impersonated token. So the token must be converted
      to a impersonation token. However the first process token cannot be converted. It must be duplicated and then
      converted. After that the thread can call SetThreadToken to change its security context.

      Actually these token functions are not supported :
      @unorderedlist(
      @item - NTCreateToken
      )

      @Name does only support few vista enhancements :
        @unorderedlist(
        @item Elevation
        @item ElevationType
      )

      @Name does not support some of the values defined in the MSDN http://msdn2.microsoft.com/en-us/library/aa379626.aspx

      @abstract(@Name administers a token (impersonated or not))
      }

  TJwSecurityToken = class(TObject)//,ISecurityMemoryClass)
  private
       {fPrivelegesList administers all created privileges list by @link(GetTokenPrivileges).
        If a list was not freed by user, it will be freed on the instance ending.
        }
    fPrivelegesList: TObjectList;
    fStackPrivilegesList: TObjectList;
    //internal token handle
    fTokenHandle: TJwTokenHandle;
    //shared status
    fShared:     boolean;
    fAccessMask: TJwAccessMask;
       {@Name is called by Destroy to free all things that were allocated by Create();
        Only objects are destroyed!
       }
    procedure Done; virtual;
       {@Name restores privileges from a nested call to PushPrivileges.
        TODO: to test
        @return Returns the count of privilege stack elements.
       }
    function PopPrivileges: Cardinal;
              {@Name saves the actual privilege enabled states in a stack.
        They can be restored with a correctly nested call to PopPrivileges.
               TODO: to test
        @return
       }
    function PushPrivileges: Cardinal;
  public
    {see @link(TokenType)}
    function GetTokenType: TOKEN_TYPE; virtual;

        {@Name returns the needed memory for a token information.
         @param(hTokenHandle receives the token handle)
         @param(aTokenInformationClass receives token class
              See @link(GetTokenInformationLength GetTokenInformationLength) for class types.)
         @return(Returns the length of needed memory buffer. If the call failed zero will be returned);
         }
    function GetTokenInformationLength(hTokenHandle: TJwTokenHandle;
      aTokenInformationClass: TTokenInformationClass): Cardinal; virtual;


        {@Name returns a buffer filled with token information.
        @param(hTokenHandle receives the token handle)
         @param(aTokenInformationClass receives token class.
           Legend : o  defines already implemented structures.
              @unorderedlist(
              @item TokenDefaultDacl   The buffer receives a TOKEN_DEFAULT_DACL structure containing the default DACL for newly created objects.
              @item o TokenGroups   The buffer receives a TOKEN_GROUPS structure containing the group accounts associated with the token.
              @item TokenGroupsAndPrivileges   The buffer receives a TOKEN_GROUPS_AND_PRIVILEGES structure containing the user SID, the group accounts, the restricted SIDs, and the authentication ID associated with the token.
              @item o TokenImpersonationLevel   The buffer receives a SECURITY_IMPERSONATION_LEVEL value indicating the impersonation level of the token. If the access token is not an impersonation token, the function fails.
              @item o TokenOrigin   The buffer receives a TOKEN_ORIGIN value that contains information about the logon session ID.
              @item o TokenOwner   The buffer receives a TOKEN_OWNER structure containing the default owner SID for newly created objects.
              @item o TokenPrimaryGroup   The buffer receives a TOKEN_PRIMARY_GROUP structure containing the default primary group SID for newly created objects.
              @item o TokenPrivileges   The buffer receives a TOKEN_PRIVILEGES structure containing the token's privileges.
              @item o TokenRestrictedSids   The buffer receives a TOKEN_GROUPS structure containing the list of restricting SIDs in a restricted token.
              @item TokenSandBoxInert   The buffer receives a DWORD value that is nonzero if the token includes the SANDBOX_INERT flag.
              @item o TokenSessionId   The buffer receives a DWORD value that contains the Terminal Services session identifier associated with the token. If the token is associated with the Terminal Server console session, the session identifier is zero. A nonzero session identifier indicates a Terminal Services client session. In a non-Terminal Services environment, the session identifier is zero.
              @item o TokenSource   The buffer receives a TOKEN_SOURCE structure containing the source of the token. TOKEN_QUERY_SOURCE access is needed to retrieve this information.
              @item TokenStatistics   The buffer receives a TOKEN_STATISTICS structure containing various token statistics.
              @item o TokenType   The buffer receives a TOKEN_TYPE value indicating whether the token is a primary or impersonation token.
              @item o TokenUser   The buffer receives a TOKEN_USER structure containing the token's user account.)
              )
         @param(TokenInformation contains the requested information. You must convert the type to the appropiate token type information class.)

        @raises EJwsclTokenInformationException is raised if a call to GetTokenInformation failed.
        @raises EJwsclAccessTypeException is raised if the given token access rights is not enough to do the necessary work.
          In this case the token instance must be reopened with sufficient rights.
        @raises EJwsclInvalidTokenHandle is raised if the token handle is invalid. Not opened or closed already.
        @raises EJwsclNotEnoughMemory is raised if a call to HeapAlloc failed because of not enough space.
         }
    procedure GetTokenInformation(hTokenHandle: TJwTokenHandle;
      TokenInformationClass: TTokenInformationClass;
      out TokenInformation: Pointer); virtual;

    {see property @link(ImpersonationLevel)}
    function GetImpersonationLevel: TSecurityImpersonationLevel; virtual;


    function GetTokenUser: TJwSecurityId; virtual;
    procedure GetTokenSource(out SourceName: ShortString;
      out SourceLUID: TLuid); overload; virtual;
    function GetTokenSource: TTokenSource; overload; virtual;

    function GetTokenGroups: TJwSecurityIdList; virtual;
    procedure SetTokenGroups(List: TJwSecurityIdList); virtual;

    function GetTokenGroupsEx: PTokenGroups;

    function GetTokenGroupsAttributesInt(Index : Integer) : TJwSidAttributeSet;
    procedure SetTokenGroupsAttributesInt(Index : Integer; Attributes: TJwSidAttributeSet);

    function GetTokenGroupsAttributesSid(Sid : TJwSecurityId) : TJwSidAttributeSet;
    procedure SetTokenGroupsAttributesSid(Sid : TJwSecurityId; Attributes: TJwSidAttributeSet);


    function GetTokenRestrictedSids: TJwSecurityIdList; virtual;



    function GetTokenDefaultDacl: TJwDAccessControlList;

    {This function is not implemented}
    procedure SetTokenDefaultDacl(
      const aDefaultDCAL: TJwDAccessControlList);
      virtual; //TOKEN_ADJUST_DEFAULT

    function GetTokenOrigin: TLuid; virtual;
    procedure SetTokenOrigin(const anOrigin: TLuid);
      virtual; //SE_TCB_NAME

    function GetTokenOwner: TJwSecurityId; virtual;
    procedure SetTokenOwner(const anOwner: TJwSecurityId);
      virtual; //TOKEN_ADJUST_DEFAULT

    function GetPrimaryGroup: TJwSecurityId; virtual;
    procedure SetPrimaryGroup(const PrimGroup: TJwSecurityId);
      virtual; //TOKEN_ADJUST_DEFAULT


    function GetTokenSessionId: Cardinal; virtual;
    procedure SetTokenSessionId(const SessionID: Cardinal);
      virtual; //SE_TCB_NAME


    function GetPrivilegeEnabled(Name: string): boolean; virtual;
    procedure SetPrivilegeEnabled(Name: string; En: boolean); virtual;

    function GetPrivilegeAvailable(Name: string): boolean;

    function GetIntegrityLevel : TJwSecurityIdList;
    function GetLinkedToken : TJwSecurityToken;

    function GetRunElevation: Cardinal;
    function GetElevationType: TTokenElevationType;

    function GetVirtualizationAllowed: boolean;
    function GetVirtualizationEnabled: boolean;

    function GetMandatoryPolicy : DWORD;

  protected
        {@Name checks the TokenHandle of this instance and raises EJwsclInvalidTokenHandle if the token is invalid; otherwise it does nothing
         @param(aSourceProc defines the caller method) 
         @raises(EJwsclInvalidTokenHandle is raised if the property TokenHandle is invalid.)}
    procedure CheckTokenHandle(sSourceProc: string); virtual;

        {@Name checks if the given token was opened with the desired access mask.
         If the desired access is not included in the token access mask an exception will be raised; otherwise nothing happens.
         @param(aDesiredAccessMask contains access mask that must be included in the token access mask to succeed.)
         @param(StringMask contains the desired access mask in a human readable format. This string will be display in the exception description.)
         @param(SourceProc contains the method name of the caller method.)
         @raises(EJwsclAccessTypeException will be raised if a desired access flag could not be found in the access mask of the token)
         }
    procedure CheckTokenAccessType(aDesiredAccessMask: TJwAccessMask;
      StringMask, SourceProc: TJwString);

        {@Name checks if the token has all privileges that was given in the array.
        It does not matter whether the privilege is en- or disabled. It simply must exist.
        The privilege names are compared case sensitive. 
        @param(Privileges contains all privileges names that the token must held)
        @raises(EJwsclPrivilegeCheckException will be raised if one privilege was not found)
        }

    procedure CheckTokenPrivileges(Privileges: array of string);

        {@Name checks if one token holds a privilege.
         The privilege names are compared case sensitive.
         @param(Priv contains the privilege name to be checked for)
         @return(@Name returns true if the privilege could be found in the tokens privileges; otherwise false)
        }
    function IsPrivilegeAvailable(Priv: string): boolean;

    function GetIsRestricted: boolean;

    function GetMaximumAllowed : TAccessMask;

  public
    {@Name TBD}
    constructor Create; overload;


    destructor Destroy; override;

        {
        CreateTokenByProcess creates a new instances and opens a process token.

        @param(aProcessHandle Receives a process handle which is used to get the process token. The handle can be zero (0) to use the actual process handle of the caller)
        @param(aDesiredAccess Receives the desired access for this token. The access types can be get from the following list. Access flags must be concatenated with or operator.
        If you want to use DuplicateToken or creating an impersonated token (by ConvertToImpersonatedToken) you must specific TOKEN_DUPLICATE.

        Access Rights for Access-Token Objects:
                from http://msdn2.microsoft.com/en-us/library/aa374905.aspx:
        @unorderedlist(
        @item TOKEN_ADJUST_DEFAULT   Required to change the default owner, primary group, or DACL of an access token.
        @item TOKEN_ADJUST_GROUPS   Required to adjust the attributes of the groups in an access token.
        @item TOKEN_ADJUST_PRIVILEGES   Required to enable or disable the privileges in an access token.
        @item TOKEN_ADJUST_SESSIONID   Required to adjust the session ID of an access token. The SE_TCB_NAME privilege is required.
        @item TOKEN_ASSIGN_PRIMARY   Required to attach a primary token to a process. The SE_ASSIGNPRIMARYTOKEN_NAME privilege is also required to accomplish this task.
        @item TOKEN_DUPLICATE   Required to duplicate an access token.
        @item TOKEN_EXECUTE   Combines STANDARD_RIGHTS_EXECUTE and TOKEN_IMPERSONATE.
        @item TOKEN_IMPERSONATE   Required to attach an impersonation access token to a process.
        @item TOKEN_QUERY   Required to query an access token.
        @item TOKEN_QUERY_SOURCE   Required to query the source of an access token.
        @item TOKEN_READ   Combines STANDARD_RIGHTS_READ and TOKEN_QUERY.
        @item TOKEN_WRITE   Combines STANDARD_RIGHTS_WRITE, TOKEN_ADJUST_PRIVILEGES, TOKEN_ADJUST_GROUPS, and TOKEN_ADJUST_DEFAULT.
        @item TOKEN_ALL_ACCESS
        )

        Standard Access Rights:
                from http://msdn2.microsoft.com/en-us/library/aa379607.aspx
        @unorderedlist(
        @item DELETE   The right to delete the object.
        @item READ_CONTROL   The right to read the information in the object's security descriptor, not including the information in the SACL.
        @item SYNCHRONIZE   The right to use the object for synchronization. This enables a thread to wait until the object is in the signaled state. Some object types do not support this access right.
        @item WRITE_DAC   The right to modify the DACL in the object's security descriptor.
        @item WRITE_OWNER   The right to change the owner in the object's security descriptor.
        )
        The Windows API also defines the following combinations of the standard access rights constants.
        @unorderedlist(
        @item Constant   Meaning
        @item STANDARD_RIGHTS_ALL   Combines DELETE, READ_CONTROL, WRITE_DAC, WRITE_OWNER, and SYNCHRONIZE access.
        @item STANDARD_RIGHTS_EXECUTE   Currently defined to equal READ_CONTROL.
        @item STANDARD_RIGHTS_READ   Currently defined to equal READ_CONTROL.
        @item STANDARD_RIGHTS_REQUIRED   Combines DELETE, READ_CONTROL, WRITE_DAC, and WRITE_OWNER access.
        @item STANDARD_RIGHTS_WRITE
        )
        )

        @raises(EJwsclOpenProcessTokenException If the token could not be opened)
        }
    constructor CreateTokenByProcess(
      const aProcessHandle: TJwProcessHandle;
      const aDesiredAccess: TJwAccessMask); virtual;

        {CreateTokenByThread creates a new instances and opens a thread token.

        @param(aProcessHandle Receives a process handle which is used to get the process token. The handle can be zero (0) to use the actual process handle of the caller)
        @param(aDesiredAccess Receives the desired access for this token. The access types can be get from the following list. Access flags must be concatenated with or operator.
        If you want to use DuplicateToken or creating an impersonated token (by ConvertToImpersonatedToken) you must specific TOKEN_DUPLICATE.

        See @link(CreateTokenByProcess CreateTokenByProcess) for a list of access rights.)
        @param(anOpenAsSelf Indicates whether the access check is to be made against the security context of the thread calling the CreateTokenByThread function or against the
                                security context of the process for the calling thread)


        @raises(EJwsclNoThreadTokenAvailable will be raised if you try to call @name in a process rather than thread)
        @raises(EJwsclOpenThreadTokenException will be raised if the threak token could not be opened)

        }
    constructor CreateTokenByThread(const aThreadHandle: TJwThreadHandle;
      const aDesiredAccess: TJwAccessMask;
      const anOpenAsSelf: boolean); virtual;

        {@Name opens a thread token or process. If it can not open the thread token it simply opens the process tokens
        @param(aDesiredAccess Receives the desired access for this token. The access types can be get from the following list. Access flags must be concatenated with or operator.
        If you want to use DuplicateToken or creating an impersonated token (by ConvertToImpersonatedToken) you must specific TOKEN_DUPLICATE.

        See @link(CreateTokenByProcess CreateTokenByProcess) for a list of access rights.)}
    constructor CreateTokenEffective(const aDesiredAccess: TJwAccessMask);
      virtual;

        {@Name create a duplicate token from an existing one. The token will be a primary one.
         You cannot use the class to adapt an existing token, because the access mask of the token is unkown. (AccessCheck not implemented yet)
         The token needs the TOKEN_DUPLICATE access type.

         @param(aTokenHandle The token handle to be copied.)
         @param(aDesiredAccess The access type of the new token)
         @param(UseDuplicateExistingToken For C++ compability only. If you are using C++ and want to use this constructor instead of Create.
              Set this parameter to true of false. This parameter is ignored!)
         }
    constructor CreateDuplicateExistingToken(
      const aTokenHandle: TJwTokenHandle;
      const aDesiredAccess: TJwAccessMask;
      UseDuplicateExistingToken: boolean = False); virtual;

    constructor Create(const aTokenHandle: TJwTokenHandle;
      const aDesiredAccess: TJwAccessMask); overload; virtual;

        {@Name opens a token of a logged on user.

         This constructor is only present on Windows XP/2003 or higher systems.
         This call fails if the thread does not have system privileges (belong to system).
         Enable SE_TCB_NAME privilege for none system principals.

         This token can be used to get a token from the specified user in a
         terminal session (also Fast User Switching). For example: This token is necessary
         to call CreateProcessAsUser to lunch a process in the given terminal session.

         @param(SessionID defines the session which is used to obtain the token.
               If set to INVALID_HANDLE_VALUE, the function does the following :
               @orderedlist(
                @item(Try to open the token of the actual console session. Using WtsGetActiveConsoleSessionID to obtain the session ID.)
                @item(Try to open the token of the current session using the session ID WTS_CURRENT_SESSION)
                )
               If this fails an exception is raised.)

         @raises(EJwsclUnsupportedWindowsVersionException is raised if the Windows System does not have WTS function support)
         @raises(EJwsclPrivilegeCheckException is raised if the privilege SE_TCB_NAME is not held.)
         @raises(EJwsclWinCallFailedException if a call to WTSQueryUserToken failed)
         }
    constructor CreateWTSQueryUserToken(
      SessionID: Cardinal = INVALID_HANDLE_VALUE); overload; virtual;


        (*
        ZwCreateToken(
           TokenHandle: PHANDLE;
           DesiredAccess: ACCESS_MASK;
           ObjectAttributes: POBJECT_ATTRIBUTES;
           Type_: TOKEN_TYPE;
           AuthenticationId: PLUID;
           ExpirationTime: PLARGE_INTEGER;
           User: PTOKEN_USER;
           Groups: PTOKEN_GROUPS;
           Privileges: PTOKEN_PRIVILEGES;
           Owner: PTOKEN_OWNER;
           PrimaryGroup: PTOKEN_PRIMARY_GROUP;
           DefaultDacl: PTOKEN_DEFAULT_DACL;
           Source: PTOKEN_SOURCE):

        *)
    constructor CreateNewToken(
      const aDesiredAccess: TJwAccessMask;
      const anObjectAttributes: TObjectAttributes;
      const anAuthenticationId: TLUID;
      const anExpirationTime: int64; anUser: TJwSecurityId;
      aGroups: TJwSecurityIdList; aPrivileges: TJwPrivilegeSet;
      anOwner: TJwSecurityId; aPrimaryGroup: TJwSecurityId;
      aDefaultDACL: TJwDAccessControlList;
      aTokenSource: TTokenSource); virtual;


    class function Create_OBJECT_ATTRIBUTES(
      const aRootDirectory: THandle;
      const anObjectName: TJwString;
      const anAttributes: Cardinal;
      const aSecurityDescriptor: TJwSecurityDescriptor;
      const anImpersonationLevel: TSecurityImpersonationLevel;
      const aContextTrackingMode: SECURITY_CONTEXT_TRACKING_MODE;
      const anEffectiveOnly: boolean): TObjectAttributes; virtual;

    class procedure Free_OBJECT_ATTRIBUTES(
      anObjectAttributes: TObjectAttributes); virtual;


        {@Name creates a new restricted token of an existing token.
         see http://msdn2.microsoft.com/en-us/library/aa446583.aspx for more information.

         You must set aTokenAccessMask to the token access type of aTokenHandle.

         @param(aTokenHandle contains the token handle to be restricted in a new token)
         @param(aTokenAccessMask contains the access mask of aTokenHandle)
         @param(aFlags contains special flags:
         @unorderedlist(
          @item( DISABLE_MAX_PRIVILEGE
                0x1   Disables all privileges in the new token. If this value is specified, the DeletePrivilegeCount and PrivilegesToDelete parameters are ignored, and the restricted token does not have the SeChangeNotifyPrivilege privilege.)
          @item( SANDBOX_INERT
                0x2   Stores this flag in the token. A token may be queried for existence of this flag using GetTokenInformation.)
          @item( LUA_TOKEN
                0x4   The new token is a LUA token.)
          @item( WRITE_RESTRICTED
                0x8   The new token contains restricting SIDs that are considered only when evaluating write access.)
          ))
         @param(aSidsToDisable contains a list of SIDs that are disabled to the new token. Can be nil.)
         @param(aPrivilegesToDelete contains a list of privileges to be removed from the token. Can be nil.)
         @param(aRestrictedSids contains a list of SIDs to be restricted. Can be nil.)
         @raises(EJwsclSecurityException will be raised if the winapi call failed)

        }
    constructor CreateRestrictedToken(aTokenHandle: TJwTokenHandle;
      const aTokenAccessMask: TJwTokenAccessMask;
      aFlags: Cardinal; aSidsToDisable: TJwSecurityIdList;
      aPrivilegesToDelete: TJwPrivilegeSet;
      aRestrictedSids: TJwSecurityIdList); overload; virtual;

    {TBD}
    constructor CreateLogonUser(sUsername: TJwString;
    // string that specifies the user name
      sDomain: TJwString;  // string that specifies the domain or server
      sPassword: TJwString;  // string that specifies the password
      dwLogonType,  // specifies the type of logon operation
      dwLogonProvider: Cardinal  // specifies the logon provider
      ); overload; virtual;

    //constructor CreateLogonUser(.....
    //constructor CreateLSALogonUser(....
  public
        {@Name converts the token into an impersonated token. It does nothing if the token is already impersonated.
         The token instance must be opened with TOKEN_DUPLICATE access right.

         Actually you can impersonate a shared token. The impersonated token will be copied into the instance property TokenHandle.
         The old handle will not be closed if Share is set to true. You must save the old value to close it by yourself.

         Because the old handle is discarded you must call these functions again :
           GetTokenPrivileges

        @param(impLevel receives the impersonation Level. Use one of these SecurityAnonymous, SecurityIdentification, SecurityImpersonation, SecurityDelegation. )
        @param(aDesiredAccess Receives the desired access for this token. The access types can be get from the following list. Access flags must be concatenated with or operator.
        If you want to use DuplicateToken or creating an impersonated token (by ConvertToImpersonatedToken) you must specify TOKEN_DUPLICATE.

        See @link(CreateTokenByProcess CreateTokenByProcess) for a list of access rights.)

        @raises(EJwsclSharedTokenException IS NOT USED! .. will be raised if @link(Shared Shared) is set to true. This is because the old token handle will be closed and other referes to it are invalid.)
        @raises(EJwsclTokenImpersonationException will be raised if the call to DuplicateTokenEx failed.)
        @raises(EJwsclAccessTypeException will be raised if the token does not have the access TOKEN_READ and TOKEN_DUPLICATE)

        }
    procedure ConvertToImpersonatedToken(
      impLevel: SECURITY_IMPERSONATION_LEVEL;
      const aDesiredAccess: TJwAccessMask); virtual;

        {@Name converts the token into a primary (or process) token. It does nothing if the token is already a primary token.
         The token instance must be opened with TOKEN_DUPLICATE access right.

         Actually you can impersonate a shared token. The primary token will be copied into the instance property TokenHandle.
         The old handle will not be closed if Share is set to true. You must save the old value to close it by yourself.

         Because the old handle is discarded you must call these functions again :
           GetTokenPrivileges



        @param(aDesiredAccess Receives the desired access for this token. The access types can be get from the following list. Access flags must be concatenated with or operator.
        If you want to use DuplicateToken or creating an primary token (by ConvertToPrimaryToken) you must specify TOKEN_DUPLICATE.

        See @link(CreateTokenByProcess CreateTokenByProcess) for a list of access rights.)

        @raises(EJwsclTokenPrimaryException will be raised if the call to DuplicateTokenEx failed.)
        @raises(EJwsclAccessTypeException will be raised if the token does not have the access TOKEN_READ and TOKEN_DUPLICATE)

        }
    procedure ConvertToPrimaryToken(
      const aDesiredAccess: TJwAccessMask); virtual;

        {@Name creates an instance of TJwPrivilegeSet with all defined privileges of this token.
         The privilege set is a readonly copy.
         You should prefer this function if you want to make more changes.

         Every time you call this function, the resulted instance TJwPrivilegeSet will be saved into an internal list,
          that is cleared if the token instance is freed.
         Be aware that your pointers to these privileges instances are invalid afterwards.
         However you can free the result by yourself. In that case the privileges instance will be removed from the internal list.
        }
    function GetTokenPrivileges: TJwPrivilegeSet;

    function GetTokenPrivilegesEx: PTOKEN_PRIVILEGES;


    {@Name duplicates the instance AND token}
    function CreateDuplicateToken(AccessMask: TJwAccessMask;
      Security: PSECURITY_ATTRIBUTES): TJwSecurityToken;

    {@Name creates an restricted token of the instance.}
    function CreateRestrictedToken(const aTokenAccessMask: TJwTokenHandle;
      aFlags: Cardinal; aSidsToDisable: TJwSecurityIdList;
      aPrivilegesToDelete: TJwPrivilegeSet;
      aRestrictedSids: TJwSecurityIdList): TJwSecurityToken; overload;
      virtual;


    function CheckTokenMembership(aSidToCheck: TJwSecurityId): boolean;

        {@Name compares the token instance with a second one.
         This function loads a function from ntdll.dll dynamically. This function is only available on XP or better
         @return(@Name returns true if both tokens do have the same accesscheck; otherwise false. It returns false if aToken is nil.)
         
         @raises(EJwsclAccessTypeException will be raised if the token or aToken does not have access type TOKEN_QUERY)
         }
    function IsEqual(aToken: TJwSecurityToken): boolean;

        {@Name sets the thread token.
         @param(Thread contains the thread handle. If Thread is zero the calling thread will be used.)

        @raises(EJwsclSecurityException will be raised if the token could not be attached to the thread)
        @raises(EJwsclSecurityException will be raised if a winapi function failed)
        }
    procedure SetThreadToken(const Thread: TJwThreadHandle);

        {
        @Name removes the token from the thread.
        @param(Thread contains the thread handle. If Thread is zero the calling thread will be used.)
        @raises(EJwsclSecurityException will be raised if a winapi function failed)
        }
    class procedure RemoveThreadToken(const Thread: TJwThreadHandle);

        {The @Name function lets the calling thread impersonate the security context of a logged-on user. The user is represented by a token handle.
        @raises(EJwsclAccessTypeException will be raised if the token is an impersonation token and does not have access type TOKEN_QUERY and TOKEN_IMPERSONATE)
        @raises(EJwsclAccessTypeException will be raised if the token is a primary token and does not have access type TOKEN_QUERY and TOKEN_DUPLICATE)
        @raises(EJwsclSecurityException will be raised if a winapi function failed)
        }
    procedure ImpersonateLoggedOnUser;

        {@Name is a simulation of WinAPI PrivilegeCheck (http://msdn2.microsoft.com/en-us/library/aa379304.aspx)
         @Name checks for enabled privleges of the token.
         If RequiresAllPrivs is false @Name returns true if one privilege provided in aRequiredPrivileges is enabled in the token
          If no privilege from aRequiredPrivileges is enabled in the token the function returns false.
         If RequiresAllPrivs is true @Name returns true if all privileges from aRequiredPrivileges are enabled in the token; otherwise false.

         Every privilege that was used for a privilege check will have the property Privilege_Used_For_Access set to true.

         @param(aRequiredPrivileges provides a list of priveleges that are compared with the token )
         @return(see description)
         }
    function PrivilegeCheck(aRequiredPrivileges: TJwPrivilegeSet;
      RequiresAllPrivs: boolean): boolean; overload;

        {@Name works like @link(PrivilegeCheck). However this function uses the winapi call PrivilegeCheck.
         The property Privilege_Used_For_Access in TJwPrivilege is not supported. 
         }
    function PrivilegeCheckEx(aRequiredPrivileges: TJwPrivilegeSet;
      RequiresAllPrivs: boolean): boolean; overload;

        {@Name is a simulation of WinAPI PrivilegeCheck (http://msdn2.microsoft.com/en-us/library/aa379304.aspx)
         @Name checks for enabled privleges of the token.
         If RequiresAllPrivs is false @Name returns true if one privilege provided in aRequiredPrivileges is enabled in the token
          If no privilege from aRequiredPrivileges is enabled in the token the function returns false.
         If RequiresAllPrivs is true @Name returns true if all privileges from aRequiredPrivileges are enabled in the token; otherwise false.

         @param(ClientToken is a token that is used to check the privileges)
         @param(aRequiredPrivileges provides a list of priveleges that are compared with the token )
         @return(see description)
         
        }
    class function PrivilegeCheck(ClientToken: TJwSecurityToken;
      aRequiredPrivileges: TJwPrivilegeSet;
      RequiresAllPrivs: boolean): boolean; overload;

    {@Name copies a LUID and returns it}
    class function CopyLUID(const originalLUID: TLUID): TLUID;

        {@Name gets token information in a class called @Link(TJwSecurityTokenStatistics).
         The programmer must free the class TJwSecurityTokenStatistics}
    function GetTokenStatistics: TJwSecurityTokenStatistics;


    //@Name is not implemented
    procedure FreeObjectMemory(var anObject: TObject);
  public
    //instance function related to token context

        {@Name function generates an audit message in the security event log.
         For a detailed information see MSDN : http://msdn2.microsoft.com/en-gb/library/aa379305.aspx

         If you want to enable audit functions the calling process (not thread token!) needs the SeAuditPrivilege privilege.
         Per default only services have this privilege. However it can be enabled in group policy editor : "gpedit.msc" manager (under xp)
           Computer configuration -> Windows settings -> security settings -> local policies -> audit policy
            enable (success/failure) policy : audit privilege
          The parameter AccessGranted is linked with the type of policy - success or failiure.
          (http://www.nemesisblue.info/images%5Cgpedit1.gif)

         The audit event can be seen in the event viewer in security leaf.

         @param(ClientToken is the token to be used in audit log. )

         @raises(EJwsclPrivilegeNotFoundException will be raised if the process token does not have the privilege : SE_AUDIT_NAME)
         @raises(EJwsclWinCallFailedException will be raised if the winapi call to PrivilegedServiceAuditAlarm failed.)
         @raises(EJwsclInvalidTokenHandle will be raised if the parameter ClientToken is nil)
         }
    class procedure PrivilegedServiceAuditAlarm(
      SubsystemName, ServiceName: TJwString;
      ClientToken: TJwSecurityToken; Privileges: TJwPrivilegeSet;
      AccessGranted: boolean);

    //see equivalent msdn function for more information
    class procedure ImpersonateAnonymousToken(
      const Thread: TJwThreadHandle);
      virtual;
    //see equivalent msdn function for more information
    class procedure ImpersonateSelf(
      const anImpersonationLevel: SECURITY_IMPERSONATION_LEVEL); virtual;
    //see equivalent msdn function for more information
    class procedure RevertToSelf; virtual;
    //see equivalent msdn function for more information
    class procedure ImpersonateNamedPipeClient(hNamedPipe: THandle);  virtual;

        {@Name returns whether the current thread has a token or not.
        @return Returns true if the thread has a token; otherwise false.}
    class function HasThreadAToken(): boolean; virtual;
        {@Name returns the token of the current thread or nil if none exists.
         See CreateTokenByThread for more information.
         @return Returns the thread token or nil if none exists.
          The caller must free the token instance.
         @raises EJwsclOpenThreadTokenException will be raised if an error occurs.}
    class function GetThreadToken(const aDesiredAccess: TJwAccessMask;
      const anOpenAsSelf: boolean): TJwSecurityToken; virtual;

    {@Name gets the security descriptor.
     The caller is responsible to free the returned instance.
     See @link(TJwSecureGeneralObject.GetSecurityInfo) for more information
     about exceptions.

     @param(SecurityFlags defines which component of the security descriptor
      is retrieved.)
     @return(Returns a new security descriptor instance. )
    }
    function GetSecurityDescriptor(const SecurityFlags :
      TJwSecurityInformationFlagSet) : TJwSecurityDescriptor; virtual;

    {@Name sets the security descriptor.
     See @link(TJwSecureGeneralObject.SetSecurityInfo) for more information
     about exceptions.
     Warning: Changing the security descriptor's security information can
      lead to security holes. 

     @param(SecurityFlags defines which component of the security descriptor
      is changed. )
    }
    procedure SetSecurityDescriptor(const SecurityFlags :
      TJwSecurityInformationFlagSet;
      const SecurityDescriptor : TJwSecurityDescriptor); virtual;
  public
    {TokenHandle contains a handle to the opened token. It can be zero.}
    property TokenHandle: TJwTokenHandle Read fTokenHandle;

        {Shared is a user defined boolean state that defines whether the token handle is used out of this instance scope.
         If true some methods do not work because they closes the handle which would lead to unpredictable results.}
    property Shared: boolean Read fShared Write fShared;

        {TokenTypes gets the token type. The result can be one of these values :
         TokenPrimary, TokenImpersonation}
    property TokenType: TOKEN_TYPE Read GetTokenType;

    {@Name  contains the access flags that was specified when the token was created or opened}
    property AccessMask: TJwAccessMask Read fAccessMask;

        {@Name returns the impersonation level of an impersonated token.
         If the token is a primary token, the result is always DEFAULT_IMPERSONATION_LEVEL}
    property ImpersonationLevel: TSecurityImpersonationLevel
      Read GetImpersonationLevel;

    {@Name returns true if the token was created by CreateRestrictedToken (or by the equivalent winapi function); otherwise false}
    property IsRestricted: boolean Read GetIsRestricted;

    {@Name checks if a user is listed in the tokens user list}
    property IsTokenMemberShip[aSID: TJwSecurityId]: boolean
      Read CheckTokenMembership;

        {@Name contains the user that holds the token.
         A read call creates a new TJwSecurityId that must be destroyed!}
    property TokenUser: TJwSecurityId Read GetTokenUser;

    {@Name contains the groups which the token belongs to.
     The caller is responsible to free the returned security id list.
     Do not use members of TokenGroups directly without using a variable.
     Every call of members directly will result into a new list!

     The token handle must be valid otherwise
      EJwsclInvalidTokenHandle will be raised.

     Get:
      see @link(GetTokenInformation) for more information about exceptions.
     Set:
      EJwsclNILParameterException is raised if the given list is nil.
      EJwsclWinCallFailedException is raised if a call to AdjustTokenGroups failed.

     }
    property TokenGroups: TJwSecurityIdList
      Read GetTokenGroups Write SetTokenGroups;

    {@Name sets or gets the token groups attributes.
     Through these attributes a token group can be activated to let
     AccessCheck use it in its checking.
      This property raises EListError if the Index could not be found.
      For further information and exceptions see @link(TokenGroups).
    }
    property TokenGroupsAttributes[Index : Integer] : TJwSidAttributeSet
       read GetTokenGroupsAttributesInt write SetTokenGroupsAttributesInt;

    {@Name sets or gets the token groups attributes.
     Through these attributes a token group can be activated to let
     AccessCheck use it in its checking.
     This property raises EListError if the Sid could not be found.
     For further information and exceptions see @link(TokenGroups).
    }
    property TokenGroupsAttributesBySid[Sid : TJwSecurityId] : TJwSidAttributeSet
       read GetTokenGroupsAttributesSid write SetTokenGroupsAttributesSid;

        {@Name contains all users that have restricted rights on the token.
         The user must free the list}
    property TokenRestrictedSids: TJwSecurityIdList
      Read GetTokenRestrictedSids;

        {@Name sets or gets the defaul discretionary access control list of the token.
         The value is dynamic returned. It always returns the actual token state and is not saved.
         So after a reading call the returned object must be freed!

         }
    property TokenDefaultDacl: TJwDAccessControlList
      Read GetTokenDefaultDacl Write SetTokenDefaultDacl; //TOKEN_ADJUST_DEFAULT

        {@Name sets or gets the token origin.
         The value can only be set if it has not been already set.
         The process or thread needs the SE_TCB_NAME privilege to set a value.
        }
    property TokenOrigin: TLuid Read GetTokenOrigin Write SetTokenOrigin;
    //SE_TCB_NAME

        {@Name sets or gets the token owner.
         To set the value the token needs TOKEN_ADJUST_DEFAULT privilege.
         }
    property TokenOwner: TJwSecurityId
      Read GetTokenOwner Write SetTokenOwner; //TOKEN_ADJUST_DEFAULT

        {@Name sets or gets the primary group.
         To set the value the token needs TOKEN_ADJUST_DEFAULT privilege}
    property PrimaryGroup: TJwSecurityId
      Read GetPrimaryGroup Write SetPrimaryGroup; //TOKEN_ADJUST_DEFAULT

        {@Name sets or gets the Session ID of the token.
         To set the value the token needs SE_TCB_NAME privilege.

         A write call on a Windows 2000 is ignored!
         A write call on higher systems neeeds the SE_TCB_NAME privilege.

         See
         http://msdn2.microsoft.com/en-us/library/aa379591.aspx
         for more information.

         }
    property TokenSessionId: Cardinal
      Read GetTokenSessionId Write SetTokenSessionId;

        {@Name sets or gets a privilege of the token.
         If you plan to use this property extensivly  try GetTokenPrivileges instead.

         EJwsclPrivilegeNotFoundException will be raised if you try to set a privilege that is unknown or not available in the token.
           If you try to read a privilege that could not be found in the privilege list the return value will be false.

         }
    property PrivilegeEnabled[Name: string]: boolean
      Read GetPrivilegeEnabled Write SetPrivilegeEnabled;

        {@Name checks whether a defined privilege is available in the token.
         It returns true if the privilege was found; otherwise false.
        }
    property PrivilegeAvailable[Name: string]: boolean
      Read GetPrivilegeAvailable;

        {@Name returns the elavation status of the process on a Windows Vista system.
         If the system is not a supported the exception EJwsclUnsupportedWindowsVersionException will be raised
         Actually only windows vista is supported.

         }
    property RunElevation: Cardinal Read GetRunElevation;

        {@Name returns the elavation type of the process on a Windows Vista system.
         If the system is not a supported the exception EJwsclUnsupportedWindowsVersionException will be raised
         Actually only windows vista is supported.
         }
    property ElevationType: TTokenElevationType Read GetElevationType;

    {@Name returns the integrity level of the token.
     This function only works in Windows Vista and newer.
     The caller is responsible for freeing the resulting TJwSecurityIdList.
    }
    property TokenIntegrityLevel : TJwSecurityIdList read GetIntegrityLevel;

    {@Name returns the linked token of this token.
     In vista every token can have a second token that has more or less
     rights. The UAC uses this token to assign it to a new process with elevated
     rights.
     However this token is useless for non privileged tokens because SetThreadToken
     and other functions which get this token checks whether the user can use this
     token or not. 

    This function only works in Windows Vista and newer.
     The caller is responsible for freeing the resulting TJwSecurityToken}
    property LinkedToken : TJwSecurityToken read GetLinkedToken;

        {@Name returns the status of allowance of virtualization of the process on a Windows Vista system.
         If the system is not a supported the exception EJwsclUnsupportedWindowsVersionException will be raised
         Actually only windows vista is supported.
         }
    property VirtualizationAllowed: boolean
      Read GetVirtualizationAllowed;

        {@Name returns the status of status of virtualization is whether on or off of the process on a Windows Vista system.
         If the system is not a supported the exception EJwsclUnsupportedWindowsVersionException will be raised
         Actually only windows vista is supported.
         }
    property VirtualizationEnabled: boolean
      Read GetVirtualizationEnabled;

    {@Name returns the mandatory policy of the token.
     This property can have one the following values (from MSDN):
      @unorderedlist(
        @item(TOKEN_MANDATORY_POLICY_OFF No mandatory integrity policy is enforced for the token.)
        @item(TOKEN_MANDATORY_POLICY_NO_WRITE_UP A process associated with the token cannot write to objects that have a greater mandatory integrity level.)
        @item(TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN A process created with the token has an integrity level that is the lesser of the parent-process integrity level and the executable-file integrity level.)
        @item(TOKEN_MANDATORY_POLICY_VALID_MASK A combination of TOKEN_MANDATORY_POLICY_NO_WRITE_UP and TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN)
      )
    }

    property MandatoryPolicy : DWORD read GetMandatoryPolicy;

  end;

     {@Name is a class that holds information about a token.
      For a detailed description see msdn : http://msdn2.microsoft.com/en-us/library/aa379632.aspx
      }
  TJwSecurityTokenStatistics = class(TObject)
  protected
    fTokenId:          TLUID;
    fAuthenticationId: LUID;
    fExpirationTime:   LARGE_INTEGER;
    fTOKEN_TYPE:       TTokenType;
    fSECURITY_IMPERSONATION_LEVEL: TSecurityImpersonationLevel;
    fDynamicCharged:   Cardinal;
    fDynamicAvailable: Cardinal;
    fGroupCount:       Cardinal;
    fPrivilegeCount:   Cardinal;
    fModifiedId:       TLUID;
  public
       {@Name creates a new token statistic class.
        @param(stats contains the token statistic structure provided by GetTokenInformation. )}
    constructor Create(stats: TTokenStatistics);

    function GetText: TJwString; virtual;
       {@Name contains the luid of the token.
        See also : http://msdn2.microsoft.com/en-us/library/aa379632.aspx}
    property TokenId: TLUID Read fTokenId;

       {@Name contains the authentication id
        See also : http://msdn2.microsoft.com/en-us/library/aa379632.aspx}
    property AuthenticationId: LUID Read fAuthenticationId;
    {For detailed information on @Name see : http://msdn2.microsoft.com/en-us/library/aa379632.aspx}
    property ExpirationTime: LARGE_INTEGER Read fExpirationTime;
    {For detailed information on @Name see : http://msdn2.microsoft.com/en-us/library/aa379632.aspx}
    property TOKEN_TYPE: TTokenType Read fTOKEN_TYPE;
    {For detailed information on @Name see : http://msdn2.microsoft.com/en-us/library/aa379632.aspx}
    property SECURITY_IMPERSONATION_LEVEL: TSecurityImpersonationLevel
      Read fSECURITY_IMPERSONATION_LEVEL;
    {For detailed information on @Name see : http://msdn2.microsoft.com/en-us/library/aa379632.aspx}
    property DynamicCharged: Cardinal Read fDynamicCharged;
    {For detailed information on @Name see : http://msdn2.microsoft.com/en-us/library/aa379632.aspx}
    property DynamicAvailable: Cardinal Read fDynamicAvailable;
    {For detailed information on @Name see : http://msdn2.microsoft.com/en-us/library/aa379632.aspx}
    property GroupCount: Cardinal Read fGroupCount;
    {For detailed information on @Name see : http://msdn2.microsoft.com/en-us/library/aa379632.aspx}
    property PrivilegeCount: Cardinal Read fPrivilegeCount;
    {For detailed information on @Name see : http://msdn2.microsoft.com/en-us/library/aa379632.aspx}
    property ModifiedId: TLUID Read fModifiedId;
    {For detailed information on @Name see : http://msdn2.microsoft.com/en-us/library/aa379632.aspx}
  end;


  {@Name contains information about a token privilege}
  TJwPrivilege = class(TObject)
  private
    fAttributes: Cardinal;
    fLUID:       LUID;


    fName, fDisplayName: TJwString;

    fLanguageID: Cardinal;

    fOwner: TJwPrivilegeSet;
    fPrivilege_Used_For_Access: boolean;

    fPrivilege_Enabled_By_Default: boolean;
  protected
       {@Name retrieves the enable status of a privilege.
        @raises EJwsclAdjustPrivilegeException will be raised if :
            @unorderedlist(
             @item A call to AdjustTokenPrivileges failed, because the privilege does not exist or was refused to change.
             @item(A second call to AdjustTokenPrivileges failed, because the original state could not be restored. The second call will only be
              made in case of a changed privilege.)
             )
        @raises EJwsclNotImplementedException If the privilete instance does not belong to a token.
        @raises EJwsclAccessTypeException If the token does not hold TOKEN_QUERY and TOKEN_ADJUST_PRIVILEGES access values.
       }
    function GetEnabled: boolean; virtual;

       {
       @Name sets the enable status of a privilege.
       If the privilege had originally the attribute flag SE_PRIVILEGE_ENABLED_BY_DEFAULT set,
       it is also set.
        @raises EJwsclAdjustPrivilegeException will be raised if call to AdjustTokenPrivileges failed, because the privilege does not exist or was refused to change.
        @raises EJwsclNotImplementedException If the privilete instance does not belong to a token.
        @raises EJwsclAccessTypeException If the token does not hold TOKEN_QUERY and TOKEN_ADJUST_PRIVILEGES access values.
       }
    procedure SetEnabled(const en: boolean); virtual;
  public
       {@Name creates a new instance with information of a privilege.
        @raises(EJwsclInvalidOwnerException will be raised if anOwner is nil.)
        }
    constructor Create(anOwner: TJwPrivilegeSet;
      aLUID_AND_ATTRIBUTES: LUID_AND_ATTRIBUTES);

       {@Name convertes a set of attributes into a human readable string

       @param(SE_Attributes receives the privilege attributes to be converted)
       @return(The result ist a combination (comma seperated) of these strings:
               (none)
               SE_PRIVILEGE_ENABLED_BY_DEFAULT
               SE_PRIVILEGE_ENABLED
               SE_PRIVILEGE_USED_FOR_ACCESS
               (unknown attributes))
       }
    class function PrivilegeAttributeToText(PrivilegeAttributes: Cardinal;
          HumanReadable : Boolean = false): TJwString;
      virtual;

       {@Name converts a LUID (locally unique ID) into a string.
        Output format: 
        'hi: 0x<hipart>, lo: 0x<lopart> (0x<(hipart shl 4) or (lopart)>)';

        @param(aLUID receives the LUID of the privilege)
       }
    class function LUIDtoText(aLUID: LUID): TJwString; virtual;

       {@Name creates a luid structure out of a privilege name on a system environment.
        @param Name The name parameter defines the privilege name to be converted into a luid.
        @param SystemName The SystemName parameter specifies the system name where to search for. Leave empty to use the local system.
        @return @Name returns a luid with the requested privilege information or the value LUID_INVALID if no exception occured but the luid value not set.

        See http://msdn2.microsoft.com/en-us/library/aa379180.aspx for more information.
       }
    class function TextToLUID(const Name: TJwString;
      const SystemName: TJwString = ''): TLuid;

    {@Name creates a luid and attributes structure from the given parameters.    }
    class function MakeLUID_AND_ATTRIBUTES(const LowPart: Cardinal;
      const HighPart: LONG;
      Attributes: Cardinal): TLuidAndAttributes; overload;

    {@Name creates a luid and attributes strcture from the given parameters.}
    class function MakeLUID_AND_ATTRIBUTES(const Luid: TLuid;
      Attributes: Cardinal): TLuidAndAttributes; overload;

    {@Name creates a luid strcture from the given parameter.}
    class function MakeLUID(const LowPart: Cardinal;
      const HighPart: LONG): TLuid;

       {@Name removes a privilege from the token.
        It cannot be readded.
        @param(aPrivilege contains the privilege to be removed)
        @raises(EJwsclAdjustPrivilegeException if the token could not be removed)
        @raises(EJwsclAdjustPrivilegeException if the token does not held the privilege) 
        }
    procedure RemoveIrrepealable; virtual;

       {@Name creates a string that contains a privilege in a human
        readable form :
         LUID       : <luid> #13#10
         Name       : <name> #13#10
         DisplayName : <descr> #13#10
         Attributes : <attributes> #13#10#13#10
        }
    function GetText: TJwString; virtual;

       {@name returns the whether the state SE_PRIVILEGE_ENABLED_BY_DEFAULT
        is set in the Attributes property (true) or not (false).
       }
    function IsEnabledByDefault: boolean; virtual;
  public
    {The owner token of this privilege set. }
    property Owner: TJwPrivilegeSet Read fOwner;

    //LUID contains the identifier of the privilege
    property LUID: LUID Read fLUID;

       {Attributes contains the status of the privilege.
        It is a bit combination of these values :

        SE_PRIVILEGE_ENABLED_BY_DEFAULT
        SE_PRIVILEGE_ENABLED
        SE_PRIVILEGE_USED_FOR_ACCESS
       }
    property Attributes: Cardinal Read fAttributes;

    //@Name contains the system name of the privilege (like SeTcbPrivilege)
    property Name: TJwString Read fName;

       {@Name contains a description of the privilege provided by the system
        The language can be retrieved in the property @link(LanguageID).
       }
    property DisplayName: TJwString Read fDisplayName;

    //@Name provides the language of the display name
    property LanguageID: Cardinal Read fLanguageID;

       {@Name enables or disables a privilege
        EJwsclNotImplementedException will be raised if the privilege is not assigned to a token.
        EJwsclAdjustPrivilegeException will be raised if the privilege attributes could not be set or retrieved.
        See also GetEnabled and SetEnabled for more information.
       }
    property Enabled: boolean Read GetEnabled Write SetEnabled;

       {Privilege_Used_For_Access will be set to true if the privilege was used
        by PrivilegeCheck function. However PrivilegeCheckEx does not support this value.
       }
    property Privilege_Used_For_Access: boolean
      Read fPrivilege_Used_For_Access Write fPrivilege_Used_For_Access;

  end;

     {@Name is a set of Privileges (defined by TJwPrivilege)
      There are two types of instances of TJwPrivilegeSet.
      1. TJwPrivilegeSet with an assigned token
      2. TJwPrivilegeSet without an assigned token.
      It is not possible to change from one to the other case.

      1. If the token is assigned, you can enable or disable privileges. However
       you cannot change privileges arbitrarily.
      2. If the privleges set is not assigned to a token, you can add or remove privileges arbitrarily.
       However you cannot enable or disable privileges.

      The description of these function shows what happens in one of these cases.

      }
  TJwPrivilegeSet = class(TObject)
  private
    fControl: Cardinal;
    fList:    TObjectList;
    fOwner:   TJwSecurityToken;

    fPPrivilegesList:    TList;
    fPPrivilegesSetList: TList;
  protected

    //see property @link(PrivByIdx)
    function GetPrivByIdx(Index: Cardinal): TJwPrivilege;
    //see property @link(PrivByName)
    function GetPrivByName(Index: string): TJwPrivilege;
    //see property @link(PrivByLUID)
    function GetPrivByLUID(Index: LUID): TJwPrivilege;

    function GetCount: Cardinal;
  public
       {@Name creates a new instance with a list of privileges.
        @param(Owner contains the owner token of this privilege set. It must not be nil!)
        @param(Privileges contains a set of privileges)
        @raises(EJwsclInvalidOwnerException will be raised if anOwner is nil.)}
    constructor Create(Owner: TJwSecurityToken;
      Privileges: jwaWindows.TPrivilegeSet); overload;
       {@Name creates a new instance with a list of privileges.
        @param(Owner contains the owner token of this privilege set. It must not be nil!)
        @param(PrivilegesPointer contains a set of privileges)
        @raises(EJwsclInvalidOwnerException will be raised if anOwner is nil.)}
    constructor Create(Owner: TJwSecurityToken;
      PrivilegesPointer: PTOKEN_PRIVILEGES); overload;

       {@Name creates a new instance with a list of privileges from a
         TJwPrivilegeSet instance.

        @param(Owner contains the owner token of this privilege set. It must not be nil!)
        @param(PrivilegesPointer contains a set of privileges)
        @raises(EJwsclInvalidOwnerException will be raised if anOwner is nil.)}
    constructor Create(Owner: TJwSecurityToken;
      PrivilegeObject: TJwPrivilegeSet); overload;

       {@Name creates a new user defined privilege list that
        cannot be used with a token.
        It is used to create a list of privileges that can be assigned a
        token function that needs it.}
    constructor Create; overload;

    destructor Destroy; override;

       {@Name creates a string that contains all privileges in a human
        readable form :
         LUID       : <luid> #13#10
         Name       : <name> #13#10
         DisplayName : <descr> #13#10
         Attributes : <attributes> #13#10#13#10
        }
    function GetText: TJwString;

       {@Name removes a privilege from the token.
        It cannot be readded.
        @param(aPrivilege contains the privilege to be removed)
        @raises(EJwsclAdjustPrivilegeException if the token could not be removed)
        @raises(EJwsclNotImplementedException if the set is not assigned to a token)
        }
    procedure RemoveIrrepealable(Privilege: TJwPrivilege); virtual;

       {@Name disables all privileges in this token.
        This is done in a faster way than iterate through the privilege list.
        You can undo this by setting Enabled state of a privilege.
        @raises(EJwsclNotImplementedException if the set is not assigned to a token)
        }
    procedure DisableAllPrivileges; virtual;

       {@Name creates an array of luid and attribute structure from the
         list of added privileges in this instance of TJwPrivilegeSet.
        The number of array elements is count.
        If count is zero the return value is nil.

        The structure must be freed by @link(Free_PLUID_AND_ATTRIBUTES).
        If not freed by the user the structure will be freed on destruction of the TJwPrivilegeSet instance.
        All created structures by @Name are freed in this way.
        }
    function Create_PLUID_AND_ATTRIBUTES: PLUID_AND_ATTRIBUTES; virtual;

       {@Name creates a set of privileges with an array of luids and attributes from the
         list of added privileges in this instance of TJwPrivilegeSet.
        The number of array elements is count.
        If count is zero the return value is an emtpy structure but not nil

        @return(Contains a set of privileges.)

        The structure must be freed by @link(Free_PPRIVILEGE_SET).
        If not freed by the user the structure will be freed on destruction of the TJwPrivilegeSet instance.
        All created structures by @Name are freed in this way.
        }
    function Create_PPRIVILEGE_SET: jwaWindows.PPRIVILEGE_SET; virtual;

       {@Name creates a set of privileges with an array of luids and attributes from the
         list of added privileges in this instance of TJwPrivilegeSet.
        The number of array elements is count.
        If count is zero the return value is an emtpy structure but not nil

        @return(Contains a set of privileges. )

        The structure must be freed by @link(Free_PTOKEN_PRIVILEGES).
        If not freed by the user the structure will be freed on destruction of the TJwPrivilegeSet instance.
        All created structures by @Name are freed in this way.
        }
    function Create_PTOKEN_PRIVILEGES: jwaWindows.PTOKEN_PRIVILEGES;
      virtual;

       {@Name frees an allocated luid and attribute structure by Create_PLUID_AND_ATTRIBUTES.
        Postcondition : privs will be nil.

        @param(Privileges contains the array pointing to the first element. )
        @raises(EJwsclSecurityException will be raised if privs was not created by Create_PLUID_AND_ATTRIBUTES of the same class instance!)
       }
    procedure Free_PLUID_AND_ATTRIBUTES(
      var Privileges: PLUID_AND_ATTRIBUTES); virtual;

       {@Name frees an allocated set of privileges structure by Create_PPRIVILEGE_SET.
        Postcondition : privs will be nil.

        @param(Privileges contains the array pointing to the first element. )
        @raises(EJwsclSecurityException will be raised if privs was not created by Create_PPRIVILEGE_SET of the same class instance!)
       }
    procedure Free_PPRIVILEGE_SET(
      var Privileges: jwaWindows.PPRIVILEGE_SET); virtual;

       {@Name frees an allocated luid and attribute structure by Create_PLUID_AND_ATTRIBUTES.
        Postcondition : privs will be nil.

        @param(Privileges contains the array pointing to the first element. )
        @raises(EJwsclSecurityException will be raised if privs was not created by Create_PLUID_AND_ATTRIBUTES of the same class instance!)
       }
    procedure Free_PTOKEN_PRIVILEGES(
      var Privileges: PTOKEN_PRIVILEGES); virtual;


       {@Name removes a privilege with the given index.
        If the privilege set is assigned to a token it simply calls RemoveIrrepealable
        If not the privilege will be removed from the list if it exists.

        @raises(EJwsclInvalidIndexPrivilegeException will be raised if the index does not exist)
        }
    procedure DeletePrivilege(Index: integer); overload; virtual;

       {@Name removes a privilege from the list.
        If the privilege set is assigned to a token it simply calls RemoveIrrepealable
        If not the privilege will be removed from the list if it exists.

        @raises(EJwsclPrivilegeNotFoundException will be raised if the privilege does not exist in list.)
        }
    procedure DeletePrivilege(Privilege: TJwPrivilege); overload; virtual;

       {@Name adds a privilege to the list if the privilege is not assigned to a token; otherwise
        EJwsclNotImplementedException will be raised.
        If the privilege already exists the exception EJwsclSecurityException will be raised.

        @param(LuidAttributes defines an luid structure with attributes. The attributes are ignored)

        @raises(EJwsclSecurityException will be raised if the privilege already exists)
        @raises(EJwsclNotImplementedException will be raised if the privilege set belongs to a token)
        @raises(EJwsclPrivilegeNotFoundException will be raised if the privilege was not found on the system)
       }
    function AddPrivilege(LuidAttributes: LUID_AND_ATTRIBUTES): integer;
      overload; virtual;

       {@Name adds a privilege to the list if the privilege is not assigned to a token; otherwise
        EJwsclNotImplementedException will be raised.
        If the privilege already exists the exception EJwsclSecurityException will be raised.

        @param(Luid defines a luid to be added)

        @raises(EJwsclSecurityException will be raised if the privilege already exists)
        @raises(EJwsclNotImplementedException will be raised if the privilege set belongs to a token)
        @raises(EJwsclPrivilegeNotFoundException will be raised if the privilege was not found on the system)
       }
    function AddPrivilege(Luid: TLuid): integer; overload; virtual;

       {@Name adds a privilege to the list if the privilege is not assigned to a token; otherwise
        EJwsclNotImplementedException will be raised.
        If the privilege already exists the exception EJwsclSecurityException will be raised.

        @param(HighValue contains the high value of the privilege luid to be added)
        @param(LowValue contains the low value of the privilege luid to be added)

        @raises(EJwsclSecurityException will be raised if the privilege already exists)
        @raises(EJwsclNotImplementedException will be raised if the privilege set belongs to a token)
        @raises(EJwsclPrivilegeNotFoundException will be raised if the privilege was not found on the system)
       }
    function AddPrivilege(HighValue, LowValue: Cardinal): integer;
      overload; virtual;

       {@Name adds a privilege to the list if the privilege is not assigned to a token; otherwise
        EJwsclNotImplementedException will be raised.
        If the privilege already exists the exception EJwsclSecurityException will be raised.

        @param(PrivName contains the privilege name to be added)

        @raises(EJwsclSecurityException will be raised if the privilege already exists)
        @raises(EJwsclNotImplementedException will be raised if the privilege set belongs to a token)
        @raises(EJwsclPrivilegeNotFoundException will be raised if the privilege was not found on the system)
       }
    function AddPrivilege(PrivName: TJwString): integer; overload; virtual;



  public
       {The owner token of this privilege set.
        If the privilege set belongs to a token, Owner is not nil.
        In this case the privilege in the list are assigned to a token.

        }
    property Owner: TJwSecurityToken Read fOwner;

       {@Name is only used if the privilege was created by Create with parameter
         (aPRIVILEGE_SET : PRIVILEGE_SET).
        Specifies a control flag related to the privileges.
        The PRIVILEGE_SET_ALL_NECESSARY control flag is currently defined.
        It indicates that all of the specified privileges must be held by the
        process requesting access. If this flag is not set, the presence
        of any privileges in the user's access token grants the access.

        http://msdn2.microsoft.com/en-us/library/aa379307.aspx
       }
    property Control: Cardinal Read fControl;

    //@Name contains the count of privileges
    property Count: Cardinal Read GetCount;

       {@Name returns a privilege by its index of list
        Be aware that an index can change if the set is updated.
        If the index is not between 0 and Count-1 the Exception
          EJwsclInvalidIndexPrivilegeException is raised.
        }
    property PrivByIdx[Index: Cardinal]: TJwPrivilege Read GetPrivByIdx;
       {@Name returns a privilege by its name.
        The string is compared case sensitive!
        You can use system constants from JwaWinNT (like SE_CREATE_TOKEN_NAME).
        If the given privilege was not found the result is nil.
        }
    property PrivByName[Index: string]: TJwPrivilege Read GetPrivByName;
       {
       @Name returns a privilege by its LUID (locally unique ID)
        If the given privilege was not found the result is nil.}
    property PrivByLUID[Index: LUID]: TJwPrivilege Read GetPrivByLUID;
  end;


var {@Name contains an handle to the process' heap.
     It is used to allocate memory on the heap.
     On unit initialization it is automatically set using GetProcessHeap
      (see http://msdn2.microsoft.com/en-us/library/aa366569.aspx).
     There is no need to change this value.
     Be aware that in future release this variable can become obsolete because the used
      memory functions are adapted or even replaced.
     }
  JwProcessHeap: Cardinal = 0;

type
  TJwPrivilegeQueryType = (pqt_Available, pqt_Enabled);
  TJwPrivilegeSetType   = (pst_Enable, pst_EnableIfAvail, pst_Disable);

{@Name checks if a given privilege is available or enabled in the actual process or thread.
@param Index gets the privilege name
@param query defines whether the given privilege should be checked for availability or is enable
@return Returns true if the privilege is available and enabled. If the privilege is not available or disabled the result is false.
}
function JwIsPrivilegeSet(const Index: string;
  const Query: TJwPrivilegeQueryType = pqt_Available): boolean;

{@Name en- or disables a given privilege.
@param Index gets the privilege name
@param query defines whether the privilege should be enabled or disabled. Define pst_EnableIfAvail if you dont want to raise an exception if
       the privlege does not exist.
@return Returns the previous state of the privilege, true if it was enabled, otherwise false. If the state is not available and query is pst_Disable
        the return value is false.
@raises EJwsclPrivilegeException will be raised if the privilege is not available and query is pst_Enable,
        otherwise the return value is false. If query is pst_EnableIfAvail the return is false, if the privilege could not be enabled.
        In this case no exception is raised.
}
function JwEnablePrivilege(const Index: string;
  const Query: TJwPrivilegeSetType): boolean;

{@Name returns a string filled with privilege names (of current token) and their states seperated by #13#10.
SE_XXXXX [enabled]
SE_XXXXX [disabled]
}
function JwGetPrivilegesText: TJwString;

{@Name returns true if the user is a member of the administrator group.
This does not mean that she has administrator rights (on Vista).
@return Returns true if the user is a member of the administrators group; otherwise
false.
}
function JwIsMemberOfAdministratorsGroup : Boolean;

{@Name checks if the user has administrative access to secured object.
This function checks if an access to a secured object, which only
users of the administration group have access, succeeds or fails.
The advantage of this function is that it also can be used with restricted
tokens, which are quite common since Windows XP and especially Vista.

@return Returns true if the user has administrative access; otherwise false.
}
function JwCheckAdministratorAccess : Boolean;





{$ENDIF SL_IMPLEMENTATION_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}
implementation

uses Math, JwsclKnownSid, JwsclMapping, JwsclSecureObjects;



{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_INTERFACE_SECTION}



function JwCheckAdministratorAccess : Boolean;
var
    SD : TJwSecurityDescriptor;
begin
  if not Assigned(JwAdministratorsSID) then
    JwInitWellKnownSIDs;

  SD := TJwSecurityDescriptor.Create;
  try
    SD.PrimaryGroup := JwNullSID;
    SD.Owner := JwAdministratorsSID;
    SD.OwnDACL := true;

    SD.DACL.Add(TJwDiscretionaryAccessControlEntryAllow.Create(nil,[],
      STANDARD_RIGHTS_ALL,JwAdministratorsSID,false));

    result := TJwSecureGeneralObject.AccessCheck(SD,nil,STANDARD_RIGHTS_ALL,
      TJwSecurityGenericMapping);
  finally
    FreeAndNil(SD);
  end;
end;

function JwIsMemberOfAdministratorsGroup : Boolean;
var Token : TJwSecurityToken;
begin
  Token := TJwSecurityToken.CreateTokenEffective(TOKEN_READ or TOKEN_DUPLICATE);
  try
    Token.ConvertToImpersonatedToken(SecurityImpersonation,MAXIMUM_ALLOWED);
    result := Token.CheckTokenMembership(JwAdministratorsSID)
  finally
    FreeAndNil(Token);
  end;
end;


function JwGetPrivilegesText: TJwString;
var
  t: TJwSecurityToken;
  s: TJwPrivilegeSet;
  i: integer;
  //[Hint] b : Boolean;
begin
  Result := '';

  t := TJwSecurityToken.CreateTokenEffective(TOKEN_DUPLICATE or
    TOKEN_READ or TOKEN_ADJUST_PRIVILEGES);
  try
    s := t.GetTokenPrivileges;


    for i := 0 to s.Count - 1 do
    begin
      if (s.GetPrivByIdx(i).Enabled) then
        Result := Result + #13#10 + s.GetPrivByIdx(i).Name + ' '+RsTokenEnabledText
      else
        Result := Result + #13#10 + s.GetPrivByIdx(i).Name + ' '+RsTokenDisabledText;
    end;

    s.Free;
  finally
    t.Free;
  end;
end;



function JwEnablePrivilege(const Index: string;
  const Query: TJwPrivilegeSetType): boolean;
var
  t: TJwSecurityToken;
begin
  if not JwIsPrivilegeSet(Index, pqt_Available) then
  begin
    if (query = pst_Enable) then
      raise EJwsclPrivilegeException.CreateFmtEx(
        RsTokenPrivilegeNotAvailable,
        'JwEnablePrivilege', RsTokenGlobalClassName, RsUNToken, 0, False, [Index])
    else
      Result := False;

    exit;
  end;

  Result := JwIsPrivilegeSet(Index, pqt_Enabled);

  t := TJwSecurityToken.CreateTokenEffective(TOKEN_DUPLICATE or
    TOKEN_READ or TOKEN_ADJUST_PRIVILEGES);
  try
    t.PrivilegeEnabled[Index] :=
      (query = pst_Enable) or (query = pst_EnableIfAvail);
  finally
    t.Free;
  end;
end;

function JwIsPrivilegeSet(const Index: string;
  const Query: TJwPrivilegeQueryType = pqt_Available): boolean;
var
  t: TJwSecurityToken;
begin
  t := TJwSecurityToken.CreateTokenEffective(TOKEN_DUPLICATE or
    TOKEN_READ or TOKEN_QUERY or TOKEN_WRITE);

  try
    Result := t.IsPrivilegeAvailable(Index);

    if Result and (query = pqt_Enabled) then
      Result := t.PrivilegeEnabled[Index];
  except
    Result := False;
  end;

  t.Free;
end;

{**************** TJwPrivilegeSet ******************}



constructor TJwPrivilegeSet.Create(Owner: TJwSecurityToken;
  PrivilegesPointer: PTOKEN_PRIVILEGES);
var
  i: integer;
begin
  //Todo: check second parameter for nil

  Self.Create;
  fOwner := Owner;
  fControl := 0;

  for i := 0 to PrivilegesPointer.PrivilegeCount - 1 do
  begin
    fList.Add(TJwPrivilege.Create(Self, PrivilegesPointer.Privileges[i]));
  end;
end;

constructor TJwPrivilegeSet.Create(Owner: TJwSecurityToken;
  PrivilegeObject: TJwPrivilegeSet);

var
  i: integer;
  aPrivileges: jwaWindows.PPRIVILEGE_SET;
begin
  //Todo: check second parameter for invalid data

  Self.Create;
  fOwner := Owner;

  fControl := 0;

  if Assigned(PrivilegeObject) then
  begin
    aPrivileges := PrivilegeObject.Create_PPRIVILEGE_SET;

    try
      for i := 0 to aPrivileges.PrivilegeCount - 1 do
      begin
        fList.Add(TJwPrivilege.Create(Self, aPrivileges.Privilege[i]));
      end;
    finally
      Free_PPRIVILEGE_SET(aPrivileges);
    end;
  end;
end;

constructor TJwPrivilegeSet.Create(Owner: TJwSecurityToken;
  Privileges: jwaWindows.TPrivilegeSet);

var
  i: integer;
begin
  //Todo: check second parameter for nil
  Self.Create;

  fOwner := Owner;

  fControl := Privileges.Control;

  for i := 0 to Privileges.PrivilegeCount - 1 do
  begin
    fList.Add(TJwPrivilege.Create(Self, Privileges.Privilege[i]));
  end;
end;

constructor TJwPrivilegeSet.Create;
begin
  fList  := TObjectList.Create(True);
  fPPrivilegesList := TList.Create;
  fPPrivilegesSetList := TList.Create;
  fOwner := nil;
end;

destructor TJwPrivilegeSet.Destroy;

  procedure ClearPrivilegeList;
  var
    i: integer;
    p: PLUID_AND_ATTRIBUTES;
  begin
    for i := fPPrivilegesList.Count - 1 downto 0 do
    begin
      p := PLUID_AND_ATTRIBUTES(fPPrivilegesList.Items[i]);
      Free_PLUID_AND_ATTRIBUTES(p);
    end;

    FreeAndNil(fPPrivilegesList);
  end;

  procedure ClearPrivilegeSetList;
  var
    i: integer;
    p: PPRIVILEGE_SET;
  begin
    for i := fPPrivilegesSetList.Count - 1 downto 0 do
    begin
      p := PPRIVILEGE_SET(fPPrivilegesSetList.Items[i]);
      Free_PPRIVILEGE_SET(p);
    end;

    FreeAndNil(fPPrivilegesSetList);
  end;

begin
  FreeAndNil(fList);
  ClearPrivilegeList;
  ClearPrivilegeSetList;

  if Assigned(Owner) then
    Owner.fPrivelegesList.Remove(Self);
  inherited;
end;


function TJwPrivilegeSet.GetText: TJwString;
var
  i: integer;
  priv: TJwPrivilege;
begin
  Result := '';
  for i := 0 to Self.Count - 1 do
  begin
    priv := TJwPrivilege(fList.Items[i]);
    Result := Result + priv.GetText + #13#10#13#10;
  end;
end;

function TJwPrivilegeSet.GetPrivByIdx(Index: Cardinal): TJwPrivilege;
begin
  if (Index >= Count) then
    raise EJwsclInvalidIndexPrivilegeException.CreateFmtEx(
      RsTokenInvalidPrivilegeIndex,
      'GetPrivByIdx', ClassName, RsUNToken,
      0, False, [Index, Count]);

  Result := TJwPrivilege(fList.Items[Index]);
end;

function TJwPrivilegeSet.GetPrivByName(Index: string): TJwPrivilege;
var
  i: integer;
  p: TJwPrivilege;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    p := TJwPrivilege(fList.Items[i]);
    if Index = p.Name then
    begin
      Result := p;
      exit;
    end;
  end;
end;



function TJwPrivilegeSet.GetPrivByLUID(Index: LUID): TJwPrivilege;
var
  i: integer;
  p: TJwPrivilege;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    p := TJwPrivilege(fList.Items[i]);
    if (Index.LowPart = p.LUID.LowPart) and
      (Index.HighPart = p.LUID.HighPart) then
    begin
      Result := p;
      exit;
    end;
  end;
end;

function TJwPrivilegeSet.GetCount: Cardinal;
begin
  if Assigned(fList) then
    Result := fList.Count
  else
    Result := 0;
end;

procedure TJwPrivilegeSet.RemoveIrrepealable(Privilege: TJwPrivilege);
var
  privs: TOKEN_PRIVILEGES;
  tcbPrevState: boolean;
begin
  if not Assigned(Owner) then
    raise EJwsclNotImplementedException.CreateFmtEx(
      RsTokenRemovePrivilegeDenied,
      'RemoveIrrepealable', ClassName, RsUNToken,
      0, False, []);

  Owner.CheckTokenHandle('RemoveIrrepealable');
  Owner.CheckTokenAccessType(TOKEN_QUERY +
    TOKEN_ADJUST_PRIVILEGES, 'TOKEN_QUERY,TOKEN_ADJUST_PRIVILEGES',
    'TJwPrivilegeSet.RemoveIrrepealable');

  if not Assigned(PrivByName[SE_TCB_NAME]) then
    raise EJwsclAdjustPrivilegeException.CreateFmtEx(
      RsTokenRemovePrivilegeDeniedByPrivilege,
      'RemoveIrrepealable', ClassName, RsUNToken,
      0, False, [Privilege.Name]);

  tcbPrevState := PrivByName[SE_TCB_NAME].Enabled;
  PrivByName[SE_TCB_NAME].Enabled := True;


  privs.PrivilegeCount := 1;
  privs.Privileges[0].Luid := Privilege.LUID;
  privs.Privileges[0].Attributes := SE_PRIVILEGE_REMOVED;


  SetLastError(0);
  if (not AdjustTokenPrivileges(Owner.TokenHandle, False, @privs, 0, nil, nil))
  then
    raise EJwsclAdjustPrivilegeException.CreateFmtEx(
      RsPrivilegeCallAdjustTokenFailed,
      'SetEnabled', ClassName, RsUNToken,
      0, True, [Privilege.Name]);

  //free memory and remove from privileges list
  fList.Remove(Privilege);

  PrivByName[SE_TCB_NAME].Enabled := tcbPrevState;
end;

procedure TJwPrivilegeSet.DisableAllPrivileges;
var
  privs: PTOKEN_PRIVILEGES;
  i: integer;
begin
  if not Assigned(Owner) then
    raise EJwsclNotImplementedException.CreateFmtEx(
      RsTokenRemovePrivilegeDenied,
      'RemoveIrrepealable', ClassName, RsUNToken,
      0, False, []);

  Owner.CheckTokenHandle('RemoveIrrepealable');
  Owner.CheckTokenAccessType(TOKEN_QUERY +
    TOKEN_ADJUST_PRIVILEGES, 'TOKEN_QUERY,TOKEN_ADJUST_PRIVILEGES',
    'TJwPrivilegeSet.RemoveIrrepealable');

  if (not AdjustTokenPrivileges(Owner.TokenHandle, True, nil, 0, nil, nil)) then
    raise EJwsclAdjustPrivilegeException.CreateFmtEx(
      RsWinCallFailed,
      'DisableAllPrivileges', ClassName, RsUNToken,
      0, True, ['AdjustToken']);

  fList.Clear;

  Owner.GetTokenInformation(Owner.TokenHandle, TokenPrivileges, Pointer(privs));

  for i := 0 to privs.PrivilegeCount - 1 do
  begin
    fList.Add(TJwPrivilege.Create(Self, privs.Privileges[i]));
  end;

  HeapFree(JwProcessHeap, 0, privs);
end;

function TJwPrivilegeSet.Create_PLUID_AND_ATTRIBUTES: PLUID_AND_ATTRIBUTES;
type
  TArrayLuids = array of LUID_AND_ATTRIBUTES;
var
  i: integer;
  p: ^TArrayLuids;
begin
  Result := nil;

  if Count = 0 then
    exit;

  Result := HeapAlloc(JwProcessHeap, HEAP_ZERO_MEMORY,
    sizeof(TLuidAndAttributes) * Count);

  fPPrivilegesList.Add(Result);

  p := @Result;

  for i := 0 to Count - 1 do
  begin
    p^[i].Luid := PrivByIdx[i].LUID;
    p^[i].Attributes := 0;
  end;
end;

procedure TJwPrivilegeSet.Free_PLUID_AND_ATTRIBUTES(
  var Privileges: PLUID_AND_ATTRIBUTES);
begin
  if Privileges = nil then
    exit;

  if fPPrivilegesList.IndexOf(Privileges) < 0 then
    raise EJwsclSecurityException.CreateFmtEx(
      RsTokenInvalidPrivilegePointer,
      'Free_PLUID_AND_ATTRIBUTES', ClassName, RsUNToken,
      0, False, []);

  fPPrivilegesList.Remove(Privileges);
  HeapFree(JwProcessHeap, 0, Privileges);

  Privileges := nil;
end;

procedure TJwPrivilegeSet.Free_PTOKEN_PRIVILEGES(
  var Privileges: PTOKEN_PRIVILEGES);
begin
  if Privileges = nil then
    exit;
  if fPPrivilegesList.IndexOf(Privileges) < 0 then
    raise EJwsclSecurityException.CreateFmtEx(
      RsTokenInvalidPrivilegePointer,
      'Free_PLUID_AND_ATTRIBUTES', ClassName, RsUNToken,
      0, False, []);

  fPPrivilegesList.Remove(Privileges);
  HeapFree(JwProcessHeap, 0, Privileges);

  Privileges := nil;
end;

function TJwPrivilegeSet.Create_PTOKEN_PRIVILEGES:
jwaWindows.PTOKEN_PRIVILEGES;
var
  size, i: integer;

begin
  size := sizeof(jwaWindows.PTOKEN_PRIVILEGES) +
    sizeof(TLuidAndAttributes) * Count;
  Result := HeapAlloc(JwProcessHeap, HEAP_ZERO_MEMORY, size);

  Result^.PrivilegeCount := Count;

  fPPrivilegesSetList.Add(Result);

  for i := 0 to Count - 1 do
  begin
    Result^.Privileges[i].Luid := PrivByIdx[i].LUID;
    Result^.Privileges[i].Attributes := 0;
    //SE_PRIVILEGE_ENABLED_BY_DEFAULT or SE_PRIVILEGE_ENABLED;
  end;
end;

function TJwPrivilegeSet.Create_PPRIVILEGE_SET: jwaWindows.PPRIVILEGE_SET;
var
  i: integer;
begin
  Result := HeapAlloc(JwProcessHeap, HEAP_ZERO_MEMORY,
    sizeof(jwaWindows.TPrivilegeSet) -
    sizeof(TLuidAndAttributes) +
    sizeof(TLuidAndAttributes) * Count);

  Result^.PrivilegeCount := Count;
  Result^.Control := 0;

  fPPrivilegesSetList.Add(Result);

  for i := 0 to Count - 1 do
  begin
    Result^.Privilege[i].Luid := PrivByIdx[i].LUID;
    Result^.Privilege[i].Attributes := 0;
  end;
end;

procedure TJwPrivilegeSet.Free_PPRIVILEGE_SET(
  var Privileges: jwaWindows.PPRIVILEGE_SET);
begin
  if Privileges = nil then
    exit;

  fPPrivilegesSetList.Remove(Privileges);

  HeapFree(JwProcessHeap, 0, Pointer(Privileges));

  Privileges := nil;
end;


procedure TJwPrivilegeSet.DeletePrivilege(Privilege: TJwPrivilege);
var
  i: integer;
begin
  if not Assigned(Privilege) then
    exit;

  i := fList.IndexOf(Privilege);
  if i >= 0 then
    DeletePrivilege(i)
  else
    raise EJwsclPrivilegeNotFoundException.CreateFmtEx(
      RsTokenPrivlegeNotInList,
      'DeletePrivilege', ClassName, RsUNToken, 0, True, []);
end;

procedure TJwPrivilegeSet.DeletePrivilege(Index: integer);
begin
  if Assigned(Owner) then
    RemoveIrrepealable(PrivByIdx[Index])
  else
  begin
    fList.Delete(Index);
  end;
end;

function TJwPrivilegeSet.AddPrivilege(PrivName: TJwString): integer;
var
  aLUID: Luid;
begin
  if not
  {$IFDEF UNICODE}LookupPrivilegeValueW{$ELSE}
    LookupPrivilegeValueA
{$ENDIF}
    ((''), TJwPChar(PrivName), aLUID) then
    raise EJwsclPrivilegeNotFoundException.CreateFmtEx(
      RsTokenCallLookUpPrivilegeValueFailed,
      'AddPrivilege', ClassName, RsUNToken, 0, True, [PrivName]);
  Result := AddPrivilege(aLUID);
end;

function TJwPrivilegeSet.AddPrivilege(HighValue, LowValue: Cardinal): integer;
var
  aLuid: TLuid;
begin
  aLuid.LowPart := HighValue;
  aLuid.HighPart := LowValue;
  Result := AddPrivilege(aLuid);
end;

function TJwPrivilegeSet.AddPrivilege(Luid: TLuid): integer;
var
  la: LUID_AND_ATTRIBUTES;
begin
  la.Luid := Luid;
  la.Attributes := 0;
  Result  := AddPrivilege(la);
end;


function TJwPrivilegeSet.AddPrivilege(LuidAttributes: LUID_AND_ATTRIBUTES)
: integer;
var
  i: integer;
begin
  if Assigned(Owner) then
    raise EJwsclNotImplementedException.CreateFmtEx(
      RsTokenPrivilegeAssignDenied,
      'AddPrivilege', ClassName, RsUNToken, 0, False, [])
  else
  begin
    for i := 0 to fList.Count - 1 do
    begin
      if (TJwPrivilege(fList.Items[i]).LUID.LowPart =
        LuidAttributes.Luid.LowPart) and
        (TJwPrivilege(fList.Items[i]).LUID.HighPart =
        LuidAttributes.Luid.HighPart) then
        raise EJwsclSecurityException.CreateFmtEx(
          RsTokenPrivilegeAlreadyInList, 'AddPrivilege', ClassName, RsUNToken, 0, False,
          [TJwPrivilege(fList.Items[i]).LUID.HighPart,
          TJwPrivilege(fList.Items[i]).LUID.LowPart]);
    end;


    Result := fList.Add(TJwPrivilege.Create(self, LuidAttributes));
  end;
end;



{**************** TJwPrivilege ******************}

constructor TJwPrivilege.Create(anOwner: TJwPrivilegeSet;
  aLUID_AND_ATTRIBUTES: LUID_AND_ATTRIBUTES);

  function GetName(aLUID: jwaWindows.LUID): TJwString;
  var
    len: Cardinal;
    sName: TJwPChar;

  begin
    if not Assigned(anOwner) then
      raise EJwsclInvalidOwnerException.CreateFmtEx(
       RsNilParameter,
        'Create', ClassName, RsUNToken, 0, False, ['Owner']);

    Result := '';
    len := 0;
    {$IFDEF UNICODE}LookupPrivilegeNameW{$ELSE}
    LookupPrivilegeNameA
{$ENDIF}
    ('', LUID, '', len);

    sName := HeapAlloc(JwProcessHeap, HEAP_ZERO_MEMORY, (len + 1) * sizeof(TJwChar));

    if (sName = nil) then
      raise EJwsclNotEnoughMemory.CreateFmtEx(
        RsTokenNotEnoughMemoryForPrivName,
        'Create', ClassName, RsUNToken, 0, False, []);

    if
{$IFDEF UNICODE}LookupPrivilegeNameW{$ELSE}
    LookupPrivilegeNameA
{$ENDIF}
      ('', LUID, sName, len) then
      Result := sName;

    HeapFree(JwProcessHeap, 0, sName);
  end;

  function GetDisplayName(aName: TJwString;
    out aLanguageID: Cardinal): TJwString;
  var
    len: Cardinal;
    sName: TJwPChar;

  begin
    Result := '';

    fOwner := anOwner;

    Len := 0;
    {$IFDEF UNICODE}LookupPrivilegeDisplayNameW{$ELSE}
    LookupPrivilegeDisplayNameA
{$ENDIF}
    ('', TJwPChar(aName), '', len, aLanguageID);

    sName := HeapAlloc(JwProcessHeap, HEAP_ZERO_MEMORY, (len + 1) * sizeof(TJwChar));

    if
{$IFDEF UNICODE}LookupPrivilegeDisplayNameW{$ELSE}
    LookupPrivilegeDisplayNameA
{$ENDIF}
      (nil, TJwPChar(aName), sName, len, aLanguageID) then
      Result := sName;

    HeapFree(JwProcessHeap, 0, sName);
  end;

begin
  fAttributes := aLUID_AND_ATTRIBUTES.Attributes;
  fLUID := aLUID_AND_ATTRIBUTES.Luid;

  fName := GetName(LUID);
  fPrivilege_Used_For_Access := False;
  fDisplayName := GetDisplayName(Self.Name, fLanguageID);

  fPrivilege_Enabled_By_Default := IsEnabledByDefault;
end;

class function TJwPrivilege.MakeLUID_AND_ATTRIBUTES(const LowPart: Cardinal;
  const HighPart: LONG; Attributes: Cardinal): TLuidAndAttributes;
begin
  Result.Luid := MakeLUID(LowPart, HighPart);
  Result.Attributes := Attributes;
end;

class function TJwPrivilege.MakeLUID_AND_ATTRIBUTES(const Luid: TLuid;
  Attributes: Cardinal): TLuidAndAttributes;
begin
  Result.Luid := Luid;
  Result.Attributes := Attributes;
end;


class function TJwPrivilege.MakeLUID(const LowPart: Cardinal;
  const HighPart: LONG): TLuid;
begin
  Result.LowPart  := LowPart;
  Result.HighPart := HighPart;
end;

class function TJwPrivilege.TextToLUID(const Name: TJwString;
  const SystemName: TJwString = ''): TLuid;
begin
  Result := LUID_INVALID;
  if not
{$IFDEF UNICODE}LookupPrivilegeValueW{$ELSE}
    LookupPrivilegeValueA
{$ENDIF}
    (TJwPChar(SystemName), TJwPChar(Name), Result) then

    raise EJwsclWinCallFailedException.CreateFmtEx(
      RsWinCallFailed,
      'TextToLUID', ClassName, RsUNToken, 0, True,
       ['LookupPrivilegeValue']);

end;

class function TJwPrivilege.LUIDtoText(aLUID: LUID): TJwString;
var
  i: int64;
  s: integer;
begin
  s := sizeof(aLUID.LowPart);
  i := aLUID.HighPart;
  i := i shl s;
  i := i or aLUID.LowPart;


  Result := JwFormatString(RsPrivilegeLuidText,
      [aLUID.HighPart, aLUID.LowPart,i]);
end;

class function TJwPrivilege.PrivilegeAttributeToText(PrivilegeAttributes: Cardinal;
  HumanReadable : Boolean = false)
: TJwString;
begin
  Result := '';
  if PrivilegeAttributes and SE_PRIVILEGE_ENABLED_BY_DEFAULT =
    SE_PRIVILEGE_ENABLED_BY_DEFAULT then
  begin
    if HumanReadable then
      Result := ','+RsPrivilegeEnabledByDefault
    else
      Result := ',SE_PRIVILEGE_ENABLED_BY_DEFAULT';
    PrivilegeAttributes := PrivilegeAttributes and not SE_PRIVILEGE_ENABLED_BY_DEFAULT;
  end;
  if PrivilegeAttributes and SE_PRIVILEGE_ENABLED = SE_PRIVILEGE_ENABLED then
  begin
    if HumanReadable then
      Result := ','+RsPrivilegeEnabled
    else
      Result := Result + ',SE_PRIVILEGE_ENABLED';
    PrivilegeAttributes := PrivilegeAttributes and not SE_PRIVILEGE_ENABLED;
  end;
  if PrivilegeAttributes and SE_PRIVILEGE_USED_FOR_ACCESS =
    SE_PRIVILEGE_USED_FOR_ACCESS then
  begin
    if HumanReadable then
      Result := ','+RsPrivilegeRemoved
    else
      Result := Result + ',SE_PRIVILEGE_USED_FOR_ACCESS';
    PrivilegeAttributes := PrivilegeAttributes and not SE_PRIVILEGE_USED_FOR_ACCESS;
  end;


  if PrivilegeAttributes > 0 then
    Result := result + ',' + JwFormatString(RsPrivilegeUnknown,[PrivilegeAttributes]);
    //Result := Result + ',(unknown attributes)';

  if Length(Result) > 0 then
    System.Delete(Result, 1, 1)
  else
    Result := RsPrivilegeNone;
end;

function TJwPrivilege.GetText: TJwString;
begin
  Result := JwFormatString(
    RsPrivilegeFormatText,
    [LUIDtoText(LUID),
     Name,
     DisplayName,
     PrivilegeAttributeToText(fAttributes)
     ]);

{  Result := 'LUID       : ' + LUIDtoText(LUID) + #13#10 +
    'Name       : ' + Name + #13#10 + 'DisplayName : ' +
    DisplayName + #13#10 + 'Attributes : ' +
    PrivilegeAttributeToText(fAttributes) + #13#10;
  }
end;

function TJwPrivilege.GetEnabled: boolean;
var
  privs, prevState: TOKEN_PRIVILEGES;

  preLen: Cardinal;
begin
  if not Assigned(Owner.Owner) then
    raise EJwsclNotImplementedException.CreateFmtEx(
      RsTokenNotAssignedPrivilege,
      'GetEnabled', ClassName, RsUNToken, 0, False, []);

  Owner.Owner.CheckTokenHandle('get TJwPrivilege.Enabled');
  Owner.Owner.CheckTokenAccessType(TOKEN_QUERY +
    TOKEN_ADJUST_PRIVILEGES, 'TOKEN_QUERY,TOKEN_ADJUST_PRIVILEGES',
    'TJwPrivilege.SetEnabled');


  privs.PrivilegeCount := 1;
  privs.Privileges[0].Luid := Self.LUID;
  privs.Privileges[0].Attributes := 0; //disable privilege

  (*
  To get privilege attributes, we first have to set them, get the previous state
  and reset it to the previous state
  *)

  Fillchar(prevState, sizeof(prevState), 0);
  preLen := 0;
  if (not AdjustTokenPrivileges(Owner.Owner.TokenHandle, False,
    @privs, sizeof(privs), @prevState, @preLen)) then
  begin
    raise EJwsclAdjustPrivilegeException.CreateFmtEx(
      RsPrivilegeCallAdjustTokenFailed,
      'GetEnabled', ClassName, RsUNToken,
      0, True, [Self.Name]);
  end;

  try
    //if prevState.PrivilegeCount is zero, no privilege was changed, and we do not need to restore it. So omit that:
    if (prevState.PrivilegeCount = 1) then
    begin
      if (not AdjustTokenPrivileges(Owner.Owner.TokenHandle,
        False, @prevState, preLen, nil, nil)) then
      begin
        raise EJwsclAdjustPrivilegeException.CreateFmtEx(
          RsPrivilegeCallAdjustTokenFailed1,
          'GetEnabled', ClassName, RsUNToken,
          0, True, [Self.Name]);
      end;
    end;
  finally
  end;

  fAttributes := prevState.Privileges[0].Attributes;

  Result := (Attributes and SE_PRIVILEGE_ENABLED = SE_PRIVILEGE_ENABLED) or
    (Attributes and SE_PRIVILEGE_ENABLED_BY_DEFAULT =
    SE_PRIVILEGE_ENABLED_BY_DEFAULT);
end;

function TJwPrivilege.IsEnabledByDefault: boolean;
begin
  Result := Attributes and SE_PRIVILEGE_ENABLED_BY_DEFAULT =
    SE_PRIVILEGE_ENABLED_BY_DEFAULT;
end;

procedure TJwPrivilege.SetEnabled(const en: boolean);
var
  privs: TOKEN_PRIVILEGES;
begin
  if not Assigned(Owner.Owner) then
    raise EJwsclNotImplementedException.CreateFmtEx(
      RsTokenNotAssignedPrivilege,
      'SetEnabled', ClassName, RsUNToken, 0, False, []);

  Owner.Owner.CheckTokenHandle('set TJwPrivilege.Enabled');
  Owner.Owner.CheckTokenAccessType(TOKEN_QUERY +
    TOKEN_ADJUST_PRIVILEGES, 'TOKEN_QUERY,TOKEN_ADJUST_PRIVILEGES',
    'TJwPrivilege.SetEnabled');

  privs.PrivilegeCount := 1;
  privs.Privileges[0].Luid := Self.LUID;

  if en then
    if fPrivilege_Enabled_By_Default then
      //also reset enabled by default attribute if it was originally specified
      privs.Privileges[0].Attributes :=
        SE_PRIVILEGE_ENABLED or SE_PRIVILEGE_ENABLED_BY_DEFAULT
    else
      privs.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
  else
    privs.Privileges[0].Attributes := 0;


  if (not AdjustTokenPrivileges(Owner.Owner.TokenHandle, False,
    @privs, 0, nil, nil)) then
    raise EJwsclAdjustPrivilegeException.CreateFmtEx(
      RsPrivilegeCallAdjustTokenFailed,
      'SetEnabled', ClassName, RsUNToken,
      0, True, [Self.Name]);

  fAttributes := privs.Privileges[0].Attributes;
end;

procedure TJwPrivilege.RemoveIrrepealable;
begin
  Owner.RemoveIrrepealable(Self);
end;



{**************** TJwSecurityToken ******************}

constructor TJwSecurityToken.Create;
begin
  inherited;

  fPrivelegesList := TObjectList.Create(False);
  fStackPrivilegesList := TObjectList.Create(True);

  //  fSecurityIDList := TJwSecurityIdList.Create(true);

  fTokenHandle := 0;
  fShared := True;
end;

procedure TJwSecurityToken.Done;
//[Hint] var i : Integer;
begin
  fPrivelegesList.Free;
  fPrivelegesList := nil;

  //!!hier noch privs zur�ckpopen
  fStackPrivilegesList.Free;
  fStackPrivilegesList := nil;
end;

destructor TJwSecurityToken.Destroy;
begin
  inherited;

  //close handle if not shared
  if not Shared then
    CloseHandle(fTokenHandle);

  //invalidate it  
  fTokenHandle := 0;

  Done;
  //  fSecurityIDList.Free;
end;

function TJwSecurityToken.PopPrivileges: Cardinal;
var
  Privs, PrivPop: TJwPrivilegeSet;
  i: integer;
  Priv: TJwPrivilege;
begin
  Result := 0;

  if (fStackPrivilegesList.Count = 0) then
    exit;
  if not Assigned(fStackPrivilegesList) then
    fStackPrivilegesList := TObjectList.Create;

  Privs := GetTokenPrivileges;
  PrivPop := fStackPrivilegesList[fStackPrivilegesList.Count - 1] as
    TJwPrivilegeSet;
  for i := 0 to Privs.Count - 1 do
  begin
    try
      Priv := Privs.GetPrivByName(PrivPop.PrivByIdx[i].Name);
    except
      Priv := nil;
    end;
    if Assigned(Priv) then
    begin
      Priv.Enabled := PrivPop.PrivByIdx[i].Enabled;
    end;
  end;
  fStackPrivilegesList.Delete(fStackPrivilegesList.Count - 1);

  Result := fStackPrivilegesList.Count;
end;

function TJwSecurityToken.PushPrivileges: Cardinal;
var
  Privs: TJwPrivilegeSet;
begin
  Privs := GetTokenPrivileges;
  fStackPrivilegesList.Add(Privs);

  Result := fStackPrivilegesList.Count;
end;

procedure TJwSecurityToken.CheckTokenHandle(sSourceProc: string);
begin
  //TODO: check also non null tokens
  if fTokenHandle = 0 then
    raise EJwsclInvalidTokenHandle.CreateFmtEx(
      RsTokenInvalidTokenHandle,
      sSourceProc, ClassName, RsUNToken, 0, False, []);
end;

function TJwSecurityToken.GetMaximumAllowed : TAccessMask;
var SD : TJwSecurityDescriptor;
    Token : TJwSecurityToken;
begin
  SD := TJwSecureGeneralObject.GetSecurityInfo(
    TokenHandle,//const aHandle: THandle;
    SE_KERNEL_OBJECT,  //const aObjectType: TSeObjectType;
    [siOwnerSecurityInformation,siGroupSecurityInformation,siDaclSecurityInformation]//aSecurityInfo: TJwSecurityInformationFlagSet;
    );

//  ShowMEssage(SD.Text);
  try
    Token := TJwSecurityToken.CreateTokenEffective(TOKEN_READ or TOKEN_QUERY or
      TOKEN_DUPLICATE);
    Token.ConvertToImpersonatedToken(SecurityImpersonation,
        TOKEN_IMPERSONATE or TOKEN_DUPLICATE or TOKEN_READ or TOKEN_QUERY);
    try
      result := TJwSecureGeneralObject.ConvertMaximumAllowed(SD, Token,
                TJwSecurityTokenMapping);
    finally
      FreeAndNil(Token);
    end;
  finally
    FreeAndNil(SD);
  end;
end;

constructor TJwSecurityToken.CreateTokenByProcess(
  const aProcessHandle: TJwProcessHandle; const aDesiredAccess: TJwAccessMask);
var
  hProcess: TJwProcessHandle;
  bResult:  boolean;
begin
  Self.Create;

  hProcess := aProcessHandle;
  if hProcess = 0 then
    hProcess := GetCurrentProcess;

  bResult := OpenProcessToken(hProcess, aDesiredAccess, fTokenHandle);

  if not bResult then
  begin
    raise EJwsclOpenProcessTokenException.CreateFmtEx(
      RsWinCallFailed,
      'CreateTokenByProcess',
      ClassName, RsUNToken, 0, True, ['OpenProcessToken']);
  end;

  if aDesiredAccess = MAXIMUM_ALLOWED then
    fAccessMask := GetMaximumAllowed
  else
    fAccessMask := aDesiredAccess;


  Shared := False;
end;

constructor TJwSecurityToken.CreateTokenByThread(
  const aThreadHandle: TJwThreadHandle; const aDesiredAccess: TJwAccessMask;
  const anOpenAsSelf: boolean);
var
  hThread: TJwThreadHandle;
  bResult: boolean;
begin
  Self.Create;


  hThread := aThreadHandle;
  if hThread = 0 then
    hThread := GetCurrentThread;

  bResult := OpenThreadToken(hThread, aDesiredAccess, anOpenAsSelf,
    fTokenHandle);

  if not bResult then
  begin
    Done;

    if GetLastError() = ERROR_NO_TOKEN then //no token available
    begin
      raise EJwsclNoThreadTokenAvailable.CreateFmtEx(
        RsTokenInvalidThreadToken,
        'CreateTokenByThread', ClassName, RsUNToken, 0, True, []);
    end
    else
    begin
      raise EJwsclOpenThreadTokenException.CreateFmtEx(
        RsTokenUnableToOpenThreadToken, 'CreateTokenByThread', ClassName,
        RsUNToken, 0, True, []);
    end;
  end;

  if aDesiredAccess = MAXIMUM_ALLOWED then
    fAccessMask := GetMaximumAllowed
  else
    fAccessMask := aDesiredAccess;

  Shared := False;
end;

constructor TJwSecurityToken.CreateTokenEffective(
  const aDesiredAccess: TJwAccessMask);
var
  bResult: boolean;
  hTokenHandle: TJwTokenHandle;
begin
  //[Hint] bResult := true; //if false the thread token is not available
  (*try
    CreateTokenByThread(0, aDesiredAccess, true);
  except
    on E : EJwsclNoThreadTokenAvailable do  //continue if thread token is not available...
      bResult := false; //thread token is not available
    else
      raise; //...otherwise reraise exception
  end;*)

  bResult := OpenThreadToken(GetCurrentThread, aDesiredAccess,
    True, hTokenHandle);
  if bResult then
  begin
    Self.Create;

    fTokenHandle := hTokenHandle;
    Shared := False;
  end;

  if not bResult then //get process token if thread token is not available
    //open process token
    CreateTokenByProcess(0, aDesiredAccess);

  if aDesiredAccess = MAXIMUM_ALLOWED then
    fAccessMask := GetMaximumAllowed
  else
    fAccessMask := aDesiredAccess;
end;

constructor TJwSecurityToken.Create(const aTokenHandle: TJwTokenHandle;
  const aDesiredAccess: TJwAccessMask);
begin
  Self.Create;
  fTokenHandle := aTokenHandle;
  fAccessMask  := aDesiredAccess;

  if aDesiredAccess = MAXIMUM_ALLOWED then
    fAccessMask := GetMaximumAllowed
  else
    fAccessMask := aDesiredAccess;
end;

constructor TJwSecurityToken.CreateWTSQueryUserToken(SessionID:
  Cardinal {= INVALID_HANDLE_VALUE});
begin
  if not (TJwWindowsVersion.IsWindowsXP(True) or
    TJwWindowsVersion.IsWindows2003(True)) then
    raise EJwsclUnsupportedWindowsVersionException.CreateFmtEx(
      RsTokenUnsupportedWtsCall,
      'Create', ClassName, RsUNToken, 0, False, []);

  if not JwIsPrivilegeSet(SE_TCB_NAME,pqt_Available) then
    raise EJwsclPrivilegeCheckException.CreateFmtEx(
      RsTokenPrivilegeNotHeld,
      'Create', ClassName, RsUNToken, 0, False, [SE_TCB_NAME]);

  Self.Create;
  fShared := False;
  fTokenHandle := 0;

  if SessionID = INVALID_HANDLE_VALUE then
  begin
    if not WTSQueryUserToken(WtsGetActiveConsoleSessionID, fTokenHandle) then
      if not WTSQueryUserToken(WTS_CURRENT_SESSION, fTokenHandle) then
        raise EJwsclWinCallFailedException.CreateFmtEx(
          RsTokenCallWtsQueryUserTokenFailed,
          'WTSQueryUserToken', ClassName, RsUNToken,
          0, True, [SessionID]);
  end
  else
  begin
    if not WTSQueryUserToken(SessionID, fTokenHandle) then
      raise EJwsclWinCallFailedException.CreateFmtEx(
        RsTokenCallWtsQueryUserTokenFailed,
        'WTSQueryUserToken', ClassName, RsUNToken,
        0, True, [SessionID]);
  end;

  //should be TOKEN_ALL_ACCESS
  fAccessMask := GetMaximumAllowed;
end;

constructor TJwSecurityToken.CreateDuplicateExistingToken(
  const aTokenHandle: TJwTokenHandle; const aDesiredAccess: TJwAccessMask;
  UseDuplicateExistingToken: boolean = False);
begin
  Self.Create;

  fTokenHandle := aTokenHandle;
  fAccessMask  := TOKEN_ALL_ACCESS;

  try
    ConvertToPrimaryToken(aDesiredAccess);
  except
    Done; //free objects created by Self.Create;
    raise;
  end;
end;

constructor TJwSecurityToken.CreateRestrictedToken(aTokenHandle: TJwTokenHandle;
  const aTokenAccessMask: TJwTokenAccessMask;
  aFlags: Cardinal;
  aSidsToDisable: TJwSecurityIdList;
  aPrivilegesToDelete: TJwPrivilegeSet;
  aRestrictedSids: TJwSecurityIdList);
var
  bRes: boolean;

  pLuids: PLUID_AND_ATTRIBUTES;
  pDisSids, pResSids: PSID_AND_ATTRIBUTES;

  cLuids, cDisSids, cResSids: Cardinal;

  aToken: TJwSecurityToken;
begin
  Self.Create;
  fShared := False;

  aToken := nil;

  if aTokenHandle = 0 then
  begin
    aToken := TJwSecurityToken.CreateTokenEffective(aTokenAccessMask);
    aTokenHandle := aToken.TokenHandle;

  end;

  pDisSids := nil;
  pLuids := nil;
  pResSids := nil;



  cDisSids := 0;
  cLuids := 0;
  cResSids := 0;

  if Assigned(aSidsToDisable) then
  begin
    pDisSids := PSID_AND_ATTRIBUTES(aSidsToDisable.Create_PSID_Array);
    cDisSids := aSidsToDisable.Count;
  end;

  if Assigned(aPrivilegesToDelete) then
  begin
    pLuids := aPrivilegesToDelete.Create_PLUID_AND_ATTRIBUTES;
    cLuids := aPrivilegesToDelete.Count;
  end;

  if Assigned(aRestrictedSids) then
  begin
    pResSids := PSID_AND_ATTRIBUTES(aRestrictedSids.Create_PSID_Array);
    cResSids := aRestrictedSids.Count;
  end;

  //[Hint] bRes := false;
  try
    bRes := jwaWindows.CreateRestrictedToken(aTokenHandle,
      aFlags, cDisSids, pDisSids, cLuids, pLuids,
      cResSids, pResSids, fTokenHandle);
  finally
    if Assigned(pDisSids) then
      aSidsToDisable.Free_PSID_Array(PSidAndAttributesArray(pDisSids));

    if Assigned(pLuids) then
      aPrivilegesToDelete.Free_PLUID_AND_ATTRIBUTES(pLuids);

    if Assigned(pResSids) then
      aRestrictedSids.Free_PSID_Array(PSidAndAttributesArray(pResSids));
  end;

  if aTokenAccessMask = MAXIMUM_ALLOWED then
    fAccessMask := GetMaximumAllowed
  else
    fAccessMask := aTokenAccessMask;

  if Assigned(aToken) then
    aToken.Free;

  if not bRes then
    raise EJwsclSecurityException.CreateFmtEx(
      RsTokenFailedImpersonateAnonymousToken,
      'CreateRestrictedToken', ClassName, RsUNToken, 0, True, []);
end;


procedure TJwSecurityToken.ConvertToImpersonatedToken(
  impLevel: SECURITY_IMPERSONATION_LEVEL; const aDesiredAccess: TJwAccessMask);
var
  hNewTokenHandle: TJwTokenHandle;
begin
  //check for valid token handle
  CheckTokenHandle('ConvertToImpersonatedToken');
  CheckTokenAccessType(TOKEN_DUPLICATE +
    TOKEN_READ, 'TOKEN_DUPLICATE,TOKEN_READ', 'ConvertToImpersonatedToken');



  //we do not need to impersonate token if it is already impersonated
  if GetTokenType = TokenImpersonation then
    exit;

  //we are not allowed to close
{  if fShared then
    raise EJwsclSharedTokenException.CreateFmtEx('Cannot convert a SHARED  token',
                        'ConvertToImpersonatedToken','TJwSecurityToken',RsUNToken,0,true,[]);
 }

  //create a copy of the token
  if DuplicateTokenEx(fTokenHandle, aDesiredAccess, nil, impLevel,
    TokenImpersonation, hNewTokenHandle) then
  begin
    //we need to close the handle
    if not fShared then
      CloseHandle(fTokenHandle);
    fTokenHandle := hNewTokenHandle;
    if aDesiredAccess = MAXIMUM_ALLOWED then
      fAccessMask := GetMaximumAllowed
    else
      fAccessMask := aDesiredAccess;
  end
  else
    raise EJwsclTokenImpersonationException.CreateFmtEx(
      RsTokenCallDuplicateTokenFailed1,
      'GetTokenInformation', ClassName, RsUNToken, 0, True, []);
end;

procedure TJwSecurityToken.ConvertToPrimaryToken(
  const aDesiredAccess: TJwAccessMask);
var
  hNewTokenHandle: TJwTokenHandle;
begin
  //check for valid token handle
  CheckTokenHandle('ConvertToPrimaryToken');
  CheckTokenAccessType(TOKEN_DUPLICATE +
    TOKEN_READ, 'TOKEN_DUPLICATE,TOKEN_READ', 'ConvertToPrimaryToken');

  //we do not need to impersonate token if it is already impersonated
  if GetTokenType = TokenPrimary then
    exit;

  //we are not allowed to close
{  if fShared then
    raise EJwsclSharedTokenException.CreateFmtEx('Cannot convert a SHARED  token',
                        'ConvertToImpersonatedToken','TJwSecurityToken',RsUNToken,0,true,[]);
 }

  //create a copy of the token
  if DuplicateTokenEx(fTokenHandle, aDesiredAccess, nil,
    DEFAULT_IMPERSONATION_LEVEL, TokenPrimary, hNewTokenHandle) then
  begin
    //we need to close the handle
    if not fShared then
      CloseHandle(fTokenHandle);
    fTokenHandle := hNewTokenHandle;

    if aDesiredAccess = MAXIMUM_ALLOWED then
      fAccessMask := GetMaximumAllowed
    else
      fAccessMask := aDesiredAccess;
  end
  else
    raise EJwsclTokenPrimaryException.CreateFmtEx(
      RsTokenCallDuplicateTokenFailed1,
      'GetTokenInformation', ClassName, RsUNToken, 0, True, []);
end;


function TJwSecurityToken.GetTokenInformationLength(hTokenHandle: TJwTokenHandle;
  aTokenInformationClass: TTokenInformationClass): Cardinal;

var
  ptrTokenType: Pointer;
  iError : Integer;
  iTC : Cardinal;
  TokenClass : JwaWindows._TOKEN_INFORMATION_CLASS;
begin
  CheckTokenHandle('GetTokenInformationLength');

  Result := 0;
  ptrTokenType := nil;

  iTC := Cardinal(aTokenInformationClass);
  TokenClass := JwaWindows._TOKEN_INFORMATION_CLASS(iTC);

  //GetTokenInformation should always return ERROR_INSUFFICIENT_BUFFER
  if not jwaWindows.GetTokenInformation(
    hTokenHandle, TokenClass,
    ptrTokenType, 0, Result) then
  begin
    iError := GetLastError;
    if (iError <> ERROR_INSUFFICIENT_BUFFER) and
       (iError <> 24) then
      Result := 0;
  end;
end;

procedure TJwSecurityToken.GetTokenInformation(hTokenHandle: TJwTokenHandle;
  TokenInformationClass: TTokenInformationClass;
  out TokenInformation: Pointer);

  procedure doRaiseError(EClass: EJwsclExceptionClass; msg: string);
  begin
    if EClass = nil then
      EClass := EJwsclTokenInformationException;
    raise EClass.CreateFmtEx(msg, 'GetTokenInformation', ClassName,
      RsUNToken, 0, True, []);
  end;

var
  tokLen: Cardinal;
  Result: boolean;
  //[Hint] i,i2,i3 : Integer;
  //[Hint] w : Cardinal;
  //[Hint] k : jwawindows.TTokenInformationClass;
begin
  CheckTokenHandle('GetTokenInformation');

  CheckTokenAccessType(TOKEN_READ or
    TOKEN_QUERY, 'TOKEN_READ, TOKEN_QUERY', 'GetTokenInformation');

  tokLen := Self.GetTokenInformationLength(
    hTokenHandle, TokenInformationClass);

  if tokLen <= 0 then
    doRaiseError(nil, RsTokenUnableTokenInformationLength);

  TokenInformation := HeapAlloc(JwProcessHeap, HEAP_ZERO_MEMORY, tokLen);

  if (TokenInformation = nil) then
    doRaiseError(EJwsclNotEnoughMemory,
      RsTokenNotEnoughMemoryTokenSave);

  //result := jwaWindows.GetTokenInformation(hTokenHandle,TokenInformationClass,
  //                       TokenInformation, tokLen,tokLen);
  {i := Integer(TokenInformationClass);
  if i = 0 then;
  i2 := sizeof(JwsclTypes.TTokenInformationClass);  // = 1
  i3 := sizeof(jwawindows.TTokenInformationClass); // = 4
  if i2 = i3 then;
  i3 := sizeof(w);}

  //alignment of 4 bytes is important - JwsclTypes.TTokenInformationClass does not
  Result := jwaWindows.GetTokenInformation(hTokenHandle,
    jwawindows.TTokenInformationClass(TokenInformationClass),
    TokenInformation, tokLen, tokLen);

  if not Result then
  begin
    HeapFree(JwProcessHeap, 0, TokenInformation);
    doRaiseError(nil, RsTokenUnableGetTokenInformation);
  end;
end;

function TJwSecurityToken.GetImpersonationLevel: TSecurityImpersonationLevel;
var
  imp: PSecurityImpersonationLevel;
begin
  CheckTokenHandle('GetImpersonationLevel');

  //a process token does not have impersonation level
  if GetTokenType = TokenPrimary then
  begin
    Result := DEFAULT_IMPERSONATION_LEVEL;
    exit;
  end;


  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}*)
    TokenImpersonationLevel, Pointer(imp));


  Result := imp^;

  HeapFree(JwProcessHeap, 0, imp);
end;

function TJwSecurityToken.GetTokenUser: TJwSecurityId;
var
  pUser: PTOKEN_USER;
begin
  CheckTokenHandle('GetTokenUser');

  pUser := nil;
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}*)
    JwaVista.TokenUser, Pointer(pUser));


  Result := TJwSecurityId.Create(PSidAndAttributes(@pUser^.User));

  HeapFree(JwProcessHeap, 0, pUser);
end;

function TJwSecurityToken.GetTokenSource: TTokenSource;
var
  pSource: PTOKEN_SOURCE;
begin
  CheckTokenHandle('GetTokenSource');

  GetTokenInformation(fTokenHandle, TokenSource, Pointer(pSource));
  Result := pSource^;
  HeapFree(JwProcessHeap, 0, pSource);
end;



procedure TJwSecurityToken.GetTokenSource(out SourceName: ShortString;
  out SourceLUID: TLuid);
var
  pSource: PTOKEN_SOURCE;
begin
  CheckTokenHandle('GetTokenSource');

  GetTokenInformation(fTokenHandle, TokenSource, Pointer(pSource));

  SourceName := pSource^.SourceName;
  SourceLUID := pSource^.SourceIdentifier;

  HeapFree(JwProcessHeap, 0, pSource);
end;

function TJwSecurityToken.GetTokenGroupsAttributesInt(Index : Integer) : TJwSidAttributeSet;
var Groups : TJwSecurityIdList;
begin
  Groups := TokenGroups;
  try
    result := Groups.Items[Index].AttributesType;
  finally
    FreeAndNil(Groups);
  end;
end;

procedure TJwSecurityToken.SetTokenGroupsAttributesInt(Index : Integer; Attributes: TJwSidAttributeSet);
var Groups : TJwSecurityIdList;
begin
  Groups := TokenGroups;
  try
    Groups.Items[Index].AttributesType := Attributes;
    TokenGroups := Groups;
  finally
    FreeAndNil(Groups);
  end;
end;

function TJwSecurityToken.GetTokenGroupsAttributesSid(Sid : TJwSecurityId) : TJwSidAttributeSet;
var Groups : TJwSecurityIdList;
begin
  Groups := TokenGroups;
  try
    result := Groups.Items[Groups.FindSid(Sid)].AttributesType;
  finally
    FreeAndNil(Groups);
  end;
end;


procedure TJwSecurityToken.SetTokenGroupsAttributesSid(Sid : TJwSecurityId; Attributes: TJwSidAttributeSet);
var Groups : TJwSecurityIdList;
begin
  Groups := TokenGroups;
  try
    Groups.Items[Groups.FindSid(Sid)].AttributesType := Attributes;
    TokenGroups := Groups;
  finally
    FreeAndNil(Groups);
  end;
end;


procedure TJwSecurityToken.SetTokenGroups(List: TJwSecurityIdList);
var
  groups: PTOKEN_GROUPS;
  temp: Cardinal;
begin
  CheckTokenHandle('GetTokenGroupsEx');

  if not Assigned(List) then
    raise EJwsclNILParameterException.CreateFmtEx(
      RsNilParameter,
      'SetTokenGroups', ClassName, RsUNToken, 0, False,
      ['List']);

  groups := List.Create_PTOKEN_GROUPS;
  temp := 0;
  try
    if not AdjustTokenGroups(fTokenHandle,//HANDLE TokenHandle,
      False,//BOOL ResetToDefault,
      groups,//PTOKEN_GROUPS NewState,
      0,//DWORD BufferLength,
      nil,//PTOKEN_GROUPS PreviousState,
      @temp//PDWORD ReturnLength
      ) then
      raise EJwsclWinCallFailedException.CreateFmtWinCall(
        RsWinCallFailed,
        'SetTokenGroups',                               //sSourceProc
        ClassName,                                //sSourceClass
        RsUNToken,                          //sSourceFile
        0,                                           //iSourceLine
        True,                                 //bShowLastError
        'AdjustTokenGroups',                  //sWinCall
        ['AdjustTokenGroups']);
    //const Args: array of const


  finally
    List.Free_PTOKEN_GROUPS(groups);
  end;

end;

function TJwSecurityToken.GetTokenGroups: TJwSecurityIdList;
var
  pGroups: PTOKEN_GROUPS;
begin
  CheckTokenHandle('GetTokenGroups');

  GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}*)
    JwaVista.TokenGroups, Pointer(pGroups));

  Result := TJwSecurityIdList.Create(True, pGroups);

  HeapFree(JwProcessHeap, 0, pGroups);
end;

function TJwSecurityToken.GetTokenGroupsEx: PTokenGroups;
  //var pGroups : PTOKEN_GROUPS;
begin
  CheckTokenHandle('GetTokenGroupsEx');

  GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}*)
    JwaVista.TokenGroups, Pointer(Result));
end;




function TJwSecurityToken.GetTokenRestrictedSids: TJwSecurityIdList;
var
  pGroups: PTOKEN_GROUPS;
begin
  CheckTokenHandle('GetTokenRestrictedSids');
  GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}     *)
    JwaVista.TokenRestrictedSids, Pointer(pGroups));
  Result := TJwSecurityIdList.Create(True, pGroups);
  HeapFree(JwProcessHeap, 0, pGroups);
end;



function TJwSecurityToken.GetTokenDefaultDacl: TJwDAccessControlList;
var
  pDACL: PTOKEN_DEFAULT_DACL;
begin
  CheckTokenHandle('GetTokenDefaultDacl');

  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}     *)
    JwaVista.TokenDefaultDacl, Pointer(pDACL));
  try
    Result := TJwDAccessControlList.Create(pDACL^.DefaultDacl);
  finally
    HeapFree(JwProcessHeap, 0, pDACL);
  end;
end;

procedure TJwSecurityToken.SetTokenDefaultDacl(
  const aDefaultDCAL: TJwDAccessControlList); //TOKEN_ADJUST_DEFAULT
var
  pDACL: TOKEN_DEFAULT_DACL;
begin
  CheckTokenHandle('SetfTokenDefaultDacl');
  CheckTokenAccessType(TOKEN_ADJUST_DEFAULT, 'TOKEN_ADJUST_DEFAULT',
    'SetfTokenDefaultDacl');


  pDACL.DefaultDacl := aDefaultDCAL.Create_PACL;

  if (not SetTokenInformation(fTokenHandle, jwaWindows.TokenDefaultDacl,
    Pointer(@pDACL), sizeof(TOKEN_DEFAULT_DACL))) then
    raise EJwsclWinCallFailedException.CreateFmtEx(
      RsWinCallFailed,
      'SetTokenDefaultDacl', ClassName, RsUNToken, 0, True,
      ['SetTokenInformation']);

  aDefaultDCAL.Free_PACL(pDACL.DefaultDacl);
end;

function TJwSecurityToken.GetTokenOrigin: TLuid;
var
  pOrigin: PTOKEN_ORIGIN;
begin
  CheckTokenHandle('GetTokenOrigin');

  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}     *)
    JwaVista.TokenOrigin, Pointer(pOrigin));
  try
    Result := pOrigin^.OriginatingLogonSession;
  finally
    HeapFree(GetProcessHeap, 0, pOrigin);
  end;
end;

procedure TJwSecurityToken.SetTokenOrigin(const anOrigin: TLuid); //SE_TCB_NAME
var
  pOrigin: TOKEN_ORIGIN;
begin
  CheckTokenHandle('SetTokenOrigin');
  CheckTokenPrivileges([SE_TCB_NAME]);

  try
    PushPrivileges;
    PrivilegeEnabled[SE_TCB_NAME] := True;

    pOrigin.OriginatingLogonSession := anOrigin;

    if (not SetTokenInformation(fTokenHandle, jwaWindows.TokenOrigin,
      Pointer(@pOrigin), sizeof(pOrigin))) then
      raise EJwsclWinCallFailedException.CreateFmtEx(
        RsWinCallFailed,
        'SetTokenOrigin', ClassName, RsUNToken, 0, True,
         ['SetTokenInformation']);
  finally
    PopPrivileges;
  end;

end;

function TJwSecurityToken.GetTokenOwner: TJwSecurityId;
var
  pOwner: PTOKEN_OWNER;
begin
  CheckTokenHandle('GetTokenOwner');

  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}     *)
    JwaVista.TokenOwner, Pointer(pOwner));
  try
    Result := TJwSecurityId.Create(PSidAndAttributes(@pOwner^.Owner));
  finally
    HeapFree(GetProcessHeap, 0, pOwner);
  end;
end;

procedure TJwSecurityToken.SetTokenOwner(const anOwner: TJwSecurityId);
//TOKEN_ADJUST_DEFAULT
var
  pOwner: TOKEN_OWNER;
begin
  CheckTokenHandle('SetTokenOrigin');
  CheckTokenPrivileges([SE_TCB_NAME]);

  pOwner.Owner := anOwner.SID;
  try
    PushPrivileges;
    PrivilegeEnabled[SE_TCB_NAME] := True;

    if (not SetTokenInformation(fTokenHandle, jwaWindows.TokenOwner,
      Pointer(@pOwner), sizeof(pOwner))) then
      raise EJwsclWinCallFailedException.CreateFmtEx(
        RsWinCallFailed,
        'SetTokenInformation', ClassName, RsUNToken, 0, True,
        ['SetTokenInformation']);
  finally
    PopPrivileges;
  end;
end;

function TJwSecurityToken.GetPrimaryGroup: TJwSecurityId;
var
  pPrimaryGroup: PTOKEN_PRIMARY_GROUP;
begin
  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}     *)
    JwaVista.TokenPrimaryGroup, Pointer(pPrimaryGroup));
  try
    Result := TJwSecurityId.Create(PSidAndAttributes(
      @pPrimaryGroup^.PrimaryGroup));
  finally
    HeapFree(GetProcessHeap, 0, pPrimaryGroup);
  end;
end;

procedure TJwSecurityToken.SetPrimaryGroup(const PrimGroup: TJwSecurityId);
//TOKEN_ADJUST_DEFAULT
var
  pPrimaryGroup: TOKEN_PRIMARY_GROUP;
begin
  CheckTokenHandle('SetTokenOrigin');

  pPrimaryGroup.PrimaryGroup := PrimGroup.SID;

  if (not SetTokenInformation(fTokenHandle, jwaWindows.TokenPrimaryGroup,
    Pointer(@pPrimaryGroup), sizeof(pPrimaryGroup))) then
    raise EJwsclWinCallFailedException.CreateFmtEx(
      RsWinCallFailed,
      'SetPrimaryGroup', ClassName, RsUNToken, 0, True,
      ['SetTokenInformation']);
end;


function TJwSecurityToken.GetTokenSessionId: Cardinal;
var
  ID: PCardinal;
begin
  CheckTokenHandle('GetTokenSessionId');

  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}     *)
    JwaVista.TokenSessionId, Pointer(ID));
  try
    Result := ID^;
  finally
    HeapFree(GetProcessHeap, 0, ID);
  end;
end;

procedure TJwSecurityToken.SetTokenSessionId(const SessionID: Cardinal);
//SE_TCB_NAME
begin
  if TJwWindowsVersion.IsWindows2000(False) then
    exit;

  CheckTokenHandle('SetTokenSessionId');
  CheckTokenPrivileges([SE_TCB_NAME]);

  try
    PushPrivileges;

    PrivilegeEnabled[SE_TCB_NAME] := True;

    if (not SetTokenInformation(
      fTokenHandle, jwaWindows.TokenSessionId, Pointer(@SessionID),
      sizeof(SessionID))) then
      raise EJwsclWinCallFailedException.CreateFmtEx(
        RsWinCallFailed,
        'SetTokenSessionId', ClassName, RsUNToken, 0, True,
         ['SetTokenInformation']);
  finally
    PopPrivileges;
  end;
end;

function TJwSecurityToken.GetPrivilegeAvailable(Name: string): boolean;
var
  privSet: TJwPrivilegeSet;
begin
  CheckTokenHandle('GetPrivilegeAvailable');
  
  privSet := GetTokenPrivileges;

  try
    Result := Assigned(privSet.PrivByName[Name]);
  finally
    privSet.Free;
  end;
end;

function TJwSecurityToken.GetPrivilegeEnabled(Name: string): boolean;
var
  privSet: TJwPrivilegeSet;
begin
  CheckTokenHandle('GetPrivilegeEnabled');
  privSet := GetTokenPrivileges;

  if Assigned(privSet.PrivByName[Name]) then
    Result := privSet.PrivByName[Name].Enabled
  else
    Result := False;

  privSet.Free;
end;

procedure TJwSecurityToken.SetPrivilegeEnabled(Name: string; En: boolean);
var
  privSet: TJwPrivilegeSet;
  S: TJwString;
begin
  CheckTokenHandle('SetPrivilegeEnabled');
  privSet := GetTokenPrivileges;

  S := TJwString(Name);
  if Assigned(privSet.PrivByName[s]) then
    privSet.PrivByName[s].Enabled := En
  else
  begin
    privSet.Free;
    raise EJwsclPrivilegeNotFoundException.CreateFmtEx(
      RsTokenPrivilegeNotFound, 'IsPrivilegeEnabled', ClassName, RsUNToken,
      0, False, [Name]);
  end;

  privSet.Free;
end;

function TJwSecurityToken.GetRunElevation: Cardinal;
var
  privs: PTokenElevation;
begin
  TJwWindowsVersion.CheckWindowsVersion(
    cOsVista, True, 'GetRunElevation', ClassName, RsUNToken, 0);
  CheckTokenHandle('GetRunElevation');

  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}*)
    JwaVista.TTokenInformationClass(
(*{$IFNDEF SL_OMIT_SECTIONS}
    JwsclTypes.
{$ENDIF SL_OMIT_SECTIONS}*)
    JwaVista.TokenElevation), Pointer(privs));

  Result := privs^.TokenIsElevated;

  HeapFree(GetProcessHeap, 0, privs);
end;


function TJwSecurityToken.GetLinkedToken : TJwSecurityToken;
var Data : PTokenLinkedToken;
begin
  TJwWindowsVersion.CheckWindowsVersion(
    cOsVista, True, 'GetLinkedToken', ClassName, RsUNToken, 0);
  CheckTokenHandle('GetLinkedToken');

  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
    JwaVista.TTokenInformationClass(JwaVista.TokenLinkedToken), Pointer(Data));

  try
    result := TJwSecurityToken.Create(Data^.LinkedToken, MAXIMUM_ALLOWED);
  finally
    HeapFree(GetProcessHeap, 0, Data);
  end;
end;

function TJwSecurityToken.GetIntegrityLevel: TJwSecurityIdList;
var
  mL: PTokenMandatoryLabel;
begin
  TJwWindowsVersion.CheckWindowsVersion(
    cOsVista, True, 'GetIntegrityLevel', ClassName, RsUNToken, 0);
  CheckTokenHandle('GetIntegrityLevel');

  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
    JwaVista.TTokenInformationClass(JwaVista.TokenIntegrityLevel), Pointer(mL));

  try
    result := TJwSecurityIdList.Create(@Ml^.Label_);
  finally
    HeapFree(GetProcessHeap, 0, mL);
  end;
end;

function TJwSecurityToken.GetElevationType: TTokenElevationType;
var
  privs: PTokenElevationType;
begin
  TJwWindowsVersion.CheckWindowsVersion(
    cOsVista, True, 'GetElevationType', ClassName, RsUNToken, 0);
  CheckTokenHandle('GetElevationType');

  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}*)
    JwaVista.TTokenInformationClass(
(*{$IFNDEF SL_OMIT_SECTIONS}
    JwsclTypes.
{$ENDIF SL_OMIT_SECTIONS}*)
    JwaVista.TokenElevationType), Pointer(privs));

  Result := privs^;

  HeapFree(GetProcessHeap, 0, privs);
end;

function TJwSecurityToken.GetVirtualizationAllowed: boolean;
var
  privs: PCardinal;
begin
  TJwWindowsVersion.CheckWindowsVersion(
    cOsVista, True, 'GetVirtualizationAllowed', ClassName, RsUNToken, 0);
  CheckTokenHandle('GetVirtualizationAllowed');

  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}*)
    JwaVista.TTokenInformationClass(
(*{$IFNDEF SL_OMIT_SECTIONS}
    JwsclTypes.
{$ENDIF SL_OMIT_SECTIONS}*)
    JwaVista.TokenVirtualizationAllowed), Pointer(privs));

  Result := privs^ <> 0;

  HeapFree(GetProcessHeap, 0, privs);
end;

function TJwSecurityToken.GetVirtualizationEnabled: boolean;
var
  privs: PCardinal;
begin
  TJwWindowsVersion.CheckWindowsVersion(
    cOsVista, True, 'GetVirtualizationEnabled', ClassName, RsUNToken, 0);
  CheckTokenHandle('GetVirtualizationEnabled');

  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}*)
    JwaVista.TTokenInformationClass(
(*{$IFNDEF SL_OMIT_SECTIONS}
    JwsclTypes.
{$ENDIF SL_OMIT_SECTIONS}*)
    JwaVista.TokenVirtualizationEnabled), Pointer(privs));

  Result := privs^ <> 0;

  HeapFree(GetProcessHeap, 0, privs);
end;


function TJwSecurityToken.GetMandatoryPolicy : DWORD;
var p : PTokenMandatoryPolicy;
begin
  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
    JwaVista.TokenMandatoryPolicy, Pointer(p));

  result := p^.Policy;
  
  HeapFree(GetProcessHeap, 0, p);
end;


function TJwSecurityToken.GetTokenPrivileges: TJwPrivilegeSet;
var
  privs: PTOKEN_PRIVILEGES;
begin
  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}     *)
    JwaVista.TokenPrivileges, Pointer(privs));

  Result := TJwPrivilegeSet.Create(Self, privs);
  fPrivelegesList.Add(Result);

  HeapFree(GetProcessHeap, 0, privs);
end;

function TJwSecurityToken.GetTokenPrivilegesEx: PTOKEN_PRIVILEGES;
  //var privs : PTOKEN_PRIVILEGES;
begin
  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}     *)
    JwaVista.TokenPrivileges, Pointer(Result));
end;

function TJwSecurityToken.CreateRestrictedToken(
  const aTokenAccessMask: TJwTokenHandle;
  aFlags: Cardinal;
  aSidsToDisable: TJwSecurityIdList;
  aPrivilegesToDelete: TJwPrivilegeSet;
  aRestrictedSids: TJwSecurityIdList)
: TJwSecurityToken;
begin
  Result := TJwSecurityToken.CreateRestrictedToken(TokenHandle,
    aTokenAccessMask, aFlags, aSidsToDisable, aPrivilegesToDelete,
    aRestrictedSids);
end;


function TJwSecurityToken.CreateDuplicateToken(AccessMask: TJwAccessMask;
  Security: PSECURITY_ATTRIBUTES): TJwSecurityToken;
var
  newTokenHandle: TJwTokenHandle;
begin
  CheckTokenHandle('CreateDuplicateToken');
  CheckTokenAccessType(TOKEN_DUPLICATE +
    TOKEN_READ, 'TOKEN_DUPLICATE,TOKEN_READ', 'CreateDuplicateToken');


  if not jwaWindows.DuplicateTokenEx(TokenHandle, AccessMask,
    LPSECURITY_ATTRIBUTES(Security), GetImpersonationLevel,
    GetTokenType, newTokenHandle) then
    EJwsclDuplicateTokenException.CreateFmtEx(
     RsWinCallFailed,
      'CreateDuplicateToken', ClassName, RsUNToken, 0, True,
      ['DuplicateTokenEx']);

  Result := TJwSecurityToken.Create;

  Result.fShared := False;
  Result.fTokenHandle := newTokenHandle;

  if AccessMask = MAXIMUM_ALLOWED then
    fAccessMask := GetMaximumAllowed
  else
    fAccessMask := AccessMask;  
end;



function TJwSecurityToken.CheckTokenMembership(aSidToCheck: TJwSecurityId)
: boolean;
var
  bRes: longbool;
begin
  CheckTokenHandle('CheckTokenMembership');

  bRes := True;
  jwaWindows.CheckTokenMembership(Self.TokenHandle, @aSidToCheck.SID, bRes);
  Result := bRes;
end;

function TJwSecurityToken.IsEqual(aToken: TJwSecurityToken): boolean;
var
  NtCompareTokens: function(FirstTokenHandle, SecondTokenHandle: THandle;
    var Equal: boolean): NTSTATUS; stdcall;
  dRes: NTSTATUS;
begin
  if not Assigned(aToken) then
    Result := False;

  CheckTokenAccessType(TOKEN_QUERY, 'TOKEN_QUERY', 'IsEqual');
  aToken.CheckTokenAccessType(TOKEN_QUERY, 'TOKEN_QUERY', 'IsEqual');
  @NtCompareTokens := TJwSecurityLibrary.LoadLibProc(ntdll, 'NtCompareTokens');

  SetLAstError(0);

  Result := False;
  if @NtCompareTokens <> nil then
  begin
    dRes := NtCompareTokens(TokenHandle, aToken.TokenHandle, Result);
    if not NT_SUCCESS(dRes) then
      raise EJwsclSecurityException.CreateFmtEx(
        RsTokenCallNTCompareTokensFailed,
        'IsEqual', ClassName, RsUNToken, 0, True, [dRes]);
  end
  else
    raise EJwsclNotImplementedException.CreateFmtEx(
      RsTokenUnsupportedNTCompareTokens,
      'IsEqual', ClassName, RsUNToken, 0, False, []);

end;

class procedure TJwSecurityToken.RemoveThreadToken(
  const Thread: TJwThreadHandle);
var
  pThread: ^TJwThreadHandle;
begin
  
  if Thread = 0 then
    pThread := nil
  else
    pThread := @Thread;

  if not jwaWindows.SetThreadToken(PHandle(pThread), 0) then
    raise EJwsclSecurityException.CreateFmtEx(RsTokenUnableRemoveToken,
      'SetThreadToken', ClassName, RsUNToken, 0, True, []);
end;


procedure TJwSecurityToken.SetThreadToken(const Thread: TJwThreadHandle);
var
  pThread: ^TJwThreadHandle;
begin
  CheckTokenHandle('SetThreadToken');
  
  if (TokenType <> TokenImpersonation) then
    raise EJwsclTokenPrimaryException.CreateFmtEx(
      RsTokeOnlyAttachImpersonatedToken,
      'SetThreadToken', ClassName, RsUNToken, 0, False, []);

  if Thread = 0 then
    pThread := nil
  else
    pThread := @Thread;
  if not jwaWindows.SetThreadToken(PHandle(pThread), TokenHandle) then
    raise EJwsclSecurityException.CreateFmtEx(RsTokenFailedSetToken,
      'SetThreadToken', ClassName, RsUNToken, 0, True, []);
end;

procedure TJwSecurityToken.ImpersonateLoggedOnUser;
begin
  //primary TOKEN_QUERY and TOKEN_DUPLICATE access. If hToken is an impersonation token, it must have TOKEN_QUERY and TOKEN_IMPERSONATE access.
  if TokenType = TokenImpersonation then
    CheckTokenAccessType(TOKEN_QUERY + TOKEN_IMPERSONATE,
      'TOKEN_QUERY,TOKEN_IMPERSONATE', 'ImpersonateLoggedOnUser')
  else
    CheckTokenAccessType(TOKEN_QUERY + TOKEN_DUPLICATE,
      'TOKEN_QUERY,TOKEN_DUPLICATE', 'ImpersonateLoggedOnUser');


  if not jwaWindows.ImpersonateLoggedOnUser(TokenHandle) then
    raise EJwsclSecurityException.CreateFmtEx(
      RsTokenFailedImpLoggedOnUser,
      'ImpersonateLoggedOnUser', ClassName, RsUNToken, 0, True, []);
end;

function TJwSecurityToken.PrivilegeCheck(aRequiredPrivileges: TJwPrivilegeSet;
  RequiresAllPrivs: boolean): boolean;
begin
  Result := PrivilegeCheck(Self, aRequiredPrivileges, RequiresAllPrivs);
end;

function TJwSecurityToken.PrivilegeCheckEx(aRequiredPrivileges: TJwPrivilegeSet;
  RequiresAllPrivs: boolean): boolean;
var
  pPriv: jwaWindows.PPRIVILEGE_SET;
  privs: TJwPrivilegeSet;
  bRes:  longbool;
begin
  privs := GetTokenPrivileges;
  pPriv := privs.Create_PPRIVILEGE_SET;

  if RequiresAllPrivs then
    pPriv.Control := PRIVILEGE_SET_ALL_NECESSARY;

  if not jwaWindows.PrivilegeCheck(TokenHandle, pPriv, bRes) then
  begin
    privs.Free_PPRIVILEGE_SET(pPriv);
    privs.Free;
    raise EJwsclSecurityException.CreateFmtEx(
      RsWinCallFailed,
      'PrivilegeCheckEx', ClassName, RsUNToken, 0, True,
      ['PrivilegeCheck']);
  end;

  Result := bRes;

  privs.Free_PPRIVILEGE_SET(pPriv);
  privs.Free;
end;

class procedure TJwSecurityToken.PrivilegedServiceAuditAlarm(
  SubsystemName, ServiceName: TJwString; ClientToken: TJwSecurityToken;
  Privileges: TJwPrivilegeSet;
  AccessGranted: boolean);

var
  pPriv: jwaWindows.PPRIVILEGE_SET;
  privs: TJwPrivilegeSet;

  primToken: TJwSecurityToken;
  bOldAuditPriv: boolean;
begin
  bOldAuditPriv := False;
  if not Assigned(ClientToken) then
    raise EJwsclInvalidTokenHandle.CreateFmtEx(
      RsWinCallFailed,
      'PrivilegedServiceAuditAlarm', ClassName, RsUNToken, 0, True,
      ['ClientToken']);


  {PrivilegedServiceAuditAlarm checks the process token for the needed privilege SE_AUDIT_NAME.
   So we open it here.
   The thread that calls this function does not need that privilege.

   We open the token with minimal access.
  }
  primToken := TJwSecurityToken.CreateTokenByProcess(0,
    TOKEN_READ or TOKEN_QUERY or
    TOKEN_ADJUST_PRIVILEGES or
    TOKEN_AUDIT_SUCCESS_INCLUDE or TOKEN_AUDIT_SUCCESS_EXCLUDE or
    TOKEN_AUDIT_FAILURE_INCLUDE or TOKEN_AUDIT_FAILURE_EXCLUDE);

  {first we try to get status of SE_AUDIT_NAME privilege.
   Maybe the process has not the privilege?

   We save the privilege status for later resetting.
  }
  try
    bOldAuditPriv := primToken.PrivilegeEnabled[SE_AUDIT_NAME];

    //not enable privilege
    primToken.PrivilegeEnabled[SE_AUDIT_NAME] := True;

    //now we set all privileges of the client token, so they will be shown in the audit log message
    privs := ClientToken.GetTokenPrivileges;
    pPriv := privs.Create_PPRIVILEGE_SET;

    if not
{$IFDEF UNICODE}PrivilegedServiceAuditAlarmW{$ELSE}
      PrivilegedServiceAuditAlarmA
{$ENDIF}
      (TJwPChar(SubsystemName), TJwPChar(ServiceName),
      ClientToken.TokenHandle, pPriv^, AccessGranted) then
    begin
      raise EJwsclWinCallFailedException.CreateFmtEx(
        RsWinCallFailed,
        'PrivilegedServiceAuditAlarm',
        ClassName, RsUNToken, 0, True,
        ['PrivilegeCheck']);
    end;

  finally
    try
      //reset privilege to old status
      primToken.PrivilegeEnabled[SE_AUDIT_NAME] := bOldAuditPriv;
    finally
      privs.Free_PPRIVILEGE_SET(pPriv);
      FreeAndNil(privs);
      //free token
      primToken.Free;
    end;
  end;
end;

class function TJwSecurityToken.CopyLUID(const originalLUID: TLUID): TLUID;
begin
  Result.LowPart  := originalLUID.LowPart;
  Result.HighPart := originalLUID.HighPart;
end;

function TJwSecurityToken.GetTokenStatistics: TJwSecurityTokenStatistics;
var
  stat: PTokenStatistics;
begin
  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}*)
    JwaVista.TokenStatistics, Pointer(stat));

  Result := TJwSecurityTokenStatistics.Create(stat^);

  HeapFree(GetProcessHeap, 0, stat);
end;

class function TJwSecurityToken.PrivilegeCheck(ClientToken: TJwSecurityToken;
  aRequiredPrivileges: TJwPrivilegeSet;
  RequiresAllPrivs: boolean): boolean;
var
  i: integer;
  privs: TJwPrivilegeSet;
  priv: TJwPrivilege;
begin
  if not Assigned(ClientToken) then
    raise EJwsclInvalidTokenHandle.CreateFmtEx(
      RsWinCallFailed,
      'PrivilegeCheck', ClassName, RsUNToken, 0, False,
      ['ClientToken']);

  Result := True;

  privs := ClientToken.GetTokenPrivileges;
  for i := 0 to aRequiredPrivileges.Count - 1 do
  begin
    priv := privs.GetPrivByLUID(aRequiredPrivileges.PrivByIdx[i].LUID);


    if Assigned(priv) and priv.Enabled then
    begin
      priv.Privilege_Used_For_Access := True;

      if not RequiresAllPrivs then
      begin
        Result := True;
        privs.Free;
        exit;
      end;
    end
    else
    begin
      if Assigned(priv) then
        priv.Privilege_Used_For_Access := False;
      if RequiresAllPrivs then
      begin
        Result := False;
        privs.Free;
        exit;
      end;
    end;
  end;

  privs.Free;
end;


//instance function related to token context
class procedure TJwSecurityToken.ImpersonateAnonymousToken(
  const Thread: TJwThreadHandle);
begin
  if not jwaWindows.ImpersonateAnonymousToken(Thread) then
    raise EJwsclSecurityException.CreateFmtEx(
      RsTokenFailedImpAnonymousToken,
      'ImpersonateAnonymousToken', ClassName, RsUNToken, 0, True, []);
end;

class procedure TJwSecurityToken.ImpersonateSelf(
  const anImpersonationLevel: SECURITY_IMPERSONATION_LEVEL);
begin
  if not jwaWindows.ImpersonateSelf(anImpersonationLevel) then
    raise EJwsclSecurityException.CreateFmtEx(RsTokenFailedImpSelf,
      'ImpersonateSelf', ClassName, RsUNToken, 0, True, []);
end;

class procedure TJwSecurityToken.RevertToSelf;
begin
  if not jwaWindows.RevertToSelf then
    raise EJwsclSecurityException.CreateFmtEx(RsTokenFailedRevertSelf,
      'RevertToSelf', ClassName, RsUNToken, 0, True, []);
end;

class procedure TJwSecurityToken.ImpersonateNamedPipeClient(
  hNamedPipe: THandle);
begin
  if not jwaWindows.ImpersonateNamedPipeClient(hNamedPipe) then
    raise EJwsclSecurityException.CreateFmtEx(
      RsTokenFailedImpPipe,
      'ImpersonateNamedPipeClient', ClassName, RsUNToken, 0, True, []);
end;

class function TJwSecurityToken.HasThreadAToken(): boolean;
var
  p: TJwSecurityToken;
begin
  p := nil;
  try
    p := GetThreadToken(TOKEN_QUERY or TOKEN_READ, False);
    Result := Assigned(p);
    if not Result then
      p := GetThreadToken(TOKEN_QUERY or TOKEN_READ, True);
    Result := Assigned(p);

  except
    Result := False;
  end;

  p.Free;
end;

class function TJwSecurityToken.GetThreadToken(
  const aDesiredAccess: TJwAccessMask;
  const anOpenAsSelf: boolean): TJwSecurityToken;
begin
  try
    Result := TJwSecurityToken.CreateTokenByThread(0, aDesiredAccess,
      anOpenAsSelf);
  except
    Result := nil;
  end;
end;



function TJwSecurityToken.GetTokenType: TOKEN_TYPE;
var
  ptrTokenType: PTOKEN_TYPE;
begin
  //Raises an exception if errors occur
  Self.GetTokenInformation(fTokenHandle,
(*{$IFDEF SL_OMIT_SECTIONS}JwsclLibrary.{$ELSE}
    JwsclTypes.
{$ENDIF}     *)
    JwaVista.TokenType, Pointer(ptrTokenType));

  Result := ptrTokenType^;

  HeapFree(GetProcessHeap, 0, ptrTokenType);
end;

procedure TJwSecurityToken.CheckTokenPrivileges(Privileges: array of string);
var
  privSet: TJwPrivilegeSet;
  i: integer;
begin
  privSet := GetTokenPrivileges;


  for i := LOW(Privileges) to High(Privileges) do
  begin
    if not Assigned(privSet.PrivByName[Privileges[i]]) then
    begin
      FreeAndNil(privSet);
      raise EJwsclPrivilegeCheckException.CreateFmtEx(
        RsTokenPrivilegeNotFound, 'CheckTokenPrivileges', ClassName, RsUNToken,
        0, False, [Privileges[i]]);
    end;
  end;

  privSet.Free;
end;

procedure TJwSecurityToken.FreeObjectMemory(var anObject: TObject);
begin
  //   if fPrivelegesList.Remove(anObject) < 0 then
  //     fSecurityIDList.Remove(anObject);
end;


function TJwSecurityToken.IsPrivilegeAvailable(Priv: string): boolean;
var
  privSet: TJwPrivilegeSet;
begin
  privSet := GetTokenPrivileges;

  Result := Assigned(privSet.PrivByName[Priv]);

  privSet.Free;
end;

function TJwSecurityToken.GetIsRestricted: boolean;
begin
  Result := True;
  SetLastError(0);
  if not IsTokenRestricted(TokenHandle) then
  begin
    if GetLastError() <> 0 then
      raise EJwsclInvalidTokenHandle.CreateFmtEx(
        RsWinCallFailed,
        'IsRestricted', ClassName, RsUNToken,
        0, True, ['IsTokenRestricted']);

    Result := False;
  end;
end;



procedure TJwSecurityToken.CheckTokenAccessType(aDesiredAccessMask:
  TJwAccessMask;
  StringMask, SourceProc: TJwString);

  function IntToBin(Value: Cardinal): string;
  var
    i: integer;
  begin
    Result := '';
    for i := sizeof(Cardinal) * 8 downto 0 do
      if Value and (1 shl i) <> 0 then
        Result := Result + '1'
      else
        Result := Result + '0';
  end;

begin
  if (Self.AccessMask and aDesiredAccessMask) <> aDesiredAccessMask then
    raise EJwsclAccessTypeException.CreateFmtEx(
      RsTokenCheckAccessTypeText
      ,SourceProc,ClassName, RsUNToken, 0,
      False,
      [IntToBin(aDesiredAccessMask), StringMask, IntToBin(AccessMask),SourceProc]);
end;


constructor TJwSecurityTokenStatistics.Create(stats: TTokenStatistics);
begin
  with stats do
  begin
    fTokenId := TJwSecurityToken.CopyLUID(TokenId);
    fAuthenticationId := TJwSecurityToken.CopyLUID(AuthenticationId);
    fExpirationTime := ExpirationTime;
    fTOKEN_TYPE := TokenType;
    fSECURITY_IMPERSONATION_LEVEL := SECURITY_IMPERSONATION_LEVEL;
    fDynamicCharged := DynamicCharged;
    fDynamicAvailable := DynamicAvailable;
    fGroupCount := GroupCount;
    fPrivilegeCount := PrivilegeCount;
    fModifiedId := TJwSecurityToken.CopyLUID(ModifiedId);
  end;
end;

function TJwSecurityTokenStatistics.GetText: TJwString;

  function FileTime2DateTime(FileTime: FileTime): TDateTime;
  var
    LocalFileTime: TFileTime;
    SystemTime: TSystemTime;
  begin
    FileTimeToLocalFileTime(FileTime, LocalFileTime);
    FileTimeToSystemTime(LocalFileTime, SystemTime);

    Result := SystemTimeToDateTime(SystemTime);
  end;

  function GetExpirationTimeString: TJwString;
  var
    F: FileTIME;
  begin
    if fExpirationTime.QuadPart >= $7FFFFFFFFFFFFFFF then
    begin
      Result := RsInfinite;
      exit;
    end;
    F.dwLowDateTime  := fExpirationTime.LowPart;
    F.dwHighDateTime := fExpirationTime.HighPart;
    try
      Result := DateTimeToStr(FileTime2DateTime(F));
    except
      on E: EConvertError do
        Result := RsInfinite;
    end;
  end;

begin
  Result := '';
  {
  RsTokenStatisticsText = 'TokenID: %0:s\r\AuthenticationId: %1:s\r\nExpirat' +
    'ionTime: %2:s\r\nToken type: %3:d\r\nImpersonation level: 0x%4:x\r\nDynam' +
    'ic charged: 0x%5:x\r\nDynamic available: 0x%6:x\r\nGroup count: %7:d\r\nP' +
    'rivilege count: %8:d\r\nModified ID: %9:s\r\n';
 
  }

  result := JwFormatString(RsTokenStatisticsText,
    [TJwPrivilege.LUIDtoText(fTokenId), //0
     TJwPrivilege.LUIDtoText(fAuthenticationId), //1
     GetExpirationTimeString, //2
     Integer(fTOKEN_TYPE), //3
     Integer(fSECURITY_IMPERSONATION_LEVEL), //4
     Integer(fDynamicCharged), //5
     Integer(fDynamicAvailable), //6
     fGroupCount, //7
     fPrivilegeCount, //8
     TJwPrivilege.LUIDtoText(fModifiedId) //9
      ]);
  {
  Result := Result + 'TokenID: ' + TJwPrivilege.LUIDtoText(fTokenId) + #13#10;
  Result := Result + 'AuthenticationId: ' + TJwPrivilege.LUIDtoText(
    fAuthenticationId) + #13#10;

  Result := Result + 'ExpirationTime: ' + GetExpirationTimeString + #13#10;
  Result := Result + 'TOKEN_TYPE: 0x' + IntToHex(integer(fTOKEN_TYPE), 2) + #13#10;
  Result := Result + 'SECURITY_IMPERSONATION_LEVEL: 0x' + IntToHex(
    integer(fSECURITY_IMPERSONATION_LEVEL), 2) + #13#10;
  Result := Result + 'DynamicCharged: 0x' + IntToHex(fDynamicCharged, 2) + #13#10;
  Result := Result + 'DynamicAvailable: 0x' + IntToHex(
    fDynamicAvailable, 2) + #13#10;
  Result := Result + 'GroupCount: 0x' + IntToHex(fGroupCount, 2) + #13#10;
  Result := Result + 'PrivilegeCount: 0x' + IntToHex(fPrivilegeCount, 2) + #13#10;
  Result := Result + 'ModifiedId: ' + TJwPrivilege.LUIDtoText(fModifiedId) + #13#10;      }
end;

constructor TJwSecurityToken.CreateLogonUser(sUsername, sDomain,
  sPassword: TJwString; dwLogonType, dwLogonProvider: Cardinal);

var
  bResult: boolean;
begin
  Create;

  fShared := False;
  fAccessMask := TOKEN_ALL_ACCESS;

  bResult :=
{$IFDEF UNICODE}LogonUserW{$ELSE}
    LogonUserA
{$ENDIF}
    (TJwPChar(sUserName), TJwPChar(sDomain), TJwPChar(sPassword),
    dwLogonType, dwLogonProvider, fTokenHandle);

  if (not bResult) then
    raise EJwsclSecurityException.CreateFmtEx(
      RsWinCallFailed,
      'CreateLogonUser', ClassName, RsUNToken,
      0, True, ['LogonUser']);
end;




constructor TJwSecurityToken.CreateNewToken(const aDesiredAccess: TJwAccessMask;
  const anObjectAttributes: TObjectAttributes;
  const anAuthenticationId: TLUID; const anExpirationTime: int64;
  anUser: TJwSecurityId; aGroups: TJwSecurityIdList;
  aPrivileges: TJwPrivilegeSet; anOwner, aPrimaryGroup: TJwSecurityId;
  aDefaultDACL: TJwDAccessControlList; aTokenSource: TTokenSource);
var
  ttTokenUser: TTokenUser;
  pGroups: PTOKEN_GROUPS;
  pPrivileges: PTOKEN_PRIVILEGES;
  ttTokenOwner: TTokenOwner;
  ttTokenPrimaryGroup: TTokenPrimaryGroup;
  ttTokenDefaultDACL: TTokenDefaultDacl;

  res: Cardinal;
  actualToken: TJwSecurityToken;
begin
  fShared := False;

  actualToken := TJwSecurityToken.CreateTokenEffective(TOKEN_QUERY or
    TOKEN_READ);

  if not Assigned(anOwner) then
    anOwner := actualToken.GetTokenOwner;
  ttTokenOwner.Owner := anOwner.CreateCopyOfSID;

  if not Assigned(aPrimaryGroup) then
    aPrimaryGroup := actualToken.GetPrimaryGroup;
  ttTokenPrimaryGroup.PrimaryGroup := aPrimaryGroup.CreateCopyOfSID;


  FillChar(ttTokenUser.User, sizeof(ttTokenUser.User), 0);
  if not Assigned(anUser) then
    anUser := actualToken.GetTokenUser;
  ttTokenUser.User.Sid := anUser.CreateCopyOfSID;

  if not Assigned(aGroups) then
  begin
    pGroups := nil;
    aGroups := actualToken.GetTokenGroups;
    if Assigned(aGroups) then
    begin
      pGroups := aGroups.Create_PTOKEN_GROUPS;
      aGroups.Free;
    end;
  end
  else
    pGroups := aGroups.Create_PTOKEN_GROUPS;

  if not Assigned(aPrivileges) then
  begin
    pPrivileges := nil;
    aPrivileges := actualToken.GetTokenPrivileges;
    if Assigned(aPrivileges) then
    begin
      pPrivileges := aPrivileges.Create_PTOKEN_PRIVILEGES;
      aPrivileges.Free;
    end;
  end
  else
    pPrivileges := aPrivileges.Create_PTOKEN_PRIVILEGES;

  if not Assigned(aDefaultDACL) then
  begin
    ttTokenDefaultDACL.DefaultDacl := nil;
    aDefaultDACL := actualToken.GetTokenDefaultDacl;
    if Assigned(aDefaultDACL) then
    begin
      ttTokenDefaultDACL.DefaultDacl := aDefaultDACL.Create_PACL;
      aDefaultDACL.Free;
    end;
  end
  else
    ttTokenDefaultDACL.DefaultDacl := aDefaultDACL.Create_PACL;


  try
    res := ZwCreateToken(@fTokenHandle,//TokenHandle: PHANDLE;
      aDesiredAccess,//DesiredAccess: ACCESS_MASK;
      @anObjectAttributes,//ObjectAttributes: POBJECT_ATTRIBUTES;
      TokenPrimary,//Type_: TOKEN_TYPE;
      @anAuthenticationId,//AuthenticationId: PLUID;
      @anExpirationTime,//ExpirationTime: PLARGE_INTEGER;
      @ttTokenUser,//User: PTOKEN_USER;
      pGroups,//Groups: PTOKEN_GROUPS;
      pPrivileges,//Privileges: PTOKEN_PRIVILEGES;
      @ttTokenOwner,//Owner: PTOKEN_OWNER;
      @ttTokenPrimaryGroup,//PrimaryGroup: PTOKEN_PRIMARY_GROUP;
      @ttTokenDefaultDACL,//DefaultDacl: PTOKEN_DEFAULT_DACL;
      @aTokenSource //Source: PTOKEN_SOURCE):
      );

    res := RtlNtStatusToDosError(Res);
    SetLastError(res);

    if res <> 0 then
      raise EJwsclWinCallFailedException.CreateFmtEx(
        RsWinCallFailed,
        'CreateNewToken', ClassName, RsUNToken,
        0, True, ['ZwCreateToken']);
  finally
    TJwSecurityId.FreeSID(ttTokenOwner.Owner);
    TJwSecurityId.FreeSID(ttTokenPrimaryGroup.PrimaryGroup);
    TJwSecurityId.FreeSID(ttTokenUser.User.Sid);
    aGroups.Free_PTOKEN_GROUPS(pGroups);
    aPrivileges.Free_PTOKEN_PRIVILEGES(pPrivileges);
    aDefaultDACL.Free_PACL(ttTokenDefaultDACL.DefaultDacl);
  end;
end;



class function TJwSecurityToken.Create_OBJECT_ATTRIBUTES(
  const aRootDirectory: THandle; const anObjectName: TJwString;
  const anAttributes: Cardinal;
  const aSecurityDescriptor: TJwSecurityDescriptor;
  const anImpersonationLevel: TSecurityImpersonationLevel;
  const aContextTrackingMode: SECURITY_CONTEXT_TRACKING_MODE;
  const anEffectiveOnly: boolean): TObjectAttributes;
var
  sqos: PSECURITY_QUALITY_OF_SERVICE;
begin
  FillChar(Result, sizeof(Result), 0);
  Result.Length := sizeof(Result);
  Result.RootDirectory := aRootDirectory;
  Result.Attributes := anAttributes;
  Result.ObjectName := JwCreateUnicodeString(anObjectName);

  if Assigned(aSecurityDescriptor) then
    Result.SecurityDescriptor := aSecurityDescriptor.Create_SD(False);

  GetMem(sqos, sizeof(SECURITY_QUALITY_OF_SERVICE));
  sqos.Length := sizeof(SECURITY_QUALITY_OF_SERVICE);
  sqos.ImpersonationLevel := anImpersonationLevel;
  sqos.ContextTrackingMode := aContextTrackingMode;
  sqos.EffectiveOnly := anEffectiveOnly;

  Result.SecurityQualityOfService := sqos;
end;

class procedure TJwSecurityToken.Free_OBJECT_ATTRIBUTES(
  anObjectAttributes: TObjectAttributes);
begin
  if (anObjectAttributes.ObjectName <> nil) then
    RtlFreeUnicodeString(anObjectAttributes.ObjectName);

  if (anObjectAttributes.SecurityDescriptor <> nil) then
    TJwSecurityDescriptor.Free_SD(PSECURITY_DESCRIPTOR(
      anObjectAttributes.SecurityDescriptor));

  if (anObjectAttributes.SecurityQualityOfService <> nil) then
    FreeMem(anObjectAttributes.SecurityQualityOfService);

  FillChar(anObjectAttributes, sizeof(anObjectAttributes), 0);
end;

function TJwSecurityToken.GetSecurityDescriptor(
  const SecurityFlags: TJwSecurityInformationFlagSet): TJwSecurityDescriptor;
begin
  CheckTokenHandle('GetSecurityDescriptor');
  CheckTokenAccessType(TOKEN_READ, 'TOKEN_READ',
    'GetSecurityDescriptor');

  result := TJwSecureGeneralObject.GetSecurityInfo(TokenHandle,
    SE_KERNEL_OBJECT,SecurityFlags);
end;

procedure TJwSecurityToken.SetSecurityDescriptor(
  const SecurityFlags: TJwSecurityInformationFlagSet;
  const SecurityDescriptor: TJwSecurityDescriptor);
begin
  CheckTokenHandle('SetSecurityDescriptor');
  CheckTokenAccessType(TOKEN_WRITE, 'TOKEN_WRITE',
    'GetSecurityDescriptor');

  TJwSecureGeneralObject.SetSecurityInfo(TokenHandle,
    SE_KERNEL_OBJECT,SecurityFlags,SecurityDescriptor);
end;

{$ENDIF SL_INTERFACE_SECTION}

{$IFNDEF SL_OMIT_SECTIONS}



initialization
{$ENDIF SL_OMIT_SECTIONS}

{$IFNDEF SL_INITIALIZATION_SECTION}
  //warning do not add here code lines!!
  JwProcessHeap := GetProcessHeap;
  //add code from here
  JwCheckAdministratorAccess;
{$ENDIF SL_INITIALIZATION_SECTION}


{$IFNDEF SL_OMIT_SECTIONS}
end.
{$ENDIF SL_OMIT_SECTIONS}
