unit Tests.Core.Collect;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  DUnitX.TestFramework,
  Base.Core,
  Base.Collections;

type
  [TestFixture]
  TCollectFixture = class
  public
    [Test] procedure Filter_PreservesOrder_AndDoesNotMutateSource;
    [Test] procedure Map_PreservesOrder_AndDoesNotMutateSource;
    [Test] procedure Sort_ReturnsSortedCopy_AndDoesNotMutateSource;
    [Test] procedure Reduce_FoldsLeft_FromSeed;
    [Test] procedure Reduce_EmptyList_ReturnsSeed;
    [Test] procedure Any_ShortCircuitsAndReturnsTrueWhenMatch;
    [Test] procedure All_ShortCircuitsAndReturnsFalseWhenAnyFails;
    [Test] procedure Count_CountsPredicateMatches;

    [Test]
    [TestCase('Take_Zero_Returns_Empty', '0')]
    [TestCase('Take_Two_Returns_Two', '2')]
    [TestCase('Take_Three_Returns_Three', '3')]
    [TestCase('Take_Ten_Returns_Three', '3')]
    procedure Take_ReturnsCorrectly(const aCount:integer);

    [Test]
    [TestCase('Take_Zero_Returns_Empty', '0')]
    [TestCase('Take_Two_Returns_Two', '2')]
    [TestCase('Take_Three_Returns_Three', '3')]
    [TestCase('Take_Ten_Returns_Three', '3')]
    procedure Skip_ReturnsCorrectly(const aCount:integer);

    [Test] procedure Test_TakeWhile;
    [Test] procedure Test_TakeUntil;
    [Test] procedure Test_Dispose;
    [Test] procedure Test_SkipWhile;
    [Test] procedure Test_SkipWhile_Eol;
    [Test] procedure Test_SkipUntil;
    [Test] procedure Test_SkipUntil_Eol;
  end;

implementation

