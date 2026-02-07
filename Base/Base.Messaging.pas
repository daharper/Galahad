{***************************************************************************************************
  Project:     Galahad
  Unit:        Base.Messaging
  Author:      David Harper
  License:     MIT
  Purpose:     Provides lightweight messaging primitives (publish/subscribe) for decoupled
               notifications within a process.

  Overview
  --------
  Base.Messaging contains foundational types for in-process messaging and event distribution.

  TMulticast<T>
    A thread-safe multicast publisher for values of type T. Subscribers are stored as method
    pointers (procedures of object). Publishing uses a snapshot of subscribers to avoid holding
    locks while invoking callbacks and to provide stable iteration under concurrent subscribe/
    unsubscribe operations.

    Semantics:
    - Subscribe / Unsubscribe are idempotent (duplicate subscriptions are ignored).
    - Publish is resilient: subscriber exceptions are caught and optionally collected.
    - PublishRaising aggregates failure: if any subscriber raises, an exception is raised after
      publishing completes.

    Thread-Safe via a reader/writer lock and snapshot/versioning to minimize contention:
    - Writes (subscribe/unsubscribe) update a version counter.
    - Reads (publish) operate over an immutable snapshot of the subscriber list.

    Suitable for decoupled notifications such as:
    - domain/application events within a process
    - instrumentation hooks and diagnostics
    - UI or service-layer observation points

***************************************************************************************************}

unit Base.Messaging;

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
    fSnapshot: TArray<TSubscriber<T>>;
    fVersion: Integer;
    fSnapshotVersion: Integer;

    function Snapshot: TArray<TSubscriber<T>>;
  public
    procedure Subscribe(const aSubscriber: TSubscriber<T>);
    procedure Unsubscribe(const aSubscriber: TSubscriber<T>);

    /// <summary>
    ///  Publishes a value to all current subscribers.
    ///
    ///  All subscribers are invoked using a stable snapshot taken at publish time.
    ///  Exceptions raised by subscribers are caught and do not stop delivery to
    ///  subsequent subscribers.
    ///
    ///  If <paramref name="aErrors"/> is provided, details of any subscriber
    ///  exceptions are collected into the list.
    ///
    ///  Returns True if all subscribers completed successfully; False if one or
    ///  more subscribers raised an exception.
    /// </summary>
    function Publish(const aValue: T; aErrors: TList<TSubscriberError> = nil): boolean;

    /// <summary>
    ///  Publishes a value to all current subscribers and raises on failure.
    ///
    ///  All subscribers are invoked using a stable snapshot taken at publish time.
    ///  If one or more subscribers raise an exception, publishing continues for
    ///  all subscribers and an <see cref="EMulticastInvokeException"/> is raised
    ///  after completion.
    ///
    ///  The raised exception reports the total number of failures and includes
    ///  diagnostic details for the first encountered error.
    /// </summary>
    procedure PublishRaising(const aValue: T);

    constructor Create;
    destructor Destroy; override;
  end;

implementation

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

  fVersion := 0;
  fSnapshotVersion := -1;
  fSnapshot := nil;
  fSubscribers := TList<TSubscriber<T>>.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TMulticast<T>.Destroy;
begin
  fLock.BeginWrite;
  try
    fSnapshot := nil;
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
    var target := TMethod(aSubscriber);
      for var s in fSubscribers do
        if TMethod(s) = target then exit;

    fSubscribers.Add(aSubscriber);
    Inc(fVersion);
  finally
    fLock.EndWrite;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMulticast<T>.Unsubscribe(const aSubscriber: TSubscriber<T>);
begin
  if not Assigned(aSubscriber) then exit;

  var target := TMethod(aSubscriber);
  var removed := False;

  fLock.BeginWrite;
  try
    for var i := Pred(fSubscribers.Count) downto 0 do
    begin
      if TMethod(fSubscribers[i]) = target then
      begin
        fSubscribers.Delete(i);
        removed := True;
      end;
    end;

    if removed then Inc(fVersion);
  finally
    fLock.EndWrite;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TMulticast<T>.Snapshot: TArray<TSubscriber<T>>;
begin
  fLock.BeginRead;
  try
    if fSnapshotVersion = fVersion then
    begin
      Result := fSnapshot;
      exit;
    end;
  finally
    fLock.EndRead;
  end;

  fLock.BeginWrite;
  try
    if fSnapshotVersion <> fVersion then
    begin
      fSnapshot := fSubscribers.ToArray;
      fSnapshotVersion := fVersion;
    end;

    Result := fSnapshot;
  finally
    fLock.EndWrite;
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
