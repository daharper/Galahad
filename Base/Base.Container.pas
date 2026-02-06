{***************************************************************************************************
  Project:     Galahad
  Author:      David Harper
  Unit:        Base.Container
  Purpose:     Provides a dependency injection container.
***************************************************************************************************}

unit Base.Container;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.TypInfo,
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
  ///  Thread-safe cache of singleton instances (interface + object).
  ///  Stores instances by service key (type + name).
  /// </summary>
  TSingletonValue = record
    IsObject: Boolean;
    OwnsObject: Boolean;
    Intf: IInterface;
    Obj: TObject;
  end;

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

type
  TContainer = class
  private
    fRegistry: TServiceRegistry;
    fSingletons: TSingletonRegistry;

    class function TypeNameOf(aTypeInfo: PTypeInfo): string; static;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///  Registers an interface instance as a singleton service.
    ///  The container holds a reference to the interface and will release it when the container is destroyed or cleared.
    /// </summary>
    /// <remarks>
    ///  The service is keyed by (TypeInfo(T), aName). An empty name means the default registration.
    ///  Raises EArgumentException if an identical key is already registered (via Ensure).
    /// </remarks>
    procedure Add<T: IInterface>(const aInstance: T; const aName: string = ''); overload;

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
    procedure AddType<TService: IInterface; TImpl: class>(aLifetime: TServiceLifetime; const aName: string = '');

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
    procedure AddClassType<T: class>(aLifetime: TServiceLifetime; const aName: string = '');

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

    /// <summary>
    ///  Resolves an interface service by type and optional name, raising on failure.
    /// </summary>
    /// <remarks>
    ///  Raises EArgumentException if the service is not registered or cannot be resolved.
    ///  Use TryResolve for non-throwing behavior.
    /// </remarks>
    function Resolve<T: IInterface>(const aName: string = ''): T;

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
  end;

implementation

uses
 System.StrUtils;

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
procedure TContainer.Add<T>(const aInstance: T; const aName: string);
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
  lReg: TRegistration;
  lValue: TSingletonValue;
begin
  Result   := false;
  aService := Default(T);

  var key := TServiceKey.Create(TypeInfo(T), aName);

  // todo - use a locator
  if not fRegistry.TryGet(key, lReg) then exit;

  // if instance registration, it must already be in singleton cache.
  if lReg.Kind = Instance then
  begin
    if fSingletons.TryGet(key, lValue) and (not lValue.IsObject) and Assigned(lValue.Intf) then
    begin
      aService := T(lValue.Intf);
      exit(true);
    end;

    exit(false);
  end;

  // factory registration
  if lReg.Kind = Factory then
  begin
    // singleton: return cached if present
    if lReg.Lifetime = Singleton then
    begin
      if fSingletons.TryGet(key, lValue) and (not lValue.IsObject) and Assigned(lValue.Intf) then
      begin
        aService := T(lValue.Intf);
        exit(true);
      end;

      // create and cache
      Ensure.IsAssigned(@lReg.FactoryIntf, 'TryResolve<T>: missing interface factory');

      var created := lReg.FactoryIntf();

      // factory may legally return nil; treat as failure
      if not Assigned(created) then exit(false);

      fSingletons.PutInterface(key, created);
      aService := T(Created);

      exit(true);
    end;

    // Transient: always create
    Ensure.IsAssigned(@lReg.FactoryIntf, 'TryResolve<T>: missing interface factory');

    var created := lReg.FactoryIntf();

    if not Assigned(created) then exit(false);

    aService := T(Created);
    exit(true);
  end;

  // todo - TypeMap/Activator not supported yet
  Exit(false);
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
  lReg: TRegistration;
  lValue: TSingletonValue;
begin
  aInstance := default(T);

  var key := TServiceKey.Create(TypeInfo(T), aName);

  if not fRegistry.TryGet(key, lReg) then exit(False);

  // Instance registration => should already be in singleton cache
  if lReg.Kind = Instance then
  begin
    if fSingletons.TryGet(key, lValue) and lValue.IsObject and Assigned(lValue.Obj) then
    begin
      if lValue.Obj is T then
      begin
        aInstance := T(lValue.Obj);
        exit(true);
      end;
    end;

    exit(false);
  end;

  // Factory registration
  if lReg.Kind = Factory then
  begin
    Ensure.IsAssigned(@lReg.FactoryObj, 'TryResolveClass<T>: missing object factory');

    if lReg.Lifetime = Singleton then
    begin
      // return cached singleton if present
      if fSingletons.TryGet(key, lValue) and lValue.IsObject and Assigned(lValue.Obj) then
      begin
        if lValue.Obj is T then
        begin
          aInstance := T(lValue.Obj);
          exit(true);
        end;

        exit(false);
      end;

      // create, cache, container owns
      var obj := lReg.FactoryObj();

      if not Assigned(obj) then exit(false);

      if not (obj is T) then
      begin
        obj.Free; // created but wrong type
        exit(false);
      end;

      fSingletons.PutObject(key, obj, true);
      aInstance := T(obj);

      exit(true);
    end;

    // transient: create and return; caller owns
    var obj := lReg.FactoryObj();

    if not Assigned(obj) then exit(false);

    if not (obj is T) then
    begin
      obj.Free;
      exit(false);
    end;

    aInstance := T(obj);
    exit(true);
  end;

  // TypeMap/Activator not supported yet
  exit(false);
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
procedure TContainer.AddType<TService, TImpl>(aLifetime: TServiceLifetime; const aName: string);
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

end.
