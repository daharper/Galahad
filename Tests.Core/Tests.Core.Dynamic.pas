unit Tests.Core.Dynamic;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Variants,
  Winapi.ActiveX,
  Base.Dynamic;

type
  // Simple interface DTO for return-value tests
  ICustomer = interface
    ['{2C5F44E9-6068-4E35-826B-27C03E4F5083}']
    function GetId: Integer;
    function GetName: string;
    property Id: Integer read GetId;
    property Name: string read GetName;
  end;

  TCustomer = class(TInterfacedObject, ICustomer)
  private
    FId: Integer;
    FName: string;
  public
    constructor Create(AId: Integer; const AName: string);
    function GetId: Integer;
    function GetName: string;
    class function Make(AId: Integer; const AName: string): ICustomer; static;
  end;

  // Instrumented dynamic object
  TTestDynamic = class(TDynamicObject)
  private
    FCount: Integer;
    FItems: array[0..2] of string;

    function GetItem(aIndex: Integer): string;
    procedure SetItem(aIndex: Integer; const Value: string);
  public
    LastMissingName: string;
    LastMissingArgs: TArray<Variant>;
    MissingCount: Integer;

    function Add(A, B: Integer): Integer;
    function Echo(const S: string): string;

    // Arrays / supported types
    function SumArray(const A: TArray<Integer>): Integer;
    function BytesLen(const B: TBytes): Integer;
    function GuidStrings(const A: TArray<TGUID>): TArray<TGUID>;
    function MakeCustomer(AId: Integer; const AName: string): ICustomer;

    property Count: Integer read FCount write FCount;

    // Indexed property
    property Item[aIndex: Integer]: string read GetItem write SetItem;

    function MethodMissing(const aName: string; const aArgs: TArray<Variant>): Variant; override;
  end;

  // Instrumented extended object
  TTestExtended = class(TExtendedObject)
  public
    LastMissingName: string;
    LastMissingArgs: TArray<Variant>;
    MissingCount: Integer;
    function MethodMissing(const Name: string; const Args: TArray<Variant>): Variant; override;
  end;

  [TestFixture]
  TDynamicTests = class
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test] procedure Dynamic_StaticMethod_Dispatches;
    [Test] procedure Dynamic_PropertyGetPut_Dispatches;
    [Test] procedure Dynamic_IndexedProperty_GetPut_Dispatches;
    [Test] procedure Dynamic_MethodMissing_WhenMemberNotFound;
    [Test] procedure Extended_Always_MethodMissing;
    [Test] procedure Decorator_Delegates_To_Source;
    [Test] procedure EffectivePropertyFlags_PropertyPutRef_For_Interface_LastArg;
    [Test] procedure EffectivePropertyFlags_PropertyPut_For_NonInterface_LastArg;
    [Test] procedure Dynamic_SupportedTypes_TArrayInteger;
    [Test] procedure Dynamic_SupportedTypes_TBytes;
    [Test] procedure Dynamic_SupportedTypes_TArrayGuid;
    [Test] procedure Dynamic_SupportedTypes_InterfaceReturn;
  end;

implementation

uses
  ComObj;

{ TDynamicTests }

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.Setup;
begin
  // Ensure COM is initialized for OleVariant/IDispatch usage in tests
  OleCheck(CoInitializeEx(nil, COINIT_APARTMENTTHREADED));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.TearDown;
begin
  CoUninitialize;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.Dynamic_StaticMethod_Dispatches;
var
  O: TTestDynamic;
  V: OleVariant;
begin
  O := TTestDynamic.Create;

  V := O.AsVariant;

  Assert.AreEqual(3, Integer(V.Add(1, 2)));
  Assert.AreEqual('hello', string(V.Echo('hello')));

  Assert.AreEqual(0, O.MissingCount, 'MethodMissing should not be called for real methods');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.Dynamic_PropertyGetPut_Dispatches;
var
  O: TTestDynamic;
  V: OleVariant;
begin
  O := TTestDynamic.Create;

  V := O.AsVariant;

  V.Count := 123;
  Assert.AreEqual(123, O.Count);
  Assert.AreEqual(123, Integer(V.Count));

  Assert.AreEqual(0, O.MissingCount, 'MethodMissing should not be called for real properties');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.Dynamic_IndexedProperty_GetPut_Dispatches;
