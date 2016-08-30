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
    procedure ListView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  protected
    procedure WMDropFiles (var Msg: TMessage); message wm_DropFiles;
  private
    FDevice : TAMoblieDevice;
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA; //Standard modular program
    procedure DoOnDeviceConnect(Sender: TObject; Device: TAMoblieDevice);
    procedure DoOnDeviceDisconnect(Sender: TObject; Device: TAMoblieDevice);
    procedure Dir(Address: string);
    procedure DoOnFileTransStep(Sender: TObject;Step: Cardinal);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  Connected, Jailbreaked, ListCompleted: boolean;
  Path, FileIndex: string;

implementation

{$R *.dfm}

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
    if Jailbreaked then Caption:=Caption+' jailbreaked';
    StatusBar1.SimpleText:=' Устройство подключено';
    Dir(Path);
  end;
end;

function EmptyFunc:boolean;
begin

end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Ini:TIniFile;
begin
  DragAcceptFiles(Handle, True);
  Application.Title:=Caption;
  //Button1.ControlState:=[csFocusing];
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'setup.ini');
  Path:=Ini.ReadString('Main','Path','/');
  Ini.Free;
  Connected:=false;
  Jailbreaked:=false;
  if not assigned(lpAMobileDeviceModule) then begin
    lpAMobileDeviceModule:=TAMobileDeviceModule.Create;
    lpAMobileDeviceModule.OnDeviceConnect:=DoOnDeviceConnect;
    lpAMobileDeviceModule.OnDeviceDisconnect:=DoOnDeviceDisconnect;
    if lpAMobileDeviceModule.InitialModule then Connected:=true;
    if lpAMobileDeviceModule.Subscribe then EmptyFunc;
  end;
  ListView1.Columns[0].Width:=ListView1.Width-30;
  //ListView1.Perform(LVM_SETCOLUMNWIDTH, 0, 200);

  if ParamCount>0 then Path:=ParamStr(1);
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
  Item: TListItem; i: integer; DirList: TStringList;
