unit Tests.Core.Specifications;

interface

uses
  DUnitX.TestFramework,
  Base.Core,
  Base.Integrity,
  Base.Specifications,
  Mocks.Entities,
  Mocks.Repositories,
  Mocks.Specifications;

type
  [TestFixture]
  TSpecificationTests = class
  private
    fCustomers: TCustomerRepository;
    fSales: TSaleRepository;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure ITCustomerWithHighSalary_ReturnsMatches;
    [Test] procedure DairyOrAlcoholSales_ContainsExpectedProducts;
    [Test] procedure NotITCustomer_ReturnsNonIT;
    [Test] procedure PredicateSpecification_Works;
    [Test] procedure Filtering_In_Stream;
  end;

implementation

uses
  Base.Stream;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.Filtering_In_Stream;
begin
  var spec := TDepartmentIs.Create('IT').AndAlso(TSalaryAbove.Create(68000));

  var names := Stream
        .From<TCustomer>(fCustomers.GetEnumerator, true)
        .Filter(spec)
        .Map<string>(function(const c: TCustomer): string begin Result := c.Name; end)
        .AsArray;

  Assert.Contains<string>(names, 'Aidan');
  Assert.Contains<string>(names, 'Slim');
  Assert.DoesNotContain<string>(names, 'Eduardo');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.ITCustomerWithHighSalary_ReturnsMatches;
var
  matches: TArray<string>;
begin
  var spec := TDepartmentIs.Create('IT').AndAlso(TSalaryAbove.Create(68000));

  for var c in fCustomers do
    if spec.IsSatisfiedBy(c) then
      matches := matches + [c.Name];

  Assert.Contains<string>(matches, 'Aidan');
  Assert.Contains<string>(matches, 'Slim');
  Assert.DoesNotContain<string>(matches, 'Eduardo');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.DairyOrAlcoholSales_ContainsExpectedProducts;
var
  spec: ISpecification<TSale>;
  s: TSale;
  matches: TArray<string>;
begin
  spec := TSaleSectionIs.Create('Dairy').OrElse(TSaleSectionIs.Create('Alcohol'));

  for s in fSales do
    if spec.IsSatisfiedBy(s) then
      matches := matches + [s.Product];

  Assert.Contains<string>(matches, 'Milk');
  Assert.Contains<string>(matches, 'Guiness');
  Assert.DoesNotContain<string>(matches, 'Pasta');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.NotITCustomer_ReturnsNonIT;
var
  spec: ISpecification<TCustomer>;
  c: TCustomer;
  matches: TArray<string>;
begin
  spec := TDepartmentIs.Create('IT').NotThis;

  for c in fCustomers do
    if spec.IsSatisfiedBy(c) then
      matches := matches + [c.Name];

  Assert.Contains<string>(matches, 'Paul');
  Assert.Contains<string>(matches, 'Una');
  Assert.DoesNotContain<string>(matches, 'Aidan');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.PredicateSpecification_Works;
begin
  var spec := TSpecification<TCustomer>.FromPredicate(
    function(const x: TCustomer): Boolean
    begin
      Result := x.Salary > 70000;
    end
  );

  for var c in fCustomers do
    if c.Name = 'Aidan' then
      Assert.IsTrue(spec.IsSatisfiedBy(c));
end;


{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.Setup;
begin
  fCustomers := TCustomerRepository.Create;
  fSales := TSaleRepository.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationTests.TearDown;
begin
  fCustomers.Free;
  fSales.Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TSpecificationTests);

end.
