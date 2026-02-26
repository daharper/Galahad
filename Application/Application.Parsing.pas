unit Application.Parsing;

interface

uses
  System.Generics.Collections,
  Base.Core,
  Base.Integrity,
  Domain.Terms,
  Application.Language;

type
  TTokenKind = (ttUnknown, ttText, ttNumber, ttQuotedString);

  TToken = class
  private
    fKind: TTokenKind;
    fText: string;
    fWord: IWord;
    fTerm: ITerm;
  public
    property Kind: TTokenKind read fKind write fKind;
    property Text: string read fText write fText;
    property Word: IWord read fWord write fWord;
    property Term: ITerm read fTerm write fTerm;

    function IsTerm: boolean;
    function IsWord: boolean;
    function IsText: boolean;
    function IsNumber: boolean;
    function IsQuoted: boolean;
    function TermKind: TTermKind;
    function IsValidTerm: boolean;

    constructor Create;
  end;

  TTokens = TObjectList<TToken>;

  ITextSanitizer = interface
    ['{0332265D-2112-421E-9B32-D48797EE7BC0}']
    function Execute(const aInput: string): string;
  end;

  ITextTokenizer = interface
    ['{BC1BD32C-CF8F-4EA3-81DB-4F431CF3F31B}']
    function Execute(const aInput: string): TTokens;
  end;

  IWordResolver = interface
    ['{AA7341F3-FCBD-4190-8064-A7206AE4F181}']
    procedure Execute(const aTokens: TTokens);
  end;

  ITermResolver = interface
    ['{D8EA0616-D6B8-4A73-BB2D-CDC7E04E11D7}']
    procedure Execute(const aTokens: TTokens);
  end;

  INoiseRemover = interface
    ['{03CA1948-8E5E-48E5-A9F3-8E35B455A09D}']
    procedure Execute(var aTokens: TTokens);
  end;

  ITextParser = interface
    ['{C661FDB1-B62D-4193-A512-697E7776B1B5}']
    function Execute(const aInput: string): TTokens;
  end;

  TTextSanitizer = class(TSingleton, ITextSanitizer)
  public
    function Execute(const aInput: string): string;
  end;

  TTextTokenizer = class(TSingleton, ITextTokenizer)
  private
    fInput:    string;
    fPosition: Integer;

    function CurrentChar: Char;
    function IsAtEnd: Boolean;
    function GetNextToken: TToken;

    procedure SkipWhitespace;
  public
    function Execute(const aInput: string): TTokens;
  end;

  TWordResolver = class(TSingleton, IWordResolver)
  private
    fRegistry: IWordRegistry;
  public
    procedure Execute(const aTokens: TTokens);
    constructor Create(const aRegistry: IWordRegistry);
  end;

  TTermResolver = class(TSingleton, ITermResolver)
  private
    fRegistry: ITermRegistry;
  public
    procedure Execute(const aTokens: TTokens);
    constructor Create(const aRegistry: ITermRegistry);
  end;

  TNoiseRemover = class(TSingleton, INoiseRemover)
  public
    procedure Execute(var aTokens: TTokens);
  end;

  TTextParser = class(TSingleton, ITextParser)
  private
    fTextTokenizer: ITextTokenizer;
    fTextSanitizer: ITextSanitizer;
    fWordResolver:  IWordResolver;
    fTermResolver:  ITermResolver;
    fNoiseRemover:  INoiseRemover;
  public
    function Execute(const aInput: string): TTokens;

    constructor Create(
      const aTextSanitizer: ITextSanitizer;
      const aTextTokenizer: ITextTokenizer;
      const aWordResolver:  IWordResolver;
      const aTermResolver:  ITermResolver;
      const aNoiseRemover:  INoiseRemover);

    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
  System.Character,
  Base.Stream;

{ TTextParser }

{----------------------------------------------------------------------------------------------------------------------}
destructor TTextParser.Destroy;
begin
  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTextParser.Execute(const aInput: string): TTokens;
begin
  var text   := fTextSanitizer.Execute(aInput);
  var tokens := fTextTokenizer.Execute(text);

  fWordResolver.Execute(tokens);
  fTermResolver.Execute(tokens);
  fNoiseRemover.Execute(tokens);

  Result := tokens;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TTextParser.Create(
  const aTextSanitizer: ITextSanitizer;
  const aTextTokenizer: ITextTokenizer;
  const aWordResolver:  IWordResolver;
  const aTermResolver:  ITermResolver;
  const aNoiseRemover:  INoiseRemover);
begin
  fTextSanitizer := aTextSanitizer;
  fTextTokenizer := aTextTokenizer;
  fWordResolver  := aWordResolver;
  fTermResolver  := aTermResolver;
  fNoiseRemover  := aNoiseRemover;
end;

{ TWordResolver }

