unit Application.Language;

interface

uses
  System.Generics.Collections,
  Base.Core,
  Base.Data,
  Base.Integrity,
  Domain.Terms;

type
  IRewriteRule = interface(IEntity)
    ['{A331665B-B226-4BBD-A4D4-8681286BD087}']
    function GetPattern: string;
    function GetReplacement: string;
    function GetPriority: integer;

    procedure SetPattern(const aValue: string);
    procedure SetReplacement(const aValue: string);
    procedure SetPriority(const aValue: integer);

    property Pattern: string read GetPattern write SetPattern;
    property Replacement: string read GetReplacement write SetReplacement;
    property Priority: integer read GetPriority write SetPriority;
  end;

  TRewriteRule = class(TEntity, IRewriteRule)
  private
    fPattern: string;
    fReplacement: string;
    fPriority: integer;

    procedure SetPattern(const aValue: string);
    procedure SetReplacement(const aValue: string);
    procedure SetPriority(const aValue: integer);

    function GetPattern: string;
    function GetReplacement: string;
    function GetPriority: integer;
  public
    property Pattern: string read GetPattern write SetPattern;
    property Replacement: string read GetReplacement write SetReplacement;
    property Priority: integer read GetPriority write SetPriority;
  end;

  IRewriteRepository = interface(IRepository<IRewriteRule, TRewriteRule>)
    ['{87124496-DFCD-49C5-ACE3-A3ABE32290A9}']
    function GetPriorizedRules: TArray<IRewriteRule>;
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

  TWords = TList<IWord>;

  IWordRepository = interface(IRepository<IWord, TWord>)
    ['{544E53F9-D880-40F5-A44A-0C69461710BD}']
  end;

  IWordRegistry = interface
    ['{6CECBCF0-65D1-48CD-9CEF-8669E2A9D1FF}']
    function GetTermId(const aWord: string): TOption<integer>;
    function GetWord(const aText: string): TOption<IWord>;
  end;

  TWordRegistry = class(TSingleton, IWordRegistry)
  private
    fIndex: TDictionary<string, IWord>;
  public
    function GetTermId(const aWord: string): TOption<integer>;
    function GetWord(const aText: string): TOption<IWord>;

    constructor Create(const aRepository:IWordRepository);
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
  fIndex := TDictionary<string, IWord>.Create(TIStringComparer.Ordinal);

  for var word in aRepository.GetAll do
    fIndex.Add(word.Value, word);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TWordRegistry.Destroy;
begin
  fIndex.Clear;
  fIndex.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TWordRegistry.GetTermId(const aWord: string): TOption<integer>;
var
  word: IWord;
begin
  if fIndex.TryGetValue(aWord, word) then
    Result.SetSome(word.TermId)
  else
    Result.SetNone;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TWordRegistry.GetWord(const aText: string): TOption<IWord>;
var
  word: IWord;
begin
  if fIndex.TryGetValue(aText, word) then
    Result.SetSome(word)
  else
    Result.SetNone;
end;

{ TRewriteRule }

{----------------------------------------------------------------------------------------------------------------------}
function TRewriteRule.GetPattern: string;
begin
  Result := fPattern;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRewriteRule.GetPriority: integer;
begin
  Result := fPriority;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRewriteRule.GetReplacement: string;
begin
  Result := fReplacement;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRewriteRule.SetPattern(const aValue: string);
begin
  fPattern := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRewriteRule.SetPriority(const aValue: integer);
begin
  fPriority := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TRewriteRule.SetReplacement(const aValue: string);
begin
  fReplacement := aValue;
end;

end.
