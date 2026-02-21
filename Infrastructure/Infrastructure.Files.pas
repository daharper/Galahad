unit Infrastructure.Files;

interface

uses
  Base.Core,
  Application.Contracts;

type
  TFileService = class(TInterfacedObject, IFileService)
  private
    fStartupPath: string;
    fDatabasePath: string;
  public
    function StartupPath: string;
    function DatabasePath: string;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils;

{ TFileService }

{----------------------------------------------------------------------------------------------------------------------}
function TFileService.DatabasePath: string;
begin
  Result := fDatabasePath;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TFileService.StartupPath: string;
begin
  Result := fStartupPath;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TFileService.Create;
begin
  inherited Create;

  fStartupPath  := ExtractFileDir(ParamStr(0));
  fDatabasePath := TPath.Combine(fStartupPath, 'escape.db');
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TFileService.Destroy;
begin

  inherited;
end;


end.
