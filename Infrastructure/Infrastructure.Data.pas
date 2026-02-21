unit Infrastructure.Data;

interface

uses
  Base.Sqlite,
  Base.Data,
  Domain.Terms,
  Application.Contracts,
  Application.Language;

type
  TDatabaseService = class(TSqliteDatabase, IDatabaseService)
  private
    procedure CreateDatabase;
    procedure SeedTerms;
    procedure SeedWords;
  public
    procedure AfterConstruction; override;

    constructor Create(aFileService: IFileService);
    destructor Destroy; override;
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
  System.IOUtils;

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

{ TDatabase }

{----------------------------------------------------------------------------------------------------------------------}
procedure TDatabaseService.CreateDatabase;
const
  DDL = '''
        create table Term
        (
          Id INTEGER primary key,
          Value TEXT not null unique,
          KindId INTEGER not null
        );

        create table Word
        (
          Id INTEGER primary key,
          Value TEXT not null unique,
          TermId INTEGER not null references Term
        );
        ''';
begin
  fConnection.ExecSQL(DDL);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDatabaseService.SeedTerms;
const
  SQL = '''
        INSERT INTO Term (Id, Value, KindId) VALUES
        -- Noise
        (1,  'NOISE', 1),

        -- Prepositions
        (2,  'WITH', 2),
        (3,  'TO', 2),
        (4,  'FROM', 2),
        (5,  'IN', 2),
        (6,  'ON', 2),
        (7,  'UNDER', 2),
        (8,  'AT', 2),
        (9,  'THROUGH', 2),

        -- Directions
        (10, 'NORTH', 3),
        (11, 'SOUTH', 3),
        (12, 'EAST', 3),
        (13, 'WEST', 3),
        (14, 'UP', 3),
        (15, 'DOWN', 3),

        -- Actions
        (16, 'GO', 4),
        (17, 'LOOK', 4),
        (18, 'TAKE', 4),
        (19, 'DROP', 4),
        (20, 'USE', 4),
        (21, 'OPEN', 4),
        (22, 'CLOSE', 4),
        (23, 'ATTACK', 4),
        (24, 'INVENTORY', 4),
        (25, 'EXAMINE', 4),

        -- Manner / Adverbs
        (26, 'QUICKLY', 5),
        (27, 'CAREFULLY', 5),
        (28, 'SLOWLY', 5),

        -- Quantity
        (29, 'ALL', 6),
        (30, 'ONE', 6),
        (31, 'TWO', 6);
        ''';
begin
  fConnection.ExecSQL(SQL);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDatabaseService.SeedWords;
const
  SQL = '''
        INSERT INTO Word (Value, TermId) VALUES
        -- Noise
        ('the', 1),
        ('a', 1),
        ('an', 1),
        ('please', 1),
        ('kindly', 1),
        ('just', 1),

        -- Preposition Synonyms
        ('inside', 5),
        ('into', 5),
        ('within', 5),
        ('onto', 6),
        ('beneath', 7),
        ('below', 7),

        -- Direction Synonyms
        ('n', 10),
        ('s', 11),
        ('e', 12),
        ('w', 13),
        ('u', 14),
        ('d', 15),

        -- Action Synonyms
        ('walk', 16),
        ('move', 16),
        ('run', 16),

        ('inspect', 17),
        ('view', 17),
        ('see', 17),

        ('get', 18),
        ('grab', 18),
        ('pick', 18),

        ('leave', 19),

        ('unlock', 21),
        ('shut', 22),

        ('inv', 24),
        ('i', 24),

        ('x', 25),

        -- Adverb Synonyms
        ('fast', 26),
        ('slow', 28);
        ''';
begin
  fConnection.ExecSQL(SQL);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TDatabaseService.AfterConstruction;
begin
  inherited;

  if Exists then
  begin
    fConnection.ExecSQL('PRAGMA wal_checkpoint(TRUNCATE);');
    exit;
  end;

  CreateDatabase;

  SeedTerms;
  SeedWords;

  Exists := true;
end;

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

end.