var
  O: TTestDynamic;
  V: OleVariant;
begin
  O := TTestDynamic.Create;

  V := O.AsVariant;

  // Indexed property: Item[1] := 'x' and read back
  V.Item(1) := 'X'; // Delphi uses default "indexed property call" syntax for IDispatch
  Assert.AreEqual('X', O.Item[1]);

  Assert.AreEqual('X', string(V.Item(1)));

  Assert.AreEqual(0, O.MissingCount, 'MethodMissing should not be called for indexed properties');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.Dynamic_MethodMissing_WhenMemberNotFound;
var
  O: TTestDynamic;
  V: OleVariant;
  R: Variant;
begin
  O := TTestDynamic.Create;

  V := O.AsVariant;

  R := V.NoSuchMethod(10, 'abc');

  Assert.AreEqual(1, O.MissingCount);
  Assert.AreEqual('NoSuchMethod', O.LastMissingName);
  Assert.AreEqual(2, Length(O.LastMissingArgs));
  Assert.AreEqual(10, Integer(O.LastMissingArgs[0]));
  Assert.AreEqual('abc', string(O.LastMissingArgs[1]));

  Assert.IsTrue(VarIsStr(R));
  Assert.IsTrue(string(R).StartsWith('[missing-test]'));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.Extended_Always_MethodMissing;
var
  O: TTestExtended;
  V: OleVariant;
  R: Variant;
begin
  O := TTestExtended.Create;

  V := O.AsVariant;

  R := V.Anything(1, 2, 3);

  Assert.AreEqual(1, O.MissingCount);
  Assert.AreEqual('Anything', O.LastMissingName);
  Assert.AreEqual(3, Length(O.LastMissingArgs));
  Assert.IsTrue(string(R).StartsWith('[missing-ext]'));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.Decorator_Delegates_To_Source;
var
  Src: TTestDynamic;
  Dec: TDynamicDecorator<TTestDynamic>;
  V: OleVariant;
begin
  Src := TTestDynamic.Create;
  Dec := TDynamicDecorator<TTestDynamic>.Create(Src);

  V := Dec.AsVariant;

  // Method exists only on source: should be found by decorator's second dispatch attempt
  Assert.AreEqual(7, Integer(V.Add(3, 4)));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.EffectivePropertyFlags_PropertyPutRef_For_Interface_LastArg;
var
  DP: TDispParams;
  Named: Integer;
  Args: TArray<Variant>;
  Flags: Word;
  C: ICustomer;
