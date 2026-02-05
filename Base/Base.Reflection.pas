{***************************************************************************************************
  Project:     Galahad
  Author:      David Harper
  Unit:        Base.Reflection
  Purpose:     Provides RTTI and Variant/TValue conversion helpers for building safe,
               deterministic automation and dynamic-dispatch boundaries.

  Design contract:
  - Objects cross the boundary as interfaces (IUnknown / IDispatch).
  - Values cross the boundary as Variant-compatible value types.
  - Conversions are explicit, lossless, and predictable.
  - Unsupported conversions fail cleanly (return False), never partially succeed.

  This unit intentionally restricts the set of supported types in order to:
  - maintain binary compatibility with COM / Automation
  - avoid ambiguous overload resolution
  - prevent lifetime and ownership bugs
  - enable round-trip safety (TValue -> Variant -> TValue)

  Primary responsibilities:
  - Type inspection helpers (kind, managed-ness, reference semantics)
  - Interface safety checks and casting helpers
  - Deterministic TValue <-> Variant conversions
  - Argument marshaling for RTTI method invocation

  Non-goals:
  - Arbitrary object serialization
  - Automatic record marshaling (except special-cased TGUID)
  - Deep graph copying or persistence

  All conversion APIs are designed to be:
  - symmetric where possible
  - explicit in failure
  - suitable for use in dynamic / scripting / automation scenarios

  Supported TValue <-> Variant conversions

  Scalars
  -------
  Delphi Type                    Variant Representation
  -----------------------------  -----------------------------------------
  Integer / Int64                varInt64
  Boolean                        varBoolean
  Enum                           varInt64 (ordinal)
  Set                            varInt64 (bitmask)
  Char / WideChar                UnicodeString (length = 1)
  ShortString                    UnicodeString
  AnsiString                     UnicodeString
  WideString                     UnicodeString
  UnicodeString                  UnicodeString
  Double / Extended              varDouble
  Currency                       varCurrency
  TDateTime                      varDate
  Variant                        Variant (passthrough)

  Interfaces / Objects
  --------------------
  Delphi Type                    Variant Representation
  -----------------------------  -----------------------------------------
  Interface                      varUnknown / varDispatch
  nil interface                  Null / Empty
  TObject                        NOT supported (must cross as interface)

  Arrays
  ------
  Delphi Type                    Variant Representation
  -----------------------------  -----------------------------------------
  TArray<Integer>                1D Variant array (varVariant)
  TArray<Byte> / TBytes          varByte SAFEARRAY
  TArray<TGUID>                  1D Variant array of GUID strings
  TArray<IInterface>             1D Variant array (varUnknown elements)

  Records
  -------
  Delphi Type                    Variant Representation
  -----------------------------  -----------------------------------------
  TGUID                          String "{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}{"

  Unsupported
  -----------
  - Arbitrary records
  - Classes (except via interface)
  - Multidimensional arrays
  - Open arrays
  - Sets larger than 64 bits

  Policy notes:
  - All array conversions are 1D only.
  - All numeric conversions are explicit and range-safe.
  - String-to-numeric coercion is allowed where unambiguous.

  Support for marshaling other types should materialize in later versions.

***************************************************************************************************}

unit Base.Reflection;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Variants;

