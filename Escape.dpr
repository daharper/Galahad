program Escape;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Base.Collections in 'Base\Base.Collections.pas',
  Base.Container in 'Base\Base.Container.pas',
  Base.Conversions in 'Base\Base.Conversions.pas',
  Base.Core in 'Base\Base.Core.pas',
  Base.Dynamic in 'Base\Base.Dynamic.pas',
  Base.Formatting in 'Base\Base.Formatting.pas',
  Base.Integrity in 'Base\Base.Integrity.pas',
  Base.Json in 'Base\Base.Json.pas',
  Base.Messaging in 'Base\Base.Messaging.pas',
  Base.Reflection in 'Base\Base.Reflection.pas',
  Base.Specifications in 'Base\Base.Specifications.pas',
  Base.Stream in 'Base\Base.Stream.pas',
  Base.Xml in 'Base\Base.Xml.pas',
  SharedKernel.Data in 'SharedKernel\SharedKernel.Data.pas',
  Application.Language in 'Application\Application.Language.pas',
  Infrastructure.ConsoleApplication in 'Infrastructure\Infrastructure.ConsoleApplication.pas',
  Application.Contracts in 'Application\Application.Contracts.pas',
  Domain.Game in 'Domain\Domain.Game.pas',
  Infrastructure.ApplicationBuilder in 'Infrastructure\Infrastructure.ApplicationBuilder.pas';

begin
  ReportMemoryLeaksOnShutdown := true;

  ApplicationBuilder.Services.AddModule(TConsoleApplicationModule.Create);

  var app := ApplicationBuilder.Build;

  try
    app.Welcome;
    app.Execute;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
