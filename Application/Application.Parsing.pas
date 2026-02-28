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
    function IsNoise: boolean;
    function IsStructural: boolean;

    constructor Create;
  end;

  TTokens = TObjectList<TToken>;

  TokenHelper = class helper for TTokens
  public
    function HasAction: boolean;
    function HasDirection: boolean;
    function ActionCount: integer;

    function HasStructuralTokens: Boolean;

    function IndexOfFirst(aKind: TTermKind): TOption<integer>;

    function FirstAction: TOption<TToken>;
    function FirstDirection: TOption<TToken>;
    function FirstStructural: TOption<TToken>;
    function StructuralCount: Integer;

    function HasKind(aKind: TTermKind): boolean;
    function CountKind(aKind: TTermKind): integer;
    function FirstKind(aKind: TTermKind): TOption<TToken>;
    function LastKind(aKind: TTermKind): TOption<TToken>;

    procedure InsertActionAtStart(const aTerm: ITerm);
    procedure InsertTokenAtStart(const aToken: TToken);

    procedure RemoveSubsequentActions;

    function StartsWithKind(aKind: TTermKind): Boolean;
    function StartsWithMannerThenDirection: Boolean;

    function HasExactlyOneAction: Boolean;
    function HasNoActions: Boolean;
    function IsDirectionOnly: Boolean;
    function IsEmptyAfterNoiseRemoval: Boolean;

    function DumpTokens: string;
    function DumpTerms: string;

    function StructuralTokens: TArray<TToken>;
  end;

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
    function TryGetBy(const aName: string; out aValue: ITerm): boolean;
  end;

  INoiseRemover = interface
    ['{03CA1948-8E5E-48E5-A9F3-8E35B455A09D}']
    procedure Execute(var aTokens: TTokens);
  end;

  INormalizer = interface
    ['{70C732A2-6207-4EA8-8F6A-C3F8E02EED87}']
    function Execute(var aTokens: TTokens): TStatus;
  end;

  ITextParser = interface
    ['{C661FDB1-B62D-4193-A512-697E7776B1B5}']
    function Execute(const aInput: string): TResult<TTokens>;
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
    function TryGetBy(const aName: string; out aValue: ITerm): boolean;
    constructor Create(const aRegistry: ITermRegistry);
  end;

  TNoiseRemover = class(TSingleton, INoiseRemover)
  public
    procedure Execute(var aTokens: TTokens);
  end;

  TNormalizer = class(TSingleton, INormalizer)
  private
    fTermResolver: ITermResolver;
  public
    function Execute(var aTokens: TTokens): TStatus;
    constructor Create(const aTermResolver: ITermResolver);
  end;

  TTextParser = class(TSingleton, ITextParser)
  private
    fTextTokenizer: ITextTokenizer;
    fTextSanitizer: ITextSanitizer;
    fWordResolver:  IWordResolver;
    fTermResolver:  ITermResolver;
    fNoiseRemover:  INoiseRemover;
    fNormalizer:    INormalizer;
  public
    function Execute(const aInput: string): TResult<TTokens>;

    constructor Create(
      const aTextSanitizer: ITextSanitizer;
      const aTextTokenizer: ITextTokenizer;
      const aWordResolver:  IWordResolver;
      const aTermResolver:  ITermResolver;
      const aNoiseRemover:  INoiseRemover;
      const aNormalizer:    INormalizer);

    destructor Destroy; override;
  end;

const
  TokenKindNames: array[TTokenKind] of string = ('Unknown', 'Text', 'Number', 'QuotedString');

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
function TTextParser.Execute(const aInput: string): TResult<TTokens>;
begin
  var text   := fTextSanitizer.Execute(aInput);
  var tokens := fTextTokenizer.Execute(text);

  fWordResolver.Execute(tokens);
  fTermResolver.Execute(tokens);
  fNoiseRemover.Execute(tokens);

  var status := fNormalizer.Execute(tokens);

  if status.IsErr then
  begin
    Result.SetErr(status);
    tokens.Free;
    exit;
  end;

  Result.SetOk(tokens);
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TTextParser.Create(
  const aTextSanitizer: ITextSanitizer;
  const aTextTokenizer: ITextTokenizer;
  const aWordResolver:  IWordResolver;
  const aTermResolver:  ITermResolver;
  const aNoiseRemover:  INoiseRemover;
  const aNormalizer:    INormalizer);
begin
  fTextSanitizer := aTextSanitizer;
  fTextTokenizer := aTextTokenizer;
  fWordResolver  := aWordResolver;
  fTermResolver  := aTermResolver;
  fNoiseRemover  := aNoiseRemover;
  fNormalizer    := aNormalizer;
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

{----------------------------------------------------------------------------------------------------------------------}
function TTermResolver.TryGetBy(const aName: string; out aValue: ITerm): boolean;
begin
  Result := fRegistry.TryGetTerm(aName, aValue);
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
function TToken.IsStructural: boolean;
begin
  Result := TermKind not in [tkUnknown, tkNoise]
end;

{----------------------------------------------------------------------------------------------------------------------}
function TToken.IsNoise: boolean;
begin
  Result := TermKind = tkNoise;
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

{ TNoiseRemover }

{----------------------------------------------------------------------------------------------------------------------}
procedure TNoiseRemover.Execute(var aTokens: TTokens);
begin
  var i := Pred(aTokens.Count);

  while i >= 0 do
  begin
    if aTokens[i].IsNoise then
      aTokens.Delete(i);

    Dec(i);
  end;
