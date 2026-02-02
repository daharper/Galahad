unit Base.Collections;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Base.Core;

type
  /// <summary>
  /// Predefined IComparer<T> helpers (mostly thin wrappers over RTL singletons).
  /// </summary>
  Comparers = record
  strict private
    type
      TDescendingComparer<T> = class(TInterfacedObject, IComparer<T>)
      private
        fBase: IComparer<T>;
      public
        constructor Create(const ABase: IComparer<T>);
        function Compare(const aLeft, aRight: T): Integer;
      end;
  public
    /// <summary>Default comparer for T (TComparer&lt;T&gt;.Default).</summary>
    class function Default<T>: IComparer<T>; static;

    /// <summary>
    /// Returns a comparer that reverses the given comparer. If Base is nil, uses TComparer&lt;T&gt;.Default.
    /// </summary>
    class function Descending<T>(const aBase: IComparer<T> = nil): IComparer<T>; static;

    /// <summary>
    /// Case-insensitive, ordinal string comparer (RTL TIStringComparer.Ordinal).
    /// Suitable for Sort(...) and other ordering operations.
    /// </summary>
    class function StringIgnoreCase: IComparer<string>; static;

    /// <summary>
    /// Case-sensitive, ordinal string comparer (RTL TStringComparer.Ordinal).
    /// </summary>
    class function StringOrdinal: IComparer<string>; static;
  end;

  /// <summary>
  /// Predefined IEqualityComparer<T> helpers (mostly thin wrappers over RTL singletons).
  /// </summary>
  Equality = record
  public
    /// <summary>Default equality comparer for T (TEqualityComparer&lt;T&gt;.Default).</summary>
    class function Default<T>: IEqualityComparer<T>; static;

    /// <summary>
    /// Case-insensitive, ordinal string equality comparer (RTL TIStringComparer.Ordinal).
    /// Suitable for Distinct(...), dictionaries, sets.
    /// </summary>
    class function StringIgnoreCase: IEqualityComparer<string>; static;

    /// <summary>
    /// Case-sensitive, ordinal string equality comparer (RTL TStringComparer.Ordinal).
    /// </summary>
    class function StringOrdinal: IEqualityComparer<string>; static;
  end;

  /// <summary>
  /// Stateless collection algorithms.
  ///
  /// Ownership contract:
  /// - Never mutates the input list.
  /// - Never frees items.
  /// - Any returned list is newly allocated and caller-owned.
  /// - The Dispose and ToArray utility functions being the exceptions.
  /// </summary>
  TCollect = class sealed
  public
    /// <summary>
    /// Copies list contents to a dynamic array, then frees the list.
    /// Does NOT free any items (even if T is a class).
    /// Accepts temporaries, so it can be used at the end of a pipeline.
    /// </summary>
    class function ToArray<T>(const aList: TList<T>): TArray<T>; static;

    /// <summary>
    /// Converts a TList<T> into a TObjectList<T> that owns its items.
    /// Transfers item references, frees the source list.
    /// </summary>
    class function ToObjectList<T: class>(var aList: TList<T>; const aOwnsObjects: Boolean = True): TObjectList<T>; static;

    /// <summary>
    /// Converts a TDictionary to a TObjectDictionary, transferring entries and consuming the source.
    /// Frees aDict and sets it to nil. Does not clone keys/values.
    /// Default ownership: owns values.
    /// </summary>
    class function ToObjectDictionary<TKey; TValue: class>(
      var aDict: TDictionary<TKey, TValue>;
      const aOwnerships: TDictionaryOwnerships = [doOwnsValues]
    ): TObjectDictionary<TKey, TValue>; static;

    /// <summary>
    /// Disposes a list that owns its items.
    /// Frees each item (if T is a class), then frees the list and sets it to nil.
    /// </summary>
    class procedure Dispose<T: class>(var aSource: TList<T>); static;

    /// <summary>
    /// Returns a new list containing the first aCount items from Source (or fewer if Source is shorter).
    /// Stable order. Never mutates Source.
    /// </summary>
    class function Take<T>(const aSource: TList<T>; const aCount: Integer): TList<T>; static;

    /// <summary>
    /// Returns a new list containing items from Source while Predicate(Item) is True.
    /// Stops at the first False (short-circuit).
    /// Stable order. Never mutates Source.
    /// </summary>
    class function TakeWhile<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TList<T>; static;

    /// <summary>
    /// Returns a new list containing items from Source until Predicate(Item) becomes True.
    /// The first item that satisfies Predicate is NOT included.
    /// Stops at the first True (short-circuit).
    /// Stable order. Never mutates Source.
    /// </summary>
    class function TakeUntil<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TList<T>; static;

    /// <summary>
    /// Returns a new list containing the last aCount items from Source (or fewer if Source is shorter).
    /// Order is preserved (stable).
    /// </summary>
    class function TakeLast<T>(const aSource: TList<T>; const aCount: Integer): TList<T>; static;

    /// <summary>
    /// Returns a new list containing items from Source after skipping the first aCount items.
    /// Stable order. Never mutates Source.
    /// </summary>
    class function Skip<T>(const aSource: TList<T>; const aCount: Integer): TList<T>; static;

    /// <summary>
    /// Returns a new list containing items from Source after skipping leading items
    /// while Predicate(Item) is True. Once Predicate is False, remaining items are included.
    /// Stable order. Never mutates Source.
    /// </summary>
    class function SkipWhile<T>(const aSource: TList<T>;const aPredicate: TConstPredicate<T>): TList<T>; static;

    /// <summary>
    /// Returns a new list containing items from Source starting at the first item
    /// for which Predicate(Item) is True (that item IS included), plus all remaining items.
    /// If no item satisfies Predicate, returns empty list.
    /// Stable order. Never mutates Source.
    /// </summary>
    class function SkipUntil<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TList<T>; static;

    /// <summary>
    /// Returns a new list containing items from Source except the last aCount items.
    /// Order is preserved (stable).
    /// </summary>
    class function SkipLast<T>(const aSource: TList<T>; const aCount: Integer): TList<T>; static;

    /// <summary>
    /// Returns a new list containing items from Source that satisfy Predicate.
    /// Order is preserved (stable w.r.t. the source order).
    /// </summary>
    class function Filter<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TList<T>; static;

    /// <summary>
    /// Returns a new list containing the distinct items from Source (stable, keeps first occurrence).
    /// If aComparer is nil, the default equality comparer for T is used.
    /// </summary>
    class function Distinct<T>(const aSource: TList<T>; const aComparer: IEqualityComparer<T> = nil): TList<T>; static;

    /// <summary>
    /// Returns a new list containing items from Source, keeping only the first item for each distinct key.
    /// Order is preserved (stable).
    /// If aComparer is nil, the default equality comparer for TKey is used.
    /// </summary>
    class function DistinctBy<T, TKey>(
      const aSource: TList<T>;
      const aKeySelector: TConstFunc<T, TKey>;
      const aComparer: IEqualityComparer<TKey> = nil
    ): TList<T>; static;

    /// <summary>
    /// Groups items by key. Returns a new dictionary mapping each key to a new list of items.
    /// Order within each group is preserved (stable w.r.t. Source order).
    /// If aComparer is nil, the default equality comparer for TKey is used.
    /// Caller owns the dictionary and all lists stored as values.
    /// </summary>
    class function GroupBy<T, TKey>(
      const aSource: TList<T>;
      const aKeySelector: TConstFunc<T, TKey>;
      const aComparer: IEqualityComparer<TKey> = nil
    ): TDictionary<TKey, TList<T>>; static;

    /// <summary>
    /// Returns a new list containing Mapper(Source[i]) for all i in source order.
    /// Order is preserved.
    /// </summary>
    class function Map<T, U>(const aSource: TList<T>; const aMapper: TConstFunc<T, U>): TList<U>; static;

    /// <summary>
    /// Returns a new list that is a sorted copy of Source using the default comparer.
    /// </summary>
    class function Sort<T>(const aSource: TList<T>): TList<T>; overload; static;

    /// <summary>
    /// Returns a new list that is a sorted copy of Source using the provided comparer.
    /// </summary>
    class function Sort<T>(const aSource: TList<T>; const aComparer: IComparer<T>): TList<T>; overload; static;

    /// <summary>
    /// Returns a new list that is a sorted copy of Source using the provided comparison.
    /// </summary>
    class function Sort<T>(const aSource: TList<T>; const aComparison: TComparison<T>): TList<T>; overload; static;

    /// <summary>
    /// Fold-left / reduce with seed.
    /// Acc := Seed; for each item in Source order: Acc := Reducer(Acc, Item);
    /// Empty list returns Seed.
    /// </summary>
    class function Reduce<TItem, TAcc>(const aSource: TList<TItem>; const aSeed: TAcc; const aReducer: TConstFunc<TAcc, TItem, TAcc>): TAcc; static;

    /// <summary>Returns True if any item satisfies Predicate (short-circuit).</summary>
    class function Any<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): Boolean; static;

    /// <summary>Returns True if all items satisfy Predicate (short-circuit).</summary>
    class function All<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): Boolean; static;

    /// <summary>Counts items that satisfy Predicate.</summary>
    class function Count<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): Integer; static;
  end;

