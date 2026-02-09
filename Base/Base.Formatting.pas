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
    class function DateISO(const D: TDateTime): string; static;

    /// <summary>Formats time as hh:nn:ss (24-hour).</summary>
    class function TimeISO(const T: TDateTime): string; static;

    /// <summary>Formats date-time as YYYY-MM-DDThh:nn:ss.</summary>
    class function DateTimeISO(const DT: TDateTime): string; static;

    /// <summary>
    ///  Formats date-time as ISO 8601 with milliseconds: YYYY-MM-DDThh:nn:ss.zzz.
    /// </summary>
    class function DateTimeISOMs(const DT: TDateTime): string; static;

    { ISO 8601 (UTC, with Z) }
    /// <summary>
    ///  Formats date-time as UTC ISO 8601: YYYY-MM-DDThh:nn:ssZ.
    ///  Converts using the local system time zone.
    /// </summary>
    class function DateTimeUTCISO(const DT: TDateTime): string; static;

    /// <summary>
    ///  Formats date-time as UTC ISO 8601 with milliseconds: YYYY-MM-DDThh:nn:ss.zzzZ.
    /// </summary>
    class function DateTimeUTCISOMs(const DT: TDateTime): string; static;

    { Numbers (invariant, machine-friendly) }
    /// <summary>Invariant float formatting ('.' decimal separator, no thousands).</summary>
    class function FloatInv(const Value: Double): string; static;

    /// <summary>
    ///  Invariant float formatting with fixed decimal places (rounding).
    /// </summary>
    /// <remarks>
    ///  Uses standard Delphi rounding semantics.
    ///  This method may round the value when reducing precision.
    /// </remarks>
    class function FloatInvFixed(const Value: Double; const Decimals: Integer): string; static;

    /// <summary>
    ///  Invariant float formatting with fixed decimal places (truncation).
    /// </summary>
    /// <remarks>
    ///  Truncates toward zero; no rounding is ever performed.
    /// </remarks>
    class function FloatInvFixedTrunc(const Value: Double; const Decimals: Integer): string; static;

    /// <summary>Invariant integer formatting (no thousands separators).</summary>
    class function IntInv(const Value: Int64): string; static;

    { Display helpers (explicit FS) }
    /// <summary>Formats currency using explicit format settings.</summary>
    class function CurrencyDisp(const Value: Currency; const FS: TFormatSettings): string; static;

    /// <summary>
    ///  Formats a percentage using explicit FS.
    ///  Input is fractional (e.g., 0.1234 -> "12.34%").
    /// </summary>
    class function PercentDisp(const Fraction: Double; const Decimals: Integer; const FS: TFormatSettings): string; static;

    { Misc }
    /// <summary>Returns "True"/"False" (capitalized) regardless of locale.</summary>
    class function BoolText(const Value: Boolean): string; static;

    /// <summary>
    ///  Quotes a string for diagnostics/logs, escaping common control characters.
    ///  Produces something like: "Hello\r\nWorld"
    /// </summary>
    class function QuoteLog(const S: string): string; static;

    { ISO 8601 with offset }
    class function DateTimeISOOffset(const DT: TDateTime): string; static;
    class function DateTimeISOOffsetMs(const DT: TDateTime): string; static;

    { Round-trip floats (invariant) }
    class function FloatInvRoundTrip(const Value: Double): string; overload; static;
    class function FloatInvRoundTrip(const Value: Single): string; overload; static;

    { GUID formatting }
    class function GuidD(const G: TGUID): string; static; // 8-4-4-4-12 (no braces)
    class function GuidN(const G: TGUID): string; static; // 32 hex (no braces, no hyphens)

    { Bytes formatting }
    class function BytesHex(const Bytes: TBytes): string; static;
    class function BytesBase64(const Bytes: TBytes): string; static;

    /// <summary>
    ///  Invariant money formatting with fixed decimal places (rounding).
    /// </summary>
    /// <remarks>
    ///  Uses standard Delphi Currency rounding semantics.
    ///  Suitable for presentation output where rounding is desired.
    /// </remarks>
    class function MoneyInvFixed(const Value: Currency; const Decimals: Integer = 2): string; static;

    /// <summary>
    ///  Invariant money formatting with fixed decimal places (truncation).
    /// </summary>
    /// <remarks>
    ///  Truncates toward zero; no rounding is ever performed.
    ///  Suitable for deterministic or regulatory-sensitive output.
    /// </remarks>
    class function MoneyInvFixedTrunc(const Value: Currency; const Decimals: Integer = 2): string; static;
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
class function TFormat.DateISO(const D: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd', D, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.TimeISO(const T: TDateTime): string;
begin
  Result := FormatDateTime('hh":"nn":"ss', T, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeISO(const DT: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', DT, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeISOMs(const DT: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz', DT, InvariantFS);
end;

{ ISO 8601 (UTC, with Z) }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeUTCISO(const DT: TDateTime): string;
var
  Utc: TDateTime;
begin
  Utc := TTimeZone.Local.ToUniversalTime(DT);
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"Z"', Utc, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeUTCISOMs(const DT: TDateTime): string;
var
  Utc: TDateTime;
begin
  Utc := TTimeZone.Local.ToUniversalTime(DT);
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz"Z"', Utc, InvariantFS);
end;

{ Numbers (invariant, machine-friendly) }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.FloatInv(const Value: Double): string;
begin
  // General format, no thousands separators, invariant decimal separator.
  Result := FloatToStr(Value, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.FloatInvFixed(const Value: Double; const Decimals: Integer): string;
var
  FS: TFormatSettings;
begin
  FS := InvariantFS;
  Result := FormatFloat('0.' + DupeString('0', Max(0, Decimals)), Value, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.FloatInvFixedTrunc(const Value: Double; const Decimals: Integer): string;
var
  FS: TFormatSettings;
  Pow10: Double;
  V: Double;
begin
  FS := InvariantFS;

  if Decimals <= 0 then
    Exit(IntToStr(Trunc(Value)));

  Pow10 := IntPower(10, Decimals);

  // Truncate toward zero at the requested precision:
  //  12.349, Decimals=2 => 12.34
  V := Trunc(Value * Pow10) / Pow10;

  Result := FormatFloat('0.' + DupeString('0', Decimals), V, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.IntInv(const Value: Int64): string;
begin
  // Avoid locale-dependent thousand separators: plain IntToStr is already safe,
  // but keep this for symmetry and discoverability.
  Result := IntToStr(Value);
end;

{ Display helpers (explicit FS) }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.CurrencyDisp(const Value: Currency; const FS: TFormatSettings): string;
begin
  // CurrencyToStr respects FS for separators; symbol placement is OS/FS dependent by design.
  Result := CurrToStr(Value, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.PercentDisp(const Fraction: Double; const Decimals: Integer; const FS: TFormatSettings): string;
begin
  Result := FormatFloat('0.' + DupeString('0', Max(0, Decimals)), Fraction * 100, FS) + '%';
end;

{ Misc }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.BoolText(const Value: Boolean): string;
begin
  if Value then
    Result := 'True'
  else
    Result := 'False';
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.QuoteLog(const S: string): string;
var
  I: Integer;
  Ch: Char;
  B: TStringBuilder;
begin
  B := TStringBuilder.Create(S.Length + 2);
  try
    B.Append('"');
    for I := 1 to S.Length do
    begin
      Ch := S[I];
      case Ch of
        '"':  B.Append('\"');
        '\':  B.Append('\\');
        #8:   B.Append('\b');
        #9:   B.Append('\t');
        #10:  B.Append('\n');
        #12:  B.Append('\f');
        #13:  B.Append('\r');
      else
        if Ord(Ch) < 32 then
          B.Append('\x' + IntToHex(Ord(Ch), 2))
        else
          B.Append(Ch);
      end;
    end;
    B.Append('"');
    Result := B.ToString;
  finally
    B.Free;
  end;
end;

{ ISO 8601 with offset }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeISOOffset(const DT: TDateTime): string;
var
  Offset: TTimeSpan;
  TotalMins: Integer;
  Sign: Char;
  H, M: Integer;
begin
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

  Result :=
    FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', DT, InvariantFS) +
    Format('%s%.2d:%.2d', [Sign, H, M], InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.DateTimeISOOffsetMs(const DT: TDateTime): string;
var
  Offset: TTimeSpan;
  TotalMins: Integer;
  Sign: Char;
  H, M: Integer;
begin
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

  Result :=
    FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz', DT, InvariantFS) +
    Format('%s%.2d:%.2d', [Sign, H, M], InvariantFS);
end;

{ Round-trip floats (invariant) }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.FloatInvRoundTrip(const Value: Double): string;
begin
  // 17 significant digits is the common round-trip safe precision for IEEE-754 double
  Result := FloatToStrF(Value, ffGeneral, 17, 0, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.FloatInvRoundTrip(const Value: Single): string;
begin
  // 9 significant digits is typically round-trip safe for IEEE-754 single
  Result := FloatToStrF(Value, ffGeneral, 9, 0, InvariantFS);
end;

{ GUID formatting }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.GuidD(const G: TGUID): string;
var
  S: string;
begin
  // GUIDToString => "{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}"
  S := GUIDToString(G);
  Result := Copy(S, 2, S.Length - 2); // strip braces
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.GuidN(const G: TGUID): string;
var
  D: string;
begin
  D := GuidD(G);
  Result := StringReplace(D, '-', '', [rfReplaceAll]);
end;

{ Bytes formatting }

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.BytesHex(const Bytes: TBytes): string;
begin
  if Length(Bytes) = 0 then
    Exit('');

  SetLength(Result, Length(Bytes) * 2);
  BinToHex(@Bytes[0], PChar(Result), Length(Bytes));
  // BinToHex produces uppercase hex
end;

class function TFormat.BytesBase64(const Bytes: TBytes): string;
begin
  if Length(Bytes) = 0 then
    Exit('');

  Result := TNetEncoding.Base64.EncodeBytesToString(Bytes);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.MoneyInvFixed(const Value: Currency; const Decimals: Integer): string;
var
  FS: TFormatSettings;
  Mask: string;
begin
  if (Decimals < 0) or (Decimals > 4) then
    raise EArgumentOutOfRangeException.Create('Decimals must be in 0..4 for Currency.');

  FS := InvariantFS;

  if Decimals = 0 then
    Mask := '0'
  else
    Mask := '0.' + DupeString('0', Decimals);

  Result := FormatCurr(Mask, Value, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TFormat.MoneyInvFixedTrunc(const Value: Currency; const Decimals: Integer): string;
var
  FS: TFormatSettings;
  Mask: string;
  Scale: Int64;
  Scaled: Int64;
  TruncScaled: Int64;
begin
  if (Decimals < 0) or (Decimals > 4) then
    raise EArgumentOutOfRangeException.Create('Decimals must be in 0..4 for Currency.');

  FS := InvariantFS;

  // Currency is fixed-point scaled by 10000 in storage.
  // We truncate toward zero to the requested decimal count.
  case Decimals of
    0: Scale := 10000;
    1: Scale := 1000;
    2: Scale := 100;
    3: Scale := 10;
    4: Scale := 1;
  else
    Scale := 100; // unreachable
  end;

  // Convert to scaled Int64, truncate, then convert back.
  // Value * 10000 is exact for Currency.
  Scaled := Round(Value * 10000);      // exact for Currency values
  TruncScaled := (Scaled div Scale) * Scale;

  // Format
  if Decimals = 0 then
    Mask := '0'
  else
    Mask := '0.' + DupeString('0', Decimals);

  Result := FormatCurr(Mask, TruncScaled / 10000.0, FS);
end;

end.