type
  /// <summary>
  ///  Reflection and interop helpers for safely bridging Delphi types with RTTI,
  ///  Variant, and Automation (IDispatch) boundaries.
  ///
  ///  Design principles:
  ///    - Objects cross the boundary as interfaces (IUnknown / IDispatch).
  ///    - Values cross the boundary as values (Variant-compatible representations).
  ///    - Only a well-defined, Automation-safe subset of types is supported.
  ///    - Unsupported kinds fail deterministically (return False or raise).
  ///
  ///  This unit is intended for:
  ///    - RTTI-based invocation
  ///    - Automation / OleVariant dispatch
  ///    - Dynamic method interception (method-missing patterns)
  ///    - Script- or plugin-facing APIs
  ///
  ///  The conversion rules enforced here mirror COM/Automation constraints,
  ///  ensuring binary compatibility and predictable lifetime semantics.
  ///
  /// </summary>
  TReflection = record
  public
    // -------------------------------------------------------------------------
    // Basic type-kind classification helpers
    // -------------------------------------------------------------------------

    /// <summary>Returns True if T is an interface type (tkInterface).</summary>
    class function IsInterface<T>: Boolean; static; inline;

    /// <summary>Returns True if T is a class type (tkClass).</summary>
    class function IsClass<T>: Boolean; static; inline;

    /// <summary>Returns True if T is a record type (tkRecord).</summary>
    class function IsRecord<T>: Boolean; static; inline;

    /// <summary>Returns True if T is a class reference (metaclass).</summary>
    class function IsClassRef<T>: Boolean; static; inline;

    /// <summary>
    ///  Returns True if T is an ordinal type: integers, int64, chars, enums, or sets.
    /// </summary>
    class function IsOrdinal<T>: Boolean; static; inline;

    /// <summary>Returns True if T is a floating-point or currency type.</summary>
    class function IsFloat<T>: Boolean; static; inline;

    /// <summary>
    ///  Returns True if T is a string type (ShortString, AnsiString, WideString, UnicodeString).
    /// </summary>
    class function IsString<T>: Boolean; static; inline;

    /// <summary>Returns True if T is a static (fixed-length) array.</summary>
    class function IsArray<T>: Boolean; static; inline;

    /// <summary>Returns True if T is a dynamic array (TArray&lt;T&gt;).</summary>
    class function IsDynArray<T>: Boolean; static; inline;

    /// <summary>Returns True if T is a method pointer (of object).</summary>
    class function IsMethod<T>: Boolean; static; inline;

    /// <summary>Returns True if T is a raw pointer type.</summary>
    class function IsPointer<T>: Boolean; static; inline;

    /// <summary>Returns True if T is a Variant.</summary>
    class function IsVariant<T>: Boolean; static; inline;

    /// <summary>
    ///  Returns True if T is a primitive, trivially representable value
    ///  suitable for simple Variant transport.
    /// </summary>
    class function IsPrimitive<T>: Boolean; static; inline;

    // -------------------------------------------------------------------------
    // Managed / lifetime semantics
    // -------------------------------------------------------------------------

    /// <summary>
    ///  Returns True if T is a compiler-managed type (reference-counted or requires finalization).
    /// </summary>
    class function IsManaged<T>: Boolean; static; inline;

    /// <summary>
    ///  Returns True if values of type T do not imply ownership
    ///  and are safe to pass without transfer-of-ownership semantics.
    /// </summary>
    class function IsNonOwningSafe<T>: Boolean; static; inline;

    /// <summary>
    ///  Returns True if values of type T require finalization when leaving scope.
    /// </summary>
    class function NeedsFinalization<T>: Boolean; static; inline;

    /// <summary>
    ///  Returns True if values of type T are reference-counted (interfaces, strings, dynamic arrays).
    /// </summary>
    class function IsReferenceCounted<T>: Boolean; static; inline;

    /// <summary>
    ///  Returns True if values of type T are trivially copyable
    ///  (safe for Move/memcpy and no finalization required).
    /// </summary>
    class function IsTriviallyCopyable<T>: Boolean; static; inline;

    // -------------------------------------------------------------------------
    // Array metadata
    // -------------------------------------------------------------------------

    /// <summary>
    ///  Returns the PTypeInfo of the element type of an array or dynamic array.
    ///  Returns nil if T is not an array type.
    /// </summary>
    class function ElementTypeInfo<T>: PTypeInfo; static;

    /// <summary>
    ///  Returns the type name of the element type of an array or dynamic array.
    ///  Returns an empty string if T is not an array type.
    /// </summary>
    class function ElementTypeName<T>: string; static;

    // -------------------------------------------------------------------------
    // Type metadata and naming
    // -------------------------------------------------------------------------

    /// <summary>Returns the RTTI kind (TTypeKind) of T.</summary>
    class function KindOf<T>: TTypeKind; static; inline;

    /// <summary>Returns the PTypeInfo for T.</summary>
    class function TypeInfoOf<T>: PTypeInfo; static; inline;

    /// <summary>Returns the short (unqualified) type name of T.</summary>
    class function TypeNameOf<T>: string; static; inline;

    /// <summary>
    /// Returns the fully qualified type name of T (Unit.Type),
    /// where applicable.
    /// </summary>
    class function FullNameOf<T>: string; static; inline;

    // -------------------------------------------------------------------------
    // Utility helpers
    // -------------------------------------------------------------------------

    /// <summary>Returns the default (zero-initialized) value of T.</summary>
    class function DefaultOf<T>: T; static; inline;

    /// <summary>
    /// Returns the interface GUID for T. T must be an interface type.
    /// </summary>
    class function InterfaceGuidOf<T>: TGUID; static; inline;

    /// <summary>
    /// Raises in debug builds if T is not an interface type.
    /// Used to enforce interface-only object boundaries.
    /// </summary>
    class procedure RequireInterfaceType<T>; static; inline;

    /// <summary>
    /// Casts an object reference to interface T, raising if unsupported.
    /// </summary>
    class function &As<T>(const aSource: TObject): T; overload; static; inline;

    /// <summary>
    /// Casts an interface reference to interface T, raising if unsupported.
    /// </summary>
    class function &As<T>(const aSource: IInterface): T; overload; static; inline;

    /// <summary>
    /// Returns True if the object implements interface T.
    /// </summary>
    class function Implements<T>(const aSource: TObject): Boolean; overload; static; inline;

    /// <summary>
    /// Returns True if the object implements interface T and outputs the cast.
    /// </summary>
    class function Implements<T>(const aSource: TObject; out aTarget: T): Boolean; overload; static; inline;

    /// <summary>
    /// Returns True if the interface implements interface T.
    /// </summary>
    class function Implements<T>(const aSource: IInterface): Boolean; overload; static; inline;

    /// <summary>
    /// Returns True if the interface implements interface T and outputs the cast.
    /// </summary>
    class function Implements<T>(const aSource: IInterface; out aTarget: T): Boolean; overload; static; inline;

    /// <summary>
    ///  Sets aGuid to the Interface GUID of the specified T if found, otherwise to an empty good.
    ///  Returns true if found, otherwise false.
    /// </summary>
    class function TryGetInterfaceGuid<T>(out aGuid: TGUID): Boolean; static;

    // -------------------------------------------------------------------------
    // Variant / TValue interop
    // -------------------------------------------------------------------------

    /// <summary>
    ///  Attempts to convert a TValue into a Variant using a lossless,
    ///  Automation-compatible representation.
    ///
    ///  Returns False if the TValue kind is not supported by the interop contract.
    /// </summary>
    class function TryTValueToVariant(
      const aValue: TValue;
      out aOutVar: Variant
    ): Boolean; static;

    /// <summary>
    ///  Attempts to convert a Variant into a TValue of the exact destination type.
    ///
    ///  Returns False if the Variant cannot be represented as the destination type
    ///  under the supported interop rules.
    /// </summary>
    class function TryVariantToTValue(
      const aVar: Variant;
      aDestType: PTypeInfo;
      out aOutValue: TValue
    ): Boolean; overload; static;

    /// <summary>
    ///  Convenience overload accepting a TRttiType as the destination.
    /// </summary>
    class function TryVariantToTValue(
      const aVar: Variant;
      const aDestRttiType: TRttiType;
      out aOutValue: TValue
    ): Boolean; overload; static;

    class function TryVariantToTValueStrict(
      const aVar: Variant;
      aDestType: PTypeInfo;
      out aOutValue: TValue): Boolean; static;

    /// <summary>
    ///  Converts an array of Variant arguments into TValue call arguments
    ///  suitable for invoking an RTTI-described method.
    ///
    ///  Parameter counts and types must match exactly; var/out parameters
    ///  are currently rejected.
    /// </summary>
    class function ConvertArgsFor(
      const aParams: TArray<TRttiParameter>;
      const aInArgs: TArray<Variant>;
      out aCallArgs: TArray<TValue>
    ): Boolean; static;

    class function ConvertArgsForStrict(
      const aParams: TArray<TRttiParameter>;
      const aInArgs: TArray<Variant>;
      out aCallArgs: TArray<TValue>
    ): Boolean; static;
  end;

