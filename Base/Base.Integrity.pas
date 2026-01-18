unit Base.Integrity;

interface

uses
  System.SysUtils;

type
  TMaybeState = (
    /// <summary>State has not been initialized</summary>
    msUnknown,
    /// <summary>None has been set.</summary>
    msNone,
    /// <summary>Some has been set.</summary>
    msSome
  );

  /// <summary>
  /// Represents an optional value. Inspired by Option/Maybe monads.
  /// </summary>
  /// <typeparam name="T">Type of the optional value</typeparam>
  TMaybe<T> = record
  private
    fState: TMaybeState;
    fValue: T;

    function GetValue: T;

    procedure SetSome(const aValue: T);
    procedure SetNone;
  public
    /// <summary>
    /// Gets the value if successful, raises an exception if no value was set.
    /// Sets the value if no state has been set, raises if it has (avoids record duplication)
    /// </summary>
    property Value: T read GetValue;

    /// <summary>Returns true if value is present.</summary>
    function IsSome: Boolean;

    /// <summary>Returns true if no value is present, or not initialized.</summary>
    function IsNone: Boolean;

    /// <summary>Returns the value if present, otherwise the fallback.</summary>
    function OrElse(const aFallback: T): T;

    /// <summary>Returns the value if present, otherwise computes it from the function.</summary>
    function OrElseGet(aFunc: TFunc<T>): T;

    /// <summary>
    /// Initializes with the specified value, this reduces duplication with a pre-allocated result.
    /// </summary>
    procedure InitSome(const aValue: T);

    /// <summary>
    /// Initializes with the none value, this reduces duplication with a pre-allocation result.
    /// </summary>
    procedure InitNone;

    /// <summary>Constructs a TMaybe with a value.</summary>
    class function Some(const aValue: T): TMaybe<T>; overload; static;

    /// <summary>Constructs an empty TMaybe.</summary>
    class function None: TMaybe<T>; static;

    /// <summary>Initializes the default state.</summary>
    class operator Initialize;
  end;

  /// <summary>
  /// Represents the result of an operation: either a value or an error.
  /// </summary>
  /// <typeparam name="T">Type of the value on success</typeparam>
  TResult<T> = record
  private
    fValue: T;
    fError: string;
    fOk: Boolean;

    function GetValue: T;
    function GetError: string;

  public
    /// <summary>
    /// Gets the success value.
    /// </summary>
    /// <remarks>
    /// This is only valid when <c>IsOk</c> is True.
    /// </remarks>
    property Value: T read GetValue;

    /// <summary>
    /// Gets the error message.
    /// </summary>
    /// <remarks>
    /// This is only valid when <c>IsErr</c> is True.
    /// </remarks>
    property Error: string read GetError;

    /// <summary>
    /// Returns True if this result represents success (contains a value).
    /// </summary>
    function IsOk: Boolean;

    /// <summary>
    /// Returns True if this result represents failure (contains an error message).
    /// </summary>
    function IsErr: Boolean;

    /// <summary>
    /// Returns the contained value if this result is Ok; otherwise returns <paramref name="Default"/>.
    /// <para>
    /// This is similar to Optional/Maybe "unwrap-or-default".
    /// </para>
    /// </summary>
    function OrElse(const aDefault: T): T;

   /// <summary>
    /// Returns the contained value if this result is Ok; otherwise computes a fallback value.
    /// <para>
    /// The fallback function receives the error message and must return a value of type <c>T</c>.
    /// This is the lazy (deferred) form of <c>OrElse</c>.
    /// </para>
    /// </summary>
    function OrElseGet(const aFallback: TFunc<string, T>): T;

    /// <summary>
    /// Creates a successful result containing <paramref name="aValue"/>.
    /// </summary>
    class function Ok(const aValue: T): TResult<T>; static;

    /// <summary>
    /// Creates a failed result containing an error message <paramref name="aMessage"/>.
    /// </summary>
    class function Err(const aMessage: string = ''): TResult<T>; static;

    /// <summary>
    /// Executes <paramref name="Func"/> and returns Ok(value) if it completes.
    /// If an exception is raised, returns Err(exception message) instead.
    /// </summary>
    class function TryGet(const Func: TFunc<T>): TResult<T>; static;

    /// <summary>
    /// Executes <paramref name="Proc"/> and returns Ok(True) if it completes.
    /// If an exception is raised, returns Err(exception message) instead.
    /// </summary>
    class function TryDo(const Proc: TProc): TResult<Boolean>; static;

    /// <summary>
    /// If <paramref name="Res"/> is Ok and <paramref name="Predicate"/> returns False,
    /// returns Err(<paramref name="ErrorMessage"/>). Otherwise returns <paramref name="Res"/>.
    /// Err results are propagated unchanged.
    /// </summary>
    class function Ensure(const Res: TResult<T>; const Predicate: TFunc<T, Boolean>; const ErrorMessage: string): TResult<T>; overload; static;

    /// <summary>
    /// If <paramref name="Res"/> is Ok and <paramref name="Predicate"/> returns False,
    /// returns Err(<paramref name="ErrorMessage"/>). Otherwise returns <paramref name="Res"/>.
    /// Err results are propagated unchanged.
    /// </summary>
    class function Ensure(const Res: TResult<T>; const Predicate: TFunc<T, Boolean>; const ErrorFactory: TFunc<T, string>): TResult<T>; overload; static;
  end;

  /// <summary>
  /// Delphi generic limitations in records prohibit result chaining, so we wrap instead.
  /// </summary>
  /// <remarks>
  /// Terminology:
  /// <list type="bullet">
  /// <item><description><c>Map</c> transforms the Ok value only.</description></item>
  /// <item><description><c>Bind</c> (i.e. AndThen) chains operations that return TResult.</description></item>
  /// <item><description><c>Match</c> handles both Ok and Err cases explicitly.</description></item>
  /// </list>
  /// </remarks>
  TResultOps = record
  public
    /// <summary>
    /// Chains a computation that may fail.
    /// <para>
    /// If <paramref name="Res"/> is Ok, calls <paramref name="F"/> and returns its result.
    /// If <paramref name="Res"/> is Err, the error is propagated unchanged.
    /// </para>
    /// <para>
    /// This is also known as "AndThen" / "FlatMap".
    /// </para>
    /// </summary>
    class function Bind<T, U>(const R: TResult<T>; const F: TFunc<T, TResult<U>>): TResult<U>; static;

    /// <summary>
    /// Transforms the success value using <paramref name="F"/> if <paramref name="Res"/> is Ok.
    /// <para>
    /// If <paramref name="Res"/> is Err, the error is propagated unchanged.
    /// </para>
    /// <para>
    /// Equivalent to "Select" in LINQ and "map" in functional programming.
    /// </para>
    /// </summary>
    class function Map<T, U>(const R: TResult<T>; const F: TFunc<T, U>): TResult<U>; static;

    /// <summary>
    /// Transforms the error message using <paramref name="F"/> if <paramref name="Res"/> is Err.
    /// <para>
    /// If <paramref name="Res"/> is Ok, it is returned unchanged.
    /// </para>
    /// <para>
    /// This is useful for adding context to errors (e.g. prefixing a message with the current operation).
    /// </para>
    /// </summary>
    class function MapError<T>(const R: TResult<T>; const F: TFunc<string, string>): TResult<T>; static;

    /// <summary>
    /// Converts an Err result into an Ok result by providing a fallback value.
    /// <para>
    /// If <paramref name="Res"/> is Err, <paramref name="F"/> is called with the error message and must return a value of type <c>T</c>.
    /// If <paramref name="Res"/> is Ok, it is returned unchanged.
    /// </para>
    /// </summary>
    class function Recover<T>(const R: TResult<T>; const F: TFunc<string, T>): TResult<T>; static;

    /// <summary>
    /// Executes <paramref name="Action"/> for side-effects when <paramref name="Res"/> is Ok.
    /// <para>
    /// The original result is returned unchanged.
    /// </para>
    /// <para>
    /// Useful for logging/debugging without changing the pipeline.
    /// (Also known as "OnSuccess" in some libraries.)
    /// </para>
    /// </summary>
    class function Tap<T>(const Res: TResult<T>; const Action: TProc<T>): TResult<T>; static;

    /// <summary>
    /// Executes <paramref name="Action"/> for side-effects when <paramref name="Res"/> is Err.
    /// <para>
    /// The original result is returned unchanged.
    /// </para>
    /// <para>
    /// Useful for logging/debugging errors without changing the pipeline.
    /// (Also known as "OnError" in some libraries.)
    /// </para>
    /// </summary>
    class function TapError<T>(const Res: TResult<T>; const Action: TProc<string>): TResult<T>; static;

    /// <summary>
    /// Consumes a result by executing exactly one of two branches.
    /// <para>
    /// If <paramref name="Res"/> is Ok, <paramref name="OnOk"/> is called and its return value is returned.
    /// If <paramref name="Res"/> is Err, <paramref name="OnErr"/> is called and its return value is returned.
    /// </para>
    /// <para>
    /// This is commonly called "Match" or "Fold" in functional programming.
    /// </para>
    /// </summary>
    class function Match<T, R>(const Res: TResult<T>; const OnOk: TFunc<T, R>; const OnErr: TFunc<string, R>): R; overload; static;

    /// <summary>
    /// Consumes a result by executing exactly one of two procedures.
    /// <para>
    /// If <paramref name="Res"/> is Ok, <paramref name="OnOk"/> is called.
    /// If <paramref name="Res"/> is Err, <paramref name="OnErr"/> is called.
    /// </para>
    /// <para>
    /// This is commonly called "Match" or "Fold" in functional programming.
    /// </para>
    /// </summary>
    class procedure Match<T>(const Res: TResult<T>; const OnOk: TProc<T>; const OnErr: TProc<string>); overload; static;

    /// <summary>
    /// Returns the contained value if <paramref name="Res"/> is Ok; otherwise returns <paramref name="Default"/>.
    /// <para>
    /// This is a terminal operation that collapses a TResult&lt;T&gt; into a plain value of type <c>T</c>.
    /// </para>
    /// <para>
    /// Equivalent to Optional/Maybe "unwrap-or-default" and similar to LINQ's "FirstOrDefault" semantics
    /// (i.e. it never throws just because the result is Err).
    /// </para>
    /// </summary>
    class function UnwrapOr<T>(const Res: TResult<T>; const Default: T): T; static;

    /// <summary>
    /// Returns the contained value if <paramref name="Res"/> is Ok; otherwise computes a fallback value.
    /// <para>
    /// The fallback function receives the error message and must return a value of type <c>T</c>.
    /// This is the lazy (deferred) form of <c>UnwrapOr</c>.
    /// </para>
    /// <para>
    /// This is a terminal operation that collapses a TResult&lt;T&gt; into a plain value of type <c>T</c>.
    /// </para>
    /// </summary>
    class function UnwrapOrElse<T>(const Res: TResult<T>; const Fallback: TFunc<string, T>): T; static;
  end;

