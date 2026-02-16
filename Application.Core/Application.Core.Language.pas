unit Application.Core.Language;

interface

uses
  System.Generics.Collections,
  Base.Core,
  Base.Data,
  Base.Integrity;

type
  TTermKind = (
    tkUnknown,     // fallback
    tkAction,      // CONSUME, UNLOCK, GO
    tkSubstance,   // KEY, DOOR, GOBLIN
    tkQuality,     // GOLDEN, IRON, RUSTY
    tkDirection,   // NORTH, UP, DOWN
    tkManner,      // QUICKLY, CAREFULLY
    tkPrep,        // WITH, TO, ON
    tkQuantity     // ONE, TWO, ALL
  );

  ITerm = interface(IEntity)
    ['{E224CCA0-E911-4337-BFCC-EF83813FE995}']
    function GetValue: string;
    function GetKindId: integer;
    function GetKind: TTermKind;

    procedure SetValue(const aValue: string);
    procedure SetKindId(const aValue: integer);
    procedure SetKind(const aValue: TTermKind);

    property Kind: TTermKind read GetKind write SetKind;
    property Value: string read GetValue write SetValue;
    property KindId: integer read GetKindId write SetKindId;
  end;

  IWord = interface(IEntity)
    ['{BEA756F2-0334-447F-AC31-7B088C7C6FD1}']
    function GetValue: string;
    function GetTermId: integer;

    procedure SetValue(const aValue: string);
    procedure SetTermId(const aValue: integer);

    property Value: string read GetValue write SetValue;
    property TermId: integer read GetTermId write SetTermId;
  end;

  TTerm = class(TEntity, ITerm)
  private
    fValue: string;
    fKindId: integer;
  public
    function GetValue: string;
    function GetKindId: integer;
    function GetKind: TTermKind;

    procedure SetValue(const aValue: string);
    procedure SetKindId(const aValue: integer);
    procedure SetKind(const aValue: TTermKind);

    [Transient]
    property Kind: TTermKind read GetKind write SetKind;
    property Value: string read GetValue write SetValue;
    property KindId: integer read GetKindId write SetKindId;
  end;

  TWord = class(TEntity, IWord)
  private
    fValue: string;
    fTermId: integer;
  public
    function GetValue: string;
    function GetTermId: integer;

    procedure SetValue(const aValue: string);
    procedure SetTermId(const aValue: integer);

    property Value: string read GetValue write SetValue;
    property TermId: integer read GetTermId write SetTermId;
  end;

  ITermRepository = IRepository<ITerm, TTerm>;

  IWordRepository = IRepository<IWord, TWord>;

  IWordRegistry = interface
    ['{6CECBCF0-65D1-48CD-9CEF-8669E2A9D1FF}']
    function GetTermId(const aWord: string): TMaybe<integer>;
  end;

  ITermRegistry = interface
    ['{DCCA3483-0883-4E1F-A4AC-D1B3FAB37082}']
    function GetTerm(const aId: integer): TMaybe<ITerm>;
  end;

  IVocabRegistrar = interface
    ['{BD599A48-B640-45F6-AD50-8E506A6AED7B}']
    function ResolveTerm(const aWord: string): TMaybe<ITerm>;
  end;

  TWordRegistry = class(TSingleton, IWordRegistry)
  private
    fIndex: TDictionary<string, integer>;
  public
    function GetTermId(const aWord: string): TMaybe<integer>;

    constructor Create(const aRepository:IWordRepository);
    destructor Destroy; override;
  end;

  TTermRegistry = class(TSingleton, ITermRegistry)
  private
    fIndex: TDictionary<integer, ITerm>;
  public
    function GetTerm(const aId: integer): TMaybe<ITerm>;

    constructor Create(const aRepository: ITermRepository);
    destructor Destroy; override;
  end;

  TVocabRegistrar = class(TSingleton, IVocabRegistrar)
  private
    fWords: IWordRegistry;
    fTerms: ITermRegistry;
  public
    function ResolveTerm(const aWord: string): TMaybe<ITerm>;

    constructor Create(const aWords: IWordRegistry; const aTerms: ITermRegistry);
    destructor Destroy; override;
  end;

implementation

uses
  System.Generics.Defaults;

{ TTerm }

{----------------------------------------------------------------------------------------------------------------------}
function TTerm.GetKind: TTermKind;
begin
  Result := TTermKind(fKindId);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTerm.GetKindId: integer;
begin
  Result := fKindId;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TTerm.GetValue: string;
begin
  Result := fValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TTerm.SetKind(const aValue: TTermKind);
begin
  fKindId := Ord(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TTerm.SetKindId(const aValue: integer);
begin
  fKindId := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TTerm.SetValue(const aValue: string);
begin
  fValue := aValue;
end;

{ TWord }

{----------------------------------------------------------------------------------------------------------------------}
function TWord.GetTermId: integer;
begin
  Result := fTermId;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TWord.SetTermId(const aValue: integer);
begin
  fTermId := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TWord.GetValue: string;
begin
  Result := fValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TWord.SetValue(const aValue: string);
begin
  fValue := aValue;
end;

{ TWordRegistry }

{----------------------------------------------------------------------------------------------------------------------}
constructor TWordRegistry.Create(const aRepository: IWordRepository);
begin
  fIndex := TDictionary<string, integer>.Create(TIStringComparer.Ordinal);

  for var word in aRepository.GetAll do
    fIndex.Add(word.Value, word.TermId);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TWordRegistry.Destroy;
begin
  fIndex.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TWordRegistry.GetTermId(const aWord: string): TMaybe<integer>;
var
  i: integer;
begin
  if fIndex.TryGetValue(aWord, i) then
    Result.SetSome(i)
  else
    Result.SetNone;
end;

{ TTermRegistry }

{----------------------------------------------------------------------------------------------------------------------}
function TTermRegistry.GetTerm(const aId: integer): TMaybe<ITerm>;
var
  term: ITerm;
begin
  if fIndex.TryGetValue(aId, term) then
    Result.SetSome(term)
  else
    Result.SetNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TTermRegistry.Create(const aRepository: ITermRepository);
begin
  fIndex := TDictionary<integer, ITerm>.Create;

  for var term in aRepository.GetAll do
    fIndex.Add(term.Id, term);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TTermRegistry.Destroy;
begin
  fIndex.Clear;
  fIndex.Free;

  inherited;
end;

{ TVocabRegistrar }

{----------------------------------------------------------------------------------------------------------------------}
function TVocabRegistrar.ResolveTerm(const aWord: string): TMaybe<ITerm>;
begin
  var getId := fWords.GetTermId(aWord);

  if getId.IsNone then exit(Result.None);

  var getTerm := fTerms.GetTerm(getId.Value);

  if getTerm.IsSome then
    Result.SetSome(getTerm.Value)
  else
    Result.SetNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TVocabRegistrar.Create(const aWords: IWordRegistry; const aTerms: ITermRegistry);
begin
  fWords := aWords;
  fTerms := aTerms;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TVocabRegistrar.Destroy;
begin
  fWords := nil;
  fTerms := nil;

  inherited;
end;

end.
