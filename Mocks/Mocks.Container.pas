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

  IDep = interface
    ['{0D5B32BB-2A62-4A49-A5B0-BAA2C10A5E69}']
    function Value: Integer;
  end;

  IService = interface
    ['{D75F3D84-1B0A-4B3F-8C2D-DC58F0B5E6E5}']
    function DepValue: Integer;
    function SelfId: NativeInt;
  end;

  TDep = class(TInterfacedObject, IDep)
  public
    function Value: Integer;
  end;

  // parameterless
  TService0 = class(TInterfacedObject, IService)
  public
    function DepValue: Integer;
    function SelfId: NativeInt;
  end;

  // ctor injection
  TService1 = class(TInterfacedObject, IService)
  private
    FDep: IDep;
  public
    constructor Create(const Dep: IDep);
    function DepValue: Integer;
    function SelfId: NativeInt;
  end;

  // unsatisfied ctor (primitive)
  TBadService = class(TInterfacedObject, IService)
  public
    constructor Create(const S: string); overload;
    function DepValue: Integer;
    function SelfId: NativeInt;
  end;

  // class for ResolveClass tests
  TFoo = class
  public
    class var Instances: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

// multiple constructors: prefer the "most resolvable params" one
  TMultiCtor = class
  private
    FDep: IDep;
  public
    constructor Create; overload;
    constructor Create(const Dep: IDep); overload;

    function DepAssigned: Boolean;
    function DepValue: Integer;
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

{ TDep }

{----------------------------------------------------------------------------------------------------------------------}
function TDep.Value: Integer;
begin
  Result := 99;
end;

{ TService0 }

{----------------------------------------------------------------------------------------------------------------------}
function TService0.DepValue: Integer;
begin
  Result := -1; // no dep
end;

{----------------------------------------------------------------------------------------------------------------------}
function TService0.SelfId: NativeInt;
begin
  Result := NativeInt(Pointer(Self));
end;

{ TService1 }

{----------------------------------------------------------------------------------------------------------------------}
constructor TService1.Create(const Dep: IDep);
begin
  inherited Create;
  FDep := Dep;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TService1.DepValue: Integer;
begin
  if Assigned(FDep) then
    Result := FDep.Value
  else
    Result := -1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TService1.SelfId: NativeInt;
begin
  Result := NativeInt(Pointer(Self));
end;

{ TBadService }

{----------------------------------------------------------------------------------------------------------------------}
constructor TBadService.Create(const S: string);
begin
  inherited Create;
  // should never be called in these tests
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBadService.DepValue: Integer;
begin
  Result := -1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBadService.SelfId: NativeInt;
begin
  Result := NativeInt(Pointer(Self));
end;

{ TFoo }

{----------------------------------------------------------------------------------------------------------------------}
constructor TFoo.Create;
begin
  inherited Create;
  Inc(Instances);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TFoo.Destroy;
begin
  Dec(Instances);
  inherited;
end;

{ TMultiCtor }

{----------------------------------------------------------------------------------------------------------------------}
constructor TMultiCtor.Create;
begin
  inherited Create;
  FDep := nil;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TMultiCtor.Create(const Dep: IDep);
begin
  inherited Create;
  FDep := Dep;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TMultiCtor.DepAssigned: Boolean;
begin
  Result := Assigned(FDep);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TMultiCtor.DepValue: Integer;
begin
  if Assigned(FDep) then Result := FDep.Value else Result := -1;
end;

end.
