unit Base.Sqlite;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Rtti,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  FireDAC.VCLUI.Wait,
  FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  Data.DB,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  Base.Data,
  Base.Core;

type
  // Maps to PRAGMA journal_mode
  TSqliteJournalMode = (
    jmUnset,
    jmWAL,
    jmDelete,
    jmTruncate,
    jmPersist,
    jmMemory,
    jmOff
  );

  // Maps to PRAGMA synchronous
  TSqliteSynchronous = (
    syUnset,
    syOff,
    syNormal,
    syFull,
    syExtra
  );

  TSqliteForeignKeys = (
    fkUnset,
    fkOff,
    fkOn
  );

  TSqliteOptions = record
    DatabasePath: string;
    BusyTimeoutMs: Integer;
    ForeignKeys: TSqliteForeignKeys;
    JournalMode: TSqliteJournalMode;
    Synchronous: TSqliteSynchronous;

    procedure Validate;

    class operator Initialize;
    class function Defaults: TSqliteOptions; static;
  end;

  TSqliteConfigureProc = reference to procedure(var Opt: TSqliteOptions);

  IDbContext = interface
    ['{642ACC20-F09B-48C0-AAD4-4E024544F797}']

    function DatabasePath: string;
    function BusyTimeoutMs: Integer;
    function ForeignKeys: TSqliteForeignKeys;
    function JournalMode: TSqliteJournalMode;
    function Synchronous: TSqliteSynchronous;
  end;

  TSqliteContext = class(TSingleton, IDbContext)
  private
    fDatabasePath: string;
    fBusyTimeoutMs: Integer;
    fForeignKeys: TSqliteForeignKeys;
    fJournalMode: TSqliteJournalMode;
    fSynchronous: TSqliteSynchronous;
  public
    function DatabasePath: string; inline;
    function BusyTimeoutMs: Integer; inline;
    function ForeignKeys: TSqliteForeignKeys; inline;
    function JournalMode: TSqliteJournalMode; inline;
    function Synchronous: TSqliteSynchronous; inline;

    constructor Create(const aOptions: TSqliteOptions);
  end;

  TSqliteDatabase = class(TSingleton)
  private
    fExists: boolean;
    fPath: string;
  protected
    fDriver: TFDPhysSQLiteDriverLink;
    fConnection: TFDConnection;
    fQuery: TFDQuery;

    property Exists: boolean read fExists write fExists;
    property Path: string read fPath write fPath;

    constructor Create(const aPath: string);
  public
    function Connection: TFDConnection;
    function Query: TFDQuery;
    function GetDatabaseVersion: integer;

    procedure SetDatabaseVersion(const aVersion: integer);
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    procedure Truncate;

    destructor Destroy; override;
  end;

  function SqliteJournalModeToPragma(const aMode: TSqliteJournalMode): string;
  function SqliteSynchronousToPragma(const aSync: TSqliteSynchronous): string;
  function SqliteForeignKeysToPragma(const aKey: TSqliteForeignKeys): string;
  function HasJournalMode(const aMode: TSqliteJournalMode): Boolean; inline;
  function HasSynchronous(const aSync: TSqliteSynchronous): Boolean; inline;
  function HasForeignKeys(const aKey: TSqliteForeignKeys): Boolean; inline;
  function TryParseSqliteJournalMode(const aValue: string; out aMode: TSqliteJournalMode): Boolean;
  function TryParseSqliteSynchronous(const aValue: string; out aSync: TSqliteSynchronous): Boolean;

  /// <example>
  ///  Ctx := BuildSqliteContext(FileService.DatabasePath,
  ///     procedure(var opt: TSqliteOptions)
  ///     begin
  ///       opt.BusyTimeoutMs := Settings.DbBusyTimeoutMs;
  ///       opt.JournalMode := jmWAL;
  ///       opt.Synchronous := syNormal;
  ///       opt.ForeignKeys := fkOn;
  ///    end);
  ///
  ///  Ctx := BuildSqliteContext(FileService.DatabasePath, nil, false);
  /// </example>
  function BuildSqliteContext(
    const aDatabasePath: string;
    const aConfigure: TSqliteConfigureProc = nil;
    const aUseDefaults: Boolean = True
  ): IDbContext; overload;

  function BuildSqliteContext(const aOptions: TSqliteOptions): IDbContext; overload;

const
  CSqliteJournalModeNames: array[TSqliteJournalMode] of string = (
    '',
    'WAL',
    'DELETE',
    'TRUNCATE',
    'PERSIST',
    'MEMORY',
    'OFF'
  );

  CSqliteSynchronousNames: array[TSqliteSynchronous] of string = (
    '',
    'OFF',
    'NORMAL',
    'FULL',
    'EXTRA'
  );

  CSqliteForeignKeysNames: array[TSqliteForeignKeys] of string = (
    '', 'OFF', 'ON'
  );

implementation

uses
  System.StrUtils,
  System.IOUtils,
  System.Variants;

  {----------------------------------------------------------------------------------------------------------------------}
function SqliteJournalModeToPragma(const aMode: TSqliteJournalMode): string;
begin
  Result := CSqliteJournalModeNames[aMode];
end;

{----------------------------------------------------------------------------------------------------------------------}
function SqliteSynchronousToPragma(const aSync: TSqliteSynchronous): string;
begin
Result := CSqliteSynchronousNames[aSync];
end;

{----------------------------------------------------------------------------------------------------------------------}
function SqliteForeignKeysToPragma(const aKey: TSqliteForeignKeys): string;
begin
  Result := CSqliteForeignKeysNames[aKey];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TryParseSqliteJournalMode(const aValue: string; out aMode: TSqliteJournalMode): Boolean;