end;

{ TNormalizer }

{----------------------------------------------------------------------------------------------------------------------}
function TNormalizer.Execute(var aTokens: TTokens): TStatus;
begin
  var count := aTokens.ActionCount;

  // insert go if necessary
  if (count = 0) and ((aTokens.StartsWithKind(tkDirection)) or (aTokens.StartsWithMannerThenDirection)) then
  begin
    var term: ITerm;

    if not fTermResolver.TryGetBy(GoTermName, term) then
      exit(Result.Err('Unable to find term: %s', [GoTermName]));

    aTokens.InsertActionAtStart(term);

    exit(Result.Ok);
  end;

  if count = 0 then
    exit(Result.Err('Please enter an action'));

  if count > 1 then
    exit(Result.Err('Please enter one action at a time.'));

  Result.SetOk;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TNormalizer.Create(const aTermResolver: ITermResolver);
begin
  fTermResolver := aTermResolver;
end;

{ TokenHelper }

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.ActionCount: Integer;
begin
  Result := CountKind(tkAction);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.CountKind(aKind: TTermKind): Integer;
begin
  Result := 0;

  for var token in Self do
    if token.TermKind = aKind then
      Inc(Result);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.FirstAction: TOption<TToken>;
begin
  Result := FirstKind(tkAction);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.FirstDirection: TOption<TToken>;
begin
  Result := FirstKind(tkDirection);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.FirstStructural: TOption<TToken>;
begin
  for var token in Self do
    if token.IsStructural then
    begin
      Result.SetSome(token);
      exit;
    end;

  Result.SetNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.StructuralTokens: TArray<TToken>;
begin
  Result := Stream.From<TToken>(GetEnumerator)
                  .Filter(function(const t:TToken): boolean begin Result := t.IsStructural; end)
                  .AsArray;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.StructuralCount: Integer;
begin
  Result := 0;

  for var token in Self do
     if token.IsStructural then
        Inc(Result);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.FirstKind(aKind: TTermKind): TOption<TToken>;
begin
  for var token in Self do
    if token.TermKind = aKind then
    begin
      Result.SetSome(token);
      exit;
    end;

  Result.SetNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.LastKind(aKind: TTermKind): TOption<TToken>;
begin
  for var i := Pred(Self.Count) downto 0 do
  begin
    var token := Self[i];

    if token.TermKind = aKind then
    begin
      Result.SetSome(token);
      exit;
    end;
  end;

  Result.SetNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.HasAction: Boolean;
begin
  Result := hasKind(tkAction);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.HasDirection: Boolean;
begin
  Result := hasKind(tkDirection);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.HasExactlyOneAction: Boolean;
begin
  Result := CountKind(tkAction) = 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.HasKind(aKind: TTermKind): Boolean;
begin
  Result := false;

  for var token in Self do
    if token.TermKind = aKind then
      exit(true);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.HasNoActions: Boolean;
begin
  Result := ActionCount = 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.IsDirectionOnly: Boolean;
begin
  if (StructuralCount <> 1) then exit(false);

  var firstOp := FirstStructural;

  Result := (firstOp.IsSome) and (firstOp.Value.TermKind = tkDirection);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.IsEmptyAfterNoiseRemoval: boolean;
begin
  Result := CountKind(tkNoise) = Self.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.HasStructuralTokens: boolean;
begin
  Result := false;

  for var token in Self do
    if token.IsStructural then
      exit(true);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.StartsWithKind(aKind: TTermKind): boolean;
begin
  var t: TToken;
  Result := FirstStructural.TryGetValue(t) and (t.TermKind = aKind);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.StartsWithMannerThenDirection: boolean;
begin
  var tokens := StructuralTokens;

  if Length(tokens) < 2 then exit(false);

  if tokens[0].TermKind <> tkManner then exit(false);

  Result := tokens[1].TermKind = tkDirection;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.IndexOfFirst(aKind: TTermKind): TOption<integer>;
begin
  var i := 0;

  for var token in Self do
  begin
    if token.TermKind = aKind then
    begin
      Result.SetSome(i);
      exit;
    end;

    Inc(i);
  end;

  Result.SetNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TokenHelper.InsertActionAtStart(const aTerm: ITerm);
begin
  var token := TToken.Create;

  token.Text := aTerm.Value;
  token.Kind := ttText;
  token.Term := aTerm;

  Self.Insert(0, token);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TokenHelper.InsertTokenAtStart(const aToken: TToken);
begin
  Self.Insert(0, aToken);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TokenHelper.RemoveSubsequentActions;
begin
  var tokenOp := IndexOfFirst(tkAction);

  if tokenOp.IsNone then exit;

  var index := tokenOp.Value;
  var i := Pred(Count);

  while i > index do
  begin
    if Self[i].TermKind = tkAction then
      Self.Delete(i);

    Dec(i);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.DumpTokens: string;
begin
  Result := '';

  for var token in Self do
    if token.IsStructural then
      Result := Result + Format('%s (%s) ', [token.Text, TokenKindNames[token.Kind]]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TokenHelper.DumpTerms: string;
begin
  Result := '';

  for var token in Self do
    if token.IsStructural then
      Result := Result + Format('%s (%s) ', [token.Term.Value, TermKindNames[token.TermKind]]);
end;

end.
