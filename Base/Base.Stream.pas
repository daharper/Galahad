unit Base.Stream;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Base.Core;

type
  Stream = record
  public type
    TPipe<T> = record
    private type
      IState = interface
        ['{7D0D82C9-9B6B-4E6A-8EAA-0C3A2E0D1E3E}']
        function GetList: TList<T>;
        procedure SetList(const Value: TList<T>);
        function GetOwnsList: Boolean;
        procedure SetOwnsList(Value: Boolean);
        function GetConsumed: Boolean;
        procedure SetConsumed(Value: Boolean);
        procedure CheckNotConsumed;
        procedure CheckDisposable(const aOnDiscard: TConstProc<T>);
        procedure Terminate;
        property List: TList<T> read GetList write SetList;
      end;

      TState = class(TInterfacedObject, IState)
      private
        fList: TList<T>;
        fOwnsList: Boolean;
        fConsumed: Boolean;
      public
        constructor Create(AList: TList<T>; AOwnsList: Boolean);

        function GetList: TList<T>;
        procedure SetList(const aValue: TList<T>);
        function GetOwnsList: Boolean;
        procedure SetOwnsList(aValue: Boolean);
        function GetConsumed: Boolean;
        procedure SetConsumed(aValue: Boolean);
        procedure CheckNotConsumed;
        procedure CheckDisposable(const aOnDiscard: TConstProc<T>);
        procedure Terminate;
        property List: TList<T> read GetList write SetList;
      end;

    private
      fState: IState;

      class function CreatePipe(aList: TList<T>; aOwnsList: Boolean): TPipe<T>; static;
    public
      { transformers }

      function Filter(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function Map<U>(const aMapper: TConstFunc<T, U>; const aOnDiscard: TConstProc<T> = nil): TPipe<U>; overload;
      function Map(const aMapper: TConstFunc<T, T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>; overload;
      function Distinct(const aEquality: IEqualityComparer<T> = nil; const AOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function Sort(const AComparer: IComparer<T> = nil): TPipe<T>;
      function Reverse: TPipe<T>;
      function Concat(const aValues: array of T): TPipe<T>; overload;
      function Concat(const aList: TList<T>; aOwnsList: Boolean): TPipe<T>; overload;
      function Concat(aEnum: TEnumerator<T>; aOwnsEnum: Boolean = False): TPipe<T>; overload;
      function Take(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function TakeWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function TakeLast(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function Skip(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function SkipWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function SkipLast(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function Peek(const aAction: TConstProc<T>): TPipe<T>;
      function PeekIndexed(const aAction: TConstProc<Integer, T>): TPipe<T>;

      function Zip<T2, TResult>(
        const aOther: TList<T2>;
        aOwnsList: Boolean;
        const aZipper: TConstFunc<T, T2, TResult>;
        const aOnDiscard: TConstProc<T> = nil;
        const aOnDiscardOther: TConstProc<T2> = nil
      ): TPipe<TResult>; overload;

      function Zip<T2, TResult>(
        const aOther: array of T2;
        const aZipper: TConstFunc<T, T2, TResult>;
        const aOnDiscard: TConstProc<T> = nil
      ): TPipe<TResult>; overload;

      function Zip<T2, TResult>(
        aEnum: TEnumerator<T2>;
        aOwnsEnum: Boolean;
        const aZipper: TConstFunc<T, T2, TResult>;
        const aOnDiscard: TConstProc<T> = nil;
        const aOnDiscardOther: TConstProc<T2> = nil
      ): TPipe<TResult>; overload;

      { terminators }

      function AsList: TList<T>;
      function AsArray: TArray<T>;
      function Count: Integer;
      function Any(const aPredicate: TConstPredicate<T>): Boolean;
      function All(const aPredicate: TConstPredicate<T>): Boolean;
      function Reduce<TAcc>(const aSeed: TAcc; const aReducer: TConstFunc<TAcc, T, TAcc>): TAcc;
      function FirstOr(const aDefault: T): T;
      function FirstOrDefault: T;
      function LastOr(const aDefault: T): T;
      function LastOrDefault: T;
      function IsEmpty: Boolean;
      function None(const aPredicate: TConstPredicate<T>): Boolean;
      function Contains(const aValue: T; const aEquality: IEqualityComparer<T> = nil): Boolean;

      procedure ForEach(const aAction: TConstProc<T>);
    end;

  public
    /// <summary>
    /// Takes ownership of the list container. Stream may free it when replaced/consumed.
    /// Items are never freed by Stream.
    /// </summary>
    class function From<T>(const aList: TList<T>): TPipe<T>; overload; static;

    /// <summary>
    /// Borrows the list container. Stream never frees it.
    /// Items are never freed by Stream.
    /// </summary>
    class function Borrow<T>(const aList: TList<T>): TPipe<T>; overload; static;

    /// <summary>
    /// Materializes an internal list buffer from the array (owned by Stream until detached).
    /// </summary>
    class function From<T>(const aValues: array of T): TPipe<T>; overload; static;

    /// <summary>
    /// Materializes an internal list buffer from an enumerator (owned by Stream until detached).
    /// OwnsEnum controls whether the enumerator is freed.
    /// </summary>
    class function From<T>(aEnum: TEnumerator<T>; aOwnsEnum: Boolean = False): TPipe<T>; overload; static;
  end;

implementation

uses
  Base.Integrity;

{ Stream.TPipe<T>.TState }

{----------------------------------------------------------------------------------------------------------------------}
constructor Stream.TPipe<T>.TState.Create(aList: TList<T>; aOwnsList: Boolean);
begin
  inherited Create;

  fList := aList;
  fOwnsList := aOwnsList;
  fConsumed := false;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TState.GetConsumed: Boolean;
begin
  Result := fConsumed;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TState.GetList: TList<T>;
begin
  Result := fList;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TState.GetOwnsList: Boolean;
begin
  Result := fOwnsList;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.SetConsumed(aValue: Boolean);
begin
  fConsumed := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.SetList(const aValue: TList<T>);
begin
  if (Assigned(fList)) and (fOwnsList) then
  begin
    fList.Free;
    fList := nil;
  end;

  fList := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.SetOwnsList(aValue: Boolean);
begin
  fOwnsList := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.Terminate;
begin
  SetList(nil);
  fOwnsList := false;
  fConsumed := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.CheckNotConsumed;
begin
  Ensure.IsFalse(fConsumed, 'Stream has been consumed');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.CheckDisposable(const aOnDiscard: TConstProc<T>);
begin
  if (Assigned(aOnDiscard)) and (not fOwnsList) then
    TError.Throw(EArgumentException.Create('Use Stream.From(list) or omit OnDiscard.'));
end;

{ Stream.TPipe<T> }

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.TPipe<T>.CreatePipe(aList: TList<T>; aOwnsList: Boolean): TPipe<T>;
begin
  Result.fState := TState.Create(aList, aOwnsList);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.AsList: TList<T>;
begin
  fState.CheckNotConsumed;

  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  Result := if fState.GetOwnsList then fState.List else TList<T>.Create(fState.List);

  FState.SetOwnsList(false);
  FState.SetList(nil);
  FState.SetConsumed(true);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.AsArray: TArray<T>;
begin
  fState.CheckNotConsumed;

  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  SetLength(Result, fState.List.Count);

  for var i := 0 to Pred(fState.List.Count) do
    Result[I] := fState.List[I];

  fState.Terminate;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Count: Integer;
begin
  fState.CheckNotConsumed;

  Ensure.IsAssigned(FState.List, 'Stream has no buffer');

  Result := FState.List.Count;

  fState.Terminate;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Any(const aPredicate: TConstPredicate<T>): Boolean;
begin
  Ensure.IsAssigned(@aPredicate, 'Predicate is nil');

  FState.CheckNotConsumed;

  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  Result := False;

  for var i := 0 to Pred(fState.List.Count) do
    if aPredicate(fState.List[i]) then
    begin
      Result := True;
      Break;
    end;

  fState.Terminate;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.All(const aPredicate: TConstPredicate<T>): Boolean;
begin
  Ensure.IsAssigned(@aPredicate, 'Predicate is nil')
        .IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;

  Result := True;

  for var i := 0 to Pred(fState.List.Count) do
    if not aPredicate(fState.List[i]) then
    begin
      Result := False;
      Break;
    end;

  fState.Terminate;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Reduce<TAcc>(const aSeed: TAcc; const aReducer: TConstFunc<TAcc, T, TAcc>): TAcc;
begin
  Ensure.IsAssigned(@aReducer, 'Reducer is nil')
        .IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;

  var acc := aSeed;

  for var i := 0 to Pred(fState.List.Count) do
    acc := aReducer(acc, fState.List[i]);

  Result := acc;

  fState.Terminate;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.ForEach(const aAction: TConstProc<T>);
begin
  Ensure.IsAssigned(@aAction, 'Action is nil')
        .IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;

  for var i := 0 to Pred(fState.List.Count) do
    aAction(fState.List[i]);

  fState.Terminate;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.FirstOrDefault: T;
begin
  Result := FirstOr(Default(T));
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.FirstOr(const aDefault: T): T;
begin
  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;

  if fState.List.Count > 0 then
    Result := fState.List[0]
  else
    Result := aDefault;

  fState.Terminate;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.LastOrDefault: T;
begin
  Result := LastOr(Default(T));
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.LastOr(const aDefault: T): T;
begin
  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;

  if fState.List.Count > 0 then
    Result := fState.List[Pred(fState.List.Count)]
  else
    Result := aDefault;

  fState.Terminate;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.IsEmpty: Boolean;
begin
  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;

  Result := fState.List.Count = 0;

  fState.Terminate;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.None(const aPredicate: TConstPredicate<T>): Boolean;
begin
  Ensure.IsAssigned(@aPredicate, 'Predicate is nil');

  Result := not Any(aPredicate);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Contains(const aValue: T; const aEquality: IEqualityComparer<T>): Boolean;
begin
  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;

  var eq := if aEquality = nil then TEqualityComparer<T>.Default else aEquality;

  Result := false;

  for var i := 0 to Pred(fState.List.Count - 1) do
    if Eq.Equals(fState.List[i], aValue) then
    begin
      Result := True;
      Break;
    end;

  fState.Terminate;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Distinct(const aEquality: IEqualityComparer<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  lSeen: TDictionary<T, Byte>;
  lItem: T;
  i: Integer;
  scope: TScope;
begin
  try
    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := fState.List.Count;

    lSeen := scope.Owns(TDictionary<T, Byte>.Create(aEquality));
    lSeen.Capacity := fState.List.Count;

    for i := 0 to Pred(fState.List.Count) do
    begin
      lItem := fState.List[i];

      if lSeen.ContainsKey(lItem) then
      begin
        if Assigned(AOnDiscard) then
           aOnDiscard(lItem);

        continue;
      end;

      lSeen.Add(lItem, 0);
      list.Add(lItem);
    end;

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Sort(const AComparer: IComparer<T>): TPipe<T>;
var
  scope: TScope;
  lCmp: IComparer<T>;
begin
  try
    fState.CheckNotConsumed;

    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

    if aComparer = nil then
      lCmp := TComparer<T>.Default
    else
      lCmp := AComparer;

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := fState.List.Count;
    list.AddRange(fState.List);
    list.Sort(lCmp);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;
{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Reverse: TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

    FState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count;

    for var i := Pred(fState.List.Count) downto 0 do
      list.Add(fState.List[I]);

    FState.SetList(scope.Release(list));
    FState.SetOwnsList(True);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Concat(const aValues: array of T): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

    FState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count + Length(aValues);
    list.AddRange(fState.List);

    for var i := Low(aValues) to High(aValues) do
      list.Add(aValues[I]);

    FState.SetList(scope.Release(list));
    FState.SetOwnsList(True);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Concat(const aList: TList<T>; aOwnsList: Boolean): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(aList, 'List is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    FState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count + aList.Count;
    list.AddRange(fState.List);
    list.AddRange(aList);

    if aOwnsList then
      aList.Free;

    FState.SetList(scope.Release(list));
    FState.SetOwnsList(True);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Concat(aEnum: TEnumerator<T>; aOwnsEnum: Boolean): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(aEnum, 'Enum is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    FState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count;
    list.AddRange(fState.List);

    while aEnum.MoveNext do
      list.Add(aEnum.Current);

    if aOwnsEnum then
      aEnum.Free;

    FState.SetList(scope.Release(list));
    FState.SetOwnsList(True);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Filter(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aPredicate, 'Predicate is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := fState.List.Count;

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];

      if aPredicate(item) then
        list.Add(item)
      else if Assigned(aOnDiscard) then
        aOnDiscard(item);
    end;

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Map<U>(const aMapper: TConstFunc<T, U>; const aOnDiscard: TConstProc<T>): TPipe<U>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aMapper, 'Mapper is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var list := scope.Owns(TList<U>.Create);
    list.Capacity := fState.List.Count;

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];
      list.Add(aMapper(item));

      if Assigned(aOnDiscard) then
        aOnDiscard(item);
    end;

    fState.Terminate;
    Result := Stream.TPipe<U>.CreatePipe(scope.Release(list), true);
  except
    fState.Terminate;
    raise;
  end;
end;
{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Map(const aMapper: TConstFunc<T, T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aMapper, 'Mapper is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := fState.List.Count;

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];
      list.Add(aMapper(item));

      if Assigned(aOnDiscard) then
        aOnDiscard(item);
    end;

    fState.Terminate;
    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Take(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aCount >= 0, 'Count must be >= 0')
          .IsAssigned(fState.List, 'Stream has no buffer');

    FState.CheckNotConsumed;
    FState.CheckDisposable(aOnDiscard);

    var lCount := if aCount > fState.List.Count then fState.List.Count else aCount;

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := lCount;

    for var i := 0 to Pred(lCount) do
      list.Add(fState.List[i]);

    if Assigned(aOnDiscard) then
      for var i := lCount to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    FState.SetList(scope.Release(list));
    FState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TakeWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aPredicate, 'Predicate is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var lCount := 0;

    while (lCount < fState.List.Count) and aPredicate(fState.List[lCount]) do
      Inc(lCount);

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := lCount;

    for var i := 0 to Pred(lCount) do
      list.Add(fState.List[i]);

    if Assigned(aOnDiscard) then
      for var i := lCount to Pred(fState.List.Count) do
        aOnDiscard(fState.List[I]);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TakeLast(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aCount >= 0, 'Count must be >= 0')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var lCount := if aCount > fState.List.Count then fState.List.Count else aCount;

    var startIdx := fState.List.Count - lCount;
    var list := scope.Owns(TList<T>.Create);

    list.Capacity := lCount;

    if Assigned(aOnDiscard) then
      for var i := 0 to Pred(startIdx) do
        aOnDiscard(fState.List[i]);

    for var i := startIdx to Pred(fState.List.Count) do
      list.Add(fState.List[I]);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Skip(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aCount >= 0, 'Count must be >= 0')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var lCount := if aCount > fState.List.Count then fState.List.Count else aCount;

    var startIdx := lCount;
    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count - startIdx;

    if Assigned(aOnDiscard) then
      for var i := 0 to Pred(startIdx) do
        aOnDiscard(fState.List[I]);

    for var i := startIdx to Pred(fState.List.Count) do
      list.Add(fState.List[I]);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.SkipWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aPredicate, 'Predicate is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var startIdx := 0;

    while (startIdx < fState.List.Count) and aPredicate(fState.List[startIdx]) do
    begin
      if Assigned(aOnDiscard) then
        aOnDiscard(fState.List[startIdx]);

      Inc(startIdx);
    end;

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := fState.List.Count - startIdx;

    for var i := startIdx to Pred(fState.List.Count) do
      list.Add(fState.List[i]);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.SkipLast(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aCount >= 0, 'Count must be >= 0')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var dropCount := if aCount > fState.List.Count then fState.List.Count else aCount;
    var keepCount := fState.List.Count - DropCount;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := keepCount;

    for var i := 0 to Pred(KeepCount) do
      list.Add(fState.List[I]);

    if Assigned(aOnDiscard) then
      for var i := KeepCount to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Peek(const aAction: TConstProc<T>): TPipe<T>;
begin
  try
    Ensure.IsAssigned(@aAction, 'Action is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;

    for var i := 0 to Pred(fState.List.Count) do
      aAction(fState.List[i]);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.PeekIndexed(const aAction: TConstProc<Integer, T>): TPipe<T>;
begin
  try
    Ensure.IsAssigned(@aAction, 'Action is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;

    for var i := 0 to Pred(fState.List.Count) do
      aAction(i, fState.List[i]);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Zip<T2, TResult>(
  const aOther: TList<T2>;
  aOwnsList: Boolean;
  const aZipper: TConstFunc<T, T2, TResult>;
  const aOnDiscard: TConstProc<T>;
  const aOnDiscardOther: TConstProc<T2>
): TPipe<TResult>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aOther, 'Other is nil')
          .IsAssigned(@aZipper, 'Zipper is nil')
          .IsAssigned(fState.List, 'Stream has no buffer')
          .IsFalse(Assigned(aOnDiscardOther) and (not aOwnsList), 'OnDiscardOther requires aOwnsList=True');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var n := if aOther.Count < fState.List.Count then aOther.Count else fState.List.Count;

    var list := scope.Owns(TList<TResult>.Create);
    list.Capacity := n;

    for var i := 0 to Pred(N) do
      list.Add(aZipper(fState.List[i], aOther[i]));

    if Assigned(aOnDiscard) then
      for var i := n to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    if Assigned(aOnDiscardOther) then
      for var i := n to Pred(aOther.Count) do
        aOnDiscardOther(aOther[I]);

    fState.Terminate;

    Result := Stream.TPipe<TResult>.CreatePipe(scope.Release(list), true);
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Zip<T2, TResult>(
  const aOther: array of T2;
  const aZipper: TConstFunc<T, T2, TResult>;
  const aOnDiscard: TConstProc<T>
  ): TPipe<TResult>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aOther, 'Other is nil')
          .IsAssigned(@aZipper, 'Zipper is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var n := if Length(aOther) < fState.List.Count then Length(aOther) else fState.List.Count;

    var list := scope.Owns(TList<TResult>.Create);
    list.Capacity := n;

    for var i := 0 to Pred(N) do
      list.Add(aZipper(FState.List[i], aOther[i]));

    if Assigned(aOnDiscard) then
      for var i := n to Pred(fState.List.Count) do
        aOnDiscard(FState.List[i]);

    fState.Terminate;

    Result := Stream.TPipe<TResult>.CreatePipe(scope.Release(list), true);
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Zip<T2, TResult>(
  aEnum: TEnumerator<T2>;
  aOwnsEnum: Boolean;
  const aZipper: TConstFunc<T, T2, TResult>;
  const aOnDiscard: TConstProc<T>;
  const aOnDiscardOther: TConstProc<T2>
  ): TPipe<TResult>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aEnum, 'Enum is nil')
          .IsAssigned(@aZipper, 'Zipper is nil')
          .IsAssigned(fState.List, 'Stream has no buffer')
          .IsFalse(Assigned(aOnDiscardOther) and (not aOwnsEnum), 'OnDiscardOther requires aOwnsEnum=True');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var list := scope.Owns(TList<TResult>.Create);
    list.Capacity := fState.List.Count;

    var n := 0;

    for var i := 0 to Pred(fState.List.Count) do
    begin
      if not aEnum.MoveNext then break;
      list.Add(aZipper(fState.List[i], aEnum.Current));
      Inc(n);
    end;

    if Assigned(aOnDiscard) then
      for var i := n to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    if Assigned(aOnDiscardOther) then
      while aEnum.MoveNext do
        aOnDiscardOther(aEnum.Current);

    if aOwnsEnum then
      aEnum.Free;

    fState.Terminate;

    Result := Stream.TPipe<TResult>.CreatePipe(scope.Release(list), true);
  except
    fState.Terminate;
    raise;
  end;
end;

{ Stream factories }

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(const aList: TList<T>): TPipe<T>;
begin
  Ensure.IsAssigned(aList, 'List is nil');

  Result := TPipe<T>.CreatePipe(aList, true);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.Borrow<T>(const aList: TList<T>): TPipe<T>;
begin
  Ensure.IsAssigned(aList, 'List is nil');

  Result := TPipe<T>.CreatePipe(aList,false);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(const aValues: array of T): TPipe<T>;
begin
  var list := TList<T>.Create(aValues);

  Result := TPipe<T>.CreatePipe(list, true);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(aEnum: TEnumerator<T>; aOwnsEnum: Boolean): TPipe<T>;
begin
  Ensure.IsAssigned(aEnum, 'Enum is nil');

  var list := TList<T>.Create;

  while aEnum.MoveNext do
    list.Add(aEnum.Current);

  Result := TPipe<T>.CreatePipe(list, true);

  if aOwnsEnum then
    aEnum.Free;
end;

end.
