{*******************************************************}
{                                                       }
{       Single IOS Device Control Class                 }
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
{ ReferenceList：
  [The iPhone wiki] http://theiphonewiki.com/wiki/MobileDevice_Library
  [Manzana] http://manzana.googlecode.com/
}

unit AMobileDevice;

interface

uses
  ComCtrls, SysUtils, Classes, TypInfo,
  AMoblieDeviceFuncModule,
  AMoblieDeviceModuleDef;

type
  TNameEnum = (st_size,st_blocks,st_ifmt);
  TValueEnum = (S_IFDIR,S_IFREG,S_IFBLK,S_IFCHR,S_IFIFO,S_IFLNK,S_IFMT,S_IFSOCK);

  TFileType =
  (
    ftFile = 1,
    ftFolder = 2,
    ftBlockDevice = 3,
    ftCharDevice = 4,
    ftFIFO = 5,
    ftLink = 6,
    ftFileMask = 7,
    ftSocket = 8,
    ftUnknown = 9
  );

  TJailBreakedStatus = (jbsUnknown, jbsTrue, jbsFalse); 

  TDeviceDetailInfo = record
    DeviceName  : string; //设备名称  'DeviceName'
    DeviceClass : string; //设备类型  'DeviceClass'
    ProductType : string; //产品类型  'ProductType'
    ProductVersion : string; //系统版本 'ProductVersion'
    SerialNumber   : string; //序列号 'SerialNumber'
    ActivationState : string; //激活信息 'ActivationState'
    BasebandVersion : string; //基带版本 'BasebandVersion'
    BuildVersion    : string; //产品版本 'BuildVersion'
    FirmwareVersion : string; //固件版本 'FirmwareVersion'
    IMEI            : string; //  'InternationalMobileEquipmentIdentity'
    ICCID           : string; //  'IntegratedCircuitCardIdentity'
    IMSI            : string; //  'InternationalMobileSubscriberIdentity'
    ModelNumber     : string; //设备型号 'ModelNumber'
    PhoneNumber     : string; //电话号码 'PhoneNumber'
    SIMStatus       : string; //SIM卡状态 'SIMStatus'
  end;

type
  TModuleMessage = procedure(Sender: TObject; Msg: string) of object;

  TAMoblieDevice = class(TObject)
  private
    FReConnect : Boolean;
    FDevice : p_am_device;     
    FDeviceDetailInfo : TDeviceDetailInfo;
    FLastErrCode : Cardinal;
    FJailBreakedStatus : TJailBreakedStatus;
  private
    FIsConnect : Boolean;
    FCurrentDirectory : string;
    FActivationState : string;
    FAFCHandle : p_afc_connection;
    FAFConnection : p_afc_connection;
  private
    procedure GetDeviceDetailInfo();
    function CFStringToCString(CFString:Pointer):string;
    procedure InternalDeleteDirectory(Path: string);
  public
    function GetAMDeviceCopyValue(device: p_am_device; Value:string):string;
    function IsDirectory(Path: string):Boolean;
    function Exists(Path: string):Boolean;
    procedure GetFileInfo(Path: string;var Size:Integer;var IsDirectory:Boolean);overload;
    procedure GetFileInfo(Path: string;Dest:TStrings);overload;
    function GetFileType(Path: string):TFileType;
    procedure GetKeyValueMap(dict: Pointer;Dest:TStrings);
    function Get_st_ifmt(Path: string):string;
    procedure GetDirectories(Path: string;Dest:TStrings);
    function CreateDirectory(Path: string):Boolean;
    function GetFileSize(Path: string):Integer;
    procedure GetFiles(Path: string;Dest:TStrings);
    function Rename(SourceName: string;DestName:string):Boolean;
    function GetDirectoryRoot(Path: string):string; 
    function DeleteDirectory(Path: string):Boolean;overload;
    function DeleteDirectory(Path: string;Recursive:Boolean):Boolean;overload;
    function DeleteFile(Path:string):Boolean;
    function GetDeviceInfo():string;
  public
    function FillPath(Path1,Path2:string):string;
  public
    constructor Create(device: p_am_device);
    destructor Destroy; override;
  public
    function Connect():Boolean;
    function DisConnect():Boolean;
  public
    property Device : p_am_device read FDevice write FDevice;
    property DeviceDetailInfo : TDeviceDetailInfo read FDeviceDetailInfo;
    property Connected : Boolean read FIsConnect;
    property ReConnect : Boolean read FReConnect write FReConnect;
    property CurrentDirectory : string read FCurrentDirectory write FCurrentDirectory;
    property JailBreakedStatus : TJailBreakedStatus read FJailBreakedStatus;
    property AFCHandle : p_afc_connection read FAFCHandle;
    property AFConnection : p_afc_connection read FAFConnection;
  end;
  
