{***************************************************************************************************
  Project:     Galahad
  Unit:        Base.Container
  Author:      David Harper
  License:     MIT
  Purpose:     Provides a lightweight, explicit, and Delphi-native Dependency Injection container.

  Overview
  --------
  Base.Container implements a pragmatic IoC / DI container designed specifically for Delphi.
  It favors explicit registration, predictable behavior, and compatibility with Delphi’s
  object model, RTTI, and memory management semantics.

  The container intentionally avoids "magic" behaviors such as automatic type scanning,
  attribute-based registration, or open-generic resolution. Preferring services to be explicitly
  registered by the user due to Delphi's aggressive Linker trimming.

  Ownership
  ---------
  Although constructor arguments with unregistered class types are supported, this is discouraged
  because it introduces ownership ambiguity. Auto-registered classes are always transient.

  Ownership rules for class-based services:

  - Singleton class registrations: the container may own and dispose the singleton instance (depending on registration).
  - Transient class instances (registered or implicit): the container creates them to satisfy a request but does
    not track or dispose them afterwards. Ownership is effectively transferred to the receiver.

  Because Delphi does not enforce ownership, mixing singleton and transient class injection can easily lead
  to double frees or leaks if consumers guess wrong about who should free a dependency.

  To avoid confusion and make lifetime predictable:

  - Register services against interfaces (use Add<ICustomerRepository, TCustomerRepository>)
  - Use interfaces for constructor argument types (e.g. ICustomerRepository)

  With interface-based services, lifetime is managed automatically through reference counting:
  request, use, forget — no manual memory management.

  Prefer the core methods (such as Add, AddSingleton - see below) for safe memory management.

  Modules allow you to group requirements, register them with AddModule.

  TContainer can be used for local purposes, but it's recommended to use the default container for
  applications, which is exposed via the global "Container" function.

***************************************************************************************************}

unit Base.Container;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.TypInfo,
  System.Rtti,
  Base.Core,
  Base.Integrity;

type
  EContainerError = class(Exception);
  EServiceNotRegistered = class(EContainerError);
  EServiceAlreadyRegistered = class(EContainerError);

  TServiceLifetime = (Singleton, Transient);
  TRegistrationKind = (Instance, Factory, TypeMap);

  /// <summary>
  ///  Identifies a registration. Name is optional; '' means default registration.
  ///  TypeInfo is required and is typically an interface or class typeinfo.
  /// </summary>
  TServiceKey = record
  public
    TypeInfo: PTypeInfo;
    Name: string;

    class function Create(aTypeInfo: PTypeInfo; const aName: string = ''): TServiceKey; static; inline;
  end;

  /// <summary>
  ///  Registration metadata stored by the container/registry.
  ///  Supports:
  ///  - Instance registrations (interface or object)
  ///  - Factory registrations (interface or object)
  ///  - Type-map registrations (interface->class, or class self-binding)
  ///
  ///  Ownership:
  ///  - OwnsInstance applies only to object singleton instance registrations.
  ///    If True, container will Free the instance when container is destroyed.
  /// </summary>
  TRegistration = record
  public
    Key: TServiceKey;
    Lifetime: TServiceLifetime;
    Kind: TRegistrationKind;

    // Provider details
    ImplClass: TClass; // for TypeMap

    // Factories (stored untyped to keep registry simple)
    FactoryIntf: TFunc<IInterface>;
    FactoryObj: TFunc<TObject>;

    // Object singleton instance ownership flag
    OwnsInstance: Boolean;

    // Diagnostics (optional but useful)
    ServiceTypeName: string;
  end;

  /// <summary>
  /// Thread-safe registration registry.
  /// </summary>
  TServiceRegistry = class
  private type
    TKeyComparer = class(TInterfacedObject, IEqualityComparer<TServiceKey>)
    public
      function Equals(const aLeft, aRight: TServiceKey): Boolean; reintroduce;
      function GetHashCode(const aValue: TServiceKey): Integer; reintroduce;
    end;
  private
    fLock: TObject;
    fMap: TDictionary<TServiceKey, TRegistration>;
    fComparer: IEqualityComparer<TServiceKey>;
  public
    procedure Clear;
    procedure Add(const aReg: TRegistration);

    function TryGet(const aKey: TServiceKey; out aReg: TRegistration): Boolean;
    function Contains(const aKey: TServiceKey): Boolean;

    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>
  ///  Represents a singleton value.
  /// </summary>
  TSingletonValue = record
    IsObject: Boolean;
    OwnsObject: Boolean;
    Intf: IInterface;
    Obj: TObject;
  end;

  /// <summary>
  ///  Thread-safe cache of singleton instances (interface + object).
  ///  Stores instances by service key (type + name).
  /// </summary>
  TSingletonRegistry = class
  private
    fLock: TObject;
    fMap: TDictionary<TServiceKey, TSingletonValue>;
    fComparer: IEqualityComparer<TServiceKey>;
  public
    procedure PutInterface(const aKey: TServiceKey; const aValue: IInterface);
    procedure PutObject(const aKey: TServiceKey; aValue: TObject; aOwns: Boolean);

    function TryGet(const aKey: TServiceKey; out aValue: TSingletonValue): Boolean;
    procedure Clear; // releases interfaces and frees owned objects

    constructor Create(const aComparer: IEqualityComparer<TServiceKey>);
    destructor Destroy; override;
  end;

  TContainer = class; // forward delcaration

  /// <summary>
  ///  Modules are the preferred grouping for service registration.
  /// </summary>
  IContainerModule = interface
    ['{3D71D3B6-7F2A-4E3E-9E29-0D40E9A0E2C1}']
    /// <summary>
    /// Registers services into the provided container.
    /// </summary>
    procedure RegisterServices(const C: TContainer);
  end;

  /// <summary>
  ///  The key component in the dependency injection architecture. The container exposes
  ///  APIs for registering and resolving services.
  /// </summary>
  TContainer = class
  private
    fRegistry: TServiceRegistry;
    fSingletons: TSingletonRegistry;

    class var fContext: TRttiContext;

    procedure EnsureAutoRegisteredClass(const aServiceType: PTypeInfo);

