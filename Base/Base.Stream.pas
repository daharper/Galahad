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

      { terminators }

      function AsList: TList<T>;

      function Count: Integer;

      function Any(const aPredicate: TConstPredicate<T>): Boolean;

      function All(const aPredicate: TConstPredicate<T>): Boolean;

      function Reduce<TAcc>(const aSeed: TAcc; const aReducer: TConstFunc<TAcc, T, TAcc>): TAcc;
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
  fList := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.SetOwnsList(aValue: Boolean);
begin
  fOwnsList := aValue;
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
  lOldList: TList<T>;
  lNewList: TList<T>;
  lSeen: TDictionary<T, Byte>;
  lItem: T;
  i: Integer;
  scope: TScope;
begin
  fState.CheckNotConsumed;
  fState.CheckDisposable(aOnDiscard);

  lOldList := fState.GetList;

  Ensure.IsAssigned(lOldList, 'Stream has no buffer');

  lNewList := TList<T>.Create;
  lNewList.Capacity := lOldList.Count;

  lSeen := scope.Owns(TDictionary<T, Byte>.Create(aComparer));
  lSeen.Capacity := lOldList.Count;

  for i := 0 to Pred(lOldList.Count) do
  begin
    lItem := lOldList[i];

    if lSeen.ContainsKey(lItem) then
    begin
      if Assigned(AOnDiscard) then
         aOnDiscard(lItem);

      continue;
    end;

    lSeen.Add(lItem, 0);
    lNewList.Add(lItem);
  end;

  if fState.GetOwnsList then
    lOldList.Free;

  fState.SetList(lNewList);
  fState.SetOwnsList(true);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Sort(const AComparer: IComparer<T>): TPipe<T>;
var
  lOldList: TList<T>;
  lNewList: TList<T>;
  lCmp: IComparer<T>;