implementation

uses
  Base.Integrity;

{ TCollect }

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.All<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): Boolean;
var
  i: integer;
begin
  Ensure.IsAssigned(aSource, 'Source is nil').IsAssigned(@aPredicate, 'Predicate is nil');

  for i := 0 to Pred(aSource.Count) do
    if not aPredicate(aSource[i]) then
      Exit(false);

  Result := True;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Any<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): Boolean;
var
  i: Integer;
begin
  Ensure.IsAssigned(aSource, 'Source is nil').IsAssigned(@aPredicate, 'Predicate is nil');

  for i := 0 to Pred(aSource.Count) do
    if aPredicate(aSource[i]) then
      Exit(true);

  Result := False;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Count<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): Integer;
var
  i: Integer;
begin
  Ensure.IsAssigned(aSource, 'Source is nil').IsAssigned(@aPredicate, 'Predicate is nil');

  Result := 0;

  for I := 0 to Pred(aSource.Count) do
    if aPredicate(aSource[i]) then
      Inc(Result);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Filter<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TList<T>;
var
  i: Integer;
  lItem: T;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  Result := TList<T>.Create;

  try
    Result.Capacity := aSource.Count;

    for i := 0 to Pred(aSource.Count) do
    begin
      lItem := aSource[i];

      if aPredicate(lItem) then
        Result.Add(lItem);
    end;

  except
    on e: Exception do
    begin
      Result.Free;
      TError.Throw(e);
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Distinct<T>(const aSource: TList<T>; const aComparer: IEqualityComparer<T>): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil');

  var cmp := if Assigned(aComparer) then aComparer else TEqualityComparer<T>.Default;

  var list := scope.Owns(TList<T>.Create);
  var seen := scope.Owns(TDictionary<T, Byte>.Create(cmp));

  list.Capacity := aSource.Count;

  for var item in aSource do
  begin
    if not seen.ContainsKey(item) then
    begin
      seen.Add(item, 0);
      list.Add(item);
    end;
  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.DistinctBy<T, TKey>(
  const aSource: TList<T>;
  const aKeySelector: TConstFunc<T, TKey>;
  const aComparer: IEqualityComparer<TKey>
): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aKeySelector, 'KeySelector is nil');

  var cmp := if Assigned(aComparer) then aComparer else TEqualityComparer<TKey>.Default;

  var list := scope.Owns(TList<T>.Create);
  var seen := scope.Owns(TDictionary<TKey, Byte>.Create(cmp));

  list.Capacity := aSource.Count;

  for var item in aSource do
  begin
    var key := aKeySelector(item);

    if not seen.ContainsKey(key) then
    begin
      seen.Add(key, 0);
      list.Add(item);
    end;
  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.GroupBy<T, TKey>(
  const aSource: TList<T>;
  const aKeySelector: TConstFunc<T, TKey>;
  const aComparer: IEqualityComparer<TKey>
): TDictionary<TKey, TList<T>>;
var
  group: TList<T>;
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aKeySelector, 'KeySelector is nil');

  var cmp := if Assigned(aComparer) then aComparer else TEqualityComparer<TKey>.Default;
  var map := scope.Owns(TDictionary<TKey, TList<T>>.Create(cmp));

  try
    for var item in aSource do
    begin
      var key := aKeySelector(item);

      if not map.TryGetValue(key, group) then
      begin
        group := TList<T>.Create;
        map.Add(key, group);
      end;

      group.Add(item);
    end;
  except
    on E:Exception do
    begin
      for var pair in map do
        pair.Value.Free;

      TError.Throw(E);
    end;
  end;

  Result := scope.Release(map);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Map<T, U>(const aSource: TList<T>; const aMapper: TConstFunc<T, U>): TList<U>;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aMapper, 'Mapper is nil');

  Result := TList<U>.Create;

  try
    Result.Capacity := aSource.Count;

    for var i := 0 to Pred(aSource.Count) do
      Result.Add(aMapper(aSource[i]));

  except
    on e: Exception do
    begin
      Result.Free;
      TError.Throw(e);
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Reduce<TItem, TAcc>(const aSource: TList<TItem>; const aSeed: TAcc; const aReducer: TConstFunc<TAcc, TItem, TAcc>): TAcc;
var
  i: Integer;
  lAcc: TAcc;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aReducer, 'Mapper is nil');

  lAcc := aSeed;

  for i := 0 to Pred(aSource.Count) do
    lAcc := aReducer(lAcc, aSource[i]);

  Result := lAcc;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Sort<T>(const aSource: TList<T>; const aComparer: IComparer<T>): TList<T>;