implementation

{ TAMoblieDevice }

function TAMoblieDevice.Connect: Boolean;
begin
  if FReConnect then
  begin
    FAFCHandle := nil;
    FAFConnection := nil;
  end;    

  Result := False;
  FIsConnect := Result;
  FLastErrCode :=  FuncModule.lpf_AMDeviceConnect(FDevice);
  if FLastErrCode = 1 then
  begin
    FAFCHandle := nil;
    FAFConnection := nil;
    Exit;
  end;

  FLastErrCode := FuncModule.lpf_AMDeviceIsPaired(FDevice);
  if FLastErrCode = 0 then
    begin
      FuncModule.lpf_AMDeviceDisconnect(FDevice);
      FAFCHandle := nil;
      FAFConnection := nil;
      Exit;
    end;

  FLastErrCode := FuncModule.lpf_AMDeviceValidatePairing(FDevice);
  if FLastErrCode <> 0 then
  begin
    FuncModule.lpf_AMDeviceDisconnect(FDevice);
    FAFCHandle := nil;
    FAFConnection := nil;
    Exit;
  end;

  FLastErrCode := FuncModule.lpf_AMDeviceStartSession(FDevice);
  if FLastErrCode = 1 then
  begin
    FuncModule.lpf_AMDeviceDisconnect(FDevice);
    FAFCHandle := nil;
    FAFConnection := nil;
    Exit;
  end;

  FLastErrCode := FuncModule.lpf_AMDeviceStartService(FDevice,FuncModule.lpf_CFStringCreateWithCString(nil,PChar(AFC2_STRING),0),@FAFCHandle,nil);
  if FLastErrCode <> 0  then
    begin
      FLastErrCode := FuncModule.lpf_AMDeviceStartService(FDevice,FuncModule.lpf_CFStringCreateWithCString(nil,PChar(AFC_STRING),0),@FAFCHandle,nil);
      if FLastErrCode <> 0 then
      begin
        FuncModule.lpf_AMDeviceStopSession(FDevice);
        FuncModule.lpf_AMDeviceDisconnect(FDevice);
        FAFCHandle := nil;
        FAFConnection := nil;
        Exit;
      end
      else
        FJailBreakedStatus := jbsFalse;
    end
  else
    FJailBreakedStatus := jbsTrue;

  FLastErrCode := FuncModule.lpf_AFCConnectionOpen(FAFCHandle,0,@FAFConnection);
  if FLastErrCode = 0  then
  begin
    Result := True
  end;
  
  FIsConnect := Result;
  Self.GetDeviceDetailInfo;
end;

function TAMoblieDevice.DisConnect: Boolean;
begin
  Result := True;
  if not FIsConnect then Exit;

  try
    FLastErrCode := FuncModule.lpf_AMDeviceStopSession(FDevice);
    FLastErrCode := FuncModule.lpf_AMDeviceDisconnect(FDevice);
    FAFCHandle := nil;
    FAFConnection := nil;
    FIsConnect := False;
  except
    Result := False;
  end;
end;

