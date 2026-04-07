{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Files
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Provides basic file utility functions.
-----------------------------------------------------------------------------------------------------------------------}

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
    function DataPath: string;

    function GetDatabasePath(const aName: string): string;
    function GetDocumentPath(const aName: string): string;
  end;

  /// <summary>
  ///  Suitable for self-contained applications that access folders and files
  ///  within their startup folder:
  ///
  ///  - Settings.xml
  ///  - docs/
  ///  - data/
  ///
  /// </summary>
  TStandardFileService = class(TSingleton, IFileService)
  private
    fStartupPath:   string;
    fDataPath:      string;
    fDocumentsPath: string;
    fSettingsPath:  string;
  public
    function StartupPath: string;
    function DocumentsPath: string;
    function SettingsPath: string;
    function DataPath: string;

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
function TStandardFileService.GetDatabasePath(const aName: string): string;
begin
  Result := if TPath.IsPathRooted(aName) then aName else TPath.Combine(fDataPath, aName);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TStandardFileService.GetDocumentPath(const aName: string): string;
begin
  Result := TPath.Combine(fDocumentsPath, aName);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TStandardFileService.DocumentsPath: string;
begin
  Result := fDocumentsPath;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TStandardFileService.SettingsPath: string;
begin
  Result := fSettingsPath;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TStandardFileService.StartupPath: string;
begin
  Result := fStartupPath;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TStandardFileService.DataPath: string;
begin
  Result := fDataPath;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TStandardFileService.Create;
begin
  inherited Create;

  { simple for v0.1 }

  fStartupPath   := ExtractFileDir(ParamStr(0));
  fDataPath      := TPath.Combine(fStartupPath, 'data');
  fDocumentsPath := TPath.Combine(fStartupPath, 'docs');
  fSettingsPath  := TPath.Combine(fStartupPath, 'Settings.xml');

  if not TDirectory.Exists(fDocumentsPath) then
    TDirectory.CreateDirectory(fDocumentsPath);

  if not TDirectory.Exists(fDataPath) then
    TDirectory.CreateDirectory(fDataPath);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TStandardFileService.Destroy;
begin

  inherited;
end;

end.
