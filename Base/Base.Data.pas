{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Data
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Provides simple data abstractions.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Data;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.TypInfo,
  System.Variants,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  Base.Core,
  Base.Files,
  Base.Integrity,
  Base.Dynamic,
  Base.Specifications,
  Base.Settings;

type
  IDbContextFingerprint = interface
    ['{A16A68A9-A17F-4975-B975-597C28DBB3F8}']
    function Fingerprint: string;
  end;

  IDbContext = interface
    ['{5A8FA1CA-DF84-4371-935A-2E0385F3CE04}']
    function ProviderId: string;   // e.g. 'sqlite'
    function Name: string;         // e.g. 'default'
    function Payload: IInterface;  // provider-specific, strongly-typed via interface cast
  end;

  IDbContextProvider = interface
    ['{7D9A8D2C-8E7D-4C11-9F4E-7C6D7E4B9A10}']
    function ProviderId: string; // e.g. 'sqlite'
    function BuildContext(const aFileService: IFileService; const Settings: ISettings): IDbContext;
  end;

  IDbContextFactory = interface
    ['{B9A7D1A2-2D5B-4A92-8E1E-0C4B1C6D9A33}']
    function BuildFromSettings(const Settings: ISettings): IDbContext;
  end;

  TDbContextFactory = class(TSingleton, IDbContextFactory)
  private
    fFileService: IFileService;
  public
    function BuildFromSettings(const Settings: ISettings): IDbContext;
    constructor Create(const aFileService: IFileService);
  end;

  IDbSession = interface
    ['{FC69B63A-0EA7-4C27-9641-202F66B2FE4A}']
    function Connection: TFDConnection;
    function NewQuery: TFDQuery;

    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;

    // Transitional: schema/user version for migrations
    function GetSchemaVersion: Integer;
    procedure SetSchemaVersion(const Value: Integer);
  end;

  IDbSessionFactory = interface
    ['{A152B6F7-B167-40C1-B70E-083182CDD68D}']
    function OpenSession(const aCtx: IDbContext): IDbSession;
  end;

  IDbSessionManager = interface
    ['{7C695785-EA4A-452F-9B89-67198A4CB873}']
    // Install context for the *current thread* (important for Tasks). Guard restores previous state.
    function UseContext(const aCtx: IDbContext): IInterface;

    // Returns the "current" session:
    // - active transactional session if inside InTransaction
    // - otherwise per-thread cached session (lazy)
    function CurrentSession: IDbSession;

    // Runs Proc inside a transaction on the current thread.
    procedure InTransaction(const aProc: TProc);

    // Optional: clear per-thread cached session (useful for tests or context changes)
    procedure ClearThreadSession;
  end;

  IDbStartupHook = interface
    ['{2C01D581-ED3F-4814-94F1-E14F6FF561BA}']
    procedure Execute(const aDb: IDbSessionManager; const aCtx: IDbContext);
  end;

  TDbSessionManager = class(TSingleton, IDbSessionManager)
  private
    fFactory: IDbSessionFactory;

    class threadvar tCtx: IDbContext;
    class threadvar tActive: IDbSession;

    // per-thread cached session (lazy)
    class threadvar tThreadSession: IDbSession;
    class threadvar tThreadSessionFingerprint: string;

    function Fingerprint(const aCtx: IDbContext): string;
    function EnsureThreadSession(const aCtx: IDbContext): IDbSession;
  public
    constructor Create(const aFactory: IDbSessionFactory);

    function UseContext(const aCtx: IDbContext): IInterface;
    function CurrentSession: IDbSession;

    procedure InTransaction(const aProc: TProc);
    procedure ClearThreadSession;
  end;

  /// <summary>
  ///  Task/threadpool threads do not inherit the ambient DB context (it is stored in TLS).
  ///  Therefore, every TTask must install the context explicitly and keep the guard alive
  ///  for the full duration of the task body.
  ///
  ///  Pattern:
  ///
  ///   TTask.Run(
  ///     procedure
  ///     var
  ///       G: IInterface;
  ///       DbMgr: IDbSessionManager;
  ///     begin
  ///       DbMgr := Container.Resolve<IDbSessionManager>;  // or capture it
  ///       G := DbMgr.UseContext(Ctx);                     // Ctx is immutable, safe to capture
  ///
  ///       // do DB work here (repos will resolve DbMgr.CurrentSession)
  ///     end
  ///   );
  ///
  ///  Do not store G anywhere global; it must be released on the same thread that installed it.
  ///  </summary>
  TDbAmbientGuard = class(TTransient)
  private
    fPrevCtx: IDbContext;
    fPrevActive: IDbSession;
  public
    constructor Create(const aPrevCtx: IDbContext; const aPrevActive: IDbSession);
    destructor Destroy; override;
  end;

  IDbAmbientInstaller = interface
    ['{11C84219-66C7-4096-A54D-744546298759}']
  end;

  TDbAmbientInstaller = class(TSingleton, IDbAmbientInstaller)
  private
    fGuard: IInterface;
  public
    constructor Create(const aDbMgr: IDbSessionManager; const aCtx: IDbContext);
    destructor Destroy; override;
  end;

  /// <summary>
  ///  Apply to non-persisted entity fields.
  /// </summary>
  TransientAttribute = class(TCustomAttribute) end;

  /// <summary>
  ///  Base interface for all entities.
  /// </summary>
  IEntity = interface
    ['{DFEF00C0-5695-443E-91A7-E79E794ED794}']

    /// <summary>Sets the Id.</summary>
    procedure SetId(const aId: integer);

    /// <summary>Gets the Id.</summary>
    function GetId: integer;

    /// <summary>Returns true if the entity does not have an Id.</summary>
    function IsNew: boolean;

    /// <summary>Returns true if the entity does have an Id.</summary>
    function Exists: boolean;

    property Id: integer read GetId write SetId;
  end;

  { todo - in subsequent versions improve field-to-property and table-to-entity mapping options }

  /// <summary>
  ///  This is the base entity class all domain entities in Escape use.
  ///
  ///  The following conventions are enforced:
  ///   - Decorate transient properties with [Transient]
  ///   - The name of the database table matches the name of the entity (TCustomer => Customer)
  ///   - The name of the database columns match the names of the properties
  ///   - Every table has an autogenerated Id field
  ///
  /// </summary>
  TEntity = class(TInterfacedObject, IEntity)
  private
    fId: integer;
  public
    procedure SetId(const aId: integer);

    function GetId: integer;
    function IsNew: boolean;
    function Exists: boolean;

    property Id: integer read GetId write SetId;
  end;

  /// <summary>
  ///  An interface for essential database functionality.
  /// </summary>
//  IDatabaseService = interface
//    ['{957F3224-AE99-4870-A2B9-11B11881FDE3}']
//
//    function Connection: TFDConnection;
//    function Query: TFDQuery;
//    function GetDatabaseVersion: integer;
//
//    procedure SetDatabaseVersion(const aVersion: integer);
//    procedure StartTransaction;
//    procedure Commit;
//    procedure Rollback;
//    procedure Truncate;
//  end;

  /// <summary>
  ///  Set directives to affect the queries, before the query is executed.
  ///  Directives are cleared after each request.
  /// </summary>
  TDirective = (
    /// <summary>Limit the number of records returned</summary>
    tdLimit,
    /// <summary>Order ascending.</summary>
    tdAscending,
    /// <summary>Order descending.</summary>
    tdDescending,
    /// <summary>Begin at record offset.</summary>
    tdOffset
  );

  /// <summary>
  ///  Base interface for the repositories.
  /// </summary>
  IRepository<TService: IEntity; T: TEntity, constructor> = interface
    ['{2B0A8B8E-2A59-43E7-8B3F-0A6B8A2A4A3C}']

    function TableName: string;

    function GetAll: TArray<TService>;
    function GetBy(const aId: integer): TMaybe<TService>;
  end;

  /// <summary>
  ///  Base type for all repositories. Requires entities to follow the T[Table] naming convention,
  ///  for example, TCustomer for a table named Customer.
  /// </summary>
{$IFDEF MSWINDOWS}
  TRepository<TService: IEntity; T: TEntity, constructor> = class(TDynamicObject, IRepository<TService, T>)
{$ELSE}
  TRepository<TService: IEntity; T: TEntity, constructor> = class(TTransient, IRepository<TService, T>)
{$ENDIF}
  private
    fDb: IDbSessionManager;

    // data moves around internally in a list (efficient) but returns to the client as an Array (memory safe)
//    fResults: TList<TService>;

    function GetQueryResults(const aQuery: TFDQuery):TList<TService>;
  protected
    fDirectives: TDictionary<TDirective, string>;

    function Database: IDbSessionManager;
    function Connection: TFDConnection;
    function NewQuery: TFDQuery;

    function ExecQuery(const aSql: string):TList<TService>; overload;
    function ExecQuery(const aQuery: TFDQuery):TList<TService>; overload;

    class var fName: string;
    class var fPropertyOrder: TList<string>;
    class var fProperties: TDictionary<string, TRttiProperty>;
  public
    function TableName: string;

    function GetAll: TArray<TService>;
    function GetBy(const aId: integer): TMaybe<TService>;

    constructor Create(const aDb: IDbSessionManager);
    destructor Destroy; override;

    class constructor Create;
    class destructor Destroy;
  end;

  TMigration = class
  private
    fVersion: integer;
    fSequence: integer;
    fDescription: string;
  public
    property Version: integer read fVersion write fVersion;
    property Sequence: integer read fSequence write fSequence;
    property Description: string read fDescription write fDescription;

    procedure Execute(const aDb: IDbSessionManager); virtual;
  end;

  TMigrationClass = class of TMigration;

  IMigrationManager = interface
    ['{902A60CA-F419-4CEC-A4D3-7A1C1A2D37AA}']
    procedure Add(const aVersion: integer; const aSequence: integer; const aMigration:TMigrationClass; const aDescription: string);
    procedure Execute;
  end;

  IMigrationRegistrar = interface
    ['{C64AD729-DDB8-4AF0-9D23-92BE9E830E14}']
    procedure Configure(const m: IMigrationManager);
  end;

  TMigrationManager = class(TInterfacedObject, IMigrationManager)
  private
    fMigrations: TObjectList<TMigration>;
    fDb: IDbSessionManager;
  public
    procedure Add(const aVersion: integer; const aSequence: integer; const aMigration:TMigrationClass; const aDescription: string);
    procedure Execute;

    constructor Create(const aDb: IDbSessionManager; const aRegistrar: IMigrationRegistrar);
    destructor Destroy; override;
  end;

implementation

uses
  System.Math,
  System.Generics.Defaults,
  Base.Reflection,
  Base.Stream,
  Base.Container;

{ TEntity }

{----------------------------------------------------------------------------------------------------------------------}
function TEntity.GetId: integer;
begin
  Result := fId;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEntity.SetId(const aId: integer);
begin
  fId := aId;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEntity.Exists: boolean;
begin
  Result := fId > 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEntity.IsNew: boolean;
begin
  Result := fId < 1;
end;

{ TRepository<TService, T> }

{----------------------------------------------------------------------------------------------------------------------}
function TRepository<TService, T>.Database: IDbSessionManager;
begin
  Result := fDb;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRepository<TService, T>.Connection: TFDConnection;
begin
  Result := fDb.CurrentSession.Connection;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRepository<TService, T>.NewQuery: TFDQuery;
begin
  Result := fDb.CurrentSession.NewQuery;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRepository<TService, T>.GetAll: TArray<TService>;
const
  SQL = 'select * from %s';
var
  scope: TScope;
begin
  var qry := SQL.Format(SQL, [TableName]);
  var list := scope.Owns(ExecQuery(qry));

  Result := list.ToArray;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRepository<TService, T>.GetBy(const aId: integer): TMaybe<TService>;
const
  SQL = 'select * from %s where id = %d';
var
  scope: TScope;
begin
  var qry := SQL.Format(SQL, [TableName, aId]);

  var list := scope.Owns(ExecQuery(qry));

  if list.IsEmpty then
    Result.SetNone
  else
    Result.SetSome(list[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRepository<TService, T>.TableName: string;
begin
  Result := fName;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRepository<TService, T>.ExecQuery(const aSql: string):TList<TService>;
begin
  var query := NewQuery;

  try
    query.SQL.Text := aSQL;
    Result := ExecQuery(query);
  finally
    query.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRepository<TService, T>.ExecQuery(const aQuery: TFDQuery): TList<TService>;
begin
  aQuery.Open;
  try
    Result := GetQueryResults(aQuery);
  finally
    aQuery.Close;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRepository<TService, T>.GetQueryResults(const aQuery: TFDQuery): TList<TService>;
const
  ERR = '%s does not support requested interface %s';
var
  lValue: TValue;
  lEntity: T;
  lName: string;
  lVariant: Variant;
  lProperty: TRttiProperty;
  lNamedProperty: TPair<string, TRttiProperty>;
begin
  Result := TList<TService>.Create;

  if aQuery.RecordCount = 0 then exit;

  aQuery.First;

  while not aQuery.Eof do
  begin
    lEntity := T.Create;

    for lNamedProperty in fProperties do
    begin
      lName     := lNamedProperty.Key;
      lProperty := lNamedProperty.Value;
      lVariant  := aQuery[lName];

      if not TReflection.TryVariantToTValue(lVariant, lProperty.PropertyType.Handle, lValue) then
        lValue := TValue.FromVariant(lVariant);

      lProperty.SetValue(TObject(lEntity), lValue);
    end;

    Result.Add(TReflection.As<TService>(lEntity));

    aQuery.Next;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TRepository<TService, T>.Create(const aDb: IDbSessionManager);
begin
  inherited Create;

  fDb := aDb;
  fDirectives := TDictionary<TDirective, string>.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TRepository<TService, T>.Destroy;
begin
  fDirectives.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
class constructor TRepository<TService, T>.Create;
const
  NAME_ERR = 'Entities should follow the T[Table] naming convention: %s';
  TYPE_ERR = '%s does not implement %s';
var
  lCtx: TRttiContext;
begin
  lCtx := TRttiContext.Create;

{$IFDEF DEBUG}
  // Delphi can't constrain Class + Interface on T, so we fail fast here.
  // T must implement TService.
  Assert(TReflection.Is<T, TService>, Format(TYPE_ERR, [T.ClassName, TReflection.TypeNameOf<TService>]));
{$ENDIF}

  var lType :=  lCtx.GetType(T);
  var lClass := TRttiInstanceType(lType);

{$IFDEF DEBUG}
  // Name entities with the T prefix convention so we know where to begin looking for the table name
  // The entity name should match T[Table], i.e. TCustomer => Customer
  Assert(lClass.Name.StartsWith('T', true), Format(NAME_ERR, [lClass.Name]));
{$ENDIF}

  fName := lClass.Name;
  fName := fName.Substring(1);

  fPropertyOrder := TList<string>.Create;
  fProperties := TDictionary<string, TRttiProperty>.Create(TIStringComparer.Ordinal);

  for var lProperty in lType.GetProperties do
  begin
    if SameText(lProperty.Name, 'RefCount') then Continue;

    if Assigned(lProperty.GetAttribute<TransientAttribute>()) then continue;

    fProperties.Add(lProperty.Name, lProperty);
    fPropertyOrder.Add(lProperty.Name);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor TRepository<TService, T>.Destroy;
begin
  if Assigned(fProperties) then
  begin
    fProperties.Clear;
    FreeAndNil(fProperties);
  end;

  FreeAndNil(fPropertyOrder);
end;

{ TMigration }

{----------------------------------------------------------------------------------------------------------------------}
procedure TMigration.Execute(const aDb: IDbSessionManager);
begin
  Writeln(Format('Applying migration (%d.%d): %s', [fVersion, fSequence, fDescription]));
end;

{ TMigrationManager }

{----------------------------------------------------------------------------------------------------------------------}
procedure TMigrationManager.Execute;
var
  scope: TScope;
begin
  var version := fDb.CurrentSession.GetSchemaVersion;
  var max := 0;

  for var m in fMigrations do
    if m.Version > max then
      max := m.Version;

  if max = version then exit;

  var migrations := Stream.From<TMigration>(fMigrations.ToArray)
    .Filter(function(const m: TMigration): Boolean
        begin
          Result := m.Version > version;
        end)
    .Sort(TComparer<TMigration>.Construct(function(const l, r: TMigration): integer
        begin
          if l.Version <> r.Version then
            Result := Ord(CompareValue(l.Version, r.Version))
          else
            Result := Ord(CompareValue(l.Sequence, r.Sequence));
        end))
    .GroupBy<integer>(function(const m: TMigration): integer
        begin
          Result := m.Version;
        end);

  scope.Owns(migrations);
  scope.Defer(procedure begin for var item in migrations do item.Value.Free; end);

  Inc(version);

  for var v in [version..max] do
  begin
    var m: TMigration := nil;

    try
      fDb.CurrentSession.StartTransaction;

      for m in migrations[v] do
        m.Execute(fDb);

      fDb.CurrentSession.SetSchemaVersion(v);
      fDb.CurrentSession.Commit;
    except
      on E:Exception do
      begin
        fDb.CurrentSession.Rollback;

        var msg := if Assigned(m) then
                     Format('Migration Error (%d.%d - %s): %s', [v, m.Sequence, m.Description, E.Message])
                   else
                     Format('Migration Error (%d): %s', [v, E.Message]);

        raise Exception.Create(msg);
      end;
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMigrationManager.Add(const aVersion: integer; const aSequence: integer; const aMigration:TMigrationClass; const aDescription: string);
begin
  var m := aMigration.Create;

  m.Version     := aVersion;
  m.Sequence    := aSequence;
  m.Description := aDescription;

  fMigrations.Add(m)
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TMigrationManager.Create(const aDb: IDbSessionManager; const aRegistrar: IMigrationRegistrar);
begin
  fDb := aDb;
  fMigrations := TObjectList<TMigration>.Create(true);

  aRegistrar.Configure(Self);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TMigrationManager.Destroy;
begin
  fMigrations.Free;
  inherited;
end;

{ TDbAmbientGuard }

{----------------------------------------------------------------------------------------------------------------------}
constructor TDbAmbientGuard.Create(const aPrevCtx: IDbContext; const aPrevActive: IDbSession);
begin
  inherited Create;

  fPrevCtx := aPrevCtx;
  fPrevActive := aPrevActive;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TDbAmbientGuard.Destroy;
begin
  TDbSessionManager.tActive := fPrevActive;
  TDbSessionManager.tCtx := fPrevCtx;

  inherited;
end;

{ TDbSessionManager }

{----------------------------------------------------------------------------------------------------------------------}
procedure TDbSessionManager.ClearThreadSession;
begin
  tThreadSession := nil;
  tThreadSessionFingerprint := '';
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDbSessionManager.CurrentSession: IDbSession;
begin
  // If inside an explicit transaction, always return that session.
  if tActive <> nil then exit(tActive);

  if tCtx = nil then
    raise Exception.Create('No ambient DB context set for this thread. Call UseContext(...) first.');

  Result := EnsureThreadSession(tCtx);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDbSessionManager.EnsureThreadSession(const aCtx: IDbContext): IDbSession;
begin
  var fp := Fingerprint(aCtx);

  if (tThreadSession = nil) or (tThreadSessionFingerprint <> fp) then
  begin
    tThreadSession := fFactory.OpenSession(aCtx);
    tThreadSessionFingerprint := fp;
  end;

  Result := tThreadSession;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDbSessionManager.Fingerprint(const aCtx: IDbContext): string;
var
  FP: IDbContextFingerprint;
begin
  if aCtx = nil then
    raise EArgumentNilException.Create('aCtx');

  Result := aCtx.ProviderId + '|' + aCtx.Name;

  if Supports(aCtx.Payload, IDbContextFingerprint, FP) then
    Result := Result + '|' + FP.Fingerprint
  else
    // Fallback: if no fingerprint is provided, treat payload changes as "unknown"
    // and avoid caching by returning something that will not match across calls.
    Result := Result + '|nocache';
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDbSessionManager.InTransaction(const aProc: TProc);
begin
  if not Assigned(aProc) then
    raise EArgumentNilException.Create('aProc');

  if tCtx = nil then
    raise Exception.Create('No ambient DB context set for this thread. Call UseContext(...) first.');

  // Use the per-thread session. (Simple, predictable for v0.1.)
  var session := EnsureThreadSession(tCtx);

  var prevActive := tActive;

  tActive := session;
  try
    session.StartTransaction;
    try
      aProc();
      session.Commit;
    except
      session.Rollback;
      raise;
    end;
  finally
    tActive := prevActive;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDbSessionManager.UseContext(const aCtx: IDbContext): IInterface;
var
  PrevCtx: IDbContext;
  PrevActive: IDbSession;
begin
  if aCtx = nil then
    raise EArgumentNilException.Create('aCtx');

  PrevCtx := tCtx;
  PrevActive := tActive;

  tCtx := aCtx;

  // Note: do NOT create the session here; keep it lazy.

  Result := TDbAmbientGuard.Create(PrevCtx, PrevActive);
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TDbSessionManager.Create(const aFactory: IDbSessionFactory);
begin
  inherited Create;

  fFactory := aFactory;
end;

{ TDbAmbientInstaller }

{----------------------------------------------------------------------------------------------------------------------}
constructor TDbAmbientInstaller.Create(const aDbMgr: IDbSessionManager; const aCtx: IDbContext);
begin
  inherited Create;

  fGuard := aDbMgr.UseContext(aCtx);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TDbAmbientInstaller.Destroy;
begin
  fGuard := nil;

  inherited;
end;

{ TDbContextFactory }

{----------------------------------------------------------------------------------------------------------------------}
function TDbContextFactory.BuildFromSettings(const Settings: ISettings): IDbContext;
begin
  Ensure.IsTrue(Assigned(Settings), 'Settings is required');

  var database   := Settings.Database;
  var providerId := database.Attr('provider', 'sqlite').AsString;
  var provider   := Container.Resolve<IDbContextProvider>(providerId);

  Ensure.IsTrue(Assigned(provider), 'Database provider not registerd: ' + providerId);

  Result := Provider.BuildContext(fFileService, Settings);
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TDbContextFactory.Create(const aFileService: IFileService);
begin
  fFileService := aFileService;
end;

end.
