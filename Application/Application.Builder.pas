unit Application.Builder;

interface

uses
  Base.Core,
  Base.Container,
  Application.Contracts;

type
  TApplicationBuilder = class
  private
    class var fInstance: TApplicationBuilder;
  public
    function Services: TContainer;
    function Build: IApplication;

    class constructor Create;
    class destructor Destroy;
  end;

  function ApplicationBuilder: TApplicationBuilder;

implementation

uses
  System.SysUtils;

{ Functions }

{----------------------------------------------------------------------------------------------------------------------}
function ApplicationBuilder: TApplicationBuilder;
begin
  Result := TApplicationBuilder.fInstance;
end;

{ TApplicationBuilder }

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.Build: IApplication;
begin
  Result := Container.Resolve<IApplication>;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TApplicationBuilder.Services: TContainer;
begin
  Result := Container;
end;

{----------------------------------------------------------------------------------------------------------------------}
class constructor TApplicationBuilder.Create;
begin
  fInstance := TApplicationBuilder.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
class destructor TApplicationBuilder.Destroy;
begin
  FreeAndNil(fInstance);
end;

end.
