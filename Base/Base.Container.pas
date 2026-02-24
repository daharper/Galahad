{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Container
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Provides a lightweight, explicit, and Delphi-native Dependency Injection container.
-----------------------------------------------------------------------------------------------------------------------}

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

    function TryAdd(const aReg: TRegistration): Boolean;
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

    function AllParamsAreInjectableAndResolvable(const aCtor: TRttiMethod): Boolean;

{$IFNDEF TESTINSIGHT}
    function TryResolveByTypeInfo(aServiceType: PTypeInfo; out aIntf: IInterface; const aName: string = ''): Boolean;
    function TryResolveClassByTypeInfo(aServiceType: PTypeInfo; out aObj: TObject; const aName: string = ''): Boolean;
    function BuildObject(const aImplClass: TClass; out aObj: TObject): Boolean;
    function TryResolveParam(const aParamType: TRttiType; out aValue: TValue): Boolean;
    function FindBestConstructor(const aImplClass: TClass; out aCtor: TRttiMethod; out aArgs: TArray<TValue>): Boolean;

    class function TypeNameOf(aTypeInfo: PTypeInfo): string; static;
{$ENDIF}

  public

{$IFDEF TESTINSIGHT}
    function TryResolveByTypeInfo(aServiceType: PTypeInfo; out aIntf: IInterface; const aName: string = ''): Boolean;
    function TryResolveClassByTypeInfo(aServiceType: PTypeInfo; out aObj: TObject; const aName: string = ''): Boolean;
    function BuildObject(const aImplClass: TClass; out aObj: TObject): Boolean;
    function TryResolveParam(const aParamType: TRttiType; out aValue: TValue): Boolean;
    function FindBestConstructor(const aImplClass: TClass; out aCtor: TRttiMethod; out aArgs: TArray<TValue>): Boolean;

    class function TypeNameOf(aTypeInfo: PTypeInfo): string; static;
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
    procedure AddFactory<T: IInterface>(aLifetime: TServiceLifetime; const aFactory:TConstFunc<T>; const aName: string = ''); overload;

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
    ///
    ///  The lifetime is determined by whether the provider implements TSingleton or not.
    /// </remarks>
    procedure Add<TService: IInterface; TImpl: class>(const aName: string = ''); overload;

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

    procedure AddModule<T: IContainerModule, class, constructor>; overload;

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
    procedure AddClass<T: class>(aInstance: T; const aName: string = ''; aTakeOwnership: Boolean = True);

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
    procedure AddClassFactory<T: class>(aLifetime: TServiceLifetime; const aFactory: TConstFunc<T>; const aName: string = '');

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
    procedure AddClassType<TBase: class; TImpl:class>(aLifetime: TServiceLifetime; const aName: string = ''); overload;

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
function TServiceRegistry.TryAdd(const aReg: TRegistration): Boolean;
begin
  TMonitor.Enter(fLock);
  try
    if fMap.ContainsKey(aReg.Key) then
      Exit(False);

    fMap.Add(aReg.Key, aReg);
    Exit(True);
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
procedure TContainer.AddFactory<T>(aLifetime: TServiceLifetime; const aFactory: TConstFunc<T>; const aName: string);
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
procedure TContainer.AddClassFactory<T>(aLifetime: TServiceLifetime; const aFactory: TConstFunc<T>; const aName: string);
const
  E_SINGLE = 'AddClassFactory<%s>: %s inherits from TSingleton and cannot be registered as Transient';
var
  lKey: TServiceKey;
  lReg: TRegistration;
begin
  Ensure.IsAssigned(@aFactory, 'AddClass<T: class>: factory is nil')
        .IsFalse(T.InheritsFrom(TSingleton) and (aLifetime = Transient), Format(E_SINGLE, [T.ClassName, T.ClassName]));

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
procedure TContainer.Add<TService, TImpl>(const aName: string);
var
  inferred: TServiceLifetime;
