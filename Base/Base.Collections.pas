{***************************************************************************************************
  Project:     Galahad
  Unit:        Base.Collections
  Author:      David Harper
  License:     MIT
  Purpose:     Provides collection-related types and utility helpers.

  Overview
  --------
  Base.Collections defines a small set of collection-oriented abstractions and helpers intended
  to simplify common operations on Delphi collections. It is designed to complement the standard
  RTL collections without replacing them.

  The unit focuses on clarity, correctness, and convenience when working with lists, dictionaries,
  sets, and related structures.

  Design Principles
  -----------------
  - Non-intrusive:
      Extends and assists existing RTL collections rather than introducing alternative container
      hierarchies.

  - Expressive helpers:
      Common collection patterns are expressed explicitly to reduce boilerplate and improve
      readability.

  - Side-effect conscious:
      Helper functions make mutation explicit and avoid hidden ownership or lifetime changes.

  Intended Usage
  --------------
  Base.Collections is intended to be used wherever collections are manipulated, especially in
  situations where repeated patterns would otherwise lead to verbose or error-prone code.

***************************************************************************************************}

unit Base.Collections;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Base.Core,
  Base.Integrity;

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

  TPartition<T> = record
    TrueList: TList<T>;
    FalseList: TList<T>;
  end;

  TSplit<T> = record
    Left: TList<T>;
    Right: TList<T>;
  end;

  TSpan<T> = record
    Prefix: TList<T>;
    Remainder: TList<T>;
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
    /// Splits Source into two new lists based on Predicate.
    /// Items satisfying Predicate go to TrueList; others go to FalseList.
    /// Stable order. Never mutates Source. Caller owns both lists.
    /// </summary>
    class function Partition<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TPartition<T>; static;

    /// <summary>
    /// Splits Source into two new lists at the specified index.
    /// Left contains the first aIndex items; Right contains the remaining items.
    /// Order is preserved (stable w.r.t. Source order).
    /// Never mutates Source. Caller owns both lists.
    /// </summary>
    class function SplitAt<T>(const aSource: TList<T>; const aIndex: Integer): TSplit<T>; static;

    /// <summary>
    /// Splits Source into a prefix that satisfies Predicate and the remaining items.
    /// The prefix is the longest leading run where Predicate(item) is True.
    /// Order is preserved (stable w.r.t. Source order).
    /// Never mutates Source. Caller owns both lists.
    /// </summary>
    class function Span<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TSpan<T>; static;

    /// <summary>
    /// Flattens a list of lists into a single list by concatenating all inner lists.
    /// Order is preserved (stable w.r.t. outer and inner list order).
    /// Nil inner lists are skipped.
    /// </summary>
    class function Flatten<T>(const aSource: TList<TList<T>>): TList<T>; static;

    /// <summary>
    /// Applies Mapper to each item in Source, appending zero or more results
    /// directly into Dest.
    /// </summary>
    /// <remarks>
    /// Mapper is responsible for adding items to Dest for each source item.
    /// No intermediate lists are created.
    /// Order is preserved (stable w.r.t. Source order and append order).
    /// Never mutates Source. Dest is appended to, not cleared.
    /// </remarks>
    class procedure FlatMapInto<T, U>(
      const aSource: TList<T>;
      const aMapper: TConstProc<T, TList<U>>;
      const aDest: TList<U>
    ); static;

    /// <summary>
    /// Maps each item in Source to zero or more items and flattens the results
    /// into a single new list.
    /// </summary>
    /// <remarks>
    /// This is a convenience wrapper over FlatMapInto that allocates
    /// and returns a new list.
    /// Order is preserved (stable w.r.t. Source order and append order).
    /// Never mutates Source. Caller owns the returned list.
    /// </remarks>
    class function FlatMap<T, U>(const aSource: TList<T>; const aMapper: TConstProc<T, TList<U>>): TList<U>; static;

    /// <summary>
    /// Returns a new list containing Mapper(Source[i]) for all i in source order.
    /// Order is preserved.
    /// </summary>
    class function Map<T, U>(const aSource: TList<T>; const aMapper: TConstFunc<T, U>): TList<U>; static;

    /// <summary>
    /// Returns a new list containing all items from Left followed by all items from Right.
    /// Order is preserved (stable).
    /// Nil inputs are treated as empty.
    /// </summary>
    class function Concat<T>(const aLeft, aRight: TList<T>): TList<T>; static;

    /// <summary>
    /// Returns a new list containing items from Left that do not appear in Right.
    /// Order is preserved (stable w.r.t. Left).
    /// If aComparer is nil, the default equality comparer for T is used.
    /// </summary>
    class function Subtract<T>(const aLeft, aRight: TList<T>; const aComparer: IEqualityComparer<T> = nil): TList<T>; static;

    /// <summary>
    /// Returns the symmetric difference (XOR) of Left and Right:
    /// items that appear in exactly one of the two lists.
    /// Result is distinct and stable (Left order first, then Right order).
    /// If aComparer is nil, the default equality comparer for T is used.
    /// </summary>
    class function Difference<T>(const aLeft, aRight: TList<T>; const aComparer: IEqualityComparer<T> = nil): TList<T>; static;

    /// <summary>
    /// Returns a new list containing items from Left that also appear in Right.
    /// Order is preserved (stable w.r.t. Left).
    /// Duplicates from Left are preserved if the item exists in Right.
    /// If aComparer is nil, the default equality comparer for T is used.
    /// </summary>
    class function Intersect<T>(const aLeft, aRight: TList<T>; const aComparer: IEqualityComparer<T> = nil): TList<T>; static;

    /// <summary>
    /// Returns the union of Left and Right, preserving the order of first occurrence.
    /// Items from Left appear first, followed by items from Right that were not already present.
    /// If aComparer is nil, the default equality comparer for T is used.
    /// </summary>
    class function Union<T>(const aLeft, aRight: TList<T>; const aComparer: IEqualityComparer<T> = nil): TList<T>; static;

    /// <summary>
    /// Returns the first item in Source that satisfies Predicate, wrapped in Maybe.
    /// If no item matches, returns None.
    /// </summary>
    class function First<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TMaybe<T>; static;

    /// <summary>
    /// Returns the last item in Source that satisfies Predicate, wrapped in Maybe.
    /// If no item matches, returns None.
    /// </summary>
    class function Last<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TMaybe<T>; static;

    /// <summary>
    /// Returns the first item in Source that satisfies Predicate.
    /// If no item matches, returns Fallback.
    /// </summary>
    class function FirstOr<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>; const aFallback: T): T; static;

    /// <summary>
    /// Returns the first item in Source that satisfies Predicate.
    /// If no item matches, returns Default(T).
    /// </summary>
    class function FirstOrDefault<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): T; static;

    /// <summary>
    /// Returns the last item in Source that satisfies Predicate.
    /// If no item matches, returns Fallback.
    /// </summary>
    class function LastOr<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>; const aFallback: T): T; static;

    /// <summary>
    /// Returns the last item in Source that satisfies Predicate.
    /// If no item matches, returns Default(T).
    /// </summary>
    class function LastOrDefault<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): T; static;

    /// <summary>
    /// Returns exactly one matching item.
    /// Ok(value) if exactly one match.
    /// Err if none match or more than one match.
    /// </summary>
    class function Single<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TResult<T>; static;

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
    /// Returns a list of integers from Start (inclusive) to End (exclusive).
    /// If Start >= End, returns an empty list.
    /// </summary>
    class function Range(const aStart, aEnd: Integer): TList<Integer>; static;

    /// <summary>
    /// Returns Source[Index] wrapped in Maybe.
    /// If Index is out of range (including negative), returns None.
    /// </summary>
    class function At<T>(const aSource: TList<T>; const aIndex: Integer): TMaybe<T>; static;

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
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  var list := scope.Owns(TList<T>.Create);

  list.Capacity := aSource.Count;

  for var i := 0 to Pred(aSource.Count) do
  begin
    var lItem := aSource[i];

    if aPredicate(lItem) then
      list.Add(lItem);
  end;

  Result := scope.Release(list);
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
    for var pair in map do
      pair.Value.Free;

    raise;
  end;

  Result := scope.Release(map);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Partition<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TPartition<T>;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  Result.TrueList := TList<T>.Create;
  Result.FalseList := TList<T>.Create;

  try
    Result.TrueList.Capacity := aSource.Count;
    Result.FalseList.Capacity := aSource.Count;

    for var item in aSource do
    begin
      if aPredicate(item) then
        Result.TrueList.Add(item)
      else
        Result.FalseList.Add(item);
    end;
  except
    on E:Exception do
    begin
      Result.TrueList.Free;
      Result.FalseList.Free;
      Result.TrueList := nil;
      Result.FalseList := nil;
      raise;
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.SplitAt<T>(const aSource: TList<T>; const aIndex: Integer): TSplit<T>;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsTrue(aIndex >= 0, 'Index must be >= 0');

  Result.Left := TList<T>.Create;
  Result.Right := TList<T>.Create;

  try
    var cut := if aIndex >= aSource.Count then aSource.Count else aIndex;

    Result.Left.Capacity := cut;
    Result.Right.Capacity := aSource.Count - cut;

    for var i := 0 to Pred(cut) do
      Result.Left.Add(aSource[i]);

    for var i := cut to Pred(aSource.Count) do
      Result.Right.Add(aSource[i]);
  except
    on E:Exception do
    begin
      Result.Left.Free;
      Result.Right.Free;
      Result.Left := nil;
      Result.Right := nil;
      raise;
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Span<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TSpan<T>;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  try
    var cut := 0;

    for var i := 0 to Pred(aSource.Count) do
    begin
      if aPredicate(aSource[i]) then
        Inc(cut)
      else
        Break;
    end;

    Result.Prefix := TList<T>.Create;
    Result.Remainder := TList<T>.Create;

    Result.Prefix.Capacity := cut;
    Result.Remainder.Capacity := aSource.Count - cut;

    for var i := 0 to Pred(cut) do
      Result.Prefix.Add(aSource[i]);

    for var i := cut to Pred(aSource.Count) do
    Result.Remainder.Add(aSource[i]);

  except
    on E:Exception do
    begin
      Result.Prefix.Free;
      Result.Remainder.Free;
      Result.Prefix := nil;
      Result.Remainder := nil;
      raise;
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Flatten<T>(const aSource: TList<TList<T>>): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil');

  var list  := scope.Owns(TList<T>.Create);
  var total := 0;

  for var inner in aSource do
    if inner <> nil then
      Inc(total, inner.Count);

  list.Capacity := total;

  for var inner in aSource do
  begin
    if inner = nil then Continue;

    for var i := 0 to Pred(inner.Count) do
      list.Add(inner[i]);
  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TCollect.FlatMapInto<T, U>(
  const aSource: TList<T>;
  const aMapper: TConstProc<T, TList<U>>;
  const aDest: TList<U>
);
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aMapper, 'Mapper is nil')
        .IsAssigned(aDest, 'Dest is nil');

  for var item in aSource do
    aMapper(item, aDest);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.FlatMap<T, U>(const aSource: TList<T>; const aMapper: TConstProc<T, TList<U>>): TList<U>;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<U>.Create);

  FlatMapInto<T, U>(aSource, aMapper, list);

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Map<T, U>(const aSource: TList<T>; const aMapper: TConstFunc<T, U>): TList<U>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aMapper, 'Mapper is nil');

  var list := scope.Owns(TList<U>.Create);

  list.Capacity := aSource.Count;

  for var i := 0 to Pred(aSource.Count) do
    list.Add(aMapper(aSource[i]));

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Concat<T>(const aLeft, aRight: TList<T>): TList<T>;
var
  leftCount, rightCount: Integer;
