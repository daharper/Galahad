unit Infrastructure.ConsoleApplication;

interface

uses
  Base.Core,
  Base.Container,
  Application.Contracts;

type
  /// <summary>
  ///  Registers services with the application builder.
  /// </summary>
  TConsoleModule = class(TInterfacedObject, IContainerModule)
  public
    procedure RegisterServices(const aContainer: TContainer);
  end;

  /// <summary>
  ///  The console application.
  /// </summary>
  TConsoleApplication = class(TSingleton, IApplication)
  private
    procedure Welcome;
    procedure Execute;
  end;

implementation

{ TConsole }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleApplication.Execute;
begin
  Writeln('Running');
  Readln;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleApplication.Welcome;
begin
  Writeln('Press Q to quit, T for Terms, S for Synonyms');
end;

{ TConsoleModule }

{----------------------------------------------------------------------------------------------------------------------}
procedure TConsoleModule.RegisterServices(const aContainer: TContainer);
begin
  aContainer.Add<IApplication, TConsoleApplication>(Singleton);
end;

end.
