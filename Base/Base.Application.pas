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
  Base.Core,
  Base.Integrity,
  Base.Data,
  Base.Settings,
  Base.Files,
  Base.Container;

type
  IApplication = interface
    ['{F0FA85F4-CD6E-454B-8D45-798D5BFDF580}']
    procedure Execute;
  end;

  TApplicationBase = class(TTransient, IApplication)
  protected
    procedure Run; virtual; abstract;
    procedure HandleException(const E: Exception); virtual;
  public
    procedure Execute;
  end;

  TApplicationBuilder = class
  private
    fDatabaseConfigured: boolean;

    class var fInstance: TApplicationBuilder;
  public
    function Services: TContainer;
    function Build: IApplication;
    function LoadSettings: ISettings;

    procedure ConfigureDatabase(const aCtx: IDbContext); overload;
    procedure ConfigureDatabase; overload;

    procedure PerformMigrations;

    class constructor Create;
    class destructor Destroy;
  end;

  function ApplicationBuilder: TApplicationBuilder;

implementation

uses
  Base.Xml;

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
  Result := Container.Resolve<IApplication>;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TApplicationBuilder.ConfigureDatabase(const aCtx: IDbContext);
const
  CONFIG_ERR = 'Database has already been configured.';
  CONTEXT_ERR = 'Database context is required';
begin
  Ensure.IsFalse(fDatabaseConfigured, CONFIG_ERR).IsTrue(Assigned(aCtx), CONTEXT_ERR);

  Services.AddSingleton<IDbContext>(aCtx);

  Services.Add<IDbAmbientInstaller, TDbAmbientInstaller>;
  Services.Resolve<IDbAmbientInstaller>; // ensure ambient installed now (main thread)

  fDatabaseConfigured := True;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TApplicationBuilder.ConfigureDatabase;
begin
  var settings := Services.Resolve<ISettings>;
  var ctx := Services.Resolve<IDbContextFactory>.BuildFromSettings(settings);

  ConfigureDatabase(ctx);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TApplicationBuilder.PerformMigrations;
const
  ERR = 'Please configure the database before performing migrations.';
begin
  Ensure.IsTrue(fDatabaseConfigured, ERR);

  var migrator := Services.Resolve<IMigrationManager>;
  migrator.Execute;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.Services: TContainer;
begin
  Result := Container;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.LoadSettings: ISettings;
begin
  var files := Services.Resolve<IFileService>;
  var settingsRes := TXml.Load(files.SettingsPath);

  Ensure.IsTrue(settingsRes.IsOk, 'Error loading the settings file: ' + files.SettingsPath);

  var xml := settingsRes.Value;

  Services.AddSingleton<ISettings>(TSettings.Create(xml));

  Result := Services.Resolve<ISettings>;
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
procedure TApplicationBase.HandleException(const E: Exception);
begin
  Writeln(E.ClassName, ': ', E.Message);
end;

end.