begin
  // Infer from implementation type
  if TImpl.InheritsFrom(TSingleton) then
    inferred := Singleton
  else
    inferred := Transient;

  // Delegate to explicit overload (keeps all validation/registration logic in one place)
  Add<TService, TImpl>(inferred, aName);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.Add<TService, TImpl>(aLifetime: TServiceLifetime; const aName: string);
const
  ERR = 'Add<TService,TImpl>: TService must be an interface';
  E_SINGLE = 'Add<%s,%s>: %s inherits from TSingleton and cannot be registered as Transient';
var
  Reg: TRegistration;
begin
  Ensure.IsTrue(PTypeInfo(TypeInfo(TService)).Kind = tkInterface, ERR);

  if TImpl.InheritsFrom(TSingleton) then
    Ensure.IsFalse(aLifetime = Transient, Format(E_SINGLE, [TypeNameOf(TypeInfo(TService)), TImpl.ClassName, TImpl.ClassName]));

  var key := TServiceKey.Create(TypeInfo(TService), aName);

  FillChar(Reg, SizeOf(Reg), 0);
  Reg.Key := key;
  Reg.Kind := TypeMap;
  Reg.Lifetime := aLifetime;
  Reg.ImplClass := TImpl;
  Reg.FactoryIntf := nil;
  Reg.FactoryObj := nil;
  Reg.OwnsInstance := False;
  Reg.ServiceTypeName := TypeNameOf(TypeInfo(TService));

  fRegistry.Add(Reg);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TContainer.AddClassType<T>(aLifetime: TServiceLifetime; const aName: string);
const
  E_SINGLE = 'AddClassType<%s>: %s inherits from TSingleton and cannot be registered as Transient';
var
  Reg: TRegistration;
begin
  Ensure.IsTrue(T.InheritsFrom(TObject), 'AddClassType<T>: T must be a class')
        .IsFalse(T.InheritsFrom(TSingleton) and (aLifetime = Transient), Format(E_SINGLE, [T.ClassName, T.ClassName]));

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
procedure TContainer.AddClassType<TBase, TImpl>(aLifetime: TServiceLifetime; const aName: string);
const
  E_SINGLE = 'AddClassType<%s,%s>: %s inherits from TSingleton and cannot be registered as Transient';
var
  reg: TRegistration;
