unit Base.Integrity;

interface

uses
  System.SysUtils,
  System.TypInfo,
  Base.Core;

const
  MON_INIT_ERROR   = 'State has already been initialized error.';
  MON_ACCESS_ERROR = 'Cannot access value of None';

type
  TMaybeState = (
    // initial state, used to enforce immutability, evaluates to msNone
    msUnknown,
    // some value has been set
    msSome,
    // none has been set
    msNone);

  TResultState = (
    // initial state, used to enforce immutability, evaluates to rsErr
    rsUnknown,
    // ok has been set
    rsOk,
    // err has been set
    rsErr);

  /// <summary>
  ///  Basic implementation of an optional, adapted for Delphi record/memory constraints.
  /// </summary>
  TMaybe<T> = record
  strict private
    fState: TMaybeState;
    fValue: T;

    function GetValue: T;
  public
    property Value: T read GetValue;

    function IsSome: Boolean;
    function IsNone: Boolean;

    function OrElse(const aFallback: T): T;
    function OrElseGet(const aFunc: TFunc<T>): T;

    procedure IfSome(const aProc: TProc<T>);
    procedure IfNone(const aProc: TProc);

    procedure Match(const aSomeProc: TProc<T>; const aNoneProc: TProc); overload;
    function Match<R>(const aSomeFunc: TFunc<T, R>; const aNoneFunc: TFunc<R>): R; overload;

    function Filter(const aPredicate: TFunc<T, Boolean>): TMaybe<T>;
    function Tap(const aProc: TProc<T>): TMaybe<T>;

    procedure SetSome(const aValue: T);
    procedure SetNone;

    class function TryGet(const Func: TFunc<T>): TMaybe<T>; static; inline;

    class function MakeSome(const aValue: T): TMaybe<T>; static; inline;
    class function MakeNone: TMaybe<T>; static; inline;

    class operator Initialize;
  end;

  /// <summary>
  ///  Basic implementation of a result, adapted for Delphi record/memory constraints.
  /// </summary>
  TResult<T> = record
  strict private
    fState: TResultState;
    fError: string;
    fValue: T;

    function GetValue: T;
  public
    property Value: T read GetValue;
    property Error: string read fError;

    function IsErr: Boolean;
    function IsOk: Boolean;

    function OrElse(const aFallback: T): T;
    function OrElseGet(const aFunc: TFunc<T>): T;

    procedure IfOk(const aProc: TProc<T>);
    procedure IfErr(const aProc: TProc);

    procedure Match(const aOkProc: TProc<T>; const aErrProc: TProc); overload;
    function Match<R>(const aOkFunc: TFunc<T, R>; const aErrFunc: TFunc<string, R>): R; overload;

    function Tap(const aProc: TProc<T>): TResult<T>;
    function TapError(const aProc: TProc<string>): TResult<T>;

    function Validate(const aPredicate: TFunc<T, Boolean>; const aError: string): TResult<T>; overload;
    function Validate(const aPredicate: TFunc<T, Boolean>; const aErrorFunc: TFunc<T, string>): TResult<T>; overload;

    procedure SetOk(const aValue: T);
    procedure SetErr(const aMessage: string = ''); overload;
    procedure SetErr(const aFormat: string; const aArgs: array of const); overload;

    class function TryGet(const Func: TFunc<T>): TResult<T>; static; inline;

    class function MakeOk(const aValue: T): TResult<T>; static; inline;
    class function MakeErr(const aMessage: string = ''): TResult<T>; overload; static; inline;
    class function MakeErr(const aFormat: string; const aArgs: array of const): TResult<T>; overload; static;

    class operator Initialize;
  end;

  /// <summary>
  ///  Takes ownership of instance, cleans it up on scope exit.
  /// </summary>
  TUsing<T: class> = record
  strict private
    fInstance: T;
  public
    function Instance(aObject: T): T;

    constructor Create(aObject: T);

    class operator Initialize;
    class operator Finalize;
  end;

  /// <summary>
  ///  Centralized error handling.
  /// </summary>
  TErrorCentral = class
  private
    fSubscribers: TMulticast<Exception>;

    class var fInstance: TErrorCentral;
  public
    property Subscribers:TMulticast<Exception> read fSubscribers write fSubscribers;

    procedure Throw<T: Exception>(const Msg: string); overload;
    procedure Throw<T: Exception>(const Fmt: string; const Args: array of const); overload;
    procedure Throw(const [ref] aException: Exception); overload;

    procedure Notify(const [ref] aException: Exception);

    constructor Create;
    destructor Destroy; override;

    class constructor Create;
    class destructor Destroy;
  end;

  TEnsure = class
  private
    class var fInstance: TEnsure;
  public
    function IsBlank(const aText: string; const aMessage: string = ''): TEnsure;
    function IsNotBlank(const aText: string; const aMessage: string = ''): TEnsure;
    function IsTrue(const aCondition: boolean; const aMessage: string = ''): TEnsure;
    function IsFalse(const aCondition: boolean; const aMessage: string = ''): TEnsure;
    function IsSame(const aLhs: string; const aRhs: string; const aMessage: string = ''): TEnsure;
    function IsNotSame(const aLhs: string; const aRhs: string; const aMessage: string = ''): TEnsure;

    class constructor Create;
    class destructor Destroy;
  end;

  function TError: TErrorCentral;
  function Ensure: TEnsure;

