unit Tests.Container.Resolve;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TResolveFixture = class
  public
    [Setup]
    procedure Setup;

    [Test] procedure TypeMap_Interface_Parameterless_Transient_Builds;
    [Test] procedure TypeMap_Interface_Singleton_Caches;
    [Test] procedure TypeMap_Interface_CtorInjection_Resolves_Dep;
    [Test] procedure TypeMap_Interface_CtorInjection_Resolves_To_Default;

    [Test] procedure Factory_Interface_Transient_NotCached;

    [Test] procedure TypeMap_Class_Transient_Builds_CallerOwns;
    [Test] procedure TypeMap_Class_Singleton_Caches_ContainerOwns;
    [Test] procedure FindBestConstructor_PicksInjectableCtor_AndInvokeWorks;
  end;

implementation

uses
  System.SysUtils,
  System.Rtti,
  Base.Integrity,
  Base.Container,
  Mocks.Container;

{ TResolveFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.Setup;
begin
  TFoo.Instances := 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.FindBestConstructor_PicksInjectableCtor_AndInvokeWorks;
var
  scope: TScope;
  ctor: TRttiMethod;
  args: TArray<TValue>;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<IDep>(TDep.Create);

  Assert.IsTrue(container.FindBestConstructor(TMultiCtor, ctor, args), 'Expected to find a constructor');
  Assert.IsNotNull(Ctor, 'Ctor should be assigned');
  Assert.AreEqual(1, Length(Args), 'Expected injectable ctor with 1 param');

  var classValue := TValue.From<TClass>(TMultiCtor);
  var created    := Ctor.Invoke(classValue, Args);
  var obj        := scope.Owns(Created.AsObject);

  Assert.IsTrue(Assigned(obj));

  var instance :TMultiCtor := TMultiCtor(obj);

  Assert.IsTrue(instance.DepAssigned);
  Assert.AreEqual(99, instance.DepValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TypeMap_Interface_Parameterless_Transient_Builds;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddType<IService, TService0>(Transient);

  var service: IService := container.Resolve<IService>;

  Assert.IsTrue(Assigned(service));

  Assert.AreEqual(-1, service.DepValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TypeMap_Interface_Singleton_Caches;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddType<IService, TService0>(Singleton);

  var serviceA: IService := container.Resolve<IService>;
  var serviceB: IService := container.Resolve<IService>;

  Assert.IsTrue(Assigned(serviceA));
  Assert.IsTrue(Assigned(serviceB));

  Assert.AreEqual(serviceA.SelfId, serviceB.SelfId);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TypeMap_Interface_CtorInjection_Resolves_Dep;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  var dep: IDep := TDep.Create;
  container.Add<IDep>(dep);

  container.AddType<IService, TService1>(Transient);

  var service: IService := container.Resolve<IService>;

  Assert.IsTrue(Assigned(service));
  Assert.AreEqual(99, service.DepValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TypeMap_Interface_CtorInjection_Resolves_To_Default;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddType<IService, TBadService>(Transient);

  var service: IService := container.Resolve<IService>;

  Assert.IsTrue(Assigned(service));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.Factory_Interface_Transient_NotCached;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<IService>(Transient,
    function: IService
    begin
      Result := TService0.Create as IService;
    end);

  var serviceA: IService := container.Resolve<IService>;
  var serviceB: IService := container.Resolve<IService>;

  Assert.AreNotEqual(serviceA.SelfId, serviceB.SelfId);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TypeMap_Class_Transient_Builds_CallerOwns;
begin
  try
    var scope: TScope;
    var container := scope.Owns(TContainer.Create);

    container.AddClassType<TFoo>(Transient);

    var fooA := scope.Owns(container.ResolveClass<TFoo>);
    var fooB := scope.Owns(container.ResolveClass<TFoo>);

    Assert.IsTrue(Assigned(fooA));
    Assert.IsTrue(Assigned(fooB));

    Assert.AreNotSame(fooA, fooB);
    Assert.AreEqual(2, TFoo.Instances);
  finally
    Assert.AreEqual(0, TFoo.Instances);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TypeMap_Class_Singleton_Caches_ContainerOwns;
begin
  try
    var scope: TScope;
    var container := scope.Owns(TContainer.Create);

    container.AddClassType<TFoo>(Singleton);

    var fooA := container.ResolveClass<TFoo>;
    var fooB := container.ResolveClass<TFoo>;

    Assert.IsTrue(Assigned(fooA));
    Assert.IsTrue(Assigned(fooB));

    Assert.AreSame(fooA, fooB);

    Assert.AreEqual(1, TFoo.Instances);
  finally
    Assert.AreEqual(0, TFoo.Instances);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TResolveFixture);

end.
