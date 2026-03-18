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

  TRewriteRepository = class(TRepository<IRewriteRule, TRewriteRule>, IRewriteRepository)
  public
    constructor Create(const aDb: IDbSessionManager);

    function GetPriorizedRules: TArray<IRewriteRule>;
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

{ TRewriteRuleRepository }

{----------------------------------------------------------------------------------------------------------------------}
constructor TRewriteRepository.Create(const aDb: IDbSessionManager);
begin
  inherited Create(aDb);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TRewriteRepository.GetPriorizedRules: TArray<IRewriteRule>;
const
  SQL = 'select * from RewriteRule order by Priority';
var
  scope: TScope;
begin
  var rules := scope.Owns(ExecQuery(SQL));

  Result := rules.ToArray;
end;

end.
