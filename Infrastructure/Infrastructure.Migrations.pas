unit Infrastructure.Migrations;

interface

uses
  System.Generics.Collections,
  Base.Data,
  Base.Integrity;

type
  TMigration = class
  private
    fVersion: integer;
    fSequence: integer;
    fDescription: string;
  protected
    constructor Create(const aVersion: integer; const aSequence: integer; const aDescription: string);
  public
    property Version: integer read fVersion;
    property Sequence: integer read fSequence;
    property Description: string read fDescription;

    procedure Execute(const aDatabase: IDatabaseService); virtual;
  end;

  IMigrationManager = interface
    ['{902A60CA-F419-4CEC-A4D3-7A1C1A2D37AA}']
  end;

  TMigrationManager = class(TInterfacedObject, IMigrationManager)
  private
    fMigrations: TObjectList<TMigration>;
    fDatabase: IDatabaseService;

    procedure Add<T:TMigration, constructor>;
    procedure AddMigrations;
    procedure Execute;
  public
    constructor Create(const aDatabase: IDatabaseService);
    destructor Destroy; override;
  end;

  // migration 1.1
  TCreateDatabaseMigration = class(TMigration)
  public
    procedure Execute(const aDatabase: IDatabaseService); override;
    constructor Create;
  end;

  // migration 1.2
  TSeedTermsMigration = class(TMigration)
  public
    procedure Execute(const aDatabase: IDatabaseService); override;
    constructor Create;
  end;

  // migration 1.3
  TSeedWordsMigration = class(TMigration)
  public
    procedure Execute(const aDatabase: IDatabaseService); override;
    constructor Create;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Defaults,
  System.Math,
  Base.Stream;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMigrationManager.AddMigrations;
begin
  Add<TCreateDatabaseMigration>;
  Add<TSeedTermsMigration>;
  Add<TSeedWordsMigration>;
end;

{$region '1.1 TCreateDatabaseMigration' }

{----------------------------------------------------------------------------------------------------------------------}
constructor TCreateDatabaseMigration.Create;
begin
  inherited Create(1, 1, 'Create the initial schema');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TCreateDatabaseMigration.Execute(const aDatabase: IDatabaseService);
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

  aDatabase.Connection.ExecSQL(DDL);
end;

{$endregion}

{$region '1.2 TSeedTermsMigration' }

{----------------------------------------------------------------------------------------------------------------------}
constructor TSeedTermsMigration.Create;
begin
  inherited Create(1, 2, 'Seeding intial term list');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSeedTermsMigration.Execute(const aDatabase: IDatabaseService);
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
  inherited;

  aDatabase.Connection.ExecSQL(SQL);
end;

{$endregion}

{$region '1.3 TSeedWordsMigration' }

{----------------------------------------------------------------------------------------------------------------------}
constructor TSeedWordsMigration.Create;
begin
  inherited Create(1, 3, 'Seeding intial word list');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSeedWordsMigration.Execute(const aDatabase: IDatabaseService);
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
  inherited;

  aDatabase.Connection.ExecSQL(SQL);
end;

{$endregion}

{$region 'mechanics'}

{----------------------------------------------------------------------------------------------------------------------}
procedure TMigrationManager.Execute;
var
  scope: TScope;
begin
  var version := fDatabase.GetDatabaseVersion;
  var max := 0;

  for var m in fMigrations do
    if m.Version > max then
      max := m.Version;

  if max = version then exit;

  var migrations := Stream.From<TMigration>(fMigrations.ToArray)
    .Filter(function(const m: TMigration): Boolean
        begin
          Result := m.Version > version;
        end)
    .Sort(TComparer<TMigration>.Construct(function(const l, r: TMigration): integer
        begin
          if l.Version <> r.Version then
            Result := Ord(CompareValue(l.Version, r.Version))
          else
            Result := Ord(CompareValue(l.Sequence, r.Sequence));
        end))
    .GroupBy<integer>(function(const m: TMigration): integer
        begin
          Result := m.Version;
        end);

  scope.Owns(migrations);
  scope.Defer(procedure begin for var item in migrations do item.Value.Free; end);

  Inc(version);

  for var v in [version..max] do
  begin
    fDatabase.StartTransaction;

    for var m in migrations[v] do
    try
      m.Execute(fDatabase);

      fDatabase.SetDatabaseVersion(v);
      fDatabase.Commit;
    except
      on E:Exception do
      begin
        fDatabase.Rollback;

        var msg := Format('Migration Error (%d.%d - %s): %s]', [v, m.Sequence, m.Description, E.Message]);
        raise Exception.Create(msg);
      end;
    end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TMigrationManager.Add<T>;
var
  m: T;
begin
  m := T.Create;
  fMigrations.Add(m)
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TMigrationManager.Create(const aDatabase: IDatabaseService);
begin
  fDatabase := aDatabase;

  fMigrations := TObjectList<TMigration>.Create(true);

  AddMigrations;

  Execute;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TMigrationManager.Destroy;
begin
  fMigrations.Free;

  inherited;
end;

{ TMigration }

{----------------------------------------------------------------------------------------------------------------------}
procedure TMigration.Execute(const aDatabase: IDatabaseService);
begin
  Writeln(Format('Applying migration (%d.%d): %s', [fVersion, fSequence, fDescription]));
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TMigration.Create(const aVersion: integer; const aSequence: integer; const aDescription: string);
begin
  fVersion     := aVersion;
  fSequence    := aSequence;
  fDescription := aDescription;
end;

{$endregion}

end.
