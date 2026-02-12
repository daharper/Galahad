{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Conversions
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Provides conversion utilities
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Conversions;

interface

uses
  System.SysUtils,
  System.DateUtils;

type
  /// <summary>Raised by TConvert.ToXxx strict conversions on failure.</summary>
  EStrictConvertError = class(EConvertError);

  /// <summary>
  ///  Strict, policy-driven string-to-value conversions.
  /// </summary>
  /// <remarks>
  ///  All parsing methods in TConvert are intentionally strict:
  ///  - No silent truncation or rounding
  ///  - No acceptance of trailing junk
  ///  - No ambiguous or heuristic parsing
  ///
  ///  Locale handling is explicit:
  ///  - Default overloads use the current thread's locale (System.SysUtils.FormatSettings)
  ///    and are intended for user-facing input.
  ///  - FS overloads require an explicit TFormatSettings and are intended for known locales.
  ///  - Invariant (Inv) overloads use a fixed, culture-independent format and provide
  ///    deterministic behaviour across machines, regions, and platforms.
  ///
  ///  Invariant methods exist to solve a common class of bugs caused by locale differences
  ///  when parsing data at system boundaries (APIs, config files, persistence, tests).
  ///  They guarantee that the same input string produces the same result everywhere.
  ///
  ///  Failure is reported explicitly:
  ///  - TryToXxx: returns Boolean and never raises exceptions
  ///  - ToXxxOr : returns a caller-supplied default on failure
  ///  - ToXxx   : strict conversion that raises EStrictConvertError on failure
  /// </remarks>
  TConvert = record
  private
    class procedure SetEnumOrdinal<T>(const aOrdinal: Integer; out aValue: T); static;
    class procedure RaiseStrict(const aTypeName, S: string); static;
  public
    /// <summary>
    /// Returns invariant (culture-independent) format settings.
    /// </summary>
    /// <remarks>
    /// The invariant format settings define a fixed, locale-neutral representation:
    /// - '.' is used as the decimal separator
    /// - No thousands separators are applied
    /// - Date and time formats are stable and unambiguous
    ///
    /// These conventions match how numeric values are typically represented in
    /// REST APIs, JSON payloads, configuration files, and other wire formats,
    /// where locale-specific formatting is not permitted.
    ///
    /// These settings are used internally by all *Inv methods (for example,
    /// ToDoubleInv, TryToDateTimeInv, TryToMoneyInv) to guarantee deterministic
    /// parsing behaviour regardless of the machine, user locale, or region.
    ///
    /// Use invariant formatting when parsing or processing data at system boundaries,
    /// such as APIs, JSON/XML, configuration files, persistence, logs, and tests,
    /// where values must be interpreted identically across environments.
    ///
    /// In contrast, default-locale overloads are intended for user-facing input,
    /// where parsing should respect the user's regional settings.
    /// </remarks>
    class function InvariantFS: TFormatSettings; static;

    {------------------------------------------------ Integer ----------------------------------------------------}

    /// <summary>Tries to strictly parse an Integer from S.</summary>
    class function TryToInt(const S: string; out aValue: Integer): Boolean; static;

    /// <summary>Parses an Integer or returns Default if parsing fails.</summary>
    class function ToIntOr(const S: string; const aDefault: Integer = 0): Integer; static;

    /// <summary>Strictly parses an Integer; raises EStrictConvertError on failure.</summary>
    class function ToInt(const S: string): Integer; static;

    {------------------------------------------------- Int64 -----------------------------------------------------}

    /// <summary>Tries to strictly parse an Int64 from S.</summary>
    class function TryToInt64(const S: string; out aValue: Int64): Boolean; static;

    /// <summary>Parses an Int64 or returns Default if parsing fails.</summary>
    class function ToInt64Or(const S: string; const aDefault: Int64 = 0): Int64; static;

    /// <summary>Strictly parses an Int64; raises EStrictConvertError on failure.</summary>
    class function ToInt64(const S: string): Int64; static;

    {----------------------------------------------- Unsigned ----------------------------------------------------}

    /// <summary>Tries to strictly parse a UInt32 (Cardinal) from S.</summary>
    class function TryToUInt32(const S: string; out aValue: Cardinal): Boolean; static;

    /// <summary>Tries to strictly parse a UInt64 from S.</summary>
    class function TryToUInt64(const S: string; out aValue: UInt64): Boolean; static;

    /// <summary>Parses a UInt32 or returns Default if parsing fails.</summary>
    class function ToUInt32Or(const S: string; const aDefault: Cardinal = 0): Cardinal; static;

    /// <summary>Parses a UInt64 or returns Default if parsing fails.</summary>
    class function ToUInt64Or(const S: string; const aDefault: UInt64 = 0): UInt64; static;

    /// <summary>Strictly parses a UInt32; raises EStrictConvertError on failure.</summary>
    class function ToUInt32(const S: string): Cardinal; static;

    /// <summary>Strictly parses a UInt64; raises EStrictConvertError on failure.</summary>
    class function ToUInt64(const S: string): UInt64; static;

    {----------------------------------------------- Boolean -----------------------------------------------------}

    /// <summary>Tries to strictly parse a Boolean from S.</summary>
    /// <remarks>Accepts: True/False, T/F, Yes/No, Y/N, 1/0 (case-insensitive).</remarks>
    class function TryToBool(const S: string; out aValue: Boolean): Boolean; static;

    /// <summary>Parses a Boolean or returns Default if parsing fails.</summary>
    class function ToBoolOr(const S: string; const aDefault: Boolean = False): Boolean; static;

    /// <summary>Strictly parses a Boolean; raises EStrictConvertError on failure.</summary>
    class function ToBool(const S: string): Boolean; static;

    {------------------------------------------------- Char ------------------------------------------------------}

    /// <summary>Tries to parse a single character; succeeds only when Length(S)=1.</summary>
    class function TryToChar(const S: string; out aValue: Char): Boolean; static;

    /// <summary>Parses a Char or returns Default if parsing fails.</summary>
    class function ToCharOr(const S: string; const aDefault: Char = #0): Char; static;

    /// <summary>Strictly parses a Char; raises EStrictConvertError on failure.</summary>
    class function ToChar(const S: string): Char; static;

    {------------------------------------------------ Single -----------------------------------------------------}

    /// <summary>
    /// Tries to parse a Single using the current locale.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToSingle(const S: string; out aValue: Single): Boolean; overload; static;

    /// <summary>Parses a Single using the current locale or returns Default if parsing fails.</summary>
    class function ToSingleOr(const S: string; const aDefault: Single = 0): Single; overload; static;

    /// <summary>Strictly parses a Single using the current locale; raises EStrictConvertError on failure.</summary>
    class function ToSingle(const S: string): Single; overload; static;

    /// <summary>
    /// Tries to parse a Single using the supplied format settings.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToSingle(const S: string; out aValue: Single; const aFs: TFormatSettings): Boolean; overload; static;

    /// <summary>Parses a Single using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToSingleOr(const S: string; const aFs: TFormatSettings; const aDefault: Single = 0): Single; overload; static;

    /// <summary>Strictly parses a Single using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToSingle(const S: string; const aFs: TFormatSettings): Single; overload; static;

    /// <summary>
    /// Tries to parse a Single using invariant (culture-independent) settings.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToSingleInv(const S: string; out aValue: Single): Boolean; static;

    /// <summary>Parses a Single using invariant settings or returns Default if parsing fails.</summary>
    class function ToSingleOrInv(const S: string; const aDefault: Single = 0): Single; static;

    /// <summary>Strictly parses a Single using invariant settings; raises EStrictConvertError on failure.</summary>
    class function ToSingleInv(const S: string): Single; static;

    {------------------------------------------------ Double -----------------------------------------------------}

    /// <summary>
    /// Tries to parse a Double using the current locale.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToDouble(const S: string; out aValue: Double): Boolean; overload; static;

    /// <summary>Parses a Double using the current locale or returns Default if parsing fails.</summary>
    class function ToDoubleOr(const S: string; const aDefault: Double = 0): Double; overload; static;

    /// <summary>Strictly parses a Double using the current locale; raises EStrictConvertError on failure.</summary>
    class function ToDouble(const S: string): Double; overload; static;

    /// <summary>
    /// Tries to parse a Double using the supplied format settings.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToDouble(const S: string; out aValue: Double; const aFs: TFormatSettings): Boolean; overload; static;

    /// <summary>Parses a Double using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToDoubleOr(const S: string; const aFs: TFormatSettings; const aDefault: Double = 0): Double; overload; static;

    /// <summary>Strictly parses a Double using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToDouble(const S: string; const aFs: TFormatSettings): Double; overload; static;

    /// <summary>
    /// Tries to parse a Double using invariant (culture-independent) settings.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToDoubleInv(const S: string; out aValue: Double): Boolean; static;

    /// <summary>Parses a Double using invariant settings or returns Default if parsing fails.</summary>
    class function ToDoubleOrInv(const S: string; const aDefault: Double = 0): Double; static;

    /// <summary>Strictly parses a Double using invariant settings; raises EStrictConvertError on failure.</summary>
    class function ToDoubleInv(const S: string): Double; static;

    {---------------------------------------------- Date / Time --------------------------------------------------}

    /// <summary>
    /// Tries to strictly parse a date and time using the current locale.
    /// Input must exactly match the expected format; trailing or partial input is rejected.
    /// </summary>
    class function TryToDateTime(const S: string; out aValue: TDateTime): Boolean; overload; static;

    /// <summary>
    /// Tries to strictly parse a date (date-only) using the current locale.
    /// Time components, trailing characters, or ambiguous input are rejected.
    /// </summary>
    class function TryToDate(const S: string; out aValue: TDateTime): Boolean; overload; static;

    /// <summary>
    /// Tries to strictly parse a time (time-only) using the current locale.
    /// Date components, trailing characters, or ambiguous input are rejected.
    /// </summary>
    class function TryToTime(const S: string; out aValue: TDateTime): Boolean; overload; static;

    /// <summary>Parses a date and time using the current locale or returns Default if parsing fails.</summary>
    class function ToDateTimeOr(const S: string; const aDefault: TDateTime = 0): TDateTime; overload; static;

    /// <summary>Parses a date using the current locale or returns Default if parsing fails.</summary>
    class function ToDateOr(const S: string; const aDefault: TDateTime = 0): TDateTime; overload; static;

    /// <summary>Parses a time using the current locale or returns Default if parsing fails.</summary>
    class function ToTimeOr(const S: string; const aDefault: TDateTime = 0): TDateTime; overload; static;

    /// <summary>Strictly parses a date and time using the current locale; raises EStrictConvertError on failure.</summary>
    class function ToDateTime(const S: string): TDateTime; overload; static;

    /// <summary>Strictly parses a date using the current locale; raises EStrictConvertError on failure.</summary>
    class function ToDate(const S: string): TDateTime; overload; static;

    /// <summary>Strictly parses a time using the current locale; raises EStrictConvertError on failure.</summary>
    class function ToTime(const S: string): TDateTime; overload; static;

    /// <summary>
    /// Tries to strictly parse a date and time using the supplied format settings.
    /// Input must exactly match the specified format; no coercion is performed.
    /// </summary>
    class function TryToDateTime(const S: string; out aValue: TDateTime; const aFs: TFormatSettings): Boolean; overload; static;

    /// <summary>
    /// Tries to strictly parse a date (date-only) using the supplied format settings.
    /// Input must exactly match the specified format; no coercion is performed.
    /// </summary>
    class function TryToDate(const S: string; out aValue: TDateTime; const aFs: TFormatSettings): Boolean; overload; static;

    /// <summary>
    /// Tries to strictly parse a time (time-only) using the supplied format settings.
    /// Input must exactly match the specified format; no coercion is performed.
    /// </summary>
    class function TryToTime(const S: string; out aValue: TDateTime; const aFs: TFormatSettings): Boolean; overload; static;

    /// <summary>Parses a date and time using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToDateTimeOr(const S: string; const aFs: TFormatSettings; const aDefault: TDateTime = 0): TDateTime; overload; static;

    /// <summary>Parses a date using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToDateOr(const S: string; const aFs: TFormatSettings; const aDefault: TDateTime = 0): TDateTime; overload; static;

    /// <summary>Parses a time using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToTimeOr(const S: string; const aFs: TFormatSettings; const aDefault: TDateTime = 0): TDateTime; overload; static;

    /// <summary>Strictly parses a date and time using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToDateTime(const S: string; const aFs: TFormatSettings): TDateTime; overload; static;

    /// <summary>Strictly parses a date using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToDate(const S: string; const aFs: TFormatSettings): TDateTime; overload; static;

    /// <summary>Strictly parses a time using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToTime(const S: string; const aFs: TFormatSettings): TDateTime; overload; static;

    /// <summary>
    /// Tries to parse an ISO 8601 date/time string.
    /// Parsing is strict; local-time semantics are preserved (no timezone normalization).
    /// </summary>
    class function TryToDateTimeISO8601(const S: string; out aValue: TDateTime): Boolean; static;

    /// <summary>Parses ISO 8601 date/time or returns Default if parsing fails.</summary>
    class function ToDateTimeOrISO8601(const S: string; const aDefault: TDateTime = 0): TDateTime; static;

    /// <summary>Strictly parses ISO 8601 date/time; raises EStrictConvertError on failure.</summary>
    class function ToDateTimeISO8601(const S: string): TDateTime; static;

    {------------------------------- Currency (RTL-style parsing, locale-aware) ----------------------------------}

    /// <summary>
    /// Tries to parse a Currency value using the supplied format settings.
    /// Parsing follows RTL rules and may round according to Currency scale.
    /// </summary>
    class function TryToCurrency(const S: string; out aValue: Currency; const aFs: TFormatSettings): Boolean; static;

    /// <summary>
    /// Tries to parse a Currency value using invariant (culture-independent) settings.
    /// Parsing follows RTL rules and may round according to Currency scale.
    /// </summary>
    class function TryToCurrencyInv(const S: string; out aValue: Currency): Boolean; static;

    /// <summary>Parses Currency using the current locale or returns Default if parsing fails.</summary>
    class function ToCurrencyOr(const S: string; const aDefault: Currency = 0): Currency; overload; static;

    /// <summary>Strictly parses Currency using the current locale; raises EStrictConvertError on failure.</summary>
    class function ToCurrency(const S: string): Currency; overload; static;

    /// <summary>Parses Currency using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToCurrencyOr(const S: string; const aFs: TFormatSettings; const aDefault: Currency = 0): Currency; overload; static;

    /// <summary>Strictly parses Currency using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToCurrency(const S: string; const aFs: TFormatSettings): Currency; overload; static;

    /// <summary>Parses Currency using invariant settings or returns Default if parsing fails.</summary>
    class function ToCurrencyOrInv(const S: string; const aDefault: Currency = 0): Currency; static;

    /// <summary>Strictly parses Currency using invariant settings; raises EStrictConvertError on failure.</summary>
    class function ToCurrencyInv(const S: string): Currency; static;

    {------------------------------------------------- GUID ------------------------------------------------------}

    /// <summary>Tries to parse a GUID string into a TGUID.</summary>
    class function TryToGuid(const S: string; out aValue: TGUID): Boolean; static;

    /// <summary>Parses a GUID or returns Default if parsing fails.</summary>
    class function ToGuidOr(const S: string; const aDefault: TGUID): TGUID; static;

    /// <summary>Strictly parses a GUID; raises EStrictConvertError on failure.</summary>
    class function ToGuid(const S: string): TGUID; static;

    {------------------------------------  Money (strict policy parsing) -----------------------------------------}

    /// <summary>
    /// Tries to strictly parse a monetary value using a fixed decimal policy.
    /// No rounding or truncation is performed; invalid input is rejected.
    /// </summary>
    class function TryToMoney(
      const S: string;
      out aValue: Currency;
      const aDecimals: Integer;
      const aFs: TFormatSettings
    ): Boolean; static;

    /// <summary>
    /// Tries to strictly parse a monetary value using invariant settings.
    /// No rounding, no truncation, and no coercion; exact decimal precision is enforced.
    /// </summary>
    class function TryToMoneyInv(
      const S: string;
      out aValue: Currency;
      const aDecimals: Integer
    ): Boolean; static;

    /// <summary>
    /// Parses money using the current locale and fixed decimal policy.
    /// No rounding is ever performed; input must conform exactly to the policy.
    /// </summary>
    class function ToMoneyOr(const S: string; const aDecimals: Integer = 2; const aDefault: Currency = 0): Currency; overload; static;

    /// <summary>Strictly parses money using the current locale and Decimals policy; raises EStrictConvertError on failure.</summary>
    class function ToMoney(const S: string; const aDecimals: Integer): Currency; overload; static;

    /// <summary>Parses money using the supplied format settings and Decimals policy, or returns Default if parsing fails.</summary>
    class function ToMoneyOr(const S: string; const aFs: TFormatSettings; const aDecimals: Integer = 2; const aDefault: Currency = 0): Currency; overload; static;

    /// <summary>Strictly parses money using the supplied format settings and Decimals policy; raises EStrictConvertError on failure.</summary>
    class function ToMoney(const S: string; const aFs: TFormatSettings; const aDecimals: Integer): Currency; overload; static;

    /// <summary>Parses money using invariant settings and Decimals policy, or returns Default if parsing fails.</summary>
    class function ToMoneyOrInv(const S: string; const aDecimals: Integer = 2; const aDefault: Currency = 0): Currency; static;

    /// <summary>
    /// Strictly parses money using invariant settings and fixed decimal policy.
    /// Any deviation from the expected format results in failure.
    /// </summary>
    class function ToMoneyInv(const S: string; const aDecimals: Integer): Currency; static;

    {------------------------------------------------- Enum ------------------------------------------------------}

    /// <summary>Tries to convert S to an enum value of type T (by name, and optionally ordinal).</summary>
    class function TryToEnum<T>(
      const S: string;
      out aValue: T;
      const aIgnoreCase: Boolean = True;
      const aAllowOrdinal: Boolean = False
    ): Boolean; static;

    /// <summary>Converts S to an enum value of type T, or returns Default if parsing fails.</summary>
    class function ToEnumOr<T>(
      const S: string;
      const aDefault: T;
      const aIgnoreCase: Boolean = True;
      const aAllowOrdinal: Boolean = False
    ): T; static;

    /// <summary>Strictly converts S to an enum value of type T; raises EStrictConvertError on failure.</summary>
    class function ToEnum<T>(
      const S: string;
      const aIgnoreCase: Boolean = True;
      const aAllowOrdinal: Boolean = False
    ): T; static;

    {------------------------------------------  Bytes decoding --------------------------------------------------}

    /// <summary>Tries to decode a hexadecimal string into a byte array.</summary>
    class function TryToBytesHex(const S: string; out aValue: TBytes): Boolean; static;

    /// <summary>Tries to decode a Base64 string into a byte array (strict canonical validation).</summary>
    class function TryToBytesBase64(const S: string; out aValue: TBytes): Boolean; static;

    /// <summary>Decodes a hexadecimal string or returns Default if decoding fails.</summary>
    class function ToBytesHexOr(const S: string; const Default: TBytes): TBytes; static;

    /// <summary>Decodes a Base64 string or returns Default if decoding fails.</summary>
    class function ToBytesBase64Or(const S: string; const Default: TBytes): TBytes; static;

    /// <summary>Strictly decodes a hexadecimal string; raises EStrictConvertError on failure.</summary>
    class function ToBytesHex(const S: string): TBytes; static;

    /// <summary>Strictly decodes a Base64 string; raises EStrictConvertError on failure.</summary>
    class function ToBytesBase64(const S: string): TBytes; static;

    {--------------------------------  Invariant string output (canonical) ---------------------------------------}

    /// <summary>
    /// Converts a Single to an invariant (culture-independent) string.
    /// </summary>
    /// <remarks>
    /// Uses '.' as decimal separator and no thousands separators.
    /// Uses a general format intended to round-trip reliably when parsed with SingleInv functions.
    /// </remarks>
    class function SingleToStringInv(const aValue: Single): string; static;

    /// <summary>
    /// Converts a Double to an invariant (culture-independent) string.
    /// </summary>
    /// <remarks>
    /// Uses '.' as decimal separator and no thousands separators.
    /// Uses a general format intended to round-trip reliably when parsed with DoubleInv functions.
    /// </remarks>
    class function DoubleToStringInv(const aValue: Double): string; static;

    /// <summary>
    /// Converts a Currency to an invariant string with exactly 4 fractional digits.
    /// </summary>
    /// <remarks>
    /// Currency is fixed-scale (4 decimal places). Output is canonical (no thousands separators).
    /// </remarks>
    class function CurrencyToStringInv(const aValue: Currency): string; static;

    /// <summary>
    /// Converts a monetary value to an invariant string with exactly Decimals fractional digits.
    /// </summary>
    /// <remarks>
    /// This is the formatting counterpart to TryToMoneyInv. Output contains:
    /// optional '-' sign, digits, optional '.', and exactly Decimals fractional digits.
    /// No thousands separators or currency symbols are ever emitted.
    /// </remarks>
    class function MoneyToStringInv(const aValue: Currency; const aDecimals: Integer = 2): string; static;

    /// <summary>
    /// Converts a TDateTime to an ISO 8601 string (invariant).
    /// </summary>
    /// <remarks>
    /// Uses local-time semantics (no timezone normalization). Intended to round-trip with TryToDateTimeISO8601.
    /// </remarks>
    class function DateTimeToStringISO8601(const aValue: TDateTime): string; static;

    /// <summary>
    /// Converts a date (TDateTime) to ISO 8601 date-only form (YYYY-MM-DD).
    /// </summary>
    class function DateToStringISO8601(const aValue: TDateTime): string; static;

    /// <summary>
    /// Converts a time (TDateTime) to ISO-like time-only form (HH:NN:SS).
    /// </summary>
    class function TimeToStringISO8601(const aValue: TDateTime): string; static;

    /// <summary>
    /// Encodes bytes as canonical Base64 text.
    /// </summary>
    class function BytesToBase64StringInv(const aValue: TBytes): string; static;

    /// <summary>
    /// Encodes bytes as canonical hexadecimal text (uppercase, no separators).
    /// </summary>
    class function BytesToHexStringInv(const aValue: TBytes): string; static;

    /// <summary>
    ///  Returns the hex value for the character
    /// </summary>
    class function HexValue(c: Char): Integer; static;

    /// <summary>
    ///  Returns the decimal value for the character
    /// </summary>
    class function DecimalValue(c: Char): Integer; static;

    /// <summary>
    ///  Returns the string representing the specified code point
    /// </summary>
    class function CodePointToString(aCodePoint: Integer): string; static;
  end;

implementation

uses
  System.StrUtils,
  System.TypInfo,
  System.NetEncoding,
  Base.Integrity;

{$region 'Helpers'}

{----------------------------------------------------------------------------------------------------------------------}
class procedure TConvert.RaiseStrict(const aTypeName, S: string);
begin
  var e := EStrictConvertError.CreateFmt('Cannot convert "%s" to %s.', [S, aTypeName]);

  TError.Notify(e);

  raise e;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.InvariantFS: TFormatSettings;
begin
  Result := TFormatSettings.Invariant;
end;

{$endregion}

{$region 'Integer'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToInt(const S: string; out aValue: Integer): Boolean;
begin
  Result := TryStrToInt(S, aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToIntOr(const S: string; const aDefault: Integer): Integer;
begin
  if not TryToInt(S, Result) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToInt(const S: string): Integer;
begin
  if not TryToInt(S, Result) then RaiseStrict('Integer', S);
end;

{$endregion}

{$region 'Int64'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToInt64(const S: string; out aValue: Int64): Boolean;
begin
  Result := TryStrToInt64(S, aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToInt64Or(const S: string; const aDefault: Int64): Int64;
begin
  if not TryToInt64(S, Result) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToInt64(const S: string): Int64;
begin
  if not TryToInt64(S, Result) then RaiseStrict('Int64', S);
end;

{$endregion}

{$region 'Unsigned'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToUInt64(const S: string; out aValue: UInt64): Boolean;
var
  I64: Int64;
begin
  var input := Trim(S);

  if (input = '') or (input[1] = '-') then exit(false);

  if TryStrToInt64(input, I64) then
  begin
    if I64 < 0 then exit(false);
    aValue := UInt64(I64);
    exit(true);
  end;

  aValue := 0;

  for var ch in Input do
  begin
    if not CharInSet(ch, ['0'..'9']) then exit(false);

    var digit := Ord(Ch) - Ord('0');

    if (aValue > (High(UInt64) div 10)) or
       ((aValue = (High(UInt64) div 10)) and
       (UInt64(digit) > (High(UInt64) mod 10))) then exit(false);

    aValue := aValue * 10 + UInt64(digit);
  end;

  Result := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToUInt32(const S: string; out aValue: Cardinal): Boolean;
var
  U64: UInt64;
begin
  if not TryToUInt64(S, U64) then exit(false);

  if U64 > High(Cardinal) then exit(false);

  aValue := Cardinal(U64);
  Result := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToUInt64Or(const S: string; const aDefault: UInt64): UInt64;
begin
  if not TryToUInt64(S, Result) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToUInt32Or(const S: string; const aDefault: Cardinal): Cardinal;
begin
  if not TryToUInt32(S, Result) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToUInt64(const S: string): UInt64;
begin
  if not TryToUInt64(S, Result) then RaiseStrict('UInt64', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToUInt32(const S: string): Cardinal;
begin
  if not TryToUInt32(S, Result) then RaiseStrict('UInt32', S);
end;

{$endregion}

{$region 'Boolean'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToBool(const S: string; out aValue: Boolean): Boolean;
begin
  aValue := false;

  var input := Trim(S);

  if input = '' then exit(false);

  // True values
  if IndexText(input, ['true', 't', 'yes', 'y', '1', '-1']) <> -1 then
  begin
    aValue := true;
    exit(true);
  end;

  // False values
  if IndexText(Input, ['false', 'f', 'no', 'n', '0']) <> -1 then
    Result := true
  else
    Result := false;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToBoolOr(const S: string; const aDefault: Boolean): Boolean;
begin
  if not TryToBool(S, Result) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToBool(const S: string): Boolean;
begin
  if not TryToBool(S, Result) then RaiseStrict('Boolean', S);
end;

{$endregion}

{$region 'Char'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToChar(const S: string; out aValue: Char): Boolean;
begin
  Result := Length(S) = 1;

  aValue := if Result then S[1] else #0;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCharOr(const S: string; const aDefault: Char): Char;
begin
  if not TryToChar(S, Result) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToChar(const S: string): Char;
begin
  if not TryToChar(S, Result) then RaiseStrict('Char', S);
end;

{$endregion}

{$region 'Single'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToSingle(const S: string; out aValue: Single): Boolean;
begin
  Result := TryToSingle(S, aValue, FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingleOr(const S: string; const aDefault: Single): Single;
begin
  Result := ToSingleOr(S, FormatSettings, aDefault);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingle(const S: string): Single;
begin
  Result := ToSingle(S, FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToSingle(const S: string; out aValue: Single; const aFs: TFormatSettings): Boolean;
begin
  Result := TryStrToFloat(S, aValue, aFs);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingleOr(const S: string; const aFs: TFormatSettings; const aDefault: Single): Single;
begin
  if not TryToSingle(S, Result, aFs) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingle(const S: string; const aFs: TFormatSettings): Single;
begin
  if not TryToSingle(S, Result, aFs) then RaiseStrict('Single', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToSingleInv(const S: string; out aValue: Single): Boolean;
begin
  Result := TryToSingle(S, aValue, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingleOrInv(const S: string; const aDefault: Single): Single;
begin
  Result := ToSingleOr(S, InvariantFS, aDefault);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingleInv(const S: string): Single;
begin
  Result := ToSingle(S, InvariantFS);
end;

{$endregion}

{$region 'Double'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDouble(const S: string; out aValue: Double): Boolean;
begin
  Result := TryToDouble(S, aValue, FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDoubleOr(const S: string; const aDefault: Double): Double;
begin
  Result := ToDoubleOr(S, FormatSettings, aDefault);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDouble(const S: string): Double;
begin
  Result := ToDouble(S, FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDouble(const S: string; out aValue: Double; const aFs: TFormatSettings): Boolean;
begin
  Result := TryStrToFloat(S, aValue, aFs);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDoubleOr(const S: string; const aFs: TFormatSettings; const aDefault: Double): Double;
begin
  if not TryToDouble(S, Result, aFs) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDouble(const S: string; const aFs: TFormatSettings): Double;
begin
  if not TryToDouble(S, Result, aFs) then RaiseStrict('Double', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDoubleInv(const S: string; out aValue: Double): Boolean;
begin
  Result := TryToDouble(S, aValue, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDoubleOrInv(const S: string; const aDefault: Double): Double;
begin
  Result := ToDoubleOr(S, InvariantFS, aDefault);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDoubleInv(const S: string): Double;
begin
  Result := ToDouble(S, InvariantFS);
end;

{$endregion}

{$region 'DateTime'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDateTime(const S: string; out aValue: TDateTime): Boolean;
begin
  Result := TryToDateTime(S, aValue, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDate(const S: string; out aValue: TDateTime): Boolean;
begin
  Result := TryToDate(S, aValue, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToTime(const S: string; out aValue: TDateTime): Boolean;
begin
  Result := TryToTime(S, aValue, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTimeOr(const S: string; const aDefault: TDateTime): TDateTime;
begin
  Result := ToDateTimeOr(S, System.SysUtils.FormatSettings, aDefault);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateOr(const S: string; const aDefault: TDateTime): TDateTime;
begin
  Result := ToDateOr(S, System.SysUtils.FormatSettings, aDefault);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToTimeOr(const S: string; const aDefault: TDateTime): TDateTime;
begin
  Result := ToTimeOr(S, System.SysUtils.FormatSettings, aDefault);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTime(const S: string): TDateTime;
begin
  Result := ToDateTime(S, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDate(const S: string): TDateTime;
begin
  Result := ToDate(S, FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToTime(const S: string): TDateTime;
begin
  Result := ToTime(S, FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDateTime(const S: string; out aValue: TDateTime; const aFs: TFormatSettings): Boolean;
begin
  var input := Trim(S);

  if not TryStrToDateTime(input, aValue, aFs) then exit(false);

  var canonical := FormatDateTime(aFs.ShortDateFormat + ' ' + aFs.LongTimeFormat, aValue, aFs);
  Result := SameText(input, canonical);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDate(const S: string; out aValue: TDateTime; const aFs: TFormatSettings): Boolean;
begin
  var input := Trim(S);

  if not TryStrToDate(input, aValue, aFs) then exit(false);

  var canonical := FormatDateTime(aFs.ShortDateFormat, aValue, aFs);
  Result := SameText(input, canonical);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToTime(const S: string; out aValue: TDateTime; const aFs: TFormatSettings): Boolean;
var
  canonical: string;
begin
  var input := Trim(S);

  if not TryStrToTime(input, aValue, aFs) then exit(false);

  if aFs.LongTimeFormat <> '' then
    canonical := FormatDateTime(aFs.LongTimeFormat, aValue, aFs)
  else
    canonical := FormatDateTime(aFs.ShortTimeFormat, aValue, aFs);

  Result := SameText(input, canonical);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTimeOr(const S: string; const aFS: TFormatSettings; const aDefault: TDateTime): TDateTime;
begin
  if not TryToDateTime(S, Result, aFs) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateOr(const S: string; const aFs: TFormatSettings; const aDefault: TDateTime): TDateTime;
begin
  if not TryToDate(S, Result, aFs) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToTimeOr(const S: string; const aFs: TFormatSettings; const aDefault: TDateTime): TDateTime;
begin
  if not TryToTime(S, Result, aFs) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTime(const S: string; const aFs: TFormatSettings): TDateTime;
begin
  if not TryToDateTime(S, Result, aFs) then RaiseStrict('TDateTime', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDate(const S: string; const aFs: TFormatSettings): TDateTime;
begin
  if not TryToDate(S, Result, aFs) then RaiseStrict('TDate', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToTime(const S: string; const aFs: TFormatSettings): TDateTime;
begin
  if not TryToTime(S, Result, aFs) then RaiseStrict('TTime', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDateTimeISO8601(const S: string; out aValue: TDateTime): Boolean;
begin
  Result := TryISO8601ToDate(S, aValue, False);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTimeOrISO8601(const S: string; const aDefault: TDateTime): TDateTime;
begin
  if not TryToDateTimeISO8601(S, Result) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTimeISO8601(const S: string): TDateTime;
begin
  if not TryToDateTimeISO8601(S, Result) then RaiseStrict('ISO-8601 TDateTime', S);
end;

{$endregion}

{$region 'Currency'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToCurrency(const S: string; out aValue: Currency; const aFs: TFormatSettings): Boolean;
begin
  Result := TryStrToCurr(Trim(S), aValue, aFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToCurrencyInv(const S: string; out aValue: Currency): Boolean;
begin
  Result := TryToCurrency(S, aValue, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrencyOr(const S: string; const aDefault: Currency): Currency;
begin
  Result := ToCurrencyOr(S, FormatSettings, aDefault);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrency(const S: string): Currency;
begin
  Result := ToCurrency(S, FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrencyOr(const S: string; const aFs: TFormatSettings; const aDefault: Currency): Currency;
begin
  if not TryToCurrency(S, Result, aFS) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrency(const S: string; const aFs: TFormatSettings): Currency;
begin
  if not TryToCurrency(S, Result, aFs) then RaiseStrict('Currency', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrencyOrInv(const S: string; const aDefault: Currency): Currency;
begin
  Result := ToCurrencyOr(S, InvariantFS, aDefault);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrencyInv(const S: string): Currency;
begin
  Result := ToCurrency(S, InvariantFS);
end;

{$endregion}

{$region 'GUID'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToGuid(const S: string; out aValue: TGUID): Boolean;
begin
  try
    aValue := StringToGUID(Trim(S));
    Result := true;
  except
    aValue := TGUID.Empty;
    Result := false;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToGuidOr(const S: string; const aDefault: TGUID): TGUID;
begin
  if not TryToGuid(S, Result) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToGuid(const S: string): TGUID;
begin
  if not TryToGuid(S, Result) then RaiseStrict('TGUID', S);
end;

{$endregion}

{$region 'Enum'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToEnum<T>(
  const S: string;
  out aValue: T;
  const aIgnoreCase: Boolean;
  const aAllowOrdinal: Boolean
): Boolean;
var
  ordinal: Integer;
begin
  var input := Trim(S);
  var info: PTypeInfo := TypeInfo(T);

  if (info = nil) or (info^.Kind <> tkEnumeration) then exit(false);

  var data := GetTypeData(Info);
  var min := data^.MinValue;
  var max := data^.MaxValue;

  if aAllowOrdinal and TryStrToInt(input, ordinal) then
  begin
    if (ordinal < min) or (ordinal > max) then exit(false);
    SetEnumOrdinal<T>(ordinal, aValue);
    exit(true);
  end;

  if not aIgnoreCase then
  begin
    ordinal := GetEnumValue(info, input);
    if (ordinal < min) or (ordinal > max) then exit(false);
    SetEnumOrdinal<T>(ordinal, aValue);
    exit(true);
  end;

  for ordinal := min to max do
  begin
    var name := GetEnumName(info, ordinal);

    if SameText(name, input) then
    begin
      SetEnumOrdinal<T>(ordinal, aValue);
      exit(true);
    end;
  end;

  Result := false;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToEnumOr<T>(
  const S: string;
  const aDefault: T;
  const aIgnoreCase: Boolean;
  const aAllowOrdinal: Boolean
): T;
begin
  if not TryToEnum<T>(S, Result, aIgnoreCase, aAllowOrdinal) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToEnum<T>(const S: string; const aIgnoreCase: Boolean; const aAllowOrdinal: Boolean): T;
begin
  if not TryToEnum<T>(S, Result, aIgnoreCase, aAllowOrdinal) then RaiseStrict('Enum', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TConvert.SetEnumOrdinal<T>(const aOrdinal: Integer; out aValue: T);
var
  B: Byte;
  SB: ShortInt;
  W: Word;
  SW: SmallInt;
  L: Cardinal;
  SL: Integer;
begin
  var info := TypeInfo(T);
  var data := GetTypeData(info);

  case data^.OrdType of
    otUByte: begin B := Byte(aOrdinal); Move(B, aValue, SizeOf(T)); end;
    otSByte: begin SB := ShortInt(aOrdinal); Move(SB, aValue, SizeOf(T)); end;
    otUWord: begin W := Word(aOrdinal); Move(W, aValue, SizeOf(T)); end;
    otSWord: begin SW := SmallInt(aOrdinal); Move(SW, aValue, SizeOf(T)); end;
    otULong: begin L := Cardinal(aOrdinal); Move(L, aValue, SizeOf(T)); end;
    otSLong: begin SL := Integer(aOrdinal); Move(SL, aValue, SizeOf(T)); end;
  else
    SL := Integer(aOrdinal);
    Move(SL, aValue, SizeOf(T));
  end;
end;

{$endregion}

{$region 'Money'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToMoney(
  const S: string;
  out aValue: Currency;
  const aDecimals: Integer;
  const aFs: TFormatSettings
): Boolean;

  function Pow10U(const N: Integer): UInt64;
  begin
    case N of
      0: Result := 1;
      1: Result := 10;
      2: Result := 100;
      3: Result := 1000;
      4: Result := 10000;
    else
      Result := 0;
    end;
  end;

  function AddDigit(var Acc: UInt64; const Digit: Byte): Boolean;
  begin
    if (Acc > (High(UInt64) div 10)) or ((Acc = (High(UInt64) div 10)) and (Digit > (High(UInt64) mod 10))) then
      exit(false);

    Acc := Acc * 10 + Digit;
    Result := True;
  end;

  function MaxAbsScaledCurrency: UInt64;
  begin
    Result := UInt64(High(Int64)); // Currency stored as scaled Int64 (x10000)
  end;

  function BuildCurrencyScaled(const ScaledAbs: UInt64; const Negative: Boolean): Boolean;
  var
    SignedScaled: Int64;
  begin
    if ScaledAbs > MaxAbsScaledCurrency then exit(false);

    SignedScaled := Int64(ScaledAbs);

    if Negative then
      SignedScaled := -SignedScaled;

    aValue := SignedScaled / 10000.0;
    Result := True;
  end;

begin
  aValue := 0;

  if (aDecimals < 0) or (aDecimals > 4) then Exit(False);

  var input := Trim(S);

  if input = '' then exit(False);

  if (Pos(' ', Input) > 0) or (Pos(#9, input) > 0) or (Pos(#10, input) > 0) or (Pos(#13, input) > 0) then
    exit(False);

  if (aFs.ThousandSeparator <> #0) and (aFs.ThousandSeparator <> #$FFFF) then
    if Pos(aFs.ThousandSeparator, input) > 0 then exit(false);

  if (aFs.CurrencyString <> '') and (Pos(aFs.CurrencyString, input) > 0) then exit(false);

  var i := 1;
  var negative := false;

  if (input[i] = '+') or (input[i] = '-') then
  begin
    negative := (input[i] = '-');
    Inc(i);
    if i > input.Length then exit(false);
  end;

  var sawDigit := False;
  var sawSep := False;
  var fracDigits := 0;
  var intPart : UInt64 := 0;
  var fracPart : UInt64 := 0;

  while i <= input.Length do
  begin
    var ch := input[i];

    if ch = aFs.DecimalSeparator then
    begin
      if sawSep then exit(false);
      sawSep := True;
      Inc(i);
      Continue;
    end;

    if (ch >= '0') and (ch <= '9') then
    begin
      sawDigit := True;
      var digit := Byte(Ord(ch) - Ord('0'));

      if not sawSep then
      begin
        if not AddDigit(intPart, digit) then exit(false);
      end
      else
      begin
        Inc(fracDigits);
        if fracDigits > aDecimals then exit(false);
        if not AddDigit(fracPart, digit) then exit(false);
      end;

      Inc(i);
      Continue;
    end;

    exit(false);
  end;

  if not sawDigit then exit(false);

  if intPart > (MaxAbsScaledCurrency div 10000) then exit(false);

  var scaledAbs := intPart * 10000;

  if fracDigits > 0 then
  begin
    var scaleTo4: UInt64 := Pow10U(4 - fracDigits);
    if fracPart > (MaxAbsScaledCurrency div scaleTo4) then exit(false);
    scaledAbs := scaledAbs + (fracPart * scaleTo4);
  end;

  Result := BuildCurrencyScaled(scaledAbs, negative);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToMoneyInv(const S: string; out aValue: Currency; const aDecimals: Integer): Boolean;
begin
  Result := TryToMoney(S, aValue, aDecimals, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoneyOr(const S: string; const aDecimals: Integer; const aDefault: Currency): Currency;
begin
  Result := ToMoneyOr(S, FormatSettings, aDecimals, aDefault);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoney(const S: string; const aDecimals: Integer): Currency;
begin
  Result := ToMoney(S, FormatSettings, aDecimals);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoneyOr(const S: string; const aFs: TFormatSettings; const aDecimals: Integer; const aDefault: Currency): Currency;
begin
  if not TryToMoney(S, Result, aDecimals, aFs) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoney(const S: string; const aFs: TFormatSettings; const aDecimals: Integer): Currency;
begin
  if not TryToMoney(S, Result, aDecimals, aFs) then RaiseStrict('Money', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoneyOrInv(const S: string; const aDecimals: Integer; const aDefault: Currency): Currency;
begin
  if not TryToMoneyInv(S, Result, aDecimals) then Result := aDefault;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoneyInv(const S: string; const aDecimals: Integer): Currency;
begin
  Result := ToMoney(S, InvariantFS, aDecimals);
end;

{$endregion}

{$region 'Bytes'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToBytesHex(const S: string; out aValue: TBytes): Boolean;

  function HexNibble(const C: Char; out N: Byte): Boolean;
  begin
    case C of
      '0'..'9': begin N := Byte(Ord(C) - Ord('0')); Exit(True); end;
      'a'..'f': begin N := Byte(10 + Ord(C) - Ord('a')); Exit(True); end;
      'A'..'F': begin N := Byte(10 + Ord(C) - Ord('A')); Exit(True); end;
    else
      Exit(false);
    end;
  end;

var
  Hi, Lo: Byte;
begin
  var input := Trim(S);
  var len := input.Length;

  if len = 0 then
  begin
    aValue := nil;
    exit(true);
  end;

  if (len and 1) = 1 then exit(false);

  SetLength(aValue, len div 2);

  for var i := 0 to High(aValue) do
  begin
    if not HexNibble(input[1 + I*2], Hi) then exit(false);
    if not HexNibble(input[2 + I*2], Lo) then exit(false);

    aValue[i] := (Hi shl 4) or Lo;
  end;

  Result := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToBytesBase64(const S: string; out aValue: TBytes): Boolean;
begin
  var input := Trim(S);

  if input = '' then
  begin
    aValue := nil;
    exit(True);
  end;

  try
    var bytes := TNetEncoding.Base64.DecodeStringToBytes(input);
    var canonical := TNetEncoding.Base64.EncodeBytesToString(bytes);

    if canonical <> input then exit(false);

    aValue := bytes;
    Result := True;
  except
    aValue := nil;
    Result := False;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToBytesHexOr(const S: string; const Default: TBytes): TBytes;
begin
  if not TryToBytesHex(S, Result) then Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToBytesBase64Or(const S: string; const Default: TBytes): TBytes;
begin
  if not TryToBytesBase64(S, Result) then Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToBytesHex(const S: string): TBytes;
begin
  if not TryToBytesHex(S, Result) then RaiseStrict('HexBytes', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToBytesBase64(const S: string): TBytes;
begin
  if not TryToBytesBase64(S, Result) then RaiseStrict('Base64Bytes', S);
end;

{$endregion}

{$region 'String'}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.SingleToStringInv(const aValue: Single): string;
begin
  var f := InvariantFS;

  f.ThousandSeparator := #0;

  // 9 digits is the usual "round-trip" precision for Single
  Result := FloatToStrF(aValue, ffGeneral, 9, 0, f);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.DoubleToStringInv(const aValue: Double): string;
begin
  var f := InvariantFS;

  f.ThousandSeparator := #0;

  // 17 digits is the usual "round-trip" precision for Double
  Result := FloatToStrF(aValue, ffGeneral, 17, 0, f);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.CurrencyToStringInv(const aValue: Currency): string;
begin
  var f := InvariantFS;

  f.ThousandSeparator := #0;

  // Currency is fixed scale (4 dp) => emit exactly 4 dp to be canonical
  Result := FormatFloat('0.0000', aValue, f);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.MoneyToStringInv(const aValue: Currency; const aDecimals: Integer): string;
var
  lFormat: string;
begin
  if (aDecimals < 0) or (aDecimals > 4) then
    RaiseStrict('Money', Format('Decimals=%d', [aDecimals]));

  var f := InvariantFS;

  f.ThousandSeparator := #0;

  lFormat := if aDecimals = 0 then '0' else '0.' + StringOfChar('0', aDecimals);

  Result := FormatFloat(lFormat, aValue, f);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.DateTimeToStringISO8601(const aValue: TDateTime): string;
begin
  // local-time semantics preserved (matches TryToDateTimeISO8601 using AInputIsUTC=False)
  Result := DateToISO8601(aValue, false);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.DateToStringISO8601(const aValue: TDateTime): string;
begin
  Result := DateToISO8601(aValue, false);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TimeToStringISO8601(const aValue: TDateTime): string;
begin
  // Time-only ISO-like form; keep it deterministic and culture-independent
  Result := FormatDateTime('hh":"nn":"ss', aValue, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.BytesToBase64StringInv(const aValue: TBytes): string;
begin
  if Length(aValue) = 0 then exit('');

  Result := System.NetEncoding.TNetEncoding.Base64.EncodeBytesToString(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.BytesToHexStringInv(const aValue: TBytes): string;
const
  HexChars: array[0..15] of Char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
begin
  if Length(aValue) = 0 then exit('');

  SetLength(Result, Length(aValue) * 2);

  for var i := 0 to High(aValue) do
  begin
    var b := aValue[i];

    Result[(i * 2) + 1] := HexChars[b shr 4];
    Result[(i * 2) + 2] := HexChars[b and $0F];
  end;
end;

{$endregion}

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.HexValue(c: Char): Integer;
begin
  case C of
    '0'..'9': Result := Ord(C) - Ord('0');
    'A'..'F': Result := Ord(C) - Ord('A') + 10;
    'a'..'f': Result := Ord(C) - Ord('a') + 10;
  else
    raise Exception.Create('Invalid hex digit');
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.DecimalValue(c: Char): Integer;
begin
  if (c < '0') or (c > '9') then
    raise Exception.Create('Invalid decimal digit');

  Result := Ord(c) - Ord('0');
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.CodePointToString(aCodePoint: Integer): string;
begin
  if aCodePoint <= $FFFF then
  begin
    // BMP character (no surrogate needed)
    Result := Char(aCodePoint);
  end
  else
  begin
    // Non-BMP character => UTF-16 surrogate pair
    Dec(aCodePoint, $10000);

    Result :=
      Char($D800 + (aCodePoint shr 10)) +   // high surrogate
      Char($DC00 + (aCodePoint and $3FF));  // low surrogate
  end;
end;

end.

