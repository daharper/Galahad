unit Tests.Integrity.ResultOp;

interface

uses
  DUnitX.TestFramework,
  Base.Integrity;

type
  [TestFixture]
  TResultOpFixture = class
  public
    [Test] procedure Bind_DoesNotCallFunc_OnErr;
    [Test] procedure Map_TransformsOk;
    [Test] procedure UnwrapOr_ReturnsValue_WhenOk;
    [Test] procedure UnwrapOr_ReturnsDefault_WhenErr;
    [Test] procedure UnwrapOrElse_ReturnsValue_WhenOk_DoesNotCallFallback;
    [Test] procedure UnwrapOrElse_CallsFallback_WhenErr_PassesError;
    [Test] procedure MapError_DoesNotCallFunc_WhenOk;
    [Test] procedure MapError_TransformsError_WhenErr;
    [Test] procedure Recover_DoesNotCallFunc_WhenOk;
    [Test] procedure Recover_TurnsErrIntoOk_WhenErr;
  end;

implementation

uses
  System.SysUtils;

{ TResultOpFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultOpFixture.Bind_DoesNotCallFunc_OnErr;
begin
  var called := false;
  var res := TResult<Integer>.Err('boom');

  var outRes := TResultOp.Bind<Integer, string>(Res,
    function (v: Integer): TResult<string>
    begin
      called := True;
      Result := TResult<string>.Ok(v.ToString);
    end);

  Assert.IsFalse(called);
  Assert.IsTrue(outRes.IsErr);
  Assert.AreEqual('boom', outRes.Error);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultOpFixture.Map_TransformsOk;
begin
  var res := TResult<Integer>.Ok(3);

  var outRes := TResultOp.Map<Integer, Integer>(res,
    function (v: Integer): Integer
    begin
      Result := v * v;
    end);

  Assert.IsTrue(outRes.IsOk);
  Assert.AreEqual(9, outRes.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultOpFixture.UnwrapOr_ReturnsValue_WhenOk;
begin
  var res := TResult<Integer>.Ok(42);
  var val := TResultOp.UnwrapOr<Integer>(res, 999);

  Assert.AreEqual(42, val, 'Should return the Ok value (not the default)');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultOpFixture.UnwrapOr_ReturnsDefault_WhenErr;
begin
  var res := TResult<Integer>.Err('bad');
  var val := TResultOp.UnwrapOr<Integer>(res, 999);

  Assert.AreEqual(999, val, 'Should return the default when Err');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultOpFixture.UnwrapOrElse_CallsFallback_WhenErr_PassesError;
begin
  var called := False;
  var seenError := '';
  var res := TResult<Integer>.Err('boom');

  var val := TResultOp.UnwrapOrElse<Integer>(res,
    function (E: string): Integer
    begin
      called := True;
      seenError := E;
      Result := 8080;
    end);

  Assert.IsTrue(called, 'Fallback must be called when Err');
  Assert.AreEqual('boom', SeenError, 'Fallback must receive the error message');
  Assert.AreEqual(8080, val, 'Should return fallback value when Err');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultOpFixture.UnwrapOrElse_ReturnsValue_WhenOk_DoesNotCallFallback;
begin
  var called := False;
  var res := TResult<Integer>.Ok(7);

  var val := TResultOp.UnwrapOrElse<Integer>(Res,
    function (E: string): Integer
    begin
      called := True;
      Result := 123;
    end);

  Assert.IsFalse(called, 'Fallback must not be called when Ok');
  Assert.AreEqual(7, val, 'Should return the Ok value');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultOpFixture.MapError_DoesNotCallFunc_WhenOk;
begin
  var called := False;
  var res := TResult<Integer>.Ok(123);

  var outRes := TResultOp.MapError<Integer>(Res,
    function (E: string): string
    begin
      called := True;
      Result := 'mapped:' + E;
    end);

  Assert.IsFalse(called, 'MapError must not call mapper when Ok');
  Assert.IsTrue(outRes.IsOk);
  Assert.AreEqual(123, outRes.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultOpFixture.MapError_TransformsError_WhenErr;
begin
  var res := TResult<Integer>.Err('boom');

  var outRes := TResultOp.MapError<Integer>(Res,
    function (E: string): string
    begin
      Result := 'context: ' + E;
    end);

  Assert.IsTrue(outRes.IsErr);
  Assert.AreEqual('context: boom', outRes.Error);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultOpFixture.Recover_DoesNotCallFunc_WhenOk;
begin
  var called := False;
  var res := TResult<Integer>.Ok(7);

  var outRes := TResultOp.Recover<Integer>(Res,
    function (E: string): Integer
    begin
      Called := True;
      Result := 999;
    end);

  Assert.IsFalse(called, 'Recover must not call fallback when Ok');
  Assert.IsTrue(outRes.IsOk);
  Assert.AreEqual(7, outRes.Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResultOpFixture.Recover_TurnsErrIntoOk_WhenErr;
begin
  var called := False;
  var seenError := '';

  var res := TResult<Integer>.Err('boom');

  var outRes := TResultOp.Recover<Integer>(Res,
    function (E: string): Integer
    begin
      called := True;
      seenError := E;
      Result := 42;
    end);

  Assert.IsTrue(called, 'Recover must call fallback when Err');
  Assert.AreEqual('boom', seenError, 'Recover must pass the error message to fallback');
  Assert.IsTrue(outRes.IsOk, 'Recover should turn Err into Ok');
  Assert.AreEqual(42, outRes.Value);
end;

initialization
  TDUnitX.RegisterTestFixture(TResultOpFixture);

end.
