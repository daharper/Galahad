unit Tests.Integrity.Option;

interface

uses
  DUnitX.TestFramework,
  Base.Integrity;

type
  [TestFixture]
  TMaybeFixture = class
  public
    [Test] procedure TestMakeNone;
    [Test] procedure TestMakeSome;
    [Test] procedure TestSetNone;
    [Test] procedure TestSetSome;
    [Test] procedure TestOrElse;
    [Test] procedure TestOrElseGet;
    [Test] procedure TestTryGet;
    [Test] procedure TestIfSome;
    [Test] procedure TestIfNone;
    [Test] procedure TestMatch;
    [Test] procedure TestFilter;
    [Test] procedure TestTap;
    [Test] procedure TestImmutability;
  end;

implementation

uses
  System.SysUtils;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestMakeNone;
begin
  var opt := TOption<integer>.None();

  Assert.IsTrue(opt.IsNone, 'Expected none, but got some.');
  Assert.IsFalse(opt.IsSome, 'Expected none, but got some.');

  Assert.WillRaiseWithMessage(procedure begin opt.Value; end, EArgumentException, MON_ACCESS_ERROR);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestSetNone;
var
  opt: TOption<integer>;
begin
  opt.SetNone;

  Assert.IsTrue(opt.IsNone, 'Expected none, but got some.');
  Assert.IsFalse(opt.IsSome, 'Expected none, but got some.');

  Assert.WillRaiseWithMessage(procedure begin opt.Value; end, EArgumentException, MON_ACCESS_ERROR);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestMakeSome;
begin
  var opt := TOption<integer>.Some(7);

  Assert.IsTrue(opt.IsSome, 'Expected none, but got some.');
  Assert.IsFalse(opt.IsNone, 'Expected none, but got some.');

  Assert.WillNotRaiseWithMessage(procedure begin opt.Value; end);

  Assert.AreEqual(7, opt.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestSetSome;
var
  opt: TOption<integer>;
begin
  opt.SetSome(3);

  Assert.IsTrue(opt.IsSome, 'Expected none, but got some.');
  Assert.IsFalse(opt.IsNone, 'Expected none, but got some.');

  Assert.WillNotRaiseWithMessage(procedure begin opt.Value; end);

  Assert.AreEqual(3, opt.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestOrElse;
begin
  var opt := TOption<integer>.None;
  var val := opt.OrElse(3);

  Assert.AreEqual(3, val);

  opt := TOption<integer>.Some(4);
  val := opt.OrElse(3);

  Assert.AreEqual(4, val);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestOrElseGet;
begin
  var opt := TOption<integer>.None;
  var val := opt.OrElseGet(function():integer begin Result := 3; end);

  Assert.AreEqual(3, val);

  opt := TOption<integer>.Some(4);
  val := opt.OrElseGet(function():integer begin Result := 3; end);

  Assert.AreEqual(4, val);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestTryGet;
begin
  var opt := TOption<integer>.TryGet(function:integer begin Result := 2; end);

  Assert.IsTrue(opt.IsSome);
  Assert.AreEqual(2, opt.Value);

  var err := TOption<integer>.TryGet(function: integer begin raise Exception.Create('x'); end);

  Assert.IsTrue(err.IsNone);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestIfSome;
var
  lValue: string;
begin
  lValue := '';

  var opt := TOption<integer>.None;
  opt.IfSome(procedure(const n: integer) begin lValue := IntToStr(n); end);

  Assert.AreEqual('', lValue);

  opt := TOption<integer>.Some(1);
  opt.IfSome(procedure(const n: integer) begin lValue := IntToStr(n); end);

  Assert.AreEqual('1', lValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestFilter;
begin
  var opt := TOption<integer>
                .Some(11)
                .Filter(function(const i: Integer):boolean begin Result := I < 10; end);

  Assert.IsTrue(opt.IsNone);

  opt := TOption<integer>
                .Some(7)
                .Filter(function(const i: Integer):boolean begin Result := I < 10; end);

  Assert.IsTrue(opt.IsSome);
  Assert.AreEqual(7, opt.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestTap;
begin
  var text := '';

  var opt := TOption<integer>
                .Some(11)
                .Tap(procedure(i: integer) begin text := IntToStr(i); end)
                .Filter(function(const i: Integer):boolean begin Result := I < 10; end);

  Assert.IsTrue(opt.IsNone);
  Assert.AreEqual('11', text);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestIfNone;
var
  lValue: string;
begin
  lValue := '';

  var opt := TOption<integer>.Some(1);
  opt.IfNone(procedure begin lValue := 'none'; end);

  Assert.AreEqual('', lValue);

  opt := TOption<integer>.None;
  opt.IfNone(procedure begin lValue := 'none'; end);

  Assert.AreEqual('none', lValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestMatch;
var
  lValue: integer;
begin
  lValue := 0;

  var opt := TOption<integer>.Some(2);
  opt.Match(procedure(const n: integer) begin lValue := n; end, procedure begin lValue := -1; end);

  Assert.AreEqual(2, lValue);

  lValue := 0;

  opt := TOption<integer>.None;
  opt.Match(procedure(const n: integer) begin lValue := n; end, procedure begin lValue := -1; end);

  Assert.AreEqual(-1, lValue);

  opt := TOption<integer>.Some(1);

  var text := opt.Match<string>(
    function(const n:integer): string begin Result := IntToStr(n); end,
    function: string begin Result := '404'; end);

  Assert.AreEqual('1', text);

  opt := TOption<integer>.None;

  text := opt.Match<string>(
    function(const n:integer): string begin Result := IntToStr(n); end,
    function: string begin Result := '404'; end);

  Assert.AreEqual('404', text);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMaybeFixture.TestImmutability;
var
  no: TOption<integer>;
  ok: TOption<integer>;
begin
  var none := TOption<integer>.None();

  Assert.WillRaiseWithMessage(
    procedure begin none.SetNone; end, EArgumentException, MON_INIT_ERROR);

  Assert.WillRaiseWithMessage(
    procedure begin none.SetSome(5); end, EArgumentException, MON_INIT_ERROR);

  var some := TOption<integer>.Some(3);

  Assert.WillRaiseWithMessage(
    procedure begin some.SetNone; end, EArgumentException, MON_INIT_ERROR);

  Assert.WillRaiseWithMessage(
    procedure begin some.SetSome(5); end, EArgumentException, MON_INIT_ERROR);

  no.SetNone();

  Assert.WillRaiseWithMessage(
    procedure begin no.SetNone; end, EArgumentException, MON_INIT_ERROR);

  Assert.WillRaiseWithMessage(
    procedure begin no.SetSome(5); end, EArgumentException, MON_INIT_ERROR);

  ok.SetSome(3);

  Assert.WillRaiseWithMessage(
    procedure begin ok.SetNone; end, EArgumentException, MON_INIT_ERROR);

  Assert.WillRaiseWithMessage(
    procedure begin ok.SetSome(5); end, EArgumentException, MON_INIT_ERROR);
end;

initialization
  TDUnitX.RegisterTestFixture(TMaybeFixture);

end.
