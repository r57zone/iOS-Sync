unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, AMobileDevice, AMobileDeviceFile, AMoblieDeviceModule, AMoblieDeviceModuleDef,
  StdCtrls, XPMan, IniFiles, ImgList, ComCtrls, Menus, ShellApi;

type
  TForm1 = class(TForm)
    XPManifest1: TXPManifest;
    ImageList1: TImageList;
    ListView1: TListView;
    StatusBar1: TStatusBar;
    PopupMenu1: TPopupMenu;
    N11: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ListView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure N11Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
  protected
    procedure WMDropFiles (var Msg: TMessage); message wm_DropFiles;
  private
    FDevice : TAMoblieDevice;
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA; //Standard modular program
    procedure DoOnDeviceConnect(Sender: TObject;Device: TAMoblieDevice);
    procedure DoOnDeviceDisconnect(Sender: TObject;Device: TAMoblieDevice);
    procedure Dir(Address:string);
    procedure DoOnFileTransStep(Sender: TObject;Step: Cardinal);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  connected,jailbreaked,ListCompleted:boolean;
  path,fileindex:string;

implementation

{$R *.dfm}

function empty_func:boolean;
begin
end;

procedure TForm1.DoOnDeviceConnect(Sender: TObject;
  Device: TAMoblieDevice);
begin
if Device.Connect then begin
FDevice:=Device;
case FDevice.JailBreakedStatus of
jbsTrue:jailbreaked:=true;
jbsFalse:jailbreaked:=false;
end;
caption:=Application.Title+' - '+Device.DeviceDetailInfo.DeviceName;
if jailbreaked then caption:=caption+' jailbreaked' else caption:=caption+' without jailbreak';
StatusBar1.SimpleText:=' Устройство подключено';
dir(path);
end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
Ini:TIniFile;
begin
DragAcceptFiles(Handle, True);
Application.Title:=caption;
//Button1.ControlState:=[csFocusing];
Ini:=TIniFile.Create(ExtractFilePath(paramstr(0))+'setup.ini');
Path:=Ini.ReadString('Main','Path','/');
Ini.Free;
connected:=false;
jailbreaked:=false;
if not assigned(lpAMobileDeviceModule) then begin
lpAMobileDeviceModule:=TAMobileDeviceModule.Create;
lpAMobileDeviceModule.OnDeviceConnect:=DoOnDeviceConnect;
lpAMobileDeviceModule.OnDeviceDisconnect:=DoOnDeviceDisconnect;
if lpAMobileDeviceModule.InitialModule then connected:=true;
if lpAMobileDeviceModule.Subscribe then empty_func;
end;
ListView1.Columns[0].Width:=ListView1.Width-30;
//ListView1.Perform(LVM_SETCOLUMNWIDTH, 0, 200);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
if Assigned(lpAMobileDeviceModule) then lpAMobileDeviceModule.Destroy;
end;

procedure TForm1.DoOnDeviceDisconnect(Sender: TObject;
  Device: TAMoblieDevice);
begin
ListView1.Clear;
connected:=false;
StatusBar1.SimpleText:=' Устройство отключено';
caption:='iOS Sync';
end;

procedure TForm1.Dir(Address: string);
var
Item:TListItem; i:integer; DirList:TStringList;
begin
ListCompleted:=false;
ListView1.Clear;

if trim(address)='' then address:='/';

if (address<>'/') then begin
Item:=ListView1.Items.Add;
Item.Caption:='.';
Item.SubItems.Add('');
Item.ImageIndex:=1;

Item:=ListView1.Items.Add;
Item.Caption:='..';
Item.SubItems.Add('');
Item.ImageIndex:=0;
end;

DirList:=TStringList.Create;
FDevice.GetDirectories(AnsiToUTF8(address),DirList);

