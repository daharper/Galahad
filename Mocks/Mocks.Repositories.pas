unit Mocks.Repositories;

interface

uses
  System.Generics.Collections,
  Base.Core,
  Base.Stream,
  Mocks.Entities;

type
  ICustomerRepository = interface
    ['{D2DE82D3-90F7-42FB-B68F-C8CCFECB0B77}']

    function Id: integer;
    function Count: integer;
    function AsStream: Stream.TPipe<TCustomer>;
    function GetEnumerator: TEnumerator<TCustomer>;
  end;

  ISaleRepository = interface
    ['{578673C0-EF27-461D-8847-2B3A6148ED41}']

    function Id: integer;
    function Count: integer;
    function AsStream: Stream.TPipe<TSale>;
    function GetEnumerator: TEnumerator<TSale>;
  end;

  ICarSaleRepository = interface
    ['{039DC5CE-7FEB-4C49-949D-33545A32C3C7}']

    function Id: integer;
    function Count: integer;
    function AsStream: Stream.TPipe<TSale>;
    function GetEnumerator: TEnumerator<TSale>;
  end;

  TCustomerRepository = class(TInterfacedObject, ICustomerRepository)
  private
    fCustomers: TCustomerList;

    class var
      fId: integer;

  public
    function Id: integer;
    function Count: integer;
    function AsStream: Stream.TPipe<TCustomer>;
    function GetEnumerator: TEnumerator<TCustomer>;
    function ToList: TCustomerList;

    constructor Create;
    destructor Destroy; override;
  end;

  TSaleRepository = class(TInterfacedObject, ISaleRepository)
  private
    fSales: TSalesList;

    class var
      fId: integer;

  public
    function Id: integer;
    function Count: integer;
    function AsStream: Stream.TPipe<TSale>;
    function GetEnumerator: TEnumerator<TSale>;
    function ToList: TSalesList;

    constructor Create;
    destructor Destroy; override;
  end;

  TCarSaleRepository = class(TInterfacedObject, ICarSaleRepository)
  private
    fSales: TSalesList;

    class var
      fId: integer;

  public
    function Id: integer;
    function Count: integer;
    function AsStream: Stream.TPipe<TSale>;
    function GetEnumerator: TEnumerator<TSale>;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils;

{ TCustomerRepository }

{----------------------------------------------------------------------------------------------------------------------}
function TCustomerRepository.Count: integer;
begin
  Result := fCustomers.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TCustomerRepository.Create;
begin
  Inc(fId);

  fCustomers := TCustomerList.Create;

  fCustomers.Add(TCustomer.Create(1, 'Aidan',   'IT',         75000));
  fCustomers.Add(TCustomer.Create(2, 'Chris',   'IT',         65000));
  fCustomers.Add(TCustomer.Create(3, 'Slim',    'IT',         70000));
  fCustomers.Add(TCustomer.Create(4, 'Alan',    'IT',         70000));
  fCustomers.Add(TCustomer.Create(5, 'Roger',   'IT',         65000));
  fCustomers.Add(TCustomer.Create(6, 'Paul',    'Management', 85000));
  fCustomers.Add(TCustomer.Create(7, 'Una',     'HR',         75000));
  fCustomers.Add(TCustomer.Create(8, 'Osin',    'Testing',    35000));
  fCustomers.Add(TCustomer.Create(9, 'Eduardo', 'Testing',    40000));
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TCustomerRepository.Destroy;
begin
  fCustomers.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCustomerRepository.GetEnumerator:TEnumerator<TCustomer>;
begin
  Result := fCustomers.GetEnumerator;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCustomerRepository.AsStream: Stream.TPipe<TCustomer>;
begin
  Result := Stream.From<TCustomer>(fCustomers);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCustomerRepository.ToList: TCustomerList;
begin
  Result := fCustomers;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCustomerRepository.Id: integer;
begin
  Result := fId;
end;

{ TCustomerRepository }

{----------------------------------------------------------------------------------------------------------------------}
function TSaleRepository.Count: integer;
begin
  Result := fSales.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSaleRepository.Create;
begin
  Inc(fId);

  fSales := TSalesList.Create;

  fSales.Add(TSale.Create(1, 'Milk',    'Dairy',   70000));
  fSales.Add(TSale.Create(2, 'Cheese',  'Dairy',   65000));
  fSales.Add(TSale.Create(3, 'Yogurt',  'Dairy',   70000));
  fSales.Add(TSale.Create(4, 'Bread',   'Grains',  70000));
  fSales.Add(TSale.Create(5, 'Pasta',   'Grains',  65000));
  fSales.Add(TSale.Create(6, 'Rice',    'Grains',  85000));
  fSales.Add(TSale.Create(7, 'Water',   'Drinks',  75000));
  fSales.Add(TSale.Create(8, 'Coffee',  'Drinks',  35000));
  fSales.Add(TSale.Create(9, 'Guiness', 'Alcohol', 40000));
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TSaleRepository.Destroy;
begin
  fSales.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSaleRepository.GetEnumerator:TEnumerator<TSale>;
begin
  Result := fSales.GetEnumerator;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSaleRepository.AsStream: Stream.TPipe<TSale>;
begin
  Result := Stream.From<TSale>(fSales);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSaleRepository.ToList: TSalesList;
begin
  Result := fSales;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSaleRepository.Id: integer;
begin
  Result := fId;
end;

{ TCarSaleRepository }

{----------------------------------------------------------------------------------------------------------------------}
function TCarSaleRepository.Count: integer;
begin
  Result := fSales.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TCarSaleRepository.Create;
begin
  Inc(fId);

  fSales := TSalesList.Create;

  fSales.Add(TSale.Create(1, 'Peugeot', '      Sports',  70000));
  fSales.Add(TSale.Create(2, 'Chevrolet',     'Sports',  65000));
  fSales.Add(TSale.Create(3, 'Porche',        'Sports',  70000));
  fSales.Add(TSale.Create(4, 'Ferrari',       'Sports',  70000));
  fSales.Add(TSale.Create(8, 'Lamborghini',   'Sports',  35000));
  fSales.Add(TSale.Create(9, 'McLaren',       'Sports',  40000));
  fSales.Add(TSale.Create(5, 'Toyota RAV4',   'Family',  65000));
  fSales.Add(TSale.Create(6, 'Skoda Octavia', 'Family',  85000));
  fSales.Add(TSale.Create(7, 'Hyundai Tucson', 'Family', 75000));
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TCarSaleRepository.Destroy;
begin
  fSales.Free;

  inherited;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCarSaleRepository.GetEnumerator:TEnumerator<TSale>;
begin
  Result := fSales.GetEnumerator;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCarSaleRepository.AsStream: Stream.TPipe<TSale>;
begin
  Result := Stream.From<TSale>(fSales);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TCarSaleRepository.Id: integer;
begin
  Result := fId;
end;

end.
