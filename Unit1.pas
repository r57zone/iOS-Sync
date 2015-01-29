unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, AMobileDevice, AMobileDeviceFile, AMoblieDeviceModule, AMoblieDeviceModuleDef,
  StdCtrls, XPMan, IniFiles, ImgList, ComCtrls, Menus, ShellApi, ShlObj;

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
    N3: TMenuItem;
    N4: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ListView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure N11Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
  protected
    procedure WMDropFiles (var Msg: TMessage); message wm_DropFiles;
  private
    FDevice : TAMoblieDevice;
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA; //Standard modular program
    procedure DoOnDeviceConnect(Sender: TObject;Device: TAMoblieDevice);
    procedure DoOnDeviceDisconnect(Sender: TObject;Device: TAMoblieDevice);
    procedure Dir(Address:string);
    procedure DoOnFileTransStep(Sender: TObject;Step: Cardinal);
    procedure StatusBar(SimpleText:string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  Connected,Jailbreaked,ListCompleted:boolean;
  Path,FileIndex:string;

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
jbsTrue:Jailbreaked:=true;
jbsFalse:Jailbreaked:=false;
end;
Caption:=Application.Title+' - '+Device.DeviceDetailInfo.DeviceName;
if Jailbreaked then Caption:=Caption+' Jailbreaked';
StatusBar1.SimpleText:=' Устройство подключено';
Dir(Path);
end;
end;

function GetSystemLanguage:string;
var
Buffer:PChar;
Size:integer;
begin
Size:=GetLocaleInfo (LOCALE_USER_DEFAULT, LOCALE_SENGLANGUAGE, nil, 0);
GetMem(Buffer, Size);
try
GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SENGLANGUAGE, Buffer, Size);
result:=Buffer;
finally
FreeMem(Buffer);
end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
Ini:TIniFile;
begin
DragAcceptFiles(Handle, True);
Application.Title:=Caption;
//Button1.ControlState:=[csFocusing];
Ini:=TIniFile.Create(ExtractFilePath(paramstr(0))+'setup.ini');
Path:=Ini.ReadString('Main','Path','/');
Ini.Free;
Connected:=false;
Jailbreaked:=false;
if not assigned(lpAMobileDeviceModule) then begin
lpAMobileDeviceModule:=TAMobileDeviceModule.Create;
lpAMobileDeviceModule.OnDeviceConnect:=DoOnDeviceConnect;
lpAMobileDeviceModule.OnDeviceDisconnect:=DoOnDeviceDisconnect;
if lpAMobileDeviceModule.InitialModule then Connected:=true;
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
Connected:=false;
StatusBar1.SimpleText:=' Устройство отключено';
Caption:='iOS Sync';
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

for i:=0 to DirList.Count-1 do begin
Item:=ListView1.Items.Add;
Item.Caption:=StringReplace(UTF8ToAnsi(DirList.Strings[i]),'и?','й',[rfreplaceall]);
Item.Caption:=StringReplace(Item.Caption,'И?','Й',[rfreplaceall]);
//Item.SubItems.Add('');
Item.ImageIndex:=2;
end;
DirList.Clear;
FDevice.GetFiles(AnsiToUTF8(address),DirList);
for i:=0 to DirList.Count-1 do begin
Item :=ListView1.Items.Add;
Item.Caption:=StringReplace(DirList.Strings[i],'и?','й',[rfreplaceall]);
Item.Caption:=StringReplace(Item.Caption,'И?','Й',[rfreplaceall]);
//Item.SubItems.Add('');
Item.SubItems.Add('');
Item.ImageIndex:=4;
if ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.mp3' then Item.ImageIndex:=3;
if ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.txt' then Item.ImageIndex:=5;
if (ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.jpg') or (ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.bmp')
or (ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.png') or (ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.gif') then Item.ImageIndex:=6;
end;
DirList.Free;
Path:=address;
ListCompleted:=true;
end;

