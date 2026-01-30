unit Tests.Core.Let;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils;

type
  [TestFixture]
  TLetFixture = class
  public
    [Test] procedure Let_Positional_MixedTypes_AssignsAll;
    [Test] procedure Let_Array_NotEnoughValues_Raises;
    [Test] procedure LetOrDefault_Array_FillsMissingWithDefault;
    [Test] procedure LetOrDefault_Array_AssignsPresentValues;
    [Test] procedure LetOr_Array_UsesFallback;
    [Test] procedure LetOr_Array_PrefersValues;
  end;

implementation

uses
  Base.Core;

{----------------------------------------------------------------------------------------------------------------------}
procedure TLetFixture.Let_Positional_MixedTypes_AssignsAll;
var
  id: Integer;
  price: Double;
begin
  TLx.Let<Integer, Double>(id, price, 5, 12.5);

  Assert.AreEqual(5, id);
  Assert.AreEqual<Double>(12.5, price);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TLetFixture.Let_Array_NotEnoughValues_Raises;
begin
  Assert.WillRaise(
    procedure
    var
      A, B, C: Integer;
    begin
      TLx.Let<Integer>(A, B, C, [1, 2]);
    end,
    ELetException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TLetFixture.LetOrDefault_Array_AssignsPresentValues;
var
A, B, C: string;
begin
  TLx.LetOrDefault<string>(A, B, C, ['x', 'y']);

  Assert.AreEqual('x', A);
  Assert.AreEqual('y', B);
  Assert.AreEqual('', C);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TLetFixture.LetOrDefault_Array_FillsMissingWithDefault;
var
  A, B, C: Integer;
begin
  TLx.LetOrDefault<Integer>(A, B, C, [42]);

  Assert.AreEqual(42, A);
  Assert.AreEqual(0, B);
  Assert.AreEqual(0, C);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TLetFixture.LetOr_Array_PrefersValues;
var
  A, B, C: Integer;
begin
  TLx.LetOr<Integer>(A, B, C, 0, [1, 2]);

  Assert.AreEqual(1, A);
  Assert.AreEqual(2, B);
  Assert.AreEqual(0, C);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TLetFixture.LetOr_Array_UsesFallback;
var
  A, B: Integer;
begin
  TLx.LetOr<Integer>(A, B, -1, []);

  Assert.AreEqual(-1, A);
  Assert.AreEqual(-1, B);
end;

initialization
TDUnitX.RegisterTestFixture(TLetFixture);

end.
