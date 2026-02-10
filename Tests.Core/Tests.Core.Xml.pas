unit Tests.Core.Xml;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils;

type
  [TestFixture]
  TXmlFixture = class
  public
    [Test] procedure Test_Attribute;
  end;

implementation

uses
  System.DateUtils,
  Base.Core,
  Base.Integrity,
  Base.Xml;


{ TXmlFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Attribute;
var scope: TScope;
begin
  var a := scope.Owns(TBvAttribute.Create('id'));

  Assert.AreEqual('id', a.Name);
  Assert.AreEqual('', a.Value);
  Assert.IsFalse(a.HasValue);

  Assert.AreEqual('', a.AsXml);

  Assert.WillRaise(procedure begin a.Name := 'type' end);

  a.Value := '1';

  Assert.AreEqual('1', a.Value);
  Assert.AreEqual('id="1"', a.AsXml);

  a.Assign(20); Assert.AreEqual(20, a.AsInteger);
  a.Assign(#32); Assert.AreEqual(#32, a.AsChar);

  var n : TDateTime := Now;

  a.Assign(n); Assert.AreEqual(n, a.AsDateTime);
  a.Assign(Double(12.34)); Assert.AreEqual<Double>(12.34, a.AsDouble);
  a.Assign(Single(12.37)); Assert.AreEqual<Single>(12.37, a.AsSingle);
end;

initialization
  TDUnitX.RegisterTestFixture(TXmlFixture);

end.