{$IFNDEF TESTINSIGHT}
    function TryResolveByTypeInfo(aServiceType: PTypeInfo; out aIntf: IInterface; const aName: string = ''): Boolean;
    function TryResolveClassByTypeInfo(aServiceType: PTypeInfo; out aObj: TObject; const aName: string = ''): Boolean;
    function BuildObject(const aImplClass: TClass; out aObj: TObject): Boolean;
    function TryResolveParam(const aParamType: TRttiType; out aValue: TValue): Boolean;
    function FindBestConstructor(const aImplClass: TClass; out aCtor: TRttiMethod; out aArgs: TArray<TValue>): Boolean;
{$ENDIF}

  public

{$IFDEF TESTINSIGHT}
    function TryResolveByTypeInfo(aServiceType: PTypeInfo; out aIntf: IInterface; const aName: string = ''): Boolean;
    function TryResolveClassByTypeInfo(aServiceType: PTypeInfo; out aObj: TObject; const aName: string = ''): Boolean;
    function BuildObject(const aImplClass: TClass; out aObj: TObject): Boolean;
    function TryResolveParam(const aParamType: TRttiType; out aValue: TValue): Boolean;
    function FindBestConstructor(const aImplClass: TClass; out aCtor: TRttiMethod; out aArgs: TArray<TValue>): Boolean;
{$ENDIF}

    {------------------------------------------------ core methods ----------------------------------------------------}

    /// <summary>
    ///  Registers an interface instance as a singleton service.
    ///  The container holds a reference to the interface and will release it when the container is destroyed or cleared.
    /// </summary>
    /// <remarks>
    ///  The service is keyed by (TypeInfo(T), aName). An empty name means the default registration.
    ///  Raises EArgumentException if an identical key is already registered (via Ensure).
    /// </remarks>
    procedure AddSingleton<T: IInterface>(const aInstance: T; const aName: string = '');

    /// <summary>
    ///  Registers an interface factory for the given lifetime.
    /// </summary>
    /// <remarks>
    ///  For Singleton, the factory will be invoked at most once per key and the resulting interface is cached.
    ///  For Transient, the factory is invoked on each resolution.
    ///
    ///  The service is keyed by (TypeInfo(T), aName). An empty name means the default registration.
    ///  Raises EArgumentException if an identical key is already registered (via Ensure).
    /// </remarks>
    procedure Add<T: IInterface>(aLifetime: TServiceLifetime; const aFactory:TConstFunc<T>; const aName: string = ''); overload;

    /// <summary>
    ///  Registers a type mapping from an interface service type to a concrete implementation class.
    /// </summary>
    /// <remarks>
    ///  This does not construct anything at registration time; it only records that requests for TService
    ///  should be satisfied by TImpl, subject to the specified lifetime and name.
    ///
    ///  Construction and constructor-injection are implemented later (typically using RTTI) once the
    ///  ServiceLocator is available to find missing dependencies.
    ///
    ///  The mapping is keyed by (TypeInfo(TService), aName). An empty name means the default registration.
    ///  Raises EArgumentException if an identical key is already registered (via Ensure).
    /// </remarks>
    procedure Add<TService: IInterface; TImpl: class>(aLifetime: TServiceLifetime; const aName: string = ''); overload;

    /// <summary>
    /// Applies a single module (grouped registrations) to this container.
    /// </summary>
    /// <remarks>
    /// Modules are invoked immediately; the container does not retain module references.
    /// Raises EArgumentException if the module is nil.
    /// </remarks>
    procedure AddModule(const aModule: IContainerModule); overload;

    /// <summary>
    /// Applies multiple modules (grouped registrations) to this container in order.
    /// </summary>
    /// <remarks>
    /// Each module is invoked immediately; the container does not retain module references.
    /// Raises EArgumentException if any module is nil.
    /// </remarks>
    procedure AddModule(const aModules: array of IContainerModule); overload;

    /// <summary>
    ///  Resolves an interface service by type and optional name, raising on failure.
    /// </summary>
    /// <remarks>
    ///  Raises EArgumentException if the service is not registered or cannot be resolved.
    ///  Use TryResolve for non-throwing behavior.
    /// </remarks>
    function Resolve<T: IInterface>(const aName: string = ''): T;

    /// <summary>
    ///  Attempts to resolve an interface service by type and optional name.
    /// </summary>
    /// <remarks>
    /// Resolution uses registrations only (instance/factory/type-map as supported by the container version).
    ///
    ///  For interface singletons, the container returns a cached instance when available; otherwise it may invoke
    ///  the registered factory (for Singleton) and cache the result. For Transient registrations, the factory is
    ///  invoked on each call and the returned interface is not cached.
    ///
    /// Returns False if the service is not registered or cannot be constructed under current container capabilities.
    /// </remarks>
    function TryResolve<T: IInterface>(out aService: T; const aName: string = ''): Boolean;

    {------------------------------------------ special purpose methods -----------------------------------------------}

    /// <summary>
    ///  Registers a class instance as a singleton service.
    /// </summary>
    /// <param name="aTakeOwnership">
    ///  If True, the container owns the instance and will Free it when the container is destroyed or cleared.
    ///  If False, the caller retains ownership and must free the instance (the container will not).
    /// </param>
    /// <remarks>
    ///  The service is keyed by (TypeInfo(T), aName). An empty name means the default registration.
    ///  Raises EArgumentException if an identical key is already registered (via Ensure).
    /// </remarks>
    procedure AddClass<T: class>(aInstance: T; const aName: string = ''; aTakeOwnership: Boolean = True); overload;

    /// <summary>
    ///  Registers a class factory for the given lifetime.
    /// </summary>
    /// <remarks>
    ///  For Singleton, the factory will be invoked at most once per key and the resulting object is cached.
    ///  If the container creates the singleton via this factory, it owns that cached instance and will Free it
    ///  when the container is destroyed or cleared.
    ///
    ///  For Transient, the factory is invoked on each resolution and the caller owns the returned object and must Free it
    ///  (until scoped disposal/tracking is introduced).
    ///
    ///  The service is keyed by (TypeInfo(T), aName). An empty name means the default registration.
    ///  Raises EArgumentException if an identical key is already registered (via Ensure).
    /// </remarks>
    procedure AddClass<T: class>(aLifetime: TServiceLifetime; const aFactory: TConstFunc<T>; const aName: string = ''); overload;

    /// <summary>
    ///  Registers a type mapping for a concrete class service type to itself.
    /// </summary>
    /// <remarks>
    ///  Equivalent to mapping "T -> T". This is useful when resolving concrete classes via the container
    ///  (e.g. ResolveClass<T>) once type-map resolution is implemented.
    ///
    ///  The mapping is keyed by (TypeInfo(T), aName). An empty name means the default registration.
    ///  Raises EArgumentException if an identical key is already registered (via Ensure).
    /// </remarks>
    procedure AddClassType<T: class>(aLifetime: TServiceLifetime; const aName: string = '');  overload;
    procedure AddClassType<TBase: class; TImpl:TBase>(aLifetime: TServiceLifetime; const aName: string = ''); overload;

    /// <summary>
    /// Attempts to resolve a class instance by type and optional name.
    /// </summary>
    /// <remarks>
    ///  For class singletons, the container returns a cached instance when available; otherwise it may invoke
    ///  the registered factory (for Singleton) and cache the result. Singleton instances created by the container
    ///  are owned by the container and freed on Clear/Destroy.
    ///
    ///  For Transient registrations, the factory is invoked on each call. Until scoping / tracking is introduced,
    ///  transient objects are caller-owned and must be freed by the caller.
    ///
    ///  Returns False if the service is not registered, cannot be constructed, or is not assignable to T.
    /// </remarks>
    function TryResolveClass<T: class>(out aInstance: T; const aName: string = ''): Boolean;

    /// <summary>
    ///  Resolves a class instance by type and optional name, raising on failure.
    /// </summary>
    /// <remarks>
    ///  Raises EArgumentException if the service is not registered or cannot be resolved.
    ///  Use TryResolveClass for non-throwing behavior.
    /// </remarks>
    function ResolveClass<T: class>(const aName: string = ''): T;

    {---------------------------------------------- general methods ---------------------------------------------------}

    /// <summary>
    ///  Returns True if a service with the given type (and optional name) is registered.
    /// </summary>
    function IsRegistered<T>(const aName: string = ''): Boolean;

    /// <summary>
    ///  Clears all registrations and cached singleton instances.
    /// </summary>
    /// <remarks>
    ///  Releases cached interface singletons and frees any owned object singletons.
    /// </remarks>
    procedure Clear;

    class function TypeNameOf(aTypeInfo: PTypeInfo): string; static;

    constructor Create;
    destructor Destroy; override;

    class constructor Create;
    class destructor Destroy;
  end;

  /// <summary>
  ///  Manages a universal container for application/testing usage.
  /// </summary>
  DefaultContainer = class
  private
    class var fInstance: TContainer;

    class constructor Create;
    class destructor Destroy;
  end;

  /// <summary>
  ///  Provides access to the default container.
  /// </summary>
  function Container: TContainer;

