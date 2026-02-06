unit Tests.Container.Registration;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Base.Container;

type
  ITestSvc = interface
    ['{B56A390B-29D1-4C96-9C07-5FD80DFE7C9E}']
    function Ping: Integer;
  end;

  TTestSvc = class(TInterfacedObject, ITestSvc)
  public
    function Ping: Integer;
  end;

  TObjectSvc = class
  public
    Value: Integer;
  end;

  [TestFixture]
  TRegistrationFixture = class
  public
    [Test] procedure Add_InterfaceInstance_RegistersDefaultName;
    [Test] procedure Add_InterfaceInstance_NamedSeparatesRegistrations;
    [Test] procedure Add_InterfaceInstance_DuplicateRaises;

    [Test] procedure AddClass_ObjectInstance_RegistersDefaultName;
    [Test] procedure AddClass_ObjectInstance_OptOutOwnership_DoesNotCrash;
    [Test] procedure AddClass_ObjectInstance_DuplicateRaises;

    [Test] procedure Add_InterfaceFactory_Singleton_DuplicateRaises;
    [Test] procedure Add_InterfaceFactory_Transient_DuplicateRaises;
    [Test] procedure Add_InterfaceFactory_NamedSeparatesRegistrations;

    [Test] procedure AddClass_ObjectFactory_Singleton_DuplicateRaises;
    [Test] procedure AddClass_ObjectFactory_Transient_DuplicateRaises;
    [Test] procedure AddClass_ObjectFactory_NamedSeparatesRegistrations;

    [Test] procedure Clear_RemovesRegistrations;
  end;

implementation

uses
  Base.Integrity;

{ Tests }

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.Add_InterfaceInstance_RegistersDefaultName;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<ITestSvc>(TTestSvc.Create);

  Assert.IsTrue(container.IsRegistered<ITestSvc>(''));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.Add_InterfaceInstance_NamedSeparatesRegistrations;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<ITestSvc>(TTestSvc.Create, 'A');
  container.Add<ITestSvc>(TTestSvc.Create, 'B');

  Assert.IsTrue(container.IsRegistered<ITestSvc>('A'));
  Assert.IsTrue(container.IsRegistered<ITestSvc>('B'));
  Assert.IsFalse(container.IsRegistered<ITestSvc>(''));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.Add_InterfaceInstance_DuplicateRaises;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);
  var service : ITestSvc := TTestSvc.Create;

  container.Add<ITestSvc>(service);

  Assert.WillRaise(procedure begin container.Add<ITestSvc>(service); end, EArgumentException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.AddClass_ObjectInstance_RegistersDefaultName;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);
  var obj := TObjectSvc.Create;

  obj.Value := 123;

  container.AddClass<TObjectSvc>(obj);

  Assert.IsTrue(container.IsRegistered<TObjectSvc>(''));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.AddClass_ObjectInstance_OptOutOwnership_DoesNotCrash;
begin
  var container := TContainer.Create;
  try
    var obj := TObjectSvc.Create;
    try
      container.AddClass<TObjectSvc>(obj, '', false);
      Assert.IsTrue(container.IsRegistered<TObjectSvc>(''));
    finally
      obj.Free;
    end;
  finally
    container.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.AddClass_ObjectInstance_DuplicateRaises;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  var obj1 := TObjectSvc.Create;
  var obj2 := scope.Owns(TObjectSvc(TObjectSvc.Create));

  container.AddClass<TObjectSvc>(obj1);

  Assert.WillRaise(procedure begin container.AddClass<TObjectSvc>(obj2); end, EArgumentException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.Add_InterfaceFactory_Singleton_DuplicateRaises;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<ITestSvc>(Singleton, function: ITestSvc begin Result := TTestSvc.Create; end);

  Assert.WillRaise(
    procedure
    begin
      container.Add<ITestSvc>(Singleton, function: ITestSvc begin Result := TTestSvc.Create; end);
    end,
    EArgumentException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.Add_InterfaceFactory_Transient_DuplicateRaises;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<ITestSvc>(Transient, function: ITestSvc begin Result := TTestSvc.Create; end);

  Assert.WillRaise(
    procedure
    begin
      container.Add<ITestSvc>(Transient, function: ITestSvc begin Result := TTestSvc.Create; end);
    end,
    EArgumentException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.Add_InterfaceFactory_NamedSeparatesRegistrations;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.Add<ITestSvc>(Singleton, function: ITestSvc begin Result := TTestSvc.Create; end, 'A');
  container.Add<ITestSvc>(Singleton, function: ITestSvc begin Result := TTestSvc.Create; end, 'B');

  Assert.IsTrue(container.IsRegistered<ITestSvc>('A'));
  Assert.IsTrue(container.IsRegistered<ITestSvc>('B'));
  Assert.IsFalse(container.IsRegistered<ITestSvc>(''));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.AddClass_ObjectFactory_Singleton_DuplicateRaises;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddClass<TObjectSvc>(Singleton, function: TObjectSvc begin Result := TObjectSvc.Create; end);

  Assert.WillRaise(
    procedure
    begin
      container.AddClass<TObjectSvc>(Singleton, function: TObjectSvc begin Result := TObjectSvc.Create; end);
    end,
    EArgumentException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.AddClass_ObjectFactory_Transient_DuplicateRaises;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddClass<TObjectSvc>(Transient, function: TObjectSvc begin Result := TObjectSvc.Create; end);

  Assert.WillRaise(
    procedure
    begin
      container.AddClass<TObjectSvc>(Transient, function: TObjectSvc begin Result := TObjectSvc.Create; end);
    end,
    EArgumentException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.AddClass_ObjectFactory_NamedSeparatesRegistrations;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  container.AddClass<TObjectSvc>(Singleton, function: TObjectSvc begin Result := TObjectSvc.Create; end, 'A');

  container.AddClass<TObjectSvc>(Singleton, function: TObjectSvc begin Result := TObjectSvc.Create; end, 'B');

  Assert.IsTrue(container.IsRegistered<TObjectSvc>('A'));
  Assert.IsTrue(container.IsRegistered<TObjectSvc>('B'));
  Assert.IsFalse(container.IsRegistered<TObjectSvc>(''));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRegistrationFixture.Clear_RemovesRegistrations;
var scope : TScope;
begin
  var container := scope.Owns(TContainer.Create);

  var service: ITestSvc := TTestSvc.Create;
  container.Add<ITestSvc>(service, 'X');

  Assert.IsTrue(container.IsRegistered<ITestSvc>('X'));

  container.Clear;

  Assert.IsFalse(container.IsRegistered<ITestSvc>('X'));
end;

{ TTestSvc }

{----------------------------------------------------------------------------------------------------------------------}
function TTestSvc.Ping: Integer;
begin
  Result := 42;
end;

initialization
  TDUnitX.RegisterTestFixture(TRegistrationFixture);

end.
