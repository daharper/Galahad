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
  TSpecificationFixture = class
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
    [Test] procedure DepartmentIs_Builds_Where_Clause;
    [Test] procedure DepartmentAndSalary_Builds_Composed_Where_Clause;
    [Test] procedure SaleSectionOr_Builds_Composed_Where_Clause;
    [Test] procedure SaleSectionNot_Builds_Where_Clause;
    [Test] procedure SaleSection_Or_NotSection_Builds_Composed_Where_Clause;
    [Test] procedure Customer_And_Or_Not_Builds_Composed_Where_Clause;
    [Test] procedure Customer_DoubleNot_Builds_Where_Clause;
    [Test] procedure Sale_BalancedTree_Builds_Composed_Where_Clause;
    [Test] procedure Sale_ReusedLeafInstance_Produces_Two_Params;
    [Test] procedure MissingAdapter_Raises_NotTranslatable;
    [Test] procedure AdapterDeclines_Raises_NotTranslatable;
    [Test] procedure EmptyAlias_Produces_Unqualified_Column;
    [Test] procedure ExplicitGrouping_And_With_Inner_Or;
  end;

implementation

uses
  Base.Stream;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.ExplicitGrouping_And_With_Inner_Or;
var
  builder: TSpecSqlBuilder<TCustomer>;
  spec: ISpecification<TCustomer>;
  where: TSqlWhere;
begin
  builder := TSpecSqlBuilder<TCustomer>.Create('c');
  try
    builder.RegisterAdapter(TDepartmentIs, TDepartmentIsSqlAdapter.Create);
    builder.RegisterAdapter(TSalaryAbove, TSalaryAboveSqlAdapter.Create);

    // (Department = 'IT') AND (Salary > 50000 OR Salary > 80000)
    spec :=
      TDepartmentIs.Create('IT')
        .AndAlso(
          TSalaryAbove.Create(50000)
            .OrElse(TSalaryAbove.Create(80000))
        );

    where := builder.BuildWhere(spec);

    Assert.AreEqual(
      '(c.Department = :p0 AND (c.Salary > :p1 OR c.Salary > :p2))',
      where.Sql
    );

    Assert.AreEqual(3, Length(where.Params));

    Assert.AreEqual(':p0', where.Params[0].Name);
    Assert.AreEqual('IT', string(where.Params[0].Value));

    Assert.AreEqual(':p1', where.Params[1].Name);
    Assert.AreEqual<Integer>(50000, where.Params[1].Value);

    Assert.AreEqual(':p2', where.Params[2].Name);
    Assert.AreEqual<Integer>(80000, where.Params[2].Value);
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.EmptyAlias_Produces_Unqualified_Column;
var
  builder: TSpecSqlBuilder<TCustomer>;
  spec: ISpecification<TCustomer>;
  where: TSqlWhere;
begin
  builder := TSpecSqlBuilder<TCustomer>.Create('');
  try
    builder.RegisterAdapter(TDepartmentIs, TDepartmentIsSqlAdapter.Create);

    spec := TDepartmentIs.Create('IT');

    where := builder.BuildWhere(spec);

    Assert.AreEqual('Department = :p0', where.Sql);
    Assert.AreEqual(1, Length(where.Params));
    Assert.AreEqual('IT', string(where.Params[0].Value));
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.AdapterDeclines_Raises_NotTranslatable;
var
  builder: TSpecSqlBuilder<TCustomer>;
  spec: ISpecification<TCustomer>;
begin
  builder := TSpecSqlBuilder<TCustomer>.Create('c');
  try
    builder.RegisterAdapter(TDepartmentIs, TDecliningCustomerAdapter.Create);

    spec := TDepartmentIs.Create('IT');

    Assert.WillRaise(
      procedure
      begin
        builder.BuildWhere(spec);
      end,
      ESpecNotTranslatable
    );
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.MissingAdapter_Raises_NotTranslatable;
var
  builder: TSpecSqlBuilder<TCustomer>;
  spec: ISpecification<TCustomer>;
begin
  builder := TSpecSqlBuilder<TCustomer>.Create('c');
  try
    spec := TDepartmentIs.Create('IT');

    Assert.WillRaise(
      procedure
      begin
        builder.BuildWhere(spec);
      end,
      ESpecNotTranslatable
    );
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.Sale_ReusedLeafInstance_Produces_Two_Params;
var
  builder: TSpecSqlBuilder<TSale>;
  leaf: ISpecification<TSale>;
  spec: ISpecification<TSale>;
  where: TSqlWhere;
