unit Tests.Core.Collect;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  DUnitX.TestFramework,
  Base.Collections;

type
  TTestObj = class
  public
    Value: Integer;
    constructor Create(AValue: Integer);
  end;

  TCountingObj = class(TTestObj)
  private
    class var FreedCount: integer;
  public
    destructor Destroy; override;
  end;

  TTestEnumerator<T> = class(TEnumerator<T>)
  private
    fItems: TArray<T>;
    fIndex: Integer;
    fFreed: PBoolean;
  protected
    function DoGetCurrent: T; override;
    function DoMoveNext: Boolean; override;
  public
    constructor Create(const aItems: array of T; aFreedFlag: PBoolean);
    destructor Destroy; override;
  end;

  [TestFixture]
  TCollectFixture = class
  public
    [Setup]
    procedure Setup;

    [Test] procedure List_FromArray_AsList_ReturnsMaterializedList;
    [Test] procedure List_FromEnumerator_OwnsEnumFalse_DoesNotFreeEnum;
    [Test] procedure List_Sort_Default_Works;
    [Test] procedure List_Sort_Comparer_Works;
    [Test] procedure List_Sort_Comparison_Works;
    [Test] procedure ObjectList_Filter_OwnsObjectsTrue_FreesRemoved;
    [Test] procedure ObjectList_Filter_OwnsObjectsFalse_DoesNotFreeRemoved;
    [Test] procedure ObjectList_MapToList_ProjectsValues;
    [Test] procedure ObjectList_Map_OwnsObjectsTrue_FreesMappedObjects;
    [Test] procedure ObjectList_Map_OwnsObjectsFalse_DoesNotFreeMappedObjects;
  end;

implementation

{ TTestObj }

{----------------------------------------------------------------------------------------------------------------------}
constructor TTestObj.Create(AValue: Integer);
begin
  inherited Create;

  Value := aValue;
end;

{ TCountingObj }

destructor TCountingObj.Destroy;
begin
  Inc(FreedCount);
  inherited;
end;

