unit Tests.Core.Reflection;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Variants,
  Base.Reflection;

type
  { Test types }

  {$SCOPEDENUMS ON}
  TTestEnum = (Zero, One, Two);
  {$SCOPEDENUMS OFF}

  TTestSet = set of (sa, sb, sc);

  ITestIntf = interface(IInterface)
    ['{7A88B2A6-8D85-4F3F-9A23-9D4A6B8D9C0F}']
    function Ping: Integer;
  end;

  TTestObj = class(TInterfacedObject, ITestIntf)
  public
    function Ping: Integer;
  end;

  TUnrelatedObj = class(TInterfacedObject)
  end;

  TPlainUnrelatedObj = class(TObject)
  end;

  TTestRec = record
    X: Integer;
  end;

  // record with managed field (to exercise IsManagedType fallback/RTL behavior)
  TManagedRec = record
    S: string;
  end;

  TStaticIntArray = array[0..2] of Integer;
  TDynIntArray = TArray<Integer>;

  TMethodHost = class
  public
    procedure Proc0;
    function Sum(const A: Integer; const B: string): string;
    procedure HasVarParam(var A: Integer);
    procedure HasOutParam(out A: Integer);
  end;

  TSimpleProc = procedure of object;

  TSmallSetEnum = (e0, e1, e2, e3, e4, e5);
  TSmallSet = set of TSmallSetEnum;

  ICustomer = interface
    ['{2C5F44E9-6068-4E35-826B-27C03E4F5083}']
    function GetId: integer;
    procedure SetId(const aValue: integer);

    function GetName: string;
    procedure SetName(const aValue: string);

    property Id: integer read GetId write SetId;
    property Name: string read GetName write SetName;
  end;

  TCustomer = class(TInterfacedObject, ICustomer)
  private
    fId: integer;
    fName: string;
  public
    function GetId: integer;
    procedure SetId(const aValue: integer);

    function GetName: string;
    procedure SetName(const aValue: string);

    class function Make(const aId: integer; const aValue: string): TCustomer;
  end;

  [TestFixture]
  TReflectionFixture = class
  private
    class function GetMethod(const AClass: TClass; const AName: string): TRttiMethod; static;

    procedure ExpectAsInvalidCast(const Obj: TObject);
  public
    [Test] procedure KindHelpers_Basics;
    [Test] procedure KindHelpers_OrdinalFloatString;
    [Test] procedure KindHelpers_ArrayDynArrayMethodPointer;
    [Test] procedure KindHelpers_PointerVariantPrimitive;
    [Test] procedure ManagedHelpers_ManagedVsTrivial;
    [Test] procedure ManagedHelpers_NonOwningSafe;
    [Test] procedure ElementType_StaticArray;
    [Test] procedure ElementType_DynArray;
    [Test] procedure ElementType_NonArrayReturnsNil;
    [Test] procedure Names_KindTypeInfoTypeName;
    [Test] procedure Names_FullName_HasUnitPrefixForStructuredTypes;
    [Test] procedure Interface_TryGetGuid_SucceedsForInterface;
    [Test] procedure Interface_TryGetGuid_FailsForNonInterface;
    [Test] procedure Interface_AsAndImplements_ObjectAndInterface;
    [Test] procedure TValueToVariant_SupportedKinds;
    [Test] procedure TValueToVariant_UnsupportedKinds;
    [Test] procedure VariantToTValue_StringsAndChars;
    [Test] procedure VariantToTValue_IntegersEnumsBool;
    [Test] procedure VariantToTValue_FloatsDateCurrency;
    [Test] procedure VariantToTValue_VariantPassthrough;
    [Test] procedure VariantToTValue_Interface_NullBecomesNil;
    [Test] procedure VariantToTValue_Interface_SupportsGuid;
    [Test] procedure VariantToTValue_Interface_RejectsWrongGuid;
    [Test] procedure ConvertArgsFor_SucceedsForSimpleParams;
    [Test] procedure ConvertArgsFor_FailsOnCountMismatch;
    [Test] procedure ConvertArgsFor_RejectsVarAndOutParams;
    [Test] procedure Debug_StringKind;
    [Test] procedure RoundTrip_EmptyByteArray;
    [Test] procedure RoundTrip_Set_Int64Mask;
    [Test] procedure VariantToTValue_Set_AllowsNullAsEmpty;
    [Test] procedure RoundTrip_Guid_String;
    [Test] procedure VariantToTValue_Guid_AllowsNullAsEmpty;
    [Test] procedure VariantToTValue_Guid_InvalidStringFails;
    [Test] procedure RoundTrip_TArray_Integer;
    [Test] procedure RoundTrip_TArray_String;
    [Test] procedure RoundTrip_TArray_Interface;
  end;

