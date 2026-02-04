unit Mocks.Entities;

interface

uses
  System.Generics.Collections,
  Base.Core;

type
  TCustomer = record
    Id: integer;
    Name: string;
    Department: string;
    Salary: integer;

    class function Create(aId: integer; const aName: string; aDepartment: string; aSalary: integer): TCustomer; static;
  end;

  TCustomerList = TList<TCustomer>;

 TSale = record
    Id: integer;
    Product: string;
    Section: string;
    Price: integer;

    class function Create(aId: integer; const aProduct: string; aSection: string; aPrice: integer): TSale; static;
  end;

  TSalesList = TList<TSale>;

  TSaleSectionTotal = record
    Name:  string;
    Total: integer;
  end;

implementation

{ TCustomer }

{----------------------------------------------------------------------------------------------------------------------}
class function TCustomer.Create(aId: integer; const aName: string; aDepartment: string; aSalary: integer): TCustomer;
begin
  Result.Id := aId;
  Result.Name := aName;
  Result.Department := aDepartment;
  Result.Salary := aSalary;
end;

{ TSale }

{----------------------------------------------------------------------------------------------------------------------}
class function TSale.Create(aId: integer; const aProduct: string; aSection: string; aPrice: integer): TSale;
begin
  Result.Id := aId;
  Result.Product := aProduct;
  Result.Section := aSection;
  Result.Price := aPrice;
end;

end.