var
  i: Integer;
begin
  Ensure.IsAssigned(aSource, 'Source is nil');

  Result := TList<T>.Create;

  try
    Result.Capacity := aSource.Count;

    for i := 0 to Pred(aSource.Count) do
      Result.Add(aSource[i]);

    if not Assigned(aComparer) then
      Result.Sort
    else
      Result.Sort(aComparer);

  except
    on e: Exception do
    begin
      Result.Free;
      TError.Throw(e);
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Sort<T>(const aSource: TList<T>; const aComparison: TComparison<T>): TList<T>;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aComparison, 'Comparison is nil');

  Result := Sort<T>(aSource, TComparer<T>.Construct(aComparison));
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TCollect.Dispose<T>(var aSource: TList<T>);
begin
  if aSource = nil then exit;

  for var item in aSource do
    item.Free;

  aSource.Free;
  aSource := nil;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.ToArray<T>(const aList: TList<T>): TArray<T>;
var
  scope: TScope;
begin
  scope.Owns(aList);

  if aList = nil then exit(nil);

  Result := aList.ToArray;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.ToObjectList<T>(var aList: TList<T>; const aOwnsObjects: Boolean): TObjectList<T>;
begin
  Result := TObjectList<T>.Create(aOwnsObjects);

  if aList = nil then exit;

  try
    Result.Capacity := aList.Count;
    Result.AddRange(aList);
  finally
    aList.Free;
    aList := nil;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.ToObjectDictionary<TKey; TValue>(
  var aDict: TDictionary<TKey, TValue>;
  const aOwnerships: TDictionaryOwnerships
): TObjectDictionary<TKey, TValue>;
var
  pair: TPair<TKey, TValue>;
