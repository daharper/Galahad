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

  TBvItem = class
  private
    fName: string;
    fValue: string;

    procedure SetName(const aValue: string);
    procedure SetValue(const aValue: string);

    constructor Create(const aName: string; const aValue: string = ''); virtual;
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
    function AsInt64: integer;
    function AsGuid: TGuid;

    function AsXml: string; virtual;

    procedure Assign(const aValue: integer); overload;
    procedure Assign(const aValue: boolean; const aUseBoolStrs: boolean = false); overload;
    procedure Assign(const aValue: string); overload;
    procedure Assign(const aValue: single); overload;
    procedure Assign(const aValue: single; const aFS: TFormatSettings); overload;
    procedure Assign(const aValue: double); overload;
    procedure Assign(const aValue: double; const aFS: TFormatSettings); overload;
    procedure Assign(const aValue: TDateTime); overload;
    procedure Assign(const aValue: TDateTime; const aFS: TFormatSettings); overload;
    procedure Assign(const aValue: char); overload;
    procedure Assign(const aValue: Int64); overload;
    procedure Assign(const aValue: TGuid); overload;
  end;

  TBvAttribute = class(TBvItem)
  public
    function AsXml: string; override;

    constructor Create(const aName: string; const aValue: string = '');  override;
  end;

  TBvElement = class(TBvItem)
  private
    fElems: TList<TBvElement>;
    fAttrs: TList<TBvAttribute>;
    fParent: TBvElement;
  public
    property Parent: TBvElement read fParent write fParent;
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

{ TBvAttribute }

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.SetName(const aValue: string);
var
  lName: string;
begin
  lName := Trim(aValue);

  Ensure.IsTrue(IsValidName(lName), 'invalid attribute name: ' + aValue);

  fName := lName;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.SetValue(const aValue: string);
begin
  fValue := RemoveEntities(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvItem.HasValue: boolean;
begin
  Result := string.IsNullOrWhiteSpace(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvItem.AsBoolean: boolean;
begin
  Result := StrToBool(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvItem.AsChar: Char;
begin
  if Length(fValue) < 1 then
    Result := #0
  else
    Result := fValue.Chars[0];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvItem.AsDateTime: TDateTime;
begin
  Result := TConvert.ToDateTimeDef(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvItem.AsDouble: double;
begin
  Result := TConvert.ToDoubleDef(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvItem.AsGuid: TGuid;
begin
  Result := TConvert.ToGuidDef(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvItem.AsSingle: single;
begin
  Result := TConvert.ToSingleDef(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvItem.AsInt64: integer;
begin
  Result := TConvert.ToIntDef(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvItem.AsInteger: integer;
begin
  Result := TConvert.ToIntDef(fValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvItem.AsString: string;
begin
  Result := fValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TBvItem.AsXml: string;
begin
  Result := '';
{$IFDEF DEBUG}
  Ensure.IsFalse(true, 'Please implement in descendant');
{$ENDIF}
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TBvItem.Create(const aName, aValue: string);
begin
  SetName(aName);
  SetValue(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: boolean; const aUseBoolStrs: boolean = false);
begin
 fValue := BoolToStr(aValue, aUseBoolStrs);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: integer);
begin
 fValue := IntToStr(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: char);
begin
  fvalue := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: single);
begin
  fValue := FloatToStrF(aValue, ffGeneral, 7, 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: single; const aFS: TFormatSettings);
begin
   fValue := FloatToStrF(aValue, ffGeneral, 7, 0, aFs);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: double);
begin
   fValue := FloatToStrF(aValue, ffGeneral, 15, 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: double; const aFS: TFormatSettings);
begin
  fValue := FloatToStrF(aValue, ffGeneral, 15, 0, aFs);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: TDateTime);
begin
  fValue := DateTimeToStr(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: TDateTime; const aFS: TFormatSettings);
begin
  fValue := DateTimeToStr(aValue, aFs);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: string);
begin
  fValue := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: Int64);
begin
  fValue := IntToStr(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TBvItem.Assign(const aValue: TGuid);
begin
  fValue := GUIDToString(aValue);
end;

{ TBvAttribute }

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
constructor TBvAttribute.Create(const aName, aValue: string);
begin
  inherited Create(aName, aValue);
end;

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
