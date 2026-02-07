{***************************************************************************************************
  Project:     Galahad
  Unit:        Base.Messaging
  Author:      David Harper
  License:     MIT
  Purpose:     Provides lightweight messaging primitives (publish/subscribe) for decoupled
               notifications within a process.

  Overview
  --------
  This unit provides lightweight, thread-safe primitives for publish/subscribe
  communication within a single process.

  Key components include:

  - TMulticast<T>
      A low-level multicast dispatcher that allows multiple subscribers to be
      notified of published values. Subscribers are invoked using a stable
      snapshot to ensure safe iteration under concurrent modification.

  - TEventBus<TBase>
      A higher-level event bus built on top of multicast channels. Events are
      routed by concrete type, with explicit support for grouped publishing
      without polymorphic fan-out.

      The event bus enforces clear ownership semantics:
        * Publish(...)      – the bus owns and frees the event.
        * PublishOwned(...) – the caller retains ownership.

      Subscriber exceptions are never raised directly; instead, they are reported
      through the central error notification mechanism, allowing applications to
      decide how errors are handled (log, alert, ignore, etc.).

  Messaging in this unit is designed for correctness, clarity, and explicitness
  over implicit behavior or reflection-based discovery. It is intended to be
  used as foundational infrastructure across application, domain, and UI layers.

***************************************************************************************************}

unit Base.Messaging;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.SyncObjs,
  System.TypInfo;

type
  TExceptionClass = class of Exception;

  TSubscriberError = record
    ExceptionClass: string;
    MessageText: string;
    StackTrace: string;

    class function Create(const [ref] E: Exception): TSubscriberError; static;
  end;

  TPublishException = class(Exception)
  private
    fError: TSubscriberError;
  public
    property SubscriberError: TSubscriberError read fError;

    constructor Create(const aMessage: string; const [ref] aError: TSubscriberError);
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

  /// <summary>
  ///  TMulticast provides a thread-safe, in-process publish/subscribe mechanism
  ///  for values of a single type.
  ///
  ///  Subscribers are registered as method references and are invoked in the
  ///  order they were added. Publishing uses a stable snapshot of subscribers,
  ///  ensuring safe delivery even when subscriptions change concurrently.
  ///
  ///  Exceptions raised by individual subscribers are caught and do not prevent
  ///  delivery to remaining subscribers. Any such errors are reported via the
  ///  central error notification mechanism.
  ///
  ///  TMulticast does not own published values and performs no lifecycle
  ///  management. Ownership semantics, if required, are the responsibility of
  ///  higher-level constructs such as TEventBus.
  ///
  ///  This class is intended as a low-level building block and is not aware of
  ///  event types, inheritance, or grouping semantics.
  /// </summary>
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

  /// <summary>
  ///  Base event type for in-process messaging. Layers may derive their own base types, e.g.:
  ///    TDomainEvent = class(TBaseEvent)
  ///    TUiEvent     = class(TBaseEvent)
  ///    TAppEvent    = class(TBaseEvent)
  ///
  ///  Events are plain objects. The event bus does not own instances unless PublishOwned is used.
  /// </summary>
  TBaseEvent = class
  public
    OccurredAt: TDateTime;
    constructor Create;
  end;

  /// <summary>
  ///  TEventBus provides an in-process, type-safe event dispatch mechanism built
  ///  on top of multicast channels.
  ///
  ///  Events are published and subscribed to by their concrete type. Each event
  ///  type has its own isolated channel, ensuring predictable delivery with no
  ///  implicit fan-out or polymorphic dispatch.
  ///
  ///  The bus supports two ownership models:
  ///   - Publish: the bus assumes ownership of the event instance and will free it
  ///     after delivery.
  ///   - PublishOwned: the caller retains ownership of the event instance.
  ///
  ///  Group publishing is supported by explicitly publishing an additional event
  ///  instance to a second channel, allowing clients to subscribe to logical
  ///  groupings (e.g. domain-level or application-level events) without inheritance
  ///  or runtime type inspection.
  ///
  ///  TEventBus never raises subscriber exceptions. Any errors raised by handlers
  ///  are reported via the central error notification mechanism.
  ///
  ///  This class is thread-safe and intended for use within a single process.
  /// </summary>
  TEventBus<TBase: TBaseEvent> = class
  private
    fLock: TLightweightMREW;
    fChannels: TObjectDictionary<PTypeInfo, TObject>;

    function GetOrCreateChannel<T: TBase>: TMulticast<T>;
    function TryGetChannel<T: TBase>(out aChannel: TMulticast<T>): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Subscribe<T: TBase>(const aHandler: TSubscriber<T>);
    procedure Unsubscribe<T: TBase>(const aHandler: TSubscriber<T>);

    // Bus owns aEvent (and optional group event): will Free them.
    procedure Publish<T: TBase>(var aEvent: T); overload;
    procedure Publish<T: TBase; TGroup: TBase>(var aEvent: T; var aGroupEvent: TGroup); overload;
    procedure PublishGroup<TGroup: TBase>(var aGroupEvent: TGroup);

    // Caller owns events: bus will NOT Free them.
    procedure PublishOwned<T: TBase>(const aEvent: T); overload;
    procedure PublishOwned<T: TBase; TGroup: TBase>(const aEvent: T; const aGroupEvent: TGroup); overload;
    procedure PublishGroupOwned<TGroup: TBase>(const aGroupEvent: TGroup);
  end;