procedure TAMoblieDevice.GetDeviceDetailInfo;
begin
  try
    FDeviceDetailInfo.DeviceName := GetAMDeviceCopyValue(FDevice,'DeviceName');
    FDeviceDetailInfo.DeviceClass := GetAMDeviceCopyValue(FDevice,'DeviceClass');
    FDeviceDetailInfo.ProductType := GetAMDeviceCopyValue(FDevice,'ProductType');
    FDeviceDetailInfo.ProductVersion := GetAMDeviceCopyValue(FDevice,'ProductVersion');
    FDeviceDetailInfo.SerialNumber := GetAMDeviceCopyValue(FDevice,'SerialNumber');
    FDeviceDetailInfo.ActivationState := GetAMDeviceCopyValue(FDevice,'ActivationState');
    FDeviceDetailInfo.BasebandVersion := GetAMDeviceCopyValue(FDevice,'BasebandVersion');
    FDeviceDetailInfo.BuildVersion := GetAMDeviceCopyValue(FDevice,'BuildVersion');
    FDeviceDetailInfo.FirmwareVersion := GetAMDeviceCopyValue(FDevice,'FirmwareVersion');
    FDeviceDetailInfo.IMEI := GetAMDeviceCopyValue(FDevice,'InternationalMobileEquipmentIdentity');
    FDeviceDetailInfo.ICCID := GetAMDeviceCopyValue(FDevice,'IntegratedCircuitCardIdentity');
    FDeviceDetailInfo.IMSI := GetAMDeviceCopyValue(FDevice,'InternationalMobileSubscriberIdentity');
    FDeviceDetailInfo.ModelNumber := GetAMDeviceCopyValue(FDevice,'ModelNumber');
    FDeviceDetailInfo.PhoneNumber := GetAMDeviceCopyValue(FDevice,'PhoneNumber');
    FDeviceDetailInfo.SIMStatus := GetAMDeviceCopyValue(FDevice,'SIMStatus');
  except
  end; 
end;

constructor TAMoblieDevice.Create(device: p_am_device);
begin
  FJailBreakedStatus := jbsUnknown;
  FReConnect := False;
  FDevice := device;
end;

function TAMoblieDevice.CreateDirectory(Path: string): Boolean;
begin
  Result := FuncModule.lpf_AFCDirectoryCreate(FAFConnection,PChar(FillPath(FCurrentDirectory,Path))) = 0;
end;

function TAMoblieDevice.DeleteDirectory(Path: string): Boolean;
var
  strFullPath : string;
begin
  Result := False;
  strFullPath := FillPath(FCurrentDirectory,Path);
  if IsDirectory(strFullPath) then
  begin
    FLastErrCode := FuncModule.lpf_AFCRemovePath(FAFConnection,PChar(strFullPath));
    if FLastErrCode = 0 then
    begin
      Result := True;
    end;  
  end;  
end;

function TAMoblieDevice.DeleteDirectory(Path: string;
  Recursive: Boolean): Boolean;
var
  strFullPath : string;
begin
  if not Recursive then
  begin
    Result := DeleteDirectory(Path);
  end
  else
  begin
    strFullPath := FillPath(FCurrentDirectory,Path);
    if IsDirectory(strFullPath) then
    begin
      InternalDeleteDirectory(strFullPath);
    end;
    Result := True;
  end;
end;

procedure TAMoblieDevice.InternalDeleteDirectory(Path: string);
var
  strFullPath : string;
  files : TStringList;
  i : Integer;
begin
  strFullPath := FillPath(FCurrentDirectory,Path);
  files := TStringList.Create;
  GetFiles(strFullPath, files);
  for i := 0 to files.Count - 1 do
    DeleteFile(strFullPath + '/' + files.Strings[i]);

  files.Clear;
  GetDirectories(strFullPath, files);
  for i := 0 to files.Count - 1 do
    InternalDeleteDirectory(strFullPath + '/' + files.Strings[i]);

  DeleteDirectory(Path);
  files.Destroy;
end;

function TAMoblieDevice.DeleteFile(Path: string): Boolean;
var
  strFullPath : string;