uses
  Base.Integrity;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_SkipUntil;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create);
  src.AddRange([1,3,5,6,7]);

  var dst := scope.Owns(
    TCollect.SkipUntil<Integer>(
      src,
      function(const n: Integer): Boolean
      begin
        Result := (n mod 2) = 0;
      end
    )
  );

  Assert.AreEqual(2, dst.Count);
  Assert.AreEqual(6, dst[0]);
  Assert.AreEqual(7, dst[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_SkipUntil_Eol;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create);
  src.AddRange([1,3,5,6,7]);

  var dst := scope.Owns(
    TCollect.SkipUntil<Integer>(
      src,
      function(const n: Integer): Boolean
      begin
        Result := n = 8;
      end
    )
  );

  Assert.AreEqual(0, dst.Count);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_SkipWhile;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create);
  src.AddRange([1,3,4,5]);

  var dst := scope.Owns(
    TCollect.SkipWhile<Integer>(
      src,
      function(const n: Integer): Boolean
      begin
        Result := Odd(n);
      end
    )
  );

  Assert.AreEqual(2, dst.Count);
  Assert.AreEqual(4, dst[0]);
  Assert.AreEqual(5, dst[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_SkipWhile_Eol;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create);
  src.AddRange([1,3,4,5]);

  var dst := scope.Owns(
    TCollect.SkipWhile<Integer>(
      src,
      function(const n: Integer): Boolean
      begin
        Result := n <> 6;
      end
    )
  );

  Assert.AreEqual(0, dst.Count);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Skip_ReturnsCorrectly(const aCount:integer);
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create);
  src.AddRange([1,2,3]);

  var dst := scope.Owns(TCollect.Skip<Integer>(src, aCount));
  var n := src.Count - aCount;

  if n < 0 then n := 0;

  Assert.IsNotNull(dst);
  Assert.AreEqual(n, dst.Count);

  for var i := aCount to Pred(aCount) do
    Assert.AreEqual(src[i], dst[i]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_Dispose;
begin
  var list := TList<TList<Integer>>.Create;

  list.Add(TList<Integer>.Create);
  list.Add(TList<Integer>.Create);

  TCollect.Dispose<TList<Integer>>(list);

  Assert.IsNull(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Take_ReturnsCorrectly(const aCount:integer);
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create);

  src.AddRange([1,2,3]);

  var dst := scope.Owns(TCollect.Take<Integer>(src, aCount));

  Assert.IsNotNull(dst);
  Assert.AreEqual(aCount, dst.Count);

  for var i := 0 to Pred(aCount) do
    Assert.AreEqual(src[i], dst[i]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_TakeWhile;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create);

  src.AddRange([1,2,3]);

  var dst := scope.Owns(TCollect.TakeWhile<Integer>(src, function(const n:TInt):Boolean begin Result := Odd(n); end));

  Assert.AreEqual(2, dst.Count);
  Assert.AreEqual(1, dst[0]);
  Assert.AreEqual(3, dst[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_TakeUntil;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create);

  src.AddRange([1,3,5,6,7]);

  var dst := scope.Owns(TCollect.TakeUntil<TInt>(src, function(const n: TInt): Boolean begin Result := (n mod 2) = 0; end));

  Assert.AreEqual(3, dst.Count);

  Assert.AreEqual(1, dst[0]);
  Assert.AreEqual(3, dst[1]);
  Assert.AreEqual(5, dst[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Filter_PreservesOrder_AndDoesNotMutateSource;
var
  scope: TScope;
begin
  var s := scope.Owns(TList<TInt>.Create);

  s.AddRange([5, 2, 9, 2, 7, 4]);

  var r := scope.Owns(TCollect.Filter<TInt>(s, function(const x: TInt): Boolean begin Result := (x mod 2) = 0; end));

  // Result preserves original relative order: [2, 2, 4]
  Assert.AreEqual(3, r.Count);
  Assert.AreEqual(2, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(4, r[2]);

  // Source must be unchanged
  Assert.AreEqual(6, s.Count);
  Assert.AreEqual(5, s[0]);
  Assert.AreEqual(2, s[1]);
  Assert.AreEqual(9, s[2]);
  Assert.AreEqual(2, s[3]);
  Assert.AreEqual(7, s[4]);
  Assert.AreEqual(4, s[5]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Map_PreservesOrder_AndDoesNotMutateSource;
var
  scope: TScope;
begin
  var s := scope.Owns(TList<TInt>.Create);

  s.AddRange([3, 1, 4]);

  var r := scope.Owns(TCollect.Map<TInt, string>(s, function(const x: TInt): string begin Result := 'v' + x.ToString;end));

  Assert.AreEqual(3,    r.Count);
  Assert.AreEqual('v3', r[0]);
  Assert.AreEqual('v1', r[1]);
  Assert.AreEqual('v4', r[2]);

  // Source must be unchanged
  Assert.AreEqual(3, s.Count);
  Assert.AreEqual(3, s[0]);
  Assert.AreEqual(1, s[1]);
  Assert.AreEqual(4, s[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Sort_ReturnsSortedCopy_AndDoesNotMutateSource;
var
  scope: TScope;
begin
  var s := scope.Owns(TList<TInt>.Create);

  s.AddRange([3, 1, 2, 1]);

  var r := scope.Owns(TCollect.Sort<TInt>(s));

  // Sorted copy: [1, 1, 2, 3]
  Assert.AreEqual(4, r.Count);
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(1, r[1]);
  Assert.AreEqual(2, r[2]);
  Assert.AreEqual(3, r[3]);

  // Source unchanged
  Assert.AreEqual(4, s.Count);
  Assert.AreEqual(3, s[0]);
  Assert.AreEqual(1, s[1]);
  Assert.AreEqual(2, s[2]);
  Assert.AreEqual(1, s[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Reduce_FoldsLeft_FromSeed;
var
  scope: TScope;
begin
  var s := scope.Owns(TList<TInt>.Create);

  s.AddRange([1, 2, 3]);

  var sum := TCollect.Reduce<TInt, TInt>(s, 10, function(const acc, n: TInt): TInt begin Result := acc + n; end);

  Assert.AreEqual(16, sum);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Reduce_EmptyList_ReturnsSeed;
var
  scope: TScope;
begin
  var s := scope.Owns(TList<TInt>.Create);

  var r := TCollect.Reduce<TInt, TInt>(s, 42, function(const acc, n: TInt): TInt begin Result := acc + n; end);

  Assert.AreEqual(42, r);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Any_ShortCircuitsAndReturnsTrueWhenMatch;
var
  scope: TScope;
begin
  var s := scope.Owns(TList<TInt>.Create);

  s.AddRange([1, 2, 3, 4, 5]);

  var calls := 0;

  var found := TCollect.Any<TInt>(s,
      function(const x: TInt): Boolean
      begin
        Inc(calls);
        Result := x = 3;
      end);

  Assert.IsTrue(found);
  Assert.AreEqual(3, calls);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.All_ShortCircuitsAndReturnsFalseWhenAnyFails;
var
  scope: TScope;
begin
  var s := scope.Owns(TList<TInt>.Create);

  s.AddRange([2, 4, 6, 7, 8]);
  var calls := 0;

  var allEven := TCollect.All<TInt>(s,
    function(const x: TInt): Boolean
    begin
      Inc(Calls);
      Result := (x mod 2) = 0;
    end);

  Assert.IsFalse(allEven);
  Assert.AreEqual(4, calls);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Count_CountsPredicateMatches;
var
  scope: TScope;
begin
  var s := scope.Owns(TList<TInt>.Create);

  s.AddRange([1, 2, 3, 4, 5, 6]);

  var r := TCollect.Count<TInt>(s, function(const x: TInt): Boolean begin Result := (x mod 2) = 0;end);

  Assert.AreEqual(3, r);
end;


initialization
  TDUnitX.RegisterTestFixture(TCollectFixture);

end.


