unit Tests.Core.Stream;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DUnitX.TestFramework,
  Base.Core,
  Base.Stream;

type
  TFlagList = class(TList<Integer>)
  private
    FFlag: PBoolean;
  public
    constructor Create(AFlag: PBoolean);
    destructor Destroy; override;
  end;

  [TestFixture]
  TStreamFixture = class
  public
    [Test] procedure From_TakesOwnership_AndFreesContainerOnTransform;
    [Test] procedure Borrow_DoesNotFreeContainerOnTransform;
    [Test] procedure AsList_Borrowed_ClonesAndDoesNotTouchOriginal;
    [Test] procedure AsList_Owned_DetachesSameInstance;
    [Test] procedure Map_From_TakesOwnership_AndFreesContainer;
    [Test] procedure Map_Borrow_DoesNotFreeContainer;
    [Test] procedure Filter_Borrow_WithOnDiscard_Raises;
    [Test] procedure Map_Borrow_WithOnDiscard_Raises;
    [Test] procedure Distinct_PreservesFirstOccurrenceOrder;
    [Test] procedure Distinct_Borrow_WithOnDiscard_Raises;
    [Test] procedure ComparersAndEquality;
    [Test] procedure Count_From_FreesOwnedContainer;
    [Test] procedure Count_Borrow_DoesNotFreeContainer;
    [Test] procedure Any_ShortCircuits;
    [Test] procedure Any_Borrow_DoesNotFreeContainer;
    [Test] procedure All_ShortCircuitsOnFirstFailure;
    [Test] procedure All_Empty_ReturnsTrue;
    [Test] procedure Reduce_FoldsLeft_FromSeed;
    [Test] procedure Reduce_Empty_ReturnsSeed;
    [Test] procedure AsArray_PreservesOrder;
    [Test] procedure AsArray_Borrow_DoesNotFreeContainer;
    [Test] procedure ForEach_VisitsItemsInOrder_AndConsumes;
    [Test] procedure FirstOrDefault_Empty_ReturnsDefault;
    [Test] procedure LastOrDefault_NonEmpty_ReturnsLast;
    [Test] procedure LastOrDefault_Empty_ReturnsDefault;
    [Test] procedure Reverse_ReversesOrder;
    [Test] procedure Concat_Array_AppendsInOrder;
    [Test] procedure Concat_List_AppendsInOrder;
    [Test] procedure Concat_Enumerator_AppendsInOrder;
    [Test] procedure Concat_List_OwnsListTrue_FreesSourceContainer;
    [Test] procedure Take_Basic_KeepsFirstN;
    [Test] procedure Take_OnDiscard_Owned_CallsForDroppedItems;
    [Test] procedure Skip_Basic_SkipsFirstN;
    [Test] procedure Skip_OnDiscard_Owned_CallsForDroppedItems;
    [Test] procedure SkipWhile_SkipsLeadingMatchesOnly;
    [Test] procedure SkipWhile_OnDiscard_Owned_CallsForSkippedItems;
    [Test] procedure TakeWhile_TakesLeadingMatchesOnly;
    [Test] procedure TakeWhile_OnDiscard_Owned_CallsForDiscardedItems;
    [Test] procedure TakeLast_Basic_KeepsLastN;
    [Test] procedure TakeLast_OnDiscard_Owned_CallsForDiscardedPrefix;
  end;

implementation

uses
  Base.Integrity,
  Base.Collections;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Filter_Borrow_WithOnDiscard_Raises;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([1, 2, 3]);

  Assert.WillRaise(
    procedure
    begin
      scope.Owns(Stream
        .Borrow<Integer>(list)
        .Filter(
          function(const x: TInt): Boolean begin Result := True; end,
          procedure(const X: Integer) begin { disposal attempt } end)
        .AsList);
    end,
    EInvalidOpException,
    'Use Stream.From(list) or omit OnDiscard.');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Map_Borrow_WithOnDiscard_Raises;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([1, 2, 3]);

  Assert.WillRaise(
    procedure
    begin
      scope.Owns(Stream
        .Borrow<Integer>(list)
        .Map<Integer>(
          function(const x: TInt): TInt begin Result := x; end,
          procedure(const X: Integer) begin { disposal attempt } end)
        .AsList);
    end,
    EInvalidOpException,
    'Use Stream.From(list) or omit OnDiscard.');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.From_TakesOwnership_AndFreesContainerOnTransform;
