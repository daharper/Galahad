unit Console.Composition;

interface

uses
  Base.Application,
  Base.Integrity,
  Base.Container;

type
  /// <summary>
  ///  Registers console modules with the service container.
  /// </summary>
  TConsoleModule = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const aContainer: TContainer);
  end;

  /// <summary>
  ///  Registers console services with the application builder.
  /// </summary>
  TConsoleServiceModule = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const aContainer: TContainer);
  end;

  /// <summary>
  ///  Registers console services with the application builder.
  /// </summary>
  TConsoleParsingModule = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const aContainer: TContainer);
  end;

  /// <summary>
  ///  Registers data services with the application builder.
  /// </summary>
  TConsoleDataServicesModule = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const aContainer: TContainer);
  end;

  /// <summary>
  ///  Registers use cases with the application builder.
  /// </summary>
  TUseCaseModule = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const aContainer: TContainer);
  end;

implementation

uses
  System.SysUtils,
  Base.Data,
  Base.Sqlite,
  Base.Files,
  Domain.Game,
  Domain.Terms,
  Application.Language,
  Application.Parsing,
  Application.UseCases.StartGame,
  Infrastructure.Data,
  Infrastructure.Migrations,
  Console.Application;

{ TConsoleModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.AddModule<TConsoleServiceModule>;
  aContainer.AddModule<TConsoleDataServicesModule>;
  aContainer.AddModule<TConsoleParsingModule>;
  aContainer.AddModule<TUseCaseModule>;
end;

{ TConsoleServiceModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleServiceModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.Add<IGameSession, TGameSession>; //(Singleton);
  aContainer.Add<IApplication, TConsoleApplication>; //(Transient);
end;

{ TDataServicesModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleDataServicesModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.Add<IFileService, TFileService>;
  aContainer.Add<IDbContextProvider, TSqliteContextProvider>('sqlite');
  aContainer.Add<IDbContextFactory, TDbContextFactory>;
  aContainer.Add<IDbSessionFactory, TSqliteSessionFactory>;
  aContainer.Add<IDbSessionManager, TDbSessionManager>;
  aContainer.Add<IMigrationRegistrar, TMigrationRegistrar>(Transient);
  aContainer.Add<IMigrationManager, TMigrationManager>(Transient);
  aContainer.Add<ITermRepository, TTermRepository>(Transient);
  aContainer.Add<IWordRepository, TWordRepository>(Transient);
end;

{ TUseCaseModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TUseCaseModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.Add<IStartGameUseCase, TStartGameUseCase>(Transient);
end;

{ TConsoleParsingModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleParsingModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.Add<IWordRegistry, TWordRegistry>(Singleton);
  aContainer.Add<ITermRegistry, TTermRegistry>(Singleton);
  aContainer.Add<ITextSanitizer, TTextSanitizer>(Singleton);
  aContainer.Add<ITextTokenizer, TTextTokenizer>(Singleton);
  aContainer.Add<IWordResolver, TWordResolver>(Singleton);
  aContainer.Add<ITermResolver, TTermResolver>(Singleton);
  aContainer.Add<ITextParser, TTextParser>(Singleton);
end;

end.
