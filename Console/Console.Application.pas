 unit Console.Application;

interface

uses
  Base.Data,
  Base.Application,
  Domain.Game,
  Domain.Terms,
  Application.Language,
  Application.Parsing,
  Application.UseCases.StartGame,
  Infrastructure.Migrations;

type

  TConsoleApplication = class(TApplicationBase)
  private
    fParser: ITextParser;
    fSession: IGameSession;
  public
    procedure Run; override;

    constructor Create(
      const aParser: ITextParser;
      const aStartGameUseCase: IStartGameUseCase);
  end;

implementation

uses
  System.SysUtils;

{ TConsoleApplication }

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
procedure TConsoleApplication.Run;
var
  lInput: string;
begin
  Writeln('Press enter to quit...');

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

    var tokensRes := fParser.Execute(lInput);

    if tokensRes.IsErr then
    begin
      Writeln(tokensRes.Error);
      continue;
    end;

    var tokens := tokensRes.Value;

    try
      Writeln(tokens.DumpTokens);
      Writeln(tokens.DumpTerms);
    finally
      tokens.Free;
    end;
  end;
end;

end.
