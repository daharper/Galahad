unit Base.Dynamic;

interface

uses
  System.SysUtils,
  System.Variants,
  ComObj,
  System.Generics.Collections,
  System.Generics.Defaults,
  Winapi.Windows,
  Winapi.ActiveX,
  System.RTTI;

const
  MAX_ARGS = 20;

type
  PDispIDArray     = ^TDispIDArray;
  TDispIDArray     = array [0..MAX_ARGS] of Integer;
  PPWideCharArray  = ^TPWideCharArray;
  TPWideCharArray  = array [0..MAX_ARGS] of PWideChar;
  POleVariantArray = ^TOleVariantArray;
  TOleVariantArray = array[0..MAX_ARGS] of OleVariant;
  TDynamic         = OleVariant;
  PVariantArray    = ^TVariantArray;
  TVariantArray    = array[0..MaxInt div SizeOf(Variant) - 1] of Variant;

  /// <summary>
  /// Cache for RTTI methods, properties, and indexed properties against names for faster look up,
  /// but does not cache overloaded methods, RTTI lacks information, the client has params to help
  /// </summary>
  TDynamicClassCache = class
  private
    fClass: TClass;

    fMethods: TDictionary<string, TRttiMethod>;
    fProperties: TDictionary<string, TRttiProperty>;
    fIndexedProperties: TDictionary<string, TRttiIndexedProperty>;

    procedure BuildCache;
  public
    property MetaClass: TClass read fClass;

    function TryGetMethod(const aName: string; out aMethod: TRttiMethod): boolean;
    function TryGetProperty(const aName: string; out aProperty: TRttiProperty): boolean;
    function TryGetIndexedProperty(const aName: string; out aIndexedProperty: TRttiIndexedProperty): boolean;

    constructor Create(aClass: TClass);
    destructor Destroy; override;
  end;

  /// <summary>
  /// Central cache for RTII class cache. Use this to register and request a TDynamicClassCache.
  /// </summary>
  TDynamicCache = class
  private
    fCache: TObjectDictionary<TClass, TDynamicClassCache>;
    fCacheLock: TObject;

    class var fInstance: TDynamicCache;
  public
    constructor Create;
    destructor Destroy; override;

    function GetCache(aClass: TClass): TDynamicClassCache;
    function RegisterClass(aClass: TClass): TDynamicClassCache;

    procedure RegisterClasses(aClasses: array of TClass);

    class constructor Create;
    class destructor Destroy;
  end;

  /// <summary>
  /// Helpers for dynamic behavior.
  /// </summary>
  TDynamicHelper = class
  private
    class var fContext: TRttiContext;
  public
    class function Invoke(const Obj: OleVariant; const Name: WideString; const Args: TArray<Variant>): Variant;
    class function TryInvokeOnType(aSelf: TObject; const aName: string; const aArgs: TArray<Variant>; aFlags: Word; out aReturnValue: TValue): Boolean;
    class function EffectivePropertyFlags(aFlags: Word; const aDisplayParams: TDispParams; const aArgs: TArray<Variant>): Word;
    class function DerefArg(const V:OleVariant): Variant;

    class constructor Create;
    class destructor Destroy;
  end;

  /// <summary>
  /// Inherit from this object to implement dynamic objects that first try to dispatch to static
  /// methods, if not successful, then method missing will be called.
  ///
  /// This class relies upon OleVariant dispatch, declare variables of type TDynamic accordingly.
  /// </summary>
  TDynamicObject = class(TInterfacedObject, IDispatch)
  private
    fNameToId: TDictionary<string, Integer>;
    fIdToName: TDictionary<Integer, string>;
    fNextId: Integer;

    function GetTypeInfoCount(out aCount: Integer): HResult; stdcall;
    function GetTypeInfo(aIndex, aLocaleID: Integer; out aTypeInfo): HResult; stdcall;
    function GetIDsOfNames(const aIID: TGUID; aNames: Pointer; aNameCount, aLocaleID: Integer; aDispIDs: Pointer): HResult; stdcall;
    function Invoke(aDispID: Integer; const aIID: TGUID; aLocaleID: Integer; aFlags: Word; var aParams; aVarResult, aExcepInfo, aArgErr: Pointer): HResult; stdcall;

    procedure EnsureDispMaps;
  protected
    class var fContext: TRttiContext;
  public
    function AsVariant: OleVariant;
    function MethodMissing(const aName: string; const aArgs: TArray<Variant>): Variant; virtual;

    procedure AfterConstruction; override;

    constructor Create; reintroduce;
    destructor Destroy; override;
  end;

  /// <summary>
  /// This class provides method missing functionality when invoked via an OleVariant. It does not
  /// try to resolve static type methods first like TDynamicObject. It simply provides method missing.
  /// Please see the repository class as an example implementation that uses the X method accordingly.
  /// </summary>
  /// <remarks>
  /// It's best to call "inherited Create" in child constructors, but effort has been made to initialize
  /// the dispatch maps lazily if it hasn't been done.
  /// </remarks>
  TExtendedObject = class(TInterfacedObject, IDispatch)
  private
    fNameToId: TDictionary<string, Integer>;
    fIdToName: TDictionary<Integer, string>;
    fNextId:   integer;

    function GetTypeInfoCount(out aCount: Integer): HResult; stdcall;
    function GetTypeInfo(aIndex, aLocaleID: Integer; out aTypeInfo): HResult; stdcall;
    function GetIDsOfNames(const aIID: TGUID; aNames: Pointer; aNameCount, aLocaleID: Integer; aDispIDs: Pointer): HResult; stdcall;
    function Invoke(aDispID: Integer; const aIID: TGUID; aLocaleID: Integer; aFlags: Word; var aParams; aVarResult, aExcepInfo, aArgErr: Pointer): HResult; stdcall;

    procedure EnsureDispMaps;
  protected
    class var fContext: TRttiContext;

  public
    function AsVariant: OleVariant;
    function MethodMissing(const Name: string; const Args: TArray<Variant>): Variant; virtual;

    procedure AfterConstruction; override;

    constructor Create; reintroduce;
    destructor Destroy; override;
  end;

  /// <summary>
  /// Provides the same behavior as DynamicObject except it tries to delegate to a wrapped object as well,
  /// allowing decorator like behavior in the wrapping class. Inherit from this and add decorator methods.
  /// </summary>
  TDynamicDecorator<T:class> = class(TInterfacedObject, IDispatch)
  private
    fSource: T;
    fNameToId: TDictionary<string, Integer>;
    fIdToName: TDictionary<Integer, string>;
    fNextId: Integer;

    function GetTypeInfoCount(out aCount: Integer): HResult; stdcall;
    function GetTypeInfo(aIndex, aLocaleID: Integer; out aTypeInfo): HResult; stdcall;
    function GetIDsOfNames(const aIID: TGUID; aNames: Pointer; aNameCount, aLocaleID: Integer; aDispIDs: Pointer): HResult; stdcall;
    function Invoke(aDispID: Integer; const aIID: TGUID; aLocaleID: Integer; aFlags: Word; var aParams; aVarResult, aExcepInfo, aArgErr: Pointer): HResult; stdcall;

    procedure EnsureDispMaps;
  protected
    class var fContext: TRttiContext;
  public
    property Source: T read fSource write fSource;

    function AsVariant: OleVariant;
    function MethodMissing(const aName: string; const aArgs: TArray<Variant>): Variant; virtual;
    function ReleaseSource: T;

    procedure AfterConstruction; override;

    constructor Create(aSource: T); reintroduce;
    destructor Destroy; override;

    class function New(aSource: T): OleVariant; overload; inline;
  end;

  /// <summary>
  /// Access method for the dynamic cache.
  /// </summary>
  function DynamicCache: TDynamicCache;

