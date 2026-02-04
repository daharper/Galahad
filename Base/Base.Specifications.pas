unit Base.Specifications;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Base.Core,
  Base.Integrity;

type
  ISpecification<T> = interface
    ['{E516E6C7-2E3A-4F16-94DE-F041C3E125B9}']
    function IsSatisfiedBy(const Candidate: T): Boolean;

    function AndAlso(const aOther: ISpecification<T>): ISpecification<T>;
    function OrElse(const aOther: ISpecification<T>): ISpecification<T>;
    function NotThis: ISpecification<T>;
  end;

  IAndSpecification<T> = interface(ISpecification<T>)
    ['{9F734B3F-1F3C-4A1B-9D91-6A2D2F2A2B6B}']
    function Left: ISpecification<T>;
    function Right: ISpecification<T>;
  end;

  IOrSpecification<T> = interface(ISpecification<T>)
    ['{4E1A1C6F-1C06-4DF0-9C0D-7E56E0BE9F7B}']
    function Left: ISpecification<T>;
    function Right: ISpecification<T>;
  end;

  INotSpecification<T> = interface(ISpecification<T>)
    ['{B5B1D1F0-8E88-4E76-A0AA-7A6A9A1B3C2C}']
    function Inner: ISpecification<T>;
  end;

  /// <remarks>
  /// Specification composition is explicit. Grouping is defined by nesting
  /// (AndAlso / OrElse calls), not by operator precedence. It's just like function calls.
  /// </remarks>
  TSpecification<T> = class(TInterfacedObject, ISpecification<T>)
  public
    function IsSatisfiedBy(const aCandidate: T): Boolean; virtual; abstract;

    function AndAlso(const aOther: ISpecification<T>): ISpecification<T>;
    function OrElse(const aOther: ISpecification<T>): ISpecification<T>;
    function NotThis: ISpecification<T>;

    class function FromPredicate(const aPredicate: TConstPredicate<T>): ISpecification<T>; static;
  end;

  TAndSpecification<T> = class(TSpecification<T>, IAndSpecification<T>)
  private
    fLeft, fRight: ISpecification<T>;
  public
    constructor Create(const aLeft, aRight: ISpecification<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;

    function Left: ISpecification<T>;
    function Right: ISpecification<T>;
  end;

  TOrSpecification<T> = class(TSpecification<T>, IOrSpecification<T>)
  private
    fLeft, fRight: ISpecification<T>;
  public
    constructor Create(const aLeft, aRight: ISpecification<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;

    function Left: ISpecification<T>;
    function Right: ISpecification<T>;
  end;

  TNotSpecification<T> = class(TSpecification<T>, INotSpecification<T>)
  private
    fInner: ISpecification<T>;
  public
    constructor Create(const aInner: ISpecification<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;

    function Inner: ISpecification<T>;
  end;

  TPredicateSpecification<T> = class(TSpecification<T>)
  private
    FPredicate: TConstPredicate<T>;
  public
    constructor Create(const aPredicate: TConstPredicate<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;
  end;

  TSqlParam = record
    Name: string;
    Value: Variant;
  end;

  TSqlWhere = record
    Sql: string;
    Params: TArray<TSqlParam>;
  end;

  ISqlBuildContext = interface
    ['{F6D0C2A6-7C4B-4F83-A8B0-3B33F2A8B7C1}']
    function AddParam(const aValue: Variant): string;
    function Alias: string;
  end;

  ISpecSqlAdapter<T> = interface
    ['{2C3A9D5D-1D0B-4A4E-B5EA-7E0B4B5A2B3A}']
    function TryBuildWhere(const aSpec: ISpecification<T>; const aCtx: ISqlBuildContext; out aSql: string): Boolean;
  end;

  ESpecNotTranslatable = class(Exception);

  TSqlBuildContext = class(TInterfacedObject, ISqlBuildContext)
  private
    fAlias: string;
    fNext: Integer;
    fParams: TList<TSqlParam>;
  public
    constructor Create(const aAlias: string);
    destructor Destroy; override;

    function AddParam(const aValue: Variant): string;
    function Alias: string;

    function DetachParams: TArray<TSqlParam>;
  end;

  TSpecSqlBuilder<T> = class
  private
    fAdapters: TDictionary<TClass, ISpecSqlAdapter<T>>;
    fAlias: string;

    function BuildInternal(const aSpec: ISpecification<T>; const aCtx: TSqlBuildContext): string;
    function TryFindAdapter(const aSpec: ISpecification<T>; out aAdapter: ISpecSqlAdapter<T>): Boolean;
  public
    constructor Create(const aAlias: string = '');
    destructor Destroy; override;

    procedure RegisterAdapter(const aSpecClass: TClass; const aAdapter: ISpecSqlAdapter<T>);

    function BuildWhere(const aSpec: ISpecification<T>): TSqlWhere;
  end;

implementation

{ TSpecification<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TSpecification<T>.AndAlso(const aOther: ISpecification<T>): ISpecification<T>;
begin
  Ensure.IsAssigned(aOther, 'Other specification is nil');
  Result := TAndSpecification<T>.Create(ISpecification<T>(Self), aOther);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSpecification<T>.OrElse(const aOther: ISpecification<T>): ISpecification<T>;
begin
  Ensure.IsAssigned(aOther, 'Other specification is nil');
  Result := TOrSpecification<T>.Create(ISpecification<T>(Self), aOther);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSpecification<T>.NotThis: ISpecification<T>;
begin
  Result := TNotSpecification<T>.Create(ISpecification<T>(Self));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TSpecification<T>.FromPredicate(const aPredicate: TConstPredicate<T>): ISpecification<T>;
begin
  Ensure.IsAssigned(@aPredicate, 'Predicate is nil');

  Result := TPredicateSpecification<T>.Create(APredicate);
end;

{ TAndSpecification<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TAndSpecification<T>.Create(const aLeft, aRight: ISpecification<T>);
begin
  inherited Create;

  Ensure.IsAssigned(aLeft,  'Left specification is nil')
        .IsAssigned(aRight, 'Right specification is nil');

  fLeft  := aLeft;
  fRight := aRight;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TAndSpecification<T>.Left: ISpecification<T>;
begin
  Result := fLeft;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TAndSpecification<T>.Right: ISpecification<T>;
begin
  Result := fRight;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TAndSpecification<T>.IsSatisfiedBy(const aCandidate: T): Boolean;
begin
  Result := fLeft.IsSatisfiedBy(aCandidate) and fRight.IsSatisfiedBy(aCandidate);
end;

{ TOrSpecification<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TOrSpecification<T>.Create(const aLeft, aRight: ISpecification<T>);
begin
  inherited Create;

  Ensure.IsAssigned(aLeft, 'Left specification is nil')
        .IsAssigned(aRight, 'Right specification is nil');

  fLeft  := aLeft;
  fRight := aRight;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOrSpecification<T>.Left: ISpecification<T>;
begin
  Result := fLeft;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOrSpecification<T>.Right: ISpecification<T>;
begin
  Result := fRight;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOrSpecification<T>.IsSatisfiedBy(const aCandidate: T): Boolean;
begin
  Result := fLeft.IsSatisfiedBy(aCandidate) or fRight.IsSatisfiedBy(aCandidate);
end;

{ TNotSpecification<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TNotSpecification<T>.Create(const aInner: ISpecification<T>);
begin
  inherited Create;

  Ensure.IsAssigned(aInner, 'Inner specification is nil');

  fInner := aInner;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TNotSpecification<T>.Inner: ISpecification<T>;
begin
  Result := fInner;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TNotSpecification<T>.IsSatisfiedBy(const aCandidate: T): Boolean;
begin
  Result := not fInner.IsSatisfiedBy(aCandidate);
end;

{ TPredicateSpecification<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TPredicateSpecification<T>.Create(const aPredicate: TConstPredicate<T>);
begin
  inherited Create;

  Ensure.IsAssigned(@aPredicate, 'Predicate is nil');

  FPredicate := aPredicate;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TPredicateSpecification<T>.IsSatisfiedBy(const aCandidate: T): Boolean;
begin
  Result := FPredicate(aCandidate);
end;

{ TSqlBuildContext }

{----------------------------------------------------------------------------------------------------------------------}
constructor TSqlBuildContext.Create(const aAlias: string);
begin
  inherited Create;

  fAlias := aAlias;
  fNext := 0;
  fParams := TList<TSqlParam>.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TSqlBuildContext.Destroy;
begin
  FParams.Free;
  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqlBuildContext.Alias: string;
begin
  Result := FAlias;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqlBuildContext.AddParam(const aValue: Variant): string;
var
  p: TSqlParam;
begin
  Result := ':p' + fNext.ToString;
  Inc(fNext);

  p.Name  := Result;
  p.Value := aValue;
  fParams.Add(p);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqlBuildContext.DetachParams: TArray<TSqlParam>;
begin
  Result := fParams.ToArray;
  fParams.Clear;
end;

{ TSpecSqlBuilder<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TSpecSqlBuilder<T>.Create(const aAlias: string);
begin
  inherited Create;
  fAlias := aAlias;
  fAdapters := TDictionary<TClass, ISpecSqlAdapter<T>>.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TSpecSqlBuilder<T>.Destroy;
begin
  FAdapters.Free;
  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecSqlBuilder<T>.RegisterAdapter(const aSpecClass: TClass; const aAdapter: ISpecSqlAdapter<T>);
begin
  Ensure.IsAssigned(aSpecClass, 'SpecClass is nil')
        .IsAssigned(aAdapter, 'Adapter is nil');

  // Replace if already registered
  FAdapters.AddOrSetValue(aSpecClass, aAdapter);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSpecSqlBuilder<T>.TryFindAdapter(const aSpec: ISpecification<T>; out aAdapter: ISpecSqlAdapter<T>): Boolean;
begin
  aAdapter := nil;

  if aSpec = nil then exit(false);

  // Exact type match (simple + predictable)
  Result := FAdapters.TryGetValue((aSpec as TObject).ClassType, aAdapter);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSpecSqlBuilder<T>.BuildInternal(const aSpec: ISpecification<T>; const aCtx: TSqlBuildContext): string;
var
  andSpec: IAndSpecification<T>;
  orSpec: IOrSpecification<T>;
  notSpec: INotSpecification<T>;
  adapter: ISpecSqlAdapter<T>;
  leafSql: string;
begin
  Ensure.IsAssigned(aSpec, 'Spec is nil');

  // Composite nodes
  if Supports(aSpec, IAndSpecification<T>, andSpec) then
    Exit('(' + BuildInternal(andSpec.Left, aCtx) + ' AND ' + BuildInternal(andSpec.Right, aCtx) + ')');

  if Supports(aSpec, IOrSpecification<T>, orSpec) then
    Exit('(' + BuildInternal(orSpec.Left, aCtx) + ' OR ' + BuildInternal(orSpec.Right, aCtx) + ')');

  if Supports(aSpec, INotSpecification<T>, notSpec) then
    Exit('(NOT ' + BuildInternal(notSpec.Inner, aCtx) + ')');

  // Leaf
  if not TryFindAdapter(aSpec, adapter) then
    raise ESpecNotTranslatable.CreateFmt('No SQL adapter registered for specification %s', [(aSpec as TObject).ClassName]);

  if not adapter.TryBuildWhere(aSpec, aCtx, leafSql) then
    raise ESpecNotTranslatable.CreateFmt('Specification %s is not translatable by its adapter', [(aSpec as TObject).ClassName]);

  Result := leafSql;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSpecSqlBuilder<T>.BuildWhere(const aSpec: ISpecification<T>): TSqlWhere;
var
  ctx: TSqlBuildContext;
begin
  Ensure.IsAssigned(aSpec, 'Spec is nil');

  ctx := TSqlBuildContext.Create(FAlias);
  try
    Result.Sql := BuildInternal(aSpec, ctx);
    Result.Params := ctx.DetachParams;
  finally
    ctx.Free;
  end;
end;

end.
