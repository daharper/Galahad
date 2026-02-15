unit Infrastructure.SqliteDatabase;

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
  Base.Core,
  SharedKernel.Data,
  Application.Contracts;

type
  TSqliteDatabase = class(TSingleton)
  protected
    fDriver: TFDPhysSQLiteDriverLink;
    fConnection: TFDConnection;
    fQuery: TFDQuery;

    constructor Create(const aPath: string);
  public
    function Connection: TFDConnection;
    function Query: TFDQuery;

    destructor Destroy; override;
  end;

implementation

{ TSqliteDatabase }

{----------------------------------------------------------------------------------------------------------------------}
constructor TSqliteDatabase.Create(const aPath: string);
begin
  fDriver := TFDPhysSQLiteDriverLink.Create(nil);
  fDriver.DriverID := 'SQLiteDriver';

  fConnection := TFDConnection.Create(nil);

  fConnection.LoginPrompt := False;

  fConnection.Params.Clear;
  fConnection.Params.DriverID := 'SQLiteDriver';
  fConnection.Params.Database := aPath;
  fConnection.Params.Values['BusyTimeout'] := '500';

  fConnection.Connected := True;

  fConnection.ExecSQL('PRAGMA foreign_keys = ON;');
  fConnection.ExecSQL('PRAGMA journal_mode = WAL;');
  fConnection.ExecSQL('PRAGMA synchronous = NORMAL;');

  fQuery := TFDQuery.Create(nil);
  fQuery.Connection := fConnection;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TSqliteDatabase.Destroy;
begin
  fConnection.Connected := false;

  fConnection.ExecSQL('PRAGMA wal_checkpoint(TRUNCATE);');

  fConnection.Free;
  fDriver.Free;
  fQuery.Free;
end;

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

end.