begin
  Result := TList<T>.Create;
  try
    leftCount := 0;
    rightCount := 0;

    if aLeft <> nil then
      leftCount := aLeft.Count;

    if aRight <> nil then
      rightCount := aRight.Count;

    Result.Capacity := leftCount + rightCount;

    if aLeft <> nil then
      Result.AddRange(aLeft);

    if aRight <> nil then
      Result.AddRange(aRight);
  except
    on E:Exception do
    begin
      Result.Free;
      raise;
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Subtract<T>(const aLeft, aRight: TList<T>; const aComparer: IEqualityComparer<T>): TList<T>;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<T>.Create);

  var cmp := if aComparer <> nil then aComparer else TEqualityComparer<T>.Default;

  var excluded := scope.Owns(TDictionary<T, Byte>.Create(cmp));

  if aRight <> nil then
    for var item in aRight do
      if not excluded.ContainsKey(item) then
        excluded.Add(item, 0);

  if aLeft <> nil then
  begin
    list.Capacity := aLeft.Count;

    for var item in aLeft do
      if not excluded.ContainsKey(item) then
        list.Add(item);
  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Difference<T>(const aLeft, aRight: TList<T>; const aComparer: IEqualityComparer<T>): TList<T>;
const
  IN_LEFT  = 1;
  IN_RIGHT = 2;
  IN_BOTH  = 3;
