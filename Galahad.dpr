program Galahad;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Base.Integrity in 'Base\Base.Integrity.pas';

begin
  try
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
