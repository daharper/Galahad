unit Tests.Result;

interface

uses
  DUnitX.TestFramework,
  Base.Integrity;

type
  [TestFixture]
  TResultFixture = class
  public
    [Test] procedure TestMakeOk;
    [Test] procedure TestMakeErr;
    [Test] procedure TestSetOk;
    [Test] procedure TestSetErr;
    [Test] procedure TestOrElse;
    [Test] procedure TestOrElseGet;
    [Test] procedure TestTryGet;
    [Test] procedure TestIfOk;
    [Test] procedure TestIfErr;
    [Test] procedure TestMatch;
    [Test] procedure TestValidate;
    [Test] procedure TestTap;
    [Test] procedure TestTapError;
    [Test] procedure TestImmutability;
  end;

implementation

uses
  System.SysUtils;

{ TMaybeTestFixture }

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestMakeOk;
begin
  var r := TResult<integer>.MakeOk(2);

  Assert.IsTrue(r.IsOk);
  Assert.IsFalse(r.IsErr);
  Assert.AreEqual(2, r.Value);

  Assert.WillNotRaiseWithMessage(procedure begin r.Value; end);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestMakeErr;
begin
  var r := TResult<integer>.MakeErr('uh oh');

  Assert.IsFalse(r.IsOk);
  Assert.IsTrue(r.IsErr);
  Assert.AreEqual('uh oh', r.Error);

  Assert.WillRaiseWithMessage(procedure begin r.Value; end, EArgumentException, MON_ACCESS_ERROR);

  r := TResult<integer>.MakeErr('%s', ['uh oh']);

  Assert.IsFalse(r.IsOk);
  Assert.IsTrue(r.IsErr);
  Assert.AreEqual('uh oh', r.Error);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestSetOk;
var
  r: TResult<integer>;
begin
  r.SetOk(3);

  Assert.IsTrue(r.IsOk);
  Assert.IsFalse(r.IsErr);
  Assert.AreEqual(3, r.Value);

  Assert.WillNotRaiseWithMessage(procedure begin r.Value; end);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestSetErr;
var
  r: TResult<integer>;
  r2: TResult<integer>;
begin
  r.SetErr('uh oh');

  Assert.IsFalse(r.IsOk);
  Assert.IsTrue(r.IsErr);
  Assert.AreEqual('uh oh', r.Error);

  Assert.WillRaiseWithMessage(procedure begin r.Value; end, EArgumentException, MON_ACCESS_ERROR);

  r2 := TResult<integer>.MakeErr('%s', ['uh oh']);

  Assert.IsFalse(r2.IsOk);
  Assert.IsTrue(r2.IsErr);
  Assert.AreEqual('uh oh', r2.Error);

  Assert.WillRaiseWithMessage(procedure begin r2.Value; end, EArgumentException, MON_ACCESS_ERROR);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestIfErr;
var
  lValue: string;
begin
  lValue := '';

  var r := TResult<integer>.MakeOk(4);
  r.IfErr(procedure begin lValue := 'none'; end);

  Assert.AreEqual('', lValue);

  var r2 := TResult<integer>.MakeErr('error');
  r2.IfErr(procedure begin lValue := 'none'; end);

  Assert.AreEqual('none', lValue);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestIfOk;
var
  lValue: string;
begin
  lValue := '';

  var r := TResult<integer>.MakeErr('error');
  r.IfOk(procedure(n: integer) begin lValue := IntToStr(n); end);

  Assert.AreEqual('', lValue);

  var r2 := TResult<integer>.MakeOk(4);
  r2.IfOk(procedure(n: integer) begin lValue := IntToStr(n); end);

  Assert.AreEqual('4', lValue);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestMatch;
var
  lValue: integer;
begin
  lValue := 0;

  var r := TResult<integer>.MakeOk(4);
  r.Match(procedure(n: integer) begin lValue := n; end, procedure begin lValue := -1; end);

  Assert.AreEqual(4, lValue);

  lValue := 0;

  r := TResult<integer>.MakeErr('error');
  r.Match(procedure(n: integer) begin lValue := n; end, procedure begin lValue := -1; end);

  Assert.AreEqual(-1, lValue);

  r := TResult<integer>.MakeOk(1);

  var text := r.Match<string>(
    function(n:integer): string begin Result := IntToStr(n); end,
    function(err: string): string begin Result := '404'; end);

  Assert.AreEqual('1', text);

  r := TResult<integer>.MakeErr('error');

  text := r.Match<string>(
    function(n:integer): string begin Result := IntToStr(n); end,
    function(err: string): string begin Result := '404'; end);

  Assert.AreEqual('404', text);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestTap;
