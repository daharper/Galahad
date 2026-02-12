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
    [Test] procedure Test_Parser_RoundTrip_XML;
    [Test] procedure Test_Convert_To_Entities;
    [Test] procedure Test_Ignore_Comments;
    [Test] procedure Test_Convert_CharRef;
    [Test] procedure Test_CDATA;
    [Test] procedure Test_Message_Stanza;
    [Test] procedure Test_IQ_Stanza;
    [Test] procedure Test_Stream_Stanza;
    [Test] procedure Test_AST;
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
procedure TXmlFixture.Test_AST;
const
  XML_I = '''
          <?xml version="1.0"?>
          <UNIT line="1" col="1" name="Commands.Exit">
            <INTERFACE begin_line="3" begin_col="1" end_line="15" end_col="1">
              <USES begin_line="5" begin_col="1" end_line="8" end_col="1">
                <UNIT line="6" col="3" name="Core.Command"/>
              </USES>
              <TYPESECTION line="8" col="1">
                <ATTRIBUTES line="9" col="3">
                  <ATTRIBUTE line="9" col="4">
                    <NAME line="9" col="4" value="TCommandAttribute"/>
                    <ARGUMENTS line="9" col="21">
                      <POSITIONALARGUMENT line="9" col="22">
                        <VALUE line="9" col="22">
                          <EXPRESSION line="9" col="22">
                            <LITERAL line="9" col="28" value="exit" type="string"/>
                          </EXPRESSION>
                        </VALUE>
                      </POSITIONALARGUMENT>
                      <POSITIONALARGUMENT line="9" col="30">
                        <VALUE line="9" col="30">
                          <EXPRESSION line="9" col="30">
                            <LITERAL line="9" col="48" value="exit application" type="string"/>
                          </EXPRESSION>
                        </VALUE>
                      </POSITIONALARGUMENT>
                    </ARGUMENTS>
                  </ATTRIBUTE>
                </ATTRIBUTES>
                <TYPEDECL begin_line="10" begin_col="3" end_line="13" end_col="6" name="TExitCommand">
                  <TYPE line="10" col="18" type="class">
                    <TYPE line="10" col="24" name="TCommand"/>
                    <PUBLIC line="11" col="3" visibility="true">
                      <METHOD begin_line="12" begin_col="5" end_line="13" end_col="3" kind="procedure" name="Run" methodbinding="override"/>
                    </PUBLIC>
                  </TYPE>
                </TYPEDECL>
              </TYPESECTION>
            </INTERFACE>
            <IMPLEMENTATION begin_line="15" begin_col="1" end_line="27" end_col="1">
              <USES begin_line="17" begin_col="1" end_line="22" end_col="1">
                <UNIT line="18" col="3" name="System.SysUtils"/>
                <UNIT line="18" col="20" name="System.Generics.Collections"/>
                <UNIT line="18" col="49" name="Core.CommandManager"/>
                <UNIT line="18" col="70" name="Vcl.Forms"/>
              </USES>
              <METHOD begin_line="22" begin_col="1" end_line="27" end_col="1" name="TExitCommand.Run" kind="procedure">
                <STATEMENTS begin_line="23" begin_col="1" end_line="25" end_col="4">
                  <CALL line="24" col="3">
                    <DOT line="24" col="14">
                      <IDENTIFIER line="24" col="3" name="Application"/>
                      <IDENTIFIER line="24" col="15" name="Terminate"/>
                    </DOT>
                  </CALL>
                </STATEMENTS>
              </METHOD>
            </IMPLEMENTATION>
            <INITIALIZATION begin_line="27" begin_col="1" end_line="30" end_col="1">
              <STATEMENTS begin_line="28" begin_col="3" end_line="30" end_col="1">
                <CALL line="28" col="3">
                  <DOT line="28" col="15">
                    <IDENTIFIER line="28" col="3" name="TExitCommand"/>
                    <IDENTIFIER line="28" col="16" name="RegisterWithLinker"/>
                  </DOT>
                </CALL>
              </STATEMENTS>
            </INITIALIZATION>
          </UNIT>
          ''';

  XML_O = '''
          <UNIT line="1" col="1" name="Commands.Exit">
            <INTERFACE begin_line="3" begin_col="1" end_line="15" end_col="1">
              <USES begin_line="5" begin_col="1" end_line="8" end_col="1">
                <UNIT line="6" col="3" name="Core.Command"/>
              </USES>
              <TYPESECTION line="8" col="1">
                <ATTRIBUTES line="9" col="3">
                  <ATTRIBUTE line="9" col="4">
                    <NAME line="9" col="4" value="TCommandAttribute"/>
                    <ARGUMENTS line="9" col="21">
                      <POSITIONALARGUMENT line="9" col="22">
                        <VALUE line="9" col="22">
                          <EXPRESSION line="9" col="22">
                            <LITERAL line="9" col="28" value="exit" type="string"/>
                          </EXPRESSION>
                        </VALUE>
                      </POSITIONALARGUMENT>
                      <POSITIONALARGUMENT line="9" col="30">
                        <VALUE line="9" col="30">
                          <EXPRESSION line="9" col="30">
                            <LITERAL line="9" col="48" value="exit application" type="string"/>
                          </EXPRESSION>
                        </VALUE>
                      </POSITIONALARGUMENT>
                    </ARGUMENTS>
                  </ATTRIBUTE>
                </ATTRIBUTES>
                <TYPEDECL begin_line="10" begin_col="3" end_line="13" end_col="6" name="TExitCommand">
                  <TYPE line="10" col="18" type="class">
                    <TYPE line="10" col="24" name="TCommand"/>
                    <PUBLIC line="11" col="3" visibility="true">
                      <METHOD begin_line="12" begin_col="5" end_line="13" end_col="3" kind="procedure" name="Run" methodbinding="override"/>
                    </PUBLIC>
                  </TYPE>
                </TYPEDECL>
              </TYPESECTION>
            </INTERFACE>
            <IMPLEMENTATION begin_line="15" begin_col="1" end_line="27" end_col="1">
              <USES begin_line="17" begin_col="1" end_line="22" end_col="1">
                <UNIT line="18" col="3" name="System.SysUtils"/>
                <UNIT line="18" col="20" name="System.Generics.Collections"/>
                <UNIT line="18" col="49" name="Core.CommandManager"/>
                <UNIT line="18" col="70" name="Vcl.Forms"/>
              </USES>
              <METHOD begin_line="22" begin_col="1" end_line="27" end_col="1" name="TExitCommand.Run" kind="procedure">
                <STATEMENTS begin_line="23" begin_col="1" end_line="25" end_col="4">
                  <CALL line="24" col="3">
                    <DOT line="24" col="14">
                      <IDENTIFIER line="24" col="3" name="Application"/>
                      <IDENTIFIER line="24" col="15" name="Terminate"/>
                    </DOT>
                  </CALL>
                </STATEMENTS>
              </METHOD>
            </IMPLEMENTATION>
            <INITIALIZATION begin_line="27" begin_col="1" end_line="30" end_col="1">
              <STATEMENTS begin_line="28" begin_col="3" end_line="30" end_col="1">
                <CALL line="28" col="3">
                  <DOT line="28" col="15">
                    <IDENTIFIER line="28" col="3" name="TExitCommand"/>
                    <IDENTIFIER line="28" col="16" name="RegisterWithLinker"/>
                  </DOT>
                </CALL>
              </STATEMENTS>
            </INITIALIZATION>
          </UNIT>
          ''';
