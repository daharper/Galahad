unit Mocks.Container;

interface

type
   ITestSvc = interface
    ['{B56A390B-29D1-4C96-9C07-5FD80DFE7C9E}']
    function Ping: Integer;
  end;

  TTestSvc = class(TInterfacedObject, ITestSvc)
  public
    function Ping: Integer;
  end;

  TObjectSvc = class
  public
    Value: Integer;
  end;

  TTracked = class
  public
    class var FreedCount: Integer;
    destructor Destroy; override;
  end;

implementation

{ TTestSvc }

{----------------------------------------------------------------------------------------------------------------------}
function TTestSvc.Ping: Integer;
begin
  Result := 42;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TTracked.Destroy;
begin
  Inc(FreedCount);

  inherited;
end;

end.
