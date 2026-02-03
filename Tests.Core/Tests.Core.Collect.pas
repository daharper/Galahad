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
  TTestPair = TPair<Integer, Integer>;

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
    [Test] procedure Test_ToArray;
    [Test] procedure Test_ToObjectList;
    [Test] procedure Test_ToObjectDictionary;
    [Test] procedure Test_TakeLast;
    [Test] procedure Test_SkipLast;
    [Test] procedure Test_Distinct;
    [Test] procedure Test_DistinctBy;
    [Test] procedure Test_GroupBy;
    [Test] procedure Test_Partition;
    [Test] procedure Test_SplitAt;
    [Test] procedure Test_Span;
    [Test] procedure Test_Flatten;
    [Test] procedure Test_FlatMap;
    [Test] procedure Test_FirstOr;
    [Test] procedure Test_FirstOrDefault;
    [Test] procedure Test_LastOr;
    [Test] procedure Test_LastOrDefault;
    [Test] procedure Test_First_Maybe;
  end;

implementation

uses
  Base.Integrity;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_First_Maybe;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([2,4,5,6]));

  var m := TCollect.First<TInt>(src, function(const n: TInt): Boolean begin Result := Odd(n); end);

  Assert.IsTrue(m.IsSome);
  Assert.AreEqual(5, m.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_LastOrDefault;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([2,4,6]));

  var r := TCollect.LastOrDefault<TInt>(src, function(const n: TInt): Boolean begin Result := Odd(n); end);

  Assert.AreEqual(0, r);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_LastOr;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1,2,3,4,5]));

  var r := TCollect.LastOr<TInt>(src, function(const n: TInt): Boolean begin Result := Odd(n); end, -1);

  Assert.AreEqual(5, r);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_FirstOrDefault;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([2,4,6]));

  var r := TCollect.FirstOrDefault<TInt>(src, function(const n: TInt): Boolean begin Result := Odd(n); end);

  Assert.AreEqual(0, r);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_FirstOr;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([2,4,6]));

  var result := TCollect.FirstOr<Integer>(
    src,
    function(const n: Integer): Boolean begin Result := Odd(n); end,
    -1);

  Assert.AreEqual(-1, result);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_FlatMap;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1,2,3]));

  var dst := scope.Owns(
    TCollect.FlatMap<Integer, Integer>(
      src,
      procedure(const n: Integer; const outList: TList<Integer>)
      begin
        outList.Add(n);
        outList.Add(n * 10);
      end
    )
  );

  Assert.AreEqual(6, dst.Count);

  Assert.AreEqual(1, dst[0]);
  Assert.AreEqual(10, dst[1]);

  Assert.AreEqual(2, dst[2]);
  Assert.AreEqual(20, dst[3]);

  Assert.AreEqual(3, dst[4]);
  Assert.AreEqual(30, dst[5]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_Flatten;
var
  scope: TScope;
begin
  var a := scope.Owns(TList<Integer>.Create([1,2]));
  var b := scope.Owns(TList<Integer>.Create([3]));
  var c := scope.Owns(TList<Integer>.Create);

  var src := scope.Owns(TList<TList<Integer>>.Create);

  src.Add(a);
  src.Add(b);
  src.Add(nil);
  src.Add(c);

  var dst := scope.Owns(TCollect.Flatten<Integer>(src));

  Assert.AreEqual(3, dst.Count);
  Assert.AreEqual(1, dst[0]);
  Assert.AreEqual(2, dst[1]);
  Assert.AreEqual(3, dst[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_Span;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1,3,4,5,7]));

  var parts := TCollect.Span<Integer>(src, function(const n: Integer): Boolean begin Result := Odd(n); end);

  scope.Owns(parts.Prefix);
  scope.Owns(parts.Remainder);

  Assert.AreEqual(2, parts.Prefix.Count);
  Assert.AreEqual(1, parts.Prefix[0]);
  Assert.AreEqual(3, parts.Prefix[1]);

  Assert.AreEqual(3, parts.Remainder.Count);
  Assert.AreEqual(4, parts.Remainder[0]);
  Assert.AreEqual(5, parts.Remainder[1]);
  Assert.AreEqual(7, parts.Remainder[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_SplitAt;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create);
  src.AddRange([1,2,3,4,5]);

  var parts := TCollect.SplitAt<Integer>(src, 2);

  scope.Owns(parts.Left);
  scope.Owns(parts.Right);

  Assert.AreEqual(2, parts.Left.Count);
  Assert.AreEqual(1, parts.Left[0]);
  Assert.AreEqual(2, parts.Left[1]);

  Assert.AreEqual(3, parts.Right.Count);
  Assert.AreEqual(3, parts.Right[0]);
  Assert.AreEqual(4, parts.Right[1]);
  Assert.AreEqual(5, parts.Right[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_Partition;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1,2,3,4,5]));

  var parts := TCollect.Partition<Integer>(src, function(const n: TInt): Boolean begin Result := Odd(n); end);

  scope.Owns(parts.TrueList);
  scope.Owns(parts.FalseList);

  Assert.AreEqual(3, parts.TrueList.Count);
  Assert.AreEqual(1, parts.TrueList[0]);
  Assert.AreEqual(3, parts.TrueList[1]);
  Assert.AreEqual(5, parts.TrueList[2]);

  Assert.AreEqual(2, parts.FalseList.Count);
  Assert.AreEqual(2, parts.FalseList[0]);
  Assert.AreEqual(4, parts.FalseList[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_GroupBy;
var
  scope: TScope;
  g1, g2: TList<TTestPair>;
  p: TPair<Integer, Integer>;
begin
  var src := scope.Owns(TList<TTestPair>.Create);

  p.Key := 1; p.Value := 10; src.Add(p);
  p.Key := 2; p.Value := 20; src.Add(p);
  p.Key := 1; p.Value := 11; src.Add(p);

  var groups := TCollect.GroupBy<TTestPair, Integer>(
    src,
    function(const x: TTestPair): Integer begin Result := x.Key; end);

  scope.Owns(groups);
  scope.Defer(procedure begin for var g in groups do g.Value.Free; end);

  Assert.AreEqual(2, groups.Count);

  Assert.IsTrue(groups.TryGetValue(1, g1));
  Assert.AreEqual(2, g1.Count);
  Assert.AreEqual(10, g1[0].Value);
  Assert.AreEqual(11, g1[1].Value);

  Assert.IsTrue(groups.TryGetValue(2, g2));
  Assert.AreEqual(1, g2.Count);
  Assert.AreEqual(20, g2[0].Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_DistinctBy;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<TTestPair>.Create);

  src.Add(TTestPair.Create(1, 10));
  src.Add(TTestPair.Create(2, 20));
  src.Add(TTestPair.Create(1, 99));
  src.Add(TTestPair.Create(3, 30));

  var dst := TCollect.DistinctBy<TTestPair, Integer>(
      src,
      function(const p: TTestPair): Integer begin Result := p.Key; end);

  scope.Owns(dst);

  Assert.AreEqual(3, dst.Count);
  Assert.AreEqual(1, dst[0].Key);
  Assert.AreEqual(10, dst[0].Value);
  Assert.AreEqual(2, dst[1].Key);
  Assert.AreEqual(3, dst[2].Key);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_Distinct;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1,2,2,3,1,4]));
  var dst := scope.Owns(TCollect.Distinct<Integer>(src));

  Assert.AreEqual(4, dst.Count);
  Assert.AreEqual(1, dst[0]);
  Assert.AreEqual(2, dst[1]);
  Assert.AreEqual(3, dst[2]);
  Assert.AreEqual(4, dst[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_SkipLast;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1,2,3,4,5]));
  var dst := scope.Owns(TCollect.SkipLast<Integer>(src, 2));

  Assert.AreEqual(3, dst.Count);
  Assert.AreEqual(1, dst[0]);
  Assert.AreEqual(2, dst[1]);
  Assert.AreEqual(3, dst[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_TakeLast;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1,2,3,4,5]));
  var dst := scope.Owns(TCollect.TakeLast<Integer>(src, 2));

  Assert.AreEqual(2, dst.Count);
  Assert.AreEqual(4, dst[0]);
  Assert.AreEqual(5, dst[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_ToObjectDictionary;
var
  scope: TScope;
begin
  var src: TDictionary<Integer, TObject> := TDictionary<Integer, TObject>.Create;
  src.Add(1, TObject.Create);
  src.Add(2, TObject.Create);

  var dst := scope.Owns(TCollect.ToObjectDictionary<Integer, TObject>(src));

  Assert.IsNull(src);
  Assert.AreEqual(2, dst.Count);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_ToObjectList;
var
  scope: TScope;
begin
  var src := TList<TObject>.Create;

  src.Add(TObject.Create);
  src.Add(TObject.Create);

  var dst := scope.Owns(TCollect.ToObjectList<TObject>(src));

  Assert.AreEqual(2, dst.Count);
  Assert.IsFalse(Assigned(src));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Test_ToArray;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1, 2, 3, 4]));
  var arr := TCollect.ToArray<Integer>(TCollect.Skip<Integer>(src, 2));

  Assert.AreEqual(2, Length(arr));
  Assert.AreEqual(3, arr[0]);
  Assert.AreEqual(4, arr[1]);
end;

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