var
  state: Byte;
  scope: TScope;
begin
  var list := scope.Owns(TList<T>.Create);

  var cmp := if aComparer <> nil then aComparer else TEqualityComparer<T>.Default;

  var membership := scope.Owns(TDictionary<T, Byte>.Create(cmp));

  if aLeft <> nil then
    for var item in aLeft do
      if not membership.ContainsKey(item) then
        membership.Add(item, IN_LEFT);

  if aRight <> nil then
    for var item in aRight do
    begin
      if membership.TryGetValue(item, state) then
      begin
        if state = IN_LEFT then
          membership[item] := IN_BOTH;
      end
      else
        membership.Add(item, IN_RIGHT);
    end;

  if aLeft <> nil then
    for var item in aLeft do
      if membership.TryGetValue(item, state) and (state = IN_LEFT) then
      begin
        list.Add(item);
        membership.Remove(item);
      end;

  if aRight <> nil then
    for var item in aRight do
      if membership.TryGetValue(item, state) and (state = IN_RIGHT) then
      begin
        list.Add(item);
        membership.Remove(item);
      end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Intersect<T>(const aLeft, aRight: TList<T>; const aComparer: IEqualityComparer<T>): TList<T>;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<T>.Create);

  var cmp := if aComparer <> nil then aComparer else TEqualityComparer<T>.Default;

  var present := scope.Owns(TDictionary<T, Byte>.Create(cmp));

  if aRight <> nil then
    for var item in aRight do
      if not present.ContainsKey(item) then
        present.Add(item, 0);

  if aLeft <> nil then
  begin
    list.Capacity := aLeft.Count;
    for var item in aLeft do
      if present.ContainsKey(item) then
      begin
        list.Add(item);
        present.Remove(item);
      end;
  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Union<T>(const aLeft, aRight: TList<T>; const aComparer: IEqualityComparer<T>): TList<T>;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<T>.Create);

  var cmp  := if aComparer <> nil then aComparer else TEqualityComparer<T>.Default;
  var seen := scope.Owns(TDictionary<T, Byte>.Create(cmp));

  var capacity := if aLeft <> nil then aLeft.Count else 0;

  if aRight <> nil then
    Inc(capacity, aRight.Capacity);

  list.Capacity := capacity;

  if aLeft <> nil then
  begin

    for var item in aLeft do
      if not seen.ContainsKey(item) then
      begin
        seen.Add(item, 0);
        list.Add(item);
      end;

  end;

  if aRight <> nil then
  begin

    for var item in aRight do
      if not seen.ContainsKey(item) then
      begin
        seen.Add(item, 0);
        list.Add(item);
      end;

  end;

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.First<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TMaybe<T>;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  for var item in aSource do
    if aPredicate(item) then
    begin
      Result.SetSome(item);
      exit;
    end;

  Result.SetNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Last<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TMaybe<T>;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  for var i := aSource.Count - 1 downto 0 do
    if aPredicate(aSource[i]) then
    begin
      Result.SetSome(aSource[i]);
      exit;
    end;

  Result.SetNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.FirstOr<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>; const aFallback: T): T;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  for var item in aSource do
    if aPredicate(item) then
      Exit(item);

  Result := aFallback;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.FirstOrDefault<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): T;