{ TTestEnumerator<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TTestEnumerator<T>.Create(const aItems: array of T; aFreedFlag: PBoolean);
begin
  inherited Create;

  SetLength(FItems, Length(AItems));

  for var i := 0 to High(AItems) do
    fItems[i] := aItems[i];

  fIndex := -1;
  fFreed := aFreedFlag;

  if Assigned(fFreed) then
    fFreed^ := False;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TTestEnumerator<T>.Destroy;
begin
  if Assigned(fFreed) then
    fFreed^ := True;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTestEnumerator<T>.DoGetCurrent: T;
begin
  Result := fItems[fIndex];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTestEnumerator<T>.DoMoveNext: Boolean;
begin
  Inc(fIndex);
  Result := FIndex <= High(fItems);
end;

{ TCollectFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.Setup;
begin
  TCountingObj.FreedCount := 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.List_FromArray_AsList_ReturnsMaterializedList;
begin
  var list := TCollect.List<Integer>([3, 1, 2]).AsList;

  try
    Assert.AreEqual(3, list.Count);
    Assert.AreEqual(3, list[0]);
    Assert.AreEqual(1, list[1]);
    Assert.AreEqual(2, list[2]);
  finally
    list.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.List_FromEnumerator_OwnsEnumFalse_DoesNotFreeEnum;
begin
  var freed := False;
  var enum := TTestEnumerator<Integer>.Create([10, 20], @freed);
  var list := TCollect.List<Integer>(enum, false).AsList;

  try
    Assert.IsFalse(Freed, 'Enumerator should not be freed when OwnsEnum=False');
    Assert.AreEqual(2, list.Count);
    Assert.AreEqual(10, list[0]);
    Assert.AreEqual(20, list[1]);
  finally
    list.Free;
    enum.Free;
  end;

  Assert.IsTrue(freed, 'Enumerator should be freed after explicit Free');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.List_Sort_Default_Works;
begin
  var list := TCollect.List<Integer>([3, 1, 2]).Sort.AsList;

  try
    Assert.AreEqual(1, list[0]);
    Assert.AreEqual(2, list[1]);
    Assert.AreEqual(3, list[2]);
  finally
    list.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.List_Sort_Comparer_Works;
begin
  var desc := TComparer<Integer>.Construct(
    function(const A, B: Integer): Integer
    begin
      Result := B - A;
    end);

  var list := TCollect.List<Integer>([3, 1, 2]).Sort(Desc).AsList;

  try
    Assert.AreEqual(3, list[0]);
    Assert.AreEqual(2, list[1]);
    Assert.AreEqual(1, list[2]);
  finally
    list.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.List_Sort_Comparison_Works;
begin
  var list := TCollect
      .List<Integer>([3, 1, 2])
      .Sort(
        function(const A, B: Integer): Integer
        begin
          Result := B - A;
        end)
      .AsList;

  try
    Assert.AreEqual(3, list[0]);
    Assert.AreEqual(2, list[1]);
    Assert.AreEqual(1, list[2]);
  finally
    list.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.ObjectList_Filter_OwnsObjectsTrue_FreesRemoved;
begin
  var list := TObjectList<TTestObj>.Create(True);

  try
    var a := TCountingObj.Create(1);
    var b := TCountingObj.Create(2);
    var c := TCountingObj.Create(3);

    list.Add(a);
    list.Add(b);
    list.Add(c);

    TCollect.ObjectList<TTestObj>(list)
      .Filter(function(const O: TTestObj): Boolean begin Result := (O.Value mod 2) = 1; end);


    Assert.AreEqual(2, list.Count);
    Assert.AreEqual(1, list[0].Value);
    Assert.AreEqual(3, list[1].Value);

    Assert.AreEqual(1, TCountingObj.FreedCount, 'Exactly one object should have been freed');
  finally
    list.Free;
  end;

  Assert.AreEqual(3, TCountingObj.FreedCount, 'All three objects should have been freed overall');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.ObjectList_Filter_OwnsObjectsFalse_DoesNotFreeRemoved;
begin
  var list := TObjectList<TTestObj>.Create(False);

  var a := TCountingObj.Create(1);
  var b := TCountingObj.Create(2);
  var c := TCountingObj.Create(3);

  try
    list.Add(a);
    list.Add(b);
    list.Add(c);

    TCollect
      .ObjectList<TTestObj>(list)
      .Filter(function(const O: TTestObj): Boolean begin Result := (O.Value mod 2) = 1; end);

    Assert.AreEqual(2, list.Count);
    Assert.AreEqual(0, TCountingObj.FreedCount, 'Removed object must not be freed when OwnsObjects=False');

    b.Free;
    Assert.AreEqual(1, TCountingObj.FreedCount);
  finally
    a.Free;
    c.Free;

    list.Free;
  end;

  Assert.AreEqual(3, TCountingObj.FreedCount);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.ObjectList_MapToList_ProjectsValues;
begin
  var list := TObjectList<TTestObj>.Create(True);

  list.Add(TTestObj.Create(1));
  list.Add(TTestObj.Create(2));
  list.Add(TTestObj.Create(3));

  var r := TCollect
    .ObjectList<TTestObj>(list)
    .MapToList<Integer>(function(const O: TTestObj): Integer begin Result := O.Value * 10; end)
    .AsList;

  try
    Assert.AreEqual(3, r.Count);
    Assert.AreEqual(10, r[0]);
    Assert.AreEqual(20, r[1]);
    Assert.AreEqual(30, r[2]);
  finally
    r.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.ObjectList_Map_OwnsObjectsTrue_FreesMappedObjects;
begin
  // Source list owns its objects (unrelated to mapped list ownership).
  var src := TObjectList<TTestObj>.Create(true);

  src.Add(TTestObj.Create(1));
  src.Add(TTestObj.Create(2));

  // Map creates new objects; mapped list owns them and must free them.
  var mapped := TCollect
    .ObjectList<TTestObj>(src)
    .Map<TCountingObj>(function(const O: TTestObj): TCountingObj begin Result := TCountingObj.Create(O.Value+5); end)
    .AsObjectList;

  try
    Assert.AreEqual(2, mapped.Count);
    Assert.AreEqual(0, TCountingObj.FreedCount, 'Nothing should be freed before list destruction');
  finally
    mapped.Free;
  end;

  Assert.AreEqual(2, TCountingObj.FreedCount, 'Mapped objects must be freed when OwnsObjects=True');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCollectFixture.ObjectList_Map_OwnsObjectsFalse_DoesNotFreeMappedObjects;
begin
  // Source list owns its objects (unrelated to mapped list ownership).
  var src := TObjectList<TTestObj>.Create(true);

  src.Add(TTestObj.Create(1));
  src.Add(TTestObj.Create(2));

  // Pre-create mapped objects so we can check they survive list destruction.
  var a := TCountingObj.Create(3);
  var b := TCountingObj.Create(4);

  // Map creates new objects; mapped list owns them and must free them.
  var mapped := TCollect
    .ObjectList<TTestObj>(src)
    .Map<TCountingObj>(
      function(const O: TTestObj): TCountingObj
      begin
        Result := if o.Value = 1 then a else b;
      end,
      false)
    .AsObjectList;

  try
    Assert.AreEqual(2, mapped.Count);
    Assert.AreSame(a, mapped[0]);
    Assert.AreSame(b, mapped[1]);
    Assert.AreEqual(0, TCountingObj.FreedCount);

    Assert.AreEqual(2, mapped.Count);
    Assert.AreEqual(0, TCountingObj.FreedCount, 'Nothing should be freed before list destruction');
  finally
    mapped.Free;
  end;

  src.Free;

  Assert.AreEqual(2, TCountingObj.FreedCount, 'Mapped objects must be freed when OwnsObjects=True');
end;

initialization
  TDUnitX.RegisterTestFixture(TCollectFixture);

end.