begin
  var idx := IndexText(Trim(aValue), CSqliteJournalModeNames);

  Result := idx >= 0;

  if Result then
    aMode := TSqliteJournalMode(Idx);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TryParseSqliteSynchronous(const aValue: string; out aSync: TSqliteSynchronous): Boolean;
begin
  var idx := IndexText(Trim(aValue), CSqliteSynchronousNames);

  Result := idx >= 0;

  if Result then
    aSync := TSqliteSynchronous(idx);
end;

{----------------------------------------------------------------------------------------------------------------------}
function HasJournalMode(const aMode: TSqliteJournalMode): Boolean;
begin
  Result := aMode <> jmUnset;
end;

{----------------------------------------------------------------------------------------------------------------------}
function HasSynchronous(const aSync: TSqliteSynchronous): Boolean;
begin
  Result := aSync <> syUnset;
end;

{----------------------------------------------------------------------------------------------------------------------}
function HasForeignKeys(const aKey: TSqliteForeignKeys): Boolean;
begin
  Result := aKey <> fkUnset;
end;

{----------------------------------------------------------------------------------------------------------------------}
function BuildSqliteContext(
  const aDatabasePath: string;
  const aConfigure: TSqliteConfigureProc = nil;
  const aUseDefaults: Boolean = True
): IDbContext;
var
  opt: TSqliteOptions;
begin

  if aUseDefaults then
    opt := TSqliteOptions.Defaults
  else
    opt := Default(TSqliteOptions);

  opt.DatabasePath := aDatabasePath;

  if Assigned(aConfigure) then
    aConfigure(opt);

  opt.Validate;

  Result := TSqliteContext.Create(opt);
end;

{----------------------------------------------------------------------------------------------------------------------}
function BuildSqliteContext(const aOptions: TSqliteOptions): IDbContext;
begin
  aOptions.Validate;
  Result := TSqliteContext.Create(aOptions);

  var opt := aOptions;

  opt.Validate;

  Result := TSqliteContext.Create(opt);
end;

{ TSqliteDatabase }

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteDatabase.Connection: TFDConnection;
begin
  Result := fConnection;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteDatabase.Query: TFDQuery;
begin
  Result := fQuery;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteDatabase.StartTransaction;
begin
  fConnection.StartTransaction
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteDatabase.Truncate;
begin
  fConnection.ExecSQL('PRAGMA wal_checkpoint(TRUNCATE);');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteDatabase.Commit;
begin
  fConnection.Commit;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteDatabase.Rollback;
begin
  fConnection.Rollback;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteDatabase.GetDatabaseVersion: integer;
begin
  if not fExists then exit(0);

  Result := fConnection.ExecSQLScalar('PRAGMA user_version');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteDatabase.SetDatabaseVersion(const aVersion: integer);
begin
  fConnection.ExecSQL('PRAGMA user_version = ' + IntToStr(aVersion));

  fExists := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSqliteDatabase.Create(const aPath: string);
begin
  fPath   := aPath;
  fExists := TFile.Exists(aPath);
  fDriver := TFDPhysSQLiteDriverLink.Create(nil);

  fDriver.DriverID := 'SQLiteDriver';

  fConnection := TFDConnection.Create(nil);

  fConnection.LoginPrompt := False;

  fConnection.Params.Clear;
  fConnection.Params.DriverID := 'SQLiteDriver';
  fConnection.Params.Database := fPath;
  fConnection.Params.Values['BusyTimeout'] := '500';

  fConnection.Connected := True;

  fConnection.ExecSQL('PRAGMA foreign_keys = ON;');
  fConnection.ExecSQL('PRAGMA journal_mode = WAL;');
  fConnection.ExecSQL('PRAGMA synchronous = NORMAL;');

  if fExists then Truncate;

  fQuery := TFDQuery.Create(nil);
  fQuery.Connection := fConnection;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TSqliteDatabase.Destroy;
begin
  fQuery.Close;

  fConnection.Connected := false;

  fQuery.Free;
  fConnection.Free;
  fDriver.Free;
end;

{ TSqliteOptions }

{----------------------------------------------------------------------------------------------------------------------}
class function TSqliteOptions.Defaults: TSqliteOptions;
begin
  Result.DatabasePath := '';
  Result.BusyTimeoutMs := 500;

  Result.ForeignKeys := True;
  Result.JournalMode := jmWAL;
  Result.Synchronous := syNormal;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TSqliteOptions.Initialize;
begin
  DatabasePath := '';
  BusyTimeoutMs := 0;
  ForeignKeys := fkUnset;
  JournalMode := jmUnset;
  Synchronous := syUnset;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteOptions.Validate;
begin
  if Trim(DatabasePath) = '' then
    raise EArgumentException.Create('SQLite DatabasePath is required.');

  if BusyTimeoutMs < 0 then
    raise EArgumentOutOfRangeException.Create('SQLite BusyTimeoutMs must be >= 0.');
end;

{ TSqliteContext }

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteContext.BusyTimeoutMs: Integer;
begin
  Result := fBusyTimeoutMs;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteContext.DatabasePath: string;
begin
  Result := fDatabasePath;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteContext.ForeignKeys: Boolean;
begin
  Result := fForeignKeys;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteContext.JournalMode: TSqliteJournalMode;
begin
  Result := fJournalMode;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteContext.Synchronous: TSqliteSynchronous;
begin
  Result := fSynchronous;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSqliteContext.Create(const aOptions: TSqliteOptions);
begin
  fBusyTimeoutMs := aOptions.BusyTimeoutMs;
  fDatabasePath  := aOptions.DatabasePath;
  fForeignKeys   := aOptions.ForeignKeys;
  fJournalMode   := aOptions.JournalMode;
  fSynchronous   := aOptions.Synchronous;
end;

end.