for i:=0 to DirList.Count - 1 do begin
Item:=ListView1.Items.Add;
Item.Caption:=StringReplace(UTF8ToAnsi(DirList.Strings[i]),'и?','й',[rfreplaceall]);
Item.Caption:=StringReplace(Item.Caption,'И?','Й',[rfreplaceall]);
//Item.SubItems.Add(UTF8ToAnsi(DirList.Strings[i]));
Item.SubItems.Add('');
Item.ImageIndex:=2;
end;
DirList.Clear;
FDevice.GetFiles(AnsiToUTF8(address),DirList);
for i:=0 to DirList.Count - 1 do begin
Item :=ListView1.Items.Add;
Item.Caption:=StringReplace(DirList.Strings[i],'и?','й',[rfreplaceall]);
Item.Caption:=StringReplace(Item.Caption,'И?','Й',[rfreplaceall]);
//Item.SubItems.Add(DirList.Strings[i]);
Item.SubItems.Add('');
Item.ImageIndex:=4;
if ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.mp3' then Item.ImageIndex:=3;
if ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.txt' then Item.ImageIndex:=5;
//if copy(DirList.Strings[i],length(DirList.Strings[i])-2,3)='mp3' then
end;
DirList.Free;
path:=address;
ListCompleted:=true;
end;

