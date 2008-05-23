{******************************************************************************}
{ JEDI API example WinLogon Notification Package  							   }
{ http://jedi-apilib.sourceforge.net										   }
{ 																			   }
{ Obtained through: Joint Endeavour of Delphi Innovators (Project JEDI)        }
{ 																			   }
{ Author(s): Christian Wimmer, stOrM!					  					   }
{ Creation date: 23th May 2008 					 							   }
{ Last modification date:	23th May 2008									   }
{ 																			   }
{ Description: Demonstrates how to create a Winlogon Notification Package and  }
{    draws a transparent window inside Winlogon Process	containing a 		   }
{ 	 32BIT Bitmap							   								   }
{ Preparations: JwaWindows, any layer based graphic apllication e.g. Gimp or   }
{ 				Adobe Photoshop					   							   }
{ Article link:   							   							       }
{ http://blog.delphi-jedi.net/2008/05/24/									   }
{     how-to-create-a-winlogon-notification-package							   }
{ Version history: 23/05/2008 first release        						       }
{ 																			   }
{ No license. Use this example with no warranty at all and on your own risk.   }
{ This example is just for learning purposes and should not be used in 		   }
{ productive environments.													   }
{ The code has surely some errors that need to be fixed. In such a case	   	   }
{ you can contact the author(s) through the JEDI API hompage, the mailinglist  }
{ or via the article link.												       }
{ 																			   }
{ The JEDI API Logo is copyrighted and must not be used without permission     }
{******************************************************************************}
unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls;

type
  TForm1 = class(TForm)
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    function  ResLoader(RSectionsName : PChar; RName : String) : TBitmap;
    procedure ExecuteBlending;
  public
    { Public declarations }
  protected
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
{$R Logo.res}

function TForm1.ResLoader(RSectionsName : PChar; RName : String) : TBitmap;
  var
    Stream: TResourceStream;
  begin
    Stream := TResourceStream.Create(hInstance, RName, PChar(RSectionsName));
    try
      result := TBITMAP.Create;
      Result.LoadFromStream(Stream);
    finally
      Stream.Free;
    end;
  end;

procedure TForm1.ExecuteBlending;
var
  BlendFunction: TBlendFunction;
  BitmapPos: TPoint;
  BitmapSize: TSize;
  exStyle: DWORD;
  Bitmap: TBitmap;
  Bit2  : TBitmap;
begin
  // Enable window layering
  exStyle := GetWindowLongA(Handle, GWL_EXSTYLE);
  if (exStyle and WS_EX_LAYERED = 0) then
    SetWindowLong(Handle, GWL_EXSTYLE, exStyle or WS_EX_LAYERED);

  Bitmap := TBitmap.Create;
  Bit2 := ResLoader(PChar('DIB')
  try
    Bitmap.Assign(Bit2, PChar('JEDILOGO')));

    ASSERT(Bitmap.PixelFormat = pf32bit, 'Wrong bitmap format - must be 32 bits/pixel');

    // Resize form to fit bitmap
    ClientWidth := Bitmap.Width;
    ClientHeight := Bitmap.Height;

    // Position bitmap on form
    BitmapPos := Point(0, 0);
    BitmapSize.cx := Bitmap.Width;
    BitmapSize.cy := Bitmap.Height;

    // Setup alpha blending parameters
    BlendFunction.BlendOp := AC_SRC_OVER;
    BlendFunction.BlendFlags := 0;
    BlendFunction.SourceConstantAlpha := 255;
    BlendFunction.AlphaFormat := AC_SRC_ALPHA;

    // ... and action!
    UpdateLayeredWindow(Handle, 0, nil, @BitmapSize, Bitmap.Canvas.Handle,
      @BitmapPos, 0, @BlendFunction, ULW_ALPHA);
    Show;

    // Setzt Fenster an die vorderste Front
    SetWindowPos(Handle, HWND_TOPMOST, Left, Top, Width, Height,
    SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);

    // Setzt Parent auf den Desktop
    SetWindowLong(Handle, GWL_HWNDPARENT, 0);

    // Versteckt das Fenster in der Taskleiste
    SetWindowLong(Handle, GWL_EXSTYLE,
    GetWindowLong(Handle, GWL_EXSTYLE) or
    WS_EX_TOOLWINDOW and not WS_EX_APPWINDOW);      

  finally
    Bitmap.Free;
    Bit2.Free;
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  ExecuteBlending;
end;

end.