begin
  Result := FirstOr<T>(aSource, aPredicate, Default(T));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.LastOr<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>; const aFallback: T): T;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  for var i := aSource.Count - 1 downto 0 do
    if aPredicate(aSource[i]) then
      Exit(aSource[i]);

  Result := aFallback;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.LastOrDefault<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): T;
begin
  Result := LastOr<T>(aSource, aPredicate, Default(T));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Single<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TResult<T>;
var
  found: Boolean;
  singleValue: T;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aPredicate, 'Predicate is nil');

  found := false;
  singleValue := default(T);

  for var item in aSource do
  begin
    if not aPredicate(item) then Continue;

    if not found then
    begin
      singleValue := item;
      found := True;
    end
    else
    begin
      Result.SetErr('More than one result');
      exit;
    end;
  end;

  if found then
  begin
    Result.SetOk(singleValue);
    exit;
  end;

  Result.SetErr('No result found');
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Reduce<TItem, TAcc>(const aSource: TList<TItem>; const aSeed: TAcc; const aReducer: TConstFunc<TAcc, TItem, TAcc>): TAcc;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aReducer, 'Reducer is nil');

  var lAcc := aSeed;

  for var i := 0 to Pred(aSource.Count) do
    lAcc := aReducer(lAcc, aSource[i]);

  Result := lAcc;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Sort<T>(const aSource: TList<T>; const aComparer: IComparer<T>): TList<T>;