implementation

{ TReflectionFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.RoundTrip_TArray_Interface;
var
  InA, OutA: TArray<ICustomer>;
  V: Variant;
  TV, TV2: TValue;
begin
  SetLength(InA, 2);
  InA[0] := TCustomer.Make(1, 'Fred');
  InA[1] := TCustomer.Make(2, 'Jack');

  TV := TValue.From<TArray<ICustomer>>(InA);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));

  Assert.IsTrue(TReflection.TryVariantToTValue(V, TypeInfo(TArray<ICustomer>), TV2));
  OutA := TV2.AsType<TArray<ICustomer>>;

  Assert.AreEqual(2, Length(OutA));
  Assert.IsTrue(Assigned(OutA[0]));
  Assert.IsTrue(Assigned(OutA[1]));

  Assert.AreEqual(1, OutA[0].Id);
  Assert.AreEqual(2, OutA[1].Id);

  Assert.AreEqual('Fred', OutA[0].Name);
  Assert.AreEqual('Jack', OutA[1].Name);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.RoundTrip_TArray_Integer;
var
  InA, OutA: TArray<Integer>;
  TV, TV2: TValue;
  V: Variant;
begin
  InA := TArray<Integer>.Create(1, 2, 3);

  TV := TValue.From<TArray<Integer>>(InA);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));

  Assert.IsTrue(TReflection.TryVariantToTValue(V, TypeInfo(TArray<Integer>), TV2));
  OutA := TV2.AsType<TArray<Integer>>;

  Assert.AreEqual(Length(InA), Length(OutA));
  Assert.AreEqual(1, OutA[0]);
  Assert.AreEqual(2, OutA[1]);
  Assert.AreEqual(3, OutA[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.RoundTrip_TArray_String;
var
  InA, OutA: TArray<string>;
  TV, TV2: TValue;
  V: Variant;
begin
  InA := TArray<string>.Create('a', 'b');

  TV := TValue.From<TArray<string>>(InA);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));

  Assert.IsTrue(TReflection.TryVariantToTValue(V, TypeInfo(TArray<string>), TV2));
  OutA := TV2.AsType<TArray<string>>;

  Assert.AreEqual(Length(InA), Length(OutA));
  Assert.AreEqual('a', OutA[0]);
  Assert.AreEqual('b', OutA[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.RoundTrip_Guid_String;
var
  G1, G2: TGUID;
  TV, TV2: TValue;
  V: Variant;
begin
  G1 := TGUID.Create('{6F9619FF-8B86-D011-B42D-00C04FC964FF}');

  TV := TValue.From<TGUID>(G1);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));
  Assert.AreEqual(GUIDToString(G1), VarToStr(V));

  Assert.IsTrue(TReflection.TryVariantToTValue(V, TypeInfo(TGUID), TV2));
  G2 := TV2.AsType<TGUID>;

  Assert.IsTrue(IsEqualGUID(G1, G2));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.VariantToTValue_Guid_AllowsNullAsEmpty;
var
  TV: TValue;
  G: TGUID;
begin
  Assert.IsTrue(TReflection.TryVariantToTValue(Null, TypeInfo(TGUID), TV));
  G := TV.AsType<TGUID>;
  Assert.IsTrue(IsEqualGUID(G, AnEmptyGuid));

  Assert.IsTrue(TReflection.TryVariantToTValue(Unassigned, TypeInfo(TGUID), TV));
  G := TV.AsType<TGUID>;
  Assert.IsTrue(IsEqualGUID(G, AnEmptyGuid));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.VariantToTValue_Guid_InvalidStringFails;
var
  TV: TValue;