begin
  builder := TSpecSqlBuilder<TSale>.Create('s');
  try
    builder.RegisterAdapter(TSaleSectionIs, TSaleSectionIsSqlAdapter.Create);

    leaf := TSaleSectionIs.Create('Dairy');
    spec := leaf.OrElse(leaf); // reuse the same instance

    where := builder.BuildWhere(spec);

    Assert.AreEqual('(s.Section = :p0 OR s.Section = :p1)', where.Sql);
    Assert.AreEqual(2, Length(where.Params));

    Assert.AreEqual(':p0', where.Params[0].Name);
    Assert.AreEqual('Dairy', string(where.Params[0].Value));

    Assert.AreEqual(':p1', where.Params[1].Name);
    Assert.AreEqual('Dairy', string(where.Params[1].Value));
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.Sale_BalancedTree_Builds_Composed_Where_Clause;
var
  builder: TSpecSqlBuilder<TSale>;
  spec: ISpecification<TSale>;
  where: TSqlWhere;
begin
  builder := TSpecSqlBuilder<TSale>.Create('s');
  try
    builder.RegisterAdapter(TSaleSectionIs, TSaleSectionIsSqlAdapter.Create);

    spec :=
      TSaleSectionIs.Create('Dairy')
        .OrElse(TSaleSectionIs.Create('Alcohol'))
        .AndAlso(
          TSaleSectionIs.Create('Meat').NotThis
            .OrElse(TSaleSectionIs.Create('Bakery'))
        );

    where := builder.BuildWhere(spec);

    Assert.AreEqual(
      '((s.Section = :p0 OR s.Section = :p1) AND ((NOT s.Section = :p2) OR s.Section = :p3))',
      where.Sql
    );

    Assert.AreEqual(4, Length(where.Params));

    Assert.AreEqual(':p0', where.Params[0].Name);
    Assert.AreEqual('Dairy', string(where.Params[0].Value));

    Assert.AreEqual(':p1', where.Params[1].Name);
    Assert.AreEqual('Alcohol', string(where.Params[1].Value));

    Assert.AreEqual(':p2', where.Params[2].Name);
    Assert.AreEqual('Meat', string(where.Params[2].Value));

    Assert.AreEqual(':p3', where.Params[3].Name);
    Assert.AreEqual('Bakery', string(where.Params[3].Value));
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.Customer_DoubleNot_Builds_Where_Clause;
var
  builder: TSpecSqlBuilder<TCustomer>;
  spec: ISpecification<TCustomer>;
  where: TSqlWhere;
begin
  builder := TSpecSqlBuilder<TCustomer>.Create('c');
  try
    builder.RegisterAdapter(TDepartmentIs, TDepartmentIsSqlAdapter.Create);

    spec := TDepartmentIs.Create('IT').NotThis.NotThis;

    where := builder.BuildWhere(spec);

    Assert.AreEqual('(NOT (NOT c.Department = :p0))', where.Sql);
    Assert.AreEqual(1, Length(where.Params));

    Assert.AreEqual(':p0', where.Params[0].Name);
    Assert.AreEqual('IT', string(where.Params[0].Value));
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.Customer_And_Or_Not_Builds_Composed_Where_Clause;
var
  builder: TSpecSqlBuilder<TCustomer>;
  spec: ISpecification<TCustomer>;
  where: TSqlWhere;
begin
  builder := TSpecSqlBuilder<TCustomer>.Create('c');
  try
    builder.RegisterAdapter(TDepartmentIs, TDepartmentIsSqlAdapter.Create);
    builder.RegisterAdapter(TSalaryAbove, TSalaryAboveSqlAdapter.Create);

    spec :=
      TDepartmentIs.Create('IT')
        .AndAlso(TSalaryAbove.Create(68000))
        .OrElse(TDepartmentIs.Create('HR').NotThis);

    where := builder.BuildWhere(spec);

    Assert.AreEqual('((c.Department = :p0 AND c.Salary > :p1) OR (NOT c.Department = :p2))', where.Sql);
    Assert.AreEqual(3, Length(where.Params));

    Assert.AreEqual(':p0', where.Params[0].Name);
    Assert.AreEqual('IT', string(where.Params[0].Value));

    Assert.AreEqual(':p1', where.Params[1].Name);
    Assert.AreEqual<Integer>(68000, where.Params[1].Value);

    Assert.AreEqual(':p2', where.Params[2].Name);
    Assert.AreEqual('HR', string(where.Params[2].Value));
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.SaleSection_Or_NotSection_Builds_Composed_Where_Clause;
var
  builder: TSpecSqlBuilder<TSale>;
  spec: ISpecification<TSale>;
  where: TSqlWhere;
begin
  builder := TSpecSqlBuilder<TSale>.Create('s');
  try
    builder.RegisterAdapter(TSaleSectionIs, TSaleSectionIsSqlAdapter.Create);

    spec :=
      TSaleSectionIs.Create('Dairy')
        .OrElse(TSaleSectionIs.Create('Alcohol').NotThis);

    where := builder.BuildWhere(spec);

    Assert.AreEqual('(s.Section = :p0 OR (NOT s.Section = :p1))', where.Sql);
    Assert.AreEqual(2, Length(where.Params));

    Assert.AreEqual(':p0', where.Params[0].Name);
    Assert.AreEqual('Dairy', string(where.Params[0].Value));

    Assert.AreEqual(':p1', where.Params[1].Name);
    Assert.AreEqual('Alcohol', string(where.Params[1].Value));
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.SaleSectionNot_Builds_Where_Clause;
var
  builder: TSpecSqlBuilder<TSale>;
  spec: ISpecification<TSale>;
  where: TSqlWhere;
