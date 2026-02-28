program Galahad;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  {$ENDIF }
  DUnitX.TestFramework,
  Tests.Integrity.Option in 'Tests.Integrity\Tests.Integrity.Option.pas',
  Base.Integrity in 'Base\Base.Integrity.pas',
  Base.Core in 'Base\Base.Core.pas',
  Tests.Integrity.Result in 'Tests.Integrity\Tests.Integrity.Result.pas',
  Tests.Core.Messaging in 'Tests.Core\Tests.Core.Messaging.pas',
  Tests.Integrity.Ensure in 'Tests.Integrity\Tests.Integrity.Ensure.pas',
  Tests.Integrity.ResultOp in 'Tests.Integrity\Tests.Integrity.ResultOp.pas',
  Tests.Integrity.Scope in 'Tests.Integrity\Tests.Integrity.Scope.pas',
  Tests.Core.Let in 'Tests.Core\Tests.Core.Let.pas',
  Base.Collections in 'Base\Base.Collections.pas',
  Tests.Core.Collect in 'Tests.Core\Tests.Core.Collect.pas',
  Base.Messaging in 'Base\Base.Messaging.pas',
  Base.Stream in 'Base\Base.Stream.pas',
  Tests.Core.Stream in 'Tests.Core\Tests.Core.Stream.pas',
  Base.Specifications in 'Base\Base.Specifications.pas',
  Tests.Core.Specifications in 'Tests.Core\Tests.Core.Specifications.pas',
  Mocks.Entities in 'Mocks\Mocks.Entities.pas',
  Mocks.Repositories in 'Mocks\Mocks.Repositories.pas',
  Mocks.Specifications in 'Mocks\Mocks.Specifications.pas',
  Base.Reflection in 'Base\Base.Reflection.pas',
  Tests.Core.Reflection in 'Tests.Core\Tests.Core.Reflection.pas',
  Base.Dynamic in 'Base\Base.Dynamic.pas',
  Tests.Core.Dynamic in 'Tests.Core\Tests.Core.Dynamic.pas',
  Base.Container in 'Base\Base.Container.pas',
  Tests.Container.Registration in 'Tests.Container\Tests.Container.Registration.pas',
  Mocks.Container in 'Mocks\Mocks.Container.pas',
  Tests.Container.ResolveRegistered in 'Tests.Container\Tests.Container.ResolveRegistered.pas',
  Tests.Container.ModuleRegistration in 'Tests.Container\Tests.Container.ModuleRegistration.pas',
  Tests.Container.Resolve in 'Tests.Container\Tests.Container.Resolve.pas',
  Mocks.Messaging in 'Mocks\Mocks.Messaging.pas',
  Base.Xml in 'Base\Base.Xml.pas',
  Base.Conversions in 'Base\Base.Conversions.pas',
  Tests.Core.Conversions in 'Tests.Core\Tests.Core.Conversions.pas',
  Base.Formatting in 'Base\Base.Formatting.pas',
  Tests.Core.Formatting in 'Tests.Core\Tests.Core.Formatting.pas',
  Tests.Core.Xml in 'Tests.Core\Tests.Core.Xml.pas',
  Base.Json in 'Base\Base.Json.pas',
  Base.Sqlite in 'Base\Base.Sqlite.pas',
  Base.Data in 'Base\Base.Data.pas',
  Base.Files in 'Base\Base.Files.pas',
  Base.Settings in 'Base\Base.Settings.pas';

{ keep comment here to protect the following conditional from being removed by the IDE when adding a unit }
{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger : ITestLogger;
{$ENDIF}
begin
  ReportMemoryLeaksOnShutdown := true;

{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.
