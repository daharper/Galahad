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
      function Map<U>(const aMapper: TConstFunc<T, U>; const aOnDiscard: TConstProc<T> = nil): TPipe<U>;
      function Distinct(const AComparer: IEqualityComparer<T> = nil; const AOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function Sort(const AComparer: IComparer<T> = nil): TPipe<T>;
      function Reverse: TPipe<T>;
      function Concat(const aValues: array of T): TPipe<T>; overload;
      function Concat(const aList: TList<T>; aOwnsList: Boolean): TPipe<T>; overload;
      function Concat(aEnum: TEnumerator<T>; aOwnsEnum: Boolean = False): TPipe<T>; overload;
      function Take(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function TakeWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function Skip(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
      function SkipWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

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
    fList.Free;

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
    TError.Throw(EInvalidOpException.Create('Use Stream.From(list) or omit OnDiscard.'));
end;

{ Stream.TPipe<T> }

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.TPipe<T>.CreatePipe(aList: TList<T>; aOwnsList: Boolean): TPipe<T>;
begin
  Result.fState := TState.Create(aList, aOwnsList);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Distinct(const AComparer: IEqualityComparer<T>; const AOnDiscard: TConstProc<T>): TPipe<T>;
var
  lNewList: TList<T>;
  lSeen: TDictionary<T, Byte>;
  lItem: T;
  i: Integer;
  scope: TScope;
begin
  fState.CheckNotConsumed;
  fState.CheckDisposable(aOnDiscard);

  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  lNewList := TList<T>.Create;
  lNewList.Capacity := fState.List.Count;

  lSeen := scope.Owns(TDictionary<T, Byte>.Create(aComparer));
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
    lNewList.Add(lItem);
  end;

  fState.SetList(lNewList);
  fState.SetOwnsList(true);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Sort(const AComparer: IComparer<T>): TPipe<T>;
var
  lNewList: TList<T>;
  lCmp: IComparer<T>;
begin
  fState.CheckNotConsumed;

  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  if aComparer = nil then
    lCmp := TComparer<T>.Default
  else
    lCmp := AComparer;

  lNewList := TList<T>.Create;
  lNewList.Capacity := fState.List.Count;
  lNewList.AddRange(fState.List);
  lNewList.Sort(lCmp);

  fState.SetList(lNewList);
  fState.SetOwnsList(true);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Reverse: TPipe<T>;
begin
  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;

  var list := TList<T>.Create;

  list.Capacity := fState.List.Count;

  for var i := Pred(fState.List.Count) downto 0 do
    list.Add(fState.List[I]);

  FState.SetList(list);
  FState.SetOwnsList(True);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Concat(const aValues: array of T): TPipe<T>;
begin
  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;

  var list := TList<T>.Create;

  list.Capacity := fState.List.Count + Length(aValues);
  list.AddRange(fState.List);

  for var i := Low(aValues) to High(aValues) do
    list.Add(aValues[I]);

  FState.SetList(list);
  FState.SetOwnsList(True);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Concat(const aList: TList<T>; aOwnsList: Boolean): TPipe<T>;
begin
  Ensure.IsAssigned(aList, 'List is nil')
        .IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;

  var list := TList<T>.Create;

  list.Capacity := fState.List.Count + aList.Count;
  list.AddRange(fState.List);
  list.AddRange(aList);

  if aOwnsList then
    aList.Free;

  FState.SetList(list);
  FState.SetOwnsList(True);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Concat(aEnum: TEnumerator<T>; aOwnsEnum: Boolean): TPipe<T>;
begin
  Ensure.IsAssigned(aEnum, 'Enum is nil')
        .IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;

  var list := TList<T>.Create;

  list.Capacity := fState.List.Count;
  list.AddRange(fState.List);

  while aEnum.MoveNext do
    list.Add(aEnum.Current);

  if aOwnsEnum then
    aEnum.Free;

  FState.SetList(list);
  FState.SetOwnsList(True);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Filter(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  lNewList: TList<T>;
  i: Integer;
  lItem: T;
begin
  Ensure.IsAssigned(@aPredicate, 'Predicate is nil');

  fState.CheckNotConsumed;
  fState.CheckDisposable(aOnDiscard);

  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  lNewList := TList<T>.Create;
  lNewList.Capacity := fState.List.Count;

  for i := 0 to Pred(fState.List.Count) do

  begin
    lItem := fState.List[i];

    if aPredicate(lItem) then
      lNewList.Add(lItem)
    else if Assigned(aOnDiscard) then
      aOnDiscard(lItem);
  end;

  fState.SetList(lNewList);
  fState.SetOwnsList(true);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Map<U>(const aMapper: TConstFunc<T, U>; const aOnDiscard: TConstProc<T>): TPipe<U>;
var
  lNewList: TList<U>;
  i: Integer;
  lItem: T;
begin
  Ensure.IsAssigned(@aMapper, 'Mapper is nil');

  fState.CheckNotConsumed;
  fState.CheckDisposable(aOnDiscard);

  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  lNewList := TList<U>.Create;
  lNewList.Capacity := fState.List.Count;

  for i := 0 to Pred(fState.List.Count) do
  begin
    lItem := fState.List[i];
    lNewList.Add(aMapper(fState.List[i]));

    if Assigned(aOnDiscard) then
      aOnDiscard(lItem);
  end;

  fState.Terminate;

  Result := Stream.TPipe<U>.CreatePipe(lNewList, true);
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
function Stream.TPipe<T>.Take(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
begin
  Ensure.IsTrue(aCount >= 0, 'aCount must be >= 0')
        .IsAssigned(fState.List, 'Stream has no buffer');

  FState.CheckNotConsumed;
  FState.CheckDisposable(aOnDiscard);

  var lCount := if aCount > fState.List.Count then fState.List.Count else aCount;

  var list := TList<T>.Create;
  list.Capacity := lCount;

  for var i := 0 to Pred(lCount) do
    list.Add(fState.List[i]);

  if Assigned(aOnDiscard) then
    for var i := lCount to Pred(fState.List.Count) do
      aOnDiscard(fState.List[i]);

  FState.SetList(list);
  FState.SetOwnsList(true);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TakeWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
begin
  Ensure.IsAssigned(@aPredicate, 'Predicate is nil')
        .IsAssigned(fState.List, 'Stream has no buffer');

  fState.CheckNotConsumed;
  fState.CheckDisposable(aOnDiscard);

  var lCount := 0;

  while (lCount < fState.List.Count) and aPredicate(fState.List[lCount]) do
    Inc(lCount);

  var list := TList<T>.Create;
  list.Capacity := lCount;

  for var i := 0 to Pred(lCount) do
    list.Add(fState.List[i]);

  if Assigned(aOnDiscard) then
    for var i := lCount to Pred(fState.List.Count) do
      aOnDiscard(fState.List[I]);

  FState.SetList(list);
  FState.SetOwnsList(true);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Skip(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
begin
  Ensure.IsTrue(aCount >= 0, 'aCount must be >= 0')
        .IsAssigned(fState.List, 'Stream has no buffer');

  fState.CheckNotConsumed;
  fState.CheckDisposable(aOnDiscard);

  var lCount := if aCount > fState.List.Count then fState.List.Count else aCount;

  var startIdx := lCount;
  var list := TList<T>.Create;

  list.Capacity := fState.List.Count - startIdx;

  if Assigned(aOnDiscard) then
    for var i := 0 to Pred(startIdx) do
      aOnDiscard(fState.List[I]);

  for var i := startIdx to Pred(fState.List.Count) do
    list.Add(fState.List[I]);

  fState.SetList(list);
  fState.SetOwnsList(true);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.SkipWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
begin
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

  var list := TList<T>.Create;
  list.Capacity := fState.List.Count - startIdx;

  for var i := startIdx to Pred(fState.List.Count) do
    list.Add(fState.List[i]);

  fState.SetList(list);
  fState.SetOwnsList(true);

  Result := Self;
end;

{ Stream factories }

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(const aList: TList<T>): TPipe<T>;
begin
  Ensure.IsAssigned(aList, 'List is nil');

  Result := TPipe<T>.CreatePipe(aList, True);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.Borrow<T>(const aList: TList<T>): TPipe<T>;
begin
  Ensure.IsAssigned(aList, 'List is nil');

  Result := TPipe<T>.CreatePipe(aList, False);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(const aValues: array of T): TPipe<T>;
begin
  var list := TList<T>.Create(aValues);

  Result := TPipe<T>.CreatePipe(list, True);
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