implementation

{ TMaybe<T> }

{--------------------------------------------------------------------------------------------------}
function TMaybe<T>.IsSome: Boolean;
begin
  Result := fState = msSome;
end;

{--------------------------------------------------------------------------------------------------}
class operator TMaybe<T>.Initialize;
begin
  fState := msUnknown;
end;

{--------------------------------------------------------------------------------------------------}
procedure TMaybe<T>.InitNone;
begin

end;

{--------------------------------------------------------------------------------------------------}
procedure TMaybe<T>.InitSome(const aValue: T);
begin

end;

{--------------------------------------------------------------------------------------------------}
function TMaybe<T>.IsNone: Boolean;
begin
  Result := fState <> msSome;
end;

{--------------------------------------------------------------------------------------------------}
function TMaybe<T>.GetValue: T;
begin
  if fState <> msSome then
    raise Exception.Create('Cannot access value of None');

  Result := fValue;
end;

{--------------------------------------------------------------------------------------------------}
procedure TMaybe<T>.SetNone;
begin
  if fState <> msUnknown then
    raise Exception.Create('State has already been assigned');

  fState := msUnknown;
end;

{--------------------------------------------------------------------------------------------------}
procedure TMaybe<T>.SetSome(const aValue: T);
begin
  if fState <> msUnknown then
    raise Exception.Create('State has already been assigned');

  fState := msSome;
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
function TMaybe<T>.OrElseGet(aFunc: TFunc<T>): T;
begin
  if fState = msSome then
    Result := fValue
  else
    Result := aFunc();
