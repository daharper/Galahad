unit Infrastructure.ConsoleApplication;

interface

uses
  Base.Core,
  Base.Container,
  Domain.Game,
  Application.Core.Contracts,
  Application.Core.Language;

type
  /// <summary>
  ///  Registers console modules with the service container.
  /// </summary>
  TConsoleModule = class(TTransient, IContainerModule)
  public
    procedure RegisterServices(const aContainer: TContainer);
  end;

  /// <summary>
  ///  Registers console services with the application builder.
  /// </summary>
  TConsoleServiceModule = class(TTransient, IContainerModule)
  public
    procedure RegisterServices(const aContainer: TContainer);
  end;

  /// <summary>
  ///  Registers data services with the application builder.
  /// </summary>
  TConsoleDataServicesModule = class(TTransient, IContainerModule)
  public
    procedure RegisterServices(const aContainer: TContainer);
  end;

  /// <summary>
  ///  The console application.
  /// </summary>
  TConsoleApplication = class(TSingleton, IApplication)
  private
    fSession: IGameSession;
  public
    procedure Welcome;
    procedure Execute;

//    constructor Create(aStartGameUseCase: IStartGameUseCase);
  end;

implementation

uses
  Base.Data,
  Infrastructure.Files,
  Infrastructure.Data;

{ TConsole }

{----------------------------------------------------------------------------------------------------------------------}
//constructor TConsoleApplication.Create;
//begin
// lSession := fStartGameUse.Execute;//  fSession := aSession;
//end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleApplication.Execute;
begin
  Writeln('Running');
  Readln;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleApplication.Welcome;
begin
  Writeln('Press enter to quit...');
end;

{ TConsoleServiceModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleServiceModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.Add<IGameSession, TGameSession>(Singleton);
  aContainer.Add<IApplication, TConsoleApplication>(Singleton);
end;

{ TDataServicesModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleDataServicesModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.Add<IFileService, TFileService>(Singleton);
  aContainer.Add<IDatabaseService, TDatabaseService>(Singleton);
  aContainer.Add<ITermRepository, TTermRepository>(Transient);
  aContainer.Add<IWordRepository, TWordRepository>(Transient);
  aContainer.Add<IWordRegistry, TWordRegistry>(Singleton);
  aContainer.Add<ITermRegistry, TTermRegistry>(Singleton);
  aContainer.Add<IVocabRegistrar, TVocabRegistrar>(Singleton);
end;

{ TConsoleModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.AddModule(TConsoleServiceModule.Create);
  aContainer.AddModule(TConsoleDataServicesModule.Create);
end;

end.
