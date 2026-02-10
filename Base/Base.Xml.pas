{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Xml
  Author:      David Harper
  License:     MIT
  History:     2026-08-02  Initial version
  Purpose:     Basic XML Object and Parser for simple persistance requirements.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Xml;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Base.Core;

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

  TBvElement = class
  private
    fElems: TList<TBvElement>;
    fAttrs: TList<TBvAttribute>;
    fParent: TBvElement;
    fName: string;
    fValue: string;

    procedure Initialize;

    procedure SetName(const aValue: string);
    procedure SetValue(const aValue: string);

  public
    property Parent: TBvElement read fParent write fParent;
    property Name: string read fName write SetName;
    property Value: string read fValue write SetValue;

    function Count: integer;
    function HasValue: boolean;
    function HasElems: boolean;
    function HasAttrs: boolean;

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
    ///  Updates the attribute if it exists, adds an attribute if it doesn't.
    /// </summary>
    /// <returns>The current element.</returns>
    function AddOrSetAttr(const aName: string; const aValue: string = ''): TBvElement; overload;

    /// <summary>
    ///  Adds the attribute if it doesn't exist, otherwise frees the existing element and replaces it.
    /// </summary>
    /// <returns>The current element.</returns>
    function AddOrSetAttr(const aOther: TBvAttribute): TBvElement; overload;

    /// <summary>
    ///  Gets the attribute with the specified name, add it if it doesn't.
    /// </summary>
    function Attr(const aName: string; const aValue: string = ''): TBvAttribute;

    /// <summary>
    ///  Returns true if an attribute with the specified name exists.
    /// </summary>
    function HasAttr(const aName: string): boolean;

    /// <summary>
    ///  Returns the index of the attribute with the specified name, otherwise -1.
    /// </summary>
    function AttrIndexOf(const aName: string): integer;

    /// <summary>
    ///  Sets the value of the element with the specified name, if it doesn't exist then a new element is created
    /// </summary>
    /// <returns>The added or updated element.</returns>
    function AddOrSetElem(const aName: string; const aValue: string = ''): TBvElement; overload;

    /// <summary>
    ///  Adds the element if it doesn't exist, otherwise frees the existing element and replaces it.
    /// </summary>
    /// <returns>The added or updated element.</returns>
    function AddOrSetElem(const aOther: TBvElement): TBvElement; overload;

    /// <summary>
    ///  Gets the element with the specified name, adds it if it doesn't exist.
    /// </summary>
    function Elem(const aName: string; const aValue: string = ''): TBvElement;

    /// <summary>
    ///  Returns true if an element with the specified name exists.
    /// </summary>
    function HasElem(const aName: string): boolean;

    /// <summary>
    ///  Returns the index of the element with the specified name, otherwise -1.
    /// </summary>
    function ElemIndexOf(const aName: string): integer;

    constructor Create; overload;
    constructor Create(const aName: string; const aValue: string = ''); overload;

    { takes ownership of aOther's properties and frees aOther }
    constructor Create(aOther: TBvElement); overload;

    destructor Destroy; override;
  end;

  TBvParserState = (
    { The parser has no state }
    psNone,
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
    psDone,
    { The parser is currently ignoring characters, i.e. prologue, comments, will return to previous state }
    psIgnore
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

implementation

uses
  System.Rtti,
  System.StrUtils,
  System.Character,
  System.DateUtils,
  Base.Integrity,
  Base.Conversions;

const
  IgnoreState:                TBvParserStates = [psIgnore];
  ValueState:                 TBvParserStates = [psValue, psAttrValue];
  NoneOrValueState:           TBvParserStates = [psNone, psValue, psAttrValue];
  StartEndOrExpAttrNameState: TBvParserStates = [psStartElement, psEndElement, psExpectAttrName];

var
  lEntityToLiteralMap: TDictionary<string, string>;
  lLiteralToEntityMap: TDictionary<string, string>;

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
function RemoveEntities(const aValue: string): string;
var
  lTokens: TList<string>;
  lToken: string;
  lCh: char;

  { helpers }

  function IsTokens: boolean;  begin Result := Assigned(lTokens); end;

  procedure OnClearToken; begin lToken := ''; end;
  procedure OnTokenStart; begin lToken := '&'; end;
  procedure OnTokenChar(aChar: char); begin lToken := lToken + aChar.ToLower; end;

  procedure OnTokenEnd;
  begin
    if lEntityToLiteralMap.ContainsKey(lToken) then
    begin
      if not IsTokens then lTokens := TList<string>.Create;

      if not lTokens.Contains(lToken) then
        lTokens.Add(lToken);
    end;
  end;

begin
  if string.IsNullOrWhiteSpace(aValue) then exit(aValue);

  lTokens := nil;

  try
    for lCh in aValue do
    begin
      if lCh = '&' then
      begin
        OnTokenStart;
        continue;
      end;

      if (Length(lToken) = 0) then continue;

      if lCh = ';' then
      begin
        OnTokenEnd;
        OnClearToken;
        continue;
      end;

      if not IsValidNameChar(lCh) then
        OnClearToken
      else
        OnTokenChar(lCh);
    end;

    if not IsTokens then exit(aValue);

    for lToken in lTokens do
      Result := ReplaceText(Result, lToken, lEntityToLiteralMap[lToken]);

  finally
    lTokens.Free;
  end;
end;

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

  if not fValue.Contains('"') then
    exit(Format('%s="%s"', [fName, fValue]));

  if not fValue.Contains('''') then
    exit(Format('%s=''%s''', [fName, fValue]));

  { TODO : Replace Literals with Entities }
  Result := Format('%s="%s"', [fName, fValue]);
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

{ TBvElement }

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
function TBvElement.HasAttrs: boolean;
begin
  Result := fAttrs.Count > 0;
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
function TBvElement.AttrIndexOf(const aName: string): integer;
begin
  for var i := 0 to Pred(fAttrs.Count) do
    if (fAttrs[i].Name = aName) then exit(i);

  Result := -1;
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
function TBvElement.AddOrSetAttr(const aName, aValue: string): TBvElement;
begin
  var i := AttrIndexOf(aName);

  if i = -1 then
    fAttrs.Add(TBvAttribute.Create(aName, aValue))
  else
    fAttrs[i].SetValue(aValue);

  Result := self;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AddOrSetAttr(const aOther: TBvAttribute): TBvElement;
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
function TBvElement.ElemIndexOf(const aName: string): integer;
begin
  for var i := 0 to Pred(fElems.Count) do
    if fElems[i].Name = aName then exit(i);

  Result := -1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.HasElem(const aName: string): boolean;
begin
  Result := ElemIndexOf(aName) <> -1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AddOrSetElem(const aName, aValue: string): TBvElement;
begin
  var i := ElemIndexOf(aName);

  if i <> -1 then
    fElems[i].SetValue(aValue)
  else
  begin
    fElems.Add(TBvElement.Create(aName, aValue));
    i := Pred(fElems.Count);
  end;

  Result := fElems[i];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.AddOrSetElem(const aOther: TBvElement): TBvElement;
begin
  var i := ElemIndexOf(aOther.Name);

  if i <> -1 then
  begin
    fElems[i].Free;
    fElems[i] := aOther;
  end
  else
  begin
    fElems.Add(aOther);
    i := Pred(fElems.Count);
  end;

  Result := fElems[i];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.Elem(const aName, aValue: string): TBvElement;
begin
  var i := ElemIndexOf(aName);

  if i <> -1 then exit(fElems[i]);

  fElems.Add(TBvElement.Create(aName, aValue));

  Result := fElems[Pred(fElems.Count)];
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvElement.Initialize;
begin
  fElems := TList<TBvElement>.Create;
  fAttrs := TList<TBvAttribute>.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TBvElement.Create;
begin
  Initialize;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TBvElement.Create(const aName, aValue: string);
begin
  Initialize;

  SetName(aName);
  SetValue(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvElement.Count: integer;
begin
  Result := fElems.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TBvElement.Create(aOther: TBvElement);
begin
  fName := aOther.Name;
  fValue := aOther.Value;

  fElems := TList<TBvElement>.Create(aOther.fElems);
  fAttrs := TList<TBvAttribute>.Create(aOther.fAttrs);

  aOther.fElems.Clear;
  aOther.fAttrs.Clear;

  aOther.Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TBvElement.Destroy;
var
  i: integer;
begin
  for i := 0 to Pred(fAttrs.Count) do
    fAttrs[i].Free;

  fAttrs.Free;

  for i := 0 to Pred(fElems.Count) do
    fElems[i].Free;

  fElems.Free;

  inherited;
end;

{$endregion}

{ TBvParserException }

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

initialization
var
  lEntity: TBvEntity;
begin
  lEntityToLiteralMap := TDictionary<string, string>.Create(TIStringComparer.Ordinal);
  lLiteralToEntityMap := TDictionary<string, string>.Create(TIStringComparer.Ordinal);

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

end.
