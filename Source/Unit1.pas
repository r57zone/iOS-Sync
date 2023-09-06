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
    ListView: TListView;
    StatusBar1: TStatusBar;
    PopupMenu1: TPopupMenu;
    RemoveBtn: TMenuItem;
    N2: TMenuItem;
    RenameBtn: TMenuItem;
    CopyBtn: TMenuItem;
    CreateBtn: TMenuItem;
    CreateFolderBtn: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ListViewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure RemoveBtnClick(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
    procedure RenameBtnClick(Sender: TObject);
    procedure CopyBtnClick(Sender: TObject);
    procedure ListViewKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CreateFolderBtnClick(Sender: TObject);
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

  ID_CONNECTED, ID_DISCONNECTED, ID_COPY_FILES, ID_SUCCESSFUL_COPY_FILES,
  ID_COPY_FILES_ERROR, ID_TITLE_UPLOAD, ID_SUCCESSFUL_REMOVE_FILE,
  ID_REMOVE_FILE_ERROR, ID_SUCCESSFUL_REMOVE_FOLDER, ID_REMOVE_FOLDER_ERROR: string;
  ID_ENTER_NEW_FILENAME, ID_SUCCESSFUL_CHANGED_FILENAME, ID_ERROR_CHANGED_FILENAME,
  ID_WRONG_FILENAME, ID_SELECT_FOLDER, ID_FOLDER_NOT_SELECTED, ID_COPY_FILE, ID_COPY_FILES2,
  ID_SUCCESSFUL_COPY_FILE, ID_SUCCESSFUL_COPY, ID_ERROR_COPY_FILES,
  ID_ENTER_FOLDER_NAME, ID_FOLDER_EXISTS, ID_SUCCESSFUL_CREATE_FOLDER, ID_WRONG_FOLDER_NAME,
  ID_LAST_UPDATE, ID_ABOUT_TITLE: string;

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
    StatusBar1.SimpleText:=ID_CONNECTED;
    Dir(Path);
  end;
end;

function EmptyFunc:boolean;
begin

end;

function GetLocaleInformation(Flag: Integer): string;
var
  pcLCA: array [0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, Flag, pcLCA, 19) <= 0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Ini:TIniFile;
begin
  DragAcceptFiles(Handle, True);
  Application.Title:=Caption;
  //Button1.ControlState:=[csFocusing];
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  Path:=Ini.ReadString('Main', 'Path', '/');
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
  ListView.Columns[0].Width:=ListView.Width-30;
  //ListView1.Perform(LVM_SETCOLUMNWIDTH, 0, 200);

  if ParamCount > 0 then Path:=ParamStr(1);

  // Перевод / Translate
  if GetLocaleInformation(LOCALE_SENGLANGUAGE) <> 'Russian' then begin
    ID_CONNECTED:=' Device connected';
    ID_DISCONNECTED:=' Device not connected';
    ID_COPY_FILES:=' Files are being copied: %d of %d';
    ID_SUCCESSFUL_COPY_FILES:=' All files copied successfully';
    ID_COPY_FILES_ERROR:=' An error occurred during the copy process';
    ID_TITLE_UPLOAD:='upload';
    ID_SUCCESSFUL_REMOVE_FILE:=' File "%s" deleted successfully';
    ID_REMOVE_FILE_ERROR:=' Can''t delete file "%s"';
    ID_SUCCESSFUL_REMOVE_FOLDER:=' Folder "%s" was successfully removed';
    ID_REMOVE_FOLDER_ERROR:=' Unable to remove folder "%s"';
    ID_ENTER_NEW_FILENAME:='Enter a new filename';
    ID_SUCCESSFUL_CHANGED_FILENAME:=' Name changed successfully';
    ID_ERROR_CHANGED_FILENAME:=' The name could not be changed';
    ID_WRONG_FILENAME:=' Wrong title';
    ID_SELECT_FOLDER:='Select folder';
    ID_FOLDER_NOT_SELECTED:=' Folder not selected';
    ID_COPY_FILE:=' File is being copied';
    ID_SUCCESSFUL_COPY_FILE:=' File copied successfully';
    ID_COPY_FILES2:=' Files being copied';
    ID_SUCCESSFUL_COPY:=' Copy completed successfully';
    ID_ERROR_COPY_FILES:=' An error occurred while copying';
    ID_ENTER_FOLDER_NAME:='Enter folder name';
    ID_FOLDER_EXISTS:=' This folder already exists';
    ID_SUCCESSFUL_CREATE_FOLDER:=' Folder "s" created successfully';
    ID_WRONG_FOLDER_NAME:=' Invalid folder name';
    ID_LAST_UPDATE:='Last update:';
    ID_ABOUT_TITLE:='About..';

    CopyBtn.Caption:='Copy';
    RenameBtn.Caption:='Rename';
    RemoveBtn.Caption:='Remove';
    CreateBtn.Caption:='Create';
    CreateFolderBtn.Caption:='Folder';

    StatusBar1.SimpleText:=ID_DISCONNECTED;
  end else begin
    ID_CONNECTED:=' Устройство подключено';
    ID_DISCONNECTED:=' Устройство отключено';
    ID_COPY_FILES:=' Идет копирование файлов: %d из %d';
    ID_SUCCESSFUL_COPY_FILES:=' Все файлы успешно загружены';
    ID_COPY_FILES_ERROR:=' В процессе загрузки произошла ошибка';
    ID_TITLE_UPLOAD:='загрузка';
    ID_SUCCESSFUL_REMOVE_FILE:=' Файл "%s" успешно удален';
    ID_REMOVE_FILE_ERROR:=' Не удается удалить файл "%s"';
    ID_SUCCESSFUL_REMOVE_FOLDER:=' Папка "%s" успешно удалена';
    ID_REMOVE_FOLDER_ERROR:=' Не удается удалить папку "%s"';
    ID_ENTER_NEW_FILENAME:='Введите новое имя файла';
    ID_SUCCESSFUL_CHANGED_FILENAME:=' Название успешно изменено';
    ID_ERROR_CHANGED_FILENAME:=' Название не удалось изменить';
    ID_WRONG_FILENAME:=' Неверно задано название';
    ID_SELECT_FOLDER:='Выберите каталог';
    ID_FOLDER_NOT_SELECTED:=' Не выбран каталог';
    ID_COPY_FILE:=' Идет копирование файла';
    ID_SUCCESSFUL_COPY_FILE:=' Файл успешно скопирован';
    ID_COPY_FILES:=' Идет копирование файлов';
    ID_SUCCESSFUL_COPY:=' Копирование успешно завершено';
    ID_ERROR_COPY_FILES:=' В процессе копирования произошла ошибка';
    ID_ENTER_FOLDER_NAME:='Введите название папки';
    ID_FOLDER_EXISTS:=' Такая папка уже существует';
    ID_SUCCESSFUL_CREATE_FOLDER:=' Папка "s" успешно создана';
    ID_WRONG_FOLDER_NAME:=' Неверно задано имя папки';
    ID_LAST_UPDATE:='Последнее обновление:';
    ID_ABOUT_TITLE:='О программе...';
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(lpAMobileDeviceModule) then
    lpAMobileDeviceModule.Destroy;
end;

procedure TForm1.DoOnDeviceDisconnect(Sender: TObject;
  Device: TAMoblieDevice);
begin
  ListView.Clear;
  Connected:=false;
  StatusBar1.SimpleText:=ID_DISCONNECTED;
  Caption:='iOS Sync';
end;

procedure TForm1.Dir(Address: string);
var
  Item: TListItem; i: integer; DirList: TStringList;
begin
  ListCompleted:=false;
  ListView.Clear;

  if Trim(Address)='' then Address:='/';

  if (Address<>'/') then begin
    Item:=ListView.Items.Add;
    Item.Caption:='.';
    Item.SubItems.Add('');
    Item.ImageIndex:=1;

    Item:=ListView.Items.Add;
    Item.Caption:='..';
    Item.SubItems.Add('');
    Item.ImageIndex:=0;
  end;

  DirList:=TStringList.Create;
  FDevice.GetDirectories(AnsiToUTF8(Address),DirList);

  for i:=0 to DirList.Count-1 do begin
    Item:=ListView.Items.Add;
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
    Item:=ListView.Items.Add;
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

procedure TForm1.ListViewMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if ListView.ItemIndex = -1 then Exit;
  if Button = mbLeft then
    case ListView.Items[ListView.ItemIndex].ImageIndex of
      1: Dir('/');
      0: if Path<>'/' then begin Delete(Path,pos(ExtractFileName(StringReplace(Path,'/','\',[rfReplaceAll])),Path)-1,length(ExtractFileName(StringReplace(Path,'/','\',[rfReplaceAll])))+1); Dir(Path); end;
      2: if Path='/' then Dir(Path+ListView.Items[ListView.ItemIndex].Caption) else Dir(Path+'/'+ListView.Items[ListView.ItemIndex].Caption);
    end;
  if Button = mbRight then
    if (ListView.Items[ListView.ItemIndex].ImageIndex <> 0) and (ListView.Items[ListView.ItemIndex].ImageIndex <> 1) then begin
      FileIndex:=IntToStr(ListView.Items[ListView.ItemIndex].ImageIndex)+ListView.Items[ListView.ItemIndex].Caption;
      PopupMenu1.Popup(Mouse.CursorPos.X,Mouse.CursorPos.Y);
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
      if Form1.FDevice.Exists(AnsiToUtf8(Address + '/' + ExtractFileName(Local))) then
        Form1.FDevice.DeleteFile(AnsiToUtf8(Address + '/' + ExtractFileName(Local)));

      AMobileFile:=TAMobileDeviceFileStream.Create(Form1.FDevice,AnsiToUtf8(Address + '/' + ExtractFileName(Local)), omWrite);
      AMobileFile.OnProgressStep:=Form1.DoOnFileTransStep;
      AMobileFile.CopyFrom(LocalFile,LocalFile.Size);
      AMobileFile.Destroy;
      Result:=true;
    except
      //on E:Exception do
      //ShowMessage(Local + '/' + ExtractFileName(StrPas(Filename)) + '  ' + E.Message);
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
    Form1.FDevice.CreateDirectory(AnsiToUTF8(Address + '/' + ExtractFileName(Copy(LocalPath, 1, Length(LocalPath) - 1))));

    if FindFirst(LocalPath + '*.*', faAnyFile, SR) = 0 then begin
      repeat
        if (SR.Attr <> faDirectory) then
          UploadFile(LocalPath + SR.Name, Address + '/' + ExtractFileName(Copy(LocalPath, 1, Length(LocalPath) - 1)));
      until FindNext(SR)<>0;
      FindClose(SR);
    end;

    if FindFirst(LocalPath + '*', faAnyFile, SR) = 0 then begin
      repeat
        if (SR.Attr = faDirectory) and (SR.Name <> '.') and (SR.Name <> '..') then
          UploadDir(LocalPath + SR.Name + '\', Address + '/' + ExtractFileName(Copy(LocalPath, 1, Length(LocalPath) -1)));
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
  MyCaption: string;
begin
  if Connected then begin

    MyCaption:=Caption;
    Caption:=Application.Title + ': ' + ID_TITLE_UPLOAD;
    Count:=0;
    GoodCount:=0;

    inherited;
    Amount:=DragQueryFile(Msg.WParam, $FFFFFFFF, Filename, 255);
    for i:=0 to (Amount - 1) do begin
      Size:=DragQueryFile(Msg.WParam, i, nil, 0) + 1;
      Filename:=StrAlloc(Size);
      DragQueryFile(Msg.WParam, i, Filename, Size);
      Inc(Count);

      StatusBar1.SimpleText:=Format(ID_COPY_FILES, [IntToStr(i + 1), IntToStr(Amount)]);

      if FileExists(StrPas(Filename)) and (Pos('?', StrPas(Filename)) = 0) then begin
        if UploadFile(StrPas(Filename),Path) then Inc(GoodCount);
      end else if DirectoryExists(StrPas(Filename)) and (Pos('?',StrPas(Filename)) = 0) then
        if UploadDir(StrPas(Filename)+'\',Path) then Inc(GoodCount);

        StrDispose(Filename);
      end;
    DragFinish(Msg.WParam);

    Dir(Path);

    if Count = GoodCount then
      StatusBar1.SimpleText:=ID_SUCCESSFUL_COPY_FILES
    else
      StatusBar1.SimpleText:=ID_COPY_FILES_ERROR;

    Caption:=MyCaption;

  end else StatusBar1.SimpleText:=ID_DISCONNECTED;
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
    Address:=StringReplace(UTF8ToAnsi(Address), 'и?', 'й',[rfReplaceAll]);
    Address:=AnsiToUTF8(StringReplace(Address, 'И?', 'Й',[rfReplaceAll]));

    DirList:=TStringList.Create;

    Form1.FDevice.GetFiles(Address,DirList);
    for i:=0 to DirList.Count - 1 do
      Form1.FDevice.DeleteFile(Address + '/' + DirList.Strings[i]);

    DirList.Clear;

    Form1.FDevice.GetDirectories(Address,DirList);
    for i:=0 to DirList.Count-1 do
      if (DirList.Strings[i] <> '.') and (DirList.Strings[i] <> '..') then
        RemoveDirAndFiles(Address + '/' + DirList.Strings[i]);

    Form1.FDevice.DeleteDirectory(Address, true);
    DirList.Free;
    Result:=true;
  except
    Result:=false;
  end;
end;

procedure TForm1.RemoveBtnClick(Sender: TObject);
begin
  if FileIndex[1] <> '2' then begin
    Delete(FileIndex, 1, 1);
    if Form1.FDevice.DeleteFile(AnsiToUtf8(Path+'/'+ExtractFileName(FileIndex))) then begin
      if length(FileIndex) > 27 then FileIndex:=copy(FileIndex, 1, 27) + '...';
      StatusBar1.SimpleText:=Format(ID_SUCCESSFUL_REMOVE_FILE, [FileIndex]); Dir(Path); end
    else StatusBar1.SimpleText:=Format(ID_REMOVE_FILE_ERROR, [FileIndex]);
  end else begin
      Delete(FileIndex, 1, 1);
      if RemoveDirAndFiles(AnsiToUtf8(Path+'/'+ExtractFileName(FileIndex))) then begin
        StatusBar1.SimpleText:=Format(ID_SUCCESSFUL_REMOVE_FOLDER, [FileIndex]);
        Dir(Path);
      end else
        StatusBar1.SimpleText:=Format(ID_REMOVE_FOLDER_ERROR, [FileIndex]);
  end;
end;

procedure TForm1.StatusBar1Click(Sender: TObject);
begin
  Application.MessageBox(PChar('iOS Sync' + ' 0.4' + #13#10 +
  ID_LAST_UPDATE + ' 06.09.2023' + #13#10 +
  'https://r57zone.github.io' + #13#10 +
  'r57zone@gmail.com'), PChar(ID_ABOUT_TITLE), MB_ICONINFORMATION);
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

procedure TForm1.WMCopyData(var msg: TWMCopyData); // Standard modular program
var
  SyncList: TStringList; i, Count, GoodCount:integer;
begin
  if PChar(TWMCopyData(msg).CopyDataStruct.lpData) = 'WORK' then
    SendMessageToHandle(FindWindow(nil,'PodCast Easy'),'YES');

  if Copy(PChar(TWMCopyData(msg).CopyDataStruct.lpData),1,13)='FILES TO SYNC' then begin
    while not ListCompleted do begin Sleep(15); Application.ProcessMessages; end;
    Count:=0;
    GoodCount:=0;
    SyncList:=TStringList.Create;
    SyncList.Text:=PChar(TWMCopyData(msg).CopyDataStruct.lpData);
    SyncList.Delete(0);
    for i:=0 to SyncList.Count-1 do begin
      Inc(Count);
      StatusBar1.SimpleText:=Format(ID_COPY_FILES, [IntToStr(i + 1), IntToStr(SyncList.Count)]);
      if FileExists(SyncList.Strings[i]) then begin
        if UploadFile(SyncList.Strings[i],Path) then Inc(GoodCount); end else
        if DirectoryExists(SyncList.Strings[i]) then
          if UploadDir(SyncList.Strings[i]+'\',Path) then Inc(GoodCount);
    end;
    if Count=GoodCount then begin
      StatusBar1.SimpleText:=ID_SUCCESSFUL_COPY_FILES;
      SendMessageToHandle(FindWindow(nil, 'PodCast Easy'), 'GOOD');
      Dir(Path);
    end else begin
      StatusBar1.SimpleText:=ID_COPY_FILES_ERROR;
      Dir(Path);
      SendMessageToHandle(FindWindow(nil, 'PodCast Easy'), 'BAD');
    end;
    SyncList.Free;
  end;

  msg.Result:=Integer(True);
end;

procedure TForm1.RenameBtnClick(Sender: TObject);
var
  NewName: string;
begin
  if (FileIndex[1] <> '0') and (FileIndex[1] <> '1') then
    Delete(FileIndex,1,1);
  NewName:=FileIndex;
  if InputQuery(Application.Title, ID_ENTER_NEW_FILENAME, NewName) then
    if Trim(NewName) <> '' then begin
      if FDevice.Rename(AnsiToUtf8(Path + '/' + FileIndex), AnsiToUtf8(Path + '/' + NewName)) then
        StatusBar1.SimpleText:=ID_SUCCESSFUL_CHANGED_FILENAME
      else
        StatusBar1.SimpleText:=ID_ERROR_CHANGED_FILENAME;
      Dir(Path);
    end else StatusBar1.SimpleText:=ID_WRONG_FILENAME;
end;

function BrowseFolderDialog(title:PChar): string;
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

function DownloadFile(Address,LocalPath:string): boolean;
var
  RemoteFileSize: int64;
  AMobileFile: TAMobileDeviceFileStream;
  LocalFile: TFileStream;
begin
  RemoteFileSize:=Form1.FDevice.GetFileSize(Address);
  LocalFile:=TFileStream.Create(LocalPath + '\' + UTF8ToAnsi(ExtractFileName(StringReplace(Address, '/', '\', [rfReplaceAll]))), fmCreate);
  try
    AMobileFile:=TAMobileDeviceFileStream.Create(Form1.FDevice, Address, omRead);
    AMobileFile.OnProgressStep:=Form1.DoOnFileTransStep;
    AMobileFile.Position:=0;
    LocalFile.CopyFrom(AMobileFile, RemoteFileSize);
    AMobileFile.Destroy;
    LocalFile.Destroy;
    Result:=true;
  except
    Result:=false;
  end;
end;

function DownloadDir(Address,LocalPath:string): boolean;
var
  DirList: TStringList; i: integer;
begin
  try
    Address:=StringReplace(UTF8ToAnsi(Address), 'и?', 'й', [rfReplaceAll]);
    Address:=AnsiToUTF8(StringReplace(Address, 'И?', 'Й', [rfReplaceAll]));

    CreateDir(LocalPath + '\' + UTF8ToAnsi(ExtractFileName(StringReplace(Address, '/', '\', [rfReplaceAll]))));
    DirList:=TStringList.Create;

    Form1.FDevice.GetFiles(Address, DirList);
    for i:=0 to DirList.Count - 1 do
      DownloadFile(Address + '/' + DirList.Strings[i], LocalPath+'\' + UTF8ToAnsi(ExtractFileName(StringReplace(Address, '/', '\', [rfReplaceAll]))));

    DirList.Clear;

    Form1.FDevice.GetDirectories(Address,DirList);
    for i:=0 to DirList.Count - 1 do
      if (DirList.Strings[i] <> '.') and (DirList.Strings[i] <> '..') then
        DownloadDir(Address + '/' + DirList.Strings[i], LocalPath + '\' + UTF8ToAnsi(ExtractFileName(StringReplace(Address, '/', '\', [rfReplaceAll]))));

    DirList.Free;
    Result:=true;
  except
    Result:=false;
  end;
end;

procedure TForm1.CopyBtnClick(Sender: TObject);
var
  TempPath: string;
begin
  TempPath:=BrowseFolderDialog(PChar(ID_SELECT_FOLDER));
  if TempPath <> '' then begin
    if FileIndex[1] <> '2' then begin
      Delete(FileIndex, 1, 1);
      StatusBar1.SimpleText:=ID_COPY_FILE;
      if DownloadFile(AnsiToUtf8(Path + '/'+FileIndex), TempPath) then
        StatusBar1.SimpleText:=ID_SUCCESSFUL_COPY_FILE
      else
        StatusBar1.SimpleText:=ID_ERROR_COPY_FILES;
    end else begin
      Delete(FileIndex, 1, 1);
      StatusBar1.SimpleText:=ID_SUCCESSFUL_COPY_FILES;
      if DownloadDir(AnsiToUtf8(Path+'/'+FileIndex),TempPath) then
        StatusBar1.SimpleText:=ID_SUCCESSFUL_COPY
      else
        StatusBar1.SimpleText:=ID_ERROR_COPY_FILES;
    end;
  end else
    StatusBar1.SimpleText:=ID_FOLDER_NOT_SELECTED;
end;

procedure TForm1.ListViewKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ListView.ItemIndex = -1 then Exit;
  if Key <> 13 then Exit;
  case ListView.Items[ListView.ItemIndex].ImageIndex of
    1: Dir('/');
    0: if Path <> '/' then begin
          Delete(Path, Pos(ExtractFileName(StringReplace(Path, '/', '\', [rfReplaceAll])), Path) - 1, Length(ExtractFileName(Path)) + 1);
          Dir(Path);
        end;
    2: if Path='/' then
          Dir(Path+ListView.Items[ListView.ItemIndex].Caption)
        else
          Dir(Path+'/'+ListView.Items[ListView.ItemIndex].Caption);
  end;
end;

procedure TForm1.CreateFolderBtnClick(Sender: TObject);
var
  NameDir: string;
begin
  if InputQuery(Application.Title, ID_ENTER_FOLDER_NAME, NameDir) then
    if Trim(NameDir)<>'' then begin
      if Form1.FDevice.Exists(AnsiToUtf8(Path+'/'+NameDir)) then StatusBar1.SimpleText:=ID_FOLDER_EXISTS else begin
        Form1.FDevice.CreateDirectory(AnsiToUtf8(Path+'/'+NameDir));
        Dir(Path);
        StatusBar1.SimpleText:=Format(ID_SUCCESSFUL_CREATE_FOLDER, [NameDir]);
      end;
    end else StatusBar1.SimpleText:=ID_WRONG_FOLDER_NAME;
end;

end.
