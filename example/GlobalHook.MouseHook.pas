unit GlobalHook.MouseHook;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation

function StartHook(idHook: Integer; lpfn: TFNHookProc): Boolean; stdcall;
  external 'GlobalHook.dll';
procedure StopHook; stdcall; external 'GlobalHook.dll';

procedure MouseProc(code: Integer; wparam: wparam; lparam: lparam);
var
  MHS: MouseHookStruct;
begin
  MHS := PMouseHookStruct(lparam)^;
  Form1.Memo1.Lines.Add(string.Format('%d,%d,%d', [MHS.pt.X, MHS.pt.Y,
    MHS.hwnd]));
end;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  Memo1.Lines.Clear;
  if StartHook(WH_MOUSE, @MouseProc) then
    Memo1.Lines.Add('Start')
  else
    Memo1.Lines.Add('Failed');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  StopHook;
  Memo1.Lines.Clear;
  Memo1.Lines.Add('Stop');
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  StopHook;
end;

end.
