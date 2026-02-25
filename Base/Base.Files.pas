unit Base.Files;

interface

uses
  Base.Core;

type
  IFileService = interface
    ['{22A50D33-BEFA-4D3C-A384-99F7D8A90992}']

    function StartupPath: string;
    function DocumentsPath: string;
    function SettingsPath: string;

    function GetDatabasePath(const aName: string): string;
    function GetDocumentPath(const aName: string): string;
  end;

  TFileService = class(TSingleton, IFileService)
  private
    fStartupPath: string;
    fDatabasePath: string;
    fDocumentsPath: string;
    fSettingsPath: string;
  public
    function StartupPath: string;
    function DocumentsPath: string;
    function SettingsPath: string;

    function GetDatabasePath(const aName: string): string;
    function GetDocumentPath(const aName: string): string;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils;

{ TFileService }

{----------------------------------------------------------------------------------------------------------------------}
function TFileService.GetDatabasePath(const aName: string): string;
begin
  Result := TPath.Combine(fDatabasePath, aName);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TFileService.GetDocumentPath(const aName: string): string;
begin
  Result := TPath.Combine(fDocumentsPath, aName);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TFileService.DocumentsPath: string;
begin
  Result := fDocumentsPath;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TFileService.SettingsPath: string;
begin
  Result := fSettingsPath;
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

  { simple for v0.1 }

  fStartupPath   := ExtractFileDir(ParamStr(0));
  fDatabasePath  := fStartupPath;
  fDocumentsPath := TPath.Combine(fStartupPath, 'docs');
  fSettingsPath  := TPath.Combine(fStartupPath, 'Settings.xml');

  if not TDirectory.Exists(fDocumentsPath) then
    TDirectory.CreateDirectory(fDocumentsPath);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TFileService.Destroy;
begin

  inherited;
end;

end.