begin
  builder := TSpecSqlBuilder<TSale>.Create('s');
  try
    builder.RegisterAdapter(TSaleSectionIs, TSaleSectionIsSqlAdapter.Create);

    spec := TSaleSectionIs.Create('Dairy').NotThis;

    where := builder.BuildWhere(spec);

    Assert.AreEqual('(NOT s.Section = :p0)', where.Sql);
    Assert.AreEqual(1, Length(where.Params));

    Assert.AreEqual(':p0', where.Params[0].Name);
    Assert.AreEqual('Dairy', string(where.Params[0].Value));
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.SaleSectionOr_Builds_Composed_Where_Clause;
var
  builder: TSpecSqlBuilder<TSale>;
  spec: ISpecification<TSale>;
  where: TSqlWhere;
begin
  builder := TSpecSqlBuilder<TSale>.Create('s');
  try
    builder.RegisterAdapter(TSaleSectionIs, TSaleSectionIsSqlAdapter.Create);

    spec := TSaleSectionIs.Create('Dairy')
              .OrElse(TSaleSectionIs.Create('Alcohol'));

    where := builder.BuildWhere(spec);

    Assert.AreEqual('(s.Section = :p0 OR s.Section = :p1)', where.Sql);
    Assert.AreEqual(2, Length(where.Params));

    Assert.AreEqual(':p0', where.Params[0].Name);
    Assert.AreEqual('Dairy', string(where.Params[0].Value));

    Assert.AreEqual(':p1', where.Params[1].Name);
    Assert.AreEqual('Alcohol', string(where.Params[1].Value));
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.DepartmentAndSalary_Builds_Composed_Where_Clause;
var
  builder: TSpecSqlBuilder<TCustomer>;
  spec: ISpecification<TCustomer>;
  where: TSqlWhere;
begin
  builder := TSpecSqlBuilder<TCustomer>.Create('c');
  try
    builder.RegisterAdapter(TDepartmentIs, TDepartmentIsSqlAdapter.Create);
    builder.RegisterAdapter(TSalaryAbove, TSalaryAboveSqlAdapter.Create);

    spec := TDepartmentIs.Create('IT')
              .AndAlso(TSalaryAbove.Create(68000));

    where := builder.BuildWhere(spec);

    Assert.AreEqual('(c.Department = :p0 AND c.Salary > :p1)', where.Sql);
    Assert.AreEqual(2, Length(where.Params));

    Assert.AreEqual(':p0', where.Params[0].Name);
    Assert.AreEqual('IT', string(where.Params[0].Value));

    Assert.AreEqual(':p1', where.Params[1].Name);
    Assert.AreEqual(68000, Integer(where.Params[1].Value));
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.DepartmentIs_Builds_Where_Clause;
var
  builder: TSpecSqlBuilder<TCustomer>;
  spec: ISpecification<TCustomer>;
  where: TSqlWhere;
begin
  builder := TSpecSqlBuilder<TCustomer>.Create('c');
  try
    builder.RegisterAdapter(TDepartmentIs, TDepartmentIsSqlAdapter.Create);

    spec := TDepartmentIs.Create('IT');

    where := builder.BuildWhere(spec);

    Assert.AreEqual('c.Department = :p0', where.Sql);
    Assert.AreEqual(1, Length(where.Params));
    Assert.AreEqual(':p0', where.Params[0].Name);
    Assert.AreEqual('IT', string(where.Params[0].Value));
  finally
    builder.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.Filtering_In_Stream;
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
procedure TSpecificationFixture.ITCustomerWithHighSalary_ReturnsMatches;
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
procedure TSpecificationFixture.DairyOrAlcoholSales_ContainsExpectedProducts;
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
procedure TSpecificationFixture.NotITCustomer_ReturnsNonIT;
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
procedure TSpecificationFixture.PredicateSpecification_Works;
begin
  var spec := TSpecification<TCustomer>.FromPredicate(
    function(const x: TCustomer): Boolean
    begin
      Result := x.Salary > 70000;
    end);

  for var c in fCustomers do
    if c.Name = 'Aidan' then
      Assert.IsTrue(spec.IsSatisfiedBy(c));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.Setup;
begin
  fCustomers := TCustomerRepository.Create;
  fSales := TSaleRepository.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSpecificationFixture.TearDown;
begin
  fCustomers.Free;
  fSales.Free;
end;

initialization
  TDUnitX.RegisterTestFixture(TSpecificationFixture);

end.
