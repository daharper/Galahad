unit Tests.Core.Messaging;

interface

uses
  DUnitX.TestFramework,
  Base.Messaging,
  Mocks.Messaging;

type
  [TestFixture]
  TMulticastFixture = class
  private
    fSubA: TSubscriberAMock;
    fSubB: TSubscriberBMock;
  public
    [Setup]
    procedure Setup;

    [Teardown]
    procedure Teardown;

    [Test] procedure Publish_CallsAllSubscribers;
    [Test] procedure Unsubscribe_StopsAllValues;
  end;

  [TestFixture]
  TEventBusFixture = class
  private
    fBus: TEventBus<TTestEventBase>;
    fSub: TEventSubscriberMock;
  public
    [Setup]
    procedure Setup;

    [Teardown]
    procedure Teardown;

    [Test] procedure Publish_Delivers_To_ExactType_Subscribers;
    [Test] procedure Unsubscribe_Stops_Delivery;
    [Test] procedure Publish_Is_ExactType_NoBaseFanout;
    [Test] procedure Publish_Frees_Event;
  end;

implementation

uses
  System.SysUtils,
  Base.Core;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMulticastFixture.Publish_CallsAllSubscribers;
begin
  var publisher := TMultiCast<integer>.Create;

  try
    publisher.Subscribe(fSubA.OnValue);
    publisher.Subscribe(fSubB.OnValue);

    publisher.Publish(2);

    Assert.AreEqual(2,  fSubA.Value, 'Subscriber A should receive the value');
    Assert.AreEqual(-2, fSubB.Value, 'Subscriber B should receive the value');
  finally
    publisher.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMulticastFixture.Unsubscribe_StopsAllValues;
begin
  var publisher := TMultiCast<integer>.Create;

  try
    publisher.Subscribe(fSubA.OnValue);
    publisher.Subscribe(fSubB.OnValue);

    publisher.Publish(2);

    Assert.AreEqual(2,  fSubA.Value, 'Subscriber A should receive the value');
    Assert.AreEqual(-2, fSubB.Value, 'Subscriber B should receive the value');

    publisher.Unsubscribe(fSubB.OnValue);

    publisher.Publish(4);

    Assert.AreEqual(4,  fSubA.Value, 'Subscriber A should receive the value');
    Assert.AreEqual(-2, fSubB.Value, 'Subscriber B should not receive the value');

    publisher.Unsubscribe(fSubA.OnValue);

    publisher.Publish(8);

    Assert.AreEqual(4,  fSubA.Value, 'Subscriber A should not receive the value');
    Assert.AreEqual(-2, fSubB.Value, 'Subscriber B should not receive the value');
  finally
    publisher.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMulticastFixture.Setup;
begin
  fSubA := TSubscriberAMock.Create;
  fSubB := TSubscriberBMock.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMulticastFixture.Teardown;
begin
  fSubA.Free;
  fSubB.Free;
end;

{ TEventBusFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBusFixture.Setup;
begin
  fBus := TEventBus<TTestEventBase>.Create;
  fSub := TEventSubscriberMock.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBusFixture.Teardown;
begin
  fSub.Free;
  fBus.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBusFixture.Publish_Delivers_To_ExactType_Subscribers;
begin
  fBus.Subscribe<TEventA>(fSub.OnEventA);

  var E := TEventA.Create(7);
  try
    Assert.WillNotRaise(procedure begin fBus.PublishOwned<TEventA>(E); end);
  finally
    E.Free;
  end;

  Assert.AreEqual(1, fSub.CallsA);
  Assert.AreEqual(7, fSub.LastA);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBusFixture.Unsubscribe_Stops_Delivery;
begin
  fBus.Subscribe<TEventA>(fSub.OnEventA);
  fBus.Unsubscribe<TEventA>(fSub.OnEventA);

  var E := TEventA.Create(1);
  try
    fBus.Publish<TEventA>(E);
  finally
    E.Free;
  end;

  Assert.AreEqual(0, fSub.CallsA);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBusFixture.Publish_Is_ExactType_NoBaseFanout;
begin
  // Subscribe to base AND to EventA; publishing EventA should hit ONLY EventA subscribers
  // because bus dispatch is exact-type.
  fBus.Subscribe<TTestEventBase>(fSub.OnBase);
  fBus.Subscribe<TEventA>(fSub.OnEventA);

  var EA := TEventA.Create(5);
  try
    fBus.Publish<TEventA>(EA);
  finally
    EA.Free;
  end;

  Assert.AreEqual(1, fSub.CallsA);
  Assert.AreEqual(0, fSub.CallsBase, 'Base subscribers must NOT receive derived events under exact-type dispatch');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventBusFixture.Publish_Frees_Event;
begin
  TEventWithDtor.DestroyedCount := 0;

  fBus.Subscribe<TEventWithDtor>(fSub.OnWithDtor);

  var E := TEventWithDtor.Create;

  fBus.Publish<TEventWithDtor>(E);
  Assert.IsNull(E, 'Publish should FreeAndNil the event');

  Assert.AreEqual(1, fSub.CallsDtor, 'Subscriber should be called once');
  Assert.AreEqual(1, TEventWithDtor.DestroyedCount, 'Event destructor should have been called exactly once');
end;

initialization
  TDUnitX.RegisterTestFixture(TMulticastFixture);
  TDUnitX.RegisterTestFixture(TEventBusFixture);

end.