implementation

uses
  System.TypInfo,
  Base.Reflection;

{ Functions }

{----------------------------------------------------------------------------------------------------------------------}
function DynamicCache: TDynamicCache;
begin
  Result := TDynamicCache.fInstance;
end;

{ TDynamicObject }

{----------------------------------------------------------------------------------------------------------------------}
constructor TDynamicObject.Create;
begin
  inherited;

  EnsureDispMaps;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TDynamicObject.Destroy;
begin
  fNameToId.Free;
  fIdToName.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicObject.EnsureDispMaps;
begin
  if not Assigned(fNameToId) then
  begin
    fNameToId := TDictionary<string,Integer>.Create(TIStringComparer.Ordinal);
    fIdToName := TDictionary<Integer,string>.Create;
    fNextId   := 100;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicObject.AfterConstruction;
begin
  inherited;
  EnsureDispMaps;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicObject.AsVariant: OleVariant;
begin
  Result := IDispatch(Self);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicObject.GetTypeInfoCount(out aCount: Integer): HResult;
begin
  aCount := 0;
  Result := S_OK;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicObject.GetTypeInfo(aIndex, aLocaleID: Integer; out aTypeInfo): HResult;
begin
  Pointer(aTypeInfo) := nil;
  Result := E_NOTIMPL;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicObject.GetIDsOfNames(const aIID: TGUID; aNames: Pointer; aNameCount, aLocaleID: Integer; aDispIDs: Pointer): HResult;
