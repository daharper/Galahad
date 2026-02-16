unit Application.Language;

interface

uses
  System.Generics.Collections,
  Base.Core,
  Base.Data,
  Base.Integrity,
  Domain.Terms;

type

  IWord = interface(IEntity)
    ['{BEA756F2-0334-447F-AC31-7B088C7C6FD1}']
    function GetValue: string;
    function GetTermId: integer;

    procedure SetValue(const aValue: string);
    procedure SetTermId(const aValue: integer);

    property Value: string read GetValue write SetValue;
    property TermId: integer read GetTermId write SetTermId;
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

  IWordRepository = IRepository<IWord, TWord>;

  IWordRegistry = interface
    ['{6CECBCF0-65D1-48CD-9CEF-8669E2A9D1FF}']
    function GetTermId(const aWord: string): TMaybe<integer>;
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
