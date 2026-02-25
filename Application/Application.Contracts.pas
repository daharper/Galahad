unit Application.Contracts;

interface

type
  IFileService = interface
    ['{22A50D33-BEFA-4D3C-A384-99F7D8A90992}']

    function StartupPath: string;
    function DatabasePath: string;
  end;

implementation

end.