begin
  Result := False;
  strFullPath := FillPath(FCurrentDirectory,Path);
  if Exists(strFullPath) then
  begin
    FLastErrCode := FuncModule.lpf_AFCRemovePath(FAFConnection,PChar(strFullPath));
    if FLastErrCode = 0 then
    begin
      Result := True;
    end;  
  end;  
end;

destructor TAMoblieDevice.Destroy;
begin

  inherited;
end;

function TAMoblieDevice.GetAMDeviceCopyValue(device: p_am_device;
  Value: string): string;
var
  getvar : Pointer;
begin
  Result := '';
  if not FIsConnect then Exit;
    
  getvar := FuncModule.lpf_AMDeviceCopyValue(device,0,FuncModule.lpf_CFStringCreateWithCString(nil,PChar(Value),0));
  Result := CFStringToCString(getvar);
end;

procedure TAMoblieDevice.GetDirectories(Path: string;
  Dest: TStrings);
var
  pAFCDir ,pStr: Pointer;
  strFullPath : string;
  strBuffer : string;
begin
  if not FIsConnect then Exit;

  strFullPath := FillPath(FCurrentDirectory,Path);
  
  FLastErrCode := FuncModule.lpf_AFCDirectoryOpen(FAFConnection,PChar(strFullPath),pAFCDir);
  if FLastErrCode <> 0 then Exit;

  pStr := nil;
  FLastErrCode := FuncModule.lpf_AFCDirectoryRead(FAFConnection,pAFCDir,pStr);
  while pStr <> nil do
  begin
    strBuffer := PChar(pStr);
    if (strBuffer <> '.') and (strBuffer <> '..') and IsDirectory(FillPath(strFullPath,strBuffer)) then
      Dest.Add(strBuffer);
    FLastErrCode := FuncModule.lpf_AFCDirectoryRead(FAFConnection,pAFCDir,pStr);
  end;

  FLastErrCode := FuncModule.lpf_AFCDirectoryClose(FAFConnection, pAFCDir);
end;

function TAMoblieDevice.GetDirectoryRoot(Path: string): string;
begin
  Result := '/';
end;

function TAMoblieDevice.Exists(Path: string): Boolean;
var
  dict : Pointer;
begin
  Result := False;
  FLastErrCode := FuncModule.lpf_AFCFileInfoOpen(FAFConnection, PChar(Path), dict);
  if FLastErrCode = 0 then
  begin
    FuncModule.lpf_AFCKeyValueClose(dict);
    Result := True;
  end;  
end;

procedure TAMoblieDevice.GetFileInfo(Path: string; var Size: Integer;
  var IsDirectory: Boolean);
var
  FileInfo : TStringList;
  flag, flag3 : Boolean;
  strTmp : string;
  dir : Pointer;
begin
  IsDirectory := False;
  
  FileInfo := TStringList.Create;
  GetFileInfo(Path,FileInfo);


  Size := StrToIntDef(Trim(FileInfo.Values['st_size']),0);

  flag := False;
  IsDirectory := False;
  strTmp := Fileinfo.Text;
  strTmp := Trim(FileInfo.Values['st_ifmt']);
  if strTmp <> '' then
  begin
    if not (strTmp = 'S_IFDIR') then
    begin
      if strTmp = 'S_IFLNK' then
         flag := True;
    end
    else
    begin
      IsDirectory := True;
    end;  
  end;  
  
  if flag then
  begin
    flag3 := (FuncModule.lpf_AFCDirectoryOpen(FAFConnection,PChar(Path),dir) = 0);
    IsDirectory := flag3;
    if flag3 then
       FuncModule.lpf_AFCDirectoryClose(FAFConnection,dir);
  end;

  FileInfo.Destroy;
end;

procedure TAMoblieDevice.GetFileInfo(Path: string; Dest: TStrings);
var
  dict : Pointer;