implementation

uses
 System.StrUtils;

{----------------------------------------------------------------------------------------------------------------------}
function Container: TContainer;
begin
  Result := DefaultContainer.fInstance;
end;

{----------------------------------------------------------------------------------------------------------------------}
function NameOrDefault(const aName: string): string;
begin
  Result := if string.IsNullOrWhiteSpace(aName) then '"<default>"' else '"' + aName + '"';
end;

{ TServiceKey }

{----------------------------------------------------------------------------------------------------------------------}
class function TServiceKey.Create(aTypeInfo: PTypeInfo; const aName: string): TServiceKey;
begin
  Result.TypeInfo := aTypeInfo;
  Result.Name := aName;
end;

{ TServiceRegistry.TKeyComparer }

{----------------------------------------------------------------------------------------------------------------------}
function TServiceRegistry.TKeyComparer.Equals(const aLeft, aRight: TServiceKey): Boolean;
begin
  Result := (aLeft.TypeInfo = aRight.TypeInfo) and SameText(aLeft.Name, aRight.Name);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TServiceRegistry.TKeyComparer.GetHashCode(const aValue: TServiceKey): Integer;
begin
  // pointer hash + case-insensitive name hash
  var hash := NativeInt(aValue.TypeInfo);
  Result := hash xor (AnsiUpperCase(aValue.Name).GetHashCode);