var
  scope: TScope;
begin
  var parseXML := TBvParser.Execute(XML_I);

  Assert.IsTrue(parseXML.IsOk);

  var e := scope.Owns(parseXML.Value);

  Assert.AreEqual(XML_O, e.AsXml);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Stream_Stanza;
const
  XML_I = '''
          <stream:stream
            xmlns="jabber:client"
            xmlns:stream="http://etherx.jabber.org/streams"
            to="example.com"
            version="1.0">
          ''';

  XML_O = '''
          <stream:stream xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" to="example.com" version="1.0"/>
          ''';

var
  scope: TScope;
begin
  var parseXML := TBvParser.Execute(XML_I);

  Assert.IsTrue(parseXML.IsOk);

  var e := scope.Owns(parseXML.Value);

  Assert.AreEqual(XML_O, e.AsXml);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_IQ_Stanza;
const
  XML_I = '''
          <iq
              to="alice@example.com"
              type="result"
              id="roster1">
            <query xmlns="jabber:iq:roster">
              <item jid="bob@example.com" name="Bob"/>
            </query>
          </iq>
          ''';

  XML_O = '''
          <iq to="alice@example.com" type="result" id="roster1">
            <query xmlns="jabber:iq:roster">
              <item jid="bob@example.com" name="Bob"/>
            </query>
          </iq>
          ''';