begin
  Ensure.IsFalse(TImpl.InheritsFrom(TSingleton) and (aLifetime = Transient),
    Format(E_SINGLE, [TBase.ClassName, TImpl.ClassName, TImpl.ClassName]));

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
procedure TContainer.AddModule<T>;
begin
  var module := T.Create;
  try
    module.RegisterServices(Self);
  finally
    module.Free;
  end;

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
class function TContainer.TypeNameOf(aTypeInfo: PTypeInfo): string;
begin
  if aTypeInfo = nil then exit('<nil>');
  Result := GetTypeName(aTypeInfo);
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
begin
  aCtor := nil;
  SetLength(aArgs, 0);

  Result := false;

  if aImplClass = nil then exit;

  var lType := fContext.GetType(aImplClass);
  var instanceType := lType.AsInstance;

  if instanceType = nil then exit(false);

  // -------------------------
  // Phase 1: select constructor (no resolving / no object creation)
  // -------------------------
  var bestCtor: TRttiMethod := nil;
  var bestCount: Integer := -1;

  for var m in instanceType.GetMethods do
  begin
    if not m.IsConstructor then continue;
    if m.Visibility <> mvPublic then continue;

    // Only consider constructors declared on this class (not inherited)
    if m.Parent <> instanceType then continue;

    // Only consider ctors where params are injectable and resolvable by policy
    if not AllParamsAreInjectableAndResolvable(m) then continue;

    var paramCount := Length(m.GetParameters);

    // Prefer the ctor with the most parameters
    if paramCount > bestCount then
    begin
      bestCount := paramCount;
      bestCtor := m;
    end;
  end;

  // Fallback: any public parameterless constructor (including inherited)
  if bestCtor = nil then
  begin
    for var m in instanceType.GetMethods do
    begin
      if m.IsConstructor and (m.Visibility = mvPublic) and (Length(m.GetParameters) = 0) then
      begin
        bestCtor := m;
        Break;
      end;
    end;
  end;

  if bestCtor = nil then exit(false);

  // -------------------------
  // Phase 2: resolve args only for the chosen constructor
  // -------------------------
  var params := bestCtor.GetParameters;
  SetLength(aArgs, Length(params));

  for var i := 0 to High(params) do
  begin
    var v: TValue := TValue.Empty;

    if not TryResolveParam(params[i].ParamType, v) then
    begin
      // We did not create speculative objects anymore, so nothing to dispose here.
      // If you later introduce scoped tracking, this is where you'd roll back.
      aCtor := nil;
      SetLength(aArgs, 0);
      exit(false);
    end;

    aArgs[i] := v;
  end;

  aCtor := bestCtor;
  Result := true;
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
    if fSingletons.TryGet(key, lValue) then
    begin
      if (not lValue.IsObject) and Assigned(lValue.Intf) then
      begin
        aIntf := lValue.Intf;
        Exit(true);
      end;

      if lValue.IsObject and Assigned(lValue.Obj) then
      begin
        var guid := GetTypeData(aServiceType)^.Guid;

        if Supports(lValue.Obj, guid, aIntf) and Assigned(aIntf) then
          exit(true);

        // If we cached an object but it doesn't support the interface, treat as config error.
        exit(false);
      end;
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

        if lReg.Lifetime = Singleton then
        begin
          if lObj.InheritsFrom(TSingleton) then
            // container-owned deterministic singleton
            fSingletons.PutObject(key, lObj, True)
          else
            // IMPORTANT: do not free Obj; interface ref now owns it via refcounting
            // refcount-pinned singleton (best effort)
            fSingletons.PutInterface(key, aIntf);
        end;

        exit(true);
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
  if (aServiceType = nil) or (aServiceType^.Kind <> tkClass) then exit;

  var key := TServiceKey.Create(aServiceType, '');

  // Best-effort: build a registration candidate
  var td := GetTypeData(aServiceType);
  if (td = nil) or (td.ClassType = nil) then
    Exit;

  var implClass := td.ClassType;

  // Infer lifetime from base type
  var inferredLifetime: TServiceLifetime := Transient;
  if implClass.InheritsFrom(TSingleton) then
    inferredLifetime := Singleton;

  var reg: TRegistration;
  FillChar(reg, SizeOf(reg), 0);

  reg.Key := key;
  reg.Kind := TypeMap;
  reg.Lifetime := inferredLifetime;
  reg.ImplClass := implClass;
  reg.FactoryIntf := nil;
  reg.FactoryObj := nil;
  reg.OwnsInstance := False;
  reg.ServiceTypeName := TypeNameOf(aServiceType);

  // Atomic add: if someone else registered it first, just ignore.
  fRegistry.TryAdd(reg);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TContainer.AllParamsAreInjectableAndResolvable(const aCtor: TRttiMethod): Boolean;
begin
  Result := False;

  if not Assigned(aCtor) then exit;

  var params := aCtor.GetParameters;

  for var i := 0 to High(params) do
  begin
    var paramType := params[i].ParamType;
    if paramType = nil then exit(False);

    var info := paramType.Handle;
    if info = nil then exit(False);

    case info^.Kind of

      tkInterface:
        begin
          // Interfaces must be explicitly registered.
          if not fRegistry.Contains(TServiceKey.Create(info, '')) then exit(False);
        end;

      tkClass:
        begin
          // Classes are allowed if:
          //   - already registered
          //   - OR can be auto-registered later (ClassType exists)

          if not fRegistry.Contains(TServiceKey.Create(info, '')) then
          begin
            var td := GetTypeData(info);

            if (td = nil) or (td.ClassType = nil) then
              exit(false);

            // We don't auto-register here — just confirm it *can* be.
          end;
        end;

    else
      // We do not inject value types in v1
      exit(false);
    end;
  end;

  Result := true;
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
class constructor TContainer.Create;
begin
  fContext := TRttiContext.Create;
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
