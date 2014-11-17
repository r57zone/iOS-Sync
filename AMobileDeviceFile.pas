{*******************************************************}
{                                                       }
{       IOS Device FileStream Class                     }
{                                                       }
{       author  :  LAHCS                                }
{                                                       }
{       E-Mail  :  lahcs@qq.com                         }
{                                                       }
{       QQ      :  307643816                            }
{                                                       }
{       Copy Right (C) 2013                             }
{                                                       }
{*******************************************************}
{ ReferenceList£º
  [The iPhone wiki] http://theiphonewiki.com/wiki/MobileDevice_Library
  [Manzana] http://manzana.googlecode.com/
}
unit AMobileDeviceFile;

interface

uses
  Windows, Classes, SysUtils, AMobileDevice,AMoblieDeviceFuncModule, AMoblieDeviceModuleDef;

type
  TOpenMode = (
    omNone = 0,
    omRead = 2,
    omWrite = 3
  );
  
type
  TProgressStep = procedure (Sender: TObject;Step: Cardinal) of object;

  TAMobileDeviceHandleStream = class(TStream)
  private
    FLastErrCode : Integer;
    FConn : p_afc_connection;
    FHandle: Int64;
    FOpenMode : TOpenMode;
    FPosition: Integer;
    FOnProgressStep : TProgressStep;
  private
    function GetPosition: Int64;
    procedure SetPosition(const Pos: Int64);
    procedure SetSize(NewSize: Longint); override;
    procedure SetSize(const NewSize: Int64); override;  
    procedure FlushBuffer;
  protected
    constructor Create(Conn: p_afc_connection;AHandle: Int64; Mode: TOpenMode);
    destructor Destroy; override;
  public
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    property Handle: Int64 read FHandle;
  public
    property OnProgressStep : TProgressStep
        read FOnProgressStep
       write FOnProgressStep;
  end;

  TAMobileDeviceFileStream = class(TAMobileDeviceHandleStream)
  protected
    FLastErrCode : Cardinal;
  public
    constructor Create(Device: TAMoblieDevice;
      Path: string; Mode: TOpenMode); overload;
    destructor Destroy; override;
  published
    property OnProgressStep;
  end;

implementation

{ TAMobileDeviceHandleStream }

constructor TAMobileDeviceHandleStream.Create(Conn: p_afc_connection;
  AHandle: Int64; Mode: TOpenMode);
begin
  FConn := Conn;
  FHandle := AHandle;
  FOpenMode := Mode;
end;

destructor TAMobileDeviceHandleStream.Destroy;
begin
  if FHandle <> 0 then
  begin
    FLastErrCode := FuncModule.lpf_AFCFileRefClose(FConn,FHandle);
    FHandle := 0;
  end;  
  inherited Destroy;
end;

function TAMobileDeviceHandleStream.GetPosition: Int64;
var
  intPos : UINT;
begin
  intPos := 0;
  FuncModule.lpf_AFCFileRefTell(FConn,FHandle,intPos);
  Result := intPos;
end;

function TAMobileDeviceHandleStream.Read(var Buffer;
  Count: Integer): Longint;
var
  rLen : UINT;
begin
  Result := 0;
  
  if FOpenMode <> omRead then
    raise Exception.Create('Stream open for write only');

  if Count <= 0 then
    raise Exception.Create('Stream Read Count error');

  rLen := Count;

  FLastErrCode := FuncModule.lpf_AFCFileRefRead(FConn,FHandle,@Buffer,rLen);
  if FLastErrCode <> 0 then
    raise Exception.Create('AFCFileRefRead error = 0x' + IntToHex(FLastErrCode,8));

  if Assigned(FOnProgressStep) then
    FOnProgressStep(Self,rLen);

  Result := rLen;
end;

function TAMobileDeviceHandleStream.Seek(const Offset: Int64;
  Origin: TSeekOrigin): Int64;
begin
  Result := 0;
  FLastErrCode := FuncModule.lpf_AFCFileRefSeek(FConn, FHandle, Offset, 0);
  Result := Offset;
end;

procedure TAMobileDeviceHandleStream.SetSize(NewSize: Integer);
begin
  SetSize(Int64(NewSize));
end;

procedure TAMobileDeviceHandleStream.SetPosition(const Pos: Int64);
begin
  Seek(Pos, soBeginning);
end;

procedure TAMobileDeviceHandleStream.SetSize(const NewSize: Int64);
begin
  FLastErrCode := FuncModule.lpf_AFCFileRefSetFileSize(FConn,FHandle,NewSize);
end;

function TAMobileDeviceHandleStream.Write(const Buffer;
  Count: Integer): Longint;  
var
  rLen : Cardinal;
begin
  if FOpenMode <> omWrite then
    raise Exception.Create('Stream open for read only');

  rLen := Count;
  FLastErrCode := FuncModule.lpf_AFCFileRefWrite(FConn,FHandle,@Buffer,rLen);

  if Assigned(FOnProgressStep) then
    FOnProgressStep(Self,rLen);

  Result := rLen;
end;

procedure TAMobileDeviceHandleStream.FlushBuffer;
begin
  FLastErrCode := FuncModule.lpf_AFCFlushData(FConn,FHandle);
end;

{ TAMobileDeviceFileStream }

constructor TAMobileDeviceFileStream.Create(Device: TAMoblieDevice;
  Path: string; Mode: TOpenMode);
var
  intFileHandle : Int64;
  fullpath : string;
begin
  //fullpath := Device.FillPath(Device.CurrentDirectory,Path);
  FLastErrCode := FuncModule.lpf_AFCFileRefOpen(Device.AFConnection,PChar(Path),ord(Mode),0,intFileHandle);
  if FLastErrCode <> 0 then
    raise Exception.Create('AFCFileRefOpen failed with error 0x' + IntToHex(FLastErrCode,8));

  inherited Create(Device.AFConnection, intFileHandle, Mode);
end;

destructor TAMobileDeviceFileStream.Destroy;
begin
  inherited Destroy;
end;

end.