const
  AnEmptyGuid: TGUID = '{00000000-0000-0000-0000-000000000000}';

implementation

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.TypeInfoOf<T>: PTypeInfo;
begin
  Result := System.TypeInfo(T);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.TypeNameOf<T>: string;
begin
  Result := GetTypeName(TypeInfoOf<T>);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.KindOf<T>: TTypeKind;
begin
  Result := TypeInfoOf<T>.Kind;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsInterface<T>: Boolean;
begin
  Result := KindOf<T> = tkInterface;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsClass<T>: Boolean;
begin
  Result := KindOf<T> = tkClass;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsClassRef<T>: Boolean;
begin
  Result := KindOf<T> = tkClassRef;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsRecord<T>: Boolean;
begin
  Result := KindOf<T> = tkRecord;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsOrdinal<T>: Boolean;
begin
  Result := KindOf<T> in [tkInteger, tkInt64, tkChar, tkWChar, tkEnumeration, tkSet];
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsFloat<T>: Boolean;
begin
  Result := KindOf<T> = tkFloat;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsString<T>: Boolean;
begin
  Result := KindOf<T> in [tkString, tkLString, tkWString, tkUString];
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsArray<T>: Boolean;
begin
  Result := KindOf<T> = tkArray;    // static (fixed-length) array
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsDynArray<T>: Boolean;
begin
  Result := KindOf<T> = tkDynArray;  // dynamic array
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsMethod<T>: Boolean;
begin
  Result := KindOf<T> = tkMethod;    // method pointers (of object)
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsPointer<T>: Boolean;
begin
  Result := KindOf<T> = tkPointer;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsVariant<T>: Boolean;
begin
  Result := KindOf<T> = tkVariant;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsPrimitive<T>: Boolean;
begin
  case PTypeInfo(TypeInfo(T)).Kind of
    tkInteger, tkInt64, tkEnumeration, tkSet,
    tkChar, tkWChar,
    tkFloat,
    tkPointer,
    tkString:
      Result := True;
  else
      Result := False;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsManaged<T>: Boolean;