begin
  Result := TObjectDictionary<TKey, TValue>.Create(aOwnerships);

  if aDict = nil then exit;

  try
    Result.Capacity := aDict.Count;

    for pair in aDict do
      Result.Add(pair.Key, pair.Value);
  finally
    aDict.Free;
    aDict := nil;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Take<T>(const aSource: TList<T>; const aCount: Integer): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsTrue(aCount >= 0, 'Count must be >= 0');

  var list := scope.Owns(TList<T>.Create);

  var n := if aCount > aSource.Count then aSource.Count else aCount;

  list.Capacity := n;

  for var i := 0 to Pred(n) do
    list.Add(aSource[i]);

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.TakeWhile<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  var list := scope.Owns(TList<T>.Create);

  for var item in aSource do
    if aPredicate(item) then
      list.Add(item);

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.TakeUntil<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  var list := scope.Owns(TList<T>.Create);

  for var item in aSource do
  begin
    if aPredicate(item) then break;
    list.Add(item);
  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.TakeLast<T>(const aSource: TList<T>; const aCount: Integer): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsTrue(aCount >= 0, 'Count must be >= 0');

  var list := scope.Owns(TList<T>.Create);

  if aCount >= aSource.Count then
  begin
    list.Capacity := aSource.Count;
    list.AddRange(aSource);
  end
  else
  begin
    list.Capacity := aCount;

    var startIdx := aSource.Count - aCount;

    for var i := startIdx to Pred(aSource.Count) do
      list.Add(aSource[i]);
  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Skip<T>(const aSource: TList<T>; const aCount: Integer): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsTrue(aCount >= 0, 'Count must be >= 0');

  var list := scope.Owns(TList<T>.Create);

  if aCount < aSource.Count then
  begin
    list.Capacity := aSource.Count - aCount;

    for var i := aCount to Pred(aSource.Count) do
      list.Add(aSource[i]);
  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.SkipWhile<T>(const aSource: TList<T>;const aPredicate: TConstPredicate<T>): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  var list := scope.Owns(TList<T>.Create);
  var startIdx := 0;

  for var item in aSource do
  begin
    if not aPredicate(item) then break;
    Inc(startIdx);
  end;

  if startIdx < aSource.Count then
  begin
    list.Capacity := aSource.Count - startIdx;

    for var i := startIdx to Pred(aSource.Count) do
      list.Add(aSource[i]);
  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.SkipUntil<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  var list := scope.Owns(TList<T>.Create);

  var startIdx := aSource.Count;

  for var i := 0 to Pred(aSource.Count - 1) do
    if aPredicate(aSource[i]) then
    begin
      startIdx := i;
      Break;
    end;

  if startIdx < aSource.Count then
  begin
    list.Capacity := aSource.Count - startIdx;

    for var i := startIdx to Pred(aSource.Count) do
      list.Add(aSource[i]);
  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.SkipLast<T>(const aSource: TList<T>; const aCount: Integer): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
         .IsTrue(aCount >= 0, 'Count must be >= 0');

  var list := scope.Owns(TList<T>.Create);

  var takeCount := aSource.Count - aCount;

  if aCount = 0 then
  begin
    list.Capacity := aSource.Count;
    list.AddRange(aSource);
  end
  else if takeCount >0 then
  begin
    list.Capacity := takeCount;

    for var i := 0 to takeCount - 1 do
      list.Add(aSource[i]);
  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Sort<T>(const aSource: TList<T>): TList<T>;