begin
  fState.CheckNotConsumed;

  lOldList := fState.GetList;

  Ensure.IsAssigned(lOldList, 'Stream has no buffer');

  if aComparer = nil then
    lCmp := TComparer<T>.Default
  else
    lCmp := AComparer;

  lNewList := TList<T>.Create;
  lNewList.Capacity := lOldList.Count;
  lNewList.AddRange(lOldList);
  lNewList.Sort(lCmp);

  if fState.GetOwnsList then
    lOldList.Free;

  fState.SetList(lNewList);
  fState.SetOwnsList(true);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Filter(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  lOldList: TList<T>;
  lNewList: TList<T>;
  i: Integer;
  lItem: T;
begin
  Ensure.IsAssigned(@aPredicate, 'Predicate is nil');

  fState.CheckNotConsumed;
  fState.CheckDisposable(aOnDiscard);

  lOldList := fState.GetList;

  Ensure.IsAssigned(lOldList, 'Stream has no buffer');

  lNewList := TList<T>.Create;
  lNewList.Capacity := lOldList.Count;

  for i := 0 to Pred(lOldList.Count) do
  begin
    lItem := lOldList[i];

    if aPredicate(lItem) then
      lNewList.Add(lItem)
    else if Assigned(aOnDiscard) then
      aOnDiscard(lItem);
  end;

  if fState.GetOwnsList then
    lOldList.Free;

  fState.SetList(lNewList);
  fState.SetOwnsList(true);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Map<U>(const aMapper: TConstFunc<T, U>; const aOnDiscard: TConstProc<T>): TPipe<U>;
var
  lOldList: TList<T>;
  lNewList: TList<U>;
  i: Integer;
  lItem: T;
begin
  Ensure.IsAssigned(@aMapper, 'Mapper is nil');

  fState.CheckNotConsumed;
  fState.CheckDisposable(aOnDiscard);

  lOldList := fState.GetList;

  Ensure.IsAssigned(lOldList, 'Stream has no buffer');

  lNewList := TList<U>.Create;
  lNewList.Capacity := lOldList.Count;

 for i := 0 to Pred(lOldList.Count) do
  begin
    lItem := lOldList[i];
    lNewList.Add(aMapper(lOldList[i]));

    if Assigned(aOnDiscard) then
      aOnDiscard(lItem);
  end;

  if FState.GetOwnsList then
    lOldList.Free;

  fState.SetList(nil);
  fState.SetOwnsList(false);
  fState.SetConsumed(true);

  Result := Stream.TPipe<U>.CreatePipe(lNewList, true);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.AsList: TList<T>;
var
  lList: TList<T>;
begin
  fState.CheckNotConsumed;

  lList := fState.GetList;

  Ensure.IsAssigned(lList, 'Stream has no buffer');

  Result := if fState.GetOwnsList then lList else TList<T>.Create(lList);

  FState.SetList(nil);
  FState.SetOwnsList(false);
  FState.SetConsumed(true);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Count: Integer;
var
  lList: TList<T>;
begin
  fState.CheckNotConsumed;

  lList := FState.GetList;

  Ensure.IsAssigned(lList, 'Stream has no buffer');

  Result := lList.Count;

  if FState.GetOwnsList then
    lList.Free;

  fState.SetList(nil);
  fState.SetOwnsList(false);
  fState.SetConsumed(true);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Any(const aPredicate: TConstPredicate<T>): Boolean;
var
  lList: TList<T>;
  i: Integer;
begin
  Ensure.IsAssigned(@aPredicate, 'Predicate is nil');

  FState.CheckNotConsumed;

  lList := FState.GetList;

  Ensure.IsAssigned(lList, 'Stream has no buffer');

  Result := False;

  for i := 0 to Pred(lList.Count) do
  begin
    if aPredicate(lList[i]) then
    begin
      Result := True;
      Break;
    end;
  end;

  if fState.GetOwnsList then
    lList.Free;

  fState.SetList(nil);
  fState.SetOwnsList(false);
  fState.SetConsumed(true);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.All(const aPredicate: TConstPredicate<T>): Boolean;
var
  lList: TList<T>;
  i: Integer;
begin
  Ensure.IsAssigned(@aPredicate, 'Predicate is nil');

  FState.CheckNotConsumed;

  lList := FState.GetList;

  Ensure.IsAssigned(lList, 'Stream has no buffer');

  Result := True;

  for I := 0 to Pred(lList.Count) do
  begin
    if not aPredicate(lList[i]) then
    begin
      Result := False;
      Break;
    end;
  end;

  if FState.GetOwnsList then
    lList.Free;

  FState.SetList(nil);
  FState.SetOwnsList(false);
  FState.SetConsumed(true);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Reduce<TAcc>(const aSeed: TAcc; const aReducer: TConstFunc<TAcc, T, TAcc>): TAcc;
var
  lList: TList<T>;
  lAcc: TAcc;
  i: Integer;
begin
  Ensure.IsAssigned(@aReducer, 'Reducer is nil');

  FState.CheckNotConsumed;

  lList := FState.GetList;

  Ensure.IsAssigned(lList, 'Stream has no buffer');

  lAcc := aSeed;

  for i := 0 to Pred(lList.Count) do
    lAcc := aReducer(lAcc, lList[i]);

  Result := lAcc;

  if FState.GetOwnsList then
    lList.Free;

  FState.SetList(nil);
  FState.SetOwnsList(false);
  FState.SetConsumed(true);
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
var
  lList: TList<T>;
begin
  lList := TList<T>.Create(aValues);

  Result := TPipe<T>.CreatePipe(lList, True);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(aEnum: TEnumerator<T>; aOwnsEnum: Boolean): TPipe<T>;
var
  lList: TList<T>;
begin
  Ensure.IsAssigned(aEnum, 'Enum is nil');

  lList := TList<T>.Create;

  try
    while aEnum.MoveNext do
      lList.Add(aEnum.Current);

    Result := TPipe<T>.CreatePipe(lList, True);
  finally
    if aOwnsEnum then
      aEnum.Free;
  end;
end;

end.
