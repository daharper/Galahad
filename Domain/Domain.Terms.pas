unit Domain.Terms;

interface

uses
  System.Generics.Collections,
  Base.Core,
  Base.Integrity,
  Base.Data;

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

  TTerms = TList<ITerm>;

  ITermRepository = IRepository<ITerm, TTerm>;

  ITermRegistry = interface
    ['{DCCA3483-0883-4E1F-A4AC-D1B3FAB37082}']
    function GetTerm(const aId: integer): ITerm;
  end;

  TTermRegistry = class(TInterfacedObject, ITermRegistry)
  private
    fIndex: TDictionary<integer, ITerm>;
  public
    function GetTerm(const aId: integer): ITerm;

    constructor Create(const aRepository: ITermRepository);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils,
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

{ TTermRegistry }

{----------------------------------------------------------------------------------------------------------------------}
function TTermRegistry.GetTerm(const aId: integer): ITerm;
const
  ERR = 'Unknown term id: %d';
var
  term: ITerm;
begin
  Ensure.IsTrue(fIndex.TryGetValue(aId, term), Format(ERR, [aId]));

  Result := term
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

end.
