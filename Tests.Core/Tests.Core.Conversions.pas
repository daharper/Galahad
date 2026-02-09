unit Tests.Core.Conversions;

interface

uses
  DUnitX.TestFramework,
  Base.Conversions;

type
  TTestEnum = (teAlpha, teBeta, teGamma);

  [TestFixture]
  ConversionsFixture = class
  public
    [Test] procedure IntegerTests;
    [Test] procedure BooleanTests;
    [Test] procedure FloatTests;
    [Test] procedure DateTimeTests;
    [Test] procedure Iso8601Tests;
    [Test] procedure CharTests;
    [Test] procedure UIntTests;
    [Test] procedure GuidTests;
    [Test] procedure EnumTests;
    [Test] procedure CurrencyTests;
    [Test] procedure BytesTests;
    [Test] procedure MoneyTests;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils;

{ ConversionsFixture }

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.IntegerTests;
var
  I: Integer;
  L: Int64;
begin
  // TryToInt
  Assert.IsTrue(TConvert.TryToInt('42', I));
  Assert.AreEqual(42, I);
  Assert.IsFalse(TConvert.TryToInt('12 rubbish', I));

  // ToIntOr / ToIntDef
  Assert.AreEqual(42, TConvert.ToIntOr('42', -1));
  Assert.AreEqual(-1, TConvert.ToIntOr('oops', -1));
  Assert.AreEqual(0, TConvert.ToIntDef('oops'));
  Assert.AreEqual(123, TConvert.ToIntDef('123'));

  // ToInt (strict, raises)
  Assert.WillNotRaise(procedure begin I := TConvert.ToInt('7'); Assert.AreEqual(7, I); end);

  Assert.WillRaise(procedure begin I := TConvert.ToInt('7x'); end, EStrictConvertError);

  // Int64 variants
  Assert.IsTrue(TConvert.TryToInt64('9223372036854775807', L));
  Assert.AreEqual(Int64(9223372036854775807), L);
  Assert.IsFalse(TConvert.TryToInt64('9223372036854775808', L)); // overflow

  Assert.AreEqual(Int64(5), TConvert.ToInt64Or('5', -1));
  Assert.AreEqual(Int64(-1), TConvert.ToInt64Or('nope', -1));
  Assert.AreEqual(Int64(0), TConvert.ToInt64Def('nope'));

  Assert.WillRaise(procedure begin L := TConvert.ToInt64('nope'); end, EStrictConvertError);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.BooleanTests;
var
  B: Boolean;
begin
  // TryToBool
  Assert.IsTrue(TConvert.TryToBool('True', B));
  Assert.IsTrue(B);

  Assert.IsTrue(TConvert.TryToBool('FALSE', B));
  Assert.IsFalse(B);

  Assert.IsTrue(TConvert.TryToBool('1', B));
  Assert.IsTrue(B);

  Assert.IsTrue(TConvert.TryToBool('0', B));
  Assert.IsFalse(B);

  Assert.IsFalse(TConvert.TryToBool('yes', B)); // not accepted by TryStrToBool

  // ToBoolOr / ToBoolDef
  Assert.IsTrue(TConvert.ToBoolOr('true', False));
  Assert.IsFalse(TConvert.ToBoolOr('nope', False));
  Assert.IsFalse(TConvert.ToBoolDef('nope'));
  Assert.IsTrue(TConvert.ToBoolDef('true'));

  // ToBool (strict, raises)
  Assert.WillNotRaise(procedure begin B := TConvert.ToBool('0'); Assert.IsFalse(B); end);

  Assert.WillRaise(procedure begin B := TConvert.ToBool('yes'); end, EStrictConvertError);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.FloatTests;
var
  FSInv, FSGb: TFormatSettings;
  Sng: Single;
  Dbl: Double;
  Ext: Extended;
