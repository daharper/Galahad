unit Tests.Core.Formatting;

{
  DUnitX tests for Base.Formatting.pas (TFormat)

  - Single fixture: FormattingFixture
  - One test method per group:
      IsoLocalTests, IsoUtcTests, NumberTests, DisplayTests, BoolAndQuoteTests

  Assumptions:
    - You have DUnitX in your test project
    - Your production unit is named: Base.Formatting
    - Public API is: Base.Formatting.TFormat
}

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  FormattingFixture = class
  public
    [Test] procedure IsoLocalTests;
    [Test] procedure IsoUtcTests;
    [Test] procedure NumberTests;
    [Test] procedure DisplayTests;
    [Test] procedure BoolAndQuoteTests;
    [Test] procedure IsoOffsetTests;
    [Test] procedure RoundTripFloatTests;
    [Test] procedure GuidAndBytesTests;
    [Test] procedure MoneyTests;
  end;

implementation

uses
  System.SysUtils,
  System.TimeSpan,
  System.DateUtils,
  Base.Conversions,
  Base.Formatting;

{ FormattingFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure FormattingFixture.IsoLocalTests;
var
  DT: TDateTime;
begin
  DT := EncodeDate(2026, 2, 9) + EncodeTime(14, 30, 5, 0);

  Assert.AreEqual('2026-02-09', TFormat.DateISO(DT));
  Assert.AreEqual('14:30:05',   TFormat.TimeISO(DT));
  Assert.AreEqual('2026-02-09T14:30:05', TFormat.DateTimeISO(DT));

  DT := EncodeDate(2026, 2, 9) + EncodeTime(14, 30, 5, 123);
  Assert.AreEqual('2026-02-09T14:30:05.123', TFormat.DateTimeISOMs(DT));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure FormattingFixture.IsoUtcTests;
var
  LocalDT, UtcDT: TDateTime;
  S: string;
begin
  // Pick a local datetime with no milliseconds for stable string checks
  LocalDT := EncodeDate(2026, 2, 9) + EncodeTime(14, 30, 5, 0);

  // Compute expected UTC via the same mechanism used in TFormat, then compare formatting.
  UtcDT := TTimeZone.Local.ToUniversalTime(LocalDT);
  S := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"Z"', UtcDT, TFormat.InvariantFS);

  Assert.AreEqual(S, TFormat.DateTimeUTCISO(LocalDT));

  // Milliseconds variant
  LocalDT := EncodeDate(2026, 2, 9) + EncodeTime(14, 30, 5, 456);
  UtcDT := TTimeZone.Local.ToUniversalTime(LocalDT);
  S := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz"Z"', UtcDT, TFormat.InvariantFS);

  Assert.AreEqual(S, TFormat.DateTimeUTCISOMs(LocalDT));

  // Basic shape checks
  Assert.IsTrue(TFormat.DateTimeUTCISO(LocalDT).EndsWith('Z'));
  Assert.IsTrue(TFormat.DateTimeUTCISOMs(LocalDT).EndsWith('Z'));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure FormattingFixture.NumberTests;
var
  S: string;
begin
  // IntInv
  Assert.AreEqual('0', TFormat.IntInv(0));
  Assert.AreEqual('-123', TFormat.IntInv(-123));
  Assert.AreEqual('9223372036854775807', TFormat.IntInv(Int64(9223372036854775807)));

  // FloatInv (invariant '.' decimal separator)
  S := TFormat.FloatInv(3.5);
  Assert.IsTrue(S.Contains('.'));
  Assert.IsFalse(S.Contains(',')); // should never use comma as decimal separator under invariant settings

  // FloatInvFixed
  Assert.AreEqual('3.50', TFormat.FloatInvFixed(3.5, 2));
  Assert.AreEqual('4',    TFormat.FloatInvFixed(3.5, 0));
  Assert.AreEqual('0.000',TFormat.FloatInvFixed(0, 3));

  // FloatInvFixedTrunc
  Assert.AreEqual('3', TFormat.FloatInvFixedTrunc(3.5, 0));
  Assert.AreEqual('12.34', TFormat.FloatInvFixedTrunc(12.349, 2));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure FormattingFixture.DisplayTests;
var
  FS: TFormatSettings;
  S: string;
begin
  // Use en-GB for deterministic decimal separator '.' in most installs,
  // but keep it explicit anyway.
  FS := TFormatSettings.Create('en-GB');

  // CurrencyDisp: output can vary by currency symbol settings, so don't assert the symbol.
  // Instead assert it contains the numeric portion and respects decimal separator for en-GB.
  S := TFormat.CurrencyDisp(12.34, FS);
  Assert.IsTrue(S.Contains('12'));
  Assert.IsTrue(S.Contains(FS.DecimalSeparator));

  // PercentDisp: should multiply by 100 and append '%'
  Assert.AreEqual('12.34%', TFormat.PercentDisp(0.1234, 2, FS));
  Assert.AreEqual('0%',     TFormat.PercentDisp(0.0, 0, FS));
  Assert.IsTrue(TFormat.PercentDisp(1.0, 0, FS).EndsWith('%'));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure FormattingFixture.BoolAndQuoteTests;
begin
  // BoolText
  Assert.AreEqual('True',  TFormat.BoolText(True));
  Assert.AreEqual('False', TFormat.BoolText(False));

  // QuoteLog basics
  Assert.AreEqual('""', TFormat.QuoteLog(''));
  Assert.AreEqual('"ABC"', TFormat.QuoteLog('ABC'));

  // Escapes
  Assert.AreEqual('"\""', TFormat.QuoteLog('"'));
  Assert.AreEqual('"\\\""', TFormat.QuoteLog('\"')); // backslash then quote in source => \"

  Assert.AreEqual('"\r"', TFormat.QuoteLog(#13));
  Assert.AreEqual('"\n"', TFormat.QuoteLog(#10));
  Assert.AreEqual('"\t"', TFormat.QuoteLog(#9));

  // Control chars < 32 (that aren't explicitly mapped) => \xNN
  Assert.AreEqual('"\x01"', TFormat.QuoteLog(#1));

  // Mixed string
  Assert.AreEqual('"Hello\r\nWorld"', TFormat.QuoteLog('Hello' + sLineBreak + 'World'));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure FormattingFixture.IsoOffsetTests;
var
  DT: TDateTime;
  Offset: TTimeSpan;
  TotalMins: Integer;
  Sign: Char;
  H, M: Integer;
  Expected: string;
begin
  DT := EncodeDate(2026, 2, 9) + EncodeTime(14, 30, 5, 0);

  Offset := TTimeZone.Local.GetUtcOffset(DT);
  TotalMins := Round(Offset.TotalMinutes);

  if TotalMins < 0 then
  begin
    Sign := '-';
    TotalMins := -TotalMins;
  end
  else
    Sign := '+';

  H := TotalMins div 60;
  M := TotalMins mod 60;

  Expected :=
    FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', DT, TFormat.InvariantFS) +
    Format('%s%.2d:%.2d', [Sign, H, M], TFormat.InvariantFS);

  Assert.AreEqual(Expected, TFormat.DateTimeISOOffset(DT));
  Assert.IsTrue(TFormat.DateTimeISOOffset(DT).Contains('+') or TFormat.DateTimeISOOffset(DT).Contains('-'));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure FormattingFixture.RoundTripFloatTests;
var
  S: string;
  D: Double;
  F: Single;
  FS: TFormatSettings;
begin
  FS := TFormat.InvariantFS;

  // Double round-trip
  S := TFormat.FloatInvRoundTrip(0.1);
  Assert.IsTrue(TConvert.TryToDouble(S, D, FS));
  Assert.AreEqual(0.1, D, 0);

  // Single round-trip
  S := TFormat.FloatInvRoundTrip(Single(0.1));
  Assert.IsTrue(TConvert.TryToSingle(S, F, FS));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure FormattingFixture.GuidAndBytesTests;
var
  G: TGUID;
  D, N: string;
  Bytes: TBytes;
begin
  G := TGUID.Create('{6F9619FF-8B86-D011-B42D-00C04FC964FF}');

  D := TFormat.GuidD(G);
  N := TFormat.GuidN(G);

  Assert.IsFalse(D.StartsWith('{'));
  Assert.IsFalse(D.EndsWith('}'));
  Assert.IsTrue(D.Contains('-'));
  Assert.AreEqual(32, N.Length);
  Assert.IsFalse(N.Contains('-'));

  Bytes := TBytes.Create($01, $02, $03, $FF);
  Assert.AreEqual('010203FF', TFormat.BytesHex(Bytes));

  // Base64 for 01 02 03 FF => AQID/w==
  Assert.AreEqual('AQID/w==', TFormat.BytesBase64(Bytes));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure FormattingFixture.MoneyTests;
begin
  Assert.AreEqual('12.30', TFormat.MoneyInvFixed(Currency(12.3), 2));
  Assert.AreEqual('12.34', TFormat.MoneyInvFixed(Currency(12.34), 2));
  Assert.AreEqual('-0.05', TFormat.MoneyInvFixed(Currency(-0.05), 2));

  Assert.AreEqual('13', TFormat.MoneyInvFixed(Currency(12.9), 0));
  Assert.AreEqual('12', TFormat.MoneyInvFixedTrunc(Currency(12.9), 0));
  Assert.AreEqual('12.9000', TFormat.MoneyInvFixed(Currency(12.9), 4));
end;

initialization
  TDUnitX.RegisterTestFixture(FormattingFixture);

end.