end;

{--------------------------------------------------------------------------------------------------}
class function TMaybe<T>.Some(const aValue: T): TMaybe<T>;
begin
  Result.fState := msSome;
  Result.fValue := aValue;
end;

{--------------------------------------------------------------------------------------------------}
class function TMaybe<T>.None: TMaybe<T>;
begin
  Result.fState := msNone;
end;

{ TResult<T> }

{--------------------------------------------------------------------------------------------------}
function TResult<T>.OrElse(const aDefault: T): T;
begin
  Result := if IsOk then fValue else aDefault;
end;

{--------------------------------------------------------------------------------------------------}
function TResult<T>.OrElseGet(const aFallback: TFunc<string, T>): T;
begin
  if IsOk then exit(fValue);

  Result := aFallback(Self.FError);
end;

{--------------------------------------------------------------------------------------------------}
function TResult<T>.IsOk: Boolean;
begin
  Result := FOk;
end;

{--------------------------------------------------------------------------------------------------}
function TResult<T>.IsErr: Boolean;
begin
  Result := not FOk;
end;

{--------------------------------------------------------------------------------------------------}
function TResult<T>.GetValue: T;
begin
  if not FOk then
    raise Exception.Create('Cannot access Value of Err result');

  Result := FValue;
end;

{--------------------------------------------------------------------------------------------------}
function TResult<T>.GetError: string;
begin
  Result := FError;
end;

{--------------------------------------------------------------------------------------------------}
class function TResult<T>.Ok(const AValue: T): TResult<T>;
begin
  Result.fValue := AValue;
  Result.fOk := True;
