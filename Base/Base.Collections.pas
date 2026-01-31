unit Base.Collections;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Base.Core;

type

  /// <summary>
  /// Stateless collection algorithms.
  ///
  /// Ownership contract:
  /// - Never mutates the input list.
  /// - Never frees items.
  /// - Any returned list is newly allocated and caller-owned.
  /// </summary>
  TCollect = class
  public
    /// <summary>
    /// Returns a new list containing items from Source that satisfy Predicate.
    /// Order is preserved (stable w.r.t. the source order).
    /// </summary>
    class function Filter<T>(const aSource: TList<T>; const aPredicate: TConstPredicate<T>): TList<T>; static;

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
  Ensure.IsAssigned(aSource, 'Source is nil').IsAssigned(@aPredicate, 'Predicate is nil');

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
class function TCollect.Map<T, U>(const aSource: TList<T>; const aMapper: TConstFunc<T, U>): TList<U>;
begin
  Ensure.IsAssigned(aSource, 'Source is nil').IsAssigned(@aMapper, 'Mapper is nil');

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
  Ensure.IsAssigned(aSource, 'Source is nil').IsAssigned(@aReducer, 'Mapper is nil');

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
  Ensure.IsAssigned(@aComparison, 'Comparison is nil');

  Result := Sort<T>(aSource, TComparer<T>.Construct(aComparison));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.Sort<T>(const aSource: TList<T>): TList<T>;
begin
  Result := Sort<T>(aSource, IComparer<T>(nil));
end;

end.
