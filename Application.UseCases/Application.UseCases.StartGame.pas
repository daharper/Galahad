unit Application.UseCases.StartGame;

interface

uses
  Base.Core,
  Domain.Game;

type
  IStartGameUseCase = interface
    ['{E02E4EFF-2CD3-43E8-B88C-A7F62F35A963}']
    function Execute: IGameSession;
  end;

  TStartGameUseCase = class(TTransient, IStartGameUseCase)
  private
    fSession: IGameSession;
  public
    function Execute: IGameSession;

    constructor Create(const aSession: IGameSession);
  end;

implementation

{ TStartGameUseCase }

{----------------------------------------------------------------------------------------------------------------------}
constructor TStartGameUseCase.Create(const aSession: IGameSession);
begin
  fSession := aSession;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TStartGameUseCase.Execute: IGameSession;
begin
  // todo - init world

  fSession.State := gsRunning;

  Result := fSession;
end;

end.