begin
  // Prefer the RTL’s own test when available (it also detects records with managed fields)
 {$IF DECLARED(System.Rtti.IsManaged)}
  Result := IsManagedType(T); // System.Rtti.IsManaged(TypeInfoOf<T>);
  {$ELSE}
  // Fallback: shallow kind-based check (does NOT catch records with managed fields)
  Result := KindOf<T> in [tkInterface, tkDynArray, tkUString, tkLString, tkWString, tkVariant];
  {$IFEND}
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsNonOwningSafe<T>: Boolean;
begin
  case PTypeInfo(TypeInfo(T)).Kind of
    tkClass,   // TObject refs (need .Free if owned)
    tkPointer: // raw pointers (need Dispose/FreeMem if owned)
      Result := False;
  else
      Result := True;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.TryGetInterfaceGuid<T>(out aGuid: TGUID): Boolean;
var
  lInfo: PTypeInfo;
  lData: PTypeData;
begin
  lInfo := TypeInfoOf<T>;

  if (lInfo <> nil) and (lInfo.Kind = tkInterface) then
  begin
    lData := GetTypeData(lInfo);
    aGuid := lData.Guid;
    Result := not IsEqualGUID(aGuid, AnEmptyGuid);
  end
  else
  begin
    aGuid := AnEmptyGuid;
    Result := False;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.NeedsFinalization<T>: Boolean;
begin
  Result := IsManaged<T>;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsReferenceCounted<T>: Boolean;
begin
  case KindOf<T> of
    tkInterface, tkDynArray, tkLString, tkWString, tkUString:
      Result := True;
  else
      Result := False;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.IsTriviallyCopyable<T>: Boolean;
begin
  // Safe for Move/memcpy and no Finalize needed
  Result := not IsManaged<T>;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.ElementTypeInfo<T>: PTypeInfo;
var
  lInfo: PTypeInfo;
  lData: PTypeData;
begin
  Result := nil;

  lInfo := TypeInfoOf<T>;
  if lInfo = nil then Exit;

  lData := GetTypeData(lInfo);

  case lInfo.Kind of
    tkArray:
      // Static/fixed array: PTypeData.ArrayData.ElType
      {$IFDEF NEXTGEN}
        // NEXTGEN kept the same fields for tkArray
        Result := TD.ArrayData.ElType^;
      {$ELSE}
        Result := lData.ArrayData.ElType^;
      {$ENDIF}
    tkDynArray:
      // Dynamic array: PTypeData.DynArrElType^
      Result := lData.DynArrElType^;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.ElementTypeName<T>: string;
var
  lInfo: PTypeInfo;
begin
  lInfo := ElementTypeInfo<T>;

  if lInfo <> nil then
    Result := GetTypeName(lInfo)
  else
    Result := '';
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.DefaultOf<T>: T;
begin
  Result := Default(T);
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TReflection.RequireInterfaceType<T>;
begin
{$IFDEF DEBUG}
  if PTypeInfo(TypeInfo(T)).Kind <> tkInterface then
    raise EInvalidCast.CreateFmt('Implements<%s>: T must be an interface type', [GetTypeName(TypeInfo(T))]);
{$ENDIF}
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.InterfaceGuidOf<T>: TGUID;
begin
  Result := GetTypeData(TypeInfo(T))^.Guid;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.&As<T>(const aSource: TObject): T;
begin
  RequireInterfaceType<T>;

  if not Supports(aSource, InterfaceGuidOf<T>, Result) then
    raise EInvalidCast.CreateFmt('%s does not implement %s', [aSource.ClassName, GetTypeName(TypeInfo(T))]);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.&As<T>(const aSource: IInterface): T;
begin
  RequireInterfaceType<T>;

  if not Supports(aSource, InterfaceGuidOf<T>, Result) then
    raise EIntfCastError.CreateFmt('Interface does not support %s', [GetTypeName(TypeInfo(T))]);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.Implements<T>(const aSource: TObject): Boolean;
begin
  RequireInterfaceType<T>;
  Result := Supports(aSource, InterfaceGuidOf<T>);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.Implements<T>(const aSource: TObject; out aTarget: T): Boolean;
begin
  RequireInterfaceType<T>;
  Result := Supports(aSource, InterfaceGuidOf<T>, aTarget);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.Implements<T>(const aSource: IInterface): Boolean;
begin
  RequireInterfaceType<T>;
  Result := Supports(aSource, InterfaceGuidOf<T>);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.Implements<T>(const aSource: IInterface; out aTarget: T): Boolean;
begin
  RequireInterfaceType<T>;
  Result := Supports(aSource, InterfaceGuidOf<T>, aTarget);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.FullNameOf<T>: string;