var
  i: Integer;
  lTmp: PWideChar;
  lName: string;
  lDispIdArr: PDispIDArray;
begin
  EnsureDispMaps;

  Result := S_OK;
  lDispIdArr :=  PDispIDArray(aDispIDs);

  for i := 0 to aNameCount - 1 do
  begin
    lTmp := PPWideCharArray(aNames)^[i];
    lName := WideCharToString(lTmp);

    if not fNameToId.TryGetValue(lName, lDispIdArr^[i]) then
    begin
      Inc(FNextId);
      lDispIdArr^[i] := FNextId;
      fNameToId.Add(lName, lDispIdArr^[i]);
//      fNameToId.Add(lName, lDispIdArr[i]);
      fIdToName.Add(lDispIdArr[i], lName);
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicObject.Invoke(aDispID: Integer; const aIID: TGUID; aLocaleID: Integer; aFlags: Word; var aParams; aVarResult, aExcepInfo, aArgErr: Pointer): HResult;
var
  lDispParams: PDispParams;
  lVariants: POleVariantArray;
  lArgs: TArray<Variant>;
  lReturnValue: TValue;
  lVariant: Variant;
  lEffFlags: Word;
  lName: string;
begin
  EnsureDispMaps;

  lDispParams := @aParams;

  if Integer(lDispParams.cArgs) > MAX_ARGS then
    exit(DISP_E_BADPARAMCOUNT);

  lVariants := POleVariantArray(lDispParams.rgvarg);

  SetLength(lArgs, lDispParams.cArgs);

  for var i := 0 to lDispParams.cArgs - 1 do
    lArgs[i] := TDynamicHelper.DerefArg(lVariants^[lDispParams.cArgs - 1 - i]);
//    lArgs[i] := lVariants^[lDispParams.cArgs - 1 - i];

  if not fIdToName.TryGetValue(aDispID, lName) then
    lName := Format('DISPID_%d', [aDispID]);

  lEffFlags := TDynamicHelper.EffectivePropertyFlags(aFlags, lDispParams^, lArgs);

  try
    if TDynamicHelper.TryInvokeOnType(Self, lName, lArgs, lEffFlags, lReturnValue) then
    begin
      if Assigned(aVarResult) then
      begin
        if not TReflection.TryTValueToVariant(lReturnValue, lVariant) then
          lVariant := lReturnValue.ToString;

        PVariant(aVarResult)^ := lVariant;
      end;
      Exit(S_OK);
    end;

    if Assigned(aVarResult) then
      PVariant(aVarResult)^ := MethodMissing(lName, lArgs)
    else
      MethodMissing(lName, lArgs);

    Result := S_OK;
  except
    on E: Exception do
    begin
      Result := DISP_E_EXCEPTION;

      if aExcepInfo <> nil then
        with PExcepInfo(aExcepInfo)^ do
        begin
          bstrSource := SysAllocString('TDynamicObject');
          bstrDescription := SysAllocString(PWideChar(WideString(E.Message)));
          scode := E_FAIL;
        end;
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicObject.MethodMissing(const aName: string; const aArgs: TArray<Variant>): Variant;
begin
  Result := Format('[missing] %s(%d args)', [aName, Length(aArgs)]);
end;

{ TExtendedObject }

{----------------------------------------------------------------------------------------------------------------------}
constructor TExtendedObject.Create;
begin
  inherited;

  EnsureDispMaps;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TExtendedObject.Destroy;
begin
  fNameToId.Free;
  fIdToName.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TExtendedObject.EnsureDispMaps;
