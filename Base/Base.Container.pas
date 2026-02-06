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
    /// Registers an interface instance as a singleton service.
    /// The container holds a reference to the interface and will release it when the container is destroyed or cleared.
    /// </summary>
    /// <remarks>
    /// The service is keyed by (TypeInfo(T), aName). An empty name means the default registration.
    /// Raises EArgumentException if an identical key is already registered (via Ensure).
    /// </remarks>
    procedure Add<T: IInterface>(const aInstance: T; const aName: string = ''); overload;

    /// <summary>
    /// Registers a class instance as a singleton service.
    /// </summary>
    /// <param name="aTakeOwnership">
    /// If True, the container owns the instance and will Free it when the container is destroyed or cleared.
    /// If False, the caller retains ownership and must free the instance (the container will not).
    /// </param>
    /// <remarks>
    /// The service is keyed by (TypeInfo(T), aName). An empty name means the default registration.
    /// Raises EArgumentException if an identical key is already registered (via Ensure).
    /// </remarks>
    procedure AddClass<T: class>(aInstance: T; const aName: string = ''; aTakeOwnership: Boolean = True); overload;

    /// <summary>
    /// Registers an interface factory for the given lifetime.
    /// </summary>
    /// <remarks>
    /// For Singleton, the factory will be invoked at most once per key and the resulting interface is cached.
    /// For Transient, the factory is invoked on each resolution.
    ///
    /// The service is keyed by (TypeInfo(T), aName). An empty name means the default registration.
    /// Raises EArgumentException if an identical key is already registered (via Ensure).
    /// </remarks>
    procedure Add<T: IInterface>(aLifetime: TServiceLifetime; const aFactory:TConstFunc<T>; const aName: string = ''); overload;

    /// <summary>
    /// Registers a class factory for the given lifetime.
    /// </summary>
    /// <remarks>
    /// For Singleton, the factory will be invoked at most once per key and the resulting object is cached.
    /// If the container creates the singleton via this factory, it owns that cached instance and will Free it
    /// when the container is destroyed or cleared.
    ///
    /// For Transient, the factory is invoked on each resolution and the caller owns the returned object and must Free it
    /// (until scoped disposal/tracking is introduced).
    ///
    /// The service is keyed by (TypeInfo(T), aName). An empty name means the default registration.
    /// Raises EArgumentException if an identical key is already registered (via Ensure).
    /// </remarks>
    procedure AddClass<T: class>(aLifetime: TServiceLifetime; const aFactory: TConstFunc<T>; const aName: string = ''); overload;

    /// <summary>
    /// Returns True if a service with the given type (and optional name) is registered.
    /// </summary>
    function IsRegistered<T>(const aName: string = ''): Boolean;

    /// <summary>
    /// Clears all registrations and cached singleton instances.
    /// </summary>
    /// <remarks>
    /// Releases cached interface singletons and frees any owned object singletons.
    /// </remarks>
    procedure Clear;

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
