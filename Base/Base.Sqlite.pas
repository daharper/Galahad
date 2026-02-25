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

  ISqliteContextPayload = interface
    ['{2282CCAE-6060-44A3-8505-F07C575AF452}']
    function Options: TSqliteOptions;
  end;

  TSqliteContextPayload = class(TTransient, ISqliteContextPayload)
  private
    fOptions: TSqliteOptions;
  public
    constructor Create(const aOptions: TSqliteOptions);
    function Options: TSqliteOptions;
    function Fingerprint: string;
  end;

  TSqliteContext = class(TTransient, IDbContext)
  private
    fName: string;
    fPayload: IInterface; // actually ISqliteContextPayload
  public
    constructor Create(const aOptions: TSqliteOptions; const aName: string = 'default');

    function ProviderId: string;
    function Name: string;
    function Payload: IInterface;
  end;

  TSqliteSession = class(TTransient, IDbSession)
  private
    fDriver: TFDPhysSQLiteDriverLink;
    fConnection: TFDConnection;

    procedure ApplySqlitePolicy(const aOpt: TSqliteOptions);
  public
    constructor Create(const aOpt: TSqliteOptions);
    destructor Destroy; override;

    function Connection: TFDConnection;
    function NewQuery: TFDQuery;

    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;

    function GetSchemaVersion: Integer;
    procedure SetSchemaVersion(const Value: Integer);
  end;

  TSqliteSessionFactory = class(TSingleton, IDbSessionFactory)
  public
    function OpenSession(const aCtx: IDbContext): IDbSession;
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

{ TSqliteOptions }

{----------------------------------------------------------------------------------------------------------------------}
class function TSqliteOptions.Defaults: TSqliteOptions;
begin
  Result.DatabasePath := '';
  Result.BusyTimeoutMs := 500;

  Result.ForeignKeys := fkOn;
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

{ TSqliteSession }

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteSession.ApplySqlitePolicy(const aOpt: TSqliteOptions);
var
  S: string;
begin
  // Foreign keys
  if aOpt.ForeignKeys <> fkUnset then
  begin
    S := SqliteForeignKeysToPragma(aOpt.ForeignKeys); // 'ON' / 'OFF'
    fConnection.ExecSQL('PRAGMA foreign_keys = ' + S + ';');
  end;

  // Journal mode
  if aOpt.JournalMode <> jmUnset then
  begin
    S := SqliteJournalModeToPragma(aOpt.JournalMode); // 'WAL', 'DELETE', ...
    fConnection.ExecSQL('PRAGMA journal_mode = ' + S + ';');
  end;

  // Synchronous
  if aOpt.Synchronous <> syUnset then
  begin
    S := SqliteSynchronousToPragma(aOpt.Synchronous); // 'NORMAL', 'FULL', ...
    fConnection.ExecSQL('PRAGMA synchronous = ' + S + ';');
  end;
end;
{----------------------------------------------------------------------------------------------------------------------}
function TSqliteSession.Connection: TFDConnection;
begin
  Result := fConnection;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteSession.NewQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := fConnection;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteSession.StartTransaction;
begin
  fConnection.StartTransaction;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteSession.Commit;
begin
  fConnection.Commit;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteSession.Rollback;
begin
  fConnection.Rollback;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteSession.GetSchemaVersion: Integer;
begin
  Result := fConnection.ExecSQLScalar('PRAGMA user_version');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteSession.SetSchemaVersion(const Value: Integer);
begin
  fConnection.ExecSQL('PRAGMA user_version = ' + IntToStr(Value) + ';');
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSqliteSession.Create(const aOpt: TSqliteOptions);
begin
  inherited Create;

  // Validate should have been done when building the context, but
  // defensive checks here are cheap and prevent misuse.
  if Trim(aOpt.DatabasePath) = '' then
    raise EArgumentException.Create('SQLite DatabasePath is required.');

  // v0.1 simple: driver link per session (can be lifted to singleton later)
  fDriver := TFDPhysSQLiteDriverLink.Create(nil);
  fDriver.DriverID := 'SQLite';

  fConnection := TFDConnection.Create(nil);
  fConnection.LoginPrompt := False;

  fConnection.Params.Clear;
  fConnection.Params.DriverID := 'SQLite';
  fConnection.Params.Database := aOpt.DatabasePath;

  if aOpt.BusyTimeoutMs > 0 then
    fConnection.Params.Values['BusyTimeout'] := IntToStr(aOpt.BusyTimeoutMs);

  fConnection.Connected := True;

  ApplySqlitePolicy(aOpt);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TSqliteSession.Destroy;
begin
  if Assigned(fConnection) then
    fConnection.Connected := False;

  fConnection.Free;
  fDriver.Free;

  inherited;
end;

{ TSqliteSessionFactory }

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteSessionFactory.OpenSession(const aCtx: IDbContext): IDbSession;
var
  payload: ISqliteContextPayload;
begin
  if (aCtx = nil) then
    raise EArgumentNilException.Create('aCtx');

  if not SameText(aCtx.ProviderId, 'sqlite') then
    raise Exception.Create('TSqliteSessionFactory cannot open a non-sqlite context.');

  if not Supports(aCtx.Payload, ISqliteContextPayload, payload) then
    raise Exception.Create('SQLite context payload missing or wrong type.');

  Result := TSqliteSession.Create(payload.Options);
end;


{ TSqliteContextPayload }

{----------------------------------------------------------------------------------------------------------------------}
constructor TSqliteContextPayload.Create(const aOptions: TSqliteOptions);
begin
  inherited Create;

  fOptions := aOptions;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteContextPayload.Fingerprint: string;
begin
 // Stable "config identity" for caching purposes
  Result :=
    fOptions.DatabasePath + '|' +
    IntToStr(fOptions.BusyTimeoutMs) + '|' +
    IntToStr(Ord(fOptions.ForeignKeys)) + '|' +
    IntToStr(Ord(fOptions.JournalMode)) + '|' +
    IntToStr(Ord(fOptions.Synchronous));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteContextPayload.Options: TSqliteOptions;
begin
  Result := fOptions;
end;

{ TSqliteContext }

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteContext.Name: string;
begin
  Result := fName;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteContext.ProviderId: string;
begin
  Result := 'sqlite';
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteContext.Payload: IInterface;
begin
 Result := fPayload;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSqliteContext.Create(const aOptions: TSqliteOptions; const aName: string);
begin
  inherited Create;

  fName := aName;
  fPayload := TSqliteContextPayload.Create(aOptions);
end;

end.