var
  scope: TScope;
begin
  Ensure.IsAssigned(aSource, 'Source is nil');

  var list := Scope.Owns(TList<T>.Create);

  list.Capacity := aSource.Count;

  for var i := 0 to Pred(aSource.Count) do
    list.Add(aSource[i]);

  if not Assigned(aComparer) then
    list.Sort
  else
    list.Sort(aComparer);

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Sort<T>(const aSource: TList<T>; const aComparison: TComparison<T>): TList<T>;
begin
  Ensure.IsAssigned(aSource, 'Source is nil')
        .IsAssigned(@aComparison, 'Comparison is nil');

  Result := Sort<T>(aSource, TComparer<T>.Construct(aComparison));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Range(const aStart, aEnd: Integer): TList<Integer>;
var
  scope: TScope;
begin
  Ensure.IsTrue(aStart < aEnd , 'Start must be less than end');

  var list := scope.Owns(TList<Integer>.Create);

  list.Capacity := aEnd - aStart;

  for var i := aStart to Pred(aEnd) do
    list.Add(i);

  Result := scope.Release(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.At<T>(const aSource: TList<T>; const aIndex: Integer): TMaybe<T>;
begin
  Ensure.IsAssigned(aSource, 'Source is nil');

  if (aIndex < 0) or (aIndex >= aSource.Count) then
  begin
    Result.SetNone;
    Exit;
  end;

  Result.SetSome(aSource[aIndex]);
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
