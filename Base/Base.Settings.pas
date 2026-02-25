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