begin
  FillChar(DP, SizeOf(DP), 0);
  Named := DISPID_PROPERTYPUT;
  DP.cNamedArgs := 1;
  DP.rgdispidNamedArgs := @Named;

  C := TCustomer.Make(1, 'Fred');
  SetLength(Args, 1);
  Args[0] := IUnknown(C); // varUnknown

  Flags := TDynamicHelper.EffectivePropertyFlags(DISPATCH_METHOD, DP, Args);
  Assert.IsTrue((Flags and DISPATCH_PROPERTYPUTREF) <> 0);
  Assert.IsTrue((Flags and DISPATCH_METHOD) = 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.EffectivePropertyFlags_PropertyPut_For_NonInterface_LastArg;
var
  DP: TDispParams;
  Named: Integer;
  Args: TArray<Variant>;
  Flags: Word;
begin
  FillChar(DP, SizeOf(DP), 0);
  Named := DISPID_PROPERTYPUT;
  DP.cNamedArgs := 1;
  DP.rgdispidNamedArgs := @Named;

  SetLength(Args, 1);
  Args[0] := 123;

  Flags := TDynamicHelper.EffectivePropertyFlags(DISPATCH_METHOD, DP, Args);
  Assert.IsTrue((Flags and DISPATCH_PROPERTYPUT) <> 0);
  Assert.IsTrue((Flags and DISPATCH_METHOD) = 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.Dynamic_SupportedTypes_TArrayInteger;
var
  O: TTestDynamic;
  V: OleVariant;
  A: Variant;
begin
  O := TTestDynamic.Create;
  V := O.AsVariant;

  // SAFEARRAY-ish: Variant array
  A := VarArrayOf([1, 2, 3, 4]);
  Assert.AreEqual(10, Integer(V.SumArray(A)));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.Dynamic_SupportedTypes_TBytes;
var
  O: TTestDynamic;
  V: OleVariant;
  B: Variant;
begin
  O := TTestDynamic.Create;

  V := O.AsVariant;

  // Byte array variant: varByte SAFEARRAY
  B := VarArrayCreate([0, 2], varByte);
  B[0] := 10;
  B[1] := 20;
  B[2] := 30;

  Assert.AreEqual(3, Integer(V.BytesLen(B)));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.Dynamic_SupportedTypes_TArrayGuid;
var
  O: TTestDynamic;
  V: OleVariant;
  A: Variant;
  R: Variant;
begin
  O := TTestDynamic.Create;

  V := O.AsVariant;

  // Array of GUID strings (your contract)
  A := VarArrayCreate([0, 1], varVariant);
  A[0] := '{6F9619FF-8B86-D011-B42D-00C04FC964FF}';
  A[1] := '{2C5F44E9-6068-4E35-826B-27C03E4F5083}';

  R := V.GuidStrings(A);

  Assert.IsTrue((VarType(R) and varArray) <> 0);
  Assert.AreEqual(string(A[0]), string(R[0]));
  Assert.AreEqual(string(A[1]), string(R[1]));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDynamicTests.Dynamic_SupportedTypes_InterfaceReturn;
var
  O: TTestDynamic;
  V: OleVariant;
  R: Variant;
  C: ICustomer;
begin
  O := TTestDynamic.Create;

  V := O.AsVariant;

  R := V.MakeCustomer(7, 'Jack');

  // Returned as varUnknown/varDispatch; coerce to ICustomer for assertions
  C := IInterface(VarAsType(R, varUnknown)) as ICustomer;

  Assert.AreEqual(7, C.Id);
  Assert.AreEqual('Jack', C.Name);
end;

{ TCustomer }

{----------------------------------------------------------------------------------------------------------------------}
constructor TCustomer.Create(AId: Integer; const AName: string);
begin
  inherited Create;
  FId := AId;
  FName := AName;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCustomer.GetId: Integer;
begin
  Result := FId;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCustomer.GetName: string;
begin
  Result := FName;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCustomer.Make(AId: Integer; const AName: string): ICustomer;
begin
  Result := TCustomer.Create(AId, AName);
end;

{ TTestDynamic }

{----------------------------------------------------------------------------------------------------------------------}
function TTestDynamic.Add(A, B: Integer): Integer;
begin
  Result := A + B;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTestDynamic.Echo(const S: string): string;
begin
  Result := S;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTestDynamic.GetItem(aIndex: Integer): string;
begin
  Result := fItems[aIndex];
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TTestDynamic.SetItem(aIndex: Integer; const Value: string);
begin
  fItems[aIndex] := Value;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTestDynamic.SumArray(const A: TArray<Integer>): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(A) do
    Inc(Result, A[i]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTestDynamic.BytesLen(const B: TBytes): Integer;
begin
  Result := Length(B);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTestDynamic.GuidStrings(const A: TArray<TGUID>): TArray<TGUID>;
begin
  // Identity round-trip
  Result := A;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTestDynamic.MakeCustomer(AId: Integer; const AName: string): ICustomer;
begin
  Result := TCustomer.Make(AId, AName);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTestDynamic.MethodMissing(const aName: string; const aArgs: TArray<Variant>): Variant;
begin
  Inc(MissingCount);
  LastMissingName := aName;
  LastMissingArgs := Copy(aArgs);
  Result := Format('[missing-test] %s(%d)', [aName, Length(aArgs)]);
end;

{ TTestExtended }

{----------------------------------------------------------------------------------------------------------------------}
function TTestExtended.MethodMissing(const Name: string; const Args: TArray<Variant>): Variant;
begin
  Inc(MissingCount);
  LastMissingName := Name;
  LastMissingArgs := Copy(Args);
  Result := Format('[missing-ext] %s(%d)', [Name, Length(Args)]);
end;

initialization
  TDUnitX.RegisterTestFixture(TDynamicTests);

end.

