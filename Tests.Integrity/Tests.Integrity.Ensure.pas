unit Tests.Integrity.Ensure;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework;

type
  TErrorHandler = class
  private
    fError: string;
  public
    property Error: string read fError;
    procedure OnError(const aError: Exception);
  end;

  [TestFixture]
  TEnsureFixture = class
  private
    fHandler: TErrorHandler;
  public
    [Setup]
    procedure Setup;

    [Teardown]
    procedure Teardown;

    [Test] procedure TestIsBlank;
    [Test] procedure TestIsNotBlank;
    [Test] procedure TestIsTrue;
    [Test] procedure TestIsFalse;
    [Test] procedure TestAreSame;
    [Test] procedure TestAreDifferent;
    [Test] procedure TestAreSameText;
    [Test] procedure TestAreDifferentText;
  end;

implementation

uses
  Base.Integrity;

{ TEnsureFixture }

{--------------------------------------------------------------------------------------------------}
procedure TEnsureFixture.TestIsBlank;
begin
  Assert.WillNotRaiseWithMessage(procedure begin Ensure.IsBlank('  '); end);
  Assert.WillNotRaiseWithMessage(procedure begin Ensure.IsBlank(''); end);

  Assert.IsEmpty(fHandler.Error);

  Assert.WillRaiseWithMessage(
    procedure begin Ensure.IsBlank('a', 'wrong') end, EArgumentException, 'wrong');

  Assert.AreEqual('wrong', fHandler.Error);
end;

{--------------------------------------------------------------------------------------------------}
procedure TEnsureFixture.TestIsNotBlank;
begin
  Assert.WillNotRaiseWithMessage(procedure begin Ensure.IsNotBlank('hello'); end);

  Assert.IsEmpty(fHandler.Error);

  Assert.WillRaiseWithMessage(
    procedure begin Ensure.IsNotBlank('  ', 'err1') end, EArgumentException, 'err1');

  Assert.AreEqual('err1', fHandler.Error);

  Assert.WillRaiseWithMessage(
    procedure begin Ensure.IsNotBlank('', 'err2') end, EArgumentException, 'err2');

  Assert.AreEqual('err2', fHandler.Error);
end;

{--------------------------------------------------------------------------------------------------}
procedure TEnsureFixture.TestAreSameText;
begin
  Assert.WillNotRaiseWithMessage(procedure begin Ensure.AreSameText('hi', 'HI'); end);

  Assert.IsEmpty(fHandler.Error);

  Assert.WillRaiseWithMessage(
    procedure begin Ensure.AreSameText('Hi', ' HI ', 'wrong') end, EArgumentException, 'wrong');

  Assert.AreEqual('wrong', fHandler.Error);
end;

{--------------------------------------------------------------------------------------------------}
procedure TEnsureFixture.TestAreDifferentText;
begin
  Assert.WillNotRaiseWithMessage(procedure begin Ensure.AreDifferentText('hi', ' HI '); end);

  Assert.IsEmpty(fHandler.Error);

  Assert.WillRaiseWithMessage(
    procedure begin Ensure.AreDifferentText('Hi', 'HI', 'wrong') end, EArgumentException, 'wrong');

  Assert.AreEqual('wrong', fHandler.Error);
end;

{--------------------------------------------------------------------------------------------------}
procedure TEnsureFixture.TestAreSame;
begin
  Assert.WillNotRaiseWithMessage(procedure begin Ensure.AreSame('hi', 'hi'); end);

  Assert.IsEmpty(fHandler.Error);

  Assert.WillRaiseWithMessage(
    procedure begin Ensure.AreSame('Hi', 'HI', 'wrong') end, EArgumentException, 'wrong');

  Assert.AreEqual('wrong', fHandler.Error);
end;

{--------------------------------------------------------------------------------------------------}
procedure TEnsureFixture.TestAreDifferent;
begin
  Assert.WillNotRaiseWithMessage(procedure begin Ensure.AreDifferent('hi', 'HI'); end);

  Assert.IsEmpty(fHandler.Error);

  Assert.WillRaiseWithMessage(
    procedure begin Ensure.AreDifferent('Hi', 'Hi', 'wrong') end, EArgumentException, 'wrong');

  Assert.AreEqual('wrong', fHandler.Error);
end;

{--------------------------------------------------------------------------------------------------}
procedure TEnsureFixture.TestIsTrue;
begin
  Assert.WillNotRaiseWithMessage(procedure begin Ensure.IsTrue(true); end);

  Assert.IsEmpty(fHandler.Error);

  Assert.WillRaiseWithMessage(
    procedure begin Ensure.IsTrue(false, 'wrong') end, EArgumentException, 'wrong');

  Assert.AreEqual('wrong', fHandler.Error);
end;

{--------------------------------------------------------------------------------------------------}
procedure TEnsureFixture.TestIsFalse;
begin
  Assert.WillNotRaiseWithMessage(procedure begin Ensure.IsFalse(false); end);

  Assert.IsEmpty(fHandler.Error);

  Assert.WillRaiseWithMessage(
    procedure begin Ensure.IsFalse(true, 'wrong') end, EArgumentException, 'wrong');

  Assert.AreEqual('wrong', fHandler.Error);
end;

{--------------------------------------------------------------------------------------------------}
procedure TEnsureFixture.Setup;
begin
  fHandler := TErrorHandler.Create;
  TError.OnError.Subscribe(fHandler.OnError);
end;

{--------------------------------------------------------------------------------------------------}
procedure TEnsureFixture.Teardown;
begin
  TError.OnError.Unsubscribe(fHandler.OnError);
  fHandler.Free;
end;

{ TErrorHandler }

{--------------------------------------------------------------------------------------------------}
procedure TErrorHandler.OnError(const aError: Exception);
begin
  fError := aError.Message;
end;

initialization
  TDUnitX.RegisterTestFixture(TEnsureFixture);

end.