{----------------------------------------------------------------------------------------------------------------------}
constructor TWordResolver.Create(const aRegistry: IWordRegistry);
begin
  fRegistry := aRegistry;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TWordResolver.Execute(const aTokens: TTokens);
begin
  for var i := 0 to Pred(aTokens.Count) do
  begin
    var token := aTokens[i];

    if token.IsText then
    begin
      var wordOpt := fRegistry.GetWord(token.Text);

      if wordOpt.IsSome then
        token.Word := wordOpt.Value;
    end;
  end;
end;

{ TTermResolver }

{----------------------------------------------------------------------------------------------------------------------}
constructor TTermResolver.Create(const aRegistry: ITermRegistry);
begin
  fRegistry := aRegistry;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TTermResolver.Execute(const aTokens: TTokens);
begin
  for var i := 0 to Pred(aTokens.Count) do
  begin
    var token := aTokens[i];

    if Assigned(token.Word) then
    begin
      var term := fRegistry.GetTerm(token.Word.TermId);
      token.Term := term;
    end;
  end;
end;

{ TTextTokenizer }

{----------------------------------------------------------------------------------------------------------------------}
function TTextTokenizer.Execute(const aInput: string): TTokens;
var
  lToken: TToken;
begin
  Result := TTokens.Create(true);

  fInput := aInput;
  fPosition := 0;

  while not IsAtEnd do
  begin
    lToken := GetNextToken;
    Result.Add(lToken);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTextTokenizer.GetNextToken: TToken;
const
  WORD_SET = ['A'..'Z', 'a'..'z', ''''];
begin
  Result := TToken.Create;

  SkipWhitespace;

  if IsAtEnd then
    raise Exception.Create('End of input reached');

  if CurrentChar = '"' then
  begin
    Inc(fPosition);

    Result.Kind := ttQuotedString;
    Result.Text := '';

    while not IsAtEnd and (CurrentChar <> '"') do
    begin
      Result.Text := Result.Text + CurrentChar;
      Inc(fPosition);
    end;

    if not IsAtEnd then Inc(FPosition);

    exit;
  end;

  if CurrentChar.IsDigit then
  begin
    Result.Kind := ttNumber;
    Result.Text := '';

    while (not IsAtEnd) and (CurrentChar.IsDigit) do
    begin
      Result.Text := Result.Text + CurrentChar;
      Inc(fPosition);
    end;

    exit;
  end;

  if CharInSet(CurrentChar, WORD_SET) then
  begin
    Result.Kind := ttText;
    Result.Text := '';

    while (not IsAtEnd) and (CharInSet(CurrentChar, WORD_SET)) do
    begin
      Result.Text := Result.Text + CurrentChar;
      Inc(FPosition);
    end;

    exit;
  end;

  Result.Free;

  raise Exception.CreateFmt('Unexpected character at position %d: %s', [fPosition, CurrentChar]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTextTokenizer.IsAtEnd: Boolean;
begin
  Result := fPosition = Length(fInput);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTextTokenizer.CurrentChar: Char;
begin
  if IsAtEnd then
    Result := #0
  else
    Result := fInput.Chars[fPosition];
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TTextTokenizer.SkipWhitespace;
begin
  while (not IsAtEnd) and (CurrentChar.IsWhiteSpace) do
    Inc(fPosition);
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TToken.Create;
begin
  Kind := ttUnknown;
  Text := '';
  Word := nil;
  Term := nil;
end;

{ TToken }

{----------------------------------------------------------------------------------------------------------------------}
function TToken.IsNumber: boolean;
begin
  Result := Kind = ttNumber;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TToken.IsQuoted: boolean;
begin
  Result := Kind = ttQuotedString;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TToken.IsText: boolean;
begin
  Result := Kind = ttText;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TToken.IsWord: boolean;
begin
  Result := IsText and Assigned(Word);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TToken.TermKind: TTermKind;
begin
  if IsTerm then
    Result := term.Kind
  else
    Result := tkUnknown;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TToken.IsTerm: boolean;
begin
  Result := IsText and Assigned(Term);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TToken.IsValidTerm: boolean;
begin
  Result := TermKind not in [tkUnknown, tkNoise];
end;

{ TTextSanizizer }

{----------------------------------------------------------------------------------------------------------------------}
function TTextSanitizer.Execute(const aInput: string): string;
const
  ALLOWED = ['a'..'z', 'A'..'Z', '0'..'9', ' ', '''', '"'];
var
  ch: Char;
begin
  Result := '';

  for ch in aInput do
    if CharInSet(ch, ALLOWED) then
      Result := Result + ch.ToLower;
end;

{ TNoisePruner }

{----------------------------------------------------------------------------------------------------------------------}
procedure TNoiseRemover.Execute(var aTokens: TTokens);
begin
  var i := Pred(aTokens.Count);

  while i >= 0 do
  begin
    if not aTokens[i].IsValidTerm then
      aTokens.Delete(i);

    Dec(i);
  end;
end;

end.