end;

{--------------------------------------------------------------------------------------------------}
class function TResult<T>.Err(const aMessage: string): TResult<T>;
begin
  Result.fOk := False;
  Result.fError := aMessage;
end;

{--------------------------------------------------------------------------------------------------}
class function TResult<T>.TryGet(const Func: TFunc<T>): TResult<T>;
begin
  try
    Result := Ok(Func());
  except
    on E: Exception do
      Result := Err(E.Message);
  end;
end;

{--------------------------------------------------------------------------------------------------}
class function TResult<T>.TryDo(const Proc: TProc): TResult<Boolean>;
begin
  try
    Proc();
    Result := TResult<Boolean>.Ok(True);
  except
    on E: Exception do
      Result := TResult<Boolean>.Err(E.Message);
  end;
end;

{--------------------------------------------------------------------------------------------------}
class function TResult<T>.Ensure(
  const Res: TResult<T>;
  const Predicate: TFunc<T, Boolean>;
  const ErrorMessage: string
): TResult<T>;
begin
  if Res.IsErr then
    Exit(Res);

  if Predicate(Res.Value) then
    Exit(Res);

  Result := Err(ErrorMessage);
end;

{--------------------------------------------------------------------------------------------------}
class function TResult<T>.Ensure(
  const Res: TResult<T>;
  const Predicate: TFunc<T, Boolean>;
  const ErrorFactory: TFunc<T, string>
): TResult<T>;
begin
  if Res.IsErr then
    Exit(Res);

  if Predicate(Res.Value) then
    Exit(Res);

  Result := Err(ErrorFactory(Res.Value));
end;

{ TResultOps }

{--------------------------------------------------------------------------------------------------}
class function TResultOps.Bind<T, U>(const R: TResult<T>; const F: TFunc<T, TResult<U>>): TResult<U>;
begin
  // If Ok, run the next computation.
  if R.IsOk then
    Exit(F(R.Value));

  // If Err, propagate the existing error.
  Result := TResult<U>.Err(R.Error);
end;

{--------------------------------------------------------------------------------------------------}
class function TResultOps.Map<T, U>(const R: TResult<T>; const F: TFunc<T, U>): TResult<U>;
begin
  // If R is Ok, transform the value.
  if R.IsOk then
    Exit(TResult<U>.Ok(F(R.Value)));

  // If R is Err, propagate the error unchanged.
  Result := TResult<U>.Err(R.Error);
end;

{--------------------------------------------------------------------------------------------------}
class function TResultOps.MapError<T>(const R: TResult<T>; const F: TFunc<string, string>): TResult<T>;
begin
 if R.IsOk then
    Exit(R); // unchanged

  Result := TResult<T>.Err(F(R.Error));
end;

{--------------------------------------------------------------------------------------------------}
class function TResultOps.Match<T, R>(const Res: TResult<T>; const OnOk: TFunc<T, R>; const OnErr: TFunc<string, R>): R;
begin
  if Res.IsOk then
    Exit(OnOk(Res.Value));

  Result := OnErr(Res.Error);
end;

{--------------------------------------------------------------------------------------------------}
class procedure TResultOps.Match<T>(const Res: TResult<T>; const OnOk: TProc<T>; const OnErr: TProc<string>);
begin
  if Res.IsOk then
    OnOk(Res.Value)
  else
    OnErr(Res.Error);
end;

{--------------------------------------------------------------------------------------------------}
class function TResultOps.Recover<T>(const R: TResult<T>; const F: TFunc<string, T>): TResult<T>;
begin
  if R.IsOk then
    Exit(R); // unchanged

  Result := TResult<T>.Ok(F(R.Error));
end;

{--------------------------------------------------------------------------------------------------}
class function TResultOps.Tap<T>(const Res: TResult<T>; const Action: TProc<T>): TResult<T>;
begin
 if Res.IsOk then
    Action(Res.Value);

  Result := Res; // unchanged
end;

{--------------------------------------------------------------------------------------------------}
class function TResultOps.TapError<T>(const Res: TResult<T>; const Action: TProc<string>): TResult<T>;
begin
  if Res.IsErr then
    Action(Res.Error);

  Result := Res; // unchanged
end;

{--------------------------------------------------------------------------------------------------}
class function TResultOps.UnwrapOr<T>(const Res: TResult<T>; const Default: T): T;
begin
  if Res.IsOk then
    Exit(Res.Value);
  Result := Default;
end;

{--------------------------------------------------------------------------------------------------}
class function TResultOps.UnwrapOrElse<T>(const Res: TResult<T>; const Fallback: TFunc<string, T>): T;
begin
  if Res.IsOk then
    Exit(Res.Value);

  Result := Fallback(Res.Error);
end;

end.
