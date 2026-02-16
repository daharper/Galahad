unit Infrastructure.ConsoleApplication;

interface

uses
  Base.Core,
  Base.Container,
  Domain.Game,
  Domain.Terms,
  Application.Contracts,
  Application.Language,
  Application.UseCases.StartGame;

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
  ///  Registers use cases with the application builder.
  /// </summary>
  TUseCaseModule = class(TTransient, IContainerModule)
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

    constructor Create(const aStartGameUseCase: IStartGameUseCase);
  end;

implementation

uses
  System.SysUtils,
  Base.Data,
  Infrastructure.Files,
  Infrastructure.Data;

{ TConsole }

{----------------------------------------------------------------------------------------------------------------------}
constructor TConsoleApplication.Create(const aStartGameUseCase: IStartGameUseCase);
begin
  fSession := aStartGameUseCase.Execute;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleApplication.Execute;
var
  lInput: string;
begin
  var vocab := Container.Resolve<IVocabRegistrar>; // todo - remove after testing

  while fSession.IsRunning do
  begin
    Write('> ');

    Readln(lInput);

    lInput := Trim(lInput);

    if lInput = '' then continue;

    if SameText(lInput, 'quit') then Break;

    var termOpt := vocab.ResolveTerm(lInput);

    if termOpt.IsSome then
      Writeln(termOpt.Value.Value)
    else
      Writeln('(unknown term)');
  end;
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

{ TUseCaseModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TUseCaseModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.Add<IStartGameUseCase, TStartGameUseCase>(Transient);
end;

{ TConsoleModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.AddModule(TConsoleServiceModule.Create);
  aContainer.AddModule(TConsoleDataServicesModule.Create);
  aContainer.AddModule(TUseCaseModule.Create);
end;

end.
