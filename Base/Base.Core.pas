unit Base.Core;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.SyncObjs;

type
  { semantic abstractions for interface management }
  TSingleton = class(TNoRefCountObject);
  TTransient = class(TInterfacedObject);

  {------------------------ multicast classes----------------------- }

  TExceptionClass = class of Exception;

  TSubscriberError = record
    ExceptionClass: string;
    MessageText: string;
    StackTrace: string;

    class function Create(const [ref] E: Exception): TSubscriberError; static;
  end;

  TSubscriber<T> = procedure(const Value: T) of object;

  EMulticastInvokeException = class(Exception)
  private
    fCount: Integer;
    fError: TSubscriberError;
  public
    property Count: Integer read fCount;
    property Error: TSubscriberError read fError;

    constructor Create(const aCount: Integer; const aError: TSubscriberError);
  end;

  TMulticast<T> = class
  private
    fLock: TLightweightMREW;
    fSubscribers: TList<TSubscriber<T>>;

    function Snapshot: TArray<TSubscriber<T>>;
  public
    procedure Subscribe(const aSubscriber: TSubscriber<T>);
    procedure Unsubscribe(const aSubscriber: TSubscriber<T>);

    function Publish(const aValue: T; aErrors: TList<TSubscriberError> = nil): boolean;

    procedure PublishRaising(const aValue: T);

    constructor Create;
    destructor Destroy; override;
  end;

  {------------------------ language extentsion functions ----------------------- }

  ELetException = class(Exception);

  /// <summary>
  /// Language extensions: small, opt-in helpers (generic-friendly) grouped under one short name.
  /// </summary>
  TLx = record
  strict private
    class procedure RaiseNotEnoughValues(const Need, Got: Integer); static;
  public
    class procedure Let<T>(out A, B: T; const V1, V2: T); overload; static;
    class procedure Let<T>(out A, B, C: T; const V1, V2, V3: T); overload; static;
    class procedure Let<T>(out A, B, C, D: T; const V1, V2, V3, V4: T); overload; static;
    class procedure Let<T>(out A, B, C, D, E: T; const V1, V2, V3, V4, V5: T); overload; static;

    class procedure Let<T1, T2>(out A: T1; out B: T2; const V1: T1; const V2: T2); overload; static;
    class procedure Let<T1, T2, T3>(out A: T1; out B: T2; out C: T3; const V1: T1; const V2: T2; const V3: T3); overload; static;
    class procedure Let<T1, T2, T3, T4>(out A: T1; out B: T2; out C: T3; out D: T4; const V1: T1; const V2: T2; const V3: T3; const V4: T4); overload; static;
    class procedure Let<T1, T2, T3, T4, T5>(out A: T1; out B: T2; out C: T3; out D: T4; out E: T5; const V1: T1; const V2: T2; const V3: T3; const V4: T4; const V5: T5); overload; static;

    class procedure Let<T>(out A, B: T; const Values: array of T); overload; static;
    class procedure Let<T>(out A, B, C: T; const Values: array of T); overload; static;
    class procedure Let<T>(out A, B, C, D: T; const Values: array of T); overload; static;
    class procedure Let<T>(out A, B, C, D, E: T; const Values: array of T); overload; static;

    class procedure LetOrDefault<T>(out A, B: T; const Values: array of T); overload; static;
    class procedure LetOrDefault<T>(out A, B, C: T; const Values: array of T); overload; static;
    class procedure LetOrDefault<T>(out A, B, C, D: T; const Values: array of T); overload; static;
    class procedure LetOrDefault<T>(out A, B, C, D, E: T; const Values: array of T); overload; static;

    class procedure LetOr<T>(out A, B: T; const Fallback: T; const Values: array of T); overload; static;
    class procedure LetOr<T>(out A, B, C: T; const Fallback: T; const Values: array of T); overload; static;
    class procedure LetOr<T>(out A, B, C, D: T; const Fallback: T; const Values: array of T); overload; static;
    class procedure LetOr<T>(out A, B, C, D, E: T; const Fallback: T; const Values: array of T); overload; static;
  end;

  {------------------------ general functions ----------------------- }

  { converting a VarRec value to a strong }
  function VarRecToString(const aValue: TVarRec): string;

