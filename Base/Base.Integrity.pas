{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Integrity
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Provides foundational types for enforcing code integrity, correctness, and safety.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Integrity;

interface

uses
  System.SysUtils,
  System.TypInfo,
  System.Generics.Collections,
  Base.Core,
  Base.Messaging;

const
  MON_INIT_ERROR   = 'State has already been initialized error.';
  MON_ACCESS_ERROR = 'Cannot access value of None';

type
  PTMethod = ^TMethod;

  TOptionState = (
    // initial state, used to enforce immutability, evaluates to osNone
    osUnknown,
    // some value has been set
    osSome,
    // none has been set
    osNone);

  TResultState = (
    // initial state, used to enforce immutability, evaluates to rsErr
    rsUnknown,
    // ok has been set
    rsOk,
    // err has been set
    rsErr);

  TStatusState = (
    // initial state, used to enforce immutability, evaluates to rsErr
    ssUnknown,
    // ok has been set
    ssOk,
    // err has been set
    ssErr);



  /// <summary>
  ///  Basic implementation of an optional, adapted for Delphi record/memory constraints.
  /// </summary>
  TOption<T> = record
  strict private
    fState: TOptionState;
    fValue: T;

    function GetValue: T;
  public
    property Value: T read GetValue;

    function IsSome: Boolean;
    function IsNone: Boolean;

    function OrElse(const aFallback: T): T;
    function OrElseGet(const aFunc: TConstFunc<T>): T;

    procedure IfSome(const aProc: TConstProc<T>);
    procedure IfNone(const aProc: TProc);

    procedure Match(const aSomeProc: TConstProc<T>; const aNoneProc: TProc); overload;
    function Match<R>(const aSomeFunc: TConstFunc<T, R>; const aNoneFunc: TFunc<R>): R; overload;

    function Filter(const aPredicate: TConstFunc<T, Boolean>): TOption<T>;
    function Tap(const aProc: TProc<T>): TOption<T>;

    procedure SetSome(const aValue: T);
    procedure SetNone;

    class function TryGet(const Func: TConstFunc<T>): TOption<T>; static; inline;
    function TryGetValue(out aValue: T): boolean; inline;

    class function Some(const aValue: T): TOption<T>; static; inline;
    class function None: TOption<T>; static; inline;

    class operator Initialize;
  end;

  /// <summary>
  ///  Simple status structure representing success, or an error.
  /// </summary>
  TStatus = record
  strict private
    fState: TStatusState;
    fError: string;
    fErrorToken: string;
    fErrorDetails: string;
  public
    /// <summary>the user friendly error message</summary>
    property Error: string read fError;

    /// <summary>a domain token like http.404</summary>
    property ErrorToken: string read fErrorToken;

    /// <summary>extra error information</summary>
    property ErrorDetails: string read fErrorDetails;

    function IsErr: Boolean;
    function IsOk: Boolean;

    procedure SetOk;

    procedure SetErr(const aMessage: string = ''); overload;
    procedure SetErr(const aFormat: string; const aArgs: array of const); overload;

    procedure SetErrEx(const aToken: string; const aDetails: string; const aMessage: string); overload;
    procedure SetErrEx(const aToken: string; const aDetails: string; const aFormat: string; const aArgs: array of const); overload;

    class function Ok: TStatus; static; inline;

    class function Err(const aMessage: string = ''): TStatus; overload; static; inline;
    class function Err(const aFormat: string; const aArgs: array of const): TStatus; overload; static;

    class function ErrEx(const aToken: string; const aDetails: string; const aMessage: string): TStatus; overload; static;
    class function ErrEx(const aToken: string; const aDetails: string; const aFormat: string; const aArgs: array of const): TStatus; overload; static;

    class operator Initialize;
  end;

  /// <summary>
  ///  Basic implementation of a result, adapted for Delphi record/memory constraints.
  /// </summary>
  TResult<T> = record
  strict private
    fState: TResultState;
    fError: string;
    fErrorToken: string;
    fErrorDetails: string;
    fValue: T;

    function GetValue: T;
  public
    property Value: T read GetValue;

    /// <summary>the user friendly error message</summary>
    property Error: string read fError;

    /// <summary>a domain token like http.404</summary>
    property ErrorToken: string read fErrorToken;

    /// <summary>extra error information</summary>
    property ErrorDetails: string read fErrorDetails;

    function IsErr: Boolean;
    function IsOk: Boolean;

    function OrElse(const aFallback: T): T;
    function OrElseGet(const aFunc: TConstFunc<T>): T;

    procedure IfOk(const aProc: TConstProc<T>);
    procedure IfErr(const aProc: TProc);

    procedure Match(const aOkProc: TConstProc<T>; const aErrProc: TProc); overload;
    function Match<R>(const aOkFunc: TConstFunc<T, R>; const aErrFunc: TConstFunc<string, R>): R; overload;

    function Tap(const aProc: TConstProc<T>): TResult<T>;
    function TapError(const aProc: TConstProc<string>): TResult<T>;

    function Validate(const aPredicate: TConstFunc<T, Boolean>; const aError: string): TResult<T>; overload;
    function Validate(const aPredicate: TConstFunc<T, Boolean>; const aErrorFunc: TConstFunc<T, string>): TResult<T>; overload;

    procedure SetOk(const aValue: T);

    procedure SetErr(const aMessage: string = ''); overload;
    procedure SetErr(const aFormat: string; const aArgs: array of const); overload;
    procedure SetErr(const aStatus: TStatus); overload;

    procedure SetErrEx(const aToken: string; const aDetails: string; const aMessage: string); overload;
    procedure SetErrEx(const aToken: string; const aDetails: string; const aFormat: string; const aArgs: array of const); overload;

    class function TryGet(const Func: TConstFunc<T>): TResult<T>; static; inline;

    class function Ok(const aValue: T): TResult<T>; static; inline;

    class function Err(const aMessage: string = ''): TResult<T>; overload; static; inline;
    class function Err(const aFormat: string; const aArgs: array of const): TResult<T>; overload; static;
    class function Err(const aStatus: TStatus): TResult<T>; overload; static;

    class function ErrEx(const aToken: string; const aDetails: string; const aMessage: string): TResult<T>; overload; static;
    class function ErrEx(const aToken: string; const aDetails: string; const aFormat: string; const aArgs: array of const): TResult<T>; overload; static;

    class operator Initialize;
  end;

  /// <summary>
  ///  Minimal Result Operations to support TResult - wrapping rather than chaining for Delphi ergonomics.
  /// </summary>
  TResultOp = record
  public
    /// <summary>
    ///  Transforms the success value using <paramref name="aFunc"/> if <paramref name="aRes"/> is Ok.
    ///  Err results are propagated unchanged.
    /// </summary>
    class function Map<T, U>(const aRes: TResult<T>; const aFunc: TConstFunc<T, U>): TResult<U>; static;

    /// <summary>
    ///  Chains a computation that may fail.
    ///  If aRes is Ok, calls aFunc and returns its result.
    ///  If aRes is Err, propagates the error unchanged.
    /// </summary>
    class function Bind<T, U>(const aRes: TResult<T>; const aFunc: TConstFunc<T, TResult<U>>): TResult<U>; static;

    /// <summary>
    ///  Returns the contained value if aRes is Ok; otherwise returns aDefault.
    ///  Terminal: collapses TResult&lt;T&gt; to T.
    /// </summary>
    class function UnwrapOr<T>(const aRes: TResult<T>; const aDefault: T): T; static;

    /// <summary>
    ///  Returns the contained value if aRes is Ok; otherwise computes a fallback from the error.
    ///  Terminal: collapses TResult&lt;T&gt; to T.
    /// </summary>
    class function UnwrapOrElse<T>(const aRes: TResult<T>; const aFunc: TConstFunc<string, T>): T; static;

    /// <summary>
    ///  Transforms the error message using aFunc if aRes is Err. Ok is unchanged.
    /// </summary>
    class function MapError<T>(const aRes: TResult<T>; const aFunc: TConstFunc<string, string>): TResult<T>; static;

    /// <summary>
    ///  Converts Err into Ok by producing a fallback value from the error. Ok is unchanged.
    /// </summary>
    class function Recover<T>(const aRes: TResult<T>; const aFunc: TConstFunc<string, T>): TResult<T>; static;
  end;

  EScopeCleanupError = class(Exception);

  /// <summary>
  ///  Provides scope management, conceptually similar to using/dispose in .NET
  /// </summary>
  TScope = record
  strict private
{$IFDEF DEBUG}
    fInitialized: Boolean;
{$ENDIF}

    fItems: TArray<TObject>;
    fCount: Integer;
    fActions: TArray<TProc>;
    fActionCount: Integer;

    function Remove(aObj: TObject): Boolean;

    procedure Add(aObj: TObject);

  public
    function Release<T: class>(aObj: T): T;

    function Owns<T: class>(aObj: T): T; overload;
    //function Owns<T: class>(const Factory: TFunc<T>): T; overload;

    procedure Clear;
    procedure Defer(const aAction: System.SysUtils.TProc); overload;

    class operator Assign(var  Dest: TScope; const [ref] Src: TScope);

    class operator Initialize;
    class operator Finalize;
  end;

  /// <summary>
  ///  Centralized error handling, used for notifying subscribers of exceptions,
  ///  and for raising exceptions via guard methods (Ensure).
  /// </summary>
  /// <remarks>
  ///  Access this class via the Ensure functions, or the TError function.
  /// </remarks>
  TErrorCentral = class
  private
    fOnError: TMulticast<Exception>;

    class var fInstance: TErrorCentral;

    procedure Throw<T: Exception>(const Msg: string); overload;
    procedure Throw(const [ref] aException: Exception); overload;
  public
    { subscribe for error notifications via OnError.Subscribe }
    property OnError:TMulticast<Exception> read fOnError write fOnError;

    procedure Notify(const [ref] aException: Exception);

    constructor Create;
    destructor Destroy; override;

    class constructor Create;
    class destructor Destroy;
  end;

  /// <summary>
  ///  A simple guard class integrated with TErrorCentral, for validating conditions.
  ///  It allows chaining of checks, such as: Ensure.IsTrue(...).IsBlank(...).
  /// </summary>
  /// <remarks>
  ///  Access this class via the Ensure function.
  /// </remarks>
  TEnsure = class
  private
    class var fInstance: TEnsure;
  public
    /// <summary>
    ///  Throws if the list is not empty (must be assigned, and empty).
    /// </summary>
    function IsEmpty<T>(const aList: TList<T>; const aMessage: string = ''): TEnsure;

    /// <summary>
    ///  Throws if the list is empty (must be assigned, and have values).
    /// </summary>
    function IsNotEmpty<T>(const aList: TList<T>; const aMessage: string = ''): TEnsure;

    /// <summary>
    ///  Throws if the specified text is not blank (not empty or whitespace)
    /// </summary>
    function IsBlank(const aText: string; const aMessage: string = ''): TEnsure;

    /// <summary>
    ///  Throws if the specified text is blank (empty or whitepace)
    /// </summary>
    function IsNotBlank(const aText: string; const aMessage: string = ''): TEnsure;

    /// <summary>
    ///  Throws if the specified condition is false.
    /// </summary>
    function IsTrue(const aCondition: boolean; const aMessage: string = ''): TEnsure;

    /// <summary>
    ///  Throws if the specified condition is true.
    /// </summary>
    function IsFalse(const aCondition: boolean; const aMessage: string = ''): TEnsure;

    /// <summary>
    ///  Throws if the specified condition strings are different (case-insensitive).
    /// </summary>
    function AreSameText(const aLhs: string; const aRhs: string; const aMessage: string = ''): TEnsure;

    /// <summary>
    ///  Throws if the specified condition strings are the same (case-insensitive).
    /// </summary>
    function AreDifferentText(const aLhs: string; const aRhs: string; const aMessage: string = ''): TEnsure;

    /// <summary>
    ///  Throws if the specified condition strings are different (case-sensitive).
    /// </summary>
    function AreSame(const aLhs: string; const aRhs: string; const aMessage: string = ''): TEnsure; overload;

    /// <summary>
    ///  Throws if the specified condition strings are different (case-sensitive).
    /// </summary>
    function AreSame(const aLhs: integer; const aRhs: integer; const aMessage: string = ''): TEnsure; overload;

    /// <summary>
    ///  Throws if the specified condition strings are the same (case-sensitive).
    /// </summary>
    function AreDifferent(const aLhs: string; const aRhs: string; const aMessage: string = ''): TEnsure; overload;

    /// <summary>
    ///  Throws if the specified condition strings are the same (case-sensitive).
    /// </summary>
    function AreDifferent(const aLhs: integer; const aRhs: integer; const aMessage: string = ''): TEnsure; overload;

    /// <summary>
    ///  Throws if the value is not in the specified range.
    /// </summary>
    function InRange(const aValue: integer; const aMin: integer; const aMax: integer; const aMessage: string = ''): TEnsure; overload;

    /// <summary>
    ///  Throws if the is in the specified range.
    /// </summary>
    function NotInRange(const aValue: integer; const aMin: integer; const aMax: integer; const aMessage: string = ''): TEnsure; overload;

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

{----------------------------------------------------------------------------------------------------------------------}
function TError: TErrorCentral;
begin
  Result := TErrorCentral.fInstance;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Ensure: TEnsure;
begin
  Result := TEnsure.fInstance;
end;

{$endregion}

{$region 'TOption<T>'}

{----------------------------------------------------------------------------------------------------------------------}
function TOption<T>.IsNone: Boolean;
begin
  Result := fState <> osSome;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOption<T>.IsSome: Boolean;
begin
  Result := fState = osSome;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOption<T>.GetValue: T;
begin
  Ensure.IsTrue(fState = osSome, MON_ACCESS_ERROR);

  Result := fValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TOption<T>.SetSome(const aValue: T);
begin
  Ensure.IsTrue(fState = osUnknown, MON_INIT_ERROR);

  fState := osSome;
  fValue := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TOption<T>.SetNone;
begin
  Ensure.IsTrue(fState = osUnknown, MON_INIT_ERROR);

  fState := osNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOption<T>.Filter(const aPredicate: TConstFunc<T, Boolean>): TOption<T>;
begin
  Ensure.IsTrue(Assigned(aPredicate), 'Expected (filter) function is missing');

  if fState <> osSome then exit(self);

  if aPredicate(self.Value) then
    exit(self);

  Result := TOption<T>.None;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOption<T>.OrElse(const aFallback: T): T;
begin
  if fState = osSome then
    Result := fValue
  else
    Result := aFallback;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOption<T>.OrElseGet(const aFunc: TConstFunc<T>): T;
begin
  Ensure.IsTrue(Assigned(aFunc), 'Expected (else) function is missing');

  if fState = osSome then
    Result := fValue
  else
    Result := aFunc;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TOption<T>.Match(const aSomeProc: TConstProc<T>; const aNoneProc: TProc);
begin
  Ensure.IsTrue(Assigned(aSomeProc), 'Expected (some) procedure is missing')
        .IsTrue(Assigned(aNoneProc), 'Expected (none) procedure is missing');

  if fState = osSome then
    aSomeProc(fValue)
  else
    aNoneProc();
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOption<T>.Match<R>(const aSomeFunc: TConstFunc<T, R>; const aNoneFunc: TFunc<R>): R;
begin
  Ensure.IsTrue(Assigned(aSomeFunc), 'Expected (some) procedure is missing')
        .IsTrue(Assigned(aNoneFunc), 'Expected (none) procedure is missing');

 if fState = osSome then
    Result := aSomeFunc(fValue)
  else
    Result := aNoneFunc();
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TOption<T>.IfNone(const aProc: TProc);
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (none) procedure is missing');

  if fState <> osSome then
    aProc();
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TOption<T>.IfSome(const aProc: TConstProc<T>);
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (some) procedure is missing');

  if fState = osSome then
    aProc(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOption<T>.Tap(const aProc: TProc<T>): TOption<T>;
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (tap) procedure is missing');

  if self.IsSome then
    aProc(Self.Value);

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TOption<T>.TryGet(const Func: TConstFunc<T>): TOption<T>;
begin
  Result.fState := osUnknown; // initialize not guaranteed to run

  try
    Result.SetSome(Func());
  except
    Result.SetNone;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOption<T>.TryGetValue(out aValue: T): boolean;
begin
  if IsSome then
  begin
    aValue := fValue;
    exit(true);
  end;

  aValue := default(T);
  Result := false;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TOption<T>.Some(const aValue: T): TOption<T>;
begin
  Result.fState := osUnknown; // initialize not guaranteed to run
  Result.SetSome(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TOption<T>.None: TOption<T>;
begin
  Result.fState := osUnknown; // initialize not guaranteed to run
  Result.SetNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TOption<T>.Initialize;
begin
  fState := osUnknown;
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
function TResult<T>.Validate(const aPredicate: TConstFunc<T, Boolean>; const aError: string): TResult<T>;
begin
  if (fState <> rsOk) or (aPredicate(Self.Value)) then
    Exit(Self);

  Result := TResult<T>.Err(aError);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.Validate(const aPredicate: TConstFunc<T, Boolean>;const aErrorFunc: TConstFunc<T, string>): TResult<T>;
begin
  if (fState <> rsOk) or (aPredicate(Self.Value)) then
    Exit(Self);

  Result := TResult<T>.Err(aErrorFunc(Self.Value));
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
function TResult<T>.OrElseGet(const aFunc: TConstFunc<T>): T;
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
procedure TResult<T>.IfOk(const aProc: TConstProc<T>);
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (ok) procedure is missing');

  if fState = rsOk then
    aProc(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResult<T>.Match(const aOkProc: TConstProc<T>; const aErrProc: TProc);
begin
  Ensure.IsTrue(Assigned(aOkProc),  'Expected (ok) procedure is missing')
        .IsTrue(Assigned(aErrProc), 'Expected (err) procedure is missing');

  if fState = rsOk then
    aOkProc(fValue)
  else
    aErrProc();
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.Match<R>(const aOkFunc: TConstFunc<T, R>; const aErrFunc: TConstFunc<string, R>): R;
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
procedure TResult<T>.SetErrEx(const aToken, aDetails, aMessage: string);
begin
  Ensure.IsTrue(fState = rsUnknown, MON_INIT_ERROR);

  fState := rsErr;
  fError := aMessage;
  fErrorToken := aToken;
  fErrorDetails := aDetails;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResult<T>.SetErr(const aStatus: TStatus);
begin
  Ensure.IsTrue(fState = rsUnknown, MON_INIT_ERROR);

  fState := rsErr;
  fError := aStatus.Error;
  fErrorToken := aStatus.ErrorToken;
  fErrorDetails := aStatus.Error;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TResult<T>.SetErrEx(const aToken, aDetails, aFormat: string; const aArgs: array of const);
begin
  Ensure.IsTrue(fState = rsUnknown, MON_INIT_ERROR);

  fState := rsErr;
  fError := Format(aFormat, aArgs);
  fErrorToken := aToken;
  fErrorDetails := aDetails;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.Tap(const aProc: TConstProc<T>): TResult<T>;
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (tap) procedure is missing');

  if fState = rsOk then
    aProc(fValue);

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TResult<T>.TapError(const aProc: TConstProc<string>): TResult<T>;
begin
  Ensure.IsTrue(Assigned(aProc), 'Expected (tap error) procedure is missing');

  if fState <> rsOk then
    aProc(fError);

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.TryGet(const Func: TConstFunc<T>): TResult<T>;
begin
  Result.fState := rsUnknown; // initialize not guaranteed to run
  try
    Result.SetOk(Func());
  except on E: Exception do
    Result.SetErr(E.Message);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.Err(const aMessage: string): TResult<T>;
begin
  Result.fState := rsUnknown; // initialize not guaranteed to run
  Result.SetErr(aMessage);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.Err(const aFormat: string; const aArgs: array of const): TResult<T>;
begin
  Result.fState := rsUnknown; // initialize not guaranteed to run
  Result.SetErr(aFormat, aArgs);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.Err(const aStatus: TStatus): TResult<T>;
begin
  Result.fState := rsUnknown; // initialize not guaranteed to run
  Result.SetErr(aStatus);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.ErrEx(const aToken, aDetails, aMessage: string): TResult<T>;
begin
  Result.fState := rsUnknown; // initialize not guaranteed to run
  Result.SetErrEx(aToken, aDetails, aMessage);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.ErrEx(const aToken, aDetails, aFormat: string; const aArgs: array of const): TResult<T>;
begin
  Result.fState := rsUnknown; // initialize not guaranteed to run
  Result.SetErrEx(aToken, aDetails, aFormat, aArgs);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResult<T>.Ok(const aValue: T): TResult<T>;
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

{$region 'TStatus' }

{----------------------------------------------------------------------------------------------------------------------}
function TStatus.IsOk: Boolean;
begin
  Result := fState = ssOk;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStatus.SetOk;
begin
  Ensure.IsTrue(fState = ssUnknown, MON_INIT_ERROR);

  fState := ssOk;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TStatus.Ok: TStatus;
begin
  Result.fState := ssUnknown; // initialize not guaranteed to run
  Result.SetOk;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TStatus.IsErr: Boolean;
begin
  Result := fState <> ssOk;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStatus.SetErr(const aMessage: string);
begin
  Ensure.IsTrue(fState = ssUnknown, MON_INIT_ERROR);

  fState := ssErr;
  fError := aMessage;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStatus.SetErr(const aFormat: string; const aArgs: array of const);
begin
  Ensure.IsTrue(fState = ssUnknown, MON_INIT_ERROR);

  fState := ssErr;
  fError := Format(aFormat, aArgs);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStatus.SetErrEx(const aToken, aDetails, aMessage: string);
begin
  Ensure.IsTrue(fState = ssUnknown, MON_INIT_ERROR);

  fState := ssErr;
  fError := aMessage;
  fErrorToken := aToken;
  fErrorDetails := aDetails;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStatus.SetErrEx(const aToken, aDetails, aFormat: string; const aArgs: array of const);
begin
  Ensure.IsTrue(fState = ssUnknown, MON_INIT_ERROR);

  fState := ssErr;
  fError := Format(aFormat, aArgs);
  fErrorToken := aToken;
  fErrorDetails := aDetails;
end;
{----------------------------------------------------------------------------------------------------------------------}
class function TStatus.Err(const aMessage: string): TStatus;
begin
  Result.fState := ssUnknown; // initialize not guaranteed to run
  Result.SetErr(aMessage);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TStatus.Err(const aFormat: string; const aArgs: array of const): TStatus;
begin
  Result.fState := ssUnknown; // initialize not guaranteed to run
  Result.SetErr(aFormat, aArgs);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TStatus.ErrEx(const aToken, aDetails, aMessage: string): TStatus;
begin
  Result.fState := ssUnknown; // initialize not guaranteed to run
  Result.SetErrEx(aToken, aDetails, aMessage);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TStatus.ErrEx(const aToken, aDetails, aFormat: string; const aArgs: array of const): TStatus;
begin
  Result.fState := ssUnknown; // initialize not guaranteed to run
  Result.SetErrEx(aToken, aDetails, aFormat, aArgs);
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TStatus.Initialize;
begin
  fState := ssUnknown;
end;

{$endregion}

{ TErrorCentral }

{----------------------------------------------------------------------------------------------------------------------}
procedure TErrorCentral.Notify(const [ref] aException: Exception);
begin
  fOnError.Publish(aException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TErrorCentral.Throw(const [ref] aException: Exception);
begin
  Notify(aException);

  raise aException;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TErrorCentral.Throw<T>(const Msg: string);
begin
  var cls := TExceptionClass(GetTypeData(TypeInfo(T))^.ClassType);
  var err := cls.Create(Msg);

  Throw(err);
end;

{----------------------------------------------------------------------------------------------------------------------}
class constructor TErrorCentral.Create;
begin
  fInstance := TErrorCentral.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TErrorCentral.Create;
begin
  fOnError := TMulticast<Exception>.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TErrorCentral.Destroy;
begin
  fOnError.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor TErrorCentral.Destroy;
begin
  FreeAndNil(fInstance);
end;

{ TEnsure }

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.IsEmpty<T>(const aList: TList<T>; const aMessage: string): TEnsure;
const
  ERROR = 'Expected an empty list.';
begin
  if (not Assigned(aList)) or (not (aList.IsEmpty)) then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.IsNotEmpty<T>(const aList: TList<T>; const aMessage: string = ''): TEnsure;
const
  ERROR = 'Expected a list with values.';
begin
  if (not Assigned(aList)) or (aList.IsEmpty) then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.IsBlank(const aText, aMessage: string): TEnsure;
const
  ERROR = 'Expected value to be blank.';
begin
  if not string.IsNullOrWhiteSpace(aText) then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.IsNotBlank(const aText, aMessage: string): TEnsure;
const
  ERROR = 'Expected value is missing.';
begin
  if string.IsNullOrWhiteSpace(aText) then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.IsTrue(const aCondition: boolean; const aMessage: string): TEnsure;
const
  ERROR = 'Expected condition, or value, to be true.';
begin
  if not aCondition then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.IsFalse(const aCondition: boolean; const aMessage: string): TEnsure;
const
  ERROR = 'Expected condition, or value, to be false.';
begin
  if aCondition then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else ERROR;
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.AreSame(const aLhs, aRhs: integer; const aMessage: string): TEnsure;
const
  ERROR = 'Expected the values to be the same: %d <> %d';
begin
  if aLhs <> aRhs then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else Format(ERROR, [aLhs, aRhs]);
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.AreDifferent(const aLhs, aRhs: integer; const aMessage: string): TEnsure;
const
  ERROR = 'Expected the values to be different: %d = %d';
begin
  if aLhs = aRhs then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else Format(ERROR, [aLhs, aRhs]);
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.AreSameText(const aLhs, aRhs, aMessage: string): TEnsure;
const
  ERROR = 'Expected the values to be the same (case-insensitive): %s <> %s';
begin
  if CompareText(aLhs, aRhs) <> 0 then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else Format(ERROR, [aLhs, aRhs]);
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.AreDifferentText(const aLhs, aRhs, aMessage: string): TEnsure;
const
  ERROR = 'Expected the values to be different (case-insensitive): %s = %s';
begin
  if CompareText(aLhs, aRhs) = 0 then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else Format(ERROR, [aLhs, aRhs]);
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.AreSame(const aLhs, aRhs, aMessage: string): TEnsure;
const
  ERROR = 'Expected the values to be the same (case-sensitive): %s <> %s';
begin
  if CompareStr(aLhs, aRhs) <> 0 then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else Format(ERROR, [aLhs, aRhs]);
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.AreDifferent(const aLhs, aRhs, aMessage: string): TEnsure;
const
  ERROR = 'Expected the values to be different (case-sensitive): %s = %s';
begin
  if CompareStr(aLhs, aRhs) = 0 then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else Format(ERROR, [aLhs, aRhs]);
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.InRange(const aValue: integer; const aMin: integer; const aMax: integer; const aMessage: string = ''): TEnsure;
const
  ERROR = 'Expected the value (%d) to be in the range: %d..%d';
begin
  if (aValue < aMin) or (aValue > aMax) then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else Format(ERROR, [aValue, aMin, aMax]);
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEnsure.NotInRange(const aValue: integer; const aMin: integer; const aMax: integer; const aMessage: string = ''): TEnsure;
const
  ERROR = 'Expected the value (%d) not to be in the range: %d..%d';
begin
  if (aValue >= aMin) and (aValue <= aMax) then
  begin
    var msg := if Length(aMessage) > 0 then aMessage else Format(ERROR, [aValue, aMin, aMax]);
    TError.Throw<EArgumentException>(msg);
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
class constructor TEnsure.Create;
begin
  fInstance := TEnsure.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor TEnsure.Destroy;
begin
  FreeAndNil(fInstance);
end;

{ TResultOps }

{----------------------------------------------------------------------------------------------------------------------}
class function TResultOp.Bind<T, U>(const aRes: TResult<T>; const aFunc: TConstFunc<T, TResult<U>>): TResult<U>;
begin
  if aRes.IsOk then
    Exit(aFunc(aRes.Value));

  Result := TResult<U>.Err(aRes.Error);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResultOp.Map<T, U>(const aRes: TResult<T>; const aFunc: TConstFunc<T, U>): TResult<U>;
begin
  if aRes.IsOk then
    Exit(TResult<U>.Ok(aFunc(aRes.Value)));

  Result := TResult<U>.Err(aRes.Error);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResultOp.MapError<T>(const aRes: TResult<T>; const aFunc: TConstFunc<string, string>): TResult<T>;
begin
  if aRes.IsOk then
    Exit(aRes);

  Result := TResult<T>.Err(aFunc(aRes.Error));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResultOp.Recover<T>(const aRes: TResult<T>; const aFunc: TConstFunc<string, T>): TResult<T>;
begin
  if aRes.IsOk then
    Exit(aRes);

  Result := TResult<T>.Ok(aFunc(aRes.Error));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResultOp.UnwrapOr<T>(const aRes: TResult<T>; const aDefault: T): T;
begin
  if aRes.IsOk then
    Exit(aRes.Value);

  Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TResultOp.UnwrapOrElse<T>(const aRes: TResult<T>; const aFunc: TConstFunc<string, T>): T;
begin
  if aRes.IsOk then
    Exit(aRes.Value);

  Result := aFunc(aRes.Error);
end;

{ TScope }

{----------------------------------------------------------------------------------------------------------------------}
function TScope.Owns<T>(aObj: T): T;
begin
  if aObj = nil then exit(nil);

  for var i := 0 to Pred(fCount) do
    if fItems[i] = TObject(aObj) then exit(aObj);

  Add(aObj);

  Result := AObj;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TScope.Release<T>(aObj: T): T;
begin
  if Remove(aObj) then exit(aObj);

  Result := nil;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TScope.Add(aObj: TObject);
begin
  if aObj = nil then exit;

  if Length(fItems) = fCount then
  begin
    var NewCap := Length(fItems);
    if NewCap = 0 then NewCap := 4 else NewCap := NewCap * 2;
    SetLength(fItems, NewCap);
  end;

  fItems[fCount] := aObj;
  Inc(fCount);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TScope.Remove(aObj: TObject): Boolean;
begin
  if fCount = 0 then exit(false);

  for var i := 0 to Pred(fCount) do
  begin
    if fItems[i] = TObject(AObj) then
    begin
      Dec(fCount);
      fItems[i] := fItems[fCount];
      fItems[fCount] := nil;
      Exit(True);
    end;
  end;

  Result := false;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TScope.Defer(const aAction: TProc);
begin
{$IFDEF DEBUG}
  Assert(fInitialized, 'TScope was not initialized');
{$ENDIF}

  if not Assigned(aAction) then
    Exit;

  if Length(fActions) = fActionCount then
  begin
    var NewCap := Length(fActions);

    if NewCap = 0 then
      NewCap := 1
    else
      NewCap := NewCap * 2;
    SetLength(fActions, NewCap);
  end;

  fActions[fActionCount] := aAction;
  Inc(fActionCount);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TScope.Clear;
const
  ERR_MESSAGE = 'Error occurred freeing scoped item: %d %s %s';
begin
  for var i := Pred(fCount) downto 0 do
  begin
    try
      var item := fItems[i];
      fItems[i] := nil;

      if Assigned(item) then
        item.Free
    except
      on E: Exception do
      begin
        var Err := EScopeCleanupError.CreateFmt(ERR_MESSAGE, [i, E.ClassName, E.Message]);
        try
          try
            TError.Notify(Err);
          except
            // keep cleanup best-effort
          end;
        finally
          Err.Free;
        end;
      end;
    end;
  end;

  fCount := 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TScope.Assign(var Dest: TScope; const [ref] Src: TScope);
begin
  if (Dest.fCount <> 0) or (Src.fCount <> 0) then
    raise Exception.Create('TScope is scope-only; do not copy/assign it while owning instances.');

  Dest.fItems := nil;
  Dest.fCount := 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TScope.Initialize;
begin
{$IFDEF DEBUG}
  fInitialized := True;
{$ENDIF}

  SetLength(fActions, 1);
  fActionCount := 0;

  SetLength(fItems, 4);
  fCount := 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TScope.Finalize;
const
  ERR_MESSAGE = 'Error occurred executing action on exiting scope: %s %s';
begin
{$IFDEF DEBUG}
  Assert(fInitialized, 'TScope was not initialized');
{$ENDIF}

  // Detach to protect against reentrancy
  var actions := fActions;
  var actionCount := if actions = nil then 0 else fActionCount;
  fActions := nil;
  fActionCount := 0;

  try
    while actionCount > 0 do
    begin
      Dec(actionCount);

      var action := actions[actionCount];
      actions[actionCount] := nil;

      try
        if Assigned(action) then
          action();
      except
        on E: Exception do
        begin
          var Err := EScopeCleanupError.CreateFmt(ERR_MESSAGE, [E.ClassName, E.Message]);
          try
            try
              TError.Notify(Err);
            except
              // swallow: finalizer must not raise
            end;
          finally
            Err.Free;
          end;
        end;
      end;

    end;

    // Even if something went wrong above, still attempt to clear items.
    try
      Clear;
    except
      // defensive: finalizer must not raise.
    end;
  finally
    fCount := 0;
    fItems := nil;
  end;
end;

end.
