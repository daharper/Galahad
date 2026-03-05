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

    property Pattern: string read GetPattern;
    property Replacement: string read GetReplacement;
    property Priority: integer read GetPriority;
  end;

  TRewriteRule = class(TEntity, IRewriteRule)
  private
    fPattern: string;
    fReplacement: string;
    fPriority: integer;

    function GetPattern: string;
    function GetReplacement: string;
    function GetPriority: integer;
  public
    property Pattern: string read GetPattern;
    property Replacement: string read GetReplacement;
    property Priority: integer read GetPriority;
  end;

  IRewriteRepository = IRepository<IRewriteRule, TRewriteRule>;

  IRewriteManager = interface
    ['{8D503B87-0CD4-4972-9753-669A3E4A60AC}']
  end;

  TRewriteManager = class(TSingleton, IRewriteManager)
  private
    fRules: TList<IRewriteRule>;
  public
    constructor Create(const aRepository: IRewriteRepository);
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

  IWordRepository = IRepository<IWord, TWord>;

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

{ TRewriteManager }

{----------------------------------------------------------------------------------------------------------------------}
constructor TRewriteManager.Create(const aRepository: IRewriteRepository);
begin

end;

end.