implementation

{----------------------------------------------------------------------------------------------------------------------}
function VarRecToString(const aValue: TVarRec): string;
begin
  case aValue.VType of
    vtAnsiString: Result := string(AnsiString(aValue.VAnsiString));
    vtUnicodeString: Result := string(aValue.VUnicodeString);
    vtWideString: Result := WideString(aValue.VWideString);
    vtPChar: Result := string(aValue.VPChar);
    vtChar: Result := string(aValue.VChar);
    vtWideChar: Result := aValue.VWideChar;
    vtInteger: Result := aValue.VInteger.ToString;
    vtInt64: Result := aValue.VInt64^ .ToString;
    vtBoolean: Result := BoolToStr(aValue.VBoolean, True);
    vtExtended: Result := FloatToStr(aValue.VExtended^);
  else
    Result := '<unsupported>';
  end;
end;


{ TSubscriberError }

{----------------------------------------------------------------------------------------------------------------------}
class function TSubscriberError.Create(const [ref] E: Exception): TSubscriberError;
begin
  Result.ExceptionClass := E.ClassName;
  Result.MessageText := E.Message;
  Result.StackTrace := E.StackTrace;
end;

{ EMulticastInvokeException }

{----------------------------------------------------------------------------------------------------------------------}
constructor EMulticastInvokeException.Create(const aCount: Integer; const AError: TSubscriberError);
const
  ERR_MESSAGE = '%d multicast subscriber(s) raised an exception. First: %s: %s';
begin
  fCount := aCount;
  fError := aError;

  inherited CreateFmt(ERR_MESSAGE, [aCount, aError.ExceptionClass, aError.MessageText]);
end;

{ TMulticast<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TMulticast<T>.Create;
begin
  inherited Create;
  fSubscribers := TList<TSubscriber<T>>.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TMulticast<T>.Destroy;
begin
  fLock.BeginWrite;
  try
    FreeAndNil(fSubscribers);
  finally
    fLock.EndWrite;
  end;

  inherited Destroy;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMulticast<T>.Subscribe(const aSubscriber: TSubscriber<T>);
begin
  if not Assigned(aSubscriber) then exit;

  fLock.BeginWrite;
  try
    fSubscribers.Add(aSubscriber);
  finally
    fLock.EndWrite;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMulticast<T>.Unsubscribe(const aSubscriber: TSubscriber<T>);
begin
  if not Assigned(aSubscriber) then exit;

  var target := TMethod(aSubscriber);

  fLock.BeginWrite;
  try
    for var i := Pred(fSubscribers.Count) downto 0 do
      if TMethod(fSubscribers[i]) = target then
        fSubscribers.Delete(i);
  finally
    fLock.EndWrite;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TMulticast<T>.Snapshot: TArray<TSubscriber<T>>;
begin
  fLock.BeginRead;
  try
    Result := fSubscribers.ToArray;
  finally
    fLock.EndRead;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TMulticast<T>.Publish(const aValue: T; aErrors: TList<TSubscriberError>): Boolean;
begin
  var subscribers := Snapshot;
  var errors := false;

  for var subscriber in subscribers do
  begin
    if not Assigned(subscriber) then continue;

    try
      subscriber(AValue);
    except
      on E: Exception do
      begin
        errors := true;

        if aErrors <> nil then
          aErrors.Add(TSubscriberError.Create(E));
      end;
    end;
  end;

  Result := not errors;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMulticast<T>.PublishRaising(const AValue: T);
begin
  var errors := TList<TSubscriberError>.Create;

  try
    if not Publish(aValue, errors) then
      raise EMulticastInvokeException.Create(errors.Count, errors[0]);
  finally
    errors.Free;
  end;
end;

{ TLx }

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.RaiseNotEnoughValues(const Need, Got: Integer);
begin
  raise ELetException.CreateFmt('Let: expected at least %d value(s) but got %d.', [Need, Got]);
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B: T; const V1, V2: T);
begin
  A := V1;
  B := V2;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C: T; const V1, V2, V3: T);