procedure TForm1.ListView1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
if Button=MbLeft then begin
if ListView1.ItemIndex<>-1 then
case ListView1.Items[ListView1.ItemIndex].ImageIndex of
1: dir('/');
0: if path<>'/' then begin delete(path,pos(extractfilename(stringreplace(path,'/','\',[rfreplaceall])),path)-1,length(extractfilename(stringreplace(path,'/','\',[rfreplaceall])))+1); dir(path); end;
2: if path='/' then dir(path+ListView1.Items[ListView1.ItemIndex].Caption) else dir(path+'/'+ListView1.Items[ListView1.ItemIndex].Caption);
end;
end;
if Button=MbRight then begin
if (ListView1.ItemIndex<>-1) then
if (ListView1.Items[ListView1.ItemIndex].ImageIndex=2) or (ListView1.Items[ListView1.ItemIndex].ImageIndex=3) or (ListView1.Items[ListView1.ItemIndex].ImageIndex=4)
or (ListView1.Items[ListView1.ItemIndex].ImageIndex=5) then begin
fileindex:=IntToStr(ListView1.Items[ListView1.ItemIndex].ImageIndex)+ListView1.Items[ListView1.ItemIndex].Caption;
N11.Enabled:=true;
PopupMenu1.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y);
end else N11.Enabled:=false;
end;
end;

function UploadFile(address:string):boolean;
var
AMobileFile:TAMobileDeviceFileStream;
LocalFile:TFileStream;
begin
if (path<>'/') and (connected=true) then begin
LocalFile:=TFileStream.Create(address,fmOpenRead);
LocalFile.Position:=0;
try
if Form1.FDevice.Exists(AnsiToUtf8(path+'/'+ExtractFileName(address))) then
Form1.FDevice.DeleteFile(AnsiToUtf8(path+'/'+ExtractFileName(address)));

AMobileFile:=TAMobileDeviceFileStream.Create(Form1.FDevice,AnsiToUtf8(path+'/'+ExtractFileName(address)),omWrite);
AMobileFile.OnProgressStep:=Form1.DoOnFileTransStep;
AMobileFile.CopyFrom(LocalFile,LocalFile.Size);
AMobileFile.Destroy;
result:=true;
except
//on E:Exception do
//ShowMessage(Path+'/'+Extractfilename(StrPas(Filename))+ '  ' + E.Message);
result:=false;
end;
LocalFile.Destroy;
end else result:=false;
end;

function UploadDir(address:string):boolean;
begin
//
end;

procedure TForm1.WMDropFiles(var Msg: TMessage);
var
i, Amount, Size, Count, GoodCount:integer;
Filename: PChar;
begin
if connected then begin

Count:=0;
GoodCount:=0;

inherited;
Amount:=DragQueryFile(Msg.WParam, $FFFFFFFF, Filename, 255);
for i:=0 to (Amount - 1) do
begin
Size:=DragQueryFile(Msg.WParam, i, nil, 0) + 1;
Filename:=StrAlloc(Size);
DragQueryFile(Msg.WParam, i, Filename, Size);
Inc(Count);

StatusBar1.SimpleText:=' Идет копирование файлов ('+IntToStr(i+1)+' из '+IntToStr(Amount)+')';

if FileExists(StrPas(Filename)) then
if UploadFile(StrPas(Filename)) then Inc(GoodCount);

//if DirectoryExists(StrPas(Filename)) then
//if UploadDir(StrPas(Filename)) then Inc(GoodCount);

StrDispose(Filename);
end;
DragFinish(Msg.WParam);

Dir(path);

if Count=GoodCount then StatusBar1.SimpleText:=' Все файлы успешно загружены' else
StatusBar1.SimpleText:=' В процессе загрузки произошла ошибка';
end else StatusBar1.SimpleText:=' Устройство не подключено';
end;

procedure TForm1.DoOnFileTransStep(Sender: TObject; Step: Cardinal);
begin
Application.ProcessMessages;
end;

procedure TForm1.N11Click(Sender: TObject);
begin
if (fileindex[1]='3') or (fileindex[1]='4') or (fileindex[1]='5') then begin
delete(fileindex,1,1);
if path<>'/' then
if Form1.FDevice.Exists(AnsiToUtf8(path+'/'+ExtractFileName(fileindex))) then
if Form1.FDevice.DeleteFile(AnsiToUtf8(path+'/'+ExtractFileName(fileindex))) then begin
if length(fileindex)>27 then fileindex:=copy(fileindex,1,27)+'...';
StatusBar1.SimpleText:=' Файл "'+fileindex+'" удален'; Dir(path); end else StatusBar1.SimpleText:=' Невозможно удалить файл "'+fileindex+'"';
end;
if (fileindex[1]='2') then begin
delete(fileindex,1,1);
if Form1.FDevice.DeleteDirectory(AnsiToUtf8(path+'/'+ExtractFileName(fileindex)),true) then begin
StatusBar1.SimpleText:=' Папка "'+fileindex+'" удалена'; Dir(path); end;
end;
end;

procedure TForm1.N1Click(Sender: TObject);
var
namedir:string;
begin
if InputQuery(Application.Title, 'Введите название папки', namedir) then
if trim(namedir)<>'' then begin
if Form1.FDevice.Exists(AnsiToUtf8(path+'/'+namedir)) then StatusBar1.SimpleText:=' Такая папка уже существует' else begin
Form1.FDevice.CreateDirectory(AnsiToUtf8(path+'/'+namedir));
Dir(path);
StatusBar1.SimpleText:=' Папка "'+namedir+'" успешно создана';
end;
end else StatusBar1.SimpleText:=' Неверно задано имя папки';
end;

procedure TForm1.StatusBar1Click(Sender: TObject);
begin
Application.MessageBox('iOS Sync 0.3'+#13#10+'https://github.com/r57zone'+#13#10+'Последнее обновление: 07.09.2014','О программе...',0);
end;

procedure SendMessageToHandle(TRGWND:hwnd;MsgToHandle:string);
var
CDS: TCopyDataStruct;
begin
CDS.dwData:=0;
CDS.cbData:=(length(MsgToHandle)+ 1)*sizeof(char);
CDS.lpData:=PChar(MsgToHandle);
SendMessage(TRGWND,WM_COPYDATA, Integer(Application.Handle), Integer(@CDS));
end;

procedure TForm1.WMCopyData(var msg: TWMCopyData); //Standard modular program
var
SyncList:TStringList; i,Count,GoodCount:integer;
begin
if PChar(TWMCopyData(msg).CopyDataStruct.lpData)='WORK' then SendMessageToHandle(FindWindow(nil,'PodCast Easy'),'YES');

if copy(PChar(TWMCopyData(msg).CopyDataStruct.lpData),1,13)='FILES TO SYNC' then begin
while not ListCompleted do begin sleep(15); Application.ProcessMessages; end;
Count:=0;
GoodCount:=0;
SyncList:=TStringList.Create;
SyncList.Text:=PChar(TWMCopyData(msg).CopyDataStruct.lpData);
SyncList.Delete(0);
for i:=0 to SyncList.Count-1 do begin
inc(Count);
StatusBar1.SimpleText:=' Идет копирование файлов ('+IntToStr(i+1)+' из '+IntToStr(SyncList.Count)+')';
if FileExists(StrPas(Pchar(SyncList.Strings[i]))) then
if UploadFile(StrPas(Pchar(SyncList.Strings[i]))) then Inc(GoodCount);
end;
if Count=GoodCount then begin
StatusBar1.SimpleText:=' Все файлы успешно загружены';
SendMessageToHandle(FindWindow(nil,'PodCast Easy'),'GOOD');
Dir(path);
end else begin
StatusBar1.SimpleText:=' В процессе загрузки произошла ошибка';
Dir(path);
SendMessageToHandle(FindWindow(nil,'PodCast Easy'),'BAD');
end;
SyncList.Free;
end;

msg.Result:=Integer(True);
end;

end.
