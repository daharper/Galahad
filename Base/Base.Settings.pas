{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Settings
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Provides basic settings.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Settings;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Base.Core,
  Base.Xml;

type
  ISettings = interface(IBvElement)
    ['{6AC76463-382B-4D9B-8C8C-E0F86E07ED78}']
    function Database: IBvElement;
    function DatabaseConfiguration(const aProvider: string; const aName: string = ''): IBvElement;
  end;

  TSettings = class(TBvElement, ISettings)
  public
    function Database: IBvElement; inline;
    function DatabaseConfiguration(const aProvider: string; const aName: string = ''): IBvElement;

    constructor Create(var aOther: IBvElement);
  end;

implementation

uses
  Base.Integrity;

{ TSettings }

{----------------------------------------------------------------------------------------------------------------------}
function TSettings.Database: IBvElement;
begin
  Result := Elem('Database');
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSettings.DatabaseConfiguration(const aProvider: string; const aName: string): IBvElement;
begin
  var db := Database;

  var name := if aName <> '' then aName else db.Attr('name').Value;

  for var e in db.Elems do
    if SameText(e.Attr('name').Value, name) and
       SameText(e.Name, aProvider) then exit(e);

  Result := nil;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSettings.Create(var aOther: IBvElement);
begin
  inherited Create(aOther);
end;

end.
