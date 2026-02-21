unit Presentation.ConsoleApplication;

interface

uses
  Base.Core,
  Base.Container,
  Domain.Game,
  Domain.Terms,
  Application.Contracts,
  Application.Language,
  Application.Parsing,
  Application.UseCases.StartGame;

type
  /// <summary>
  ///  The console application.
  /// </summary>
  TConsoleApplication = class(TInterfacedObject, IApplication)
  private
    fParser: ITextParser;
    fSession: IGameSession;
  public
    procedure Welcome;
    procedure Execute;

    constructor Create(
      const aParser: ITextParser;
      const aStartGameUseCase: IStartGameUseCase);
  end;

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
  Infrastructure.Files,
  Infrastructure.Data;

{ TConsole }

{----------------------------------------------------------------------------------------------------------------------}
constructor TConsoleApplication.Create(
  const aParser: ITextParser;
  const aStartGameUseCase: IStartGameUseCase
);
begin
  fParser := aParser;
  fSession := aStartGameUseCase.Execute;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleApplication.Execute;
var
  lInput: string;
begin
  while fSession.IsRunning do
  begin
    Write('> ');

    Readln(lInput);

    lInput := Trim(lInput);

    if lInput = '' then continue;

    if SameText(lInput, 'quit') then
    begin
      fSession.State := gsFinished;
      continue;
    end;


    var tokens := fParser.Execute(lInput);

    try
      Writeln(sLineBreak + '-----------------------------------------------' + sLineBreak);

      for var token in tokens do
      begin
        Writeln('Text: ' + token.Text);
        Write('Kind: ');

        case token.Kind of
          ttUnknown:      Writeln('Unknown');
          ttText:         Writeln('Text');
          ttNumber:       Writeln('Number');
          ttQuotedString: Writeln('QuotedString');
        end;

        if token.IsWord then
          Writeln('Word: ' + token.Word.Value);

        if token.IsTerm then
          Writeln('Term: ' + token.Term.Value);

        Writeln;
      end;

      Writeln(sLineBreak + '-----------------------------------------------' + sLineBreak);
    finally
      tokens.Free;
    end;
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
  aContainer.Add<IApplication, TConsoleApplication>(Transient);
end;

{ TDataServicesModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleDataServicesModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.Add<IFileService, TFileService>(Singleton);
  aContainer.Add<IDatabaseService, TDatabaseService>(Singleton);
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

{ TConsoleModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.AddModule<TConsoleServiceModule>;
  aContainer.AddModule<TConsoleDataServicesModule>;
  aContainer.AddModule<TConsoleParsingModule>;
  aContainer.AddModule<TUseCaseModule>;
end;

end.
