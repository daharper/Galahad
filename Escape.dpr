program Escape;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Generics.Collections,
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
  Domain.Game in 'Domain\Domain.Game.pas',
  Infrastructure.Data in 'Infrastructure\Infrastructure.Data.pas',
  Base.Files in 'Base\Base.Files.pas',
  Base.Data in 'Base\Base.Data.pas',
  Application.UseCases.StartGame in 'Application.UseCases\Application.UseCases.StartGame.pas',
  Domain.Terms in 'Domain\Domain.Terms.pas',
  Application.Language in 'Application\Application.Language.pas',
  Application.Parsing in 'Application\Application.Parsing.pas',
  Console.Application in 'Console\Console.Application.pas',
  Console.Composition in 'Console\Console.Composition.pas',
  Infrastructure.Migrations in 'Infrastructure\Infrastructure.Migrations.pas',
  Base.Application in 'Base\Base.Application.pas',
  Base.Settings in 'Base\Base.Settings.pas';

begin
  ReportMemoryLeaksOnShutdown := true;

  ApplicationBuilder.Services.AddModule<TConsoleModule>;
  ApplicationBuilder.LoadSettings;

  ApplicationBuilder.ConfigureDatabase;
  ApplicationBuilder.PerformMigrations;

  var app := ApplicationBuilder.Build;

  app.Execute;
end.
