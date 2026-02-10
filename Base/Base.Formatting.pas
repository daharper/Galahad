{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Conversions
  Author:      David Harper
  License:     MIT
  History:     2026-08-02  Initial version 0.1
  Purpose:     Provides formatting utilities.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Formatting;

interface

uses
  System.SysUtils,
  System.DateUtils;

type
  /// <summary>
  ///  Explicit, policy-driven value formatting helpers.
  /// </summary>
  /// <remarks>
  ///  Formatting methods are deliberately explicit about their semantics:
  ///  - Rounding methods use standard Delphi rounding rules
  ///  - Truncation methods never round
  ///  - Invariant variants are suitable for logs, serialization, and APIs
  /// </remarks>
  TFormat = record
  public
    { Format settings }
    /// <summary>Invariant (culture-independent) format settings.</summary>
    class function InvariantFS: TFormatSettings; static;

    { ISO 8601 (local semantics, no offset) }
    /// <summary>Formats date as YYYY-MM-DD.</summary>
    class function DateISO(const aDate: TDateTime): string; static;

    /// <summary>Formats time as hh:nn:ss (24-hour).</summary>
    class function TimeISO(const aTime: TDateTime): string; static;

    /// <summary>Formats date-time as YYYY-MM-DDThh:nn:ss.</summary>
    class function DateTimeISO(const aDateTime: TDateTime): string; static;

    /// <summary>
    ///  Formats date-time as ISO 8601 with milliseconds: YYYY-MM-DDThh:nn:ss.zzz.
    /// </summary>
    class function DateTimeISOMs(const aDateTime: TDateTime): string; static;

    { ISO 8601 (UTC, with Z) }
    /// <summary>
    ///  Formats date-time as UTC ISO 8601: YYYY-MM-DDThh:nn:ssZ.
    ///  Converts using the local system time zone.
    /// </summary>
    class function DateTimeUTCISO(const aDateTime: TDateTime): string; static;

    /// <summary>
    ///  Formats date-time as UTC ISO 8601 with milliseconds: YYYY-MM-DDThh:nn:ss.zzzZ.
    /// </summary>
    class function DateTimeUTCISOMs(const aDateTime: TDateTime): string; static;

    { Numbers (invariant, machine-friendly) }
    /// <summary>Invariant float formatting ('.' decimal separator, no thousands).</summary>
    class function FloatInv(const aValue: Double): string; static;

    /// <summary>
    ///  Invariant float formatting with fixed decimal places (rounding).
    /// </summary>
    /// <remarks>
    ///  Uses standard Delphi rounding semantics.
    ///  This method may round the value when reducing precision.
    /// </remarks>
    class function FloatInvFixed(const aValue: Double; const aDecimals: Integer): string; static;

    /// <summary>
    ///  Invariant float formatting with fixed decimal places (truncation).
    /// </summary>
    /// <remarks>
    ///  Truncates toward zero; no rounding is ever performed.
    /// </remarks>
    class function FloatInvFixedTrunc(const aValue: Double; const aDecimals: Integer): string; static;

    /// <summary>Invariant integer formatting (no thousands separators).</summary>
    class function IntInv(const aValue: Int64): string; static;

    { Display helpers (explicit FS) }
    /// <summary>Formats currency using explicit format settings.</summary>
    class function CurrencyDisp(const aValue: Currency; const aFs: TFormatSettings): string; static;

    /// <summary>
    ///  Formats a percentage using explicit FS.
    ///  Input is fractional (e.g., 0.1234 -> "12.34%").
    /// </summary>
    class function PercentDisp(const aFraction: Double; const aDecimals: Integer; const aFs: TFormatSettings): string; static;

    { Misc }
    /// <summary>Returns "True"/"False" (capitalized) regardless of locale.</summary>
    class function BoolText(const aValue: Boolean): string; static;

    /// <summary>
    ///  Quotes a string for diagnostics/logs, escaping common control characters.
    ///  Produces something like: "Hello\r\nWorld"
    /// </summary>
    class function QuoteLog(const S: string): string; static;

    { ISO 8601 with offset }
    class function DateTimeISOOffset(const aDateTime: TDateTime): string; static;
    class function DateTimeISOOffsetMs(const aDateTime: TDateTime): string; static;

    { Round-trip floats (invariant) }
    class function FloatInvRoundTrip(const aValue: Double): string; overload; static;
    class function FloatInvRoundTrip(const aValue: Single): string; overload; static;

    { GUID formatting }
    class function GuidD(const aGuid: TGUID): string; static; // 8-4-4-4-12 (no braces)
    class function GuidN(const aGuid: TGUID): string; static; // 32 hex (no braces, no hyphens)

    { Bytes formatting }
    class function BytesHex(const aBytes: TBytes): string; static;
    class function BytesBase64(const aBytes: TBytes): string; static;

    /// <summary>
    ///  Invariant money formatting with fixed decimal places (rounding).
    /// </summary>
    /// <remarks>
    ///  Uses standard Delphi Currency rounding semantics.
    ///  Suitable for presentation output where rounding is desired.
    /// </remarks>
    class function MoneyInvFixed(const aValue: Currency; const aDecimals: Integer = 2): string; static;

    /// <summary>
    ///  Invariant money formatting with fixed decimal places (truncation).
    /// </summary>
    /// <remarks>
    ///  Truncates toward zero; no rounding is ever performed.
    ///  Suitable for deterministic or regulatory-sensitive output.
    /// </remarks>
    class function MoneyInvFixedTrunc(const aValue: Currency; const aDecimals: Integer = 2): string; static;
  end;

implementation

uses
  System.Classes,
  System.Math,
  System.StrUtils,
  System.TimeSpan,
  System.NetEncoding;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.InvariantFS: TFormatSettings;
begin
  Result := TFormatSettings.Invariant;
  // Ensure no thousands separators sneak in via unexpected settings.
  Result.ThousandSeparator := #0;
end;

{ ISO 8601 (local semantics, no offset) }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateISO(const aDate: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd', aDate, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.TimeISO(const aTime: TDateTime): string;
begin
  Result := FormatDateTime('hh":"nn":"ss', aTime, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeISO(const aDateTime: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', aDateTime, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeISOMs(const aDateTime: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz', aDateTime, InvariantFS);
end;

{ ISO 8601 (UTC, with Z) }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeUTCISO(const aDateTime: TDateTime): string;
begin
  var utc := TTimeZone.Local.ToUniversalTime(aDateTime);
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"Z"', utc, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeUTCISOMs(const aDateTime: TDateTime): string;
begin
  var utc := TTimeZone.Local.ToUniversalTime(aDateTime);
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz"Z"', utc, InvariantFS);
end;

{ Numbers (invariant, machine-friendly) }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.FloatInv(const aValue: Double): string;
begin
  // General format, no thousands separators, invariant decimal separator.
  Result := FloatToStr(aValue, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.FloatInvFixed(const aValue: Double; const aDecimals: Integer): string;
begin
  Result := FormatFloat('0.' + DupeString('0', Max(0, aDecimals)), aValue, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.FloatInvFixedTrunc(const aValue: Double; const aDecimals: Integer): string;
begin
  if aDecimals <= 0 then exit(IntToStr(Trunc(aValue)));

  var pow10 := IntPower(10, aDecimals);

  // Truncate toward zero at the requested precision:
  //  12.349, Decimals=2 => 12.34
  var value: Double := Trunc(aValue * pow10) / pow10;

  Result := FormatFloat('0.' + DupeString('0', aDecimals), value, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.IntInv(const aValue: Int64): string;
begin
  // Avoid locale-dependent thousand separators: plain IntToStr is already safe,
  // but keep this for symmetry and discoverability.
  Result := IntToStr(aValue);
end;

{ Display helpers (explicit FS) }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.CurrencyDisp(const aValue: Currency; const aFs: TFormatSettings): string;
begin
  // CurrencyToStr respects aFS for separators; symbol placement is OS/FS dependent by design.
  Result := CurrToStr(aValue, aFs);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.PercentDisp(const aFraction: Double; const aDecimals: Integer; const aFs: TFormatSettings): string;
begin
  Result := FormatFloat('0.' + DupeString('0', Max(0, aDecimals)), aFraction * 100, aFs) + '%';
end;

{ Misc }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.BoolText(const aValue: Boolean): string;
begin
  Result := if aValue then 'True' else 'False';
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.QuoteLog(const S: string): string;
begin
  var builder := TStringBuilder.Create(S.Length + 2);
  try
    builder.Append('"');

    for var i := 1 to S.Length do
    begin
      var ch := S[i];
      case ch of
        '"':  builder.Append('\"');
        '\':  builder.Append('\\');
        #8:   builder.Append('\b');
        #9:   builder.Append('\t');
        #10:  builder.Append('\n');
        #12:  builder.Append('\f');
        #13:  builder.Append('\r');
      else
        if Ord(ch) < 32 then
          builder.Append('\x' + IntToHex(Ord(ch), 2))
        else
          builder.Append(ch);
      end;
    end;

    builder.Append('"');

    Result := builder.ToString;
  finally
    builder.Free;
  end;
end;

{ ISO 8601 with offset }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeISOOffset(const aDateTime: TDateTime): string;
var
  sign: Char;
begin
  var offset := TTimeZone.Local.GetUtcOffset(aDateTime);
  var totalMins: Integer := Round(offset.TotalMinutes);

  if totalMins >= 0 then
    Sign := '+'
  else
  begin
    Sign := '-';
    totalMins := -totalMins;
  end;

  var h := totalMins div 60;
  var m := totalMins mod 60;

  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', aDateTime, InvariantFS) +
            Format('%s%.2d:%.2d', [sign, h, m], InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeISOOffsetMs(const aDateTime: TDateTime): string;
var
  sign: Char;
begin
  var offset := TTimeZone.Local.GetUtcOffset(aDateTime);
  var totalMins: Integer := Round(offset.TotalMinutes);

  if totalMins >= 0 then
      sign := '+'
  else
  begin
    sign := '-';
    totalMins := -totalMins;
  end;

  var h := totalMins div 60;
  var m := totalMins mod 60;

  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz', aDateTime, InvariantFS) +
            Format('%s%.2d:%.2d', [sign, h, m], InvariantFS);
end;

{ Round-trip floats (invariant) }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.FloatInvRoundTrip(const aValue: Double): string;
begin
  // 17 significant digits is the common round-trip safe precision for IEEE-754 double
  Result := FloatToStrF(aValue, ffGeneral, 17, 0, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.FloatInvRoundTrip(const aValue: Single): string;
begin
  // 9 significant digits is typically round-trip safe for IEEE-754 single
  Result := FloatToStrF(aValue, ffGeneral, 9, 0, InvariantFS);
end;

{ GUID formatting }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.GuidD(const aGuid: TGUID): string;
begin
  // GUIDToString => "{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}"
  var s := GUIDToString(aGuid);
  Result := Copy(s, 2, s.Length - 2); // strip braces
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.GuidN(const aGuid: TGUID): string;
begin
  Result := StringReplace(GuidD(aGuid), '-', '', [rfReplaceAll]);
end;

{ Bytes formatting }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.BytesHex(const aBytes: TBytes): string;
begin
  if Length(aBytes) = 0 then exit('');

  SetLength(Result, Length(aBytes) * 2);

  // BinToHex produces uppercase hex
  BinToHex(@aBytes[0], PChar(Result), Length(aBytes));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.BytesBase64(const aBytes: TBytes): string;
begin
  if Length(aBytes) = 0 then exit('');

  Result := TNetEncoding.Base64.EncodeBytesToString(aBytes);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.MoneyInvFixed(const aValue: Currency; const aDecimals: Integer): string;
begin
  if (aDecimals < 0) or (aDecimals > 4) then
    raise EArgumentOutOfRangeException.Create('Decimals must be in 0..4 for Currency.');

  var mask := if aDecimals = 0 then '0' else '0.' + DupeString('0', aDecimals);

  Result := FormatCurr(mask, aValue, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.MoneyInvFixedTrunc(const aValue: Currency; const aDecimals: Integer): string;
var
  scale: Int64;
begin
  if (aDecimals < 0) or (aDecimals > 4) then
    raise EArgumentOutOfRangeException.Create('Decimals must be in 0..4 for Currency.');

  // Currency is fixed-point scaled by 10000 in storage.
  // We truncate toward zero to the requested decimal count.
  case aDecimals of
    0: scale := 10000;
    1: scale := 1000;
    2: scale := 100;
    3: scale := 10;
    4: scale := 1;
  else
    scale := 100; // unreachable
  end;

  // Convert to scaled Int64, truncate, then convert back.
  // Value * 10000 is exact for Currency.
  var scaled: Int64 := Round(aValue * 10000);      // exact for Currency values
  var truncScaled: Int64 := (scaled div scale) * scale;

  var mask := if aDecimals = 0 then '0' else '0.' + DupeString('0', aDecimals);

  Result := FormatCurr(mask, truncScaled / 10000.0, InvariantFS);
end;

end.

