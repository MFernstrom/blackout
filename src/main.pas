{
  __________.__                 __                 __
  \______   \  | _____    ____ |  | ______  __ ___/  |_
   |    |  _/  | \__  \ _/ ___\|  |/ /  _ \|  |  \   __\
   |    |   \  |__/ __ \\  \___|    <  <_> )  |  /|  |
   |______  /____(____  /\___  >__|_ \____/|____/ |__|
          \/          \/     \/     \/ v. 1.0.0

   License    Apache 2.0
   Author     Marcus Fernstrom
   Version    1.0.0
   About      Blacks out selected monitors while chosen programs are running
}
unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ExtCtrls, Menus, JwaTlHelp32, Windows, lclintf;

type

  { TGameSetting }

  TGameSetting = class
    exePath: string;
    monitor1, monitor2, monitor3: boolean;
    function getSerializedString: string;
    constructor Create(serialized: string);
  end;

  { TBlackoutForm }

  TBlackoutForm = class(TForm)
  private
    FIdentifier: TLabel;
    FMonitor: TMonitor;
    FIsActive: boolean;
  public
    procedure ShowSmall;
    procedure ShowFull;
    procedure DoHideForm;
    procedure SetupForm(TheMonitor: TMonitor; id: string);
    property Identifier: TLabel read FIdentifier write FIdentifier;
  end;

  { TMainForm }

  TMainForm = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    SelectExeButton: TBitBtn;
    DockedMenu: TPopupMenu;
    Image1: TImage;
    LogoImage: TImage;
    PatronImage: TImage;
    QuitMenuItem: TMenuItem;
    OpenMenuItem: TMenuItem;
    Shape2: TShape;
    GameSettingsBackdrop: TShape;
    ToggleMenuItem: TMenuItem;
    SaveGameSettingsButton: TBitBtn;
    BitBtn5: TBitBtn;
    IdentifyMonitorsButton: TBitBtn;
    Monitor1Checkbox: TCheckBox;
    Monitor2Checkbox: TCheckBox;
    Monitor3Checkbox: TCheckBox;
    GameSettingsGroupBox: TGroupBox;
    Label1: TLabel;
    exePathLabel: TLabeledEdit;
    OpenDialog1: TOpenDialog;
    TrackedProcessesListBox: TListBox;
    Shape1: TShape;
    Timer1: TTimer;
    MonitorIdentifyTimer: TTimer;
    TrayIcon1: TTrayIcon;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure SelectExeButtonClick(Sender: TObject);
    procedure IdentifyMonitorsButtonClick(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure PatronImageClick(Sender: TObject);
    procedure MonitorIdentifyTimerStartTimer(Sender: TObject);
    procedure MonitorIdentifyTimerTimer(Sender: TObject);
    procedure OpenMenuItemClick(Sender: TObject);
    procedure QuitMenuItemClick(Sender: TObject);
    procedure SaveGameSettingsButtonClick(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure SaveData;
    procedure LoadData;
    procedure ShowGameSettings;
    function GetExeStringFromProcID(PID: DWORD): string;
    procedure ToggleMenuItemClick(Sender: TObject);
    procedure TrackedProcessesListBoxSelectionChange(Sender: TObject);
    procedure runBlackout(gameSetting: TGameSetting);
    procedure hideBlackout;
    procedure toggleMonitoring;
    procedure DisableGameSettingsBox;
  private

  public

  end;

var
  mainForm: TMainForm;
  Blackout1, Blackout2, Blackout3: TBlackoutForm;
  CurrentlyBlanking: boolean;
  processList: TStringList;

const
  version = '1.0.0';

implementation

{$R *.lfm}

{ TBlackoutForm }

procedure TBlackoutForm.ShowSmall;
begin
  Height := 150;
  Width := 350;
  Identifier.Show;
  Show;
end;

procedure TBlackoutForm.ShowFull;
begin
  if FIsActive = False then
  begin
    FIsActive := True;
    Identifier.Hide;
    Show;
  end;

  Top := FMonitor.Top;
  Left := FMonitor.Left;
  Height := FMonitor.Height;
  Width := FMonitor.Width;
end;

procedure TBlackoutForm.DoHideForm;
begin
  FIsActive := False;
  Hide;
end;

procedure TBlackoutForm.SetupForm(TheMonitor: TMonitor; id: string);
begin
  FMonitor := TheMonitor;
  Left := FMonitor.Left;
  Top := FMonitor.Top;
  BorderStyle := bsNone;
  Color := clBlack;

  FormStyle := fsSystemStayOnTop;
  FIdentifier := TLabel.Create(nil);
  FIdentifier.Caption := 'Monitor ' + id;
  FIdentifier.Top := 30;
  FIdentifier.Left := 30;
  FIdentifier.Font.Color := clWhite;
  FIdentifier.Font.Size := 40;
  FIdentifier.Parent := Self;
end;

{ TGameSetting }

function TGameSetting.getSerializedString: string;
var
  ret: string;
begin
  ret := exePath;
  ret := ret + '|' + BoolToStr(monitor1);
  ret := ret + '|' + BoolToStr(monitor2);
  ret := ret + '|' + BoolToStr(monitor3);
  Result := ret;
end;

constructor TGameSetting.Create(serialized: string);
var
  parts: TStringList;
begin
  parts := TStringList.Create;
  try
    parts.Delimiter := '|';
    parts.StrictDelimiter := True;
    parts.DelimitedText := serialized;
    exePath := parts[0];
    monitor1 := StrToBool(parts[1]);
    monitor2 := StrToBool(parts[2]);
    monitor3 := StrToBool(parts[3]);
  finally
    parts.Free;
  end;
end;

{ TMainForm }

procedure TMainForm.BitBtn1Click(Sender: TObject);
begin
  toggleMonitoring;
end;

procedure TMainForm.BitBtn2Click(Sender: TObject);
var
  Reply, BoxStyle: integer;
begin
  BoxStyle := MB_ICONQUESTION + MB_YESNO;
  Reply := Application.MessageBox('Remove this Game setting?', 'Confirm', BoxStyle);

  if Reply = idYes then
  begin
    TrackedProcessesListBox.Items.Delete(TrackedProcessesListBox.ItemIndex);
    SaveData;
    DisableGameSettingsBox;
  end;
end;

procedure TMainForm.SelectExeButtonClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    exePathLabel.Caption := LowerCase(OpenDialog1.FileName);
end;

procedure TMainForm.IdentifyMonitorsButtonClick(Sender: TObject);
begin
  MonitorIdentifyTimer.Enabled := True;
end;

procedure TMainForm.FormWindowStateChange(Sender: TObject);
begin
  if WindowState = wsMinimized then
  begin
    WindowState := wsNormal;
    Hide;
    ShowInTaskBar := stNever;
  end;
end;

procedure TMainForm.PatronImageClick(Sender: TObject);
begin
  OpenURL('https://www.patreon.com/MarcusFernstrom');
end;

procedure TMainForm.MonitorIdentifyTimerStartTimer(Sender: TObject);
begin
  Blackout1.ShowSmall;
  if Screen.MonitorCount > 1 then
    Blackout2.ShowSmall;

  if Screen.MonitorCount > 2 then
    Blackout3.ShowSmall;
end;

procedure TMainForm.MonitorIdentifyTimerTimer(Sender: TObject);
begin
  Blackout1.DoHideForm;

  if Screen.MonitorCount > 1 then
    Blackout2.DoHideForm;

  if Screen.MonitorCount > 2 then
    Blackout3.DoHideForm;

  MonitorIdentifyTimer.Enabled := False;
end;

procedure TMainForm.OpenMenuItemClick(Sender: TObject);
begin
  mainForm.Show;
end;

procedure TMainForm.QuitMenuItemClick(Sender: TObject);
begin
  Halt(0);
end;

procedure TMainForm.SaveGameSettingsButtonClick(Sender: TObject);
var
  gameSettings: TGameSetting;
  itemIndex: Integer;
begin
  // Save current object
  itemIndex := TrackedProcessesListBox.ItemIndex;
  gameSettings := TrackedProcessesListBox.Items.Objects[itemIndex] as TGameSetting;
  gameSettings.exePath := LowerCase(exePathLabel.Caption);
  gameSettings.monitor1 := Monitor1Checkbox.Checked;
  gameSettings.monitor2 := Monitor2Checkbox.Checked;
  gameSettings.monitor3 := Monitor3Checkbox.Checked;
  TrackedProcessesListBox.Items.Objects[itemIndex] := gameSettings;
  TrackedProcessesListBox.Items[itemIndex] := ExtractFileName(gameSettings.exePath);

  SaveData;
end;

procedure TMainForm.BitBtn5Click(Sender: TObject);
var
  tmp: TGameSetting;
begin
  tmp := TGameSetting.Create('New|false|false|false');
  TrackedProcessesListBox.Items.AddObject('New', tmp);
  TrackedProcessesListBox.ItemIndex := TrackedProcessesListBox.Count - 1;
  TrackedProcessesListBox.Selected[TrackedProcessesListBox.ItemIndex] := True;
  ShowGameSettings;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption := Caption + ' ' + version;

  processList := TStringList.Create;
  CurrentlyBlanking := False;

  Blackout1 := TBlackoutForm.CreateNew(nil);
  Blackout1.SetupForm(Screen.Monitors[0], '1');

  if Screen.MonitorCount > 1 then begin
    Blackout2 := TBlackoutForm.CreateNew(nil);
    Blackout2.SetupForm(Screen.Monitors[1], '2');
  end;

  if Screen.MonitorCount > 2 then begin
    Blackout3 := TBlackoutForm.CreateNew(nil);
    Blackout3.SetupForm(Screen.Monitors[2], '3');
  end;

  LoadData;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  processList.Free;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
var
  pa: TProcessEntry32;
  RetVal: THandle;
  exename: string;
  gameSettings: TGameSetting;
  foundGame: boolean;
  i: integer;
begin
  exename := '';
  RetVal := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  pa.dwSize := sizeof(pa);
  processList.Clear;

  // Get first process
  if Process32First(RetVal, pa) then
    // Add process name to string list
    exename := GetExeStringFromProcID(pa.th32ProcessID);
  processList.Add(LowerCase(exename));

  begin
    // While we have process handle
    while Process32Next(RetVal, pa) do
    begin
      exename := GetExeStringFromProcID(pa.th32ProcessID);
      if processList[processList.Count - 1] <> exename then
        processList.Add(LowerCase(exename));
    end;
  end;

  // Have the list of processes, compare.

  foundGame := False;
  for i := 0 to TrackedProcessesListBox.Count - 1 do
  begin
    gameSettings := TrackedProcessesListBox.Items.Objects[i] as TGameSetting;
    if processList.IndexOf(gameSettings.exePath) <> -1 then
    begin
      foundGame := True;
      runBlackout(gameSettings);
      break;
    end;
  end;

  if foundGame = False then
    hideBlackout;
end;

procedure TMainForm.SaveData;
var
  GameSettings: TGameSetting;
  fileTs: TStringList;
  i: integer;
begin
  fileTs := TStringList.Create;
  try
    for i := 0 to TrackedProcessesListBox.Count - 1 do
    begin
      gameSettings := TrackedProcessesListBox.Items.Objects[i] as TGameSetting;
      fileTs.Add(GameSettings.getSerializedString);
    end;

    fileTs.SaveToFile('processes.dat');
  finally
    fileTs.Free;
  end;
end;

procedure TMainForm.LoadData;
var
  GameSettings: TGameSetting;
  fileTs: TStringList;
  i: integer;
begin
  if FileExists('processes.dat') = True then
  begin
    fileTs := TStringList.Create;
    fileTs.LoadFromFile('processes.dat');

    try
      for i := 0 to fileTs.Count - 1 do
      begin
        GameSettings := TGameSetting.Create(fileTs[i]);
        TrackedProcessesListBox.Items.AddObject(ExtractFileName(gameSettings.exePath),
          gameSettings);
      end;
    finally
      fileTs.Free;
    end;
  end;
end;

procedure TMainForm.ShowGameSettings;
var
  gameSettings: TGameSetting;
begin
  if TrackedProcessesListBox.ItemIndex <> -1 then
  begin
    GameSettingsBackdrop.Visible := true;
    GameSettingsGroupBox.Visible := true;

    gameSettings := TrackedProcessesListBox.Items.Objects[TrackedProcessesListBox.ItemIndex] as TGameSetting;

    if gameSettings.exePath = 'New' then
      exePathLabel.Text := 'Select an exe to watch for --->'
    else
    begin
      exePathLabel.Text := gameSettings.exePath;
    end;

    Monitor1Checkbox.Checked := gameSettings.monitor1;
    Monitor2Checkbox.Checked := gameSettings.monitor2;
    Monitor3Checkbox.Checked := gameSettings.monitor3;

    GameSettingsGroupBox.Enabled := True;
  end;
end;

function TMainForm.GetExeStringFromProcID(PID: DWORD): string;
var
  hModuleSnap: THandle;
  me: TModuleEntry32;
begin
  Result := '';
  hModuleSnap := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, PID);
  if hModuleSnap <> INVALID_HANDLE_VALUE then
  begin
    me.dwSize := SizeOf(TModuleEntry32);
    if Module32First(hModuleSnap, me) then
    begin
      if lowercase(ExtractFileExt(me.szExePath)) = '.exe' then
      begin
        Result := me.szExePath;
        CloseHandle(hModuleSnap);
        exit;
      end;
      while Module32Next(hModuleSnap, me) do
        if lowercase(ExtractFileExt(me.szExePath)) = '.exe' then
        begin
          Result := me.szExePath;
          break;
        end;
    end;
    CloseHandle(hModuleSnap);
  end;
end;

procedure TMainForm.ToggleMenuItemClick(Sender: TObject);
begin
  toggleMonitoring;
end;

procedure TMainForm.TrackedProcessesListBoxSelectionChange(Sender: TObject);
begin
  ShowGameSettings;
end;

procedure TMainForm.runBlackout(gameSetting: TGameSetting);
begin
  if gameSetting.monitor1 = True then
    Blackout1.ShowFull;
  if gameSetting.monitor2 = True then
    Blackout2.ShowFull;
  if gameSetting.monitor3 = True then
    Blackout3.ShowFull;
end;

procedure TMainForm.hideBlackout;
begin
  Blackout1.DoHideForm;
  Blackout2.DoHideForm;
  Blackout3.DoHideForm;
end;

procedure TMainForm.toggleMonitoring;
begin
  if Timer1.Enabled = False then
  begin
    BitBtn1.Caption := 'Stop monitoring';
    ToggleMenuItem.Caption := 'Stop monitoring';
    Timer1.Enabled := True;
  end
  else
  begin
    BitBtn1.Caption := 'Start monitoring';
    ToggleMenuItem.Caption := 'Start monitoring';
    Timer1.Enabled := False;
  end;
end;

procedure TMainForm.DisableGameSettingsBox;
begin
  exePathLabel.Caption := '';
  Monitor1Checkbox.Checked := False;
  Monitor2Checkbox.Checked := False;
  Monitor3Checkbox.Checked := False;
  GameSettingsGroupBox.Enabled := False;
end;

end.
