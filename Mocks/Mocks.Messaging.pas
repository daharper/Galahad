unit Mocks.Messaging;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Base.Core,
  Base.Messaging;

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

  TTestEventBase = class(TBaseEvent)
  end;

  TEventA = class(TTestEventBase)
  public
    Value: Integer;
    constructor Create(AValue: Integer);
  end;

  TEventB = class(TTestEventBase)
  public
    Text: string;
    constructor Create(const AText: string);
  end;

  TEventWithDtor = class(TTestEventBase)
  public
    class var DestroyedCount: Integer;
    destructor Destroy; override;
  end;

  TEventSubscriberMock = class
  public
    CallsA: Integer;
    LastA: Integer;

    CallsBase: Integer;
    CallsB: Integer;
    CallsDtor: Integer;

    LastB: string;

    RaiseOnA: Boolean;

    procedure OnEventA(const E: TEventA);
    procedure OnBase(const E: TTestEventBase);
    procedure OnEventB(const E: TEventB);
    procedure OnWithDtor(const E: TEventWithDtor);
  end;

implementation

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

{ TEventA }

{----------------------------------------------------------------------------------------------------------------------}
constructor TEventA.Create(AValue: Integer);
begin
  inherited Create;
  Value := AValue;
end;

{ TEventB }

{----------------------------------------------------------------------------------------------------------------------}
constructor TEventB.Create(const AText: string);
begin
  inherited Create;
  Text := AText;
end;

{ TEventWithDtor }

{----------------------------------------------------------------------------------------------------------------------}
destructor TEventWithDtor.Destroy;
begin
  Inc(DestroyedCount);
  inherited Destroy;
end;

{ TEventSubscriberMock }

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventSubscriberMock.OnEventA(const E: TEventA);
begin
  Inc(CallsA);
  LastA := E.Value;

  if RaiseOnA then
    raise Exception.Create('boom');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventSubscriberMock.OnBase(const E: TTestEventBase);
begin
  Inc(CallsBase);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventSubscriberMock.OnEventB(const E: TEventB);
begin
  Inc(CallsB);
  LastB := E.Text;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TEventSubscriberMock.OnWithDtor(const E: TEventWithDtor);
begin
  Inc(CallsDtor);
end;

end.
