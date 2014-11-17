{*******************************************************}
{                                                       }
{       IOS Device Management Class                     }
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
unit AMoblieDeviceModule;

interface

uses
  Windows, SysUtils, IniFiles, AMobileDevice, AMoblieDeviceFuncModule, AMoblieDeviceModuleDef;

type
  TDeviceConnectEvent = procedure(Sender: TObject;Device: TAMoblieDevice) of object;

  TAMobileDeviceModule = class(TObject)
  private
    FLastErrCode : Cardinal;
    FOnDeciveConnect : TDeviceConnectEvent;
    FOnDeviceDisconnect : TDeviceConnectEvent;
  private
    hiTunesMobileDeviceModule : HMODULE;
    hCoreFoundationModule : HMODULE;
    p_AMDeviceNotification : p_am_device_notification;
  private
    FDeviceList : THashedStringList;
  private
    function GetDevice(Value: Integer):TAMoblieDevice;
    function GetDeviceCount:Integer;
  private
    procedure DoOnNotificationCallBack(value: p_am_device_notification_callback_info);
    procedure DoOnDeviceConnectNotice(device: p_am_device);
    procedure DoOnDeviceDisConnectNotice(device: p_am_device);
    procedure DoOnDeviceOtherNotice(device: p_am_device);
  public
    function InitialModule():Boolean;
    function Subscribe():Boolean;
  public
    constructor Create;
    destructor Destroy; override;
  public
    property OnDeviceConnect : TDeviceConnectEvent
        read FOnDeciveConnect
       write FOnDeciveConnect;
       
    property OnDeviceDisconnect : TDeviceConnectEvent
        read FOnDeviceDisconnect
       write FOnDeviceDisconnect;

    property Item[index:Integer]:TAMoblieDevice
        read GetDevice;

    property Count : Integer
        read GetDeviceCount;
  end;

var
  lpAMobileDeviceModule : TAMobileDeviceModule;

implementation

function SetDllDirectory(lpPathName:PWideChar): Bool; stdcall; external 'kernel32.dll' name 'SetDllDirectoryW';

function GetArrayStr(Value:array of UCHAR):string;
var
  i : Integer;
begin
  Result := '';
  for i:= 0 to Length(Value) - 1 do
  begin
    Result := Result + IntToHex(Value[i],2); 
  end;   
end;

procedure AMDeviceNotificationCallback(
  value: p_am_device_notification_callback_info);cdecl;
begin
  lpAMobileDeviceModule.DoOnNotificationCallBack(value);
end;  

procedure LoadiTunesMobileDeviceModule(var hiTunesMobileDeviceModule:HMODULE;var fun_pointer:Pointer;fun_name:PChar);
begin
  if hiTunesMobileDeviceModule = 0 then
    Exit;
  fun_pointer := GetProcAddress(hiTunesMobileDeviceModule,fun_name);
  if fun_pointer = nil then
  begin
    FreeLibrary(hiTunesMobileDeviceModule);
    hiTunesMobileDeviceModule := 0;
  end;  
end;

{ TAMobileDeviceModule }

constructor TAMobileDeviceModule.Create;
begin
  FDeviceList := THashedStringList.Create;  
  FuncModule := TAMoblieDeviceFuncModule.Create;
end;

destructor TAMobileDeviceModule.Destroy;
var
  i : Integer;
begin
  for i:= 0 to FDeviceList.Count - 1 do
    TAMoblieDevice(FDeviceList.Objects[i]).Destroy;
    
  FDeviceList.Clear;
  FuncModule.Destroy;
  inherited;
end;

function TAMobileDeviceModule.InitialModule:Boolean;
var
  strEnvironmentPath : WideString;
  FMDS_PATH , FAAS_PATH : WideString;