var
  Ctx: TRttiContext;
  RttiType: TRttiType;
begin
  Ctx := TRttiContext.Create;
  try
    RttiType := Ctx.GetType(TypeInfo(T));
    if RttiType <> nil then
      Exit(RttiType.QualifiedName);

    Result := GetTypeName(TypeInfo(T));
  finally
    Ctx.Free;
  end;
end;


{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.TryTValueToVariant(const aValue: TValue; out aOutVar: Variant): Boolean;
var
  TI: PTypeInfo;
  I: Integer;
  Len: Integer;
  El: TValue;
  VEl: Variant;
  Obj: TObject;
  Data: PTypeData;
  ElType: PTypeInfo;
  disp: IDispatch;
  unk: IInterface;
begin
  // Special-case records we know how to represent
  if (aValue.Kind = tkRecord) and (aValue.TypeInfo = TypeInfo(TGUID)) then
  begin
    aOutVar := GUIDToString(aValue.AsType<TGUID>);
    Exit(True);
  end;

  // Special-case dynamic array of Byte -> Variant byte array
  if (aValue.Kind = tkDynArray) and (aValue.TypeInfo <> nil) then
  begin
    var PTData: PTypeData := GetTypeData(aValue.TypeInfo);
    if (PTData <> nil) and (PTData.DynArrElType <> nil) and (PTData.DynArrElType^ = TypeInfo(Byte)) then
    begin
      Len := aValue.GetArrayLength;

      if Len = 0 then
      begin
        // Represent empty bytes as an empty varByte array
        aOutVar := VarArrayCreate([0, -1], varByte); // some RTLs accept this, some don't
        // safer portable approach:
        aOutVar := VarArrayCreate([0, 0], varByte);
        VarArrayRedim(aOutVar, -1); // makes it empty
        Exit(True);
      end;

      aOutVar := VarArrayCreate([0, Len - 1], varByte);

      for i := 0 to Len - 1 do
        aOutVar[i] := aValue.GetArrayElement(i).AsType<Byte>;

      Exit(True);
    end;
  end;

  Result := True;
  TI := aValue.TypeInfo;

  case aValue.Kind of
    tkVariant:
      aOutVar := aValue.AsVariant;

    tkUString, tkWString, tkLString, tkString:
      aOutVar := aValue.ToString;

    tkChar:
      aOutVar := string(aValue.AsType<Char>);
    tkWChar:
      aOutVar := string(aValue.AsType<WideChar>);

    tkInteger, tkInt64:
      aOutVar := aValue.AsInt64;

    tkEnumeration:
      if TI = TypeInfo(Boolean) then
        aOutVar := aValue.AsBoolean
      else
        aOutVar := aValue.AsOrdinal;

    tkSet:
      begin
        var SetData: PTypeData := GetTypeData(aValue.TypeInfo);
        if (SetData = nil) or (SetData.CompType = nil) or (SetData.CompType^ = nil) then
          Exit(False);

        // Element (base) type of the set (typically an enum)
        var ElemInfo: PTypeInfo := SetData.CompType^;
        var ElemData: PTypeData := GetTypeData(ElemInfo);
        if ElemData = nil then
          Exit(False);

        var BitCount := ElemData.MaxValue - ElemData.MinValue + 1;
        if BitCount <= 0 then
          Exit(False);

        var ByteCount := (BitCount + 7) div 8;

        // Int64 mask contract: only sets that fit in 64 bits
        if ByteCount > SizeOf(Int64) then
          Exit(False);

        var Mask: Int64 := 0;
        Move(aValue.GetReferenceToRawData^, Mask, ByteCount);

        aOutVar := Mask; // varInt64
        Exit(True);
      end;

    tkFloat:
      begin
        if TI = TypeInfo(TDateTime) then
          aOutVar := VarFromDateTime(aValue.AsType<TDateTime>)
        else if TI = TypeInfo(Currency) then
          aOutVar := VarAsType(aValue.AsExtended, varCurrency)
        else
          aOutVar := aValue.AsExtended;
      end;

    tkInterface:
      begin
        if Supports(aValue.AsInterface, IDispatch) then
          aOutVar := IDispatch(aValue.AsInterface)
        else
          aOutVar := IUnknown(aValue.AsInterface);
      end;

    tkClass:
      begin
        Obj := aValue.AsObject;

        if Obj = nil then
          aOutVar := Null
        else if Supports(Obj, IDispatch, disp) then
          aOutVar := disp                           // varDispatch
        else if Supports(Obj, IInterface, unk) then
          aOutVar := IUnknown(unk)                  // varUnknown
        else
          Exit(False);
      end;

    tkDynArray:
      begin
        Data := GetTypeData(aValue.TypeInfo);

        if (Data = nil) or (Data.DynArrElType = nil) then
          Exit(False);

        ElType := Data.DynArrElType^;

        if ElType = nil then exit(False);

        Len := aValue.GetArrayLength;
        aOutVar := VarArrayCreate([0, Len - 1], varVariant);

        for i := 0 to Len - 1 do
        begin
          El := aValue.GetArrayElement(I);

          if not TryTValueToVariant(El, VEl) then
            Exit(False);

          aOutVar[I] := VEl;
        end;
      end;

  else
    Result := False;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.TryVariantToTValue(const aVar: Variant; aDestType: PTypeInfo; out aOutValue: TValue): Boolean;
var
  kind: TTypeKind;
  s: string;
  ord: Int64;
  w: WideString;
  u: UnicodeString;
  a: AnsiString;
  ss: ShortString;
  dt: TDateTime;
  cur: Currency;
  isBool: Boolean;
  intfType: TRttiInterfaceType;
  anyIntf: IInterface;
  lDestData: PTypeData;
  lElType: PTypeInfo;
  lLow, lHigh, Len, i: Integer;
  lElTV: TValue;
  lArr: TValue;
  obj: TObject;
begin
  Result := False;
  if aDestType = nil then
    Exit;

  kind := aDestType^.Kind;

  try
    case kind of
      { strings }
      tkUString:
        begin
          u := VarToStr(aVar);
          aOutValue := TValue.From<UnicodeString>(u);
          Exit(True);
        end;

      tkWString:
        begin
          w := VarToWideStr(aVar);
          aOutValue := TValue.From<WideString>(w);
          Exit(True);
        end;

      tkLString:
        begin
          a := AnsiString(VarToStr(aVar));
          aOutValue := TValue.From<AnsiString>(a);
          Exit(True);
        end;

      tkString:
        begin
          s := VarToStr(aVar);
          ss := ShortString(s);
          aOutValue := TValue.From<ShortString>(ss);
          Exit(True);
        end;

      { chars }
      tkChar:
        begin
          s := VarToStr(aVar);
          if s = '' then s := #0;
          aOutValue := TValue.From<Char>(s[1]);
          Exit(True);
        end;

      tkWChar:
        begin
          s := VarToStr(aVar);
          if s = '' then s := #0;
          aOutValue := TValue.From<WideChar>(WideChar(s[1]));
          Exit(True);
        end;

      { integers / enums }
      tkInteger, tkInt64:
        begin
          if VarIsStr(aVar) then
          begin
            var tmp: Int64;
            if not TryStrToInt64(Trim(VarToStr(aVar)), tmp) then Exit(False);
            ord := tmp;
          end
          else
            ord := VarAsType(aVar, varInt64);

          aOutValue := TValue.FromOrdinal(aDestType, ord);
          Exit(True);
        end;

      tkEnumeration:
        begin
          isBool := aDestType = TypeInfo(Boolean);
          if isBool then
          begin
            aOutValue := TValue.From<Boolean>(VarAsType(aVar, varBoolean));
            Exit(True);
          end
          else
          begin
            if VarIsStr(aVar) then
            begin
              ord := GetEnumValue(aDestType, VarToStr(aVar));
              if ord < 0 then Exit(False);
            end
            else if VarIsStr(aVar) then
              ord := StrToInt64(Trim(VarToStr(aVar)))
            else
              ord := VarAsType(aVar, varInt64);

            aOutValue := TValue.FromOrdinal(aDestType, ord);
            Exit(True);
          end;
        end;

      { sets (encoded as Int64 bitmask) }
      tkSet:
        begin
          // Null/Empty => empty set
          if VarIsNull(aVar) or VarIsEmpty(aVar) then
            ord := 0
          else
            ord := VarAsType(aVar, varInt64);

          var SetData: PTypeData := GetTypeData(aDestType);
          if (SetData = nil) or (SetData.CompType = nil) or (SetData.CompType^ = nil) then
            Exit(False);

          var ElemInfo: PTypeInfo := SetData.CompType^;
          var ElemData: PTypeData := GetTypeData(ElemInfo);
          if ElemData = nil then
            Exit(False);

          var BitCount := ElemData.MaxValue - ElemData.MinValue + 1;
          if BitCount <= 0 then
            Exit(False);

          var ByteCount := (BitCount + 7) div 8;

          // Int64 mask contract
          if ByteCount > SizeOf(Int64) then
            Exit(False);

          // Allocate a set storage buffer and copy bytes from ord
          var Buf: array[0..7] of Byte;
          FillChar(Buf, SizeOf(Buf), 0);
          Move(ord, Buf[0], ByteCount);

          // Create TValue of the set type and copy raw bytes into it
          TValue.Make(nil, aDestType, aOutValue);
          Move(Buf[0], aOutValue.GetReferenceToRawData^, ByteCount);

          Exit(True);
        end;

      { floats / date / currency }
      tkFloat:
        begin
          if aDestType = TypeInfo(TDateTime) then
          begin
            if VarIsNull(aVar) or VarIsEmpty(aVar) then Exit(False);
            dt := VarToDateTime(aVar);
            aOutValue := TValue.From<TDateTime>(dt);
            Exit(True);
          end
          else if aDestType = TypeInfo(Currency) then
          begin
            cur := VarAsType(aVar, varCurrency);
            aOutValue := TValue.From<Currency>(cur);
            Exit(True);
          end
          else
          begin
            aOutValue := TValue.From<Double>(VarAsType(aVar, varDouble));
            Exit(True);
          end;
        end;

      { variant passthrough }
      tkVariant:
        begin
          aOutValue := TValue.FromVariant(aVar);
          Exit(True);
        end;

      { interfaces }
      tkInterface:
        begin
          // Allow Null/Empty to nil
          if VarIsNull(aVar) or VarIsEmpty(aVar) then
          begin
            anyIntf := nil;
            TValue.Make(@anyIntf, aDestType, aOutValue);
            Exit(True);
          end;

          // Accept either varUnknown (IUnknown) or varDispatch (IDispatch)
          if (VarType(aVar) and varTypeMask) in [varUnknown, varDispatch] then
          begin
            anyIntf := IInterface(VarAsType(aVar, varUnknown));

            // Ensure it supports the requested interface GUID
            var Ctx: TRttiContext := TRttiContext.Create;
            try
              intfType := Ctx.GetType(aDestType) as TRttiInterfaceType;
              if (intfType = nil) or (not Supports(anyIntf, intfType.GUID)) then
                Exit(False);
            finally
              Ctx.Free;
            end;

            TValue.Make(@anyIntf, aDestType, aOutValue);
            Exit(True);
          end;

          Exit(False);
        end;

      { classes: support only COM/Automation carriers (varDispatch/varUnknown) + Null/Empty => nil }
      tkClass:
        begin
          // Only support "no object" -> nil reference.
          if VarIsNull(aVar) or VarIsEmpty(aVar) then
          begin
            obj := nil;
            TValue.Make(@obj, aDestType, aOutValue);
            Exit(True);
          end;

          // We deliberately do NOT try to convert varDispatch/varUnknown into TObject:
          // COM objects are not generally Delphi TObject instances.
          Exit(False);
        end;

      { dynamic arrays: Variant array -> TArray<T> (or any dynarray type) }
      tkDynArray:
        begin
          // Must be a 1D Variant array
          if (VarType(aVar) and varArray) = 0 then
            Exit(False);

          if VarArrayDimCount(aVar) <> 1 then
            Exit(False);

          lLow  := VarArrayLowBound(aVar, 1);
          lHigh := VarArrayHighBound(aVar, 1);
          Len := lHigh - lLow + 1;

          lDestData := GetTypeData(aDestType);
          if (lDestData = nil) or (lDestData.DynArrElType = nil) then
            Exit(False);

          lElType := lDestData.DynArrElType^;
          if lElType = nil then
            Exit(False);

          // Create an empty dynarray TValue (owns lifetime)
          TValue.Make(nil, aDestType, lArr);

          // Set its length by operating on the dynarray variable stored inside TValue
          DynArraySetLength(PPointer(lArr.GetReferenceToRawData)^, aDestType, 1, @Len);

          // Byte-array specialization (fast + direct)
          if lElType = TypeInfo(Byte) then
          begin
            for i := 0 to Len - 1 do
            begin
              // Coerce numeric variants; works for varByte, varSmallint, etc.
              var e := aVar[i + lLow];
              var b: Byte;

              if VarIsStr(e) then
                b := Byte(StrToInt(Trim(VarToStr(e))))
              else
                b := Byte(VarAsType(e, varInteger));

              lArr.SetArrayElement(i, TValue.From<Byte>(b));
            end;

            aOutValue := lArr;
            Exit(True);
          end;

          // Generic element conversion
          for i := 0 to Len - 1 do
          begin
            if not TryVariantToTValue(aVar[i + lLow], lElType, lElTV) then
              Exit(False);

            lArr.SetArrayElement(i, lElTV);
          end;

          aOutValue := lArr;
          Exit(True);
        end;

      tkRecord:
        begin
          if aDestType = TypeInfo(TGUID) then
          begin
            // Policy: Null/Empty => empty GUID (symmetric with other “empty” conversions)
            if VarIsNull(aVar) or VarIsEmpty(aVar) then
            begin
              var G: TGUID := AnEmptyGuid;
              aOutValue := TValue.From<TGUID>(G);
              Exit(True);
            end;

            S := VarToStr(aVar);
            var G: TGUID;

            try
              G := StringToGUID(S);
            except
              Exit(False);
            end;

            aOutValue := TValue.From<TGUID>(G);
            Exit(True);
          end;

          Exit(False);
        end;

    else
      Exit(False);
    end;
  except
    on E: EVariantError do Exit(False);
    on E: EConvertError do Exit(False);
    on E: EInvalidCast do Exit(False);
  end;
end;

class function TReflection.TryVariantToTValueStrict(const aVar: Variant; aDestType: PTypeInfo; out aOutValue: TValue): Boolean;
begin
  // Strict rules:
  //  - No string -> numeric coercion (int/float/currency/datetime/set mask)
  //  - Enum: allow enum *name* strings, but not numeric strings
  //  - Everything else same as TryVariantToTValue
  //
  // Implementation strategy: copy TryVariantToTValue and change only the numeric branches.

  Result := False;
  if aDestType = nil then Exit;

  try
    case aDestType^.Kind of
      tkInteger, tkInt64:
        begin
          if VarIsStr(aVar) then Exit(False);
          aOutValue := TValue.FromOrdinal(aDestType, VarAsType(aVar, varInt64));
          Exit(True);
        end;

      tkFloat:
        begin
          if VarIsStr(aVar) then Exit(False);

          if aDestType = TypeInfo(TDateTime) then
          begin
            if VarIsNull(aVar) or VarIsEmpty(aVar) then Exit(False);
            aOutValue := TValue.From<TDateTime>(VarToDateTime(aVar));
            Exit(True);
          end
          else if aDestType = TypeInfo(Currency) then
          begin
            aOutValue := TValue.From<Currency>(VarAsType(aVar, varCurrency));
            Exit(True);
          end
          else
          begin
            aOutValue := TValue.From<Double>(VarAsType(aVar, varDouble));
            Exit(True);
          end;
        end;

      tkEnumeration:
        begin
          // Boolean stays permissive (Variant can be many things)
          if aDestType = TypeInfo(Boolean) then
          begin
            aOutValue := TValue.From<Boolean>(VarAsType(aVar, varBoolean));
            Exit(True);
          end;

          // Strict: string is only allowed as *enum name*
          if VarIsStr(aVar) then
          begin
            var ord := GetEnumValue(aDestType, VarToStr(aVar));
            if ord < 0 then Exit(False);
            aOutValue := TValue.FromOrdinal(aDestType, ord);
            Exit(True);
          end;

          aOutValue := TValue.FromOrdinal(aDestType, VarAsType(aVar, varInt64));
          Exit(True);
        end;

      tkSet:
        begin
          // Strict: don't accept strings as numeric masks
          if VarIsStr(aVar) then Exit(False);
          // Delegate to your existing implementation’s set logic by just calling it
          Exit(TryVariantToTValue(aVar, aDestType, aOutValue));
        end;
    else
      // For all other kinds, reuse the permissive converter
      Exit(TryVariantToTValue(aVar, aDestType, aOutValue));
    end;
  except
    on E: EVariantError do Exit(False);
    on E: EConvertError do Exit(False);
    on E: EInvalidCast do Exit(False);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.TryVariantToTValue(const aVar: Variant; const aDestRttiType: TRttiType; out aOutValue: TValue): Boolean;
begin
  if aDestRttiType = nil then exit(False);

  Result := TryVariantToTValue(aVar, aDestRttiType.Handle, aOutValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.ConvertArgsFor(const aParams: TArray<TRttiParameter>; const aInArgs: TArray<Variant>; out aCallArgs: TArray<TValue>): Boolean;
var
  i: Integer;
  tv: TValue;
begin
  Result := False;
  if Length(aParams) <> Length(aInArgs) then Exit;

  SetLength(aCallArgs, Length(aParams));

  for i := 0 to High(aParams) do
  begin
    // reject var/out for now (keep it simple)
    if (pfVar in aParams[i].Flags) or (pfOut in aParams[i].Flags) then Exit;

    if not TryVariantToTValue(aInArgs[i], aParams[i].ParamType.Handle, tv) then Exit;

    aCallArgs[i] := tv;
  end;
  Result := True;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflection.ConvertArgsForStrict(const aParams: TArray<TRttiParameter>; const aInArgs: TArray<Variant>; out aCallArgs: TArray<TValue>): Boolean;
var
  i: Integer;
  tv: TValue;
begin
  Result := False;
  if Length(aParams) <> Length(aInArgs) then Exit;

  SetLength(aCallArgs, Length(aParams));

  for i := 0 to High(aParams) do
  begin
    if (pfVar in aParams[i].Flags) or (pfOut in aParams[i].Flags) then Exit;

    if not TryVariantToTValueStrict(aInArgs[i], aParams[i].ParamType.Handle, tv) then Exit;
    aCallArgs[i] := tv;
  end;

  Result := True;
end;

end.