begin
  if (FuncModule.lpf_AFCFileInfoOpen(FAFConnection, PChar(Path), dict) = 0 ) and (dict <> nil) then
  begin
    GetKeyValueMap(dict,Dest);
  end;
end;

{procedure TAMoblieDevice.GetFileInfoDetails(Path: string;
  var Size: Integer; var FileType: TFileType);
var
  Data, current_data : Pointer;
  DataSize, offset : UINT;
  name, value : string;
  nameEnum : TNameEnum;
  valueEnum : TValueEnum;
begin
  FileType := ftUnknown;
  Data := nil;
  Size := 0;
 // FLastErrCode := FuncModule.lpf_AFCFileInfoOpen(FAFConnection,PChar(Path), Data, DataSize);
  if FLastErrCode <> 0 then
    Exit;

  offset := 0;
  while offset < DataSize do
  begin
    current_data := PChar(Data) + offset;
    name := PChar(current_data);
    offset := offset + Length(name) + 1;

    current_data := PChar(Data) + offset;
    value := PChar(current_data);
    offset := offset + Length(value) + 1;

    nameEnum := TNameEnum(GetEnumvalue(TypeInfo(TNameEnum), name));
    valueEnum := TValueEnum(GetEnumvalue(TypeInfo(TValueEnum), value));

    case nameEnum of
      st_size :
      begin
        Size := StrToIntDef(value,0);
        Break;
      end;
      st_blocks : Break;
      st_ifmt :
      begin
        case valueEnum of
          S_IFDIR  : FileType := ftFolder;
          S_IFREG  : FileType := ftFile;
          S_IFBLK  : FileType := ftBlockDevice;
          S_IFCHR  : FileType := ftCharDevice;
          S_IFIFO  : FileType := ftFIFO;
          S_IFLNK  : FileType := ftLink;
          S_IFMT   : FileType := ftFileMask;
          S_IFSOCK : FileType := ftSocket;
        end;
        Break;
      end;  
    end;
  end;
end;  }

procedure TAMoblieDevice.GetFiles(Path: string; Dest: TStrings);
var
  pAFCDir ,pStr: Pointer;
  strFullPath : string;
begin
  if not FIsConnect then Exit;

  strFullPath := FillPath(FCurrentDirectory,Path);
  
  FLastErrCode := FuncModule.lpf_AFCDirectoryOpen(FAFConnection,PChar(strFullPath),pAFCDir);
  if FLastErrCode <> 0 then Exit;

  FLastErrCode := FuncModule.lpf_AFCDirectoryRead(FAFConnection,pAFCDir,pStr);
  while pStr <> nil do
  begin
    if not IsDirectory(FillPath(strFullPath,PChar(pStr))) then
      Dest.Add(Utf8ToAnsi(PChar(pStr)));
    FLastErrCode := FuncModule.lpf_AFCDirectoryRead(FAFConnection,pAFCDir,pStr);
  end;

  FLastErrCode := FuncModule.lpf_AFCDirectoryClose(FAFConnection, pAFCDir);
end;   

function TAMoblieDevice.GetFileType(Path: string): TFileType;
var
  FileInfo : TStringList;
  strTmp : string;
  valueEnum : TValueEnum;
begin
  FileInfo := TStringList.Create;
  GetFileInfo(Path,FileInfo);

  strTmp := Fileinfo.Text;
  strTmp := Trim(FileInfo.Values['st_ifmt']);
  if strTmp <> '' then
  begin
    valueEnum := TValueEnum(GetEnumvalue(TypeInfo(TValueEnum), strTmp));
    case valueEnum of
      S_IFDIR  : Result := ftFolder;
      S_IFREG  : Result := ftFile;
      S_IFBLK  : Result := ftBlockDevice;
      S_IFCHR  : Result := ftCharDevice;
      S_IFIFO  : Result := ftFIFO;
      S_IFLNK  : Result := ftLink;
      S_IFMT   : Result := ftFileMask;
      S_IFSOCK : Result := ftSocket;
    else
      Result := ftUnknown;
    end;
  end;
  Fileinfo.Destroy;