var
  scope: TScope;
begin
  var parseXML := TBvParser.Execute(XML_I);

  Assert.IsTrue(parseXML.IsOk);

  var e := scope.Owns(parseXML.Value);

  Assert.AreEqual(XML_O, e.AsXml);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Message_Stanza;
const
  XML_I = '''
          <message
          from="alice@example.com"
            to="bob@example.com"
          type="chat">
            <body>Hello Bob! 😀</body>
          </message>
          ''';

  XML_O = '''
          <message from="alice@example.com" to="bob@example.com" type="chat">
            <body>Hello Bob! 😀</body>
          </message>
          ''';

var
  scope: TScope;
begin
  var parseXML := TBvParser.Execute(XML_I);

  Assert.IsTrue(parseXML.IsOk);

  var e := scope.Owns(parseXML.Value);

  Assert.AreEqual(XML_O, e.AsXml);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_CDATA;
const
  XML_I = '''
          <!-- comment -->
          <?xml
            version="1.0"
            encoding="UTF-8"
          ?>

          <e1> <!-- should ignore this -->
            <id a="1
             with 2" b="2" c="3
            and 4">1</id>
            <content><![CDATA[<p>This is <b>bold</b> text.</p>]]></content>
            <code><![CDATA[
              if (a < b && b > c) {
                return a & b;
              }]]></code>
            <!-- and this -->
            <name d="4">Mr &#128512;<first>Fred<!-- this -->dy&amp;1"&quot;</first><last>Blogs<!-- this --></last></name>
            <role e="5" <!-- here --> f="6">Developer<!-- and here --></role>
          </e1>
          ''';

  XML_O = '''
          <e1>
            <id a="1
             with 2" b="2" c="3
            and 4">1</id>
            <content>&lt;p&gt;This is &lt;b&gt;bold&lt;/b&gt; text.&lt;/p&gt;</content>
            <code>if (a &lt; b &amp;&amp; b &gt; c) {
                return a &amp; b;
              }</code>
            <name d="4">Mr 😀
              <first>Freddy&amp;1&quot;&quot;</first>
              <last>Blogs</last>
            </name>
            <role e="5" f="6">Developer</role>
          </e1>
          ''';

  XML_C = '<p>This is <b>bold</b> text.</p>';

var
  scope: TScope;
