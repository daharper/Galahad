unit Mocks.Specifications;

interface

uses
  Base.Specifications,
  Mocks.Entities,
  Mocks.Repositories;

type
  TDepartmentIs = class(TSpecification<TCustomer>)
  private
    fDept: string;
  public
    constructor Create(const Dept: string);
    function IsSatisfiedBy(const Candidate: TCustomer): Boolean; override;
  end;

  TSalaryAbove = class(TSpecification<TCustomer>)
  private
    fThreshold: Integer;
  public
    constructor Create(Threshold: Integer);
    function IsSatisfiedBy(const Candidate: TCustomer): Boolean; override;
  end;

  TSaleSectionIs = class(TSpecification<TSale>)
  private
    fSection: string;
  public
    constructor Create(const Section: string);
    function IsSatisfiedBy(const Candidate: TSale): Boolean; override;
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

end.
