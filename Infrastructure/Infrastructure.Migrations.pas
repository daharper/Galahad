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

  TRewriteRulesMigration = class(TMigration)
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
  m.Add(1, 4, TRewriteRulesMigration,   'Seeding initial rewrite rules');
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

        CREATE TABLE RewriteRule (
          Id          INTEGER PRIMARY KEY,
          Pattern     TEXT    NOT NULL,
          Replacement TEXT    NOT NULL,
          Priority    INTEGER NOT NULL DEFAULT 0);
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

        -- =========================
        -- Noise
        -- =========================
        (1, 'NOISE', 1),

        -- =========================
        -- Prepositions (100–199)
        -- =========================
        (100, 'ABOUT', 2),
        (101, 'ACROSS', 2),
        (102, 'AFTER', 2),
        (103, 'AGAINST', 2),
        (104, 'AMONG', 2),
        (105, 'AROUND', 2),
        (106, 'AT', 2),
        (107, 'BEFORE', 2),
        (108, 'BEHIND', 2),
        (109, 'BENEATH', 2),
        (110, 'BETWEEN', 2),
        (111, 'BY', 2),
        (112, 'FROM', 2),
        (113, 'IN', 2),
        (114, 'INSIDE', 2),
        (115, 'INTO', 2),
        (116, 'ON', 2),
        (117, 'ONTO', 2),
        (118, 'OUTSIDE', 2),
        (119, 'OVER', 2),
        (120, 'THROUGH', 2),
        (121, 'TO', 2),
        (122, 'TOWARD', 2),
        (123, 'UNDER', 2),
        (124, 'WITH', 2),
        (125, 'WITHIN', 2),

        -- =========================
        -- Directions (200–299)
        -- =========================
        (200, 'BACK', 3),
        (201, 'DOWN', 3),
        (202, 'EAST', 3),
        (203, 'FORWARD', 3),
        (204, 'INWARD', 3),
        (205, 'LEFT', 3),
        (206, 'NORTH', 3),
        (207, 'NORTHEAST', 3),
        (208, 'NORTHWEST', 3),
        (209, 'OUTWARD', 3),
        (210, 'RIGHT', 3),
        (211, 'SOUTH', 3),
        (212, 'SOUTHEAST', 3),
        (213, 'SOUTHWEST', 3),
        (214, 'UP', 3),
        (215, 'WEST', 3),

        -- =========================
        -- Actions (300–399)
        -- =========================
        (300, 'ATTACK', 4),
        (301, 'CAST', 4),
        (302, 'CLIMB', 4),
        (303, 'CLOSE', 4),
        (304, 'COMBINE', 4),
        (305, 'CONSUME', 4),
        (306, 'DROP', 4),
        (307, 'EAT', 4),
        (308, 'EQUIP', 4),
        (309, 'EXAMINE', 4),
        (310, 'FLEE', 4),
        (311, 'GET', 4),
        (312, 'GO', 4),
        (313, 'HELP', 4),
        (314, 'INVENTORY', 4),
        (315, 'JUMP', 4),
        (316, 'LOCK', 4),
        (317, 'LOOK', 4),
        (318, 'OPEN', 4),
        (319, 'PULL', 4),
        (320, 'PUSH', 4),
        (321, 'PUT', 4),
        (322, 'QUIT', 4),
        (323, 'READ', 4),
        (324, 'REST', 4),
        (325, 'SAVE', 4),
        (326, 'SEARCH', 4),
        (327, 'SLEEP', 4),
        (328, 'SNEAK', 4),
        (329, 'TAKE', 4),
        (330, 'TALK', 4),
        (331, 'THROW', 4),
        (332, 'UNLOCK', 4),
        (333, 'USE', 4),
        (334, 'WAIT', 4),
        (335, 'WAKE', 4),
        (336, 'WEAR', 4),
        (337, 'WIELD', 4),

        -- =========================
        -- Manners / Adverbs (400–499)
        -- =========================
        (400, 'BOLDLY', 5),
        (401, 'CAREFULLY', 5),
        (402, 'CAUTIOUSLY', 5),
        (403, 'CLUMSILY', 5),
        (404, 'DELIBERATELY', 5),
        (405, 'FAST', 5),
        (406, 'FORCEFULLY', 5),
        (407, 'GENTLY', 5),
        (408, 'HASTILY', 5),
        (409, 'LOUDLY', 5),
        (410, 'PATIENTLY', 5),
        (411, 'QUIETLY', 5),
        (412, 'QUICKLY', 5),
        (413, 'SILENTLY', 5),
        (414, 'SLOWLY', 5),
        (415, 'STEALTHILY', 5),
        (416, 'SUDDENLY', 5),

        -- =========================
        -- Quantities (500–599)
        -- =========================
        (500, 'ALL', 6),
        (501, 'BOTH', 6),
        (502, 'EACH', 6),
        (503, 'EVERY', 6),
        (504, 'FEW', 6),
        (505, 'HALF', 6),
        (506, 'MANY', 6),
        (507, 'NONE', 6),
        (508, 'ONE', 6),
        (509, 'SEVERAL', 6),
        (510, 'SOME', 6),
        (511, 'THREE', 6),
        (512, 'TWO', 6);
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
        -- =========================
        -- NOISE (1)
        -- =========================
        ('a', 1),
        ('an', 1),
        ('the', 1),
        ('and', 1),
        ('or', 1),
        ('but', 1),
        ('so', 1),
        ('then', 1),
        ('now', 1),
        ('please', 1),
        ('pls', 1),
        ('plz', 1),
        ('ok', 1),
        ('okay', 1),
        ('alright', 1),
        ('well', 1),
        ('hey', 1),
        ('uh', 1),
        ('um', 1),
        ('hmm', 1),
        ('just', 1),
        ('really', 1),
        ('very', 1),
        ('quite', 1),
        ('maybe', 1),
        ('perhaps', 1),
        ('my', 1),
        ('your', 1),
        ('our', 1),
        ('this', 1),
        ('that', 1),
        ('these', 1),
        ('those', 1),
        ('here', 1),
        ('there', 1),

        -- =========================
        -- PREPOSITIONS (100..125)
        -- =========================
        ('about', 100),
        ('across', 101),
        ('after', 102),
        ('against', 103),
        ('among', 104),
        ('amid', 104),
        ('around', 105),
        ('round', 105),
        ('at', 106),
        ('@', 106),
        ('before', 107),
        ('behind', 108),
        ('beneath', 109),
        ('between', 110),
        ('by', 111),
        ('beside', 111),
        ('near', 111),
        ('from', 112),
        ('in', 113),
        ('inside', 114),
        ('into', 115),
        ('on', 116),
        ('upon', 116),
        ('onto', 117),
        ('outside', 118),
        ('over', 119),
        ('above', 119),
        ('through', 120),
        ('thru', 120),
        ('to', 121),
        ('toward', 122),
        ('towards', 122),
        ('under', 123),
        ('underneath', 123),
        ('with', 124),
        ('using', 124),
        ('via', 124),
        ('within', 125),

        -- =========================
        -- DIRECTIONS (200..215)
        -- =========================
        ('back', 200),
        ('backward', 200),
        ('backwards', 200),
        ('b', 200),

        ('down', 201),
        ('d', 201),
        ('downward', 201),
        ('downwards', 201),

        ('east', 202),
        ('e', 202),

        ('forward', 203),
        ('forwards', 203),
        ('ahead', 203),
        ('fwd', 203),

        ('inward', 204),
        ('inwards', 204),

        ('left', 205),
        ('lft', 205),

        ('north', 206),
        ('n', 206),

        ('northeast', 207),
        ('ne', 207),

        ('northwest', 208),
        ('nw', 208),

        ('outward', 209),
        ('outwards', 209),

        ('right', 210),
        ('rgt', 210),

        ('south', 211),
        ('s', 211),

        ('southeast', 212),
        ('se', 212),

        ('southwest', 213),
        ('sw', 213),

        ('up', 214),
        ('u', 214),
        ('upward', 214),
        ('upwards', 214),

        ('west', 215),
        ('w', 215),

        -- =========================
        -- ACTIONS (300..337)
        -- =========================
        -- ATTACK (300)
        ('attack', 300),
        ('fight', 300),
        ('battle', 300),
        ('kill', 300),
        ('slay', 300),
        ('smite', 300),
        ('hit', 300),
        ('strike', 300),
        ('bash', 300),
        ('punch', 300),
        ('kick', 300),
        ('stab', 300),
        ('slash', 300),
        ('chop', 300),
        ('hack', 300),

        -- CAST (301)
        ('cast', 301),
        ('spell', 301),
        ('conjure', 301),
        ('invoke', 301),

        -- CLIMB (302)
        ('climb', 302),
        ('scale', 302),
        ('scramble', 302),

        -- CLOSE (303)
        ('close', 303),
        ('shut', 303),
        ('slam', 303),

        -- COMBINE (304)
        ('combine', 304),
        ('mix', 304),
        ('merge', 304),
        ('join', 304),
        ('attach', 304),
        ('connect', 304),

        -- CONSUME (305)
        ('consume', 305),

        -- DROP (306)
        ('drop', 306),
        ('discard', 306),
        ('ditch', 306),
        ('leave', 306),
        ('release', 306),

        -- EAT (307)
        ('eat', 307),
        ('chew', 307),
        ('devour', 307),
        ('nibble', 307),
        ('bite', 307),

        -- EQUIP (308)
        ('equip', 308),
        ('arm', 308),
        ('ready', 308),

        -- EXAMINE (309)
        ('examine', 309),
        ('inspect', 309),
        ('check', 309),
        ('study', 309),
        ('observe', 309),
        ('peer', 309),
        ('peek', 309),
        ('x', 309),
        ('ex', 309),
        ('exam', 309),

        -- FLEE (310)
        ('flee', 310),
        ('escape', 310),
        ('retreat', 310),
        ('withdraw', 310),
        ('run', 310),

        -- GET (311)
        ('get', 311),
        ('obtain', 311),
        ('acquire', 311),
        ('fetch', 311),
        ('collect', 311),
        ('retrieve', 311),
        ('snatch', 311),

        -- GO (312)
        ('go', 312),
        ('move', 312),
        ('walk', 312),
        ('step', 312),
        ('travel', 312),
        ('proceed', 312),
        ('head', 312),

        -- HELP (313)
        ('help', 313),
        ('hint', 313),
        ('hints', 313),
        ('?', 313),

        -- INVENTORY (314)
        ('inventory', 314),
        ('inv', 314),
        ('i', 314),
        ('pack', 314),
        ('bag', 314),
        ('items', 314),
        ('stuff', 314),
        ('gear', 314),

        -- JUMP (315)
        ('jump', 315),
        ('leap', 315),
        ('hop', 315),
        ('vault', 315),

        -- LOCK (316)
        ('lock', 316),
        ('secure', 316),
        ('bar', 316),

        -- LOOK (317)
        ('look', 317),
        ('l', 317),
        ('see', 317),
        ('glance', 317),
        ('stare', 317),

        -- OPEN (318)
        ('open', 318),
        ('unseal', 318),
        ('pry', 318),

        -- PULL (319)
        ('pull', 319),
        ('tug', 319),
        ('yank', 319),

        -- PUSH (320)
        ('push', 320),
        ('press', 320),
        ('shove', 320),
        ('nudge', 320),

        -- PUT (321)
        ('put', 321),
        ('place', 321),
        ('set', 321),
        ('insert', 321),
        ('stash', 321),

        -- QUIT (322)
        ('quit', 322),
        ('exit', 322),
        ('bye', 322),

        -- READ (323)
        ('read', 323),
        ('peruse', 323),

        -- REST (324)
        ('rest', 324),
        ('relax', 324),
        ('pause', 324),

        -- SAVE (325)
        ('save', 325),

        -- SEARCH (326)
        ('search', 326),
        ('find', 326),
        ('hunt', 326),
        ('probe', 326),
        ('scan', 326),
        ('rummage', 326),

        -- SLEEP (327)
        ('sleep', 327),
        ('nap', 327),
        ('doze', 327),

        -- SNEAK (328)
        ('sneak', 328),
        ('hide', 328),
        ('creep', 328),
        ('skulk', 328),

        -- TAKE (329)
        ('take', 329),
        ('grab', 329),
        ('pick', 329),
        ('pickup', 329),
        ('lift', 329),
        ('loot', 329),

        -- TALK (330)
        ('talk', 330),
        ('speak', 330),
        ('chat', 330),

        -- THROW (331)
        ('throw', 331),
        ('toss', 331),
        ('hurl', 331),
        ('lob', 331),
        ('fling', 331),

        -- UNLOCK (332)
        ('unlock', 332),
        ('unbolt', 332),

        -- USE (333)
        ('use', 333),
        ('apply', 333),
        ('operate', 333),
        ('activate', 333),

        -- WAIT (334)
        ('wait', 334),
        ('hold', 334),
        ('linger', 334),

        -- WAKE (335)
        ('wake', 335),
        ('awaken', 335),
        ('rouse', 335),

        -- WEAR (336)
        ('wear', 336),
        ('don', 336),

        -- WIELD (337)
        ('wield', 337),
        ('holdfast', 337),
        ('brandish', 337),

        -- =========================
        -- MANNERS / ADVERBS (400..416)
        -- =========================
        ('boldly', 400),
        ('bravely', 400),
        ('fearlessly', 400),

        ('carefully', 401),
        ('careful', 401),
        ('meticulously', 401),

        ('cautiously', 402),
        ('cautious', 402),
        ('warily', 402),
        ('wary', 402),

        ('clumsily', 403),
        ('clumsy', 403),
        ('awkwardly', 403),

        ('deliberately', 404),
        ('deliberate', 404),
        ('intentionally', 404),
        ('purposefully', 404),

        ('fast', 405),
        ('rapidly', 405),
        ('swiftly', 405),

        ('forcefully', 406),
        ('forceful', 406),
        ('hard', 406),
        ('strongly', 406),

        ('gently', 407),
        ('gentle', 407),
        ('softly', 407),

        ('hastily', 408),
        ('hasty', 408),

        ('loudly', 409),
        ('loud', 409),
        ('noisily', 409),

        ('patiently', 410),
        ('patient', 410),
        ('calmly', 410),

        ('quietly', 411),
        ('quiet', 411),

        ('quickly', 412),
        ('quick', 412),
        ('asap', 412),

        ('silently', 413),
        ('silent', 413),

        ('slowly', 414),
        ('slow', 414),

        ('stealthily', 415),
        ('stealthy', 415),
        ('sneakily', 415),

        ('suddenly', 416),
        ('instantly', 416),

        -- =========================
        -- QUANTITIES (500..512)
        -- =========================
        ('all', 500),
        ('everything', 500),

        ('both', 501),
        ('pair', 501),

        ('each', 502),

        ('every', 503),

        ('few', 504),

        ('half', 505),

        ('many', 506),
        ('lots', 506),
        ('plenty', 506),

        ('none', 507),
        ('no', 507),

        ('one', 508),
        ('single', 508),

        ('several', 509),

        ('some', 510),

        ('three', 511),

        ('two', 512);
        ''';
begin
  inherited;

  aDb.CurrentSession.Connection.ExecSQL(SQL);
end;

{$endregion}

{$region 'TRewriteRulesMigration' }

{----------------------------------------------------------------------------------------------------------------------}
procedure TRewriteRulesMigration.Execute(const aDb: IDbSessionManager);
const
  SQL = '''
        INSERT INTO RewriteRule (Id, Pattern, Replacement, Priority) VALUES
        (1, 'run',     'go quickly', 10),
        (2, 'go up',   'climb up',   10),
        (3, 'go down', 'climb down', 10),
        (4, 'pick up', 'take',       10),
        (5, 'look at', 'examine',    10);
        ''';
begin
  inherited;

  aDb.CurrentSession.Connection.ExecSQL(SQL);
end;

{$endregion}

end.