begin
  if not Assigned(fNameToId) then
  begin
    fNameToId := TDictionary<string,Integer>.Create(TIStringComparer.Ordinal);
    fIdToName := TDictionary<Integer,string>.Create;
    fNextId   := 100;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TExtendedObject.AfterConstruction;
begin
  inherited;

  EnsureDispMaps;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TExtendedObject.AsVariant: OleVariant;
begin
  Result := IDispatch(Self);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TExtendedObject.GetTypeInfoCount(out aCount: Integer): HResult;
begin
  aCount := 0;
  Result := S_OK;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TExtendedObject.GetTypeInfo(aIndex, aLocaleID: Integer; out aTypeInfo): HResult;
begin
  Pointer(aTypeInfo) := nil;
  Result := E_NOTIMPL;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TExtendedObject.GetIDsOfNames(const aIID: TGUID; aNames: Pointer; aNameCount, aLocaleID: Integer; aDispIDs: Pointer): HResult;
var
  i: Integer;
  W: PWideChar;
  lName: string;
  lDispIdArr: PDispIDArray;
begin
  EnsureDispMaps;

  Result := S_OK;
  lDispIdArr :=  PDispIDArray(aDispIDs);

  for i := 0 to aNameCount - 1 do
  begin
    W := PPWideCharArray(aNames)^[i];
    lName := WideCharToString(W);

    if not FNameToId.TryGetValue(lName, lDispIdArr^[i]) then
    begin
      Inc(FNextId);
      lDispIdArr^[i] := FNextId;
      fNameToId.Add(lName, lDispIdArr[i]);
      fIdToName.Add(lDispIdArr[i], lName);
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TExtendedObject.Invoke(aDispID: Integer; const aIID: TGUID; aLocaleID: Integer; aFlags: Word; var aParams; aVarResult, aExcepInfo, aArgErr: Pointer): HResult;
var
  lDispParams: PDispParams;
  lVariants: POleVariantArray;
  lArgs: TArray<Variant>;
  lName: string;
  i: Integer;
begin
  EnsureDispMaps;

  lDispParams := @aParams;

  if Integer(lDispParams.cArgs) > MAX_ARGS then
  begin
    Result := DISP_E_BADPARAMCOUNT;
    Exit;
  end;

  lVariants := POleVariantArray(lDispParams.rgvarg);

  SetLength(lArgs, lDispParams.cArgs);

  for i := 0 to lDispParams.cArgs - 1 do
    lArgs[i] := TDynamicHelper.DerefArg(lVariants^[lDispParams.cArgs - 1 - i]);
//    lArgs[i] := lVariants^[lDispParams.cArgs - 1 - i];

  if not FIdToName.TryGetValue(aDispID, lName) then
    lName := Format('DISPID_%d', [aDispID]);

  try
    if Assigned(aVarResult) then
      PVariant(aVarResult)^ := MethodMissing(lName, lArgs)
    else
      MethodMissing(lName, lArgs);

    Result := S_OK;
  except
    on E: Exception do
    begin
      Result := DISP_E_EXCEPTION;
      if aExcepInfo <> nil then
        with PExcepInfo(aExcepInfo)^ do
        begin
          bstrSource := SysAllocString('TDynamicObject');
          bstrDescription := SysAllocString(PWideChar(WideString(E.Message)));
          scode := E_FAIL;
        end;
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TExtendedObject.MethodMissing(const Name: string; const Args: TArray<Variant>): Variant;
begin
  Result := Format('[missing] %s(%d args)', [Name, Length(Args)]);
end;

{ TDynamicDecorator }

{----------------------------------------------------------------------------------------------------------------------}
constructor TDynamicDecorator<T>.Create(aSource: T);
begin
  inherited Create;

  EnsureDispMaps;

  fSource := aSource;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TDynamicDecorator<T>.Destroy;
begin
  fNameToId.Free;
  fIdToName.Free;

  if Assigned(fSource) then
    fSource.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicDecorator<T>.EnsureDispMaps;
begin
  if not Assigned(fNameToId) then
  begin
    fNameToId := TDictionary<string,Integer>.Create(TIStringComparer.Ordinal);
    fIdToName := TDictionary<Integer,string>.Create;
    fNextId   := 100;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicDecorator<T>.AfterConstruction;
