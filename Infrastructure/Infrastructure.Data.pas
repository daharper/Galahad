unit Infrastructure.Data;

interface

uses
  System.Generics.Collections,
  Base.Core,
  Base.Integrity,
  Base.Data,
  Base.Sqlite,
  Domain.Terms,
  Application.Language;

type
  TTermRepository = class(TRepository<ITerm, TTerm>, ITermRepository)
  public
    constructor Create(const aDb: IDbSessionManager);
  end;

  TWordRepository = class(TRepository<IWord, TWord>, IWordRepository)
  public
    constructor Create(const aDb: IDbSessionManager);
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
constructor TTermRepository.Create(const aDb: IDbSessionManager);
begin
  inherited Create(aDb);
end;

{ TSynonymRepository }

{----------------------------------------------------------------------------------------------------------------------}
constructor TWordRepository.Create(const aDb: IDbSessionManager);
begin
  inherited Create(aDb);
end;

end.
