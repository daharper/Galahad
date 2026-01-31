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
  end;

implementation

uses
  Base.Integrity;

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