end;

function TAMoblieDevice.GetFileSize(Path: string): Integer;
var
  IsDir : Boolean;
begin
  Result := 0;
  GetFileInfo(Path,Result,IsDir);
end;

function TAMoblieDevice.Get_st_ifmt(Path: string): string;
var
  FileInfo : TStringList;
begin
  FileInfo := TStringList.Create;
  GetFileInfo(Path,FileInfo);
  Result := FileInfo.Values['st_ifmt'];
  FileInfo.Destroy;
end;

function TAMoblieDevice.IsDirectory(Path: string): Boolean;
var
  Size : Integer;
begin
  Result := False;
  GetFileInfo(Path,Size,Result);
end;

function TAMoblieDevice.Rename(SourceName, DestName: string): Boolean;
begin
  FLastErrCode := FuncModule.lpf_AFCRenamePath(FAFConnection,
    PChar(FillPath(FCurrentDirectory, SourceName)),
    PChar(FillPath(FCurrentDirectory, DestName)));
    
  Result := FLastErrCode = 0;
end;

function TAMoblieDevice.FillPath(Path1, Path2: string): string;
var
  Split,SplitResult : TStringList;
  i: Integer;
begin
  if Trim(Path1) = '' then Path1 := '/';
  if Trim(Path2) = '' then Path2 := '/';

  Split := TStringList.Create;
  Split.Delimiter := '/';

  for i:= 1 to Length(Path1) do
    if Path1[i] = ' ' then  Path1[i] := '_';

  for i:= 1 to Length(Path2) do
    if Path2[i] = ' ' then  Path2[i] := '_';

  if Path2[1] = '/' then
    Split.DelimitedText := Path2
  else
  if Path1[1] = '/' then
    Split.DelimitedText := Path1 + '/' + Path2
  else
    Split.DelimitedText := '/' + Path1 + '/' + Path2;

  SplitResult := TStringList.Create; 
  SplitResult.Delimiter := '/';
  Result := '';

  for i := 0 to Split.Count - 1 do
  begin
    if Split.Strings[i] = '..' then
    begin
      if SplitResult.Count > 0 then
        SplitResult.Delete(SplitResult.Count - 1);
    end
    else
    if (Split.Strings[i] = '.') or (Split.Strings[i] = '') then
    begin
      { do nothing }
    end
    else
    begin
      SplitResult.Add(Split.Strings[i]);
    end;
  end;

  Result := '/' + SplitResult.DelimitedText;

  for i:= 1 to Length(Result) do
    if Result[i] = '_' then  Result[i] := ' ';

  Split.Destroy;
  SplitResult.Destroy;
end;

function TAMoblieDevice.CFStringToCString(CFString: Pointer): string;
var
  StrLen : Integer;
begin
  StrLen := Ord((PChar(CFString) + 8)^);
  SetLength(Result,StrLen);
  Move((PChar(CFString) + 9)^,Result[1],StrLen);
end;

function TAMoblieDevice.GetDeviceInfo():string;
var
  dict : Pointer;
  Info : TStringList;
begin
  if (FuncModule.lpf_AFCDeviceInfoOpen(FAFConnection,dict) = 0) and (dict <> nil) then
  begin
    Info := TStringList.Create;
    GetKeyValueMap(dict,Info);
    Result := Info.Text;
    Info.Destroy;
  end;  
end;

procedure TAMoblieDevice.GetKeyValueMap(dict: Pointer; Dest: TStrings);
var
  ptr2,ptr3 : PChar;
begin
  if dict = nil then Exit;
  
  while (((FuncModule.lpf_AFCKeyValueRead(dict,Ptr2, Ptr3) = 0) and (Ptr2 <> nil)) and (Ptr3 <> nil)) do
  begin
    Dest.Values[Utf8ToAnsi(Ptr2)] := Utf8ToAnsi(Ptr3);
  end;
  FuncModule.lpf_AFCKeyValueClose(dict);
end;

end.