begin
  inherited;
  EnsureDispMaps;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicDecorator<T>.AsVariant: OleVariant;
begin
  Result := IDispatch(Self);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicDecorator<T>.GetTypeInfoCount(out aCount: Integer): HResult;
begin
  aCount := 0;
  Result := S_OK;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicDecorator<T>.GetTypeInfo(aIndex, aLocaleID: Integer; out aTypeInfo): HResult;
begin
  Pointer(aTypeInfo) := nil;
  Result := E_NOTIMPL;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicDecorator<T>.GetIDsOfNames(const aIID: TGUID; aNames: Pointer; aNameCount, aLocaleID: Integer; aDispIDs: Pointer): HResult;
var
  i: Integer;
  lTmp: PWideChar;
  lName: string;
  lDispIdArr: PDispIDArray;
begin
  EnsureDispMaps;

  Result := S_OK;
  lDispIdArr :=  PDispIDArray(aDispIDs);

  for i := 0 to aNameCount - 1 do
  begin
    lTmp := PPWideCharArray(aNames)^[i];
    lName := WideCharToString(lTmp);

    if not FNameToId.TryGetValue(lName, lDispIdArr^[i]) then
    begin
      Inc(FNextId);
      lDispIdArr^[i] := FNextId;
      FNameToId.Add(lName, lDispIdArr[i]);
      FIdToName.Add(lDispIdArr[i], lName);
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicDecorator<T>.Invoke(aDispID: Integer; const aIID: TGUID; aLocaleID: Integer; aFlags: Word; var aParams; aVarResult, aExcepInfo, aArgErr: Pointer): HResult;
var
  lDispParams: PDispParams;
  lVariants: POleVariantArray;
  lArgs: TArray<Variant>;
  lReturnValue: TValue;
  lVariant: Variant;
  lEffFlags: Word;
  lName: string;
  i: Integer;
begin
  EnsureDispMaps;

  lDispParams := @aParams;

  if Integer(lDispParams.cArgs) > MAX_ARGS then
  begin
    Result := DISP_E_BADPARAMCOUNT;
    Exit;
  end;

  lVariants := POleVariantArray(lDispParams.rgvarg);

  SetLength(lArgs, lDispParams.cArgs);

  for i := 0 to lDispParams.cArgs - 1 do
    lArgs[i] := TDynamicHelper.DerefArg(lVariants^[lDispParams.cArgs - 1 - i]);
//    lArgs[i] := lVariants^[lDispParams.cArgs - 1 - i];

  if not FIdToName.TryGetValue(aDispID, lName) then
    lName := Format('DISPID_%d', [aDispID]);

  lEffFlags := TDynamicHelper.EffectivePropertyFlags(aFlags, lDispParams^, lArgs);

  try
    if TDynamicHelper.TryInvokeOnType(Self, lName, lArgs, lEffFlags, lReturnValue) then
    begin
      if Assigned(aVarResult) then
      begin
        if not TReflection.TryTValueToVariant(lReturnValue, lVariant) then
          lVariant := lReturnValue.ToString;

        PVariant(aVarResult)^ := lVariant;
      end;
      Exit(S_OK);
    end;

    if Assigned(fSource) then
    begin
      if TDynamicHelper.TryInvokeOnType(fSource, lName, lArgs, lEffFlags, lReturnValue) then
      begin
        if Assigned(aVarResult) then
        begin
          if not TReflection.TryTValueToVariant(lReturnValue, lVariant) then
            lVariant := lReturnValue.ToString;

          PVariant(aVarResult)^ := lVariant;
        end;
        Exit(S_OK);
      end;
    end;

    if Assigned(aVarResult) then
      PVariant(aVarResult)^ := MethodMissing(lName, lArgs)
    else
      MethodMissing(lName, lArgs);

    Result := S_OK;
  except
    on E: Exception do
    begin
      Result := DISP_E_EXCEPTION;
      if aExcepInfo <> nil then
        with PExcepInfo(aExcepInfo)^ do
        begin
          bstrSource := SysAllocString('TDynamicObject');
          bstrDescription := SysAllocString(PWideChar(WideString(E.Message)));
          scode := E_FAIL;
        end;
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicDecorator<T>.MethodMissing(const aName: string; const aArgs: TArray<Variant>): Variant;
begin
  Result := Format('[missing] %s(%d args)', [aName, Length(aArgs)]);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TDynamicDecorator<T>.New(aSource: T): OleVariant;
