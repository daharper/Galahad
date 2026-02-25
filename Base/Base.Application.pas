{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Application
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Provides basic application abstraction and builder functionality.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Application;

interface

uses
  Base.Core,
  Base.Data,
  Base.Container;

type
  IApplication = interface
    ['{F0FA85F4-CD6E-454B-8D45-798D5BFDF580}']
    procedure Execute;
  end;

  TApplicationBuilder = class
  private
    class var fInstance: TApplicationBuilder;
  public
    function Services: TContainer;
    function Build: IApplication;

    procedure ConfigureDatabase(const aCtx: IDbContext);

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
procedure TApplicationBuilder.ConfigureDatabase(const aCtx: IDbContext);
begin
  Services.AddSingleton<IDbContext>(aCtx);

  Services.Add<IDbAmbientInstaller, TDbAmbientInstaller>;
  Services.Resolve<IDbAmbientInstaller>; // ensure ambient installed now (main thread)
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
