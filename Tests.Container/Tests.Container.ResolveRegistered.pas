unit Tests.Container.ResolveRegistered;

interface

uses
  DUnitX.TestFramework;

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
    [Test] procedure ResolveClass_ObjectInstance_ReturnsSame;
    [Test] procedure ResolveClass_ObjectFactory_Transient_CreatesEachTime;
    [Test] procedure ResolveClass_ObjectFactory_Singleton_Caches;
    [Test] procedure ResolveClass_ObjectInstance_TakeOwnershipFalse_DoesNotFree;
    [Test] procedure TryResolveClass_Missing_ReturnsFalse;
    [Test] procedure ResolveClass_Missing_Raises;
  end;

implementation

uses
  System.SysUtils,
  Base.Integrity,
  Base.Container,
  Mocks.Container;

{ TResolveRegisteredFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.Resolve_InterfaceInstance_ReturnsSame;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  var inService := TTestSvc.Create;
  container.AddSingleton<ITestSvc>(inService);

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

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.ResolveClass_ObjectInstance_ReturnsSame;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  var service := TObjectSvc.Create;
  service.Value := 10;

  container.AddClass<TObjectSvc>(service);

  var instance := container.ResolveClass<TObjectSvc>;

  Assert.AreSame(service, instance);
  Assert.AreEqual(10, instance.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.ResolveClass_ObjectFactory_Transient_CreatesEachTime;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddClass<TObjectSvc>(Transient, function: TObjectSvc begin Result := TObjectSvc.Create; end);

  var instanceA := scope.Owns(container.ResolveClass<TObjectSvc>());
  var instanceB := scope.Owns(container.ResolveClass<TObjectSvc>());

  Assert.AreNotSame(instanceA, instanceB);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.ResolveClass_ObjectFactory_Singleton_Caches;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddClass<TObjectSvc>(Singleton, function: TObjectSvc begin Result := TObjectSvc.Create; end);

  var refA := container.ResolveClass<TObjectSvc>;
  var refB := container.ResolveClass<TObjectSvc>;

  Assert.AreSame(refA, refB);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.ResolveClass_ObjectInstance_TakeOwnershipFalse_DoesNotFree;
var
  lObject: TTracked;
begin
  TTracked.FreedCount := 0;

  var container := TContainer.Create;
  try
    lObject := TTracked.Create;
    container.AddClass<TTracked>(lObject, '', false);
  finally
    container.Free;
  end;

  Assert.AreEqual(0, TTracked.FreedCount, 'Container should not free non-owned instance');
  lObject.Free;
  Assert.AreEqual(1, TTracked.FreedCount, 'Caller should free non-owned instance');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.TryResolveClass_Missing_ReturnsFalse;
var
  scope : TScope;
  lObject: TObjectSvc;
begin
  var container := scope.Owns(TContainer.Create);

  Assert.IsFalse(container.TryResolveClass<TObjectSvc>(lObject));
  Assert.IsNull(lObject);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveRegisteredFixture.ResolveClass_Missing_Raises;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  Assert.WillRaise(procedure begin container.ResolveClass<TObjectSvc>; end, EArgumentException);
end;

initialization
  TDUnitX.RegisterTestFixture(TResolveRegisteredFixture);

end.
