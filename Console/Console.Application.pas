 unit Console.Application;

interface

uses
  Domain.Game,
  Domain.Terms,
  Application.Contracts,
  Application.Language,
  Application.Parsing,
  Application.UseCases.StartGame,
  Infrastructure.Migrations;

type

  TConsoleApplication = class(TInterfacedObject, IApplication)
  private
    fParser: ITextParser;
    fSession: IGameSession;
  public
    procedure Welcome;
    procedure Execute;

    constructor Create(
      const aMigrator: IMigrationManager;
      const aParser: ITextParser;
      const aStartGameUseCase: IStartGameUseCase);
  end;

implementation

uses
  System.SysUtils;

{ TConsoleApplication }

{----------------------------------------------------------------------------------------------------------------------}
constructor TConsoleApplication.Create(
  const aMigrator: IMigrationManager;
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


end.
