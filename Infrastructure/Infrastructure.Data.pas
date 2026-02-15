unit Infrastructure.Data;

interface

uses
  Base.Sqlite,
  Base.Data,
  Application.Contracts,
  Application.Language;

type
  TDatabaseService = class(TSqliteDatabase, IDatabaseService)
  public
    constructor Create(aFileService: IFileService);
    destructor Destroy; override;
  end;

  TTermRepository = class(TRepository<ITerm, TTerm>, ITermRepository)
  public
    constructor Create(const aDatabaseService: IDatabaseService);
  end;

  TSynonymRepository = class(TRepository<ISynonym, TSynonym>, ISynonymRepository)
  public
    constructor Create(const aDatabaseService: IDatabaseService);
  end;

implementation

{ TDatabase }

{----------------------------------------------------------------------------------------------------------------------}
constructor TDatabaseService.Create(aFileService: IFileService);
begin
  inherited Create(aFileService.DatabasePath);
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TDatabaseService.Destroy;
begin
  inherited;
end;

{ TTermRepository }

{----------------------------------------------------------------------------------------------------------------------}
constructor TTermRepository.Create(const aDatabaseService: IDatabaseService);
begin
  inherited Create(aDatabaseService);
end;

{ TSynonymRepository }

{----------------------------------------------------------------------------------------------------------------------}
constructor TSynonymRepository.Create(const aDatabaseService: IDatabaseService);
begin
  inherited Create(aDatabaseService);
end;

end.