implementation

uses
  Base.Integrity;

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

        var subError := TSubscriberError.Create(E);

        if aErrors <> nil then
          aErrors.Add(subError);

        var ex := TPublishException.Create('Error publishing message', subError);

        try
          TError.Notify(ex);
        finally
          ex.Free;
        end;
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

{ TEventBus<TBase> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TEventBus<TBase>.Create;
begin
  inherited Create;
  fChannels := TObjectDictionary<PTypeInfo, TObject>.Create([doOwnsValues]);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TEventBus<TBase>.Destroy;
begin
  fLock.BeginWrite;
  try
    FreeAndNil(fChannels);
  finally
    fLock.EndWrite;
  end;

  inherited Destroy;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEventBus<TBase>.TryGetChannel<T>(out aChannel: TMulticast<T>): Boolean;
var
  TI: PTypeInfo;
  Obj: TObject;
begin
  aChannel := nil;
  TI := TypeInfo(T);

  fLock.BeginRead;
  try
    Result := fChannels.TryGetValue(TI, Obj);
    if Result then
      aChannel := TMulticast<T>(Obj);
  finally
    fLock.EndRead;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TEventBus<TBase>.GetOrCreateChannel<T>: TMulticast<T>;
var
  TI: PTypeInfo;
  Obj: TObject;
begin
  TI := TypeInfo(T);

  // Fast path: read lock
  fLock.BeginRead;
  try
    if fChannels.TryGetValue(TI, Obj) then
      Exit(TMulticast<T>(Obj));
  finally
    fLock.EndRead;
  end;

  // Slow path: create under write lock
  fLock.BeginWrite;
  try
    if not fChannels.TryGetValue(TI, Obj) then
    begin
      Obj := TMulticast<T>.Create;
      fChannels.Add(TI, Obj);
    end;

    Result := TMulticast<T>(Obj);
  finally
    fLock.EndWrite;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBus<TBase>.Subscribe<T>(const aHandler: TSubscriber<T>);
begin
  GetOrCreateChannel<T>.Subscribe(aHandler);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBus<TBase>.Unsubscribe<T>(const aHandler: TSubscriber<T>);
var
  ch: TMulticast<T>;
begin
  if TryGetChannel<T>(ch) then
    ch.Unsubscribe(aHandler);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBus<TBase>.Publish<T>(var aEvent: T);
begin
  if aEvent = nil then exit;

  try
    GetOrCreateChannel<T>.Publish(aEvent);
  finally
    FreeAndNil(aEvent);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBus<TBase>.Publish<T, TGroup>(var aEvent: T; var aGroupEvent: TGroup);
begin
  try
    if aEvent <> nil then
      GetOrCreateChannel<T>.Publish(aEvent);

    if aGroupEvent <> nil then
      GetOrCreateChannel<TGroup>.Publish(aGroupEvent);
  finally
    FreeAndNil(aEvent);
    FreeAndNil(aGroupEvent);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBus<TBase>.PublishGroup<TGroup>(var aGroupEvent: TGroup);
begin
  try
    if aGroupEvent <> nil then
      GetOrCreateChannel<TGroup>.Publish(aGroupEvent);
  finally
    FreeAndNil(aGroupEvent);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBus<TBase>.PublishOwned<T>(const aEvent: T);
begin
  if aEvent <> nil then
    GetOrCreateChannel<T>.Publish(aEvent);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBus<TBase>.PublishOwned<T, TGroup>(const aEvent: T; const aGroupEvent: TGroup);
begin
  if aEvent <> nil then
    GetOrCreateChannel<T>.Publish(aEvent);

  if aGroupEvent <> nil then
    GetOrCreateChannel<TGroup>.Publish(aGroupEvent);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBus<TBase>.PublishGroupOwned<TGroup>(const aGroupEvent: TGroup);
begin
  if aGroupEvent <> nil then
    GetOrCreateChannel<TGroup>.Publish(aGroupEvent);
end;

{ TBaseEvent }

{----------------------------------------------------------------------------------------------------------------------}
constructor TBaseEvent.Create;
begin
  inherited Create;
  OccurredAt := Now;
end;

{ TPublishException }

{----------------------------------------------------------------------------------------------------------------------}
constructor TPublishException.Create(const aMessage: string; const [ref] aError: TSubscriberError);
begin
  inherited Create(aMessage);

  fError := aError;
end;

end.