begin
  A := V1;
  B := V2;
  C := V3;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C, D: T; const V1, V2, V3, V4: T);
begin
  A := V1;
  B := V2;
  C := V3;
  D := V4;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C, D, E: T; const V1, V2, V3, V4, V5: T);
begin
  A := V1;
  B := V2;
  C := V3;
  D := V4;
  E := V5;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T1, T2>(out A: T1; out B: T2; const V1: T1; const V2: T2);
begin
  A := V1;
  B := V2;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T1, T2, T3>(out A: T1; out B: T2; out C: T3; const V1: T1; const V2: T2; const V3: T3);
begin
  A := V1;
  B := V2;
  C := V3;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T1, T2, T3, T4>(out A: T1; out B: T2; out C: T3; out D: T4; const V1: T1; const V2: T2; const V3: T3; const V4: T4);
begin
  A := V1;
  B := V2;
  C := V3;
  D := V4;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T1, T2, T3, T4, T5>(out A: T1; out B: T2; out C: T3; out D: T4; out E: T5; const V1: T1; const V2: T2; const V3: T3; const V4: T4; const V5: T5);
begin
  A := V1;
  B := V2;
  C := V3;
  D := V4;
  E := V5;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B: T; const Values: array of T);
begin
  if Length(Values) < 2 then
    RaiseNotEnoughValues(2, Length(Values));

  A := Values[0];
  B := Values[1];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C: T; const Values: array of T);
begin
  if Length(Values) < 3 then
    RaiseNotEnoughValues(3, Length(Values));

  A := Values[0];
  B := Values[1];
  C := Values[2];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C, D: T; const Values: array of T);
begin
  if Length(Values) < 4 then
    RaiseNotEnoughValues(4, Length(Values));

  A := Values[0];
  B := Values[1];
  C := Values[2];
  D := Values[3];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C, D, E: T; const Values: array of T);
begin
  if Length(Values) < 5 then
    RaiseNotEnoughValues(5, Length(Values));

  A := Values[0];
  B := Values[1];
  C := Values[2];
  D := Values[3];
  E := Values[4];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOrDefault<T>(out A, B: T; const Values: array of T);
begin
  A := Default(T);
  B := Default(T);

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOrDefault<T>(out A, B, C: T; const Values: array of T);
begin
  A := Default(T);
  B := Default(T);
  C := Default(T);

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOrDefault<T>(out A, B, C, D: T; const Values: array of T);
begin
  A := Default(T);
  B := Default(T);
  C := Default(T);
  D := Default(T);

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
  if Length(Values) > 3 then D := Values[3];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOrDefault<T>(out A, B, C, D, E: T; const Values: array of T);
begin
  A := Default(T);
  B := Default(T);
  C := Default(T);
  D := Default(T);
  E := Default(T);

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
  if Length(Values) > 3 then D := Values[3];
  if Length(Values) > 4 then E := Values[4];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOr<T>(out A, B: T; const Fallback: T; const Values: array of T);
begin
  A := Fallback;
  B := Fallback;

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOr<T>(out A, B, C: T; const Fallback: T; const Values: array of T);
begin
  A := Fallback;
  B := Fallback;
  C := Fallback;

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOr<T>(out A, B, C, D: T; const Fallback: T; const Values: array of T);
begin
  A := Fallback;
  B := Fallback;
  C := Fallback;
  D := Fallback;

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
  if Length(Values) > 3 then D := Values[3];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOr<T>(out A, B, C, D, E: T; const Fallback: T; const Values: array of T);
begin
  A := Fallback;
  B := Fallback;
  C := Fallback;
  D := Fallback;
  E := Fallback;

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
  if Length(Values) > 3 then D := Values[3];
  if Length(Values) > 3 then D := Values[4];
end;

end.

