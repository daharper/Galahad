unit Application.Core.Contracts;

interface

type
  IApplication = interface
    ['{F0FA85F4-CD6E-454B-8D45-798D5BFDF580}']
    procedure Execute;
    procedure Welcome;
  end;

  IFileService = interface
    ['{22A50D33-BEFA-4D3C-A384-99F7D8A90992}']

    function StartupPath: string;
    function DatabasePath: string;
  end;



implementation

end.
