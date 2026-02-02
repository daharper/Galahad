unit Tests.Integrity.Scope;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  Base.Integrity;

type
  TFreeProbe = class
  public
    class var FreedCount: Integer;
    class var FreedLog: TStringList;

    Name: string;

    constructor Create(const AName: string);
    destructor Destroy; override;

    class procedure Reset;
  end;

  [TestFixture]
  TUsingFixture = class
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test] procedure Finalize_FreesAllRegisteredObjects;
    [Test] procedure Release_PreventsObjectFromBeingFreed;
    [Test] procedure Instance_Dedupes_SameObjectNotFreedTwice;
    [Test] procedure Assign_Raises_WhenCopyingNonEmpty;
    [Test] procedure Deferred_Action_Should_Execute;
  end;

implementation

{----------------------------------------------------------------------------------------------------------------------}
procedure TUsingFixture.Setup;
begin
  TFreeProbe.Reset;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TUsingFixture.TearDown;
begin
  FreeAndNil(TFreeProbe.FreedLog);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TUsingFixture.Deferred_Action_Should_Execute;
begin
  var text := '';

  begin
      var scope: TScope;

      scope.Defer(procedure begin text := 'see you soon'; end);
  end;

  Assert.AreEqual(text, 'see you soon');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TUsingFixture.Finalize_FreesAllRegisteredObjects;
begin
  begin
    var scope: TScope;

    scope.Owns(TFreeProbe.Create('A'));
    scope.Owns(TFreeProbe.Create('B'));
    scope.Owns(TFreeProbe.Create('C'));
  end;

  Assert.AreEqual(3, TFreeProbe.FreedCount, 'All registered objects should be freed at scope end');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TUsingFixture.Release_PreventsObjectFromBeingFreed;
var
  Kept: TFreeProbe;
begin
  begin
    var scope: TScope;

    var a := scope.Owns(TFreeProbe.Create('A'));

    scope.Owns(TFreeProbe.Create('B'));

    Kept := scope.Release(a);

    Assert.IsTrue(Kept = a);
    Assert.IsNotNull(Kept);
  end;

  Assert.AreEqual(1, TFreeProbe.FreedCount, 'Only non-released objects should be freed by scope');
  Assert.AreEqual('B', TFreeProbe.FreedLog[0], 'Expected B to be freed by scope');

  Kept.Free;

  Assert.AreEqual(2, TFreeProbe.FreedCount, 'Released object should be freed by caller');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TUsingFixture.Instance_Dedupes_SameObjectNotFreedTwice;
var
  P: TFreeProbe;
begin
  P := TFreeProbe.Create('X');

  begin
    var scope: TScope;
    scope.Owns(P);
    scope.Owns(P);
  end;

  Assert.AreEqual(1, TFreeProbe.FreedCount, 'Same instance must not be freed twice');
  Assert.AreEqual('X', TFreeProbe.FreedLog[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TUsingFixture.Assign_Raises_WhenCopyingNonEmpty;
begin
  Assert.WillRaise(
    procedure
    begin
      var s1: TScope;
      var s2: TScope;
      s1.Owns(TFreeProbe.Create('A'));
      s2 := s1;
    end,
    Exception,
    'Copying a non-empty TUsing should raise');
end;

{ TFreeProbe }

{----------------------------------------------------------------------------------------------------------------------}
class procedure TFreeProbe.Reset;
begin
  FreedCount := 0;
  FreeAndNil(FreedLog);
  FreedLog := TStringList.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TFreeProbe.Create(const aName: string);
begin
  inherited Create;

  Name := aName;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TFreeProbe.Destroy;
begin
  Inc(FreedCount);

  if FreedLog <> nil then
    FreedLog.Add(Name);

  inherited;
end;

initialization
  TDUnitX.RegisterTestFixture(TUsingFixture);
end.