begin
  Assert.IsFalse(TReflection.TryVariantToTValue('not-a-guid', TypeInfo(TGUID), TV));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.RoundTrip_Set_Int64Mask;
var
  S1, S2: TSmallSet;
  TV, TV2: TValue;
  V: Variant;
begin
  S1 := [e1, e4, e5];

  TV := TValue.From<TSmallSet>(S1);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));

  Assert.IsTrue(TReflection.TryVariantToTValue(V, TypeInfo(TSmallSet), TV2));
  S2 := TV2.AsType<TSmallSet>;

  Assert.IsTrue(S1 = S2);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.VariantToTValue_Set_AllowsNullAsEmpty;
var
  TV: TValue;
  S: TSmallSet;
begin
  Assert.IsTrue(TReflection.TryVariantToTValue(Null, TypeInfo(TSmallSet), TV));
  S := TV.AsType<TSmallSet>;
  Assert.IsTrue(S = []);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.RoundTrip_EmptyByteArray;
var
  InB, OutB: TBytes;
  V: Variant;
  TV, TV2: TValue;
begin
  InB := nil;

  TV := TValue.From<TBytes>(InB);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));

  Assert.IsTrue(TReflection.TryVariantToTValue(V, TypeInfo(TBytes), TV2));
  OutB := TV2.AsType<TBytes>;

  Assert.AreEqual(0, Length(OutB));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TReflectionFixture.GetMethod(const AClass: TClass; const AName: string): TRttiMethod;
var
  Ctx: TRttiContext;
  T: TRttiType;
begin
  Ctx := TRttiContext.Create;
  T := Ctx.GetType(AClass);
  Result := T.GetMethod(AName);
  Assert.IsNotNull(Result, 'RTTI method not found: ' + AClass.ClassName + '.' + AName);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.KindHelpers_Basics;
