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
  ISettings = interface
    ['{6AC76463-382B-4D9B-8C8C-E0F86E07ED78}']
    function Database: IBvElement;
  end;

  { todo - TSettings should be moved out of base - but wait for more pressure first }

  TSettings = class(TBvElement, ISettings)
  public
    function Database: IBvElement;
  end;

implementation

{ TSettings }

function TSettings.Database: IBvElement;
begin
  Result := Elem('Database');
end;

end.
