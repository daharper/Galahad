{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Conversions
  Author:      David Harper
  License:     MIT
  History:     2026-08-02  Initial version 0.1
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
    class procedure SetEnumOrdinal<T>(const Ordinal: Integer; out Value: T); static;
    class procedure RaiseStrict(const TypeName, S: string); static;
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
    class function TryToInt(const S: string; out Value: Integer): Boolean; static;

    /// <summary>Parses an Integer or returns Default if parsing fails.</summary>
    class function ToIntOr(const S: string; const Default: Integer = 0): Integer; static;

    /// <summary>Strictly parses an Integer; raises EStrictConvertError on failure.</summary>
    class function ToInt(const S: string): Integer; static;

    {------------------------------------------------- Int64 -----------------------------------------------------}

    /// <summary>Tries to strictly parse an Int64 from S.</summary>
    class function TryToInt64(const S: string; out Value: Int64): Boolean; static;

    /// <summary>Parses an Int64 or returns Default if parsing fails.</summary>
    class function ToInt64Or(const S: string; const Default: Int64 = 0): Int64; static;

    /// <summary>Strictly parses an Int64; raises EStrictConvertError on failure.</summary>
    class function ToInt64(const S: string): Int64; static;

    {----------------------------------------------- Unsigned ----------------------------------------------------}

    /// <summary>Tries to strictly parse a UInt32 (Cardinal) from S.</summary>
    class function TryToUInt32(const S: string; out Value: Cardinal): Boolean; static;

    /// <summary>Tries to strictly parse a UInt64 from S.</summary>
    class function TryToUInt64(const S: string; out Value: UInt64): Boolean; static;

    /// <summary>Parses a UInt32 or returns Default if parsing fails.</summary>
    class function ToUInt32Or(const S: string; const Default: Cardinal = 0): Cardinal; static;

    /// <summary>Parses a UInt64 or returns Default if parsing fails.</summary>
    class function ToUInt64Or(const S: string; const Default: UInt64 = 0): UInt64; static;

    /// <summary>Strictly parses a UInt32; raises EStrictConvertError on failure.</summary>
    class function ToUInt32(const S: string): Cardinal; static;

    /// <summary>Strictly parses a UInt64; raises EStrictConvertError on failure.</summary>
    class function ToUInt64(const S: string): UInt64; static;

    {----------------------------------------------- Boolean -----------------------------------------------------}

    /// <summary>Tries to strictly parse a Boolean from S.</summary>
    /// <remarks>Accepts: True/False, T/F, Yes/No, Y/N, 1/0 (case-insensitive).</remarks>
    class function TryToBool(const S: string; out Value: Boolean): Boolean; static;

    /// <summary>Parses a Boolean or returns Default if parsing fails.</summary>
    class function ToBoolOr(const S: string; const Default: Boolean = False): Boolean; static;

    /// <summary>Strictly parses a Boolean; raises EStrictConvertError on failure.</summary>
    class function ToBool(const S: string): Boolean; static;

    {------------------------------------------------- Char ------------------------------------------------------}

    /// <summary>Tries to parse a single character; succeeds only when Length(S)=1.</summary>
    class function TryToChar(const S: string; out Value: Char): Boolean; static;

    /// <summary>Parses a Char or returns Default if parsing fails.</summary>
    class function ToCharOr(const S: string; const Default: Char = #0): Char; static;

    /// <summary>Strictly parses a Char; raises EStrictConvertError on failure.</summary>
    class function ToChar(const S: string): Char; static;

    {------------------------------------------------ Single -----------------------------------------------------}

    /// <summary>
    /// Tries to parse a Single using the current locale.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToSingle(const S: string; out Value: Single): Boolean; overload; static;

    /// <summary>Parses a Single using the current locale or returns Default if parsing fails.</summary>
    class function ToSingleOr(const S: string; const Default: Single = 0): Single; overload; static;

    /// <summary>Strictly parses a Single using the current locale; raises EStrictConvertError on failure.</summary>
    class function ToSingle(const S: string): Single; overload; static;

    /// <summary>
    /// Tries to parse a Single using the supplied format settings.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToSingle(const S: string; out Value: Single; const FS: TFormatSettings): Boolean; overload; static;

    /// <summary>Parses a Single using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToSingleOr(const S: string; const FS: TFormatSettings; const Default: Single = 0): Single; overload; static;

    /// <summary>Strictly parses a Single using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToSingle(const S: string; const FS: TFormatSettings): Single; overload; static;

    /// <summary>
    /// Tries to parse a Single using invariant (culture-independent) settings.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToSingleInv(const S: string; out Value: Single): Boolean; static;

    /// <summary>Parses a Single using invariant settings or returns Default if parsing fails.</summary>
    class function ToSingleOrInv(const S: string; const Default: Single = 0): Single; static;

    /// <summary>Strictly parses a Single using invariant settings; raises EStrictConvertError on failure.</summary>
    class function ToSingleInv(const S: string): Single; static;

    {------------------------------------------------ Double -----------------------------------------------------}

    /// <summary>
    /// Tries to parse a Double using the current locale.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToDouble(const S: string; out Value: Double): Boolean; overload; static;

    /// <summary>Parses a Double using the current locale or returns Default if parsing fails.</summary>
    class function ToDoubleOr(const S: string; const Default: Double = 0): Double; overload; static;

    /// <summary>Strictly parses a Double using the current locale; raises EStrictConvertError on failure.</summary>
    class function ToDouble(const S: string): Double; overload; static;

    /// <summary>
    /// Tries to parse a Double using the supplied format settings.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToDouble(const S: string; out Value: Double; const FS: TFormatSettings): Boolean; overload; static;

    /// <summary>Parses a Double using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToDoubleOr(const S: string; const FS: TFormatSettings; const Default: Double = 0): Double; overload; static;

    /// <summary>Strictly parses a Double using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToDouble(const S: string; const FS: TFormatSettings): Double; overload; static;

    /// <summary>
    /// Tries to parse a Double using invariant (culture-independent) settings.
    /// Parsing is strict: no rounding, no truncation, and no trailing characters.
    /// </summary>
    class function TryToDoubleInv(const S: string; out Value: Double): Boolean; static;

    /// <summary>Parses a Double using invariant settings or returns Default if parsing fails.</summary>
    class function ToDoubleOrInv(const S: string; const Default: Double = 0): Double; static;

    /// <summary>Strictly parses a Double using invariant settings; raises EStrictConvertError on failure.</summary>
    class function ToDoubleInv(const S: string): Double; static;

    {---------------------------------------------- Date / Time --------------------------------------------------}

    /// <summary>
    /// Tries to strictly parse a date and time using the current locale.
    /// Input must exactly match the expected format; trailing or partial input is rejected.
    /// </summary>
    class function TryToDateTime(const S: string; out Value: TDateTime): Boolean; overload; static;

    /// <summary>
    /// Tries to strictly parse a date (date-only) using the current locale.
    /// Time components, trailing characters, or ambiguous input are rejected.
    /// </summary>
    class function TryToDate(const S: string; out Value: TDateTime): Boolean; overload; static;

    /// <summary>
    /// Tries to strictly parse a time (time-only) using the current locale.
    /// Date components, trailing characters, or ambiguous input are rejected.
    /// </summary>
    class function TryToTime(const S: string; out Value: TDateTime): Boolean; overload; static;

    /// <summary>Parses a date and time using the current locale or returns Default if parsing fails.</summary>
    class function ToDateTimeOr(const S: string; const Default: TDateTime = 0): TDateTime; overload; static;

    /// <summary>Parses a date using the current locale or returns Default if parsing fails.</summary>
    class function ToDateOr(const S: string; const Default: TDateTime = 0): TDateTime; overload; static;

    /// <summary>Parses a time using the current locale or returns Default if parsing fails.</summary>
    class function ToTimeOr(const S: string; const Default: TDateTime = 0): TDateTime; overload; static;

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
    class function TryToDateTime(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean; overload; static;

    /// <summary>
    /// Tries to strictly parse a date (date-only) using the supplied format settings.
    /// Input must exactly match the specified format; no coercion is performed.
    /// </summary>
    class function TryToDate(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean; overload; static;

    /// <summary>
    /// Tries to strictly parse a time (time-only) using the supplied format settings.
    /// Input must exactly match the specified format; no coercion is performed.
    /// </summary>
    class function TryToTime(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean; overload; static;

    /// <summary>Parses a date and time using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToDateTimeOr(const S: string; const FS: TFormatSettings; const Default: TDateTime = 0): TDateTime; overload; static;

    /// <summary>Parses a date using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToDateOr(const S: string; const FS: TFormatSettings; const Default: TDateTime = 0): TDateTime; overload; static;

    /// <summary>Parses a time using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToTimeOr(const S: string; const FS: TFormatSettings; const Default: TDateTime = 0): TDateTime; overload; static;

    /// <summary>Strictly parses a date and time using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToDateTime(const S: string; const FS: TFormatSettings): TDateTime; overload; static;

    /// <summary>Strictly parses a date using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToDate(const S: string; const FS: TFormatSettings): TDateTime; overload; static;

    /// <summary>Strictly parses a time using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToTime(const S: string; const FS: TFormatSettings): TDateTime; overload; static;

    /// <summary>
    /// Tries to parse an ISO 8601 date/time string.
    /// Parsing is strict; local-time semantics are preserved (no timezone normalization).
    /// </summary>
    class function TryToDateTimeISO8601(const S: string; out Value: TDateTime): Boolean; static;

    /// <summary>Parses ISO 8601 date/time or returns Default if parsing fails.</summary>
    class function ToDateTimeOrISO8601(const S: string; const Default: TDateTime = 0): TDateTime; static;

    /// <summary>Strictly parses ISO 8601 date/time; raises EStrictConvertError on failure.</summary>
    class function ToDateTimeISO8601(const S: string): TDateTime; static;

    {------------------------------- Currency (RTL-style parsing, locale-aware) ----------------------------------}

    /// <summary>
    /// Tries to parse a Currency value using the supplied format settings.
    /// Parsing follows RTL rules and may round according to Currency scale.
    /// </summary>
    class function TryToCurrency(const S: string; out Value: Currency; const FS: TFormatSettings): Boolean; static;

    /// <summary>
    /// Tries to parse a Currency value using invariant (culture-independent) settings.
    /// Parsing follows RTL rules and may round according to Currency scale.
    /// </summary>
    class function TryToCurrencyInv(const S: string; out Value: Currency): Boolean; static;

    /// <summary>Parses Currency using the current locale or returns Default if parsing fails.</summary>
    class function ToCurrencyOr(const S: string; const Default: Currency = 0): Currency; overload; static;

    /// <summary>Strictly parses Currency using the current locale; raises EStrictConvertError on failure.</summary>
    class function ToCurrency(const S: string): Currency; overload; static;

    /// <summary>Parses Currency using the supplied format settings or returns Default if parsing fails.</summary>
    class function ToCurrencyOr(const S: string; const FS: TFormatSettings; const Default: Currency = 0): Currency; overload; static;

    /// <summary>Strictly parses Currency using the supplied format settings; raises EStrictConvertError on failure.</summary>
    class function ToCurrency(const S: string; const FS: TFormatSettings): Currency; overload; static;

    /// <summary>Parses Currency using invariant settings or returns Default if parsing fails.</summary>
    class function ToCurrencyOrInv(const S: string; const Default: Currency = 0): Currency; static;

    /// <summary>Strictly parses Currency using invariant settings; raises EStrictConvertError on failure.</summary>
    class function ToCurrencyInv(const S: string): Currency; static;

    {------------------------------------------------- GUID ------------------------------------------------------}

    /// <summary>Tries to parse a GUID string into a TGUID.</summary>
    class function TryToGuid(const S: string; out Value: TGUID): Boolean; static;

    /// <summary>Parses a GUID or returns Default if parsing fails.</summary>
    class function ToGuidOr(const S: string; const Default: TGUID): TGUID; static;

    /// <summary>Strictly parses a GUID; raises EStrictConvertError on failure.</summary>
    class function ToGuid(const S: string): TGUID; static;

    {------------------------------------  Money (strict policy parsing) -----------------------------------------}

    /// <summary>
    /// Tries to strictly parse a monetary value using a fixed decimal policy.
    /// No rounding or truncation is performed; invalid input is rejected.
    /// </summary>
    class function TryToMoney(
      const S: string;
      out Value: Currency;
      const Decimals: Integer;
      const FS: TFormatSettings
    ): Boolean; static;

    /// <summary>
    /// Tries to strictly parse a monetary value using invariant settings.
    /// No rounding, no truncation, and no coercion; exact decimal precision is enforced.
    /// </summary>
    class function TryToMoneyInv(
      const S: string;
      out Value: Currency;
      const Decimals: Integer
    ): Boolean; static;

    /// <summary>
    /// Parses money using the current locale and fixed decimal policy.
    /// No rounding is ever performed; input must conform exactly to the policy.
    /// </summary>
    class function ToMoneyOr(const S: string; const Decimals: Integer = 2; const Default: Currency = 0): Currency; overload; static;

    /// <summary>Strictly parses money using the current locale and Decimals policy; raises EStrictConvertError on failure.</summary>
    class function ToMoney(const S: string; const Decimals: Integer): Currency; overload; static;

    /// <summary>Parses money using the supplied format settings and Decimals policy, or returns Default if parsing fails.</summary>
    class function ToMoneyOr(const S: string; const FS: TFormatSettings; const Decimals: Integer = 2; const Default: Currency = 0): Currency; overload; static;

    /// <summary>Strictly parses money using the supplied format settings and Decimals policy; raises EStrictConvertError on failure.</summary>
    class function ToMoney(const S: string; const FS: TFormatSettings; const Decimals: Integer): Currency; overload; static;

    /// <summary>Parses money using invariant settings and Decimals policy, or returns Default if parsing fails.</summary>
    class function ToMoneyOrInv(const S: string; const Decimals: Integer = 2; const Default: Currency = 0): Currency; static;

    /// <summary>
    /// Strictly parses money using invariant settings and fixed decimal policy.
    /// Any deviation from the expected format results in failure.
    /// </summary>
    class function ToMoneyInv(const S: string; const Decimals: Integer): Currency; static;

    {------------------------------------------------- Enum ------------------------------------------------------}

    /// <summary>Tries to convert S to an enum value of type T (by name, and optionally ordinal).</summary>
    class function TryToEnum<T>(
      const S: string;
      out Value: T;
      const IgnoreCase: Boolean = True;
      const AllowOrdinal: Boolean = False
    ): Boolean; static;

    /// <summary>Converts S to an enum value of type T, or returns Default if parsing fails.</summary>
    class function ToEnumOr<T>(
      const S: string;
      const Default: T;
      const IgnoreCase: Boolean = True;
      const AllowOrdinal: Boolean = False
    ): T; static;

    /// <summary>Strictly converts S to an enum value of type T; raises EStrictConvertError on failure.</summary>
    class function ToEnum<T>(
      const S: string;
      const IgnoreCase: Boolean = True;
      const AllowOrdinal: Boolean = False
    ): T; static;

    {------------------------------------------  Bytes decoding --------------------------------------------------}

    /// <summary>Tries to decode a hexadecimal string into a byte array.</summary>
    class function TryToBytesHex(const S: string; out Value: TBytes): Boolean; static;

    /// <summary>Tries to decode a Base64 string into a byte array (strict canonical validation).</summary>
    class function TryToBytesBase64(const S: string; out Value: TBytes): Boolean; static;

    /// <summary>Decodes a hexadecimal string or returns Default if decoding fails.</summary>
    class function ToBytesHexOr(const S: string; const Default: TBytes): TBytes; static;

    /// <summary>Decodes a Base64 string or returns Default if decoding fails.</summary>
    class function ToBytesBase64Or(const S: string; const Default: TBytes): TBytes; static;

    /// <summary>Strictly decodes a hexadecimal string; raises EStrictConvertError on failure.</summary>
    class function ToBytesHex(const S: string): TBytes; static;

    /// <summary>Strictly decodes a Base64 string; raises EStrictConvertError on failure.</summary>
    class function ToBytesBase64(const S: string): TBytes; static;
  end;

implementation

uses
  System.TypInfo,
  System.NetEncoding,
  Base.Integrity;

{--------------------------------------}
{ Core helpers }
{--------------------------------------}

class procedure TConvert.RaiseStrict(const TypeName, S: string);
begin
  var E := EStrictConvertError.CreateFmt('Cannot convert "%s" to %s.', [S, TypeName]);
  TError.Notify(E);
  raise E;
end;

class function TConvert.InvariantFS: TFormatSettings;
begin
  Result := TFormatSettings.Invariant;
end;

{--------------------------------------}
{ Integer / Int64 }
{--------------------------------------}

class function TConvert.TryToInt(const S: string; out Value: Integer): Boolean;
begin
  Result := TryStrToInt(S, Value);
end;

class function TConvert.ToIntOr(const S: string; const Default: Integer): Integer;
begin
  if not TryToInt(S, Result) then
    Result := Default;
end;

class function TConvert.ToInt(const S: string): Integer;
begin
  if not TryToInt(S, Result) then
    RaiseStrict('Integer', S);
end;

class function TConvert.TryToInt64(const S: string; out Value: Int64): Boolean;
begin
  Result := TryStrToInt64(S, Value);
end;

class function TConvert.ToInt64Or(const S: string; const Default: Int64): Int64;
begin
  if not TryToInt64(S, Result) then
    Result := Default;
end;

class function TConvert.ToInt64(const S: string): Int64;
begin
  if not TryToInt64(S, Result) then
    RaiseStrict('Int64', S);
end;

{--------------------------------------}
{ Unsigned }
{--------------------------------------}

class function TConvert.TryToUInt64(const S: string; out Value: UInt64): Boolean;
var
  Input: string;
  I64: Int64;
begin
  Input := Trim(S);

  if (Input = '') or (Input[1] = '-') then
    Exit(False);

  if TryStrToInt64(Input, I64) then
  begin
    if I64 < 0 then Exit(False);
    Value := UInt64(I64);
    Exit(True);
  end;

  Value := 0;
  for var Ch in Input do
  begin
    if not CharInSet(Ch, ['0'..'9']) then
      Exit(False);

    var Digit := Ord(Ch) - Ord('0');

    if (Value > (High(UInt64) div 10)) or
       ((Value = (High(UInt64) div 10)) and (UInt64(Digit) > (High(UInt64) mod 10))) then
      Exit(False);

    Value := Value * 10 + UInt64(Digit);
  end;

  Result := True;
end;

class function TConvert.TryToUInt32(const S: string; out Value: Cardinal): Boolean;
var
  U64: UInt64;
begin
  if not TryToUInt64(S, U64) then
    Exit(False);

  if U64 > High(Cardinal) then
    Exit(False);

  Value := Cardinal(U64);
  Result := True;
end;

class function TConvert.ToUInt64Or(const S: string; const Default: UInt64): UInt64;
begin
  if not TryToUInt64(S, Result) then
    Result := Default;
end;

class function TConvert.ToUInt32Or(const S: string; const Default: Cardinal): Cardinal;
begin
  if not TryToUInt32(S, Result) then
    Result := Default;
end;

class function TConvert.ToUInt64(const S: string): UInt64;
begin
  if not TryToUInt64(S, Result) then
    RaiseStrict('UInt64', S);
end;

class function TConvert.ToUInt32(const S: string): Cardinal;
begin
  if not TryToUInt32(S, Result) then
    RaiseStrict('UInt32', S);
end;

{--------------------------------------}
{ Boolean / Char }
{--------------------------------------}

class function TConvert.TryToBool(const S: string; out Value: Boolean): Boolean;
var
  Input: string;
begin
  Input := Trim(S);

  if Input = '' then
    Exit(False);

  // True values
  if SameText(Input, 'true') or
     SameText(Input, 't') or
     SameText(Input, 'yes') or
     SameText(Input, 'y') or
     (Input = '1') then
  begin
    Value := True;
    Exit(True);
  end;

  // False values
  if SameText(Input, 'false') or
     SameText(Input, 'f') or
     SameText(Input, 'no') or
     SameText(Input, 'n') or
     (Input = '0') then
  begin
    Value := False;
    Exit(True);
  end;

  Result := False;
end;


class function TConvert.ToBoolOr(const S: string; const Default: Boolean): Boolean;
begin
  if not TryToBool(S, Result) then
    Result := Default;
end;

class function TConvert.ToBool(const S: string): Boolean;
begin
  if not TryToBool(S, Result) then
    RaiseStrict('Boolean', S);
end;

class function TConvert.TryToChar(const S: string; out Value: Char): Boolean;
begin
  Result := Length(S) = 1;
  if Result then
    Value := S[1]
  else
    Value := #0;
end;

class function TConvert.ToCharOr(const S: string; const Default: Char): Char;
begin
  if not TryToChar(S, Result) then
    Result := Default;
end;

class function TConvert.ToChar(const S: string): Char;
begin
  if not TryToChar(S, Result) then
    RaiseStrict('Char', S);
end;

{--------------------------------------}
{ Single }
{--------------------------------------}

class function TConvert.TryToSingle(const S: string; out Value: Single): Boolean;
begin
  Result := TryToSingle(S, Value, System.SysUtils.FormatSettings);
end;

class function TConvert.ToSingleOr(const S: string; const Default: Single): Single;
begin
  Result := ToSingleOr(S, System.SysUtils.FormatSettings, Default);
end;

class function TConvert.ToSingle(const S: string): Single;
begin
  Result := ToSingle(S, System.SysUtils.FormatSettings);
end;

class function TConvert.TryToSingle(const S: string; out Value: Single; const FS: TFormatSettings): Boolean;
begin
  Result := TryStrToFloat(S, Value, FS);
end;

class function TConvert.ToSingleOr(const S: string; const FS: TFormatSettings; const Default: Single): Single;
begin
  if not TryToSingle(S, Result, FS) then
    Result := Default;
end;

class function TConvert.ToSingle(const S: string; const FS: TFormatSettings): Single;
begin
  if not TryToSingle(S, Result, FS) then
    RaiseStrict('Single', S);
end;

class function TConvert.TryToSingleInv(const S: string; out Value: Single): Boolean;
begin
  Result := TryToSingle(S, Value, InvariantFS);
end;

class function TConvert.ToSingleOrInv(const S: string; const Default: Single): Single;
begin
  Result := ToSingleOr(S, InvariantFS, Default);
end;

class function TConvert.ToSingleInv(const S: string): Single;
begin
  Result := ToSingle(S, InvariantFS);
end;

{--------------------------------------}
{ Double }
{--------------------------------------}

class function TConvert.TryToDouble(const S: string; out Value: Double): Boolean;
begin
  Result := TryToDouble(S, Value, System.SysUtils.FormatSettings);
end;

class function TConvert.ToDoubleOr(const S: string; const Default: Double): Double;
begin
  Result := ToDoubleOr(S, System.SysUtils.FormatSettings, Default);
end;

class function TConvert.ToDouble(const S: string): Double;
begin
  Result := ToDouble(S, System.SysUtils.FormatSettings);
end;

class function TConvert.TryToDouble(const S: string; out Value: Double; const FS: TFormatSettings): Boolean;
begin
  Result := TryStrToFloat(S, Value, FS);
end;

class function TConvert.ToDoubleOr(const S: string; const FS: TFormatSettings; const Default: Double): Double;
begin
  if not TryToDouble(S, Result, FS) then
    Result := Default;
end;

class function TConvert.ToDouble(const S: string; const FS: TFormatSettings): Double;
begin
  if not TryToDouble(S, Result, FS) then
    RaiseStrict('Double', S);
end;

class function TConvert.TryToDoubleInv(const S: string; out Value: Double): Boolean;
begin
  Result := TryToDouble(S, Value, InvariantFS);
end;

class function TConvert.ToDoubleOrInv(const S: string; const Default: Double): Double;
begin
  Result := ToDoubleOr(S, InvariantFS, Default);
end;

class function TConvert.ToDoubleInv(const S: string): Double;
begin
  Result := ToDouble(S, InvariantFS);
end;

{--------------------------------------}
{ Date / Time }
{--------------------------------------}

class function TConvert.TryToDateTime(const S: string; out Value: TDateTime): Boolean;
begin
  Result := TryToDateTime(S, Value, System.SysUtils.FormatSettings);
end;

class function TConvert.TryToDate(const S: string; out Value: TDateTime): Boolean;
begin
  Result := TryToDate(S, Value, System.SysUtils.FormatSettings);
end;

class function TConvert.TryToTime(const S: string; out Value: TDateTime): Boolean;
begin
  Result := TryToTime(S, Value, System.SysUtils.FormatSettings);
end;

class function TConvert.ToDateTimeOr(const S: string; const Default: TDateTime): TDateTime;
begin
  Result := ToDateTimeOr(S, System.SysUtils.FormatSettings, Default);
end;

class function TConvert.ToDateOr(const S: string; const Default: TDateTime): TDateTime;
begin
  Result := ToDateOr(S, System.SysUtils.FormatSettings, Default);
end;

class function TConvert.ToTimeOr(const S: string; const Default: TDateTime): TDateTime;
begin
  Result := ToTimeOr(S, System.SysUtils.FormatSettings, Default);
end;

class function TConvert.ToDateTime(const S: string): TDateTime;
begin
  Result := ToDateTime(S, System.SysUtils.FormatSettings);
end;

class function TConvert.ToDate(const S: string): TDateTime;
begin
  Result := ToDate(S, System.SysUtils.FormatSettings);
end;

class function TConvert.ToTime(const S: string): TDateTime;
begin
  Result := ToTime(S, System.SysUtils.FormatSettings);
end;

class function TConvert.TryToDateTime(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean;
var
  Canonical, Input: string;
begin
  Input := Trim(S);

  if not TryStrToDateTime(Input, Value, FS) then
    Exit(False);

  Canonical := FormatDateTime(FS.ShortDateFormat + ' ' + FS.LongTimeFormat, Value, FS);
  Result := SameText(Input, Canonical);
end;

class function TConvert.TryToDate(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean;
var
  Canonical, Input: string;
begin
  Input := Trim(S);

  if not TryStrToDate(Input, Value, FS) then
    Exit(False);

  Canonical := FormatDateTime(FS.ShortDateFormat, Value, FS);
  Result := SameText(Input, Canonical);
end;

class function TConvert.TryToTime(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean;
var
  Canonical, Input: string;
begin
  Input := Trim(S);

  if not TryStrToTime(Input, Value, FS) then
    Exit(False);

  if FS.LongTimeFormat <> '' then
    Canonical := FormatDateTime(FS.LongTimeFormat, Value, FS)
  else
    Canonical := FormatDateTime(FS.ShortTimeFormat, Value, FS);

  Result := SameText(Input, Canonical);
end;

class function TConvert.ToDateTimeOr(const S: string; const FS: TFormatSettings; const Default: TDateTime): TDateTime;
begin
  if not TryToDateTime(S, Result, FS) then
    Result := Default;
end;

class function TConvert.ToDateOr(const S: string; const FS: TFormatSettings; const Default: TDateTime): TDateTime;
begin
  if not TryToDate(S, Result, FS) then
    Result := Default;
end;

class function TConvert.ToTimeOr(const S: string; const FS: TFormatSettings; const Default: TDateTime): TDateTime;
begin
  if not TryToTime(S, Result, FS) then
    Result := Default;
end;

class function TConvert.ToDateTime(const S: string; const FS: TFormatSettings): TDateTime;
begin
  if not TryToDateTime(S, Result, FS) then
    RaiseStrict('TDateTime', S);
end;

class function TConvert.ToDate(const S: string; const FS: TFormatSettings): TDateTime;
begin
  if not TryToDate(S, Result, FS) then
    RaiseStrict('TDate', S);
end;

class function TConvert.ToTime(const S: string; const FS: TFormatSettings): TDateTime;
begin
  if not TryToTime(S, Result, FS) then
    RaiseStrict('TTime', S);
end;

class function TConvert.TryToDateTimeISO8601(const S: string; out Value: TDateTime): Boolean;
begin
  Result := TryISO8601ToDate(S, Value, False);
end;

class function TConvert.ToDateTimeOrISO8601(const S: string; const Default: TDateTime): TDateTime;
begin
  if not TryToDateTimeISO8601(S, Result) then
    Result := Default;
end;

class function TConvert.ToDateTimeISO8601(const S: string): TDateTime;
begin
  if not TryToDateTimeISO8601(S, Result) then
    RaiseStrict('ISO-8601 TDateTime', S);
end;

{--------------------------------------}
{ Currency }
{--------------------------------------}

class function TConvert.TryToCurrency(const S: string; out Value: Currency; const FS: TFormatSettings): Boolean;
begin
  Result := TryStrToCurr(Trim(S), Value, FS);
end;

class function TConvert.TryToCurrencyInv(const S: string; out Value: Currency): Boolean;
begin
  Result := TryToCurrency(S, Value, InvariantFS);
end;

class function TConvert.ToCurrencyOr(const S: string; const Default: Currency): Currency;
begin
  Result := ToCurrencyOr(S, System.SysUtils.FormatSettings, Default);
end;

class function TConvert.ToCurrency(const S: string): Currency;
begin
  Result := ToCurrency(S, System.SysUtils.FormatSettings);
end;

class function TConvert.ToCurrencyOr(const S: string; const FS: TFormatSettings; const Default: Currency): Currency;
begin
  if not TryToCurrency(S, Result, FS) then
    Result := Default;
end;

class function TConvert.ToCurrency(const S: string; const FS: TFormatSettings): Currency;
begin
  if not TryToCurrency(S, Result, FS) then
    RaiseStrict('Currency', S);
end;

class function TConvert.ToCurrencyOrInv(const S: string; const Default: Currency): Currency;
begin
  Result := ToCurrencyOr(S, InvariantFS, Default);
end;

class function TConvert.ToCurrencyInv(const S: string): Currency;
begin
  Result := ToCurrency(S, InvariantFS);
end;

{--------------------------------------}
{ GUID }
{--------------------------------------}

class function TConvert.TryToGuid(const S: string; out Value: TGUID): Boolean;
begin
  try
    Value := StringToGUID(Trim(S));
    Result := True;
  except
    Value := TGUID.Empty;
    Result := False;
  end;
end;

class function TConvert.ToGuidOr(const S: string; const Default: TGUID): TGUID;
begin
  if not TryToGuid(S, Result) then
    Result := Default;
end;

class function TConvert.ToGuid(const S: string): TGUID;
begin
  if not TryToGuid(S, Result) then
    RaiseStrict('TGUID', S);
end;

{--------------------------------------}
{ Enum parsing }
{--------------------------------------}

class function TConvert.TryToEnum<T>(
  const S: string;
  out Value: T;
  const IgnoreCase: Boolean;
  const AllowOrdinal: Boolean
): Boolean;
var
  Info: PTypeInfo;
  Data: PTypeData;
  Input: string;
  MinV, MaxV: Integer;
  Ordinal: Integer;
  Name: string;
begin
  Input := Trim(S);
  Info := TypeInfo(T);

  if (Info = nil) or (Info^.Kind <> tkEnumeration) then
    Exit(False);

  Data := GetTypeData(Info);
  MinV := Data^.MinValue;
  MaxV := Data^.MaxValue;

  if AllowOrdinal and TryStrToInt(Input, Ordinal) then
  begin
    if (Ordinal < MinV) or (Ordinal > MaxV) then Exit(False);
    SetEnumOrdinal<T>(Ordinal, Value);
    Exit(True);
  end;

  if not IgnoreCase then
  begin
    Ordinal := GetEnumValue(Info, Input);
    if (Ordinal < MinV) or (Ordinal > MaxV) then Exit(False);
    SetEnumOrdinal<T>(Ordinal, Value);
    Exit(True);
  end;

  for Ordinal := MinV to MaxV do
  begin
    Name := GetEnumName(Info, Ordinal);
    if SameText(Name, Input) then
    begin
      SetEnumOrdinal<T>(Ordinal, Value);
      Exit(True);
    end;
  end;

  Result := False;
end;

class function TConvert.ToEnumOr<T>(
  const S: string;
  const Default: T;
  const IgnoreCase: Boolean;
  const AllowOrdinal: Boolean
): T;
begin
  if not TryToEnum<T>(S, Result, IgnoreCase, AllowOrdinal) then
    Result := Default;
end;

class function TConvert.ToEnum<T>(
  const S: string;
  const IgnoreCase: Boolean;
  const AllowOrdinal: Boolean
): T;
begin
  if not TryToEnum<T>(S, Result, IgnoreCase, AllowOrdinal) then
    RaiseStrict('Enum', S);
end;

class procedure TConvert.SetEnumOrdinal<T>(const Ordinal: Integer; out Value: T);
var
  Info: PTypeInfo;
  Data: PTypeData;
  B: Byte;
  SB: ShortInt;
  W: Word;
  SW: SmallInt;
  L: Cardinal;
  SL: Integer;
begin
  Info := TypeInfo(T);
  Data := GetTypeData(Info);

  case Data^.OrdType of
    otUByte: begin B := Byte(Ordinal); Move(B, Value, SizeOf(T)); end;
    otSByte: begin SB := ShortInt(Ordinal); Move(SB, Value, SizeOf(T)); end;
    otUWord: begin W := Word(Ordinal); Move(W, Value, SizeOf(T)); end;
    otSWord: begin SW := SmallInt(Ordinal); Move(SW, Value, SizeOf(T)); end;
    otULong: begin L := Cardinal(Ordinal); Move(L, Value, SizeOf(T)); end;
    otSLong: begin SL := Integer(Ordinal); Move(SL, Value, SizeOf(T)); end;
  else
    SL := Integer(Ordinal);
    Move(SL, Value, SizeOf(T));
  end;
end;

{--------------------------------------}
{ Money (strict policy parsing) }
{--------------------------------------}

class function TConvert.TryToMoney(
  const S: string;
  out Value: Currency;
  const Decimals: Integer;
  const FS: TFormatSettings
): Boolean;
var
  Input: string;
  I: Integer;
  Ch: Char;
  SawDigit, SawSep: Boolean;
  FracDigits: Integer;
  IntPart, FracPart: UInt64;

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
    if (Acc > (High(UInt64) div 10)) or
       ((Acc = (High(UInt64) div 10)) and (Digit > (High(UInt64) mod 10))) then
      Exit(False);
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
    if ScaledAbs > MaxAbsScaledCurrency then
      Exit(False);

    SignedScaled := Int64(ScaledAbs);
    if Negative then
      SignedScaled := -SignedScaled;

    Value := SignedScaled / 10000.0;
    Result := True;
  end;

var
  Digit: Byte;
  Negative: Boolean;
  ScaleTo4: UInt64;
  ScaledAbs: UInt64;
begin
  Value := 0;
  Result := False;

  if (Decimals < 0) or (Decimals > 4) then Exit(False);

  Input := Trim(S);
  if Input = '' then Exit(False);

  if (Pos(' ', Input) > 0) or (Pos(#9, Input) > 0) or (Pos(#10, Input) > 0) or (Pos(#13, Input) > 0) then
    Exit(False);

  if (FS.ThousandSeparator <> #0) and (FS.ThousandSeparator <> #$FFFF) then
    if Pos(FS.ThousandSeparator, Input) > 0 then
      Exit(False);

  if (FS.CurrencyString <> '') and (Pos(FS.CurrencyString, Input) > 0) then
    Exit(False);

  I := 1;
  Negative := False;

  if (Input[I] = '+') or (Input[I] = '-') then
  begin
    Negative := (Input[I] = '-');
    Inc(I);
    if I > Input.Length then Exit(False);
  end;

  SawDigit := False;
  SawSep := False;
  FracDigits := 0;
  IntPart := 0;
  FracPart := 0;

  while I <= Input.Length do
  begin
    Ch := Input[I];

    if Ch = FS.DecimalSeparator then
    begin
      if SawSep then Exit(False);
      SawSep := True;
      Inc(I);
      Continue;
    end;

    if (Ch >= '0') and (Ch <= '9') then
    begin
      SawDigit := True;
      Digit := Byte(Ord(Ch) - Ord('0'));

      if not SawSep then
      begin
        if not AddDigit(IntPart, Digit) then Exit(False);
      end
      else
      begin
        Inc(FracDigits);
        if FracDigits > Decimals then Exit(False);
        if not AddDigit(FracPart, Digit) then Exit(False);
      end;

      Inc(I);
      Continue;
    end;

    Exit(False);
  end;

  if not SawDigit then Exit(False);

  if IntPart > (MaxAbsScaledCurrency div 10000) then Exit(False);

  ScaledAbs := IntPart * 10000;

  if FracDigits > 0 then
  begin
    ScaleTo4 := Pow10U(4 - FracDigits);

    if FracPart > (MaxAbsScaledCurrency div ScaleTo4) then Exit(False);

    ScaledAbs := ScaledAbs + (FracPart * ScaleTo4);
  end;

  Result := BuildCurrencyScaled(ScaledAbs, Negative);
end;

class function TConvert.TryToMoneyInv(const S: string; out Value: Currency; const Decimals: Integer): Boolean;
begin
  Result := TryToMoney(S, Value, Decimals, InvariantFS);
end;

class function TConvert.ToMoneyOr(const S: string; const Decimals: Integer; const Default: Currency): Currency;
begin
  Result := ToMoneyOr(S, System.SysUtils.FormatSettings, Decimals, Default);
end;

class function TConvert.ToMoney(const S: string; const Decimals: Integer): Currency;
begin
  Result := ToMoney(S, System.SysUtils.FormatSettings, Decimals);
end;

class function TConvert.ToMoneyOr(const S: string; const FS: TFormatSettings; const Decimals: Integer; const Default: Currency): Currency;
begin
  if not TryToMoney(S, Result, Decimals, FS) then
    Result := Default;
end;

class function TConvert.ToMoney(const S: string; const FS: TFormatSettings; const Decimals: Integer): Currency;
begin
  if not TryToMoney(S, Result, Decimals, FS) then
    RaiseStrict('Money', S);
end;

class function TConvert.ToMoneyOrInv(const S: string; const Decimals: Integer; const Default: Currency): Currency;
begin
  if not TryToMoneyInv(S, Result, Decimals) then
    Result := Default;
end;

class function TConvert.ToMoneyInv(const S: string; const Decimals: Integer): Currency;
begin
  Result := ToMoney(S, InvariantFS, Decimals);
end;

{--------------------------------------}
{ Bytes decoding }
{--------------------------------------}

class function TConvert.TryToBytesHex(const S: string; out Value: TBytes): Boolean;

  function HexNibble(const C: Char; out N: Byte): Boolean;
  begin
    case C of
      '0'..'9': begin N := Byte(Ord(C) - Ord('0')); Exit(True); end;
      'a'..'f': begin N := Byte(10 + Ord(C) - Ord('a')); Exit(True); end;
      'A'..'F': begin N := Byte(10 + Ord(C) - Ord('A')); Exit(True); end;
    else
      Exit(False);
    end;
  end;

var
  Input: string;
  Len: Integer;
  Hi, Lo: Byte;
begin
  Input := Trim(S);
  Len := Input.Length;

  if Len = 0 then
  begin
    Value := nil;
    Exit(True);
  end;

  if (Len and 1) = 1 then
    Exit(False);

  SetLength(Value, Len div 2);

  for var I := 0 to High(Value) do
  begin
    if not HexNibble(Input[1 + I*2], Hi) then Exit(False);
    if not HexNibble(Input[2 + I*2], Lo) then Exit(False);
    Value[I] := (Hi shl 4) or Lo;
  end;

  Result := True;
end;

class function TConvert.TryToBytesBase64(const S: string; out Value: TBytes): Boolean;
var
  Input, Canonical: string;
  Bytes: TBytes;
begin
  Input := Trim(S);

  if Input = '' then
  begin
    Value := nil;
    Exit(True);
  end;

  try
    Bytes := TNetEncoding.Base64.DecodeStringToBytes(Input);
    Canonical := TNetEncoding.Base64.EncodeBytesToString(Bytes);

    if Canonical <> Input then
      Exit(False);

    Value := Bytes;
    Result := True;
  except
    Value := nil;
    Result := False;
  end;
end;

class function TConvert.ToBytesHexOr(const S: string; const Default: TBytes): TBytes;
begin
  if not TryToBytesHex(S, Result) then
    Result := Default;
end;

class function TConvert.ToBytesBase64Or(const S: string; const Default: TBytes): TBytes;
begin
  if not TryToBytesBase64(S, Result) then
    Result := Default;
end;

class function TConvert.ToBytesHex(const S: string): TBytes;
begin
  if not TryToBytesHex(S, Result) then
    RaiseStrict('HexBytes', S);
end;

class function TConvert.ToBytesBase64(const S: string): TBytes;
begin
  if not TryToBytesBase64(S, Result) then
    RaiseStrict('Base64Bytes', S);
end;

end.