begin
  Result := Self.Create(aSource).AsVariant;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicDecorator<T>.ReleaseSource: T;
begin
  Result := fSource;
  fSource := nil;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TDynamicHelper.Invoke(const Obj: OleVariant; const Name: WideString; const Args: TArray<Variant>): Variant;
var
  Disp: IDispatch;
  lDispID: Integer;
  DispParams: TDispParams;
  i: Integer;
  ArgList: array of OleVariant;
begin
  Result := Null;

  if not Supports(Obj, IDispatch, Disp) then
    Exit;

  lDispID := DISPID_UNKNOWN;

  if Failed(Disp.GetIDsOfNames(GUID_NULL, @Name, 1, LOCALE_USER_DEFAULT, @lDispID)) then
    Exit;

  // Prepare arguments in reverse order (IDispatch expects them last-to-first)
  SetLength(ArgList, Length(Args));
  for i := 0 to High(Args) do
    ArgList[High(Args) - i] := Args[i];

  FillChar(DispParams, SizeOf(DispParams), 0);

  if Length(ArgList) > 0 then
  begin
    DispParams.cArgs := Length(ArgList);
    DispParams.rgvarg := @ArgList[0];
  end;

  // Let the object handle it — method, property get, property put etc.
  Disp.Invoke(lDispID, GUID_NULL, LOCALE_USER_DEFAULT,
    DISPATCH_METHOD or DISPATCH_PROPERTYGET or DISPATCH_PROPERTYPUT,
    DispParams, @Result, nil, nil);
end;

{----------------------------------------------------------------------------------------------------------------------}
class constructor TDynamicHelper.Create;
begin
  fContext := TRttiContext.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TDynamicHelper.DerefArg(const V: OleVariant): Variant;
var
  TV: TVarData absolute V;
begin
  Result := Variant(V);

  if (TV.VType and varByRef) <> 0 then
    Result := PVariant(TV.VPointer)^;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor TDynamicHelper.Destroy;
begin
  fContext.Free;
end;


{----------------------------------------------------------------------------------------------------------------------}
class function TDynamicHelper.EffectivePropertyFlags(aFlags: Word; const aDisplayParams: TDispParams; const aArgs: TArray<Variant>): Word;
var
  lLastIsRef: Boolean;
begin
  Result := aFlags;

  if (Result and (DISPATCH_PROPERTYGET or DISPATCH_PROPERTYPUT or DISPATCH_PROPERTYPUTREF)) <> 0 then Exit;

  if not((aDisplayParams.cNamedArgs = 1) and
         (aDisplayParams.rgdispidNamedArgs <> nil) and
         (PInteger(aDisplayParams.rgdispidNamedArgs)^ = DISPID_PROPERTYPUT)) then exit;

  lLastIsRef := (Length(aArgs) > 0) and ((VarType(aArgs[High(aArgs)]) and varTypeMask) in [varUnknown, varDispatch]);

  Result := Result and not DISPATCH_METHOD;

  if lLastIsRef then
    Result := Result or DISPATCH_PROPERTYPUTREF
  else
    Result := Result or DISPATCH_PROPERTYPUT;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TDynamicHelper.TryInvokeOnType(aSelf: TObject; const aName: string; const aArgs: TArray<Variant>; aFlags: Word; out aReturnValue: TValue): Boolean;
var
  lType: TRttiType;
  lProp: TRttiProperty;
  lIdxProp: TRttiIndexedProperty;
  lParams: TArray<TRttiParameter>;
  lCallArgs, IndexArgs: TArray<TValue>;
  lReturnValue: TValue;
  lIndexCount: integer;
  i: Integer;
  IsGet, IsPut, IsPutRef, IsMethod: Boolean;
  lMethod: TRttiMethod;
  lCache: TDynamicClassCache;
  lMethodFound: boolean;
  lInstance: TValue;
