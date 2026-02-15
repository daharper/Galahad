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
  Base.Sqlite in 'Base\Base.Sqlite.pas',
  Base.Xml in 'Base\Base.Xml.pas',
  SharedKernel.Data in 'SharedKernel\SharedKernel.Data.pas',
  Domain.Game in 'Domain\Domain.Game.pas',
  Application.Language in 'Application\Application.Language.pas',
  Application.Contracts in 'Application\Application.Contracts.pas',
  Infrastructure.Data in 'Infrastructure\Infrastructure.Data.pas',
  Infrastructure.Files in 'Infrastructure\Infrastructure.Files.pas',
  Infrastructure.ConsoleApplication in 'Infrastructure\Infrastructure.ConsoleApplication.pas',
  Infrastructure.ApplicationBuilder in 'Infrastructure\Infrastructure.ApplicationBuilder.pas';

begin
  ReportMemoryLeaksOnShutdown := true;

  ApplicationBuilder.Services.AddModule(TConsoleModule.Create);

  var app := ApplicationBuilder.Build;

  try
    { test data access }

    var terms := Container.Resolve<ITermRepository>;

    for var term in terms.GetAll do
      Writeln(term.Value);

    var synonyms := Container.Resolve<ISynonymRepository>;

    for var synonym in synonyms.GetAll do
      Writeln(synonym.Value);

    { test console application build }

    app.Welcome;
    app.Execute;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
