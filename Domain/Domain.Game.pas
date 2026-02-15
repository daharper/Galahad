unit Domain.Game;

interface

uses
  Base.Core;

type
  TGameState = (gsNone, gsRunning, gsFinished);

  IGameSession = interface
    ['{E02EFAA3-617B-4B9E-9E88-413BD0E5052D}']
    function GetState: TGameState;

    procedure SetState(const aState: TGameState);

    property State: TGameState read GetState write SetState;
  end;

  TGameSession = class(TSingleton, IGameSession)
  private
    fState: TGameState;
  public
    function GetState: TGameState;

    procedure SetState(const aState: TGameState);
  end;

implementation

{ TGameSession }

{----------------------------------------------------------------------------------------------------------------------}
function TGameSession.GetState: TGameState;
begin
  Result := fState;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TGameSession.SetState(const aState: TGameState);
begin
  fState := aState;
end;

end.