begin
  FSInv := TConvert.InvariantFS;
  FSGb := TFormatSettings.Create('en-GB');

  // TryToDouble (explicit FS)
  Assert.IsTrue(TConvert.TryToDouble('3.5', Dbl, FSInv));
  Assert.AreEqual(3.5, Dbl, 1e-12);

  Assert.IsFalse(TConvert.TryToDouble('3,5', Dbl, FSInv)); // invariant expects '.'

  // Invariant helpers
  Assert.IsTrue(TConvert.TryToDoubleInv('2.25', Dbl));
  Assert.AreEqual(2.25, Dbl, 1e-12);

  Assert.AreEqual(2.25, TConvert.ToDoubleOrInv('2.25', -1.0), 1e-12);
  Assert.AreEqual(-1.0, TConvert.ToDoubleOrInv('bad', -1.0), 1e-12);
  Assert.AreEqual(0.0, TConvert.ToDoubleDefInv('bad'), 1e-12);

  Assert.WillRaise(procedure begin Dbl := TConvert.ToDoubleInv('1.2x'); end, EStrictConvertError);

  // Single / Extended (explicit FS)
  Assert.IsTrue(TConvert.TryToSingle('1.25', Sng, FSInv));
  Assert.AreEqual(1.25, Sng, 1e-6);

  Assert.IsTrue(TConvert.TryToExtended('10.5', Ext, FSInv));
  Assert.AreEqual(10.5, Ext, 1e-12);

  // ToXxxOr / ToXxxDef / ToXxx (explicit FS)
  Assert.AreEqual(1.25, TConvert.ToSingleOr('1.25', -1, FSInv), 1e-6);
  Assert.AreEqual(-1.0, TConvert.ToDoubleOr('bad', -1.0, FSInv), 1e-12);
  Assert.AreEqual(0.0, TConvert.ToExtendedDef('bad', FSInv), 1e-12);

  Assert.WillNotRaise(procedure begin Dbl := TConvert.ToDouble('3.14', FSInv); Assert.AreEqual(3.14, Dbl, 1e-12); end);

  Assert.WillRaise(procedure begin Dbl := TConvert.ToDouble('3,14', FSInv); end, EStrictConvertError);

  // Locale sanity check (en-GB usually uses '.', but keep it explicit anyway)
  Assert.IsTrue(TConvert.TryToDouble('3.14', Dbl, FSGb));
  Assert.AreEqual(3.14, Dbl, 1e-12);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.DateTimeTests;
var
  FS: TFormatSettings;
  DT: TDateTime;
  DefaultDT: TDateTime;
begin
  FS := TFormatSettings.Create('en-GB');
  DefaultDT := EncodeDate(2000, 1, 1) + EncodeTime(12, 0, 0, 0);

  // TryToDateTime / TryToDate / TryToTime
  Assert.IsTrue(TConvert.TryToDateTime('09/02/2026 14:30:00', DT, FS));
  Assert.AreEqual(EncodeDate(2026, 2, 9) + EncodeTime(14, 30, 0, 0), DT, 1e-8);

  Assert.IsFalse(TConvert.TryToDateTime('09/02/2026 14:30:00 rubbish', DT, FS));

  Assert.IsTrue(TConvert.TryToDate('09/02/2026', DT, FS));
  Assert.AreEqual(EncodeDate(2026, 2, 9), DT, 1e-8);

  Assert.IsTrue(TConvert.TryToTime('14:30:00', DT, FS));
  Assert.AreEqual(EncodeTime(14, 30, 0, 0), DT, 1e-8);

  // Or / Def
  Assert.AreEqual(
    EncodeDate(2026, 2, 9) + EncodeTime(14, 30, 0, 0),
    TConvert.ToDateTimeOr('09/02/2026 14:30:00', DefaultDT, FS),
    1e-8);

  Assert.AreEqual(DefaultDT, TConvert.ToDateTimeOr('bad', DefaultDT, FS), 1e-8);

  Assert.AreEqual(0.0, TConvert.ToDateTimeDef('bad', FS), 1e-8);

  // Strict (raises)
  Assert.WillNotRaise(procedure begin DT := TConvert.ToDateTime('09/02/2026 14:30:00', FS); end);

  Assert.WillRaise(procedure begin DT := TConvert.ToDateTime('09/02/2026 bad', FS); end, EStrictConvertError);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.Iso8601Tests;
var
  DT: TDateTime;
begin
  // Try
  Assert.IsTrue(TConvert.TryToDateTimeISO8601('2026-02-09T14:30:00', DT));
  Assert.AreEqual(EncodeDate(2026, 2, 9) + EncodeTime(14, 30, 0, 0), DT, 1e-8);

  Assert.IsFalse(TConvert.TryToDateTimeISO8601('2026-02-09T14:30:00 rubbish', DT));

  // Or / Def
  Assert.AreEqual(
    EncodeDate(2026, 2, 9) + EncodeTime(14, 30, 0, 0), TConvert.ToDateTimeOrISO8601('2026-02-09T14:30:00', 0), 1e-8);

  Assert.AreEqual(EncodeDate(1999, 12, 31), TConvert.ToDateTimeOrISO8601('bad', EncodeDate(1999, 12, 31)), 1e-8);

  Assert.AreEqual(0.0, TConvert.ToDateTimeDefISO8601('bad'), 1e-8);

  // Strict (raises)
  Assert.WillNotRaise(procedure begin DT := TConvert.ToDateTimeISO8601('2026-02-09T14:30:00'); end);

  Assert.WillRaise(procedure begin DT := TConvert.ToDateTimeISO8601('nope'); end, EStrictConvertError);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.CharTests;
