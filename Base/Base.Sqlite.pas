unit Base.Sqlite;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Rtti,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  FireDAC.VCLUI.Wait,
  FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  Data.DB,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  Base.Data,
  Base.Core;

type
  TSqliteDatabase = class(TSingleton) //TInterfacedObject)
  private
    fExists: boolean;
    fPath: string;
  protected
    fDriver: TFDPhysSQLiteDriverLink;
    fConnection: TFDConnection;
    fQuery: TFDQuery;

    property Exists: boolean read fExists write fExists;
    property Path: string read fPath write fPath;

    constructor Create(const aPath: string);
  public
    function Connection: TFDConnection;
    function Query: TFDQuery;
    function GetDatabaseVersion: integer;

    procedure SetDatabaseVersion(const aVersion: integer);
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    procedure Truncate;

    destructor Destroy; override;
  end;

implementation

uses
  System.IOUtils,
  System.Variants;

{ TSqliteDatabase }

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteDatabase.Connection: TFDConnection;
begin
  Result := fConnection;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteDatabase.Query: TFDQuery;
begin
  Result := fQuery;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteDatabase.StartTransaction;
begin
  fConnection.StartTransaction
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteDatabase.Truncate;
begin
  fConnection.ExecSQL('PRAGMA wal_checkpoint(TRUNCATE);');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteDatabase.Commit;
begin
  fConnection.Commit;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteDatabase.Rollback;
begin
  fConnection.Rollback;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSqliteDatabase.GetDatabaseVersion: integer;
begin
  if not fExists then exit(0);

  Result := fConnection.ExecSQLScalar('PRAGMA user_version');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSqliteDatabase.SetDatabaseVersion(const aVersion: integer);
begin
  fConnection.ExecSQL('PRAGMA user_version = ' + IntToStr(aVersion));

  fExists := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSqliteDatabase.Create(const aPath: string);
begin
  fPath   := aPath;
  fExists := TFile.Exists(aPath);
  fDriver := TFDPhysSQLiteDriverLink.Create(nil);

  fDriver.DriverID := 'SQLiteDriver';

  fConnection := TFDConnection.Create(nil);

  fConnection.LoginPrompt := False;

  fConnection.Params.Clear;
  fConnection.Params.DriverID := 'SQLiteDriver';
  fConnection.Params.Database := fPath;
  fConnection.Params.Values['BusyTimeout'] := '500';

  fConnection.Connected := True;

  fConnection.ExecSQL('PRAGMA foreign_keys = ON;');
  fConnection.ExecSQL('PRAGMA journal_mode = WAL;');
  fConnection.ExecSQL('PRAGMA synchronous = NORMAL;');

  if fExists then Truncate;

  fQuery := TFDQuery.Create(nil);
  fQuery.Connection := fConnection;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TSqliteDatabase.Destroy;
begin
  fQuery.Close;

  fConnection.Connected := false;

  fQuery.Free;
  fConnection.Free;
  fDriver.Free;
end;

end.