implementation

uses
  System.Classes,
  System.Rtti;

{$region 'Functions'}

{--------------------------------------------------------------------------------------------------}
function TError: TErrorCentral;
begin
  Result := TErrorCentral.fInstance;
end;

{--------------------------------------------------------------------------------------------------}
function Ensure: TEnsure;
begin
  Result := TEnsure.fInstance;
end;

{$endregion}

{$region 'TMaybe<T>'}

{--------------------------------------------------------------------------------------------------}
function TMaybe<T>.IsNone: Boolean;
begin
  Result := fState <> msSome;
end;

{--------------------------------------------------------------------------------------------------}
function TMaybe<T>.IsSome: Boolean;
begin
  Result := fState = msSome;
end;

{--------------------------------------------------------------------------------------------------}
function TMaybe<T>.GetValue: T;
begin
  Ensure.IsTrue(fState = msSome, MON_ACCESS_ERROR);

  Result := fValue;
end;

{--------------------------------------------------------------------------------------------------}
procedure TMaybe<T>.SetSome(const aValue: T);
begin
  Ensure.IsTrue(fState = msUnknown, MON_INIT_ERROR);

  fState := msSome;
  fValue := aValue;
end;

{--------------------------------------------------------------------------------------------------}
procedure TMaybe<T>.SetNone;
begin
  Ensure.IsTrue(fState = msUnknown, MON_INIT_ERROR);

  fState := msNone;
end;

{--------------------------------------------------------------------------------------------------}
function TMaybe<T>.Filter(const aPredicate: TFunc<T, Boolean>): TMaybe<T>;
begin
  Ensure.IsTrue(Assigned(aPredicate), 'Expected (filter) function is missing');

  if fState <> msSome then exit(self);

  if aPredicate(self.Value) then
    exit(self);

  Result := TMaybe<T>.MakeNone;
end;

{--------------------------------------------------------------------------------------------------}
function TMaybe<T>.OrElse(const aFallback: T): T;
begin
  if fState = msSome then
    Result := fValue
  else
    Result := aFallback;
end;

{--------------------------------------------------------------------------------------------------}
function TMaybe<T>.OrElseGet(const aFunc: TFunc<T>): T;
begin
  Ensure.IsTrue(Assigned(aFunc), 'Expected (else) function is missing');

  if fState = msSome then
    Result := fValue
  else
    Result := aFunc;
end;

{--------------------------------------------------------------------------------------------------}
procedure TMaybe<T>.Match(const aSomeProc: TProc<T>; const aNoneProc: TProc);
begin
  Ensure.IsTrue(Assigned(aSomeProc), 'Expected (some) procedure is missing')
        .IsTrue(Assigned(aNoneProc), 'Expected (none) procedure is missing');

  if fState = msSome then
    aSomeProc(fValue)
  else
    aNoneProc();
end;

{--------------------------------------------------------------------------------------------------}
function TMaybe<T>.Match<R>(const aSomeFunc: TFunc<T, R>; const aNoneFunc: TFunc<R>): R;
begin
  Ensure.IsTrue(Assigned(aSomeFunc), 'Expected (some) procedure is missing')
        .IsTrue(Assigned(aNoneFunc), 'Expected (none) procedure is missing');

 if fState = msSome then
    Result := aSomeFunc(fValue)
  else
    Result := aNoneFunc();
end;

{--------------------------------------------------------------------------------------------------}
procedure TMaybe<T>.IfNone(const aProc: TProc);
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (none) procedure is missing');

  if fState <> msSome then
    aProc();
end;

{--------------------------------------------------------------------------------------------------}
procedure TMaybe<T>.IfSome(const aProc: TProc<T>);
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (some) procedure is missing');

  if fState = msSome then
    aProc(fValue);
end;

{--------------------------------------------------------------------------------------------------}
function TMaybe<T>.Tap(const aProc: TProc<T>): TMaybe<T>;
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (tap) procedure is missing');

  if self.IsSome then
    aProc(Self.Value);

  Result := self;