var
  scope: TScope;
begin
  var freed := false;

  var list := TFlagList.Create(@freed);

  list.AddRange([1,2,3,4]);

  var r := Stream
    .From<Integer>(list)
    .Filter(function(const x:TInt): Boolean begin Result := (x mod 2) = 0; end)
    .AsList;

  scope.Owns(r);

  Assert.IsTrue(freed, 'Expected original list container to be freed after first transform');

  Assert.AreEqual(2, r.Count);
  Assert.AreEqual(2, r[0]);
  Assert.AreEqual(4, r[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Map_Borrow_DoesNotFreeContainer;
var
  scope: TScope;
begin
  var freed := false;

  var list := scope.Owns(TFlagList.Create(@freed));

  list.AddRange([10, 20, 30]);

  var r := Stream.Borrow<Integer>(list)
      .Map<TInt>(function(const X: TInt): TInt begin Result := X + 1; end)
      .AsList;

  scope.Owns(r);

  Assert.IsFalse(Freed, 'Borrowed list container must not be freed during Map');

  Assert.AreEqual(3, r.Count);
  Assert.AreEqual(11, r[0]);
  Assert.AreEqual(21, r[1]);
  Assert.AreEqual(31, r[2]);

  Assert.AreEqual(3, list.Count);
  Assert.AreEqual(10, list[0]);
  Assert.AreEqual(20, list[1]);
  Assert.AreEqual(30, list[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Map_From_TakesOwnership_AndFreesContainer;
var
  scope: TScope;
begin
  var freed := false;

  var list := TFlagList.Create(@freed);

  list.AddRange([1, 2, 3]);

  var r := Stream
    .From<Integer>(list)
    .Map<string>(function(const X: TInt): string begin Result := 'v' + X.ToString; end)
    .AsList;

  scope.Owns(r);

  Assert.IsTrue(freed, 'Expected original list container to be freed during Map');

  Assert.AreEqual(3, r.Count);
  Assert.AreEqual('v1', r[0]);
  Assert.AreEqual('v2', r[1]);
  Assert.AreEqual('v3', r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Distinct_Borrow_WithOnDiscard_Raises;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([1, 1, 2]);

  Assert.WillRaise(
    procedure
    begin
      scope.Owns(Stream
        .Borrow<Integer>(list)
        .Distinct(nil, procedure(const x: TInt) begin { disposal attempt } end)
        .AsList);
    end,
    EInvalidOpException,
    'Use Stream.From(list) or omit OnDiscard.');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Distinct_PreservesFirstOccurrenceOrder;
begin
  var r := Stream.From<Integer>([3, 1, 3, 2, 1, 2, 4]).Distinct.AsList;
  try
    Assert.AreEqual(4, r.Count);
    Assert.AreEqual(3, r[0]);
    Assert.AreEqual(1, r[1]);
    Assert.AreEqual(2, r[2]);
    Assert.AreEqual(4, r[3]);
  finally
    r.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Borrow_DoesNotFreeContainerOnTransform;
var
  scope: TScope;
begin
  var freed := false;

  var list := scope.Owns(TFlagList.Create(@freed));

  list.AddRange([1,2,3,4]);

  var r := Stream
      .Borrow<Integer>(list)
      .Filter(function(const x: TInt): Boolean begin Result := x > 2;end)
      .AsList;

  scope.Owns(r);

  Assert.IsFalse(Freed, 'Borrowed list container must not be freed by Stream');

  Assert.AreEqual(2, r.Count);
  Assert.AreEqual(3, r[0]);
  Assert.AreEqual(4, r[1]);

  Assert.AreEqual(4, list.Count);
  Assert.AreEqual(1, list[0]);
  Assert.AreEqual(2, list[1]);
  Assert.AreEqual(3, list[2]);
  Assert.AreEqual(4, list[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.AsList_Borrowed_ClonesAndDoesNotTouchOriginal;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 20, 30]);

  var r := scope.Owns(Stream.Borrow<Integer>(list).AsList);

  Assert.IsTrue(r <> list, 'Borrowed AsList must return a clone');

  Assert.AreEqual(3, r.Count);
  Assert.AreEqual(10, r[0]);
  Assert.AreEqual(20, r[1]);
  Assert.AreEqual(30, r[2]);

  r.Add(40);

  Assert.AreEqual(3, list.Count);
  Assert.AreEqual(4, r.Count);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.AsList_Owned_DetachesSameInstance;
var
  scope: TScope;
begin
  var list := TList<Integer>.Create;

  list.AddRange([1,2,3]);

  var r := scope.Owns(Stream.From<Integer>(list).AsList);

  Assert.AreSame(list, R);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.ComparersAndEquality;
var
  scope: TScope;
begin
  var l1 := scope.Owns(Stream
    .From<string>(['A', 'a', 'B', 'b', 'B'])
    .Distinct(Equality.StringIgnoreCase)
    .AsList);

  Assert.AreEqual(2, l1.Count);
  Assert.AreEqual('A', l1[0]);
  Assert.AreEqual('B', l1[1]);

  var l2 := scope.Owns(Stream
    .From<Integer>([3, 1, 2, 2])
    .Sort(Comparers.Descending<Integer>)
    .AsList);

  Assert.AreEqual(4, l2.Count);
  Assert.AreEqual(3, l2[0]);
  Assert.AreEqual(2, l2[1]);
  Assert.AreEqual(2, l2[2]);
  Assert.AreEqual(1, l2[3]);

  var l3 := scope.Owns(Stream
    .From<string>(['b', 'A', 'a', 'C'])
    .Sort(Comparers.Descending<string>(Comparers.StringIgnoreCase))
    .AsList);

  Assert.AreEqual(4, l3.Count);
  Assert.AreEqual('C', l3[0]);
  Assert.AreEqual('b', l3[1]);
  Assert.IsTrue((l3[2] = 'A') or (l3[2] = 'a'));
  Assert.IsTrue((l3[3] = 'A') or (l3[3] = 'a'));
  Assert.AreEqual(l3[2], l3[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Count_From_FreesOwnedContainer;
begin
  var freed := false;

  var lList := TFlagList.Create(@Freed);
  lList.AddRange([1, 2, 3]);

  var n := Stream.From<Integer>(lList).Count;

  Assert.AreEqual(3, n);
  Assert.IsTrue(Freed, 'Expected owned list container to be freed by Count terminal');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Count_Borrow_DoesNotFreeContainer;
var
  scope: TScope;
begin
  var freed := False;

  var lList := scope.Owns(TFlagList.Create(@Freed));

  lList.AddRange([1, 2, 3]);

  var n := Stream.Borrow<Integer>(lList).Count;

  Assert.AreEqual(3, n);
  Assert.IsFalse(Freed, 'Borrowed list container must not be freed by Count terminal');

  Assert.AreEqual(3, lList.Count);
  Assert.AreEqual(1, lList[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Any_ShortCircuits;
begin
  var calls := 0;

  var found := Stream
    .From<Integer>([1, 2, 3, 4, 5])
    .Any(function(const X: TInt): Boolean begin Inc(calls); Result := X = 3; end);

  Assert.IsTrue(found);

  Assert.AreEqual(3, calls);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Any_Borrow_DoesNotFreeContainer;
var
  scope: TScope;
begin
  var freed := False;

  var lList := scope.Owns(TFlagList.Create(@Freed));

  lList.AddRange([1, 2, 3]);

  var found := Stream
    .Borrow<Integer>(lList)
    .Any(function(const X: TInt): Boolean begin Result := X = 2; end);

  Assert.IsTrue(found);
  Assert.IsFalse(freed, 'Borrowed list container must not be freed by Any terminal');

  Assert.AreEqual(3, lList.Count);
  Assert.AreEqual(1, lList[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.All_ShortCircuitsOnFirstFailure;
begin
  var calls := 0;

  var ok := Stream
    .From<Integer>([2, 4, 6, 7, 8])
    .All(function(const X: TInt): Boolean begin Inc(Calls); Result := (X mod 2) = 0; end);

  Assert.IsFalse(Ok);
  Assert.AreEqual(4, Calls);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.All_Empty_ReturnsTrue;
begin
  var list := TList<Integer>.Create;

  var ok := Stream
    .From<Integer>(list)
    .All(function(const X: TInt): Boolean begin Result := X > 0; end);

  Assert.IsTrue(Ok);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Reduce_FoldsLeft_FromSeed;
begin
  var sum := Stream
    .From<Integer>([1, 2, 3])
    .Reduce<Integer>(10, function(const Acc, N: TInt): TInt begin Result := Acc + N; end);

  Assert.AreEqual(16, Sum);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Reduce_Empty_ReturnsSeed;
begin
  var lList := TList<Integer>.Create;

  var r := Stream
    .From<Integer>(lList)
    .Reduce<Integer>(42, function(const Acc, N: TInt): TInt begin Result := Acc + N; end);

  Assert.AreEqual(42, r);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.AsArray_PreservesOrder;
begin
  var a := Stream.From<Integer>([5, 2, 9]).AsArray;

  Assert.AreEqual(3, Length(a));
  Assert.AreEqual(5, a[0]);
  Assert.AreEqual(2, a[1]);
  Assert.AreEqual(9, a[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.AsArray_Borrow_DoesNotFreeContainer;
var
  scope: TScope;
begin
  var freed := False;

  var list := scope.Owns(TFlagList.Create(@Freed));

  list.AddRange([1, 2, 3]);

  var a := Stream.Borrow<Integer>(list).AsArray;

  Assert.AreEqual(3, Length(a));
  Assert.AreEqual(1, a[0]);
  Assert.AreEqual(2, a[1]);
  Assert.AreEqual(3, a[2]);

  Assert.IsFalse(freed, 'Borrowed list container must not be freed by AsArray terminal');
  Assert.AreEqual(3, list.Count);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.ForEach_VisitsItemsInOrder_AndConsumes;
var
  scope: TScope;
begin
  var seen := scope.Owns(TList<Integer>.Create);

  Stream
    .From<Integer>([3, 1, 4])
    .ForEach(procedure(const x: TInt) begin Seen.Add(x); end);

  Assert.AreEqual(3, seen.Count);
  Assert.AreEqual(3, seen[0]);
  Assert.AreEqual(1, seen[1]);
  Assert.AreEqual(4, seen[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.FirstOrDefault_Empty_ReturnsDefault;
begin
  var list := TList<Integer>.Create;
  var val  := Stream.From<Integer>(list).FirstOrDefault;

  Assert.AreEqual(0, val);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.LastOrDefault_NonEmpty_ReturnsLast;
begin
  var v := Stream.From<Integer>([5, 9, 1]).LastOrDefault;
  Assert.AreEqual(1, v);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.LastOrDefault_Empty_ReturnsDefault;
begin
  var l := TList<Integer>.Create;
  var v := Stream.From<Integer>(l).LastOrDefault;
  Assert.AreEqual(0, v);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Reverse_ReversesOrder;
begin
  var r := Stream.From<Integer>([1, 2, 3, 4]).Reverse.AsArray;

  Assert.AreEqual(4, Length(r));
  Assert.AreEqual(4, r[0]);
  Assert.AreEqual(3, r[1]);
  Assert.AreEqual(2, r[2]);
  Assert.AreEqual(1, r[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Concat_Array_AppendsInOrder;
begin
  var r := Stream.From<Integer>([1, 2]).Concat([3, 4]).AsArray;

  Assert.AreEqual(4, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Concat_List_AppendsInOrder;
var
  scope: TScope;
begin
  var extra := scope.Owns(TList<Integer>.Create);

  extra.AddRange([3, 4]);

  var r := Stream.From<Integer>([1, 2]).Concat(Extra, false).AsArray;

  Assert.AreEqual(4, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Concat_Enumerator_AppendsInOrder;
var
  scope: TScope;
begin
  var extra := scope.Owns(TList<Integer>.Create);

  extra.AddRange([3, 4]);

  var e := Extra.GetEnumerator;

  var r := Stream.From<Integer>([1, 2]).Concat(E, True).AsArray;

  Assert.AreEqual(4, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Concat_List_OwnsListTrue_FreesSourceContainer;
begin
  var freed := false;
  var extra := TFlagList.Create(@freed);

  extra.AddRange([3, 4]);

  var r := Stream.From<Integer>([1, 2]).Concat(extra, true).AsArray;

  Assert.IsTrue(freed, 'Expected concat source list container to be freed when OwnsList=True');
  Assert.AreEqual(4, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Take_Basic_KeepsFirstN;
begin
  var r := Stream.From<Integer>([1, 2, 3, 4, 5]).Take(3).AsArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Take_OnDiscard_Owned_CallsForDroppedItems;
var
  scope: TScope;
begin
  var dropped := scope.Owns(TList<Integer>.Create);

  var r := Stream
    .From<Integer>([1, 2, 3, 4, 5])
    .Take(2, procedure(const x: TInt) begin Dropped.Add(x); end).AsArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);

  Assert.AreEqual(3, dropped.Count);
  Assert.AreEqual(3, dropped[0]);
  Assert.AreEqual(4, dropped[1]);
  Assert.AreEqual(5, dropped[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Skip_Basic_SkipsFirstN;
begin
  var r := Stream.From<Integer>([1, 2, 3, 4, 5]).Skip(2).AsArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(3, r[0]);
  Assert.AreEqual(4, r[1]);
  Assert.AreEqual(5, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Skip_OnDiscard_Owned_CallsForDroppedItems;
var
  scope: TScope;
begin
  var dropped := scope.Owns(TList<Integer>.Create);

  var r := Stream
    .From<Integer>([1, 2, 3, 4, 5])
    .Skip(3, procedure(const x: TInt) begin dropped.Add(x); end)
    .AsArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(4, r[0]);
  Assert.AreEqual(5, r[1]);

  Assert.AreEqual(3, dropped.Count);
  Assert.AreEqual(1, dropped[0]);
  Assert.AreEqual(2, dropped[1]);
  Assert.AreEqual(3, dropped[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.SkipWhile_SkipsLeadingMatchesOnly;
begin
  var r := Stream
    .From<Integer>([1, 2, 3, 1, 4])
    .SkipWhile(function(const x: TInt): Boolean begin Result := x < 3; end)
    .AsArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(3, r[0]);
  Assert.AreEqual(1, r[1]);
  Assert.AreEqual(4, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.SkipWhile_OnDiscard_Owned_CallsForSkippedItems;
var
  scope: TScope;
begin
  var dropped := scope.Owns(TList<Integer>.Create);

  var r := Stream
      .From<Integer>([1, 2, 3, 4])
      .SkipWhile(
          function(const x: TInt): Boolean begin Result := x < 3; end,
          procedure(const X: TInt) begin dropped.Add(x); end)
      .AsArray;

  Assert.AreEqual(2, Length(R));
  Assert.AreEqual(3, r[0]);
  Assert.AreEqual(4, r[1]);

  Assert.AreEqual(2, dropped.Count);
  Assert.AreEqual(1, dropped[0]);
  Assert.AreEqual(2, dropped[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.TakeWhile_TakesLeadingMatchesOnly;
begin
  var r := Stream
    .From<Integer>([1, 2, 3, 1, 4])
    .TakeWhile(function(const x: TInt): Boolean begin Result := x < 3;end)
    .AsArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.TakeWhile_OnDiscard_Owned_CallsForDiscardedItems;
var
  scope: TScope;
begin
  var dropped := scope.Owns(TList<Integer>.Create);

  var r := Stream
      .From<Integer>([1, 2, 3, 4])
      .TakeWhile(
          function(const x: TInt): Boolean begin Result := x < 3; end,
          procedure(const x: TInt) begin dropped.Add(x); end)
      .AsArray;

  Assert.AreEqual(2, Length(R));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);

  Assert.AreEqual(2, dropped.Count);
  Assert.AreEqual(3, dropped[0]);
  Assert.AreEqual(4, dropped[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.TakeLast_Basic_KeepsLastN;
begin
  var r := Stream.From<Integer>([1, 2, 3, 4, 5]).TakeLast(2).AsArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(4, r[0]);
  Assert.AreEqual(5, r[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.TakeLast_OnDiscard_Owned_CallsForDiscardedPrefix;
var
  scope: TScope;
begin
  var dropped := scope.Owns(TList<Integer>.Create);

  var r := Stream
      .From<Integer>([1, 2, 3, 4, 5])
      .TakeLast(2, procedure(const x: Integer) begin dropped.Add(X); end)
      .AsArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(4, r[0]);
  Assert.AreEqual(5, r[1]);

  Assert.AreEqual(3, dropped.Count);
  Assert.AreEqual(1, dropped[0]);
  Assert.AreEqual(2, dropped[1]);
  Assert.AreEqual(3, dropped[2]);
end;

{ TFlagList }

{----------------------------------------------------------------------------------------------------------------------}
constructor TFlagList.Create(AFlag: PBoolean);
begin
  inherited Create;
  FFlag := AFlag;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TFlagList.Destroy;
begin
  if Assigned(FFlag) then
    FFlag^ := True;

  inherited;
end;

initialization
  TDUnitX.RegisterTestFixture(TStreamFixture);

end.
