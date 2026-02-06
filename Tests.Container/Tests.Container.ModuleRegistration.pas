unit Tests.Container.ModuleRegistration;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TModuleRegistrationFixture = class
  public
    [Test] procedure AddModule_Single_Registers;
    [Test] procedure AddModule_Array_RegistersInOrder;
    [Test] procedure AddModule_Single_Nil_Raises;
    [Test] procedure AddModule_Array_NilElement_Raises;
  end;

implementation

uses
  System.SysUtils,
  Base.Integrity,
  Base.Container,
  Mocks.Container;

{ TModuleRegistrationFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure TModuleRegistrationFixture.AddModule_Single_Registers;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  var module: IContainerModule := TTestModuleA.Create;
  container.AddModule(module);

  Assert.IsTrue(container.IsRegistered<ITestSvc>('A'));
  Assert.IsFalse(container.IsRegistered<ITestSvc>('B'));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TModuleRegistrationFixture.AddModule_Array_RegistersInOrder;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  var moduleA: IContainerModule := TTestModuleA.Create;
  var moduleB: IContainerModule := TTestModuleB.Create;

  container.AddModule([moduleA, moduleB]);

  Assert.IsTrue(container.IsRegistered<ITestSvc>('A'));
  Assert.IsTrue(container.IsRegistered<ITestSvc>('B'));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TModuleRegistrationFixture.AddModule_Single_Nil_Raises;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  var module: IContainerModule := nil;

  Assert.WillRaise(procedure begin container.AddModule(module); end, EArgumentException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TModuleRegistrationFixture.AddModule_Array_NilElement_Raises;
var scope: TScope;
begin
  var container := scope.Owns(TContainer.Create);

  var moduleA: IContainerModule := TTestModuleA.Create;
  var moduleB: IContainerModule := nil;

  Assert.WillRaise(procedure begin container.AddModule([moduleA, moduleB]); end, EArgumentException);
end;

initialization
  TDUnitX.RegisterTestFixture(TModuleRegistrationFixture);

end.