end;

{ TServiceRegistry }

{----------------------------------------------------------------------------------------------------------------------}
procedure TServiceRegistry.Add(const aReg: TRegistration);
const
  MSG = 'Duplicate registration: %s (Name=%s)';
begin
  TMonitor.Enter(fLock);
  try
    Ensure.IsFalse(fMap.ContainsKey(aReg.Key), Format(MSG, [aReg.ServiceTypeName, NameOrDefault(aReg.Key.Name)]));

    fMap.Add(aReg.Key, aReg);
  finally
    TMonitor.Exit(fLock);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TServiceRegistry.TryGet(const aKey: TServiceKey; out aReg: TRegistration): Boolean;
begin
  TMonitor.Enter(FLock);
  try
    Result := fMap.TryGetValue(aKey, aReg);
  finally
    TMonitor.Exit(FLock);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TServiceRegistry.Contains(const aKey: TServiceKey): Boolean;
begin
  TMonitor.Enter(fLock);
  try
    Result := fMap.ContainsKey(aKey);
  finally
    TMonitor.Exit(fLock);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TServiceRegistry.Clear;
begin
  TMonitor.Enter(fLock);
  try
    fMap.Clear;
  finally
    TMonitor.Exit(fLock);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TServiceRegistry.Create;
begin
  inherited Create;

  fLock     := TObject.Create;
  fComparer := TKeyComparer.Create;
  fMap      := TDictionary<TServiceKey, TRegistration>.Create(fComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TServiceRegistry.Destroy;
begin
  fMap.Free;
  fLock.Free;

  inherited;
end;

{ TSingletonRegistry }

{----------------------------------------------------------------------------------------------------------------------}
procedure TSingletonRegistry.PutInterface(const aKey: TServiceKey; const aValue: IInterface);
var
  val: TSingletonValue;
begin
  val.IsObject := False;
  val.OwnsObject := False;
  val.Intf := aValue;
  val.Obj := nil;

  TMonitor.Enter(fLock);
  try
    FMap.AddOrSetValue(aKey, val);
  finally
    TMonitor.Exit(FLock);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSingletonRegistry.PutObject(const aKey: TServiceKey; aValue: TObject; aOwns: Boolean);
var
  val: TSingletonValue;
begin
  val.IsObject := True;
  val.OwnsObject := aOwns;
  val.Obj := aValue;
  val.Intf := nil;

  TMonitor.Enter(fLock);
  try
    FMap.AddOrSetValue(aKey, val);
  finally
    TMonitor.Exit(FLock);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSingletonRegistry.TryGet(const aKey: TServiceKey; out aValue: TSingletonValue): Boolean;
begin
  TMonitor.Enter(fLock);
  try
    Result := FMap.TryGetValue(aKey, aValue);
  finally
    TMonitor.Exit(FLock);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSingletonRegistry.Clear;
begin
  TMonitor.Enter(fLock);
  try
    for var item in fMap do
      if item.Value.IsObject and item.Value.OwnsObject then
        item.Value.Obj.Free;

    fMap.Clear;
  finally
    TMonitor.Exit(fLock);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSingletonRegistry.Create(const aComparer: IEqualityComparer<TServiceKey>);
begin
  inherited Create;

  fLock     := TObject.Create;
  fComparer := aComparer;
  fMap      := TDictionary<TServiceKey, TSingletonValue>.Create(fComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TSingletonRegistry.Destroy;
begin
  Clear;

  fMap.Free;
  fLock.Free;

  inherited;
end;

{ TContainer }

{----------------------------------------------------------------------------------------------------------------------}
class function TContainer.TypeNameOf(aTypeInfo: PTypeInfo): string;
begin
  if aTypeInfo = nil then exit('<nil>');
  Result := GetTypeName(aTypeInfo);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddSingleton<T>(const aInstance: T; const aName: string);
var
  lKey: TServiceKey;
  lReg: TRegistration;
begin
  Ensure.IsAssigned(aInstance, 'Add<T: IInterface>: instance is nil');

  lKey := TServiceKey.Create(TypeInfo(T), aName);

  lReg.Key := lKey;
  lReg.Lifetime := Singleton;
  lReg.Kind := Instance;
  lReg.ImplClass := nil;
  lReg.FactoryIntf := nil;
  lReg.FactoryObj := nil;
  lReg.OwnsInstance := False;
  lReg.ServiceTypeName := TypeNameOf(TypeInfo(T));

  fRegistry.Add(lReg);
  fSingletons.PutInterface(lKey, aInstance);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddClass<T>(aInstance: T; const aName: string; aTakeOwnership: Boolean);
var
  lKey: TServiceKey;
  lReg: TRegistration;
begin
  Ensure.IsAssigned(aInstance, 'AddClass<T: class>: instance is nil');

  lKey := TServiceKey.Create(TypeInfo(T), aName);

  lReg.Key := lKey;
  lReg.Lifetime := Singleton;
  lReg.Kind := Instance;
  lReg.ImplClass := aInstance.ClassType;
  lReg.FactoryIntf := nil;
  lReg.FactoryObj := nil;
  lReg.OwnsInstance := aTakeOwnership;
  lReg.ServiceTypeName := TypeNameOf(TypeInfo(T));

  fRegistry.Add(lReg);
  fSingletons.PutObject(lKey, aInstance, aTakeOwnership);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.Add<T>(aLifetime: TServiceLifetime; const aFactory: TConstFunc<T>; const aName: string);
var
  lKey: TServiceKey;
  lReg: TRegistration;
begin
  Ensure.IsAssigned(@aFactory, 'Add<T: IInterface>: factory is nil');

  lKey := TServiceKey.Create(TypeInfo(T), aName);

  lReg.Key := lKey;
  lReg.Lifetime := aLifetime;
  lReg.Kind := Factory;
  lReg.ImplClass := nil;
  lReg.FactoryObj := nil;
  lReg.OwnsInstance := False;
  lReg.ServiceTypeName := TypeNameOf(TypeInfo(T));

  lReg.FactoryIntf :=
    function: IInterface
    var
      Svc: T;
    begin
      Svc := aFactory();
      Result := Svc;
    end;

  fRegistry.Add(lReg);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddClass<T>(aLifetime: TServiceLifetime; const aFactory: TConstFunc<T>; const aName: string);
var
  lKey: TServiceKey;
  lReg: TRegistration;
begin
  Ensure.IsAssigned(@aFactory, 'AddClass<T: class>: factory is nil');

  lKey := TServiceKey.Create(TypeInfo(T), aName);

  lReg.Key := lKey;
  lReg.Lifetime := aLifetime;
  lReg.Kind := Factory;
  lReg.ImplClass := nil;
  lReg.FactoryIntf := nil;
  lReg.OwnsInstance := False;
  lReg.ServiceTypeName := TypeNameOf(TypeInfo(T));

  lReg.FactoryObj :=
    function: TObject
    begin
      Result := aFactory();
    end;

  fRegistry.Add(lReg);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.IsRegistered<T>(const aName: string): Boolean;
begin
  Result := fRegistry.Contains(TServiceKey.Create(TypeInfo(T), aName));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.Clear;
begin
  fSingletons.Clear;
  fRegistry.Clear;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.TryResolve<T>(out aService: T; const aName: string): Boolean;
var
  intf: IInterface;
begin
  intf := nil;

  Result := TryResolveByTypeInfo(TypeInfo(T), intf, aName);

  if Result then
    aService := T(Intf)
  else
    aService := Default(T);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.Resolve<T>(const aName: string): T;
const
  ERR = 'Service not registered: %s (Name="%s")';
begin
  if not TryResolve<T>(Result, aName) then
    raise EArgumentException.CreateFmt(ERR, [TypeNameOf(TypeInfo(T)), aName]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.TryResolveClass<T>(out aInstance: T; const aName: string): Boolean;
var
  obj: TObject;
begin
  obj := nil;

  Result := TryResolveClassByTypeInfo(TypeInfo(T), obj, aName);

  if Result then
    aInstance := T(obj)
  else
    aInstance := nil;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.ResolveClass<T>(const aName: string): T;
const
  ERR = 'Service not registered: %s (Name="%s")';
begin
  if not TryResolveClass<T>(Result, aName) then
    raise EArgumentException.CreateFmt(ERR, [TypeNameOf(TypeInfo(T)), aName]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.Add<TService, TImpl>(aLifetime: TServiceLifetime; const aName: string);
var
  Reg: TRegistration;
begin
  Ensure.IsTrue(PTypeInfo(TypeInfo(TService)).Kind = tkInterface,
    'AddType<TService,TImpl>: TService must be an interface');

  var key := TServiceKey.Create(TypeInfo(TService), aName);

  FillChar(Reg, SizeOf(Reg), 0);
  Reg.Key := Key;
  Reg.Kind := TypeMap;
  Reg.Lifetime := aLifetime;
  Reg.ImplClass := TImpl;
  Reg.FactoryIntf := nil;
  Reg.FactoryObj := nil;
  Reg.OwnsInstance := False;

  fRegistry.Add(Reg);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddClassType<T>(aLifetime: TServiceLifetime; const aName: string);
var
  Reg: TRegistration;
begin
  Ensure.IsTrue(T.InheritsFrom(TObject), 'AddClassType<T>: T must be a class');

  var key := TServiceKey.Create(TypeInfo(T), aName);

  FillChar(Reg, SizeOf(Reg), 0);
  Reg.Key := Key;
  Reg.Kind := TypeMap;
  Reg.Lifetime := aLifetime;
  Reg.ImplClass := T;
  Reg.FactoryIntf := nil;
  Reg.FactoryObj := nil;
  Reg.OwnsInstance := False;

  fRegistry.Add(Reg);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddModule(const aModule: IContainerModule);
begin
  Ensure.IsAssigned(aModule, 'AddModule: module is nil');
  aModule.RegisterServices(Self);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddModule(const aModules: array of IContainerModule);
begin
  for var i := 0 to High(aModules) do
  begin
    Ensure.IsAssigned(aModules[i], Format('AddModule: module[%d] is nil', [i]));
    aModules[i].RegisterServices(Self);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.BuildObject(const aImplClass: TClass; out aObj: TObject): Boolean;
var
  lCtor: TRttiMethod;
  lArgs: TArray<TValue>;
begin
  aObj := nil;
  Result := False;

  if aImplClass = nil then Exit;

  var rttiType := fContext.GetType(aImplClass);
  var instanceType := rttiType.AsInstance;

  if instanceType = nil then exit(false);

  if not FindBestConstructor(aImplClass, lCtor, lArgs) then exit;

  var created := lCtor.Invoke(instanceType.MetaclassType, lArgs);

  aObj := created.AsObject;

  Result := Assigned(aObj);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.FindBestConstructor(const aImplClass: TClass; out aCtor: TRttiMethod; out aArgs: TArray<TValue>): Boolean;
var
  lType: TRttiType;
  lCandidateArgs: TArray<TValue>;
  lBestCount: Integer;
  lValue: TValue;

  procedure DisposeCandidateArgs(const Args: TArray<TValue>);
  begin
    for var j := 0 to High(Args) do
      if Args[j].IsObject and (Args[j].AsObject <> nil) then
        Args[j].AsObject.Free;
  end;

begin
  aCtor := nil;
  SetLength(aArgs, 0);
  lBestCount := -1;

  lType := fContext.GetType(aImplClass);

  var instanceType := lType.AsInstance;
  if instanceType = nil then Exit(False);

  for var m in instanceType.GetMethods do
  begin
    if not m.IsConstructor then continue;
    if m.Visibility <> mvPublic then continue;

    var params := m.GetParameters;
    SetLength(lCandidateArgs, Length(params));

    var ok := True;

    // zero out candidate args so we can safely dispose partial fills
    for var k := 0 to High(lCandidateArgs) do
      lCandidateArgs[k] := TValue.Empty;

    for var i := 0 to High(params) do
    begin
      if not TryResolveParam(params[i].ParamType, lValue) then
      begin
        ok := False;
        Break;
      end;

      lCandidateArgs[i] := lValue;
    end;

    if not ok then
    begin
      // Candidate rejected: dispose any transient objects already created.
      DisposeCandidateArgs(lCandidateArgs);
      Continue;
    end;

    if Length(params) > lBestCount then
    begin
      // We are replacing the previous best: dispose the previous best args
      DisposeCandidateArgs(aArgs);

      lBestCount := Length(params);
      aCtor := m;
      aArgs := Copy(lCandidateArgs);

      // IMPORTANT: do NOT dispose lCandidateArgs now; it was copied into aArgs
      // (Copy keeps the same object references, so we must transfer ownership)
      // We can clear lCandidateArgs to avoid accidental disposal later:
      SetLength(lCandidateArgs, 0);
    end
    else
    begin
      // Candidate is valid but not best: dispose its created args
      DisposeCandidateArgs(lCandidateArgs);
    end;
  end;

  Result := Assigned(aCtor);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.TryResolveParam(const aParamType: TRttiType; out aValue: TValue): Boolean;
var
  lObj: TObject;
  lIntf: IInterface;
begin
  aValue := TValue.Empty;
  Result := False;

  if aParamType = nil then Exit;

  var info : PTypeInfo := aParamType.Handle;
  if info = nil then Exit;

  case info^.Kind of
    tkInterface:
      begin
        // Resolve by PTypeInfo: add a non-generic internal resolver
        if not Self.TryResolveByTypeInfo(info, lIntf, '') then exit(false);

        TValue.Make(@lIntf, info, aValue);
        exit(true);
      end;

    tkClass:
      begin
        if not Self.TryResolveClassByTypeInfo(info, lObj, '') then
        begin
          // If not registered, auto-register and retry once
          EnsureAutoRegisteredClass(info);

          if not Self.TryResolveClassByTypeInfo(info, lObj, '') then exit(False);
        end;

        TValue.Make(@lObj, info, aValue);
        exit(true);
      end;
  else
    exit(false); // no primitives/value-types injected in v1
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.TryResolveByTypeInfo(aServiceType: PTypeInfo; out aIntf: IInterface; const aName: string): Boolean;
var
  lReg: TRegistration;
  lValue: TSingletonValue;
  lObj: TObject;
begin
  aIntf := nil;

  if (aServiceType = nil) or (aServiceType^.Kind <> tkInterface) then exit(false);

  var key := TServiceKey.Create(aServiceType, aName);

  if not fRegistry.TryGet(key, lReg) then exit(False);

  // cached singleton?
  if (lReg.Lifetime = Singleton) then
  begin
    if fSingletons.TryGet(key, lValue) and (not lValue.IsObject) and Assigned(lValue.Intf) then
    begin
      aIntf := lValue.Intf;
      exit(true);
    end;
  end;

  // instance/factory/typemap
  case lReg.Kind of
    Instance:
      begin
        // Interface instances should have been placed in singleton registry by Add<T>(instance)
        if fSingletons.TryGet(key, lValue) and (not lValue.IsObject) and Assigned(lValue.Intf) then
        begin
          aIntf := lValue.Intf;
          Exit(true);
        end;

        exit(false);
      end;

    Factory:
      begin
        Ensure.IsAssigned(lReg.FactoryIntf, 'TryResolveByTypeInfo: FactoryIntf is nil');

        aIntf := lReg.FactoryIntf();

        if not Assigned(aIntf) then exit(false);

        if lReg.Lifetime = Singleton then
          fSingletons.PutInterface(key, aIntf);

        exit(true);
      end;

    TypeMap:
      begin
        if lReg.ImplClass = nil then exit(false);

        // Build the object and cast to requested interface
        if not BuildObject(lReg.ImplClass, lObj) then exit(False);

        var guid := GetTypeData(aServiceType)^.Guid;

        if not Supports(lObj, guid, aIntf) then
        begin
          lObj.Free;
          exit(false);
        end;

        // If singleton, cache by interface (preferred) — avoids object ownership issues
        if lReg.Lifetime = Singleton then
          fSingletons.PutInterface(key, aIntf);

        // IMPORTANT: do not free Obj; interface ref now owns it via refcounting
        exit(True);
      end;
  else
    exit(false);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.TryResolveClassByTypeInfo(aServiceType: PTypeInfo; out aObj: TObject; const aName: string): Boolean;
var
  lReg: TRegistration;
  lValue: TSingletonValue;
  lCreated: TObject;
begin
  aObj := nil;

  if (aServiceType = nil) or (aServiceType^.Kind <> tkClass) then exit(false);

  var key := TServiceKey.Create(aServiceType, aName);

  if not fRegistry.TryGet(key, lReg) then exit(False);

  // cached singleton?
  if (lReg.Lifetime = Singleton) then
  begin
    if fSingletons.TryGet(key, lValue) and lValue.IsObject and Assigned(lValue.Obj) then
    begin
      aObj := lValue.Obj;
      exit(true);
    end;
  end;

  case lReg.Kind of
    Instance:
      begin
        if fSingletons.TryGet(key, lValue) and lValue.IsObject and Assigned(lValue.Obj) then
        begin
          aObj := lValue.Obj;
          exit(true);
        end;

        exit(false);
      end;

    Factory:
      begin
        Ensure.IsAssigned(@lReg.FactoryObj, 'TryResolveClassByTypeInfo: FactoryObj is nil');

        lCreated := lReg.FactoryObj();

        if not Assigned(lCreated) then exit(false);

        // For singleton factory: cache and container owns by default
        if lReg.Lifetime = Singleton then
        begin
          fSingletons.PutObject(key, lCreated, True);
          aObj := lCreated;
          exit(true);
        end;

        // Transient: caller owns
        aObj := lCreated;
        exit(true);
      end;

    TypeMap:
      begin
        if lReg.ImplClass = nil then exit(false);

        // Build the implementation
        if not BuildObject(lReg.ImplClass, lCreated) then exit(false);

        // Ensure assignable to requested service class
        if not lCreated.InheritsFrom(GetTypeData(aServiceType)^.ClassType) then
        begin
          lCreated.Free;
          exit(false);
        end;

        if lReg.Lifetime = Singleton then
        begin
          fSingletons.PutObject(key, lCreated, True);
          aObj := lCreated;
          exit(true);
        end;

        aObj := lCreated;
        exit(true);
      end;
  else
    exit(false);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.EnsureAutoRegisteredClass(const aServiceType: PTypeInfo);
begin
  if (aServiceType = nil) or (aServiceType^.Kind <> tkClass) then  exit;
  if fRegistry.Contains(TServiceKey.Create(aServiceType, '')) then exit;

  // PTypeInfo for tkClass contains ClassType
  var td := GetTypeData(aServiceType);
  Ensure.IsAssigned(td, 'Auto-register: missing type data');

  // Create a "self type-map" registration (T -> T)
  var key := TServiceKey.Create(aServiceType, '');

  var reg: TRegistration;

  FillChar(reg, SizeOf(Reg), 0);

  reg.Key := key;
  reg.Kind := TypeMap;
  reg.Lifetime := Transient;
  reg.ImplClass := td.ClassType;
  reg.FactoryIntf := nil;
  reg.FactoryObj := nil;
  reg.OwnsInstance := False;
  reg.ServiceTypeName := TypeNameOf(aServiceType);

  Ensure.IsAssigned(reg.ImplClass, 'Auto-register: ClassType is nil');

  fRegistry.Add(reg);
end;


{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddClassType<TBase, TImpl>(aLifetime: TServiceLifetime; const aName: string);
const
  ERR = 'AddClassType<%s,%s>: %s does not inherit from %s';
var
  reg: TRegistration;
begin
  var key := TServiceKey.Create(TypeInfo(TBase), aName);

  FillChar(Reg, SizeOf(Reg), 0);
  Reg.Key := Key;
  Reg.Kind := TypeMap;
  Reg.Lifetime := aLifetime;
  Reg.ImplClass := TImpl;
  Reg.FactoryIntf := nil;
  Reg.FactoryObj := nil;
  Reg.OwnsInstance := False;
  Reg.ServiceTypeName := TypeNameOf(TypeInfo(TBase));

  fRegistry.Add(reg);
end;

{----------------------------------------------------------------------------------------------------------------------}
class constructor TContainer.Create;
begin
  fContext := TRttiContext.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TContainer.Create;
begin
  inherited Create;

  fRegistry := TServiceRegistry.Create;

  // Use same key comparer logic as the registry.
  fSingletons := TSingletonRegistry.Create(TServiceRegistry.TKeyComparer.Create);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TContainer.Destroy;
begin
  fSingletons.Free;
  fRegistry.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor TContainer.Destroy;
begin
  fContext.Free;
end;

{ DefaultContainer }

{----------------------------------------------------------------------------------------------------------------------}
class constructor DefaultContainer.Create;
begin
  fInstance := TContainer.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor DefaultContainer.Destroy;
begin
  FreeAndNil(fInstance);
end;

end.