begin
  Result := False;
  aReturnValue := TValue.Empty;

  IsGet    := (aFlags and DISPATCH_PROPERTYGET)    <> 0;
  IsPut    := (aFlags and DISPATCH_PROPERTYPUT)    <> 0;
  IsPutRef := (aFlags and DISPATCH_PROPERTYPUTREF) <> 0;
  IsMethod := ((aFlags and DISPATCH_METHOD) <> 0) or (not (IsGet or IsPut or IsPutRef));

  LType     := fContext.GetType(aSelf.ClassType);
  lCache    := DynamicCache.GetCache(aSelf.ClassType);
  LInstance := TValue.From<TObject>(aSelf);

  { Indexed property (ask explicitly) }
    // Indexed property: if it exists, we can treat METHOD calls as GET/PUT based on arg count.
    // This is important because OleVariant often calls V.Prop(i) as DISPATCH_METHOD.
  if lCache.TryGetIndexedProperty(aName, lIdxProp) then
  begin
    // If flags indicate PUT/PUTREF, treat last arg as value.
    // Otherwise treat as GET (OleVariant often calls V.Prop(i) as DISPATCH_METHOD).
    if IsPut or IsPutRef then
    begin
      if Length(aArgs) < 1 then Exit(False);

      lIndexCount := Length(aArgs) - 1;
      SetLength(IndexArgs, lIndexCount);

      for i := 0 to lIndexCount - 1 do
        IndexArgs[i] := TValue.FromVariant(aArgs[i]);

      if not TReflection.TryVariantToTValue(aArgs[lIndexCount], lIdxProp.PropertyType.Handle, lReturnValue) then
        lReturnValue := TValue.FromVariant(aArgs[lIndexCount]);

      lIdxProp.SetValue(aSelf, IndexArgs, lReturnValue);

      aReturnValue := TValue.Empty;
      Exit(True);
    end
    else
    begin
      // Default to GET for METHOD-style invocation
      lIndexCount := Length(aArgs);
      SetLength(IndexArgs, lIndexCount);

      for i := 0 to lIndexCount - 1 do
        IndexArgs[i] := TValue.FromVariant(aArgs[i]);

      aReturnValue := lIdxProp.GetValue(aSelf, IndexArgs);
      Exit(True);
    end;
  end;

  { Non-indexed property }
  if IsGet or IsPut or IsPutRef then
  begin
    if lCache.TryGetProperty(aName, lProp) then
    begin
      if (IsGet) and (Length(aArgs) = 0) then
      begin
        if not lProp.IsReadable then Exit(False);
        aReturnValue := lProp.GetValue(aSelf);
        Exit(True);
      end;

      if not lProp.IsWritable then Exit(False);
      if Length(aArgs) <> 1 then Exit(False);

      if not TReflection.TryVariantToTValue(aArgs[0], lProp.PropertyType.Handle, lReturnValue) then
        lReturnValue := TValue.FromVariant(aArgs[0]);

      lProp.SetValue(aSelf, lReturnValue);

      aReturnValue := TValue.Empty;

      Exit(True);
    end;
  end;

  { methods: instance, strict-first overload resolution }
  if not IsMethod then Exit;

  lMethod := nil;
  lMethodFound := False;

  { Pass 1: STRICT matching (no string->numeric coercion) }
  for lMethod in LType.GetMethods do
  begin
    if not SameText(lMethod.Name, aName) then
      Continue;

    if lMethod.IsConstructor or lMethod.IsDestructor then
      Continue;

    if (lMethod.Parent is TRttiInstanceType) and
       (TRttiInstanceType(lMethod.Parent).MetaclassType = TDynamicObject) then
      Continue;

    lParams := lMethod.GetParameters;

    if TReflection.ConvertArgsForStrict(lParams, aArgs, lCallArgs) then
    begin
      lMethodFound := True;
      Break;
    end;
  end;

  { Pass 2: PERMISSIVE matching (string->numeric allowed, etc.) }
  if not lMethodFound then
  begin
    for lMethod in LType.GetMethods do
    begin
      if not SameText(lMethod.Name, aName) then
        Continue;

      if lMethod.IsConstructor or lMethod.IsDestructor then
        Continue;

      if (lMethod.Parent is TRttiInstanceType) and
         (TRttiInstanceType(lMethod.Parent).MetaclassType = TDynamicObject) then
        Continue;

      lParams := lMethod.GetParameters;

      if TReflection.ConvertArgsFor(lParams, aArgs, lCallArgs) then
      begin
        lMethodFound := True;
        Break;
      end;
    end;
  end;

  if (not lMethodFound) or (lMethod = nil) then exit;

  if not lMethod.IsClassMethod then
    aReturnValue := lMethod.Invoke(aSelf, lCallArgs)
  else
  begin
    var cls        := TRttiInstanceType(LType).MetaclassType;
    var classValue := TValue.From<TClass>(cls);