begin
  var parseXML := TBvParser.Execute(XML_I);

  Assert.IsTrue(parseXML.IsOk);

  var e := scope.Owns(parseXML.Value);

  Assert.AreEqual(XML_O, e.AsXml);
  Assert.AreEqual(XML_C, e.Elem('content').Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Ignore_Comments;
const
  XML_I = '''
          <!-- comment -->
          <?xml
            version="1.0"
            encoding="UTF-8"
          ?>

          <e1> <!-- should ignore this -->
            <id a="1" b="2" c="3">1</id>
            <!-- and this -->
            <name d="4">Mr &#128512;<first>Fred<!-- this -->dy&amp;1"&quot;</first><last>Blogs<!-- this --></last></name>
            <role e="5" <!-- here --> f="6">Developer<!-- and here --></role>
          </e1>
          ''';

  XML_O = '''
          <e1>
            <id a="1" b="2" c="3">1</id>
            <name d="4">Mr 😀
              <first>Freddy&amp;1&quot;&quot;</first>
              <last>Blogs</last>
            </name>
            <role e="5" f="6">Developer</role>
          </e1>
          ''';

  XML_T = '<e1><id a="1" b="2" c="3">1</id><name d="4">Mr 😀<first>Freddy&amp;1&quot;&quot;</first><last>Blogs</last></name><role e="5" f="6">Developer</role></e1>';

var
  scope: TScope;
begin
  var parseXML := TBvParser.Execute(XML_I);

  Assert.IsTrue(parseXML.IsOk);

  var e := scope.Owns(parseXML.Value);

  Assert.AreEqual(XML_O, e.AsXml);
  Assert.AreEqual(XML_T, e.AsXml(true));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Convert_CharRef;
var
  i: integer;
begin
  i := 0; Assert.AreEqual(#9, GetCharacter('&#9;', i));
  i := 0; Assert.AreEqual(#13, GetCharacter('&#13;', i));
  i := 0; Assert.AreEqual(#32, GetCharacter('&#x20;', i));
  i := 0; Assert.AreEqual('A', GetCharacter('&#x41;', i));
  i := 0; Assert.AreEqual('©', GetCharacter('&#169;', i));
  i := 0; Assert.AreEqual('€', GetCharacter('&#8364;', i));
  i := 0; Assert.AreEqual('α', GetCharacter('&#x3b1;', i));
  i := 0; Assert.AreEqual('😀', GetCharacter('&#128512;', i));
  i := 0; Assert.AreEqual('🚀', GetCharacter('&#x1F680;', i));

  i := 0;
  Assert.AreEqual('&', GetCharacter('&#13', i));
  Assert.AreEqual(0, i);

  i := 0;
  Assert.AreEqual('&', GetCharacter('&#13N', i));
  Assert.AreEqual(0, i);

  i := 0;
  Assert.AreEqual('&', GetCharacter('&#;', i));
  Assert.AreEqual(0, i);

  i := 0;
  Assert.AreEqual('&', GetCharacter('&#x;', i));
  Assert.AreEqual(0, i);

  i := 0;
  Assert.AreEqual('&', GetCharacter('&#x8;', i));
  Assert.AreEqual(0, i);

  i := 0;
  Assert.AreEqual('&', GetCharacter('&#xD800;', i));
  Assert.AreEqual(0, i);

  i := 0;
  Assert.AreEqual('&', GetCharacter('&amp;', i));
  Assert.AreEqual(0, i);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Convert_To_Entities;
begin
  Assert.AreEqual('&amp;', ConvertToEntities('&'));

  Assert.AreEqual('&amp;', ConvertToEntities('&amp;'));
  Assert.AreEqual('&quot;', ConvertToEntities('"'));
  Assert.AreEqual('&apos;', ConvertToEntities(''''));
  Assert.AreEqual('&lt;', ConvertToEntities('<'));
  Assert.AreEqual('&gt;', ConvertToEntities('>'));

  Assert.AreEqual('a &lt; b', ConvertToEntities('a < b'));
  Assert.AreEqual('a &gt; b', ConvertToEntities('a > b'));
  Assert.AreEqual('hello &amp; world', ConvertToEntities('hello & world'));
  Assert.AreEqual('yes&apos;', ConvertToEntities('yes'''));
  Assert.AreEqual('&quot;yes&quot;', ConvertToEntities('"yes"'));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_Parser_RoundTrip_Xml;
const
  XML = '''
        <e1>
          <id a="1" b="2" c="3">1</id>
          <name d="4">Fred</name>
          <role e="5" f="6">Developer</role>
        </e1>
        ''';
var
  scope: TScope;
begin
  var parseXML := TBvParser.Execute(XML);

  Assert.IsTrue(parseXML.IsOk);

  var e := scope.Owns(parseXML.Value);

  Assert.AreSame(e, e.ElemAt(0).Parent);
  Assert.AreSame(e, e.ElemAt(1).Parent);
  Assert.AreSame(e, e.ElemAt(2).Parent);

  Assert.AreEqual(3, e.ElemAt(0).AttrCount);
  Assert.AreEqual(1, e.ElemAt(1).AttrCount);
  Assert.AreEqual(2, e.ElemAt(2).AttrCount);

  Assert.AreEqual(XML, e.AsXml);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TXmlFixture.Test_To_Xml;
const
  XML = '''
        <e1>
          <id a="1" b="2" c="3">1</id>
          <name d="4">Fred</name>
          <role e="5" f="6">Developer</role>
        </e1>
        ''';
var
  scope: TScope;
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