var
  C: Char;
begin
  // Try
  Assert.IsTrue(TConvert.TryToChar('A', C));
  Assert.AreEqual('A', C);

  Assert.IsFalse(TConvert.TryToChar('', C));
  Assert.IsFalse(TConvert.TryToChar('AB', C));

  // Or / Def
  Assert.AreEqual('Z', TConvert.ToCharOr('Z', '?'));
  Assert.AreEqual('?', TConvert.ToCharOr('', '?'));
  Assert.AreEqual(#0, TConvert.ToCharDef(''));
  Assert.AreEqual('X', TConvert.ToCharDef('X'));

  // Strict (raises)
  Assert.WillNotRaise(procedure begin C := TConvert.ToChar('Q'); Assert.AreEqual('Q', C); end);

  Assert.WillRaise(procedure begin C := TConvert.ToChar('QQ'); end, EStrictConvertError);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.UIntTests;
var
  U32: Cardinal;
  U64: UInt64;
begin
  Assert.IsTrue(TConvert.TryToUInt32('0', U32));
  Assert.AreEqual(Cardinal(0), U32);

  Assert.IsTrue(TConvert.TryToUInt32('4294967295', U32));
  Assert.AreEqual(High(Cardinal), U32);

  Assert.IsFalse(TConvert.TryToUInt32('4294967296', U32));
  Assert.IsFalse(TConvert.TryToUInt32('-1', U32));
  Assert.IsFalse(TConvert.TryToUInt32('12 rubbish', U32));

  Assert.IsTrue(TConvert.TryToUInt64('18446744073709551615', U64));
  Assert.AreEqual(High(UInt64), U64);

  Assert.IsFalse(TConvert.TryToUInt64('18446744073709551616', U64));
  Assert.IsFalse(TConvert.TryToUInt64('-1', U64));

  Assert.AreEqual(UInt64(7), TConvert.ToUInt64Or('7', 99));
  Assert.AreEqual(UInt64(99), TConvert.ToUInt64Or('bad', 99));

  Assert.WillRaise(procedure begin U64 := TConvert.ToUInt64('bad'); end, EStrictConvertError);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.GuidTests;
var
  G, D: TGUID;
begin
  D := TGUID.Empty;

  Assert.IsTrue(TConvert.TryToGuid('{6F9619FF-8B86-D011-B42D-00C04FC964FF}', G));
  Assert.IsFalse(TConvert.TryToGuid('not-a-guid', G));

  Assert.AreNotEqual(D, TConvert.ToGuidOr('{6F9619FF-8B86-D011-B42D-00C04FC964FF}', D));
  Assert.AreEqual(D, TConvert.ToGuidOr('bad', D));
  Assert.AreEqual(D, TConvert.ToGuidDef('bad'));

  Assert.WillRaise(procedure begin G := TConvert.ToGuid('bad'); end, EStrictConvertError);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.EnumTests;
var
  E: TTestEnum;
begin
  Assert.IsTrue(TConvert.TryToEnum<TTestEnum>('teAlpha', E));
  Assert.AreEqual(TTestEnum.teAlpha, E);

  // Case-insensitive by default
  Assert.IsTrue(TConvert.TryToEnum<TTestEnum>('TEBETA', E));
  Assert.AreEqual(TTestEnum.teBeta, E);

  // Ordinals disabled by default
  Assert.IsFalse(TConvert.TryToEnum<TTestEnum>('1', E));

  // Ordinals enabled explicitly
  Assert.IsTrue(TConvert.TryToEnum<TTestEnum>('1', E, True, True));
  Assert.AreEqual(TTestEnum.teBeta, E);

  Assert.AreEqual(TTestEnum.teGamma, TConvert.ToEnumOr<TTestEnum>('nope', TTestEnum.teGamma));
  Assert.WillRaise(procedure begin E := TConvert.ToEnum<TTestEnum>('nope'); end, EStrictConvertError);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.CurrencyTests;
var
  FS: TFormatSettings;
  C: Currency;
begin
  FS := TFormatSettings.Create('en-GB');

  Assert.IsTrue(TConvert.TryToCurrency('12.34', C, FS));
  Assert.AreEqual(Currency(12.34), C);

  Assert.IsFalse(TConvert.TryToCurrency('12.34 rubbish', C, FS));

  Assert.IsTrue(TConvert.TryToCurrencyInv('12.34', C));
  Assert.AreEqual(Currency(12.34), C);

  Assert.AreEqual(Currency(9.99), TConvert.ToCurrencyOr('bad', 9.99, FS));
  Assert.AreEqual(Currency(0), TConvert.ToCurrencyDef('bad', FS));

  Assert.WillRaise(procedure begin C := TConvert.ToCurrency('bad', FS); end, EStrictConvertError);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.BytesTests;
var
  B: TBytes;
  Default: TBytes;
begin
  Default := TBytes.Create($AA);

  Assert.IsTrue(TConvert.TryToBytesHex('0A0bFF', B));
  Assert.AreEqual(3, Length(B));
  Assert.AreEqual(Byte($0A), B[0]);
  Assert.AreEqual(Byte($0B), B[1]);
  Assert.AreEqual(Byte($FF), B[2]);

  Assert.IsFalse(TConvert.TryToBytesHex('0A0', B));     // odd length
  Assert.IsFalse(TConvert.TryToBytesHex('0A0X', B));    // invalid char

  Assert.IsTrue(TConvert.TryToBytesBase64('AQID', B));  // 01 02 03
  Assert.AreEqual(3, Length(B));
  Assert.AreEqual(Byte(1), B[0]);
  Assert.AreEqual(Byte(2), B[1]);
  Assert.AreEqual(Byte(3), B[2]);

  Assert.IsFalse(TConvert.TryToBytesBase64('**notbase64**', B));

  Assert.AreEqual(Byte($AA), TConvert.ToBytesHexOr('bad', Default)[0]);

  Assert.WillRaise(procedure begin B := TConvert.ToBytesHex('bad'); end, EStrictConvertError);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure ConversionsFixture.MoneyTests;
var
  FS: TFormatSettings;
  C: Currency;
begin
  FS := TFormatSettings.Create('en-GB');

  // Valid (0..2 fractional digits)
  Assert.IsTrue(TConvert.TryToMoney('12', C, 2, FS));
  Assert.AreEqual(Currency(12.0), C);

  Assert.IsTrue(TConvert.TryToMoney('12.', C, 2, FS));
  Assert.AreEqual(Currency(12.0), C);

  Assert.IsTrue(TConvert.TryToMoney('12.3', C, 2, FS));
  Assert.AreEqual(Currency(12.3), C);

  Assert.IsTrue(TConvert.TryToMoney('+12.34', C, 2, FS));
  Assert.AreEqual(Currency(12.34), C);

  Assert.IsTrue(TConvert.TryToMoney('-0.05', C, 2, FS));
  Assert.AreEqual(Currency(-0.05), C);

  // Reject too many fractional digits (no rounding)
  Assert.IsFalse(TConvert.TryToMoney('12.345', C, 2, FS));

  // Reject thousands separators / spaces / symbols
  Assert.IsFalse(TConvert.TryToMoney('1,234.56', C, 2, FS));
  Assert.IsFalse(TConvert.TryToMoney('1 234.56', C, 2, FS));
  Assert.IsFalse(TConvert.TryToMoney('£12.34', C, 2, FS));
  Assert.IsFalse(TConvert.TryToMoney('12.34£', C, 2, FS));

  // Reject junk / multiple separators
  Assert.IsFalse(TConvert.TryToMoney('12.34 rubbish', C, 2, FS));
  Assert.IsFalse(TConvert.TryToMoney('12.3.4', C, 2, FS));

  // Invariant helper
  Assert.IsTrue(TConvert.TryToMoneyInv('1234.50', C, 2));
  Assert.AreEqual(Currency(1234.5), C);

  // Or/Def/Strict
  Assert.AreEqual(Currency(9.99), TConvert.ToMoneyOr('bad', 9.99, 2, FS));
  Assert.AreEqual(Currency(0), TConvert.ToMoneyDef('bad', 2, FS));

  Assert.WillRaise(procedure begin C := TConvert.ToMoney('bad', 2, FS); end, EStrictConvertError);
end;

initialization
  TDUnitX.RegisterTestFixture(ConversionsFixture);

end.

