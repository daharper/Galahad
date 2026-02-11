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
    [Test] procedure Test_Element_Value;
    [Test] procedure Test_Element_Attributes;
    [Test] procedure Test_Subelements;
    [Test] procedure Test_Can_Walk_Attributes;
    [Test] procedure Test_Can_Walk_Elements;
    [Test] procedure Test_Can_TakeOwnership_Of_Element;
    [Test] procedure Test_To_Xml;
  end;

implementation

uses
  System.DateUtils,
  System.Generics.Collections,
  Base.Core,
  Base.Integrity,
  Base.Xml;

{ TXmlFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_To_Xml;
var scope: TScope;
const
  XML = '''
        <e1>
          <id a="1" b="2" c="3">1</id>
          <name d="4">Fred</name>
          <role e="5" f="6">Developer</role>
        </e1>
        ''';
begin
  var e := scope.Owns(TBvElement.Create('e1'));

  e.PushElem('id', '1').PushElem('name', 'Fred').PushElem('role', 'Developer');

  e.ElemAt(0).PushAttr('a', '1').PushAttr('b', '2').PushAttr('c', '3');
  e.ElemAt(1).PushAttr('d', '4');
  e.ElemAt(2).PushAttr('e', '5').PushAttr('f', '6');

  var s := e.AsXml;

  Assert.AreEqual(XML, e.AsXml);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Can_TakeOwnership_Of_Element;
var scope: TScope;
begin
  var e := TBvElement.Create('e1');

  e.PushElem('id', '1').PushElem('name', 'Fred').PushElem('role', 'Developer');

  Assert.AreSame(e, e.ElemAt(0).Parent);
  Assert.AreSame(e, e.ElemAt(1).Parent);
  Assert.AreSame(e, e.ElemAt(2).Parent);

  e.ElemAt(0).PushAttr('a', '1').PushAttr('b', '2').PushAttr('c', '3');
  e.ElemAt(1).PushAttr('d', '4');
  e.ElemAt(2).PushAttr('e', '5').PushAttr('f', '6');

  Assert.AreEqual(3, e.ElemAt(0).AttrCount);
  Assert.AreEqual(1, e.ElemAt(1).AttrCount);
  Assert.AreEqual(2, e.ElemAt(2).AttrCount);

  var e2 := scope.Owns(TBvElement.Create(e));

  Assert.AreEqual(3, e2.ElemCount);

  Assert.AreSame(e2, e2.ElemAt(0).Parent);
  Assert.AreSame(e2, e2.ElemAt(1).Parent);
  Assert.AreSame(e2, e2.ElemAt(2).Parent);

  Assert.AreEqual(3, e2.ElemAt(0).AttrCount);
  Assert.AreEqual(1, e2.ElemAt(1).AttrCount);
  Assert.AreEqual(2, e2.ElemAt(2).AttrCount);

  Assert.IsFalse(Assigned(e));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Can_Walk_Elements;
var scope: TScope;
begin
  var e := scope.Owns(TBvElement.Create('test'));

  e.PushElem('id', '1').PushElem('name', 'Fred').PushElem('role', 'developer');

  var elems := scope.Owns(TList<string>.Create);

  for var elem in e.Elems do
    elems.Add(elem.Name);

  Assert.IsTrue(elems.Contains('id'));
  Assert.IsTrue(elems.Contains('name'));
  Assert.IsTrue(elems.Contains('role'));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Can_Walk_Attributes;
var scope: TScope;
begin
  var e := scope.Owns(TBvElement.Create('test'));

  e.PushAttr('id', '1').PushAttr('name', 'Fred').PushAttr('role', 'developer');

  var attrs := scope.Owns(TList<string>.Create);

  for var attr in e.Attrs do
    attrs.Add(attr.Name);

  Assert.IsTrue(attrs.Contains('id'));
  Assert.IsTrue(attrs.Contains('name'));
  Assert.IsTrue(attrs.Contains('role'));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Subelements;
var scope: TScope;
begin
  var e := scope.Owns(TBvElement.Create('employee'));

  Assert.IsFalse(e.HasElems);

  e.AddOrSetElem('id', '1');

  Assert.IsTrue(e.HasElems);
  Assert.AreEqual(1, e.ElemCount);
  Assert.IsTrue(e.HasElem('id'));

  var id := e.Elem('id');

  Assert.AreSame(id, e.Elem('id'));
  Assert.AreEqual('1', e.Elem('id').Value);

  e.Elem('id').Value := '2';

  Assert.AreEqual('2', id.Value);

  e.PushElem('name', 'Fred');
  e.PushElem(TBvElement.Create('role', 'developer'));

  Assert.AreEqual(3, e.ElemCount);

  Assert.AreSame(e.FirstElem, e.Elem('id'));
  Assert.AreSame(e.LastElem, e.Elem('role'));
  Assert.AreSame(e.LastElem, e.PeekElem);

  var role := scope.Owns(e.PopElem);

  Assert.AreEqual('role', role.Name);

  e.RemoveElem('id');

  Assert.AreEqual(1, e.ElemCount);
  Assert.AreEqual('name', e.PeekElem.Name);

  e.ClearElems;

  Assert.AreEqual(0, e.ElemCount);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Element_Attributes;
var scope: TScope;
begin
  var e := scope.Owns(TBvElement.Create('employee'));

  Assert.IsFalse(e.HasAttrs);

  var a := e.Attr('id');

  Assert.IsTrue(e.HasAttrs);
  Assert.IsTrue(e.HasAttr('id'));
  Assert.AreEqual(0, e.AttrIndexOf('id'));
  Assert.AreSame(a, e.Attr('id'));

  Assert.AreSame(e, e.AddOrSetAttr('id', '1'));
  Assert.IsTrue(a.HasValue);
  Assert.AreEqual('1', a.Value);

  Assert.AreSame(e, e.AddOrSetAttr('id', '2'));
  Assert.AreEqual('2', a.Value);

  var b := TBvAttribute.Create('id', '3');

  e.AddOrSetAttr(b);

  Assert.AreEqual('3', e.Attr('id').Value);

  Assert.AreSame(e.FirstAttr, e.LastAttr);

  e.AddOrSetAttr('name', 'Fred').AddOrSetAttr('role', 'Developer');

  Assert.AreEqual(3, e.AttrCount);
  Assert.AreEqual('id', e.FirstAttr.Name);
  Assert.AreEqual('role', e.LastAttr.Name);

  Assert.AreEqual('3', e['id']);

  e['id'] := '4';

  Assert.AreEqual('4', e['id']);

  e.RemoveAttr('name');

  Assert.AreEqual(2, e.AttrCount);
  Assert.IsFalse(e.HasAttr('name'));

  e.ClearAttrs;

  Assert.AreEqual(0, e.AttrCount);
  Assert.IsFalse(e.HasAttrs);

  e.PushAttr('id', '5');

  Assert.IsTrue(e.HasAttrs);
  Assert.IsTrue(e.HasAttr('id'));
  Assert.AreEqual(0, e.AttrIndexOf('id'));
  Assert.AreEqual('5', e.Attr('id').Value);
  Assert.AreEqual('5', e.PeekAttr.Value);

  a := e.PopAttr;

  Assert.AreEqual('5', a.Value);
  Assert.AreEqual('id', a.Name);

  Assert.IsFalse(e.HasAttrs);

  a.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Element_Value;
var scope: TScope;
begin
  var e := scope.Owns(TBvElement.Create('id'));

  Assert.AreEqual('id', e.Name);
  Assert.AreEqual('', e.Value);
  Assert.IsFalse(e.HasValue);

  Assert.WillRaise(procedure begin e.Name := 'type' end);

  e.Value := '1';

  Assert.AreEqual('1', e.Value);

  var n : TDateTime := Now;

  e.Assign(n);
  Assert.AreEqual(n, e.AsDateTime);

  var g := TGuid.NewGuid;

  e.Assign(g);
  Assert.AreEqual(g, e.AsGuid);

  e.Assign(Double(12.34));
  Assert.AreEqual<Double>(12.34, e.AsDouble);

  e.Assign(Single(12.37));
  Assert.AreEqual<Single>(12.37, e.AsSingle);

  e.Assign(20);
  Assert.AreEqual(20, e.AsInteger);

  e.Assign(#32);
  Assert.AreEqual(#32, e.AsChar);

  e.Assign(Currency(12.20));
  Assert.AreEqual(Currency(12.20), e.AsCurrency);

  e.Assign(Int64.MaxValue);
  Assert.AreEqual<Int64>(Int64.MaxValue, e.AsInt64);

  e.Assign(true);
  Assert.AreEqual('True', e.Value);
  Assert.AreEqual(true, e.AsBoolean);

  e.Assign(true, false);
  Assert.AreEqual('-1', e.Value);
  Assert.AreEqual(true, e.AsBoolean);
end;

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

  var n : TDateTime := Now;

  a.Assign(n);
  Assert.AreEqual(n, a.AsDateTime);

  var g := TGuid.NewGuid;

  a.Assign(g);
  Assert.AreEqual(g, a.AsGuid);

  a.Assign(Double(12.34));
  Assert.AreEqual<Double>(12.34, a.AsDouble);

  a.Assign(Single(12.37));
  Assert.AreEqual<Single>(12.37, a.AsSingle);

  a.Assign(20);
  Assert.AreEqual(20, a.AsInteger);

  a.Assign(#32);
  Assert.AreEqual(#32, a.AsChar);

  a.Assign(Currency(12.20));
  Assert.AreEqual(Currency(12.20), a.AsCurrency);

  a.Assign(Int64.MaxValue);
  Assert.AreEqual<Int64>(Int64.MaxValue, a.AsInt64);

  a.Assign(true);
  Assert.AreEqual('True', a.Value);
  Assert.AreEqual(true, a.AsBoolean);

  a.Assign(true, false);
  Assert.AreEqual('-1', a.Value);
  Assert.AreEqual(true, a.AsBoolean);
end;

initialization
  TDUnitX.RegisterTestFixture(TXmlFixture);

end.