begin
  Result := False;
  FLastErrCode := $FFFFFFFF;
  
  strEnvironmentPath := GetEnvironmentVariable('CommonProgramFiles');

  FMDS_PATH := strEnvironmentPath + MDS_PATH;
  FAAS_PATH := strEnvironmentPath + AAS_PATH;

  SetDllDirectory(PWideChar(FAAS_PATH));

  hiTunesMobileDeviceModule := LoadLibraryW(PWideChar(FMDS_PATH + 'iTunesMobileDevice.dll'));
  if hiTunesMobileDeviceModule <> 0 then
  begin
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AMDeviceNotificationSubscribe,'AMDeviceNotificationSubscribe');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AMDeviceNotificationUnsubscribe,'AMDeviceNotificationUnsubscribe');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AMDeviceConnect,'AMDeviceConnect');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AMDeviceDisconnect,'AMDeviceDisconnect');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AMDeviceIsPaired,'AMDeviceIsPaired');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AMDeviceValidatePairing,'AMDeviceValidatePairing');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AMDeviceStartSession,'AMDeviceStartSession');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AMDeviceStopSession,'AMDeviceStopSession');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AMDeviceStartService,'AMDeviceStartService');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AMDeviceCopyValue,'AMDeviceCopyValue');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCConnectionOpen,'AFCConnectionOpen');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCConnectionClose,'AFCConnectionClose');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCDirectoryOpen,'AFCDirectoryOpen');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCDirectoryRead,'AFCDirectoryRead');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCDirectoryClose,'AFCDirectoryClose');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCDirectoryCreate,'AFCDirectoryCreate');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCDeviceInfoOpen,'AFCDeviceInfoOpen');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCFileInfoOpen,'AFCFileInfoOpen');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCKeyValueRead,'AFCKeyValueRead');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCKeyValueClose,'AFCKeyValueClose');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCRemovePath,'AFCRemovePath');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCRenamePath,'AFCRenamePath');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCFileRefOpen,'AFCFileRefOpen');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCFileRefClose,'AFCFileRefClose');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCFileRefRead,'AFCFileRefRead');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCFileRefWrite,'AFCFileRefWrite');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCFlushData,'AFCFlushData');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCFileRefSeek,'AFCFileRefSeek');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCFileRefTell,'AFCFileRefTell');
    LoadiTunesMobileDeviceModule(hiTunesMobileDeviceModule,@FuncModule.lpf_AFCFileRefSetFileSize,'AFCFileRefSetFileSize');
  end
  else
    Exit;

  hCoreFoundationModule :=  LoadLibraryW(PWideChar(FAAS_PATH + 'CoreFoundation.dll'));
  if hCoreFoundationModule <> 0 then
    begin                                                   
      LoadiTunesMobileDeviceModule(hCoreFoundationModule,@FuncModule.lpf_CFStringCreateWithCString,'CFStringCreateWithCString');
      LoadiTunesMobileDeviceModule(hCoreFoundationModule,@FuncModule.lpf_CFPropertyListCreateFromXMLData,'CFPropertyListCreateFromXMLData');
      LoadiTunesMobileDeviceModule(hCoreFoundationModule,@FuncModule.lpf_CFPropertyListCreateXMLData,'CFPropertyListCreateXMLData');
      Result := True;
    end
  else
    Exit;
end;    

function TAMobileDeviceModule.Subscribe: Boolean;
begin
  Result := False;
  FLastErrCode := FuncModule.lpf_AMDeviceNotificationSubscribe(AMDeviceNotificationCallback,0,0,0,@p_AMDeviceNotification);
  if FLastErrCode = 0 then
    Result := True;
end;

procedure TAMobileDeviceModule.DoOnNotificationCallBack(
  value: p_am_device_notification_callback_info);
begin
  case value.msg of
    ADNCI_MSG_CONNECTED : DoOnDeviceConnectNotice(value.dev);
    ADNCI_MSG_DISCONNECTED : DoOnDeviceDisConnectNotice(value.dev);
    ADNCI_MSG_UNKNOWN : DoOnDeviceOtherNotice(value.dev);
  end;
end;

procedure TAMobileDeviceModule.DoOnDeviceConnectNotice(
  device: p_am_device);
var
  ADevice : TAMoblieDevice;
  strHashKey : string;
  intDeviceIndex : Integer;
begin
  intDeviceIndex := 0;
  strHashKey :=  inttoHex(device.device_id,8) + inttoHex(device.product_id,8);
  if FDeviceList.Find(strHashKey,intDeviceIndex) then
  begin
    ADevice := TAMoblieDevice(FDeviceList.Objects[intDeviceIndex]);
    if Assigned(ADevice) then
    begin
      ADevice.Device := device;
      ADevice.ReConnect := True;
    end;  
  end
  else
  begin
    ADevice := TAMoblieDevice.Create(device);
    FDeviceList.AddObject(strHashKey,ADevice);
  end;

  if Assigned(FOnDeciveConnect) then
    FOnDeciveConnect(Self,ADevice);
end;

procedure TAMobileDeviceModule.DoOnDeviceDisConnectNotice(
  device: p_am_device);
var
  ADevice : TAMoblieDevice;
  strHashKey : string;
  intDeviceIndex : Integer;
begin
  intDeviceIndex := 0;
  strHashKey :=  inttoHex(device.device_id,8) + inttoHex(device.product_id,8);
  if FDeviceList.Find(strHashKey,intDeviceIndex) then
  begin
    ADevice := TAMoblieDevice(FDeviceList.Objects[intDeviceIndex]);
    if Assigned(ADevice) then
    begin
      ADevice.DisConnect;
      if Assigned(FOnDeviceDisconnect) then
        FOnDeviceDisconnect(Self,ADevice);
    end;  
  end;
end;

procedure TAMobileDeviceModule.DoOnDeviceOtherNotice(device: p_am_device);
var
  ADevice : TAMoblieDevice;
  strHashKey : string;
  intDeviceIndex : Integer;
begin
  intDeviceIndex := 0;
  strHashKey :=  inttoHex(device.device_id,8) + inttoHex(device.product_id,8);
  if FDeviceList.Find(strHashKey,intDeviceIndex) then
  begin
    ADevice := TAMoblieDevice(FDeviceList.Objects[intDeviceIndex]);
    if Assigned(ADevice) then
    begin
      ADevice.DisConnect;
    end;  
  end;
end;

function TAMobileDeviceModule.GetDevice(Value: Integer): TAMoblieDevice;
begin
  if (Value < 0) or (Value > FDeviceList.Count - 1) then
  begin
    Result := nil;
    Exit;
  end;
  Result := TAMoblieDevice(FDeviceList.Objects[Value]);
end;

function TAMobileDeviceModule.GetDeviceCount: Integer;
begin
  Result := FDeviceList.Count;
end;

end.
 