//    instanceVal := TValue.From<TClass>(TClass(aSelf.ClassType))
    aReturnValue := lMethod.Invoke(classValue, lCallArgs);
  end;

  Exit(True);
end;

{ TDynamicObjectCache }

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicClassCache.BuildCache;
var
  lContext: TRttiContext;
  lType: TRttiType;
  lMethod: TRttiMethod;
  lProperty: TRttiProperty;
  lIndexedProperty: TRttiIndexedProperty;
  lKey: string;
  lOverloads: TList<string>;
begin
  lContext   := TRttiContext.Create;
  lOverloads := TList<string>.Create;

  try
    lType := lContext.GetType(fClass);

    for lMethod in lType.GetMethods do
    begin
      if (lMethod.IsConstructor) or (lMethod.IsDestructor) then continue;

      lKey := lMethod.Name;

      if lOverloads.Contains(lKey) then continue;

      if fMethods.ContainsKey(lKey) then
      begin
        fMethods.Remove(lKey);
        lOverloads.Add(lKey);
        continue;
      end;

      fMethods.Add(lKey, lMethod);
    end;

    for lProperty in lType.GetProperties do
      fProperties.Add(lProperty.Name, lProperty);

    for lIndexedProperty in lType.GetIndexedProperties do
      fIndexedProperties.Add(lIndexedProperty.Name, lIndexedProperty);

  finally
    lOverloads.Free;
    lContext.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TDynamicClassCache.Create(aClass: TClass);
begin
  fClass             := aClass;
  fMethods           := TDictionary<string, TRttiMethod>.Create(TIStringComparer.Ordinal);
  fProperties        := TDictionary<string, TRttiProperty>.Create(TIStringComparer.Ordinal);
  fIndexedProperties := TDictionary<string, TRttiIndexedProperty>.Create(TIStringComparer.Ordinal);

  BuildCache;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TDynamicClassCache.Destroy;
begin
  fMethods.Free;
  fProperties.Free;
  fIndexedProperties.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicClassCache.TryGetIndexedProperty(const aName: string; out aIndexedProperty: TRttiIndexedProperty): boolean;
begin
  Result := fIndexedProperties.TryGetValue(aName, aIndexedProperty);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicClassCache.TryGetMethod(const aName: string; out aMethod: TRttiMethod): boolean;
begin
  Result := fMethods.TryGetValue(aName, aMethod);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicClassCache.TryGetProperty(const aName: string; out aProperty: TRttiProperty): boolean;
begin
  Result := fProperties.TryGetValue(aName, aProperty);
end;

{ TDynamicCache }

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicCache.GetCache(aClass: TClass): TDynamicClassCache;
begin
  if not fCache.TryGetValue(aClass, Result) then
    Result := RegisterClass(aClass);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDynamicCache.RegisterClass(aClass: TClass): TDynamicClassCache;
begin
  Assert(fCache.ContainsKey(aClass) = false, aClass.ClassName + ' has already been registered error.');

  TMonitor.Enter(fCacheLock);
  try
    if not fCache.TryGetValue(aClass, Result) then
    begin
      Result := TDynamicClassCache.Create(aClass);
      fCache.Add(aClass, Result);
    end;
  finally
    TMonitor.Exit(fCacheLock);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicCache.RegisterClasses(aClasses: array of TClass);
var
  lClass: TClass;
begin
  TMonitor.Enter(fCacheLock);
  try
    for lClass in aClasses do
      RegisterClass(lClass);
  finally
    TMonitor.Exit(fCacheLock);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TDynamicCache.Create;
begin
  fCache := TObjectDictionary<TClass, TDynamicClassCache>.Create([doOwnsValues]);
  fCacheLock := TObject.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TDynamicCache.Destroy;
begin
  fCache.Free;
  fCacheLock.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
class constructor TDynamicCache.Create;
begin
  fInstance := TDynamicCache.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor TDynamicCache.Destroy;
begin
  FreeAndNil(fInstance);
end;

end.

