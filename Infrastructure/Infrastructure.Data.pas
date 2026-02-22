unit Infrastructure.Data;

interface

uses
  System.Generics.Collections,
  Base.Core,
  Base.Integrity,
  Base.Sqlite,
  Base.Data,
  Domain.Terms,
  Application.Contracts,
  Application.Language;

type
  TDatabaseService = class(TSqliteDatabase, IDatabaseService)
  public
    constructor Create(aFileService: IFileService);
  end;

  TTermRepository = class(TRepository<ITerm, TTerm>, ITermRepository)
  public
    constructor Create(const aDatabaseService: IDatabaseService);
  end;

  TWordRepository = class(TRepository<IWord, TWord>, IWordRepository)
  public
    constructor Create(const aDatabaseService: IDatabaseService);
  end;


implementation

uses
  System.IOUtils,
  System.SysUtils,
  System.Math,
  System.Generics.Defaults,
  Base.Stream;

{ TTermRepository }

{----------------------------------------------------------------------------------------------------------------------}
constructor TTermRepository.Create(const aDatabaseService: IDatabaseService);
begin
  inherited Create(aDatabaseService);
end;

{ TSynonymRepository }

{----------------------------------------------------------------------------------------------------------------------}
constructor TWordRepository.Create(const aDatabaseService: IDatabaseService);
begin
  inherited Create(aDatabaseService);
end;

{ TDatabaseService }

{----------------------------------------------------------------------------------------------------------------------}
constructor TDatabaseService.Create(aFileService: IFileService);
begin
  inherited Create(aFileService.DatabasePath);
end;

end.
