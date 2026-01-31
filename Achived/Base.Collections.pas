unit Base.Collections;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Base.Core;

type

  TCollect = class
  public
    { explicit API }

    class function RemoveAll<T>(aList: TList<T>; const aPredicate: TConstPredicate<T>): Integer; static;
    class function RemoveAllObj<T: class>(aList: TObjectList<T>; const aPredicate: TConstPredicate<T>): Integer; static;

    { fluent wrappers }

    type
      { Non-owning List ops }
      TListOps<T> = record
      strict private
        fList: TList<T>;
      public
        constructor Create(aList: TList<T>);

        // Mutating Ops
        function AddRange(const aValues: array of T): TListOps<T>;
        function Filter(const aPredicate: TConstPredicate<T>): TListOps<T>;
        function Sort: TListOps<T>; overload;
        function Sort(const aComparer: IComparer<T>): TListOps<T>; overload;
        function Sort(const aComparison: TComparison<T>): TListOps<T>; overload;
        function Map<U>(const aMapper: TConstFunc<T, U>): TListOps<U>;

        // Terminators
        function AsList: TList<T>;
      end;

      { Owning-aware TObjectList ops }
      TObjectListOps<T: class> = record
      strict private
        fList: TObjectList<T>;
      public
        constructor Create(aList: TObjectList<T>);

        // Mutating Ops
        function AddRange(const aValues: array of T): TObjectListOps<T>;
        function Filter(const aPredicate: TConstPredicate<T>): TObjectListOps<T>;
        function Sort: TObjectListOps<T>; overload;
        function Sort(const aComparer: IComparer<T>): TObjectListOps<T>; overload;
        function Sort(const aComparison: TComparison<T>): TObjectListOps<T>; overload;
        function MapToList<U>(const aMapper: TConstFunc<T, U>): TListOps<U>;
        function Map<U: class>(const aMapper: TConstFunc<T, U>; aOwnsObjects: Boolean = True): TObjectListOps<U>;

        // Terminators
        function AsObjectList: TObjectList<T>;
      end;

    // Existing list: no allocation
    class function List<T>(aList: TList<T>): TListOps<T>; overload; static;
    class function ObjectList<T: class>(aList: TObjectList<T>): TObjectListOps<T>; overload; static;

    // From array: materializes new list (caller owns)
    class function List<T>(const aValues: array of T): TListOps<T>; overload; static;
    class function ObjectList<T: class>(const aValues: array of T; aOwnsObjects: Boolean = True): TObjectListOps<T>; overload; static;

    // From enumerator: materializes new list (caller owns)
    // OwnsEnum := True means we Free the enumerator after consumption.
    class function List<T>(aEnum: TEnumerator<T>; aOwnsEnum: Boolean = False): TListOps<T>; overload; static;
    class function ObjectList<T: class>(aEnum: TEnumerator<T>; aOwnsObjects: Boolean = True; aOwnsEnum: Boolean = False): TObjectListOps<T>; overload; static;
  end;

implementation

uses
  Base.Integrity;

{ TCollect }

class function TCollect.RemoveAll<T>(aList: TList<T>; const aPredicate:TConstPredicate<T>): Integer;
begin
  Ensure.IsAssigned(aList, 'List is nil').IsAssigned(@aPredicate, 'Predicate is nil');

  Result := 0;

  for var i := aList.Count - 1 downto 0 do
  begin
    if aPredicate(aList[i]) then
    begin
      aList.Delete(I);
      Inc(Result);
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.RemoveAllObj<T>(aList: TObjectList<T>; const aPredicate: TConstPredicate<T>): Integer;
begin
  Ensure.IsAssigned(aList, 'List is nil').IsAssigned(@aPredicate, 'Predicate is nil');

  Result := 0;

  for var i := Pred(aList.Count) downto 0 do
  begin
    if aPredicate(aList[I]) then
    begin
      aList.Delete(I);
      Inc(Result);
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.List<T>(aList: TList<T>): TListOps<T>;
begin
  Result := TListOps<T>.Create(aList);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.List<T>(aEnum: TEnumerator<T>; aOwnsEnum: Boolean): TListOps<T>;