begin
  Assert.IsTrue(TReflection.IsInterface<ITestIntf>);
  Assert.IsTrue(TReflection.IsClass<TTestObj>);
  Assert.IsTrue(TReflection.IsRecord<TTestRec>);
  Assert.IsTrue(TReflection.IsClassRef<TClass>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.KindHelpers_OrdinalFloatString;
begin
  Assert.IsTrue(TReflection.IsOrdinal<Integer>);
  Assert.IsTrue(TReflection.IsOrdinal<Int64>);
  Assert.IsTrue(TReflection.IsOrdinal<Char>);
  Assert.IsTrue(TReflection.IsOrdinal<TTestEnum>);
  Assert.IsTrue(TReflection.IsOrdinal<TTestSet>);

  Assert.IsTrue(TReflection.IsFloat<Double>);
  Assert.IsTrue(TReflection.IsFloat<Currency>);
  Assert.IsTrue(TReflection.IsFloat<TDateTime>);

  Assert.IsTrue(TReflection.IsString<string>);
  Assert.IsTrue(TReflection.IsString<AnsiString>);
  Assert.IsTrue(TReflection.IsString<WideString>);
  Assert.IsTrue(TReflection.IsString<ShortString>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.KindHelpers_ArrayDynArrayMethodPointer;
var
  M: TSimpleProc;
begin
  Assert.IsTrue(TReflection.IsArray<TStaticIntArray>);
  Assert.IsTrue(TReflection.IsDynArray<TDynIntArray>);

  // method pointer is tkMethod only for "procedure of object"
  M := TMethodHost(nil).Proc0;
  Assert.IsTrue(TReflection.IsMethod<TSimpleProc>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.KindHelpers_PointerVariantPrimitive;
begin
  Assert.IsTrue(TReflection.IsPointer<Pointer>);
  Assert.IsTrue(TReflection.IsVariant<Variant>);

  Assert.IsTrue(TReflection.IsPrimitive<Integer>);
  Assert.IsTrue(TReflection.IsPrimitive<Int64>);
  Assert.IsTrue(TReflection.IsPrimitive<Boolean>);
  Assert.IsTrue(TReflection.IsPrimitive<Double>);
  Assert.IsTrue(TReflection.IsPrimitive<Pointer>);
  Assert.IsTrue(TReflection.IsPrimitive<ShortString>);

  Assert.IsFalse(TReflection.IsPrimitive<string>); // kind tkUString, not tkString
  Assert.IsFalse(TReflection.IsPrimitive<TTestRec>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.Debug_StringKind;
begin
  Assert.AreEqual(tkUString, TReflection.KindOf<string>,
    'In this unit, string is not UnicodeString (likely {$H-} is in effect)');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.ManagedHelpers_ManagedVsTrivial;
begin
  Assert.IsFalse(TReflection.IsManaged<Integer>);
  Assert.IsTrue(TReflection.IsTriviallyCopyable<Integer>);
  Assert.IsFalse(TReflection.NeedsFinalization<Integer>);

  Assert.IsTrue(TReflection.IsManaged<string>);
  Assert.IsFalse(TReflection.IsTriviallyCopyable<string>);
  Assert.IsTrue(TReflection.NeedsFinalization<string>);

  // Records with managed fields should be managed when RTL has IsManagedType
  // (fallback might miss it on very old compilers; this still exercises current behavior)
  Assert.IsTrue(TReflection.IsManaged<TManagedRec>);
  Assert.IsTrue(TReflection.NeedsFinalization<TManagedRec>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.ManagedHelpers_NonOwningSafe;
begin
  Assert.IsTrue(TReflection.IsNonOwningSafe<Integer>);
  Assert.IsTrue(TReflection.IsNonOwningSafe<string>);
  Assert.IsTrue(TReflection.IsNonOwningSafe<ITestIntf>);

  Assert.IsFalse(TReflection.IsNonOwningSafe<TObject>);
  Assert.IsFalse(TReflection.IsNonOwningSafe<Pointer>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.ElementType_StaticArray;
begin
  Assert.AreEqual(string(GetTypeName(TypeInfo(Integer))), string(GetTypeName(TReflection.ElementTypeInfo<TStaticIntArray>)));
  Assert.AreEqual('Integer', TReflection.ElementTypeName<TStaticIntArray>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.ElementType_DynArray;
begin
  Assert.AreEqual(string(GetTypeName(TypeInfo(Integer))), string(GetTypeName(TReflection.ElementTypeInfo<TDynIntArray>)));
  Assert.AreEqual('Integer', TReflection.ElementTypeName<TDynIntArray>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.ElementType_NonArrayReturnsNil;
begin
  Assert.IsNull(TReflection.ElementTypeInfo<Integer>);
  Assert.AreEqual('', TReflection.ElementTypeName<Integer>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.Names_KindTypeInfoTypeName;
begin
  Assert.AreEqual(tkInteger, TReflection.KindOf<Integer>);
  Assert.IsNotNull(TReflection.TypeInfoOf<Integer>);
  Assert.AreEqual('Integer', TReflection.TypeNameOf<Integer>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.Names_FullName_HasUnitPrefixForStructuredTypes;
var
  N: string;
begin
  // FullNameOf builds UnitName.TypeName for class/interface/record.
  N := TReflection.FullNameOf<TTestObj>;
  Assert.IsTrue(N.Contains('.'), 'Expected unit prefix in FullNameOf<TTestObj>: ' + N);
  Assert.IsTrue(N.EndsWith('.TTestObj') or N.EndsWith('.' + TReflection.TypeNameOf<TTestObj>), 'Unexpected FullNameOf<TTestObj>: ' + N);

  N := TReflection.FullNameOf<ITestIntf>;
  Assert.IsTrue(N.Contains('.'), 'Expected unit prefix in FullNameOf<ITestIntf>: ' + N);

  N := TReflection.FullNameOf<TTestRec>;
  Assert.IsTrue(N.EndsWith('TTestRec'), 'Unexpected FullNameOf<TTestRec>: ' + N);

  // For primitives, unit part is intentionally empty.
  N := TReflection.FullNameOf<Integer>;
  Assert.IsTrue((N = 'Integer') or N.EndsWith('.Integer'), 'Unexpected FullNameOf<Integer>: ' + N);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.Interface_TryGetGuid_SucceedsForInterface;
var
  g1: TGUID;
begin
  Assert.IsTrue(TReflection.TryGetInterfaceGuid<ITestIntf>(g1));
  Assert.IsFalse(IsEqualGUID(g1, AnEmptyGuid));

  var g2 := TGUID.Create('{7A88B2A6-8D85-4F3F-9A23-9D4A6B8D9C0F}');

  var s1 := GUIDToString(g1);
  var s2 := GUIDToString(g2);

  Assert.AreEqual<string>(s1, s2);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.Interface_TryGetGuid_FailsForNonInterface;
var
  G: TGUID;
begin
  Assert.IsFalse(TReflection.TryGetInterfaceGuid<Integer>(G));
  Assert.IsTrue(IsEqualGUID(G, AnEmptyGuid));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.ExpectAsInvalidCast(const Obj: TObject);
var
  L: ITestIntf;
begin
  L := nil;
  L := TReflection.&As<ITestIntf>(Obj);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.Interface_AsAndImplements_ObjectAndInterface;
var
  Intf: ITestIntf;
  AsIntf: ITestIntf;
  Obj: TObject;
begin
  { Positive case: lifetime owned by interface refs }
  Intf := TTestObj.Create as ITestIntf;

  Assert.IsTrue(TReflection.Implements<ITestIntf>(Intf));
  Assert.AreEqual(42, TReflection.&As<ITestIntf>(Intf).Ping);

  Assert.IsTrue(TReflection.Implements<ITestIntf>(Intf, AsIntf));
  Assert.IsTrue(Assigned(AsIntf));
  Assert.AreEqual(42, AsIntf.Ping);

  { Negative case: unrelated object is not refcounted (TInterfacedObject still is, but we own as TObject) }
  Obj := TPlainUnrelatedObj.Create;
  try
    Assert.IsFalse(TReflection.Implements<ITestIntf>(Obj));

    Assert.WillRaise(
      procedure begin ExpectAsInvalidCast(Obj); end,
      EInvalidCast
    );
  finally
    Obj.Free;
  end;

  { Drop interface refs explicitly (not strictly required, but makes shutdown deterministic) }
  AsIntf := nil;
  Intf := nil;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.TValueToVariant_SupportedKinds;
var
  V: Variant;
  TV: TValue;
  D: TDateTime;
  C: Currency;
  I: ITestIntf;
begin
  // string kinds
  TV := TValue.From<string>('abc');
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));
  Assert.AreEqual('abc', VarToStr(V));

  // char
  TV := TValue.From<Char>('Z');
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));
  Assert.AreEqual('Z', VarToStr(V));

  // integers
  TV := TValue.From<Integer>(123);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));
  Assert.AreEqual<Integer>(Int64(123), VarAsType(V, varInt64));

  // boolean (enum kind)
  TV := TValue.From<Boolean>(True);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));
  Assert.AreEqual<Boolean>(True, VarAsType(V, varBoolean));

  // enum as ordinal
  TV := TValue.From<TTestEnum>(TTestEnum.Two);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));
  Assert.AreEqual<Integer>(Int64(Ord(TTestEnum.Two)), VarAsType(V, varInt64));

  // date time
  D := EncodeDate(2020, 1, 2) + EncodeTime(3, 4, 5, 0);
  TV := TValue.From<TDateTime>(D);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));
  Assert.AreEqual(D, VarToDateTime(V));

  // currency
  C := 12.34;
  TV := TValue.From<Currency>(C);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));
  Assert.AreEqual<Currency>(C, VarAsType(V, varCurrency));

  // interface => varUnknown/varDispatch
  I := TTestObj.Create as ITestIntf;
  TV := TValue.From<IInterface>(I);
  Assert.IsTrue(TReflection.TryTValueToVariant(TV, V));
  Assert.IsTrue((VarType(V) and varTypeMask) in [varUnknown, varDispatch]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.TValueToVariant_UnsupportedKinds;
var
  V: Variant;
  TV: TValue;
  R: TTestRec;
begin
  // records not supported without custom boxing
  R.X := 1;
  TV := TValue.From<TTestRec>(R);
  Assert.IsFalse(TReflection.TryTValueToVariant(TV, V));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.VariantToTValue_StringsAndChars;
var
  TV: TValue;
  SS: ShortString;
begin
  Assert.IsTrue(TReflection.TryVariantToTValue('hello', TypeInfo(string), TV));
  Assert.AreEqual('hello', TV.AsString);

  Assert.IsTrue(TReflection.TryVariantToTValue('wide', TypeInfo(WideString), TV));
  Assert.AreEqual('wide', string(TV.AsType<WideString>));

  Assert.IsTrue(TReflection.TryVariantToTValue('ansi', TypeInfo(AnsiString), TV));
  Assert.AreEqual('ansi', string(TV.AsType<AnsiString>));

  Assert.IsTrue(TReflection.TryVariantToTValue('ss', TypeInfo(ShortString), TV));
  SS := TV.AsType<ShortString>;
  Assert.AreEqual(string('ss'), string(SS));

  Assert.IsTrue(TReflection.TryVariantToTValue('Z', TypeInfo(Char), TV));
  Assert.AreEqual('Z', TV.AsType<Char>);

  // empty string becomes #0 for chars
  Assert.IsTrue(TReflection.TryVariantToTValue('', TypeInfo(Char), TV));
  Assert.AreEqual(Char(#0), TV.AsType<Char>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.VariantToTValue_IntegersEnumsBool;
var
  TV: TValue;
begin
  Assert.IsTrue(TReflection.TryVariantToTValue(123, TypeInfo(Integer), TV));
  Assert.AreEqual(123, TV.AsInteger);

  Assert.IsTrue(TReflection.TryVariantToTValue(Int64(1234567890123), TypeInfo(Int64), TV));
  Assert.AreEqual(Int64(1234567890123), TV.AsInt64);

  // bool
  Assert.IsTrue(TReflection.TryVariantToTValue(True, TypeInfo(Boolean), TV));
  Assert.AreEqual(True, TV.AsBoolean);

  // enum by ordinal
  Assert.IsTrue(TReflection.TryVariantToTValue(2, TypeInfo(TTestEnum), TV));
  Assert.AreEqual<Integer>(Ord(TTestEnum.Two), TV.AsOrdinal);

  // enum by name
  Assert.IsTrue(TReflection.TryVariantToTValue('One', TypeInfo(TTestEnum), TV));
  Assert.AreEqual<integer>(Ord(TTestEnum.One), TV.AsOrdinal);

  // enum invalid name => False
  Assert.IsFalse(TReflection.TryVariantToTValue('Nope', TypeInfo(TTestEnum), TV));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.VariantToTValue_FloatsDateCurrency;
var
  TV: TValue;
  D: TDateTime;
  C: Currency;
begin
  Assert.IsTrue(TReflection.TryVariantToTValue(1.25, TypeInfo(Double), TV));
  Assert.AreEqual<Double>(1.25, TV.AsType<Double>);

  D := EncodeDate(2021, 12, 31) + EncodeTime(23, 59, 58, 0);
  Assert.IsTrue(TReflection.TryVariantToTValue(VarFromDateTime(D), TypeInfo(TDateTime), TV));
  Assert.AreEqual(D, TV.AsType<TDateTime>);

  // Null/Empty date rejected
  Assert.IsFalse(TReflection.TryVariantToTValue(Null, TypeInfo(TDateTime), TV));
  Assert.IsFalse(TReflection.TryVariantToTValue(Unassigned, TypeInfo(TDateTime), TV));

  C := 99.99;
  Assert.IsTrue(TReflection.TryVariantToTValue(VarAsType(C, varCurrency), TypeInfo(Currency), TV));
  Assert.AreEqual(C, TV.AsType<Currency>);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.VariantToTValue_VariantPassthrough;
var
  TV: TValue;
  V: Variant;
begin
  V := 'x';
  Assert.IsTrue(TReflection.TryVariantToTValue(V, TypeInfo(Variant), TV));
  Assert.AreEqual('x', VarToStr(TV.AsVariant));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.VariantToTValue_Interface_NullBecomesNil;
var
  TV: TValue;
  I: ITestIntf;
begin
  Assert.IsTrue(TReflection.TryVariantToTValue(Null, TypeInfo(ITestIntf), TV));
  I := TV.AsType<ITestIntf>;
  Assert.IsTrue(I = nil);

  Assert.IsTrue(TReflection.TryVariantToTValue(Unassigned, TypeInfo(ITestIntf), TV));
  I := TV.AsType<ITestIntf>;
  Assert.IsTrue(I = nil);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.VariantToTValue_Interface_SupportsGuid;
var
  V: Variant;
  TV: TValue;
  I: ITestIntf;
  Src: ITestIntf;
begin
  Src := TTestObj.Create as ITestIntf;
  V := IUnknown(Src);

  Assert.IsTrue(TReflection.TryVariantToTValue(V, TypeInfo(ITestIntf), TV));
  I := TV.AsType<ITestIntf>;

  Assert.IsTrue(Assigned(I));
  Assert.AreEqual(42, I.Ping);

  I := nil;
  Src := nil;
  TV := TValue.Empty;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.VariantToTValue_Interface_RejectsWrongGuid;
var
  V: Variant;
  TV: TValue;
  Src: IInterface;
begin
  Src := TUnrelatedObj.Create as IInterface;
  V := IUnknown(Src);

  Assert.IsFalse(TReflection.TryVariantToTValue(V, TypeInfo(ITestIntf), TV));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.ConvertArgsFor_SucceedsForSimpleParams;
var
  M: TRttiMethod;
  Params: TArray<TRttiParameter>;
  InArgs: TArray<Variant>;
  CallArgs: TArray<TValue>;
begin
  M := GetMethod(TMethodHost, 'Sum');
  Params := M.GetParameters;

  SetLength(InArgs, 2);
  InArgs[0] := 7;
  InArgs[1] := 'abc';

  Assert.IsTrue(TReflection.ConvertArgsFor(Params, InArgs, CallArgs));
  Assert.AreEqual(2, Length(CallArgs));
  Assert.AreEqual(7, CallArgs[0].AsInteger);
  Assert.AreEqual('abc', CallArgs[1].AsString);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.ConvertArgsFor_FailsOnCountMismatch;
var
  M: TRttiMethod;
  Params: TArray<TRttiParameter>;
  InArgs: TArray<Variant>;
  CallArgs: TArray<TValue>;
begin
  M := GetMethod(TMethodHost, 'Sum');
  Params := M.GetParameters;

  SetLength(InArgs, 1);
  InArgs[0] := 7;

  Assert.IsFalse(TReflection.ConvertArgsFor(Params, InArgs, CallArgs));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TReflectionFixture.ConvertArgsFor_RejectsVarAndOutParams;
var
  M: TRttiMethod;
  Params: TArray<TRttiParameter>;
  InArgs: TArray<Variant>;
  CallArgs: TArray<TValue>;
begin
  // var param
  M := GetMethod(TMethodHost, 'HasVarParam');
  Params := M.GetParameters;
  InArgs := TArray<Variant>.Create(1);
  Assert.IsFalse(TReflection.ConvertArgsFor(Params, InArgs, CallArgs));

  // out param
  M := GetMethod(TMethodHost, 'HasOutParam');
  Params := M.GetParameters;
  InArgs := TArray<Variant>.Create(1);
  Assert.IsFalse(TReflection.ConvertArgsFor(Params, InArgs, CallArgs));
end;

{ TTestObj }

{----------------------------------------------------------------------------------------------------------------------}
function TTestObj.Ping: Integer;
begin
  Result := 42;
end;

{ TMethodHost }

{----------------------------------------------------------------------------------------------------------------------}
procedure TMethodHost.Proc0;
begin
end;

{----------------------------------------------------------------------------------------------------------------------}
function TMethodHost.Sum(const A: Integer; const B: string): string;
begin
  Result := IntToStr(A) + ':' + B;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMethodHost.HasVarParam(var A: Integer);
begin
  Inc(A);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMethodHost.HasOutParam(out A: Integer);
begin
  A := 123;
end;

{ TCustomer }

{----------------------------------------------------------------------------------------------------------------------}
function TCustomer.GetId: integer;
begin
  Result := fId;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCustomer.GetName: string;
begin
  Result := fName;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCustomer.Make(const aId: integer; const aValue: string): TCustomer;
begin
  Result := TCustomer.Create;
  Result.fId := aId;
  Result.fName := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCustomer.SetId(const aValue: integer);
begin
  fId := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCustomer.SetName(const aValue: string);
begin
  fName := aValue;
end;

initialization
  TDUnitX.RegisterTestFixture(TReflectionFixture);

end.