end;

{--------------------------------------------------------------------------------------------------}
class function TMaybe<T>.TryGet(const Func: TFunc<T>): TMaybe<T>;
begin
  Result.fState := msUnknown; // initialize not guaranteed to run

  try
    Result.SetSome(Func());
  except
    Result.SetNone;
  end;
end;

{--------------------------------------------------------------------------------------------------}
class function TMaybe<T>.MakeSome(const aValue: T): TMaybe<T>;
begin
  Result.fState := msUnknown; // initialize not guaranteed to run
  Result.SetSome(aValue);
end;

{--------------------------------------------------------------------------------------------------}
class function TMaybe<T>.MakeNone: TMaybe<T>;
begin
  Result.fState := msUnknown; // initialize not guaranteed to run
  Result.SetNone;
end;

{--------------------------------------------------------------------------------------------------}
class operator TMaybe<T>.Initialize;
begin
  fState := msUnknown;
end;

{$endregion}

{$region 'TResult<T>'}

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.IsErr: Boolean;
begin
  Result := fState <> rsOk;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.IsOk: Boolean;
begin
  Result := fState = rsOk;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.Validate(const aPredicate: TFunc<T, Boolean>; const aError: string): TResult<T>;
begin
  if (fState <> rsOk) or (aPredicate(Self.Value)) then
    Exit(Self);

  Result := TResult<T>.MakeErr(aError);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.Validate(const aPredicate: TFunc<T, Boolean>;const aErrorFunc: TFunc<T, string>): TResult<T>;
begin
  if (fState <> rsOk) or (aPredicate(Self.Value)) then
    Exit(Self);

  Result := TResult<T>.MakeErr(aErrorFunc(Self.Value));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.GetValue: T;
begin
  Ensure.IsTrue(fState = rsOk, MON_ACCESS_ERROR);

  Result := fValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.OrElse(const aFallback: T): T;
begin
  if fState = rsOk then
    Result := fValue
  else
    Result := aFallback;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.OrElseGet(const aFunc: TFunc<T>): T;
