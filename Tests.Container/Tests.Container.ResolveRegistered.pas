unit Tests.Container.ResolveRegistered;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Base.Container,
  Mocks.Container;

type
  [TestFixture]
  TResolveRegisteredFixture = class
  public
    [Test] procedure Resolve_InterfaceInstance_ReturnsSame;
    [Test] procedure Resolve_InterfaceFactory_Transient_CreatesEachTime;
    [Test] procedure Resolve_InterfaceFactory_Singleton_Caches;
    [Test] procedure Resolve_Named_UsesCorrectRegistration;
    [Test] procedure TryResolve_Missing_ReturnsFalse;
    [Test] procedure Resolve_Missing_Raises;
  end;

implementation

uses
  Base.Integrity;

{ TResolveRegisteredFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.Resolve_InterfaceInstance_ReturnsSame;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  var inService := TTestSvc.Create;
  container.Add<ITestSvc>(inService);

  var outService := container.Resolve<ITestSvc>;

  Assert.AreSame(inService as TObject, outService as TObject);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.Resolve_InterfaceFactory_Transient_CreatesEachTime;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<ITestSvc>(Transient, function: ITestSvc begin Result := TTestSvc.Create; end);

  var transient1 := container.Resolve<ITestSvc>;
  var transient2 := container.Resolve<ITestSvc>;

  Assert.AreNotSame(transient1 as TObject, transient2 as TObject);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.Resolve_InterfaceFactory_Singleton_Caches;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<ITestSvc>(Singleton, function: ITestSvc begin Result := TTestSvc.Create; end);

  var singleton1 := container.Resolve<ITestSvc>;
  var singleton2 := container.Resolve<ITestSvc>;

  Assert.AreSame(singleton1, singleton2);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.Resolve_Named_UsesCorrectRegistration;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<ITestSvc>(Singleton, function: ITestSvc begin Result := TTestSvc.Create; end, 'A');
  container.Add<ITestSvc>(Singleton, function: ITestSvc begin Result := TTestSvc.Create; end, 'B');

  var singletonA := container.Resolve<ITestSvc>('A');
  var singletonB := container.Resolve<ITestSvc>('B');

  Assert.AreNotSame(singletonA, singletonB);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.TryResolve_Missing_ReturnsFalse;
var
  scope: TScope;
  service: ITestSvc;
begin
  var container := scope.Owns(TContainer.Create);
  Assert.IsFalse(container.TryResolve<ITestSvc>(service));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.Resolve_Missing_Raises;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  Assert.WillRaise(
    procedure
    var S: ITestSvc;
    begin
      S := container.Resolve<ITestSvc>;
    end,
    EArgumentException);
end;

initialization
  TDUnitX.RegisterTestFixture(TResolveRegisteredFixture);

end.
