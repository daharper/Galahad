unit Tests.Core.Messaging;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework;

type
  TSubscriberAMock = class
  private
    fValue: integer;
  public
    property Value: integer read fValue;
    procedure OnValue(const aValue: integer);
  end;

  TSubscriberBMock = class
  private
    fValue: integer;
  public
    property Value: integer read fValue;
    procedure OnValue(const aValue: integer);
  end;

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

implementation

uses
  Base.Core,
  Base.Messaging;

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

{ TSubscriberMock }

{----------------------------------------------------------------------------------------------------------------------}
procedure TSubscriberAMock.OnValue(const aValue: integer);
begin
  fValue := Abs(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSubscriberBMock.OnValue(const aValue: integer);
begin
  fValue := Abs(aValue) * -1;
end;

initialization
  TDUnitX.RegisterTestFixture(TMulticastFixture);

end.
