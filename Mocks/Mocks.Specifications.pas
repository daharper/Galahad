unit Mocks.Specifications;

interface

uses
  Base.Specifications,
  Mocks.Entities,
  Mocks.Repositories;

type
  { Specifications }

  TDepartmentIs = class(TSpecification<TCustomer>)
  private
    fDept: string;
  public
    property Department: string read fDept;

    function IsSatisfiedBy(const Candidate: TCustomer): Boolean; override;

    constructor Create(const Dept: string);
  end;

  TSalaryAbove = class(TSpecification<TCustomer>)
  private
    fThreshold: Integer;
  public
    property Threshold: integer read fThreshold;

    function IsSatisfiedBy(const Candidate: TCustomer): Boolean; override;

    constructor Create(Threshold: Integer);
  end;

  TSaleSectionIs = class(TSpecification<TSale>)
  private
    fSection: string;
  public
    property Section: string read fSection;

    function IsSatisfiedBy(const Candidate: TSale): Boolean; override;

    constructor Create(const Section: string);
  end;

  { Sql Adapters }

  TDepartmentIsSqlAdapter = class(TInterfacedObject, ISpecSqlAdapter<TCustomer>)
  public
    function TryBuildWhere(
      const aSpec: ISpecification<TCustomer>;
      const aCtx: ISqlBuildContext;
      out aSql: string
    ): Boolean;
  end;

  TSalaryAboveSqlAdapter = class(TInterfacedObject, ISpecSqlAdapter<TCustomer>)
  public
    function TryBuildWhere(
      const aSpec: ISpecification<TCustomer>;
      const aCtx: ISqlBuildContext;
      out aSql: string
    ): Boolean;
  end;

  TSaleSectionIsSqlAdapter = class(TInterfacedObject, ISpecSqlAdapter<TSale>)
  public
    function TryBuildWhere(
      const aSpec: ISpecification<TSale>;
      const aCtx: ISqlBuildContext;
      out aSql: string
    ): Boolean;
  end;

  TDecliningCustomerAdapter = class(TInterfacedObject, ISpecSqlAdapter<TCustomer>)
  public
    function TryBuildWhere(
      const aSpec: ISpecification<TCustomer>;
      const aCtx: ISqlBuildContext;
      out aSql: string
    ): Boolean;
  end;

implementation

{----------------------------------------------------------------------------------------------------------------------}
constructor TDepartmentIs.Create(const Dept: string);
begin
  inherited Create;
  fDept := Dept;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDepartmentIs.IsSatisfiedBy(const Candidate: TCustomer): Boolean;
begin
  Result := Candidate.Department = fDept;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSalaryAbove.Create(Threshold: Integer);
begin
  inherited Create;
  fThreshold := Threshold;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSalaryAbove.IsSatisfiedBy(const Candidate: TCustomer): Boolean;
begin
  Result := Candidate.Salary > fThreshold;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSaleSectionIs.Create(const Section: string);
begin
  inherited Create;
  fSection := Section;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSaleSectionIs.IsSatisfiedBy(const Candidate: TSale): Boolean;
begin
  Result := Candidate.Section = fSection;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDepartmentIsSqlAdapter.TryBuildWhere(
  const aSpec: ISpecification<TCustomer>;
  const aCtx: ISqlBuildContext;
  out aSql: string
): Boolean;
var
  deptSpec: TDepartmentIs;
  p: string;
begin
  aSql := '';
  Result := False;

  if not (aSpec is TDepartmentIs) then
    Exit;

  deptSpec := TDepartmentIs(aSpec);

  p := aCtx.AddParam(deptSpec.Department);

  aSql := aCtx.Column('Department') + ' = ' + p;
  Result := True;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSalaryAboveSqlAdapter.TryBuildWhere(
  const aSpec: ISpecification<TCustomer>;
  const aCtx: ISqlBuildContext;
  out aSql: string
): Boolean;
var
  salarySpec: TSalaryAbove;
  col: string;
  p: string;
begin
  aSql := '';
  Result := False;

  if not (aSpec is TSalaryAbove) then
    Exit;

  salarySpec := TSalaryAbove(aSpec);

  if aCtx.Alias <> '' then
    col := aCtx.Alias + '.Salary'
  else
    col := 'Salary';

  p := aCtx.AddParam(salarySpec.Threshold);
  aSql := col + ' > ' + p;
  Result := True;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSaleSectionIsSqlAdapter.TryBuildWhere(
  const aSpec: ISpecification<TSale>;
  const aCtx: ISqlBuildContext;
  out aSql: string
): Boolean;
var
  secSpec: TSaleSectionIs;
  col: string;
  p: string;
begin
  aSql := '';
  Result := False;

  if not (aSpec is TSaleSectionIs) then
    Exit;

  secSpec := TSaleSectionIs(aSpec);

  if aCtx.Alias <> '' then
    col := aCtx.Alias + '.Section'
  else
    col := 'Section';

  p := aCtx.AddParam(secSpec.Section);
  aSql := col + ' = ' + p;
  Result := True;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TDecliningCustomerAdapter.TryBuildWhere(
  const aSpec: ISpecification<TCustomer>;
  const aCtx: ISqlBuildContext;
  out aSql: string
): Boolean;
begin
  aSql := '';
  Result := False;
end;

end.
