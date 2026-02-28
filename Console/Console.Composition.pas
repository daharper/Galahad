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
    procedure RegisterServices(const c: TContainer);
  end;

  /// <summary>
  ///  Registers console services with the application builder.
  /// </summary>
  TConsoleServiceModule = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const c: TContainer);
  end;

  /// <summary>
  ///  Registers console services with the application builder.
  /// </summary>
  TConsoleParsingModule = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const c: TContainer);
  end;

  /// <summary>
  ///  Registers data services with the application builder.
  /// </summary>
  TConsoleDataServicesModule = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const c: TContainer);
  end;

  /// <summary>
  ///  Registers use cases with the application builder.
  /// </summary>
  TUseCaseModule = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const c: TContainer);
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
procedure TConsoleModule.RegisterServices(const c: TContainer);
begin
  c.AddModule<TConsoleServiceModule>;
  c.AddModule<TConsoleDataServicesModule>;
  c.AddModule<TConsoleParsingModule>;
  c.AddModule<TUseCaseModule>;
end;

{ TConsoleServiceModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleServiceModule.RegisterServices(const c: TContainer);
begin
  c.Add<IGameSession, TGameSession>;
  c.Add<IApplication, TConsoleApplication>;
end;

{ TDataServicesModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleDataServicesModule.RegisterServices(const c: TContainer);
begin
  c.Add<IFileService, TFileService>;
  c.Add<IDbContextProvider, TSqliteContextProvider>('sqlite');
  c.Add<IDbStartupHook, TSqliteStartup>('sqlite');
  c.Add<IDbContextFactory, TDbContextFactory>;
  c.Add<IDbSessionFactory, TSqliteSessionFactory>;
  c.Add<IDbSessionManager, TDbSessionManager>;
  c.Add<IMigrationRegistrar, TMigrationRegistrar>;
  c.Add<IMigrationManager, TMigrationManager>;
  c.Add<ITermRepository, TTermRepository>;
  c.Add<IWordRepository, TWordRepository>;
end;

{ TUseCaseModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TUseCaseModule.RegisterServices(const c: TContainer);
begin
  c.Add<IStartGameUseCase, TStartGameUseCase>(Transient);
end;

{ TConsoleParsingModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleParsingModule.RegisterServices(const c: TContainer);
begin
  c.Add<IWordRegistry, TWordRegistry>;
  c.Add<ITermRegistry, TTermRegistry>;
  c.Add<ITextSanitizer, TTextSanitizer>;
  c.Add<ITextTokenizer, TTextTokenizer>;
  c.Add<IWordResolver, TWordResolver>;
  c.Add<ITermResolver, TTermResolver>;
  c.Add<INoiseRemover, TNoiseRemover>;
  c.Add<INormalizer, TNormalizer>;
  c.Add<ITextParser, TTextParser>;
end;

end.
