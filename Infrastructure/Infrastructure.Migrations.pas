unit Infrastructure.Migrations;

interface

uses
  System.Generics.Collections,
  Base.Core,
  Base.Data,
  Base.Integrity;

type
  TMigrationRegistrar = class(TTransient, IMigrationRegistrar)
  public
    procedure Configure(const m: IMigrationManager);
  end;

  { version 1 migrations }

  TCreateDatabaseMigration = class(TMigration)
  public
    procedure Execute(const aDb: IDbSessionManager); override;
  end;

  TSeedTermsMigration = class(TMigration)
  public
    procedure Execute(const aDb: IDbSessionManager); override;
  end;

  TSeedWordsMigration = class(TMigration)
  public
    procedure Execute(const aDb: IDbSessionManager); override;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Defaults,
  System.Math,
  Base.Stream;

{ TMigrationRegistrar }

{----------------------------------------------------------------------------------------------------------------------}
procedure TMigrationRegistrar.Configure(const m: IMigrationManager);
begin
  m.Add(1, 1, TCreateDatabaseMigration, 'Create the initial schema');
  m.Add(1, 2, TSeedTermsMigration,      'Seeding intial term list');
  m.Add(1, 3, TSeedWordsMigration,      'Seeding intial word list');
end;

{$region '1.1 TCreateDatabaseMigration' }

{----------------------------------------------------------------------------------------------------------------------}
procedure TCreateDatabaseMigration.Execute(const aDb: IDbSessionManager);
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
  inherited;

  aDb.CurrentSession.Connection.ExecSQL(DDL);
end;

{$endregion}

{$region '1.2 TSeedTermsMigration' }

{----------------------------------------------------------------------------------------------------------------------}
procedure TSeedTermsMigration.Execute(const aDb: IDbSessionManager);
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
  inherited;

  aDb.CurrentSession.Connection.ExecSQL(SQL);
end;

{$endregion}

{$region '1.3 TSeedWordsMigration' }

{----------------------------------------------------------------------------------------------------------------------}
procedure TSeedWordsMigration.Execute(const aDb: IDbSessionManager);
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
        ('and', 1),
        ('then', 1),

        -- Preposition Synonyms
        ('inside', 5),
        ('into', 5),
        ('within', 5),
        ('onto', 6),
        ('beneath', 7),
        ('below', 7),
        ('with', 2),
        ('to', 3),
        ('from', 4),
        ('in', 5),
        ('on', 6),
        ('under', 7),
        ('at', 8),
        ('through', 9),

        -- Direction Synonyms
        ('n', 10),
        ('s', 11),
        ('e', 12),
        ('w', 13),
        ('u', 14),
        ('d', 15),
        ('north', 10),
        ('south', 11),
        ('east', 12),
        ('west', 13),
        ('up', 14),
        ('down', 15),

        -- Action Synonyms
        ('walk', 16),
        ('move', 16),
        ('run', 16),

        ('inspect', 25),
        ('view', 25),
        ('see', 25),

        ('get', 18),
        ('grab', 18),
        ('pick', 18),

        ('leave', 19),

        ('unlock', 21),
        ('shut', 22),

        ('inv', 24),
        ('i', 24),

        ('x', 25),

        ('go', 16),
        ('look', 25),
        ('take', 18),
        ('drop', 19),
        ('use', 20),
        ('open', 21),
        ('close', 22),
        ('attack', 23),
        ('inventory', 24),
        ('examine', 25),

        -- Manner / Adverb Synonyms
        ('fast', 26),
        ('slow', 28),
        ('quickly', 26),
        ('carefully', 27),
        ('slowly', 28),

        -- Quantity
        ('all', 29),
        ('one', 30),
        ('two', 31);
        ''';
begin
  inherited;

  aDb.CurrentSession.Connection.ExecSQL(SQL);
end;

{$endregion}

end.