procedure TForm1.ListView1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
if ListView1.ItemIndex<>-1 then begin
if Button=MbLeft then begin
case ListView1.Items[ListView1.ItemIndex].ImageIndex of
1: dir('/');
0: if Path<>'/' then begin delete(Path,pos(ExtractFileName(StringReplace(Path,'/','\',[rfreplaceall])),Path)-1,length(ExtractFileName(StringReplace(Path,'/','\',[rfreplaceall])))+1); Dir(Path); end;
2: if Path='/' then dir(Path+ListView1.Items[ListView1.ItemIndex].Caption) else dir(Path+'/'+ListView1.Items[ListView1.ItemIndex].Caption);
end;
end;
if Button=MbRight then begin
if (ListView1.Items[ListView1.ItemIndex].ImageIndex<>0) and (ListView1.Items[ListView1.ItemIndex].ImageIndex<>1) then begin
FileIndex:=IntToStr(ListView1.Items[ListView1.ItemIndex].ImageIndex)+ListView1.Items[ListView1.ItemIndex].Caption;
PopupMenu1.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y);
end;
end;
end;
end;

function UploadFile(Local,Address:string):boolean;
var
AMobileFile:TAMobileDeviceFileStream;
LocalFile:TFileStream;
begin
if (address<>'/') and (Connected=true) then begin
LocalFile:=TFileStream.Create(Local,fmOpenRead);
LocalFile.Position:=0;
try
if Form1.FDevice.Exists(AnsiToUtf8(address+'/'+ExtractFileName(Local))) then
Form1.FDevice.DeleteFile(AnsiToUtf8(address+'/'+ExtractFileName(Local)));

AMobileFile:=TAMobileDeviceFileStream.Create(Form1.FDevice,AnsiToUtf8(Address+'/'+ExtractFileName(Local)),omWrite);
AMobileFile.OnProgressStep:=Form1.DoOnFileTransStep;
AMobileFile.CopyFrom(LocalFile,LocalFile.Size);
AMobileFile.Destroy;
result:=true;
except
//on E:Exception do
//ShowMessage(Local+'/'+ExtractFileName(StrPas(Filename))+ '  ' + E.Message);
result:=false;
end;
LocalFile.Destroy;
end else result:=false;
end;

function UploadDir(LocalPath,address:string):boolean;
var
SR:TSearchRec;
begin
try
Form1.FDevice.CreateDirectory(AnsiToUTF8(address+'/'+ExtractFileName(Copy(LocalPath,1,Length(LocalPath)-1))));

if FindFirst(LocalPath + '*.*', faAnyFile, SR) = 0 then begin
repeat
if (SR.Attr<>faDirectory) then UploadFile(LocalPath+SR.Name,address+'/'+ExtractFileName(Copy(LocalPath,1,Length(LocalPath)-1)));
until FindNext(SR)<>0;
FindClose(SR);
end;

if FindFirst(LocalPath + '*', faAnyFile, SR) = 0 then begin
repeat
if (SR.Attr=faDirectory) and (SR.Name<>'.') and (SR.Name<>'..') then UploadDir(LocalPath+SR.Name+'\',address+'/'+ExtractFileName(Copy(LocalPath,1,Length(LocalPath)-1)));
until FindNext(SR)<>0;
FindClose(SR);
end;

Result:=true;
except
Result:=false;
end;
end;

procedure TForm1.WMDropFiles(var Msg: TMessage);
var
i, Amount, Size, Count, GoodCount:integer;
Filename: PChar;
begin
if Connected then begin

Count:=0;
GoodCount:=0;

inherited;
Amount:=DragQueryFile(Msg.WParam, $FFFFFFFF, Filename, 255);
for i:=0 to (Amount - 1) do begin
Size:=DragQueryFile(Msg.WParam, i, nil, 0) + 1;
Filename:=StrAlloc(Size);
DragQueryFile(Msg.WParam, i, Filename, Size);
Inc(Count);

StatusBar1.SimpleText:=' Идет копирование файлов ('+IntToStr(i+1)+' из '+IntToStr(Amount)+')';

if FileExists(StrPas(Filename)) then begin
if UploadFile(StrPas(Filename),Path) then Inc(GoodCount); end else
if DirectoryExists(StrPas(Filename)) then if UploadDir(StrPas(Filename)+'\',Path) then Inc(GoodCount);

StrDispose(Filename);
end;
DragFinish(Msg.WParam);

Dir(Path);

if Count=GoodCount then StatusBar1.SimpleText:=' Все файлы успешно загружены' else
StatusBar1.SimpleText:=' В процессе загрузки произошла ошибка';
end else StatusBar1.SimpleText:=' Устройство не подключено';
end;

procedure TForm1.DoOnFileTransStep(Sender: TObject; Step: Cardinal);
begin
Application.ProcessMessages;
end;

function RemoveDirAndFiles(address:string):boolean;
var
DirList:TStringList; i:integer;
begin
try
address:=StringReplace(UTF8ToAnsi(address),'и?','й',[rfreplaceall]);
address:=AnsiToUTF8(StringReplace(address,'И?','Й',[rfreplaceall]));

DirList:=TStringList.Create;

Form1.FDevice.GetFiles(address,DirList);
for i:=0 to DirList.Count-1 do
Form1.FDevice.DeleteFile(address+'/'+DirList.Strings[i]);

DirList.Clear;

Form1.FDevice.GetDirectories(address,DirList);
for i:=0 to DirList.Count-1 do
if (DirList.Strings[i]<>'.') and (DirList.Strings[i]<>'..') then RemoveDirAndFiles(address+'/'+DirList.Strings[i]);

Form1.FDevice.DeleteDirectory(address,true);
DirList.Free;
Result:=true;
except
Result:=false;
end;
end;

procedure TForm1.N11Click(Sender: TObject);
begin
if FileIndex[1]<>'2' then begin
delete(FileIndex,1,1);
if Form1.FDevice.DeleteFile(AnsiToUtf8(Path+'/'+ExtractFileName(FileIndex))) then begin
if length(FileIndex)>27 then FileIndex:=copy(FileIndex,1,27)+'...';
StatusBar1.SimpleText:=' Файл "'+FileIndex+'" успешно удален'; Dir(Path); end else StatusBar1.SimpleText:=' Не удается удалить файл "'+FileIndex+'"';
end else begin
delete(FileIndex,1,1);
if RemoveDirAndFiles(AnsiToUtf8(Path+'/'+ExtractFileName(FileIndex))) then begin
StatusBar1.SimpleText:=' Папка "'+FileIndex+'" успешно удалена'; Dir(Path); end else StatusBar1.SimpleText:=' Не удается удалить папку "'+FileIndex+'"';
end;
end;

procedure TForm1.N1Click(Sender: TObject);
var
namedir:string;
begin
if InputQuery(Application.Title, 'Введите название папки', namedir) then
if trim(namedir)<>'' then begin
if Form1.FDevice.Exists(AnsiToUtf8(Path+'/'+namedir)) then StatusBar1.SimpleText:=' Такая папка уже существует' else begin
Form1.FDevice.CreateDirectory(AnsiToUtf8(Path+'/'+namedir));
Dir(Path);
StatusBar1.SimpleText:=' Папка "'+namedir+'" успешно создана';
end;
end else StatusBar1.SimpleText:=' Неверно задано имя папки';
end;

procedure TForm1.StatusBar1Click(Sender: TObject);
begin
Application.MessageBox('iOS Sync 0.3'+#13#10+'https://github.com/r57zone'+#13#10+'Последнее обновление: 29.01.2015','О программе...',0);
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
if FileExists(SyncList.Strings[i]) then begin
if UploadFile(SyncList.Strings[i],path) then Inc(GoodCount); end else
if DirectoryExists(SyncList.Strings[i]) then if UploadDir(SyncList.Strings[i]+'\',Path) then Inc(GoodCount);
end;
if Count=GoodCount then begin
StatusBar1.SimpleText:=' Все файлы успешно загружены';
SendMessageToHandle(FindWindow(nil,'PodCast Easy'),'GOOD');
Dir(Path);
end else begin
StatusBar1.SimpleText:=' В процессе загрузки произошла ошибка';
Dir(Path);
SendMessageToHandle(FindWindow(nil,'PodCast Easy'),'BAD');
end;
SyncList.Free;
end;

msg.Result:=Integer(True);
end;

procedure TForm1.N3Click(Sender: TObject);
var
newname:string;
begin
if (FileIndex[1]<>'0') and (FileIndex[1]<>'1') then delete(FileIndex,1,1);
if InputQuery(Application.Title, 'Введите новое название для '+FileIndex, newname) then
if trim(newname)<>'' then begin
if FDevice.Rename(AnsiToUtf8(Path+'/'+FileIndex),AnsiToUtf8(Path+'/'+newname)) then StatusBar1.SimpleText:=' Название успешно изменено' else StatusBar1.SimpleText:=' Название не удалось изменить';
Dir(Path);
end else StatusBar1.SimpleText:=' Неверно задано название';
end;

function BrowseFolderDialog(title:PChar):string;
var
titlename:string;
lpitemid:pitemidlist;
browseinfo:tbrowseinfo;
displayname:array[0..max_Path] of char;
tempPath:array[0..max_Path] of char;
begin
fillchar(browseinfo,sizeof(tbrowseinfo),#0);
browseinfo.hwndowner:=GetDesktopWindow;
browseinfo.pszdisplayname:=@displayname;
titlename:=title;
browseinfo.lpsztitle:=PChar(titlename);
browseinfo.ulflags:=bif_returnonlyfsdirs;
lpitemid:=shbrowseforfolder(browseinfo);
if lpitemid<>nil then begin
shgetPathfromidlist(lpitemid, tempPath);
result:=tempPath;
globalfreeptr(lpitemid);
end;
end;

function DownloadFile(address,LocalPath:string):boolean;
var
RemoteFileSize:Int64;
AMobileFile:TAMobileDeviceFileStream;
LocalFile:TFileStream;
begin
RemoteFileSize:=Form1.FDevice.GetFileSize(address);
LocalFile:=TFileStream.Create(LocalPath+'\'+ExtractFileName(StringReplace(address,'/','\',[rfReplaceAll])),fmCreate);
try
AMobileFile:=TAMobileDeviceFileStream.Create(Form1.FDevice,address,omRead);
AMobileFile.OnProgressStep:=Form1.DoOnFileTransStep;
AMobileFile.Position:=0;
LocalFile.CopyFrom(AMobileFile,RemoteFileSize);
AMobileFile.Destroy;
LocalFile.Destroy;
Result:=true;
except
Result:=false;
end;
end;

function DownloadDir(address,LocalPath:string):boolean;
var
DirList:TStringList; i:integer;
begin
try
address:=StringReplace(UTF8ToAnsi(address),'и?','й',[rfreplaceall]);
address:=AnsiToUTF8(StringReplace(address,'И?','Й',[rfreplaceall]));

CreateDir(LocalPath+'\'+UTF8ToAnsi(ExtractFileName(StringReplace(address,'/','\',[rfReplaceAll]))));
DirList:=TStringList.Create;

Form1.FDevice.GetFiles(address,DirList);
for i:=0 to DirList.Count-1 do
DownloadFile(address+'/'+DirList.Strings[i],LocalPath+'\'+UTF8ToAnsi(ExtractFileName(StringReplace(address,'/','\',[rfReplaceAll]))));

DirList.Clear;

Form1.FDevice.GetDirectories(address,DirList);
for i:=0 to DirList.Count-1 do
if (DirList.Strings[i]<>'.') and (DirList.Strings[i]<>'..') then DownloadDir(address+'/'+DirList.Strings[i],LocalPath+'\'+UTF8ToAnsi(ExtractFileName(StringReplace(address,'/','\',[rfReplaceAll]))));

DirList.Free;
Result:=true;
except
Result:=false;
end;
end;

procedure TForm1.N4Click(Sender: TObject);
var
TempPath:string;
begin
TempPath:=BrowseFolderDialog('Выберите каталог');
if TempPath<>'' then begin
if FileIndex[1]<>'2' then begin
delete(FileIndex,1,1);
StatusBar1.SimpleText:=' Идет копирование файла';
if DownloadFile(AnsiToUtf8(Path+'/'+FileIndex),TempPath) then StatusBar1.SimpleText:=' Файл успешно скопирован' else
StatusBar1.SimpleText:=' В процессе копирования произошла ошибка';
end else begin
delete(FileIndex,1,1);
StatusBar1.SimpleText:=' Идет копирование файлов';
if DownloadDir(AnsiToUtf8(Path+'/'+FileIndex),TempPath) then StatusBar1.SimpleText:=' Копирование успешно завершено' else
StatusBar1.SimpleText:=' В процессе копирования произошла ошибка';
end;
end else StatusBar1.SimpleText:=' Не выбран каталог';
end;

procedure TForm1.StatusBar(SimpleText: string);
begin

end;

end.
