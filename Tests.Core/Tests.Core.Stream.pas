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
  end;

implementation

uses
  Base.Integrity;

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
