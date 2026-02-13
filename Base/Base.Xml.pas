{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Xml
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Basic XML Object and Parser for simple persistance requirements.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Xml;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Base.Core,
  Base.Integrity,
  Base.Dynamic;

type
  { Currently, just basic XML entities are mapped, but given the leisure, see this page:

    https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references

    and map all entities accepted by the HTML5 specification.

    Note, Unicode characters can be expressed as such:

    &apos;        =>     #$0027
    &DownBreve;   =>     #$0020 + #$0311 + #$0311
    &TripleDot;   =>     #$0020 + #$20DB + #$20DB + #$20DB

    Ordinary mappings as per normal:

    &Tab;         =>     #9
    &NewLine;     =>     #10
    &dollar;      =>     '$'
    &lpar;        =>     '('
  }
  TBvEntity = (
    xAmpersand,
    xLessThan,
    xGreaterThan,
    xApostrophe,
    xQuote
  );

  /// <summary>Represents an XML Attribute</summary>
  TBvAttribute = class
  private
    fName: string;
    fValue: string;

    procedure SetName(const aValue: string);
    procedure SetValue(const aValue: string);

  public
    property Name: string read fName write SetName;
    property Value: string read fValue write SetValue;

    function HasValue: boolean;

    function AsInteger: integer;
    function AsBoolean: boolean;
    function AsString: string;
    function AsSingle: single;
    function AsDouble: double;
    function AsDateTime: TDateTime;
    function AsChar: Char;
    function AsInt64: Int64;
    function AsGuid: TGuid;
    function AsCurrency: Currency;

    function AsXml: string;

    procedure Assign(const aValue: integer); overload;
    procedure Assign(const aValue: boolean; const aUseBoolStrs: boolean = true); overload;
    procedure Assign(const aValue: string); overload;
    procedure Assign(const aValue: single); overload;
    procedure Assign(const aValue: double); overload;
    procedure Assign(const aValue: TDateTime); overload;
    procedure Assign(const aValue: char); overload;
    procedure Assign(const aValue: Int64); overload;
    procedure Assign(const aValue: TGuid); overload;
    procedure Assign(const aValue: Currency); overload;

    constructor Create(const aName: string; const aValue: string = '');
  end;

  TBvElement = class;

  IBvElement = interface(IDispatch)
    ['{50669930-F303-481C-A5BD-DE675EC73BE1}']
    function GetParent: TBvElement;
    function GetName: string;
    function GetValue: string;
    function GetAttribute(aName: string): string;

    procedure SetParent(const aValue: TBvElement);
    procedure SetName(const aValue: string);
    procedure SetValue(const aValue: string);
    procedure SetAttribute(aName: string; const aValue: string);
    procedure AppendXml(const [ref] aBuilder: TStringBuilder; indent: string = '');
    procedure AppendTrimXml(const [ref] aBuilder: TStringBuilder);

    property Parent: TBvElement read GetParent write SetParent;
    property Name: string read GetName write SetName;
    property Value: string read GetValue write SetValue;
    property Attributes[aName: string]: string read GetAttribute write SetAttribute; default;

    /// <summary>Returns true if there are attributes.</summary>
    function HasAttrs: boolean;

    /// <summary>Returns the attribute count.</summary>
    function AttrCount: integer;

    /// <summary>Returns the first attribute.</summary>
    function FirstAttr: TBvAttribute;

    /// <summary>Returns the last attribute.</summary>
    function LastAttr: TBvAttribute;

    /// <summary>
    ///  Updates the attribute if it exists, adds an attribute if it doesn't.
    /// </summary>
    /// <returns>The current element.</returns>
    function AddOrSetAttr(const aName: string; const aValue: string = ''): IBvElement; overload;

    /// <summary>
    ///  Adds the attribute if it doesn't exist, otherwise frees the existing element and replaces it.
    /// </summary>
    /// <returns>The current element.</returns>
    function AddOrSetAttr(const aOther: TBvAttribute): IBvElement; overload;

    /// <summary>Pushes a new attribute onto the back of the list - returns Self for chaining.</summary>
    function PushAttr(const aAttribute: TBvAttribute): IBvElement; overload;
    function PushAttr(const aName: string; const aValue: string = ''): IBvElement; overload;

    /// <summary>Returns the last attribute on the list.</summary>
    function PeekAttr: TBvAttribute;

    /// <summary>Removes the last attribute from the list.</summary>
    function PopAttr: TBvAttribute;

    /// <summary>Gets the attribute with the specified name, add it if it doesn't.</summary>
    function Attr(const aName: string; const aValue: string = ''): TBvAttribute;

    /// <summary>Returns true if an attribute with the specified name exists.</summary>
    function HasAttr(const aName: string): boolean;

    /// <summary>Returns the index of the attribute with the specified name, otherwise -1.</summary>
    function AttrIndexOf(const aName: string): integer;

    /// <summary>Removes an attribute from the list.</summary>
    procedure RemoveAttr(const aName: string);

    /// <summary>Clears attributes.</summary>
    procedure ClearAttrs;

    /// <summary>Returns an enumerator for attributes.</summary>
    function Attrs: TEnumerable<TBvAttribute>;

    /// <summary>Returns the attribute at the specified index.</summary>
    function AttrAt(const aIndex: integer): TBvAttribute;

    function ElemCount: integer;
    function HasValue: boolean;
    function HasElems: boolean;

    function AsInteger: integer;
    function AsBoolean: boolean;
    function AsString: string;
    function AsSingle: single;
    function AsDouble: double;
    function AsDateTime: TDateTime;
    function AsChar: Char;
    function AsInt64: Int64;
    function AsGuid: TGuid;
    function AsCurrency: Currency;

    function AsPrettyXml: string;
    function AsXml:string;

    procedure Assign(const aValue: integer); overload;
    procedure Assign(const aValue: boolean; const aUseBoolStrs: boolean = true); overload;
    procedure Assign(const aValue: string); overload;
    procedure Assign(const aValue: single); overload;
    procedure Assign(const aValue: double); overload;
    procedure Assign(const aValue: TDateTime); overload;
    procedure Assign(const aValue: char); overload;
    procedure Assign(const aValue: Int64); overload;
    procedure Assign(const aValue: TGuid); overload;
    procedure Assign(const aValue: Currency); overload;

    /// <summary>
    ///  Adds a child element to fElems (side-effect only).
    ///  This is the safe internal primitive: no interface return temporary.
    /// </summary>
    procedure AddElem(const aElement: IBvElement);

    /// <summary>
    ///  Adds a child element and returns that child.
    ///  Useful for internal code that needs the inserted element.
    /// </summary>
    function AppendElem(const aElement: IBvElement): IBvElement;

    /// <summary>
    ///  Sets the value of the element with the specified name, if it doesn't exist then a new element is created
    /// </summary>
    /// <returns>The added or updated element.</returns>
    function AddOrSetElem(const aName: string; const aValue: string = ''): IBvElement; overload;

    /// <summary>
    ///  Adds the element if it doesn't exist, otherwise frees the existing element and replaces it.
    /// </summary>
    /// <returns>The added or updated element.</returns>
    function AddOrSetElem(const aOther: IBvElement): IBvElement; overload;

    /// <summary>Gets the element with the specified name, adds it if it doesn't exist.</summary>
    function Elem(const aName: string; const aValue: string = ''): IBvElement;

    /// <summary>Returns true if an element with the specified name exists.</summary>
    function HasElem(const aName: string): boolean;

    /// <summary>Returns the first subelement.</summary>
    function FirstElem: IBvElement;

    /// <summary>Returns the last subelement.</summary>
    function LastElem: IBvElement;

    /// <summary>Returns the index of the element with the specified name, otherwise -1.</summary>
    function ElemIndexOf(const aName: string): integer;

    /// <summary>Pushes a new element onto the back of the list.</summary>
    /// <remarks>Returns the current element for chaining.</remarks>
    function PushElem(const aElement: IBvElement): IBvElement; overload;
    function PushElem(const aName: string; const aValue: string): IBvElement; overload;

    /// <summary>Returns the last element on the list./summary>
    function PeekElem: IBvElement;

    /// <summary>Removes the last element from the list.</summary>
    function PopElem: IBvElement;

    /// <summary>Removes a subelement from the list.</summary>
    procedure RemoveElem(const aName: string);

    /// <summary>Removes a subelement from the list at the specified index.</summary>
    procedure RemoveElemAt(const aIndex: integer);

    /// <summary>Clears subelements.</summary>
    procedure ClearElems;

    /// <summary>Returns an enumerator for attributes.</summary>
    function Elems: TEnumerable<IBvElement>;

    /// <summary>Returns the element at the specified index.</summary>
    function ElemAt(const aIndex: integer): IBvElement;
  end;

  /// <summary>Represents an XML Element</summary>
  TBvElement = class(TDynamicObject, IBvElement)
  private
    fElems: TList<IBvElement>;
    fAttrs: TList<TBvAttribute>;
    fParent: TBvElement;
    fName: string;
    fValue: string;

    function GetAttribute(aName: string): string;
    function GetName: string;
    function GetValue: string;
    function GetParent: TBvElement;

    procedure Initialize;
    procedure SetParent(const aValue: TBvElement);
    procedure SetName(const aValue: string);
    procedure SetValue(const aValue: string);
    procedure SetAttribute(aName: string; const aValue: string);
    procedure AppendXml(const [ref] aBuilder: TStringBuilder; indent: string = '');
    procedure AppendTrimXml(const [ref] aBuilder: TStringBuilder);
  public
    property Parent: TBvElement read GetParent write SetParent;
    property Name: string read fName write SetName;
    property Value: string read fValue write SetValue;
    property Attributes[aName: string]: string read GetAttribute write SetAttribute; default;

    function HasAttrs: boolean;
    function AttrCount: integer;
    function FirstAttr: TBvAttribute;
    function LastAttr: TBvAttribute;
    function AddOrSetAttr(const aName: string; const aValue: string = ''): IBvElement; overload;
    function AddOrSetAttr(const aOther: TBvAttribute): IBvElement; overload;
    function PushAttr(const aAttribute: TBvAttribute): IBvElement; overload;
    function PushAttr(const aName: string; const aValue: string = ''): IBvElement; overload;
    function PeekAttr: TBvAttribute;
    function PopAttr: TBvAttribute;
    function Attr(const aName: string; const aValue: string = ''): TBvAttribute;
    function HasAttr(const aName: string): boolean;
    function AttrIndexOf(const aName: string): integer;
    procedure RemoveAttr(const aName: string);
    procedure ClearAttrs;
    function Attrs: TEnumerable<TBvAttribute>;
    function AttrAt(const aIndex: integer): TBvAttribute;

    function ElemCount: integer;
    function HasValue: boolean;
    function HasElems: boolean;
    function AsInteger: integer;
    function AsBoolean: boolean;
    function AsString: string;
    function AsSingle: single;
    function AsDouble: double;
    function AsDateTime: TDateTime;
    function AsChar: Char;
    function AsInt64: Int64;
    function AsGuid: TGuid;
    function AsCurrency: Currency;
    function AsXml:string;
    function AsPrettyXml: string;

    procedure Assign(const aValue: integer); overload;
    procedure Assign(const aValue: boolean; const aUseBoolStrs: boolean = true); overload;
    procedure Assign(const aValue: string); overload;
    procedure Assign(const aValue: single); overload;
    procedure Assign(const aValue: double); overload;
    procedure Assign(const aValue: TDateTime); overload;
    procedure Assign(const aValue: char); overload;
    procedure Assign(const aValue: Int64); overload;
    procedure Assign(const aValue: TGuid); overload;
    procedure Assign(const aValue: Currency); overload;

    procedure AddElem(const aElement: IBvElement);
    function AppendElem(const aElement: IBvElement): IBvElement;
    function AddOrSetElem(const aName: string; const aValue: string = ''): IBvElement; overload;
    function AddOrSetElem(const aOther: IBvElement): IBvElement; overload;
    function Elem(const aName: string; const aValue: string = ''): IBvElement;
    function HasElem(const aName: string): boolean;
    function FirstElem: IBvElement;
    function LastElem: IBvElement;
    function ElemIndexOf(const aName: string): integer;
    function PushElem(const aElement: IBvElement): IBvElement; overload;
    function PushElem(const aName: string; const aValue: string): IBvElement; overload;
    function PeekElem: IBvElement;
    function PopElem: IBvElement;
    procedure RemoveElem(const aName: string);
    procedure RemoveElemAt(const aIndex: integer);
    procedure ClearElems;
    function Elems: TEnumerable<IBvElement>;
    function ElemAt(const aIndex: integer): IBvElement;
    function MethodMissing(const aName: string; const aHint: TInvokeHint; const aArgs: TArray<Variant>): Variant; override;

    constructor Create; overload;
    constructor Create(const aName: string; const aValue: string = ''); overload;
    constructor Create(var aOther: IBvElement); overload;
    destructor Destroy; override;

    class function New: TDynamic;
  end;

  TBvParserState = (
    { The parser has no state }
    psNone,
    { The parser is processing a comment }
    psComment,
    { The parser is processing the prologue }
    psPrologue,
    { The parser is processing a CDATA section }
    psCDATA,
    { The parser is analyzing a start element tag (opening tag) }
    psStartElement,
    { The parser is analyzing an end element tag (closing tag) }
    psEndElement,
    { The parser is expecting an attribute name or a terminating tag character '>' }
    psExpectAttrName,
    { The parser is analyzing an attribute name. }
    psAttrName,
    { The parser is expecting an attribute value }
    psExpectAttrValue,
    { The parser is expecting an '=' sign following the construction of an attribute name }
    psExpectEquals,
    { The parser is analyzing an attribute value }
    psAttrValue,
    { The parser is analyzing an element value }
    psValue,
    { The parser has completed building the root element }
    psDone
  );

  TBvParserStates = set of TBvParserState;

  TBvParserException = class(Exception)
    Index: integer;
    CurrentChar: char;
    NextChar: char;
    PrevQuote: char;
    State: TBvParserState;
    PrevState: TBvParserState;
    Xml: string;
    Token: string;
    Stack: string;
    Hint: string;
    LastElement: string;
    Error: string;

    function ToString: string; override;

    constructor Create;
  end;

  /// <summary>
  ///  Basic, but convenient, permissive XML Parser for simple use cases.
  /// </summary>
  TBvParser = class
  private
    fBuffer:      string;
    fRoot:        IBvElement;
    fState:       TBvParserState;
    fPrevState:   TBvParserState;
    fPrevQuote:   char;
    fElement:     IBvElement;

    { the core parsing routine }
    function Parse(const aXml: string): IBvElement;

    { called when we are ready to identify an element opening tag }
    procedure OnStartElement;

    { called when we are ready to identify an attribute name }
    procedure OnExpectAttributeName;

    { called when the attribute name has been processed }
    procedure OnAttributeNameComplete;

    { called when we are to begin processing an attribute value }
    procedure OnAttributeValue;

    { called when the attribute value has been processed }
    procedure OnAttributeValueComplete;

    { called when the start element tag has been processed }
    procedure OnStartElementComplete;

    { called when we are to begin processing an end element tag }
    procedure OnEndElement;

    { called when the end element tag has been processed }
    procedure OnEndElementComplete;

    { sometimes tokens are split into two, i.e. because of an interjected comment }
    procedure UpdateLastValue;

    { changes the parser state, keeps track of previous state }
    procedure SetState(aState: TBvParserState);

    { raises an exception with debug information }
    procedure Fail(const aXml: string; const aHint: string; aIndex: integer; aCurrChar, aNextChar: char);

    { ensures we keep previous state on state changes }
    property State: TBvParserState read FState write SetState;
  public
    class function Execute(const aXml: string): TResult<IBvElement>;
  end;

  TXml = record
    class function Parse(const aXml: string): TResult<IBvElement>; static;
    class function Load(const aPath: string): TResult<IBvElement>; static;
    class procedure Save(const aPath: string; const aElement: IBvElement); static;
  end;

const
  XmlEntities: array[xAmpersand..xQuote] of string = (
    '&amp;',
    '&lt;',
    '&gt;',
    '&apos;',
    '&quot;'
  );

  XmlLiterals: array[xAmpersand..xQuote] of string = (
    '&',
    '<',
    '>',
    #$0027,
    #$0022
  );

   { Functions }

  function IsValidNameChar(aChar: char): boolean; inline;
  function IsValidName(const aName: string): boolean;
  function RemoveEntities(const aValue: string): string;
  function ConvertToEntities(const aValue: string): string;
  function GetEntity(const aValue: string; aIndex: integer): string;
  function GetCharacter(const aValue: string; var aIndex: integer): string;
  function PeekAhead(const aValue: string; const aIndex: integer; const aCount: integer): string;

const
  ValueState:                 TBvParserStates = [psValue, psAttrValue];
  NoneOrValueState:           TBvParserStates = [psNone, psValue, psAttrValue];
  StartEndOrExpAttrNameState: TBvParserStates = [psStartElement, psEndElement, psExpectAttrName];
  CommentValidState:          TBvParserStates = [psNone, psStartElement, psEndElement, psExpectAttrName, psValue];

var
  lEntityToLiteralMap: TDictionary<string, string>;
  lLiteralToEntityMap: TDictionary<string, string>;
  lInvalidCharacters: TList<integer>;

implementation

uses
  System.Variants,
  System.Rtti,
  System.StrUtils,
  System.Character,
  System.DateUtils,
  System.IOUtils,
  Base.Conversions;

{$region 'Functions' }

{----------------------------------------------------------------------------------------------------------------------}
function IsValidNameChar(aChar: char): boolean;
const
  VALID_CHARS = ['-', '_', '.', '#', ':'];
begin
  Result := (aChar.IsLetterOrDigit) or (CharInSet(aChar, VALID_CHARS));
end;

{----------------------------------------------------------------------------------------------------------------------}
function IsValidName(const aName: string): boolean;
var
  lCh: Char;
begin
  if Length(aName) < 1 then exit(false);
  if Length(aName) > 1024 then exit(false);

  lCh := aName.Chars[0];

  if (not lCh.IsLetter) and (lCh <> '_')  then exit(false);

  for lCh in aName do
    if not IsValidNameChar(lCh) then exit(false);

  Result := Length(aName) > 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function GetEntity(const aValue: string; aIndex: integer): string;
begin
  if aValue.Chars[aIndex] <> '&' then exit(aValue.Chars[aIndex]);

  Result := '&';
  Inc(aIndex);

  while (aIndex < Length(aValue)) and (Length(Result) < 6)  do
  begin
    var c := aValue.Chars[aIndex];
    Result := Result + c ;

    if c = ';' then break;

    Inc(aIndex);
  end;

  if lEntityToLiteralMap.ContainsKey(Result) then exit;

  Result := '';
end;

{----------------------------------------------------------------------------------------------------------------------}
function GetCharacter(const aValue: string; var aIndex: integer): string;
begin
  var isHex    := false;
  var fallback := aValue.Chars[aIndex];

  var i := aIndex;

  if aValue.Chars[i] <> '&' then exit(fallback);
  Inc(i);

  if aValue.Chars[i] <> '#' then exit(fallback);
  Inc(i);

  if aValue.Chars[i] = 'x' then
  begin
    isHex := true;
    Inc(i);
  end;

  var num := '';
  var amp := false;

  while (not amp) and (i < Length(aValue)) and (Length(num) < 7)  do
  begin
    var ch := aValue.Chars[i];

    if ch = ';' then
      amp := true
    else
    begin
      if (TConvert.IsDecimalValue(ch)) or (isHex and TConvert.IsHexValue(ch)) then
        num := num + ch
      else
        exit(fallback)
    end;

    Inc(i);
  end;

  if not amp then exit(fallback);

  var value := 0;

  for var c in num do
    if isHex then
      value := value * 16 + TConvert.HexValue(c)
    else
      value := value * 10 + TConvert.DecimalValue(c);

  if value > $10FFFF then exit(fallback);

  if lInvalidCharacters.Contains(value) then exit(fallback);

  aIndex := i;

  Result := TConvert.CodePointToString(value);
end;

{----------------------------------------------------------------------------------------------------------------------}
function RemoveEntities(const aValue: string): string;
begin
  if string.IsNullOrWhiteSpace(aValue) then exit(aValue);

  Result := '';

  var i := 0;
  var n := aValue.Length - 1;

  while i < aValue.Length do
  begin
    var ch := aValue.Chars[i];
    var next := if i < n then aValue.Chars[i + 1] else #0;

    { normal character }
    if ch <> '&' then
    begin
      Result := Result + ch;
      Inc(i);
      continue;
    end;

    { possible character reference }
    if next = '#' then
    begin
      Result := Result + GetCharacter(aValue, i);
      Inc(i);
      continue;
    end;

    { possible entity }
    var text := GetEntity(aValue, i);

    if text = '' then
      Result := Result + ch
    else
    begin
      Inc(i, Length(text) - 1);
      Result := Result + lEntityToLiteralMap[text];
    end;

    Inc(i);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function ConvertToEntities(const aValue: string): string;
begin
  if string.IsNullOrWhiteSpace(aValue) then exit(aValue);

  var i := 0;

  while i < aValue.Length do
  begin
    var ch := aValue.Chars[i];

    case ch of
        '<':
          Result := Result + lLiteralToEntityMap['<'];
        '>':
          Result := Result + lLiteralToEntityMap['>'];
        #$0027:
          Result := Result + lLiteralToEntityMap[#$0027];
        #$0022:
          Result := Result + lLiteralToEntityMap[#$0022];
        '&':
          begin
            var text := GetEntity(aValue, i);

            if text = '' then
              Result := Result + lLiteralToEntityMap['&']
            else
            begin
              Inc(i, Length(text) - 1);
              Result := Result + text;
            end;
          end
        else
          Result := Result + ch;
    end;

    Inc(i);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function PeekAhead(const aValue: string; const aIndex: integer; const aCount: integer): string;
begin
  Result := '';

  var n := aIndex + aCount;

  if n >= Length(aValue) then exit('');

  var i := aIndex;

  while i < n do
  begin
    Result := Result + aValue[i];
    Inc(i);
  end;
end;

{$endregion}

{$region 'TBvAttribute'}

{ TBvAttribute }

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.SetName(const aValue: string);
var
  lName: string;
begin
  Ensure.IsTrue(Length(fName) = 0, 'Attribute names are immutable');

  lName := Trim(aValue);

  Ensure.IsTrue(IsValidName(lName), 'Invalid attribute name: ' + aValue);

  fName := lName;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.SetValue(const aValue: string);
begin
  fValue := RemoveEntities(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.HasValue: boolean;
begin
  Result := Length(fValue) > 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.AsBoolean: boolean;
begin
  Result := TConvert.ToBoolOr(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.AsChar: Char;
begin
  if Length(fValue) < 1 then
    Result := #0
  else
    Result := fValue.Chars[0];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.AsCurrency: Currency;
begin
  Result := TConvert.ToCurrencyOrInv(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.AsDateTime: TDateTime;
begin
  Result := TConvert.ToDateTimeISO8601(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.AsDouble: double;
begin
  Result := TConvert.ToDoubleOr(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.AsGuid: TGuid;
begin
  Result := TConvert.ToGuidOr(fValue, TGuid.Empty);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.AsSingle: single;
begin
  Result := TConvert.ToSingleOr(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.AsInt64: Int64;
begin
  Result := TConvert.ToInt64Or(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.AsInteger: integer;
begin
  Result := TConvert.ToIntOr(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.AsString: string;
begin
  Result := fValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvAttribute.AsXml: string;
begin
  if Length(fValue) = 0 then exit('');

  var value := ConvertToEntities(fValue);

  Result := Format('%s="%s"', [fName, value]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.Assign(const aValue: boolean; const aUseBoolStrs: boolean);
begin
 fValue := BoolToStr(aValue, aUseBoolStrs);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.Assign(const aValue: integer);
begin
 fValue := IntToStr(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.Assign(const aValue: char);
begin
  fvalue := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.Assign(const aValue: single);
begin
  fValue := TConvert.SingleToStringInv(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.Assign(const aValue: double);
begin
  fValue := TConvert.DoubleToStringInv(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.Assign(const aValue: TDateTime);
begin
  fValue := TConvert.DateTimeToStringISO8601(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.Assign(const aValue: string);
begin
  fValue := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.Assign(const aValue: Int64);
begin
  fValue := IntToStr(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.Assign(const aValue: TGuid);
begin
  fValue := GUIDToString(aValue);
end;
{----------------------------------------------------------------------------------------------------------------------}
procedure TBvAttribute.Assign(const aValue: Currency);
begin
  fValue := TConvert.CurrencyToStringInv(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TBvAttribute.Create(const aName, aValue: string);
begin
  SetName(aName);
  SetValue(aValue);
end;

{$endregion}

{$region 'TBvElement'}

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.GetName: string;
begin
  Result := fName;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.GetValue: string;
begin
  Result := fValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.GetParent: TBvElement;
begin
  Result := fParent;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.SetParent(const aValue: TBvElement);
begin
  fParent := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.SetName(const aValue: string);
var
  lName: string;
begin
  Ensure.IsTrue(Length(fName) = 0, 'Element names are immutable');

  lName := Trim(aValue);

  Ensure.IsTrue(IsValidName(lName), 'Invalid element name: ' + aValue);

  fName := lName;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.SetValue(const aValue: string);
begin
  fValue := RemoveEntities(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.HasElems: boolean;
begin
  Result := fElems.Count > 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.HasValue: boolean;
begin
  Result := Length(fValue) > 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.ElemCount: integer;
begin
  Result := fElems.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsBoolean: boolean;
begin
  Result := TConvert.ToBoolOr(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsChar: Char;
begin
  if Length(fValue) < 1 then
    Result := #0
  else
    Result := fValue.Chars[0];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsCurrency: Currency;
begin
  Result := TConvert.ToCurrencyOrInv(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsDateTime: TDateTime;
begin
  Result := TConvert.ToDateTimeISO8601(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsDouble: double;
begin
  Result := TConvert.ToDoubleOr(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsGuid: TGuid;
begin
  Result := TConvert.ToGuidOr(fValue, TGuid.Empty);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsSingle: single;
begin
  Result := TConvert.ToSingleOr(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsInt64: Int64;
begin
  Result := TConvert.ToInt64Or(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsInteger: integer;
begin
  Result := TConvert.ToIntOr(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsString: string;
begin
  Result := fValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsXml: string;
var
  lBuilder: TStringBuilder;
begin
  if Length(fName) = 0 then exit('');

  lBuilder := TStringBuilder.Create;
  try
    AppendTrimXml(lBuilder);
    Result := TrimRight(lBuilder.ToString);
  finally
    lBuilder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AsPrettyXml: string;
var
  lBuilder: TStringBuilder;
begin
  if Length(fName) = 0 then exit('');

  lBuilder := TStringBuilder.Create;
  try
    AppendXml(lBuilder);
    Result := TrimRight(lBuilder.ToString);
  finally
    lBuilder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.AppendTrimXml(const [ref] aBuilder: TStringBuilder);
var
  lAttr: TBvAttribute;
  lElem: IBvElement;
begin
  aBuilder.AppendFormat('<%s', [fName]);

  for lAttr in Attrs do
    aBuilder.AppendFormat(' %s', [lAttr.AsXml]);

  if (not HasValue) and (not HasElems) then
  begin
    aBuilder.Append('/>');
    exit;
  end;

  aBuilder.Append('>');

  if HasValue then
    aBuilder.Append(ConvertToEntities(fValue));

  if not HasElems then
  begin
    aBuilder.AppendFormat('</%s>', [fName]);
    exit;
  end;

  for lElem in fElems do
    lElem.AppendTrimXml(aBuilder);

  aBuilder.AppendFormat('</%s>', [fName]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.AppendXml(const [ref] aBuilder: TStringBuilder; indent: string);
var
  lAttr: TBvAttribute;
  lElem: IBvElement;
begin
  aBuilder.AppendFormat('%s<%s', [indent, fName]);

  for lAttr in Attrs do
    aBuilder.AppendFormat(' %s', [lAttr.AsXml]);

  if (not HasValue) and (not HasElems) then
  begin
    aBuilder.AppendLine('/>');
    exit;
  end;

  aBuilder.Append('>');

  if HasValue then
    aBuilder.Append(ConvertToEntities(fValue));

  if not HasElems then
  begin
    aBuilder.AppendFormat('</%s>', [fName]);
    aBuilder.AppendLine;
    exit;
  end;

  aBuilder.AppendLine;

  for lElem in fElems do
    lElem.AppendXml(aBuilder, indent + '  ');

  aBuilder.AppendFormat('%s</%s>', [indent, fName]);
  aBuilder.AppendLine;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Assign(const aValue: boolean; const aUseBoolStrs: boolean);
begin
 fValue := BoolToStr(aValue, aUseBoolStrs);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Assign(const aValue: integer);
begin
 fValue := IntToStr(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Assign(const aValue: char);
begin
  fvalue := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Assign(const aValue: single);
begin
  fValue := TConvert.SingleToStringInv(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Assign(const aValue: double);
begin
  fValue := TConvert.DoubleToStringInv(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Assign(const aValue: TDateTime);
begin
  fValue := TConvert.DateTimeToStringISO8601(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Assign(const aValue: string);
begin
  fValue := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Assign(const aValue: Int64);
begin
  fValue := IntToStr(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Assign(const aValue: TGuid);
begin
  fValue := GUIDToString(aValue);
end;
{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Assign(const aValue: Currency);
begin
  fValue := TConvert.CurrencyToStringInv(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.ElemIndexOf(const aName: string): Integer;
var
  i: Integer;
  e: IBvElement;
begin
  for i := 0 to fElems.Count - 1 do
  begin
    e := fElems[i];

    if e.Name = aName then exit(i);
  end;

  Result := -1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.Elems: TEnumerable<IBvElement>;
begin
  Result := fElems;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.HasElem(const aName: string): boolean;
begin
  Result := ElemIndexOf(aName) <> -1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.FirstElem: IBvElement;
begin
  Ensure.IsTrue(fElems.Count > 0, 'There are no subelements');

  Result := fElems[0];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.LastElem: IBvElement;
begin
  Ensure.IsTrue(fElems.Count > 0, 'There are no subelements');

  Result := fElems[Pred(fElems.Count)];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.PeekElem: IBvElement;
begin
  Result := LastElem;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.MethodMissing(const aName: string; const aHint: TInvokeHint; const aArgs: TArray<Variant>): Variant;
begin
  if aHint = ivPropertySetValue then
  begin
    var e: IBvElement := Elem(aName);

    if Length(aArgs) = 1 then
      e.Value := aArgs[0]
    else if Length(aArgs) = 2 then
      e.Attr(aArgs[0]).Value := aArgs[1];

    exit;
  end;

  if aHint = ivPropertyGet then
  begin
    var e: IBvElement := Elem(aName);
    Result := e;
    exit;
  end;

  if aHint = ivMethod then
  begin
    var e: IBvElement := Elem(aName);

    if Length(aArgs) = 0 then
      Result := e
    else if Length(aArgs) = 1 then
      Result := e.Attr(aArgs[0]).Value
    else if Length(aArgs) = 2 then
      e.Attr(aArgs[0]).Value := aArgs[1];
  end;
end;

/// <summary>
///  Adds a child element to fElems (side-effect only).
///  Safe internal primitive: no interface return temporary.
/// </summary>
procedure TBvElement.AddElem(const aElement: IBvElement);
begin
  aElement.Parent := Self;
  fElems.Add(aElement);
end;

/// <summary>
///  Adds a child element and returns that child.
///  Useful for internal code that needs the inserted element.
/// </summary>
function TBvElement.AppendElem(const aElement: IBvElement): IBvElement;
begin
  AddElem(aElement);
  Result := aElement;
end;

/// <summary>Pushes a new element onto the back of the list.</summary>
/// <remarks>Returns the current element for chaining.</remarks>
function TBvElement.PushElem(const aElement: IBvElement): IBvElement;
begin
  AddElem(aElement);
  Result := Self;
end;

function TBvElement.PushElem(const aName, aValue: string): IBvElement;
begin
  // Important: avoid passing a temporary straight into a fluent method
  // This is safe regardless, but keeps the pattern consistent.
  AppendElem(TBvElement.Create(aName, aValue));
  Result := Self;
end;

/// <summary>
///  Sets the value of the element with the specified name; if it doesn't exist then a new element is created.
/// </summary>
/// <returns>The added or updated element.</returns>
function TBvElement.AddOrSetElem(const aName, aValue: string): IBvElement;
var
  i: Integer;
begin
  i := ElemIndexOf(aName);

  if i <> -1 then
  begin
    fElems[i].SetValue(aValue);
    Exit(fElems[i]);
  end;

  // Return the element instance directly (do not index back into fElems after a fluent call).
  Result := AppendElem(TBvElement.Create(aName, aValue));
end;

/// <summary>
///  Adds the element if it doesn't exist, otherwise replaces the existing element.
/// </summary>
/// <returns>The added or updated element (aOther).</returns>
function TBvElement.AddOrSetElem(const aOther: IBvElement): IBvElement;
var
  i: Integer;
begin
  i := ElemIndexOf(aOther.Name);

  if i = -1 then
  begin
    AddElem(aOther);
    Exit(aOther);
  end;

  fElems[i].Parent := nil;

  aOther.Parent := Self;
  fElems[i] := aOther;

  Result := aOther;
end;

/// <summary>Gets the element with the specified name, adds it if it doesn't exist.</summary>
function TBvElement.Elem(const aName, aValue: string): IBvElement;
var
  i: Integer;
begin
  i := ElemIndexOf(aName);
  if i <> -1 then
    Exit(fElems[i]);

  Result := AppendElem(TBvElement.Create(aName, aValue));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.RemoveElemAt(const aIndex: integer);
begin
  Ensure.InRange(aIndex, 0, fElems.Count - 1, 'Index out of range');

  fElems[aIndex].Parent := nil;
  fElems.Delete(aIndex);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.RemoveElem(const aName: string);
begin
  var i := ElemIndexOf(aName);

  if i <> -1 then
    RemoveElemAt(i);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.PopElem: IBvElement;
var
  i: Integer;
  Elem: IBvElement;
begin
  Ensure.IsTrue(fElems.Count > 0, 'There are no subelements to pop');

  i := fElems.Count - 1;
  Elem := fElems[i];          // strong ref local

  // detach from parent while we still hold a reference
  Elem.Parent := nil;
  fElems.Delete(i);

  Result := Elem;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.ClearElems;
begin
  fElems.Clear;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.ElemAt(const aIndex: integer): IBvElement;
begin
  Ensure.IsTrue(fElems.Count > 0, 'There are no elements')
        .IsTrue((aIndex >= 0) and (aIndex < fElems.Count), 'element index out of range');

  Result := fElems[aIndex];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.HasAttrs: boolean;
begin
  Result := fAttrs.Count > 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AttrCount: integer;
begin
  Result := fAttrs.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AttrAt(const aIndex: integer): TBvAttribute;
begin
  Ensure.IsTrue(fAttrs.Count > 0, 'There are no attributes')
        .IsTrue((aIndex >= 0) and (aIndex < fAttrs.Count), 'attribute index out of range');

  Result := fAttrs[aIndex];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.FirstAttr: TBvAttribute;
begin
  Ensure.IsTrue(fAttrs.Count > 0, 'There are no attributes');

  Result := fAttrs[0];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.GetAttribute(aName: string): string;
begin
  Result := Attr(aName).Value;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.SetAttribute(aName: string; const aValue: string);
begin
  AddOrSetAttr(aName, aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.LastAttr: TBvAttribute;
begin
  Ensure.IsTrue(fAttrs.Count > 0, 'There are no attributes');

  Result := fAttrs[Pred(fAttrs.Count)];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.PeekAttr: TBvAttribute;
begin
  Result := LastAttr;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.PopAttr: TBvAttribute;
begin
  Ensure.IsTrue(fAttrs.Count > 0, 'There are no attributes to pop');

  var i := Pred(fAttrs.Count);

  Result := fAttrs[i];

  fAttrs.Delete(i);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.PushAttr(const aAttribute: TBvAttribute): IBvElement;
const
  ERR = 'Attribute with the same name already exists: %s';
begin
  Ensure.IsFalse(HasAttr(aAttribute.Name), Format(ERR, [aAttribute.Name]));

  fAttrs.Add(aAttribute);

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.PushAttr(const aName, aValue: string): IBvElement;
begin
  PushAttr(TBvAttribute.Create(aName, aValue));

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.RemoveAttr(const aName: string);
begin
  var i := AttrIndexOf(aName);

  if i <> -1 then
  begin
    fAttrs[i].Free;
    fAttrs.Delete(i);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AttrIndexOf(const aName: string): integer;
begin
  for var i := 0 to Pred(fAttrs.Count) do
    if (fAttrs[i].Name = aName) then exit(i);

  Result := -1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.Attrs: TEnumerable<TBvAttribute>;
begin
  Result := fAttrs;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.HasAttr(const aName: string): boolean;
begin
  Result := AttrIndexOf(aName) <> -1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.Attr(const aName, aValue: string): TBvAttribute;
begin
  var i := AttrIndexOf(aName);

  if i <> -1 then
    Result := fAttrs[i]
  else
  begin
    Result := TBvAttribute.Create(aName, aValue);
    fAttrs.Add(Result);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AddOrSetAttr(const aName, aValue: string): IBvElement;
begin
  var i := AttrIndexOf(aName);

  if i = -1 then
    fAttrs.Add(TBvAttribute.Create(aName, aValue))
  else
    fAttrs[i].Value := aValue;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AddOrSetAttr(const aOther: TBvAttribute): IBvElement;
begin
  var i := AttrIndexOf(aOther.Name);

  if i = -1 then
    fAttrs.Add(aOther)
  else
  begin
    fAttrs[i].Free;
    fAttrs[i] := aOther;
  end;

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.ClearAttrs;
begin
  for var i := 0 to Pred(fAttrs.Count) do
    fAttrs[i].Free;

  fAttrs.Clear;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Initialize;
begin
  fElems := TList<IBvElement>.Create;
  fAttrs := TList<TBvAttribute>.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TBvElement.Create;
begin
  inherited Create;

  Initialize;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TBvElement.Create(const aName, aValue: string);
begin
  inherited Create;

  Initialize;

  SetName(aName);
  SetValue(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TBvElement.Create(var aOther: IBvElement);
begin
  inherited Create;

  fName := aOther.Name;
  fValue := aOther.Value;

  fElems := TList<IBvElement>.Create;

  for var e in aOther.Elems do
    PushElem(e);

  fAttrs := TList<TBvAttribute>.Create(aOther.Attrs);

  aOther.ClearElems;
  aOther.ClearAttrs;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TBvElement.Destroy;
begin
  ClearAttrs;
  ClearElems;

  fAttrs.Free;
  fElems.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TBvElement.New: TDynamic;
begin
  Result := TBvElement.Create.AsDynamic;
end;


{$endregion}

{$region 'TBvParserException'}

{----------------------------------------------------------------------------------------------------------------------}
constructor TBvParserException.Create;
begin
  Index := -1;
  State := psNone;
  PrevState := psNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvParserException.ToString: string;
var
  sb: TStringBuilder;
  st, prevSt: string;
begin
  st     := TRttiEnumerationType.GetName(State);
  prevSt := TRttiEnumerationType.GetName(PrevState);
  sb     := TStringBuilder.Create;

  sb.AppendLine('An error occurred during xml parsing:');
  sb.AppendLine(Hint);
  sb.AppendLine;

  sb.AppendLine('Debugging details:');
  sb.AppendLine;
  sb.AppendFormat('curr index: %d', [Index]);
  sb.AppendLine;
  sb.AppendFormat('curr  char: %s', [CurrentChar]);
  sb.AppendLine;
  sb.AppendFormat('next  char: %s', [NextChar]);
  sb.AppendLine;
  sb.AppendFormat('prev quote: %s', [PrevQuote]);
  sb.AppendLine;
  sb.AppendFormat('curr state: %s', [st]);
  sb.AppendLine;
  sb.AppendFormat('prev state: %s', [prevSt]);
  sb.AppendLine;
  sb.AppendFormat('curr token: %s', [Token]);

  if Length(Stack) > 0 then
  begin
    sb.AppendLine;
    sb.AppendLine('Element stack details:');
    sb.AppendLine;
    sb.AppendLine(Stack);
  end;

  if Length(LastElement) > 0 then
  begin
    sb.AppendLine;
    sb.AppendLine('Last created element:');
    sb.AppendLine;
    sb.AppendLine(LastElement);
  end;

  if Length(Xml) > 0 then
  begin
    sb.AppendLine;
    sb.AppendLine('Xml details:');
    sb.AppendLine;
    sb.AppendLine(Xml);
  end;

  if Length(Error) > 0 then
  begin
    sb.AppendLine;
    sb.AppendLine('Exception details');
    sb.AppendLine;
    sb.AppendLine(Error);
  end;

  Result := sb.ToString;

  sb.Free;
end;

{$endregion}


{$region 'TBvParser'}

{----------------------------------------------------------------------------------------------------------------------}
class function TBvParser.Execute(const aXml: string): TResult<IBvElement>;
begin
  if string.IsNullOrWhiteSpace(aXml) then
    TResult<IBvElement>.Err('xml is blank');

  var p := TBvParser.Create;
  try
    try
      var e := p.Parse(aXml);

      if Assigned(e) then
      begin
        Result := TResult<IBvElement>.Ok(e);
        exit;
      end;

      Result := TResult<IBvElement>.Ok(TBvElement.Create);
    except on E: Exception do
      Result := TResult<IBvElement>.Err(e.ToString);
    end;

    p.fRoot := nil; // todo - confirm
  finally
    p.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvParser.Parse(const aXml: string): IBvElement;
var
  i:      integer;
  j:      integer;
  count:  integer;
  curr:   char;
  next:   char;
begin
  fPrevState := psNone;
  fState     := psNone;
  fPrevQuote := #0;
  i          := 0;
  count      := Length(aXml);

  while (fState <> psDone) and (i < count) do
  begin
    curr := aXml.Chars[i];

    Inc(i);

    if ((curr = #10) or (curr = #13)) and ((fState <> psValue) and (fState <> psAttrValue))  then
      curr := #32;

    next := if i = count then #0 else aXml.Chars[i];

    { terminate prologue if possible }
    if fState = psPrologue then
    begin
      if curr <> '?' then continue;
      if next <> '>' then Fail(aXml, 'Unexpected characters "?"', i, curr, next);
      Inc(i);
      State := psNone;
      continue;
    end;

    { terminate comment if possible }
    if fState = psComment then
    begin
      if curr <> '-' then continue;
      if next <> '-' then continue;

      if (i+1 < count) and (aXml.Chars[i+1] = '>') then
        fState := fPrevState;

      Inc(i, 2);

      continue;
    end;

    { manage quotes }
    if (curr = '''') or (curr = '"') then
    begin
      if fState = psExpectAttrValue then
      begin
        fPrevQuote := curr;
        OnAttributeValue;
        continue;
      end;

      if fState = psAttrValue then
      begin
        if fPrevQuote <> curr then
          fBuffer := fBuffer + curr
        else
        begin
          OnAttributeValueComplete;
          fPrevQuote := #0;
        end;
        continue;
      end;

      if FState <> psValue then
        Fail(aXml, 'Unexpected character (quote): ' + curr, i, curr, next);

      fBuffer := fBuffer + curr;
      continue;
    end;

    { manage start tag identifier }
    if curr = '<' then
    begin
      if next = '!' then
      begin
        { if there's a CDATA read it straight into the buffer }
        if (fState = psValue) and (fPrevQuote = #0) then
        begin
          j := i + 2;

          if (j < count) and (aXml[j] = '[')  and (PeekAhead(aXml, j, 7) = '[CDATA[') then
          begin
            Inc(i, 9);

            var endIndex := aXml.IndexOf(']]>', i);

            if endIndex <> -1 then
            begin
              while i <= endIndex do
              begin
                fBuffer := fBuffer + aXml[i];
                Inc(i);
              end;

              Inc(i, 2);
              continue;
            end;
          end;
        end;

        if not (fState in CommentValidState) then
          Fail(aXMl, 'Unexpected character "<"', i, curr, next);

        if (i + 2 < count) and (aXml.Chars[i+1] = '-') and (aXml.Chars[i+2] = '-') then
        begin
          Inc(i, 3);
          State := psComment;
          continue;
        end;

        Fail(aXml, 'Unexpected character "<"', i, curr, next);
      end;

     if not (fState in NoneOrValueState) then
        Fail(aXMl, 'Unexpected character "<"', i, curr, next);

      if next = '/' then
      begin
        Inc(i);
        OnEndElement;
        continue;
      end;

      if (next = '?') and (not (fState in ValueState)) then
      begin
        Inc(i);
        State := psPrologue;
        continue;
      end;

      OnStartElement;
      continue;
    end;

    { manage end tag identifier }
    if curr = '>' then
    begin
      if not (fState in StartEndOrExpAttrNameState) then
        Fail(aXml, 'Unexpected character ">"', i, curr, next);

      if fState <> psEndElement then
      begin
        OnStartElementComplete;
        continue;
      end;

      if not Assigned(fRoot) then
        Fail(aXml, 'Empty element, unexpected character ">"', i, curr, next);

      OnEndElementComplete;
      continue;
    end;

    { add to current value }
    if fState in ValueState then
    begin
      if not ((Length(fBuffer) = 0) and ((curr = '\t') or (curr = '\n') or (curr = '\r'))) then
        FBuffer := fBuffer + curr;

      continue;
    end;

    { identify state change triggered by space }
    if curr = #32 then
    begin
      if fState = psStartElement then
        OnExpectAttributeName
      else if fState = psAttrName then
        OnAttributeNameComplete;

      continue;
    end;

    { identify state change triggered by an equal sign }
    if curr = '=' then
    begin
      if fState = psAttrName then
        OnAttributeNameComplete
      else if fState <> psExpectEquals then
        Fail(aXml, 'Unexpected character "="', i, curr, next);

      State := psExpectAttrValue;
      continue
    end;

    { manage end of tag }
    if curr = '/' then
    begin
      if (fState in StartEndOrExpAttrNameState) and (next <> '>') then
        Fail(aXml, 'Unexpected character "/"', i, curr, next);

      OnStartElementComplete;
      OnEndElementComplete;
      Inc(i);
      continue;
    end;

    if (fState = psExpectAttrName) and (Length(fBuffer) = 0) then
      State := psAttrName;

    if (fState <> psNone) then
      fBuffer := fBuffer + curr;
  end;

  Result := fRoot;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvParser.OnStartElement;
begin
  if Length(fBuffer) > 0 then UpdateLastValue;

  var e := TBvElement.Create;

  if not Assigned(fRoot) then
  begin
    fElement := e;
    fRoot    := e;
  end
  else
  begin
    fElement.PushElem(e);
    fElement := e;
  end;

  State := psStartElement;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvParser.OnExpectAttributeName;
begin
  if Length(fBuffer) > 0 then
  begin
    fElement.Name := fBuffer;
    fBuffer       := '';
  end;

  State := psExpectAttrName;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvParser.OnAttributeNameComplete;
begin
  fElement.PushAttr(fBuffer);
  fBuffer := '';

  State := psExpectEquals;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvParser.OnAttributeValue;
begin
  State := psAttrValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvParser.OnAttributeValueComplete;
begin
  fElement.LastAttr.Value := fBuffer;
  fBuffer := '';

  State := psExpectAttrName;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvParser.OnStartElementComplete;
begin
  if Length(FBuffer) > 0 then
  begin
    fElement.Name := fBuffer;
    fBuffer := '';
  end;

  State := psValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvParser.OnEndElement;
begin
  if Length(FBuffer) > 0 then
    UpdateLastValue;

  State := psEndElement;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvParser.OnEndElementComplete;
begin
  fElement := fElement.Parent;
  fBuffer := '';

  if not Assigned(fElement) then
    State := psDone
  else
    State := psValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvParser.UpdateLastValue;
begin
  fElement.Value := fElement.Value + Trim(fBuffer);
  fBuffer := '';
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvParser.SetState(aState: TBvParserState);
begin
  fPrevState := fState;
  fState := aState;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvParser.Fail(const aXml: string; const aHint: string; aIndex: integer; aCurrChar, aNextChar: char);
var
  e: TBvParserException;
begin
  e := TBvParserException.Create;

  with e do begin
    Hint        := aHint;
    Index       := aIndex;
    CurrentChar := aCurrChar;
    NextChar    := aNextChar;
    State       := fState;
    PrevState   := fPrevState;
    PrevQuote   := fPrevQuote;
    LastElement := if Assigned(fElement) then fElement.AsXml else '';
    Stack       := if Assigned(fRoot) then fRoot.AsXml else '';
    Token       := fBuffer;
    Xml         := aXml;
  end;

  raise e;
end;

{$endregion}

{$region 'TDynXml'}

{----------------------------------------------------------------------------------------------------------------------}
class function TXml.Parse(const aXml: string): TResult<IBvElement>;
begin
  Result := TBvParser.Execute(aXml);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TXml.Load(const aPath: string): TResult<IBvElement>;
begin
  var xml := TFile.ReadAllText(aPath);
  Result := TBvParser.Execute(xml);
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TXml.Save(const aPath: string; const aElement: IBvElement);
begin
  var xml := aElement.AsXml;
  TFile.WriteAllText(aPath, xml);
end;

{$endregion}

initialization
var
  lEntity: TBvEntity;
begin
  lEntityToLiteralMap := TDictionary<string, string>.Create(TIStringComparer.Ordinal);
  lLiteralToEntityMap := TDictionary<string, string>.Create(TIStringComparer.Ordinal);
  lInvalidCharacters  := TList<integer>.Create([0, 1, 8, 11, 12, 14, 55296, 57343, 65534, 65535]);

  for lEntity in [xAmpersand..xQuote] do
  begin
    lEntityToLiteralMap.Add(XmlEntities[lEntity], XmlLiterals[lEntity]);
    lLiteralToEntityMap.Add(XmlLiterals[lEntity], XmlEntities[lEntity]);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
finalization
  FreeAndNil(lEntityToLiteralMap);
  FreeAndNil(lLiteralToEntityMap);
  FreeAndNil(lInvalidCharacters);
end.