begin
  Ensure.IsAssigned(aEnum, 'Enumerator is nil');

  var list := TList<T>.Create;

  try
    while aEnum.MoveNext do
      list.Add(AEnum.Current);
  finally
    if aOwnsEnum then
      aEnum.Free;
  end;

  Result := TListOps<T>.Create(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.List<T>(const aValues: array of T): TListOps<T>;
begin
  var list := TList<T>.Create;

  list.Capacity := Length(aValues);

  for var i := 0 to High(aValues) do
    list.Add(aValues[i]);

  Result := TListOps<T>.Create(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.ObjectList<T>(aList: TObjectList<T>): TObjectListOps<T>;
begin
  Result := TObjectListOps<T>.Create(aList);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.ObjectList<T>(const aValues: array of T; aOwnsObjects: Boolean): TObjectListOps<T>;
begin
  var list := TObjectList<T>.Create(aOwnsObjects);

  list.Capacity := Length(aValues);

  for var i := 0 to High(aValues) do
    list.Add(aValues[i]);

  Result := TObjectListOps<T>.Create(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TCollect.ObjectList<T>(aEnum: TEnumerator<T>; aOwnsObjects, aOwnsEnum: Boolean): TObjectListOps<T>;
begin
  Ensure.IsAssigned(aEnum, 'Enumerator is nil');

  var list := TObjectList<T>.Create(aOwnsObjects);

  try
    while AEnum.MoveNext do
      list.Add(aEnum.Current);
  finally
    if aOwnsEnum then
      aEnum.Free;
  end;

  Result := TObjectListOps<T>.Create(list);
end;

{ TCollect.TListOps<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TListOps<T>.AddRange(const aValues: array of T): TListOps<T>;
begin
  fList.AddRange(aValues);
  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TListOps<T>.Filter(const aPredicate: TConstPredicate<T>): TListOps<T>;
begin
  Ensure.IsAssigned(fList, 'list is nil').IsAssigned(@aPredicate, 'Predicate is nil');

  for var i := Pred(fList.Count) downto 0 do
    if not aPredicate(fList[I]) then
      fList.Delete(I);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TListOps<T>.Map<U>(const aMapper: TConstFunc<T, U>): TListOps<U>;
var
  i: Integer;
  lOutList: TList<U>;
  lItem: T;
begin
  Ensure.IsAssigned(fList, 'list is nil').IsAssigned(@aMapper, 'Mutator is nil');

  lOutList := TList<U>.Create;
  lOutList.Capacity := fList.Count;

  for i := 0 to Pred(fList.Count) do
    lOutList.Add(aMapper(fList[i]));

  fList.Free;

  Result := TListOps<U>.Create(lOutList);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TListOps<T>.Sort: TListOps<T>;
begin
  fList.Sort;
  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TListOps<T>.Sort(const aComparison: TComparison<T>): TListOps<T>;
begin
  Ensure.IsAssigned(fList, 'list is nil').IsAssigned(@aComparison, 'Comparison is nil');

  fList.Sort(TComparer<T>.Construct(aComparison));

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TListOps<T>.Sort(const aComparer: IComparer<T>): TListOps<T>;
begin
  Ensure.IsAssigned(fList, 'list is nil').IsAssigned(aComparer, 'Comperer is nil');

  fList.Sort(aComparer);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TListOps<T>.AsList: TList<T>;
begin
  Result := fList;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TCollect.TListOps<T>.Create(aList: TList<T>);
begin
  Ensure.IsAssigned(aList, 'list is nil');

  fList := aList;
end;

{ TCollect.TObjectListOps<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TObjectListOps<T>.AddRange(const aValues: array of T): TObjectListOps<T>;
begin
  fList.AddRange(aValues);
  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TObjectListOps<T>.Filter(const aPredicate: TConstPredicate<T>): TObjectListOps<T>;
begin
  Ensure.IsAssigned(@aPredicate, 'Predicate is nil');

  for var i := Pred(FList.Count) downto 0 do
    if not aPredicate(fList[I]) then
      fList.Delete(I);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TObjectListOps<T>.MapToList<U>(const aMapper: TConstFunc<T, U>): TListOps<U>;
var
  i: Integer;
  lOutList: TList<U>;
begin
  Ensure.IsAssigned(fList, 'List is nil').IsAssigned(@aMapper, 'Mapper is nil');

  lOutList := TList<U>.Create;
  lOutList.Capacity := fList.Count;

  for i := 0 to Pred(FList.Count) do
    lOutList.Add(aMapper(fList[i]));

  fList.Free;

  Result := TListOps<U>.Create(lOutList);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TObjectListOps<T>.Map<U>(const aMapper: TConstFunc<T, U>; aOwnsObjects: Boolean): TObjectListOps<U>;
var
  i: Integer;
  lOutList: TObjectList<U>;
begin
  Ensure.IsAssigned(fList, 'List is nil').IsAssigned(@aMapper, 'Mapper is nil');

  lOutList := TObjectList<U>.Create(aOwnsObjects);
  lOutList.Capacity := fList.Count;

  for i := 0 to Pred(FList.Count) do
    lOutList.Add(aMapper(fList[i]));

  fList.Free;

  Result := TObjectListOps<U>.Create(lOutList);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TObjectListOps<T>.Sort: TObjectListOps<T>;
begin
  fList.Sort;
  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TObjectListOps<T>.Sort(const aComparer: IComparer<T>): TObjectListOps<T>;
begin
  Ensure.IsAssigned(fList, 'List is nil').IsAssigned(aComparer, 'Comparer is nil');

  fList.Sort(aComparer);

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TObjectListOps<T>.Sort(const aComparison: TComparison<T>): TObjectListOps<T>;
begin
  Ensure.IsAssigned(fList, 'List is nil').IsAssigned(@aComparison, 'Comparison is nil');

  fList.Sort(TComparer<T>.Construct(aComparison));

  Result := Self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCollect.TObjectListOps<T>.AsObjectList: TObjectList<T>;
begin
  Result := fList;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TCollect.TObjectListOps<T>.Create(aList: TObjectList<T>);
begin
  Ensure.IsAssigned(aList, 'List is nil');

  fList := aList;
end;

end.
