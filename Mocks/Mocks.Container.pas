unit Mocks.Container;

interface

uses
  Base.Container;

type
  INotRegistered = interface
    ['{D6F6A6B9-4B19-4F6F-8E47-1B2D4A5C6D7E}']
  end;

  TOnlyUnsatisfiedCtor = class
  public
    constructor Create(const aSvc: INotRegistered); overload;
    constructor Create; overload;
  end;

  TBestDep = class
  public
    Value: Integer;
    constructor Create;
  end;

  IBestSvc = interface
    ['{E0A1B4E8-9F2A-4A38-8C4E-4B6F1D2B8C31}']
    function Ping: Integer;
  end;

  TBestSvc = class(TInterfacedObject, IBestSvc)
  public
    function Ping: Integer;
  end;

  // Multiple ctors: should pick the one with most resolvable args.
  TMultiCtorBest = class
  public
    Dep: TBestDep;
    Svc: IBestSvc;

    constructor Create; overload;
    constructor Create(aDep: TBestDep); overload;
    constructor Create(aDep: TBestDep; const aSvc: IBestSvc); overload;
  end;

  // Only ctor requires unregistered class -> should fail (baseline behavior).
  TOnlyUnregisteredCtor = class
  public
    constructor Create(aDep: TObject); // we'll replace with a real unregistered type in the test unit if you prefer
  end;

  // Has a private ctor that would otherwise match; should be ignored.
  TPrivateCtor = class
  private
  {$HINTS OFF}
    constructor Create(aDep: TBestDep); overload;
  {$HINTS ON}
  public
    constructor Create; overload;
  end;

  IBasicService0 = interface
    ['{1E2D94F0-8EAD-4B2A-9B28-6D04C91753E1}']
    function Ping: Integer;
  end;

  TBasicService0 = class(TInterfacedObject, IBasicService0)
  public
    function Ping: Integer;
  end;

  TBasicDep0 = class
  public
    Value: Integer;
    constructor Create;
  end;

  TBasicCtor1 = class
  public
    Dep: TBasicDep0;
    Svc: IBasicService0;
    constructor Create(aDep: TBasicDep0; const aSvc: IBasicService0);
    destructor Destroy; override;
  end;

  TBasicParamHost = class
  public
    constructor Create(aDep: TBasicDep0; const aSvc: IBasicService0);
  end;

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

  TRegisteredDep = class
  public
    function Name: string; virtual;
  end;

  TRegisteredDepImpl = class(TRegisteredDep)
  public
    function Name: string; override;
  end;

  IRegisteredSvc = interface
    ['{9C5D5C1A-7D64-4D87-9CC2-1D2F6F34C4E1}']
    function Ping: Integer;
  end;

  TRegisteredSvc = class(TInterfacedObject, IRegisteredSvc)
  public
    function Ping: Integer;
  end;

  TUnregisteredDep = class
  public
    function Value: Integer;
  end;

  TMixedCtor = class
  private
    fDep1: TRegisteredDep;
    fSvc: IRegisteredSvc;
    fDep3: TUnregisteredDep;
  public
    constructor Create(aDep1: TRegisteredDep; aSvc: IRegisteredSvc; aDep3: TUnregisteredDep);
    destructor Destroy; override;

    property Dep1: TRegisteredDep read fDep1;
    property Svc: IRegisteredSvc read fSvc;
    property Dep3: TUnregisteredDep read fDep3;
  end;

  TCtorWithUnregisteredArg = class
  private
    fDep: TUnregisteredDep;
  public
    constructor Create(aDep: TUnregisteredDep);
    destructor Destroy; override;

    property Dep: TUnregisteredDep read fDep;
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
  C.Add<ITestSvc, TTestSvc>(Singleton, 'A');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TTestModuleB.RegisterServices(const C: TContainer);
begin
  // Register a different named mapping
  C.Add<ITestSvc, TTestSvc>(Singleton, 'B');
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

{ TRegisteredDep }

{----------------------------------------------------------------------------------------------------------------------}
function TRegisteredDep.Name: string;
begin
  Result := 'base';
end;

{ TRegisteredDepImpl }

{----------------------------------------------------------------------------------------------------------------------}
function TRegisteredDepImpl.Name: string;
begin
  Result := 'impl';
end;

{ TRegisteredSvc }

{----------------------------------------------------------------------------------------------------------------------}
function TRegisteredSvc.Ping: Integer;
begin
  Result := 42;
end;

{ TUnregisteredDep }

{----------------------------------------------------------------------------------------------------------------------}
function TUnregisteredDep.Value: Integer;
begin
  Result := 7;
end;

{ TMixedCtor }

{----------------------------------------------------------------------------------------------------------------------}
constructor TMixedCtor.Create(ADep1: TRegisteredDep; ASvc: IRegisteredSvc; ADep3: TUnregisteredDep);
begin
  inherited Create;

  fDep1 := aDep1;
  fSvc  := aSvc;
  fDep3 := aDep3;
end;

{ TCtorWithUnregisteredArg }

{----------------------------------------------------------------------------------------------------------------------}
constructor TCtorWithUnregisteredArg.Create(aDep: TUnregisteredDep);
begin
  fDep := aDep;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TCtorWithUnregisteredArg.Destroy;
begin
  fDep.Free;
  inherited;
end;

{ IService0 / TService0 }

{----------------------------------------------------------------------------------------------------------------------}
function TBasicService0.Ping: Integer;
begin
  Result := 42;
end;

{ TDep0 }

{----------------------------------------------------------------------------------------------------------------------}
constructor TBasicDep0.Create;
begin
  inherited Create;
  Value := 123;
end;

{ TCtor1 }

{----------------------------------------------------------------------------------------------------------------------}
constructor TBasicCtor1.Create(aDep: TBasicDep0; const aSvc: IBasicService0);
begin
  inherited Create;

  Dep := aDep;
  Svc := aSvc;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TBasicCtor1.Destroy;
begin
  Dep.Free;

  inherited;
end;

{ TParamHost }

{----------------------------------------------------------------------------------------------------------------------}
constructor TBasicParamHost.Create(aDep: TBasicDep0; const aSvc: IBasicService0);
begin
  inherited Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TBestDep.Create;
begin
  inherited Create;
  Value := 123;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBestSvc.Ping: Integer;
begin
  Result := 42;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TMultiCtorBest.Create;
begin
  inherited Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TMultiCtorBest.Create(aDep: TBestDep);
begin
  inherited Create;
  Dep := aDep;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TMultiCtorBest.Create(aDep: TBestDep; const aSvc: IBestSvc);
begin
  inherited Create;
  Dep := aDep;
  Svc := aSvc;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TMixedCtor.Destroy;
begin
  fDep1.Free;
  fDep3.Free;

  inherited;
end;


{----------------------------------------------------------------------------------------------------------------------}
constructor TOnlyUnregisteredCtor.Create(aDep: TObject);
begin
  inherited Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TPrivateCtor.Create;
begin
  inherited Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TPrivateCtor.Create(aDep: TBestDep);
begin
  inherited Create;
end;

{ TOnlyUnsatisfiedCtor }

{----------------------------------------------------------------------------------------------------------------------}
constructor TOnlyUnsatisfiedCtor.Create;
begin
  //
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TOnlyUnsatisfiedCtor.Create(const aSvc: INotRegistered);
begin
  //
end;

end.