begin
  Ensure.IsTrue(Assigned(aFunc), 'Expected (else) function is missing');

  if fState = rsOk then
    Result := fValue
  else
    Result := aFunc;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResult<T>.IfErr(const aProc: TProc);
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (err) procedure is missing');

  if fState <> rsOk then
    aProc();
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResult<T>.IfOk(const aProc: TProc<T>);
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (ok) procedure is missing');

  if fState = rsOk then
    aProc(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResult<T>.Match(const aOkProc: TProc<T>; const aErrProc: TProc);
begin
  Ensure.IsTrue(Assigned(aOkProc),  'Expected (ok) procedure is missing')
        .IsTrue(Assigned(aErrProc), 'Expected (err) procedure is missing');

  if fState = rsOk then
    aOkProc(fValue)
  else
    aErrProc();
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.Match<R>(const aOkFunc: TFunc<T, R>; const aErrFunc: TFunc<string, R>): R;
begin
  Ensure.IsTrue(Assigned(aOkFunc),  'Expected (ok) procedure is missing')
        .IsTrue(Assigned(aErrFunc), 'Expected (err) procedure is missing');

  if fState = rsOk then
    Result := aOkFunc(fValue)
  else
    Result := aErrFunc(fError);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResult<T>.SetOk(const aValue: T);
begin
  Ensure.IsTrue(fState = rsUnknown, MON_INIT_ERROR);

  fState := rsOk;
  fValue := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResult<T>.SetErr(const aMessage: string);
begin
  Ensure.IsTrue(fState = rsUnknown, MON_INIT_ERROR);

  fState := rsErr;
  fError := aMessage;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResult<T>.SetErr(const aFormat: string; const aArgs: array of const);
begin
  Ensure.IsTrue(fState = rsUnknown, MON_INIT_ERROR);

  fState := rsErr;
  fError := Format(aFormat, aArgs);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.Tap(const aProc: TProc<T>): TResult<T>;
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (tap) procedure is missing');

  if fState = rsOk then
    aProc(fValue);

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.TapError(const aProc: TProc<string>): TResult<T>;
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (tap error) procedure is missing');

  if fState <> rsOk then
    aProc(fError);

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.TryGet(const Func: TFunc<T>): TResult<T>;
begin
  Result.fState := rsUnknown; // initialize not guaranteed to run
  try
    Result.SetOk(Func());
  except on E: Exception do
    Result.SetErr(E.Message);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.MakeErr(const aMessage: string): TResult<T>;
begin
  Result.fState := rsUnknown; // initialize not guaranteed to run
  Result.SetErr(aMessage);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.MakeErr(const aFormat: string; const aArgs: array of const): TResult<T>;
begin
  Result.fState := rsUnknown; // initialize not guaranteed to run
  Result.SetErr(aFormat, aArgs);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.MakeOk(const aValue: T): TResult<T>;
begin
  Result.fState := rsUnknown; // initialize not guaranteed to run
  Result.SetOk(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TResult<T>.Initialize;
begin
  fState := rsUnknown;
end;

{$endregion}

{$region 'TUsing<T>'}

{--------------------------------------------------------------------------------------------------}
function TUsing<T>.Instance(aObject: T): T;
begin
  fInstance := aObject;
  Result := fInstance;
end;

{--------------------------------------------------------------------------------------------------}
constructor TUsing<T>.Create(aObject: T);
begin
  fInstance := aObject;
end;

{--------------------------------------------------------------------------------------------------}
class operator TUsing<T>.Initialize;
begin
  fInstance := nil;
end;

{--------------------------------------------------------------------------------------------------}
class operator TUsing<T>.Finalize;
begin
  fInstance.Free;
end;

{$endregion}

{ TErrorCentral }

{--------------------------------------------------------------------------------------------------}
procedure TErrorCentral.Notify(const [ref] aException: Exception);
begin
  fSubscribers.Publish(aException);
end;

{--------------------------------------------------------------------------------------------------}
procedure TErrorCentral.Throw(const [ref] aException: Exception);
begin
  Notify(aException);

  raise aException;
end;

{--------------------------------------------------------------------------------------------------}
procedure TErrorCentral.Throw<T>(const Msg: string);
begin
  var cls := TExceptionClass(GetTypeData(TypeInfo(T))^.ClassType);
  var err := cls.Create(Msg);

  Notify(err);

  raise err;
end;

{--------------------------------------------------------------------------------------------------}
procedure TErrorCentral.Throw<T>(const Fmt: string; const Args: array of const);
begin
  var cls := TExceptionClass(GetTypeData(TypeInfo(T))^.ClassType);
  var err := cls.CreateFmt(Fmt, Args);

  Notify(err);

  raise err;
end;

{--------------------------------------------------------------------------------------------------}
class constructor TErrorCentral.Create;
begin
  fInstance := TErrorCentral.Create;
end;

{--------------------------------------------------------------------------------------------------}
constructor TErrorCentral.Create;
begin
  fSubscribers := TMulticast<Exception>.Create;
end;

{--------------------------------------------------------------------------------------------------}
destructor TErrorCentral.Destroy;
begin
  fSubscribers.Free;
end;

{--------------------------------------------------------------------------------------------------}
class destructor TErrorCentral.Destroy;
begin
  FreeAndNil(fInstance);
end;

{ TEnsure }

{--------------------------------------------------------------------------------------------------}
function TEnsure.IsBlank(const aText, aMessage: string): TEnsure;
const
  ERROR = 'Expected value to be blank.';
begin
  if not string.IsNullOrWhiteSpace(aText) then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  exit(self);
end;

{--------------------------------------------------------------------------------------------------}
function TEnsure.IsNotBlank(const aText, aMessage: string): TEnsure;
const
  ERROR = 'Expected value is missing.';
begin
  if string.IsNullOrWhiteSpace(aText) then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  exit(self);
end;

{--------------------------------------------------------------------------------------------------}
function TEnsure.IsTrue(const aCondition: boolean; const aMessage: string): TEnsure;
const
  ERROR = 'Expected condition, or value, to be true.';
begin
  if not aCondition then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  exit(self);
end;

{--------------------------------------------------------------------------------------------------}
function TEnsure.IsFalse(const aCondition: boolean; const aMessage: string): TEnsure;
const
  ERROR = 'Expected condition, or value, to be false.';
begin
  if aCondition then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  exit(self);
end;

{--------------------------------------------------------------------------------------------------}
function TEnsure.IsSame(const aLhs, aRhs, aMessage: string): TEnsure;
const
  ERROR = 'Expected the values to be the same.';
begin
  if CompareText(aLhs, aRhs) <> 0 then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  exit(self);
end;

{--------------------------------------------------------------------------------------------------}
function TEnsure.IsNotSame(const aLhs, aRhs, aMessage: string): TEnsure;
const
  ERROR = 'Expected the values to be different.';
begin
  if CompareText(aLhs, aRhs) = 0 then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  exit(self);
end;

{--------------------------------------------------------------------------------------------------}
class constructor TEnsure.Create;
begin
  fInstance := TEnsure.Create;
end;

{--------------------------------------------------------------------------------------------------}
class destructor TEnsure.Destroy;
begin
  FreeAndNil(fInstance);
end;

end.
