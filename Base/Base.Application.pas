{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Application
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Provides basic application abstraction and builder functionality.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Application;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  Base.Core,
  Base.Integrity,
  Base.Data,
  Base.Settings,
  Base.Files,
  Base.Container;

type
  IApplication = interface
    ['{F0FA85F4-CD6E-454B-8D45-798D5BFDF580}']
    function Settings: ISettings;
    function Services: TContainer;
    function DbContext: IDbContext;
    function DbSessionManager: IDbSessionManager;

    procedure SetSettings(const aSettings: ISettings);
    procedure SetDbContext(const aDbContext: IDbContext);
    procedure SetDbSessionManager(const aDbSessionManager: IDbSessionManager);

    procedure Execute;
    procedure ConfigureConnectionsFromDbContext(const aConnections: array of TFDConnection);
  end;

  TApplicationBase = class(TTransient, IApplication)
  private
    fSettings: ISettings;
    fDbContext: IDbContext;
    fDbSessionManager: IDbSessionManager;
  protected
    procedure Run; virtual; abstract;
    procedure HandleException(const E: Exception); virtual; abstract;
  public
    function Settings: ISettings;
    function Services: TContainer;
    function DbContext: IDbContext;
    function DbSessionManager: IDbSessionManager;

    procedure SetSettings(const aSettings: ISettings);
    procedure SetDbContext(const aDbContext: IDbContext);
    procedure SetDbSessionManager(const aDbSessionManager: IDbSessionManager);

    procedure Execute;
    procedure ConfigureConnectionsFromDbContext(const aConnections: array of TFDConnection);
  end;

  TApplicationBuilder = class
  private
    fDatabaseConfigured: boolean;
    fDatabaseRegistered: boolean;
    fMigrationsPerformed: boolean;

    fSettings:  ISettings;
    fDbContext: IDbContext;
    fDbSessionManager: IDbSessionManager;

    procedure RegisterDatabaseTypes;

    class var fInstance: TApplicationBuilder;
  public
    function Services: TContainer;
    function Build: IApplication;
    function LoadSettings<T:ISettings>: TApplicationBuilder;
    function AddModule<T: IContainerModule, class, constructor>: TApplicationBuilder;
    function AddAliases<T: IContainerModule, class, constructor>: TApplicationBuilder;
    function ConfigureDatabase:TApplicationBuilder; overload;
    function ConfigureDatabase(const aCtx: IDbContext):TApplicationBuilder; overload;

    function PerformMigrations:TApplicationBuilder;

    class constructor Create;
    class destructor Destroy;
  end;

  function ApplicationBuilder: TApplicationBuilder;

implementation

uses
  Base.Xml,
  Base.Sqlite;

{ Functions }

{----------------------------------------------------------------------------------------------------------------------}
function ApplicationBuilder: TApplicationBuilder;
begin
  Result := TApplicationBuilder.fInstance;
end;

{ TApplicationBuilder }

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.Build: IApplication;
begin
  Result := Services.Resolve<IApplication>;

  Result.SetSettings(fSettings);
  Result.SetDbContext(fDbContext);
  Result.SetDbSessionManager(fDbSessionManager);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.ConfigureDatabase(const aCtx: IDbContext):TApplicationBuilder;
const
  CONFIG_ERR = 'Database has already been configured.';
  CONTEXT_ERR = 'Database context is required';
var
  hook: IDbStartupHook;
begin
  RegisterDatabaseTypes;

  Ensure.IsFalse(fDatabaseConfigured, CONFIG_ERR).IsTrue(Assigned(aCtx), CONTEXT_ERR);

  Services.AddSingleton<IDbContext>(aCtx);

  fDbContext := aCtx;

  Services.Add<IDbAmbientInstaller, TDbAmbientInstaller>;
  Services.Resolve<IDbAmbientInstaller>; // ensure ambient installed now (main thread)

  fDatabaseConfigured := True;

  if Services.TryResolve<IDbStartupHook>(hook, aCtx.ProviderId) then
    hook.Execute(fDbSessionManager, aCtx);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.ConfigureDatabase:TApplicationBuilder;
begin
  RegisterDatabaseTypes;

  var ctx := Services.Resolve<IDbContextFactory>.BuildFromSettings(fSettings);

  ConfigureDatabase(ctx);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TApplicationBuilder.RegisterDatabaseTypes;
begin
  if fDatabaseRegistered then exit;

  // database core
  Services.Add<IDbContextFactory, TDbContextFactory>;
  Services.Add<IDbSessionManager, TDbSessionManager>;
  Services.Add<IDbSessionFactory, TSqliteSessionFactory>;
  Services.Add<IMigrationManager, TMigrationManager>;

  // database providers
  Services.Add<IDbContextProvider, TSqliteContextProvider>('sqlite');
  Services.Add<IDbStartupHook, TSqliteStartup>('sqlite');

  fDbSessionManager := Services.Resolve<IDbSessionManager>;
  fDatabaseRegistered := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.PerformMigrations:TApplicationBuilder;
const
  CFG_ERR = 'Please configure the database before performing migrations.';
  DUP_ERR = 'Migrations have already been performed.';
begin
  Ensure.IsTrue(fDatabaseConfigured, CFG_ERR);
  Ensure.IsFalse(fMigrationsPerformed, DUP_ERR);

  var migrator := Services.Resolve<IMigrationManager>;
  migrator.Execute;

  fMigrationsPerformed := true;

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.Services: TContainer;
begin
  Result := Container;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.LoadSettings<T>: TApplicationBuilder;
begin
  var files := Services.Resolve<IFileService>;
  var settingsRes := TXml.Load(files.SettingsPath);

  Ensure.IsTrue(settingsRes.IsOk, 'Error loading the settings file: ' + files.SettingsPath);

  fSettings := Services.Resolve<T>;

  fSettings.Assign(settingsRes.Value);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.AddAliases<T>: TApplicationBuilder;
begin
  Services.AddModule<T>;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.AddModule<T>: TApplicationBuilder;
begin
  Services.AddModule<T>;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
class constructor TApplicationBuilder.Create;
begin
  fInstance := TApplicationBuilder.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor TApplicationBuilder.Destroy;
begin
  FreeAndNil(fInstance);
end;

{ TApplicationBase }

{----------------------------------------------------------------------------------------------------------------------}
procedure TApplicationBase.Execute;
begin
  try
    Run;
  except
    on E: Exception do
    begin
      HandleException(E);
      ExitCode := 1;
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBase.DbContext: IDbContext;
begin
  // if not set, then try get from the container

  if not Assigned(fDbContext) then
    fDbContext := Container.Resolve<IDbContext>;

  Result := fDbContext;

  Ensure.IsTrue(Assigned(fDbContext), 'No DbContext available');
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBase.DbSessionManager: IDbSessionManager;
begin
  // if not set, then try get from the container

  if not Assigned(fDbSessionManager) then
    fDbSessionManager := Container.Resolve<IDbSessionManager>;

  Result := fDbSessionManager;

  Ensure.IsTrue(Assigned(fDbSessionManager), 'No DbSessionManager available');
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBase.Settings: ISettings;
begin
  // if not set, then try get from the container

  if not Assigned(fSettings) then
    fSettings := Container.Resolve<ISettings>;

  Result := fSettings;

  Ensure.IsTrue(Assigned(fSettings), 'No Settings available');
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBase.Services: TContainer;
begin
  Result := Container;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TApplicationBase.SetDbContext(const aDbContext: IDbContext);
begin
  fDbContext := aDbContext;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TApplicationBase.SetDbSessionManager(const aDbSessionManager: IDbSessionManager);
begin
  fDbSessionManager := aDbSessionManager;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TApplicationBase.SetSettings(const aSettings: ISettings);
begin
  fSettings := aSettings;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TApplicationBase.ConfigureConnectionsFromDbContext(const aConnections: array of TFDConnection);
begin
  for var connection in aConnections do
    fDbSessionManager.CurrentSession.Init(DbContext, connection);
end;

end.

