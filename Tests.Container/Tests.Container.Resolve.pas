unit Tests.Container.Resolve;

interface

uses
  DUnitX.TestFramework,
  System.Rtti;

type
  [TestFixture]
  TResolveFixture = class
  private
    ctx: TRttiContext;

    function GetCtorParamType(const AClass: TClass; const ParamName: string): TRttiType;

  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test] procedure TypeMap_Interface_Parameterless_Transient_Builds;
    [Test] procedure TypeMap_Interface_Singleton_Caches;
    [Test] procedure TypeMap_Interface_CtorInjection_Resolves_Dep;
    [Test] procedure TypeMap_Interface_CtorInjection_Resolves_To_Default;

    [Test] procedure Factory_Interface_Transient_NotCached;

    [Test] procedure TypeMap_Class_Transient_Builds_CallerOwns;
    [Test] procedure TypeMap_Class_Singleton_Caches_ContainerOwns;
    [Test] procedure FindBestConstructor_PicksInjectableCtor_AndInvokeWorks;

    [Test] procedure TryResolveByTypeInfo_Interface_Registered_ReturnsTrue;
    [Test] procedure TryResolveByTypeInfo_Interface_Unregistered_ReturnsFalse;

    [Test] procedure TryResolveClassByTypeInfo_Class_Registered_ReturnsTrue;
    [Test] procedure TryResolveClassByTypeInfo_Class_Unregistered_ReturnsFalse;

    [Test] procedure BuildObject_SimpleClass_NoArgs_Constructs;
    [Test] procedure BuildObject_CtorInjection_RegisteredArgs_Constructs;

    [Test] procedure TryResolveParam_InterfaceParam_Registered_Resolves;
    [Test] procedure TryResolveParam_ClassParam_Registered_Resolves;
    [Test] procedure TryResolveParam_UnregisteredClassParam_AutoRegistersAndResolves;

    [Test] procedure ResolveClass_MixedCtor_UsesRegisteredAndImplicitDependencies;
    [Test] procedure Single_Unregistered_Argument_Is_Resolved;

    [Test] procedure FindBestConstructor_IgnoresNonPublicConstructors;
    [Test] procedure FindBestConstructor_PicksMostResolvableParams;
    [Test] procedure FindBestConstructor_FallsBackToParameterlessCreate_WhenDepsUnsatisfied;

  end;

implementation

uses
  System.SysUtils,
  Base.Integrity,
  Base.Container,
  Mocks.Container;

{ TResolveFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.Setup;
begin
  ctx := TRttiContext.Create;

  TFoo.Instances := 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TearDown;
begin
  ctx.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.Single_Unregistered_Argument_Is_Resolved;
begin
  var scope: TScope;

  var container := scope.Owns(TContainer.Create);

  container.AddClassType<TCtorWithUnregisteredArg>(Transient);

  var obj := container.ResolveClass<TCtorWithUnregisteredArg>;

  scope.Owns(obj);

  Assert.IsNotNull(obj);
  Assert.IsNotNull(obj.Dep);
  Assert.AreEqual(7, obj.Dep.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.ResolveClass_MixedCtor_UsesRegisteredAndImplicitDependencies;
var scope : TScope;
begin
    var container := scope.Owns(TContainer.Create);

    container.AddClassType<TRegisteredDep, TRegisteredDepImpl>(Transient);
    container.Add<IRegisteredSvc, TRegisteredSvc>(Transient);
    container.AddClassType<TMixedCtor>(Transient);

    var obj := container.ResolveClass<TMixedCtor>;

    scope.Owns(obj);

    Assert.IsNotNull(obj);
    Assert.IsNotNull(obj.Dep1);
    Assert.IsTrue(obj.Dep1 is TRegisteredDepImpl, 'Expected mapped implementation for TRegisteredDep');
    Assert.AreEqual('impl', obj.Dep1.Name);
    Assert.IsTrue(Assigned(obj.Svc));
    Assert.AreEqual(42, obj.Svc.Ping);
    Assert.IsNotNull(obj.Dep3);
    Assert.AreEqual(7, obj.Dep3.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.FindBestConstructor_PicksMostResolvableParams;
var
  scope: TScope;
  ctor: TRttiMethod;
  args: TArray<TValue>;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddClassType<TBestDep>(Transient);

  container.AddFactory<IBestSvc>(Transient, function: IBestSvc begin Result := TBestSvc.Create as IBestSvc; end);

  Assert.IsTrue(container.FindBestConstructor(TMultiCtorBest, ctor, args));
  Assert.IsNotNull(ctor);

  Assert.AreEqual<Integer>(2, Length(ctor.GetParameters));
  Assert.AreEqual<Integer>(2, Length(args));

  Assert.IsTrue(args[0].IsObject);

  var arg1 := scope.Owns(TBestDep(args[0].AsObject));

  Assert.IsTrue(arg1 is TBestDep);

  Assert.IsTrue(args[1].IsType<IBestSvc>);
  Assert.AreEqual(42, args[1].AsType<IBestSvc>.Ping);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.FindBestConstructor_FallsBackToParameterlessCreate_WhenDepsUnsatisfied;
var
  scope: TScope;
  container: TContainer;
  ctor: TRttiMethod;
  args: TArray<TValue>;
begin
  container := scope.Owns(TContainer.Create);

  Assert.IsTrue(container.FindBestConstructor(TOnlyUnsatisfiedCtor, ctor, args));
  Assert.IsNotNull(ctor);
  Assert.AreEqual<Integer>(0, Length(ctor.GetParameters));
  Assert.AreEqual<Integer>(0, Length(args));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.FindBestConstructor_IgnoresNonPublicConstructors;
var
  scope: TScope;
  ctor: TRttiMethod;
  args: TArray<TValue>;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddClassType<TBestDep>(Transient);

  Assert.IsTrue(container.FindBestConstructor(TPrivateCtor, ctor, args));
  Assert.IsNotNull(ctor);

  Assert.AreEqual<Integer>(0, Length(ctor.GetParameters));
  Assert.AreEqual<Integer>(0, Length(args));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.FindBestConstructor_PicksInjectableCtor_AndInvokeWorks;
var
  scope: TScope;
  ctor: TRttiMethod;
  args: TArray<TValue>;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddSingleton<IDep>(TDep.Create);

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

  container.Add<IService, TService0>(Transient);

  var service: IService := container.Resolve<IService>;

  Assert.IsTrue(Assigned(service));

  Assert.AreEqual(-1, service.DepValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TypeMap_Interface_Singleton_Caches;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<IService, TService0>(Singleton);

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
  container.AddSingleton<IDep>(dep);

  container.Add<IService, TService1>(Transient);

  var service: IService := container.Resolve<IService>;

  Assert.IsTrue(Assigned(service));
  Assert.AreEqual(99, service.DepValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TypeMap_Interface_CtorInjection_Resolves_To_Default;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<IService, TBadService>(Transient);

  var service: IService := container.Resolve<IService>;

  Assert.IsTrue(Assigned(service));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.Factory_Interface_Transient_NotCached;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddFactory<IService>(Transient, function: IService begin Result := TService0.Create as IService; end);

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

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TryResolveByTypeInfo_Interface_Registered_ReturnsTrue;
var
  scope: TScope;
  intf: IInterface;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddFactory<IBasicService0>(Transient,
    function: IBasicService0
    begin
      Result := TBasicService0.Create as IBasicService0;
    end);

  Assert.IsTrue(container.TryResolveByTypeInfo(TypeInfo(IBasicService0), intf, ''));
  Assert.IsTrue(Assigned(intf));
  Assert.AreEqual(42, (intf as IBasicService0).Ping);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TryResolveByTypeInfo_Interface_Unregistered_ReturnsFalse;
var
  scope: TScope;
  intf: IInterface;
begin
  var container := scope.Owns(TContainer.Create);

  Assert.IsFalse(container.TryResolveByTypeInfo(TypeInfo(IBasicService0), intf, ''));
  Assert.IsFalse(Assigned(intf));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TryResolveClassByTypeInfo_Class_Registered_ReturnsTrue;
var
  scope: TScope;
  obj: TObject;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddClassFactory<TBasicDep0>(Transient,
    function: TBasicDep0
    begin
      Result := TBasicDep0.Create;
    end);

  Assert.IsTrue(container.TryResolveClassByTypeInfo(TypeInfo(TBasicDep0), obj, ''));
  scope.Owns(obj);

  Assert.IsNotNull(obj);
  Assert.IsTrue(obj is TBasicDep0);
  Assert.AreEqual(123, TBasicDep0(obj).Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TryResolveClassByTypeInfo_Class_Unregistered_ReturnsFalse;
var
  scope: TScope;
  obj: TObject;
begin
  var container := scope.Owns(TContainer.Create);

  Assert.IsFalse(container.TryResolveClassByTypeInfo(TypeInfo(TBasicDep0), obj, ''));
  Assert.IsNull(obj);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.BuildObject_SimpleClass_NoArgs_Constructs;
var
  scope: TScope;
  obj: TObject;
begin
  var container := scope.Owns(TContainer.Create);

  Assert.IsTrue(container.BuildObject(TBasicDep0, obj));
  scope.Owns(obj);

  Assert.IsNotNull(obj);
  Assert.IsTrue(obj is TBasicDep0);
  Assert.AreEqual(123, TBasicDep0(obj).Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.BuildObject_CtorInjection_RegisteredArgs_Constructs;
var
  scope: TScope;
  obj: TObject;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddClassType<TBasicDep0>(Transient);

  container.AddFactory<IBasicService0>(Transient,
    function: IBasicService0
    begin
      Result := TBasicService0.Create as IBasicService0;
    end);

  Assert.IsTrue(container.BuildObject(TBasicCtor1, obj));
  scope.Owns(obj);

  Assert.IsTrue(obj is TBasicCtor1);
  Assert.IsNotNull(TBasicCtor1(obj).Dep);
  Assert.IsTrue(Assigned(TBasicCtor1(obj).Svc));
  Assert.AreEqual(123, TBasicCtor1(obj).Dep.Value);
  Assert.AreEqual(42, TBasicCtor1(obj).Svc.Ping);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TryResolveParam_InterfaceParam_Registered_Resolves;
var
  scope: TScope;
  v: TValue;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddFactory<IBasicService0>(Transient,
    function: IBasicService0
    begin
      Result := TBasicService0.Create as IBasicService0;
    end);

  var paramType := GetCtorParamType(TBasicParamHost, 'aSvc');
  Ensure.IsAssigned(paramType, 'Param RTTI missing');

  Assert.IsTrue(container.TryResolveParam(paramType, v));
  Assert.IsTrue(v.IsType<IBasicService0>);
  Assert.AreEqual(42, v.AsType<IBasicService0>.Ping);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TryResolveParam_ClassParam_Registered_Resolves;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  var v: TValue;

  container.AddClassType<TBasicDep0>(Transient);

  var paramType := GetCtorParamType(TBasicParamHost, 'aDep');
  Ensure.IsAssigned(paramType, 'Param RTTI missing');

  Assert.IsTrue(container.TryResolveParam(paramType, v));

  var obj := scope.Owns(v.AsObject);

  Assert.IsTrue(obj is TBasicDep0);
  Assert.AreEqual(123, TBasicDep0(obj).Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResolveFixture.TryResolveParam_UnregisteredClassParam_AutoRegistersAndResolves;
var
  scope: TScope;
  container: TContainer;
  v: TValue;
  paramType: TRttiType;
  dep: TUnregisteredDep;
begin
  container := scope.Owns(TContainer.Create);

  paramType := GetCtorParamType(TCtorWithUnregisteredArg, 'aDep');
  Ensure.IsAssigned(paramType);

  Assert.IsTrue(container.TryResolveParam(paramType, v));
  Assert.IsTrue(v.IsObject);
  Assert.IsNotNull(v.AsObject);

  dep := scope.Owns(TUnregisteredDep(v.AsObject));
  Assert.AreEqual(7, dep.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResolveFixture.GetCtorParamType(const AClass: TClass; const ParamName: string): TRttiType;
var
  T: TRttiType;
  M: TRttiMethod;
  P: TRttiParameter;
begin
  T := ctx.GetType(AClass);

  Ensure.IsAssigned(T, 'RTTI missing for class');

  for M in T.GetMethods do
    if M.IsConstructor and SameText(M.Name, 'Create') then
    begin
      for P in M.GetParameters do
        if SameText(P.Name, ParamName) then
          Exit(P.ParamType);

      Break;
    end;

  Result := nil;
end;


initialization
  TDUnitX.RegisterTestFixture(TResolveFixture);

end.
