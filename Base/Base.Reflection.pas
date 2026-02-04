unit Base.Reflection;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Variants;

type
  TReflection = record
  public
    // Basic kind helpers
    class function IsInterface<T>: Boolean; static; inline;
    class function IsClass<T>: Boolean; static; inline;
    class function IsRecord<T>: Boolean; static; inline;
    class function IsClassRef<T>: Boolean; static; inline;   // metaclass
    class function IsOrdinal<T>: Boolean; static; inline;    // enums, sets, integers, chars, int64
    class function IsFloat<T>: Boolean; static; inline;      // Float/Curr
    class function IsString<T>: Boolean; static; inline;     // Short/Ansi/Wide/UnicodeString
    class function IsArray<T>: Boolean; static; inline;      // static array
    class function IsDynArray<T>: Boolean; static; inline;   // dynamic array
    class function IsMethod<T>: Boolean; static; inline;     // method pointer
    class function IsPointer<T>: Boolean; static; inline;
    class function IsVariant<T>: Boolean; static; inline;
    class function IsPrimitive<T>: Boolean; static; inline;

    // Managed-type (ref-counted / compiler-managed) check
    class function IsManaged<T>: Boolean; static; inline;
    class function IsNonOwningSafe<T>: Boolean; static; inline;
    class function NeedsFinalization<T>: Boolean; static; inline;
    class function IsReferenceCounted<T>: Boolean; static; inline;
    class function IsTriviallyCopyable<T>: Boolean; static; inline;

    // array element type
    class function ElementTypeInfo<T>: PTypeInfo; static;
    class function ElementTypeName<T>: string; static;

    // Names & metadata
    class function KindOf<T>: TTypeKind; static; inline;
    class function TypeInfoOf<T>: PTypeInfo; static; inline;
    class function TypeNameOf<T>: string; static; inline;
    class function FullNameOf<T>: string; static; inline;

    // Utility
    class function DefaultOf<T>: T; static; inline;
    class function InterfaceGuidOf<T>: TGUID; static; inline;

    class procedure RequireInterfaceType<T>; static; inline;

    class function &As<T>(const aSource: TObject): T; overload; static; inline;
    class function &As<T>(const aSource: IInterface): T; overload; static; inline;

    class function Implements<T>(const aSource: TObject): Boolean; overload; static; inline;
    class function Implements<T>(const aSource: TObject; out aTarget: T): Boolean; overload; static; inline;
    class function Implements<T>(const aSource: IInterface): Boolean; overload; static; inline;
    class function Implements<T>(const aSource: IInterface; out aTarget: T): Boolean; overload; static; inline;

    // Interface GUID helper
    class function TryGetInterfaceGuid<T>(out aGuid: TGUID): Boolean; static;

    // TValue to Variant (lossless for supported kinds). Returns False if not supported.
    class function TryTValueToVariant(const aValue: TValue; out aOutVar: Variant): Boolean; static;

    // Variant to TValue of the exact DestType (PTypeInfo). Returns False if not supported/convertible.
    class function TryVariantToTValue(const aVar: Variant; aDestType: PTypeInfo; out aOutValue: TValue): Boolean; overload; static;

    // Convenience overload for TRttiType
    class function TryVariantToTValue(const aVar: Variant; const aDestRttiType: TRttiType; out aOutValue: TValue): Boolean; overload; static;

    class function ConvertArgsFor(const aParams: TArray<TRttiParameter>; const aInArgs: TArray<Variant>; out aCallArgs: TArray<TValue>): Boolean; static;
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
//class function TReflection.FullNameOf<T>: string;
//var
//  lInfo: PTypeInfo;
//  lData: PTypeData;
//  lUnit : string;
//begin
//  lInfo := TypeInfo(T);
//  Result := GetTypeName(lInfo);
//  lData := GetTypeData(lInfo);
//
//  case lInfo.Kind of
//    tkClass, tkInterface, tkRecord:
//      lUnit := string(lData.UnitName);
//  else
//      lUnit := '';
//  end;
//
//  if lUnit <> '' then
//    Result := lUnit + '.' + Result;
//end;

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
  lTypeInfo: PTypeInfo;
begin
  Result := True;
  lTypeInfo := aValue.TypeInfo;

  case aValue.Kind of
    tkVariant:
      aOutVar := aValue.AsVariant;

    tkUString, tkWString, tkLString, tkString:
      aOutVar := aValue.ToString;

    tkChar:
      aOutVar := string(aValue.AsType<Char>);           // single-char string
    tkWChar:
      aOutVar := string(aValue.AsType<WideChar>);

    tkInteger, tkInt64:
      aOutVar := aValue.AsInt64;                        // use varInt64 to be safe

    tkEnumeration:
      begin
        if lTypeInfo = TypeInfo(Boolean) then
          aOutVar := aValue.AsBoolean
        else
          aOutVar := aValue.AsOrdinal;                  // enum as ordinal (lossless with DestType on return)
      end;

    tkFloat:
      begin
        if lTypeInfo = TypeInfo(TDateTime) then
          aOutVar := VarFromDateTime(aValue.AsType<TDateTime>) // varDate
        else if lTypeInfo = TypeInfo(Currency) then
          aOutVar := VarAsType(aValue.AsExtended, varCurrency) // varCurrency
        else
          aOutVar := aValue.AsExtended;               // varDouble
      end;

    tkInterface:
      begin
        // Prefer IDispatch if available; otherwise IUnknown
        if Supports(aValue.AsInterface, IDispatch) then
          aOutVar := IDispatch(aValue.AsInterface)
        else
          aOutVar := IUnknown(aValue.AsInterface);
      end;

  else
    // Not supported without custom boxing
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
  ptr: Pointer;
begin
  Result := False;
  if aDestType = nil then
    Exit;

  kind := aDestType^.Kind;

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
          else
            ord := VarAsType(aVar, varInt64);
          aOutValue := TValue.FromOrdinal(aDestType, ord);
          Exit(True);
        end;
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
          ptr := nil;
          TValue.Make(@ptr, aDestType, aOutValue);
          Exit(True);
        end;

        // Accept either varUnknown (IUnknown) or varDispatch (IDispatch)
        if (VarType(aVar) and varTypeMask) in [varUnknown, varDispatch] then
        begin
          anyIntf := IInterface(VarAsType(aVar, varUnknown));
          // Ensure it supports the requested interface GUID
          intfType := TRttiContext.Create.GetType(aDestType) as TRttiInterfaceType;

          if not Supports(anyIntf, intfType.GUID) then
            Exit(False);

          ptr := Pointer(anyIntf);
          TValue.Make(@ptr, aDestType, aOutValue);
          Exit(True);
        end;

        Exit(False);
      end;
  else
    // classes, records, dyn arrays, sets: not supported here
    Exit(False);
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

end.