begin
  ListCompleted:=false;
  ListView1.Clear;

  if Trim(Address)='' then Address:='/';

  if (Address<>'/') then begin
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
  FDevice.GetDirectories(AnsiToUTF8(Address),DirList);

  for i:=0 to DirList.Count-1 do begin
    Item:=ListView1.Items.Add;
    Item.Caption:=UTF8ToAnsi(DirList.Strings[i]);
    Item.Caption:=StringReplace(Item.Caption,'и?','й',[rfReplaceAll]);
    Item.Caption:=StringReplace(Item.Caption,'И?','Й',[rfReplaceAll]);
    Item.Caption:=StringReplace(Item.Caption,'е?','ё',[rfReplaceAll]);
    Item.Caption:=StringReplace(Item.Caption,'Е?','Ё',[rfReplaceAll]);
    //Item.SubItems.Add('');
    Item.ImageIndex:=2;
  end;
  DirList.Clear;
  FDevice.GetFiles(AnsiToUTF8(Address),DirList);
  for i:=0 to DirList.Count-1 do begin
    Item:=ListView1.Items.Add;
    Item.Caption:=DirList.Strings[i];
    Item.Caption:=StringReplace(Item.Caption,'и?','й',[rfReplaceAll]);
    Item.Caption:=StringReplace(Item.Caption,'И?','Й',[rfReplaceAll]);
    Item.Caption:=StringReplace(Item.Caption,'е?','ё',[rfReplaceAll]);
    Item.Caption:=StringReplace(Item.Caption,'Е?','Ё',[rfReplaceAll]);
    //Item.SubItems.Add('');
    Item.SubItems.Add('');
    Item.ImageIndex:=4;
    if ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.mp3' then Item.ImageIndex:=3;
    if ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.txt' then Item.ImageIndex:=5;
    if (ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.jpg') or (ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.bmp')
    or (ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.png') or (ExtractFileExt(AnsiLowerCase(DirList.Strings[i]))='.gif') then Item.ImageIndex:=6;
  end;
  DirList.Free;
  Path:=Address;
  ListCompleted:=true;
end;

procedure TForm1.ListView1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if ListView1.ItemIndex<>-1 then begin
    if Button=MbLeft then begin
      case ListView1.Items[ListView1.ItemIndex].ImageIndex of
        1: Dir('/');
        0: if Path<>'/' then begin Delete(Path,pos(ExtractFileName(StringReplace(Path,'/','\',[rfReplaceAll])),Path)-1,length(ExtractFileName(StringReplace(Path,'/','\',[rfReplaceAll])))+1); Dir(Path); end;
        2: if Path='/' then Dir(Path+ListView1.Items[ListView1.ItemIndex].Caption) else Dir(Path+'/'+ListView1.Items[ListView1.ItemIndex].Caption);
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
  AMobileFile: TAMobileDeviceFileStream;
  LocalFile: TFileStream;
begin
  if Connected then begin
    LocalFile:=TFileStream.Create(Local,fmOpenRead);
    LocalFile.Position:=0;
    try
      if Form1.FDevice.Exists(AnsiToUtf8(Address+'/'+ExtractFileName(Local))) then
        Form1.FDevice.DeleteFile(AnsiToUtf8(Address+'/'+ExtractFileName(Local)));

      AMobileFile:=TAMobileDeviceFileStream.Create(Form1.FDevice,AnsiToUtf8(Address+'/'+ExtractFileName(Local)),omWrite);
      AMobileFile.OnProgressStep:=Form1.DoOnFileTransStep;
      AMobileFile.CopyFrom(LocalFile,LocalFile.Size);
      AMobileFile.Destroy;
      Result:=true;
    except
      //on E:Exception do
      //ShowMessage(Local+'/'+ExtractFileName(StrPas(Filename))+ '  ' + E.Message);
      Result:=false;
    end;
    LocalFile.Destroy;
  end else Result:=false;
end;

function UploadDir(LocalPath,Address:string):boolean;
var
  SR: TSearchRec;
begin
  try
    Form1.FDevice.CreateDirectory(AnsiToUTF8(Address+'/'+ExtractFileName(Copy(LocalPath,1,Length(LocalPath)-1))));

    if FindFirst(LocalPath + '*.*', faAnyFile, SR) = 0 then begin
      repeat
        if (SR.Attr<>faDirectory) then UploadFile(LocalPath+SR.Name,Address+'/'+ExtractFileName(Copy(LocalPath,1,Length(LocalPath)-1)));
      until FindNext(SR)<>0;
      FindClose(SR);
    end;

    if FindFirst(LocalPath + '*', faAnyFile, SR) = 0 then begin
      repeat
        if (SR.Attr=faDirectory) and (SR.Name<>'.') and (SR.Name<>'..') then UploadDir(LocalPath+SR.Name+'\',Address+'/'+ExtractFileName(Copy(LocalPath,1,Length(LocalPath)-1)));
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
  i, Amount, Size, Count, GoodCount: integer;
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
      inc(Count);

      StatusBar1.SimpleText:=' Идет копирование файлов ('+IntToStr(i+1)+' из '+IntToStr(Amount)+')';

      if FileExists(StrPas(Filename)) and (pos('?',StrPas(Filename))=0) then begin
        if UploadFile(StrPas(Filename),Path) then inc(GoodCount); end else
        if DirectoryExists(StrPas(Filename)) and (pos('?',StrPas(Filename))=0) then if UploadDir(StrPas(Filename)+'\',Path) then inc(GoodCount);

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

function RemoveDirAndFiles(Address:string):boolean;
var
  DirList: TStringList; i: integer;
begin
  try
    Address:=StringReplace(UTF8ToAnsi(Address),'и?','й',[rfReplaceAll]);
    Address:=AnsiToUTF8(StringReplace(Address,'И?','Й',[rfReplaceAll]));

    DirList:=TStringList.Create;

    Form1.FDevice.GetFiles(Address,DirList);
    for i:=0 to DirList.Count-1 do
      Form1.FDevice.DeleteFile(Address+'/'+DirList.Strings[i]);

    DirList.Clear;

    Form1.FDevice.GetDirectories(Address,DirList);
    for i:=0 to DirList.Count-1 do
      if (DirList.Strings[i]<>'.') and (DirList.Strings[i]<>'..') then RemoveDirAndFiles(Address+'/'+DirList.Strings[i]);

    Form1.FDevice.DeleteDirectory(Address,true);
    DirList.Free;
    Result:=true;
  except
    Result:=false;
  end;
end;

procedure TForm1.N11Click(Sender: TObject);
begin
  if FileIndex[1]<>'2' then begin
    Delete(FileIndex,1,1);
    if Form1.FDevice.DeleteFile(AnsiToUtf8(Path+'/'+ExtractFileName(FileIndex))) then begin
      if length(FileIndex)>27 then FileIndex:=copy(FileIndex,1,27)+'...';
      StatusBar1.SimpleText:=' Файл "'+FileIndex+'" успешно удален'; Dir(Path); end else StatusBar1.SimpleText:=' Не удается удалить файл "'+FileIndex+'"';
  end else begin
      Delete(FileIndex,1,1);
      if RemoveDirAndFiles(AnsiToUtf8(Path+'/'+ExtractFileName(FileIndex))) then begin
      StatusBar1.SimpleText:=' Папка "'+FileIndex+'" успешно удалена'; Dir(Path); end else StatusBar1.SimpleText:=' Не удается удалить папку "'+FileIndex+'"';
  end;
end;

procedure TForm1.N1Click(Sender: TObject);
var
  NameDir: string;
begin
  if InputQuery(Application.Title, 'Введите название папки', NameDir) then
    if Trim(NameDir)<>'' then begin
      if Form1.FDevice.Exists(AnsiToUtf8(Path+'/'+NameDir)) then StatusBar1.SimpleText:=' Такая папка уже существует' else begin
        Form1.FDevice.CreateDirectory(AnsiToUtf8(Path+'/'+NameDir));
        Dir(Path);
        StatusBar1.SimpleText:=' Папка "'+NameDir+'" успешно создана';
      end;
    end else StatusBar1.SimpleText:=' Неверно задано имя папки';
end;

procedure TForm1.StatusBar1Click(Sender: TObject);
begin
  Application.MessageBox('iOS Sync 0.3.2'+#13#10+'Последнее обновление: 30.08.2016'+#13#10+'http://r57zone.github.io'+#13#10+'r57zone@gmail.com','О программе...',0);
end;

procedure SendMessageToHandle(TRGWND:hwnd;MsgToHandle:string);
var
  CDS: TCopyDataStruct;
begin
  CDS.dwData:=0;
  CDS.cbData:=(length(MsgToHandle)+ 1)*SizeOf(char);
  CDS.lpData:=PChar(MsgToHandle);
  SendMessage(TRGWND,WM_COPYDATA, Integer(Application.Handle), Integer(@CDS));
end;

procedure TForm1.WMCopyData(var msg: TWMCopyData); //Standard modular program
var
  SyncList: TStringList; i, Count, GoodCount:integer;
begin
  if PChar(TWMCopyData(msg).CopyDataStruct.lpData)='WORK' then SendMessageToHandle(FindWindow(nil,'PodCast Easy'),'YES');

  if copy(PChar(TWMCopyData(msg).CopyDataStruct.lpData),1,13)='FILES TO SYNC' then begin
    while not ListCompleted do begin Sleep(15); Application.ProcessMessages; end;
    Count:=0;
    GoodCount:=0;
    SyncList:=TStringList.Create;
    SyncList.Text:=PChar(TWMCopyData(msg).CopyDataStruct.lpData);
    SyncList.Delete(0);
    for i:=0 to SyncList.Count-1 do begin
      inc(Count);
      StatusBar1.SimpleText:=' Идет копирование файлов ('+IntToStr(i+1)+' из '+IntToStr(SyncList.Count)+')';
      if FileExists(SyncList.Strings[i]) then begin
        if UploadFile(SyncList.Strings[i],Path) then inc(GoodCount); end else
        if DirectoryExists(SyncList.Strings[i]) then if UploadDir(SyncList.Strings[i]+'\',Path) then inc(GoodCount);
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
  NewName: string;
begin
  if (FileIndex[1]<>'0') and (FileIndex[1]<>'1') then Delete(FileIndex,1,1);
  NewName:=FileIndex;
  if InputQuery(Application.Title, 'Введите новое имя файла', NewName) then
    if Trim(NewName)<>'' then begin
      if FDevice.Rename(AnsiToUtf8(Path+'/'+FileIndex),AnsiToUtf8(Path+'/'+NewName)) then StatusBar1.SimpleText:=' Название успешно изменено' else StatusBar1.SimpleText:=' Название не удалось изменить';
      Dir(Path);
    end else StatusBar1.SimpleText:=' Неверно задано название';
end;

function BrowseFolderDialog(title:PChar):string;
var
  TitleName: string;
  lpItemid: pItemIdList;
  BrowseInfo: TBrowseInfo;
  DisplayName: array[0..max_Path] of char;
  TempPath: array[0..max_Path] of char;
begin
  FillChar(BrowseInfo,SizeOf(tBrowseInfo),#0);
  BrowseInfo.hwndowner:=GetDesktopWindow;
  BrowseInfo.pSzDisplayName:=@DisplayName;
  TitleName:=title;
  BrowseInfo.lpSzTitle:=PChar(TitleName);
  BrowseInfo.ulFlags:=bIf_ReturnOnlyFSDirs;
  lpItemId:=shBrowseForFolder(BrowseInfo);
  if lpItemId<>nil then begin
    shGetPathFromIdList(lpItemId, TempPath);
    Result:=TempPath;
    GlobalFreePtr(lpitemid);
  end;
end;

function DownloadFile(Address,LocalPath:string):boolean;
var
  RemoteFileSize: int64;
  AMobileFile: TAMobileDeviceFileStream;
  LocalFile: TFileStream;
begin
  RemoteFileSize:=Form1.FDevice.GetFileSize(Address);
  LocalFile:=TFileStream.Create(LocalPath+'\'+UTF8ToAnsi(ExtractFileName(StringReplace(Address,'/','\',[rfReplaceAll]))),fmCreate);
  try
    AMobileFile:=TAMobileDeviceFileStream.Create(Form1.FDevice,Address,omRead);
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

function DownloadDir(Address,LocalPath:string):boolean;
var
  DirList: TStringList; i: integer;
begin
  try
    Address:=StringReplace(UTF8ToAnsi(Address),'и?','й',[rfReplaceAll]);
    Address:=AnsiToUTF8(StringReplace(Address,'И?','Й',[rfReplaceAll]));

    CreateDir(LocalPath+'\'+UTF8ToAnsi(ExtractFileName(StringReplace(Address,'/','\',[rfReplaceAll]))));
    DirList:=TStringList.Create;

    Form1.FDevice.GetFiles(Address,DirList);
    for i:=0 to DirList.Count-1 do
      DownloadFile(Address+'/'+DirList.Strings[i],LocalPath+'\'+UTF8ToAnsi(ExtractFileName(StringReplace(Address,'/','\',[rfReplaceAll]))));

    DirList.Clear;

    Form1.FDevice.GetDirectories(Address,DirList);
    for i:=0 to DirList.Count-1 do
      if (DirList.Strings[i]<>'.') and (DirList.Strings[i]<>'..') then DownloadDir(Address+'/'+DirList.Strings[i],LocalPath+'\'+UTF8ToAnsi(ExtractFileName(StringReplace(Address,'/','\',[rfReplaceAll]))));

    DirList.Free;
    Result:=true;
  except
    Result:=false;
  end;
end;

procedure TForm1.N4Click(Sender: TObject);
var
  TempPath: string;
begin
  TempPath:=BrowseFolderDialog('Выберите каталог');
  if TempPath<>'' then begin
    if FileIndex[1]<>'2' then begin
      Delete(FileIndex,1,1);
      StatusBar1.SimpleText:=' Идет копирование файла';
      if DownloadFile(AnsiToUtf8(Path+'/'+FileIndex),TempPath) then StatusBar1.SimpleText:=' Файл успешно скопирован' else
        StatusBar1.SimpleText:=' В процессе копирования произошла ошибка';
    end else begin
      Delete(FileIndex,1,1);
      StatusBar1.SimpleText:=' Идет копирование файлов';
      if DownloadDir(AnsiToUtf8(Path+'/'+FileIndex),TempPath) then StatusBar1.SimpleText:=' Копирование успешно завершено' else
        StatusBar1.SimpleText:=' В процессе копирования произошла ошибка';
    end;
  end else StatusBar1.SimpleText:=' Не выбран каталог';
end;

procedure TForm1.ListView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ListView1.ItemIndex<>-1 then begin
    if Key=13 then begin
      case ListView1.Items[ListView1.ItemIndex].ImageIndex of
        1: Dir('/');
        0: if Path<>'/' then begin Delete(Path,pos(ExtractFileName(StringReplace(Path,'/','\',[rfReplaceAll])),Path)-1,length(ExtractFileName(StringReplace(Path,'/','\',[rfReplaceAll])))+1); Dir(Path); end;
        2: if Path='/' then Dir(Path+ListView1.Items[ListView1.ItemIndex].Caption) else Dir(Path+'/'+ListView1.Items[ListView1.ItemIndex].Caption);
      end;
    end;
  end;
end;

end.
