unit Base.Specifications;

interface

uses
  System.SysUtils,
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

  TSpecification<T> = class(TInterfacedObject, ISpecification<T>)
  public
    function IsSatisfiedBy(const aCandidate: T): Boolean; virtual; abstract;

    function AndAlso(const aOther: ISpecification<T>): ISpecification<T>;
    function OrElse(const aOther: ISpecification<T>): ISpecification<T>;
    function NotThis: ISpecification<T>;

    class function FromPredicate(const aPredicate: TConstPredicate<T>): ISpecification<T>; static;
  end;

  TAndSpecification<T> = class(TSpecification<T>)
  private
    fLeft, fRight: ISpecification<T>;
  public
    constructor Create(const aLeft, aRight: ISpecification<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;
  end;

  TOrSpecification<T> = class(TSpecification<T>)
  private
    fLeft, fRight: ISpecification<T>;
  public
    constructor Create(const aLeft, aRight: ISpecification<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;
  end;

  TNotSpecification<T> = class(TSpecification<T>)
  private
    fInner: ISpecification<T>;
  public
    constructor Create(const aInner: ISpecification<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;
  end;

  TPredicateSpecification<T> = class(TSpecification<T>)
  private
    FPredicate: TConstPredicate<T>;
  public
    constructor Create(const aPredicate: TConstPredicate<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;
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

end.