begin
  var text := '';

  var r := TResult<integer>
                .MakeOk(11)
                .Tap(procedure(i: integer) begin text := IntToStr(i); end)
                .Validate(function(i: Integer):boolean begin Result := I < 10; end, 'out of range');

  Assert.IsTrue(r.IsErr);
  Assert.AreEqual('out of range', r.Error);
  Assert.AreEqual('11', text);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestTapError;
begin
  var text := '';

  var r := TResult<integer>
                .MakeErr('out of range')
                .TapError(procedure(e: string) begin text := 'out of bounds'; end);

  Assert.IsTrue(r.IsErr);
  Assert.AreEqual('out of range', r.Error);
  Assert.AreEqual('out of bounds', text);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestOrElse;
begin
  var r := TResult<integer>.MakeErr('error');
  var val := r.OrElse(3);

  Assert.AreEqual(3, val);

  r := TResult<integer>.MakeOk(4);
  val := r.OrElse(3);

  Assert.AreEqual(4, val);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestOrElseGet;
begin
  var r := TResult<integer>.MakeErr('error');
  var val := r.OrElseGet(function():integer begin Result := 3; end);

  Assert.AreEqual(3, val);

  r := TResult<integer>.MakeOk(4);
  val := r.OrElseGet(function():integer begin Result := 3; end);

  Assert.AreEqual(4, val);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestTryGet;
begin
  var r := TResult<integer>.TryGet(function:integer begin Result := 2; end);

  Assert.IsTrue(r.IsOk);
  Assert.AreEqual(2, r.Value);

  r := TResult<integer>.TryGet(function: integer begin raise Exception.Create('x'); end);

  Assert.IsTrue(r.IsErr);
  Assert.AreEqual('x', r.Error);
end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestValidate;
begin
  var r := TResult<integer>
              .MakeOk(4)
              .Validate(function(n: integer):boolean begin Result := n < 10; end, 'out of range');

  Assert.IsTrue(r.IsOk);
  Assert.AreEqual(4, r.Value);

  r := TResult<integer>
              .MakeOk(11)
              .Validate(function(n: integer):boolean begin Result := n < 10; end, 'out of range');

  Assert.IsTrue(r.IsErr);
  Assert.AreEqual('out of range', r.Error);

  r := TResult<integer>
              .MakeOk(7)
              .Validate(
                  function(n: integer):boolean begin Result := n < 10; end,
                  function(n: integer):string begin Result := 'out of bounds'; end);


  Assert.IsTrue(r.IsOk);
  Assert.AreEqual(7, r.Value);

  r := TResult<integer>
              .MakeOk(11)
              .Validate(
                  function(n: integer):boolean begin Result := n < 10; end,
                  function(n: integer):string begin Result := 'out of bounds'; end);

  Assert.IsTrue(r.IsErr);
  Assert.AreEqual('out of bounds', r.Error);

end;

{--------------------------------------------------------------------------------------------------}
procedure TResultFixture.TestImmutability;
var
  err: TResult<integer>;
  ok:  TResult<integer>;
begin
  var error := TResult<integer>.MakeErr('error');

  Assert.WillRaiseWithMessage(
    procedure begin error.SetErr('error2'); end, EArgumentException, MON_INIT_ERROR);

  Assert.WillRaiseWithMessage(
    procedure begin error.SetOk(5); end, EArgumentException, MON_INIT_ERROR);

  var some := TResult<integer>.MakeOk(3);

  Assert.WillRaiseWithMessage(
    procedure begin some.SetErr('error2'); end, EArgumentException, MON_INIT_ERROR);

  Assert.WillRaiseWithMessage(
    procedure begin some.SetOk(5); end, EArgumentException, MON_INIT_ERROR);

  err.SetErr('errory');

  Assert.WillRaiseWithMessage(
    procedure begin err.SetErr('error3'); end, EArgumentException, MON_INIT_ERROR);

  Assert.WillRaiseWithMessage(
    procedure begin err.SetOk(5); end, EArgumentException, MON_INIT_ERROR);

  ok.SetOk(7);

  Assert.WillRaiseWithMessage(
    procedure begin ok.SetErr('error4'); end, EArgumentException, MON_INIT_ERROR);

  Assert.WillRaiseWithMessage(
    procedure begin ok.SetOk(5); end, EArgumentException, MON_INIT_ERROR);
end;

initialization
  TDUnitX.RegisterTestFixture(TResultFixture);

end.
