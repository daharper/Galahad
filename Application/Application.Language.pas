unit Application.Language;

interface

uses
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

  ISynonym = interface(IEntity)
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

  TSynonym = class(TEntity, ISynonym)
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

  ISynonymRepository = IRepository<ISynonym, TSynonym>;

implementation

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

{ TSynonym }

{----------------------------------------------------------------------------------------------------------------------}
function TSynonym.GetTermId: integer;
begin
  Result := fTermId;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSynonym.SetTermId(const aValue: integer);
begin
  fTermId := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSynonym.GetValue: string;
begin
  Result := fValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSynonym.SetValue(const aValue: string);
begin
  fValue := aValue;
end;

end.
