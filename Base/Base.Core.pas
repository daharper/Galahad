unit Base.Core;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.SyncObjs;

type
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

  function VarRecToString(const V: TVarRec): string;

implementation

{$region 'functions'}

{----------------------------------------------------------------------------------------------------------------------}
function VarRecToString(const V: TVarRec): string;
begin
  case V.VType of
    vtAnsiString: Result := string(AnsiString(V.VAnsiString));
    vtUnicodeString: Result := string(V.VUnicodeString);
    vtWideString: Result := WideString(V.VWideString);
    vtPChar: Result := string(V.VPChar);
    vtChar: Result := V.VChar;
    vtWideChar: Result := V.VWideChar;
    vtInteger: Result := V.VInteger.ToString;
    vtInt64: Result := V.VInt64^ .ToString;
    vtBoolean: Result := BoolToStr(V.VBoolean, True);
    vtExtended: Result := FloatToStr(V.VExtended^);
  else
    Result := '<unsupported>';
  end;
end;

{$endregion}

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

end.