begin
  Result := Sort<T>(aSource, IComparer<T>(nil));
end;

{ Comparers.TDescendingComparer<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor Comparers.TDescendingComparer<T>.Create(const aBase: IComparer<T>);
begin
  inherited Create;

  fBase := aBase;

  if fBase = nil then
    fBase := TComparer<T>.Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Comparers.TDescendingComparer<T>.Compare(const aLeft, aRight: T): Integer;
begin
  // Reverse order
  Result := fBase.Compare(aRight, aLeft);
end;

{ Comparers }

{----------------------------------------------------------------------------------------------------------------------}
class function Comparers.Default<T>: IComparer<T>;
begin
  Result := TComparer<T>.Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Comparers.Descending<T>(const aBase: IComparer<T>): IComparer<T>;
begin
  Result := TDescendingComparer<T>.Create(aBase);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Comparers.StringIgnoreCase: IComparer<string>;
begin
  // TIStringComparer.Ordinal is case-insensitive ordinal and implements IComparer<string>
  Result := TIStringComparer.Ordinal;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Comparers.StringOrdinal: IComparer<string>;
begin
  // TStringComparer.Ordinal is case-sensitive ordinal and implements IComparer<string>
  Result := TStringComparer.Ordinal;
end;

{ Equality }

{----------------------------------------------------------------------------------------------------------------------}
class function Equality.Default<T>: IEqualityComparer<T>;
begin
  Result := TEqualityComparer<T>.Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Equality.StringIgnoreCase: IEqualityComparer<string>;
begin
  // TIStringComparer.Ordinal also implements IEqualityComparer<string>
  Result := TIStringComparer.Ordinal;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Equality.StringOrdinal: IEqualityComparer<string>;
begin
  // TStringComparer.Ordinal also implements IEqualityComparer<string>
  Result := TStringComparer.Ordinal;
end;

end.
