unit Hooks;

interface

uses
  Winapi.Windows;

function IsHooking: Boolean; stdcall;
function StartHook(idHook: Integer; lpfn: TFNHookProc): Boolean; stdcall;
procedure StopHook; stdcall;

implementation

type
  PShareObject = ^TShareObject;

  TShareObject = record
    HookHandle: HHOOK;
  end;

var
  HookProc: TFNHookProc;
  FileMappingObjectHandle: HWND;

const
  FileMappingObjectName = 'GlobalHook';

function Map(out AHandle: HWND; out AShareData: PShareObject): Boolean;
begin
  Result := False;
  AHandle := OpenFileMapping(FILE_MAP_ALL_ACCESS, False, FileMappingObjectName);
  if AHandle = 0 then
    Exit;

  AShareData := PShareObject(MapViewOfFile(AHandle, FILE_MAP_ALL_ACCESS,
    0, 0, 0));
  if AShareData = nil then
  begin
    CloseHandle(AHandle);
    AHandle := 0;
    Exit;
  end;
  Result := True;
end;

procedure Unmap(const AHandle: HWND; AShareData: PShareObject);
begin
  if AHandle <> 0 then
    CloseHandle(AHandle);

  if AShareData <> nil then
    UnmapViewOfFile(AShareData);
end;

function GetHookHandle: HHOOK;
var
  H: HWND;
  P: PShareObject;
begin
  Result := 0;
  if Map(H, P) then
  begin
    try
      Result := P^.HookHandle;
    finally
      Unmap(H, P);
    end;
  end;
end;

procedure SetHookHandle(const Value: HHOOK);
var
  H: HWND;
  P: PShareObject;
begin
  if Map(H, P) then
  begin
    try
      P^.HookHandle := Value;
    finally
      Unmap(H, P);
    end;
  end;
end;

function IsHooking: Boolean; stdcall;
begin
  Result := GetHookHandle <> 0;
end;

function Hook(code: Integer; wparam: wparam; lparam: lparam): LRESULT;
begin
  if code >= 0 then
    if Assigned(HookProc) then
      HookProc(code, wparam, lparam);
  Result := CallNextHookEx(GetHookHandle, code, wparam, lparam);
end;

/// <summary>
/// See https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-setwindowshookexa#parameters
/// </summary>
function StartHook(idHook: Integer; lpfn: TFNHookProc): Boolean; stdcall;
begin
  StopHook;
  HookProc := lpfn;
  SetHookHandle(SetWindowsHookEx(idHook, @Hook, HInstance, 0));
  Result := IsHooking;
end;

procedure StopHook; stdcall;
begin
  if IsHooking then
    UnhookWindowsHookEx(GetHookHandle);
  HookProc := nil;
  SetHookHandle(0);
end;

initialization

FileMappingObjectHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil,
  PAGE_READWRITE, 0, SizeOf(TShareObject), FileMappingObjectName);

finalization

if FileMappingObjectHandle <> 0 then
  CloseHandle(FileMappingObjectHandle);

end.
