unit Mocks.Container;

interface

uses
  Base.Container;

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

  IRepo = interface
    ['{9C3C2B35-0B5A-4C5F-A2D2-96B2F7E59C3A}']
  end;

  TRepo = class(TInterfacedObject, IRepo)
  end;

  TPlainClass = class
  end;

  TTestModuleA = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const C: TContainer);
  end;

  TTestModuleB = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const C: TContainer);
  end;

implementation

{ TTestSvc }

{----------------------------------------------------------------------------------------------------------------------}
function TTestSvc.Ping: Integer;
begin
  Result := 42;
end;

{ TTracked }

{----------------------------------------------------------------------------------------------------------------------}
destructor TTracked.Destroy;
begin
  Inc(FreedCount);

  inherited;
end;

{ Modules }

{----------------------------------------------------------------------------------------------------------------------}
procedure TTestModuleA.RegisterServices(const C: TContainer);
begin
  // Register one named mapping
  C.AddType<ITestSvc, TTestSvc>(Singleton, 'A');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TTestModuleB.RegisterServices(const C: TContainer);
begin
  // Register a different named mapping
  C.AddType<ITestSvc, TTestSvc>(Singleton, 'B');
end;

end.
