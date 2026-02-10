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
  ///  - No locale ambiguity (explicit TFormatSettings or invariant variants)
  ///  - Failure is reported explicitly (Try*, Or*, Def*, or exception)
  ///
  ///  These methods are intended for use at system boundaries
  ///  (user input, config, APIs, persistence).
  /// </remarks>
  TConvert = record
  private
    class procedure SetEnumOrdinal<T>(const Ordinal: Integer; out Value: T); static;
    class procedure RaiseStrict(const TypeName, S: string); static;
  public
    { Helpers }
    /// <summary>Invariant (culture-independent) format settings.</summary>
    class function InvariantFS: TFormatSettings; static;

    { Integers }
    class function TryToInt(const S: string; out Value: Integer): Boolean; static;
    class function TryToInt64(const S: string; out Value: Int64): Boolean; static;

    class function ToIntOr(const S: string; const Default: Integer): Integer; static;
    class function ToInt64Or(const S: string; const Default: Int64): Int64; static;

    class function ToIntDef(const S: string): Integer; static;
    class function ToInt64Def(const S: string): Int64; static;

    class function ToInt(const S: string): Integer; static;
    class function ToInt64(const S: string): Int64; static;

    { Booleans }
    // Accepts True/False and 0/1 (case-insensitive).
    class function TryToBool(const S: string; out Value: Boolean): Boolean; static;

    class function ToBoolOr(const S: string; const Default: Boolean): Boolean; static;
    class function ToBoolDef(const S: string): Boolean; static;

    class function ToBool(const S: string): Boolean; static;

    { Floating-point (explicit FS) }
    class function TryToSingle(const S: string; out Value: Single; const FS: TFormatSettings): Boolean; overload; static;
    class function TryToDouble(const S: string; out Value: Double; const FS: TFormatSettings): Boolean; overload; static;
    class function TryToExtended(const S: string; out Value: Extended; const FS: TFormatSettings): Boolean; overload; static;

    class function ToSingleOr(const S: string; const Default: Single; const FS: TFormatSettings): Single; overload; static;
    class function ToDoubleOr(const S: string; const Default: Double; const FS: TFormatSettings): Double; overload; static;
    class function ToExtendedOr(const S: string; const Default: Extended; const FS: TFormatSettings): Extended; overload; static;

    class function ToSingleDef(const S: string; const FS: TFormatSettings): Single; overload; static;
    class function ToDoubleDef(const S: string; const FS: TFormatSettings): Double; overload; static;
    class function ToExtendedDef(const S: string; const FS: TFormatSettings): Extended; overload; static;

    class function ToSingle(const S: string; const FS: TFormatSettings): Single; overload; static;
    class function ToDouble(const S: string; const FS: TFormatSettings): Double; overload; static;
    class function ToExtended(const S: string; const FS: TFormatSettings): Extended; overload; static;

    { Floats - default locale overloads (use System.SysUtils.FormatSettings) }
    class function TryToSingle(const S: string; out Value: Single): Boolean; overload; static;
    class function TryToDouble(const S: string; out Value: Double): Boolean; overload; static;
    class function TryToExtended(const S: string; out Value: Extended): Boolean; overload; static;

    class function ToSingleOr(const S: string; const Default: Single): Single; overload; static;
    class function ToDoubleOr(const S: string; const Default: Double): Double; overload; static;
    class function ToExtendedOr(const S: string; const Default: Extended): Extended; overload; static;

    class function ToSingleDef(const S: string): Single; overload; static;
    class function ToDoubleDef(const S: string): Double; overload; static;
    class function ToExtendedDef(const S: string): Extended; overload; static;

    class function ToSingle(const S: string): Single; overload; static;
    class function ToDouble(const S: string): Double; overload; static;
    class function ToExtended(const S: string): Extended; overload; static;

    { Floating-point (Invariant FS) }
    class function TryToSingleInv(const S: string; out Value: Single): Boolean; static;
    class function TryToDoubleInv(const S: string; out Value: Double): Boolean; static;
    class function TryToExtendedInv(const S: string; out Value: Extended): Boolean; static;

    class function ToSingleOrInv(const S: string; const Default: Single): Single; static;
    class function ToDoubleOrInv(const S: string; const Default: Double): Double; static;
    class function ToExtendedOrInv(const S: string; const Default: Extended): Extended; static;

    class function ToSingleDefInv(const S: string): Single; static;
    class function ToDoubleDefInv(const S: string): Double; static;
    class function ToExtendedDefInv(const S: string): Extended; static;

    class function ToSingleInv(const S: string): Single; static;
    class function ToDoubleInv(const S: string): Double; static;
    class function ToExtendedInv(const S: string): Extended; static;

    { Date / Time (explicit FS) }
    class function TryToDateTime(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean; overload; static;
    class function TryToDate(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean; overload; static;
    class function TryToTime(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean; overload; static;

    class function ToDateTimeOr(const S: string; const Default: TDateTime; const FS: TFormatSettings): TDateTime; overload; static;
    class function ToDateOr(const S: string; const Default: TDateTime; const FS: TFormatSettings): TDateTime; overload; static;
    class function ToTimeOr(const S: string; const Default: TDateTime; const FS: TFormatSettings): TDateTime; overload; static;

    class function ToDateTimeDef(const S: string; const FS: TFormatSettings): TDateTime; overload; static;
    class function ToDateDef(const S: string; const FS: TFormatSettings): TDateTime; overload; static;
    class function ToTimeDef(const S: string; const FS: TFormatSettings): TDateTime; overload; static;

    class function ToDateTime(const S: string; const FS: TFormatSettings): TDateTime; overload; static;
    class function ToDate(const S: string; const FS: TFormatSettings): TDateTime; overload; static;
    class function ToTime(const S: string; const FS: TFormatSettings): TDateTime; overload; static;

    { Date/Time - default locale overloads (use System.SysUtils.FormatSettings) }
    class function TryToDateTime(const S: string; out Value: TDateTime): Boolean; overload; static;
    class function TryToDate(const S: string; out Value: TDateTime): Boolean; overload; static;
    class function TryToTime(const S: string; out Value: TDateTime): Boolean; overload; static;

    class function ToDateTimeOr(const S: string; const Default: TDateTime): TDateTime; overload; static;
    class function ToDateOr(const S: string; const Default: TDateTime): TDateTime; overload; static;
    class function ToTimeOr(const S: string; const Default: TDateTime): TDateTime; overload; static;

    class function ToDateTimeDef(const S: string): TDateTime; overload; static;
    class function ToDateDef(const S: string): TDateTime; overload; static;
    class function ToTimeDef(const S: string): TDateTime; overload; static;

    class function ToDateTime(const S: string): TDateTime; overload; static;
    class function ToDate(const S: string): TDateTime; overload; static;
    class function ToTime(const S: string): TDateTime; overload; static;

    { Date / Time (ISO 8601) }
    // Uses TryISO8601ToDate(S, Value, False) to preserve local-time semantics.
    class function TryToDateTimeISO8601(const S: string; out Value: TDateTime): Boolean; static;
    class function ToDateTimeOrISO8601(const S: string; const Default: TDateTime): TDateTime; static;
    class function ToDateTimeDefISO8601(const S: string): TDateTime; static;
    class function ToDateTimeISO8601(const S: string): TDateTime; static;

    { Char }
    // Succeeds only if Length(S)=1
    class function TryToChar(const S: string; out Value: Char): Boolean; static;

    class function ToCharOr(const S: string; const Default: Char): Char; static;
    class function ToCharDef(const S: string): Char; static;
    class function ToChar(const S: string): Char; static;

        { Unsigned integers }
    class function TryToUInt32(const S: string; out Value: Cardinal): Boolean; static;
    class function TryToUInt64(const S: string; out Value: UInt64): Boolean; static;

    class function ToUInt32Or(const S: string; const Default: Cardinal): Cardinal; static;
    class function ToUInt64Or(const S: string; const Default: UInt64): UInt64; static;

    class function ToUInt32Def(const S: string): Cardinal; static;
    class function ToUInt64Def(const S: string): UInt64; static;

    class function ToUInt32(const S: string): Cardinal; static;
    class function ToUInt64(const S: string): UInt64; static;

    { Currency }
    class function TryToCurrency(const S: string; out Value: Currency; const FS: TFormatSettings): Boolean; static;
    class function TryToCurrencyInv(const S: string; out Value: Currency): Boolean; static;

    class function ToCurrencyOr(const S: string; const Default: Currency; const FS: TFormatSettings): Currency; static;
    class function ToCurrencyDef(const S: string; const FS: TFormatSettings): Currency; static;
    class function ToCurrency(const S: string; const FS: TFormatSettings): Currency; static;

    class function ToCurrencyOrInv(const S: string; const Default: Currency): Currency; static;
    class function ToCurrencyDefInv(const S: string): Currency; static;
    class function ToCurrencyInv(const S: string): Currency; static;

    { GUID }
    class function TryToGuid(const S: string; out Value: TGUID): Boolean; static;
    class function ToGuidOr(const S: string; const Default: TGUID): TGUID; static;
    class function ToGuidDef(const S: string): TGUID; static; // returns GUID_NULL on failure
    class function ToGuid(const S: string): TGUID; static;

    /// <summary>
    ///  Strict money parsing with fixed decimal precision.
    /// </summary>
    /// <remarks>
    ///  Parsing is strict and rejects ambiguous input:
    ///  - Optional leading '+' or '-'
    ///  - Digits with at most one decimal separator
    ///  - No thousands separators
    ///  - No currency symbols
    ///  - Fractional digits must be in the range 0..Decimals
    ///  - No rounding is ever performed
    ///
    ///  The parsed value is normalized to Currency's fixed 4-decimal scale.
    /// </remarks>
    class function TryToMoney(
      const S: string;
      out Value: Currency;
      const Decimals: Integer;
      const FS: TFormatSettings
    ): Boolean; static;

    /// <summary>
    ///  Strict money parsing using invariant format settings.
    /// </summary>
    /// <remarks>
    ///  See TryToMoney for parsing rules.
    ///  Uses invariant culture ('.' decimal separator).
    /// </remarks>
    class function TryToMoneyInv(
      const S: string;
      out Value: Currency;
      const Decimals: Integer
    ): Boolean; static;

    class function ToMoneyOr(
      const S: string;
      const Default: Currency;
      const Decimals: Integer;
      const FS: TFormatSettings
    ): Currency; static;

    class function ToMoneyDef(
      const S: string;
      const Decimals: Integer;
      const FS: TFormatSettings;
      const Default: Currency = 0
    ): Currency; static;

    class function ToMoney(
      const S: string;
      const Decimals: Integer;
      const FS: TFormatSettings
    ): Currency; static;

    class function ToMoneyOrInv(
      const S: string;
      const Default: Currency;
      const Decimals: Integer
    ): Currency; static;

    class function ToMoneyDefInv(
      const S: string;
      const Decimals: Integer;
      const Default: Currency = 0
    ): Currency; static;

    class function ToMoneyInv(
      const S: string;
      const Decimals: Integer
    ): Currency; static;

    /// <summary>
    ///  Strict string-to-enum conversion.
    /// </summary>
    /// <remarks>
    ///  - By default, only enum names are accepted (case-insensitive).
    ///  - Ordinal values are rejected unless AllowOrdinal is True.
    ///  - No fallback or coercion is performed.
    /// </remarks>
    class function TryToEnum<T>(
      const S: string;
      out Value: T;
      const IgnoreCase: Boolean = True;
      const AllowOrdinal: Boolean = False
    ): Boolean; static;

    class function ToEnumOr<T>(
      const S: string;
      const Default: T;
      const IgnoreCase: Boolean = True;
      const AllowOrdinal: Boolean = False
    ): T; static;

    class function ToEnum<T>(
      const S: string;
      const IgnoreCase: Boolean = True;
      const AllowOrdinal: Boolean = False
    ): T; static;

    { Bytes decoding }
    class function TryToBytesHex(const S: string; out Value: TBytes): Boolean; static;
    class function TryToBytesBase64(const S: string; out Value: TBytes): Boolean; static;

    class function ToBytesHexOr(const S: string; const Default: TBytes): TBytes; static;
    class function ToBytesBase64Or(const S: string; const Default: TBytes): TBytes; static;

    class function ToBytesHex(const S: string): TBytes; static;
    class function ToBytesBase64(const S: string): TBytes; static;
  end;

implementation

uses
  System.Math,
  System.TypInfo,
  System.NetEncoding,
  System.Rtti,
  Base.Integrity;

{ TConvert }

{----------------------------------------------------------------------------------------------------------------------}
class procedure TConvert.RaiseStrict(const TypeName, S: string);
begin
  var e := EStrictConvertError.CreateFmt('Cannot convert "%s" to %s.', [S, TypeName]);

  TError.Notify(e);

  raise e;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.InvariantFS: TFormatSettings;
begin
  Result := TFormatSettings.Invariant;
end;

{ Integers }

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToInt(const S: string; out Value: Integer): Boolean;
begin
  Result := TryStrToInt(S, Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToInt64(const S: string; out Value: Int64): Boolean;
begin
  Result := TryStrToInt64(S, Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToIntOr(const S: string; const Default: Integer): Integer;
begin
  if not TryToInt(S, Result) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToInt64Or(const S: string; const Default: Int64): Int64;
begin
  if not TryToInt64(S, Result) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToIntDef(const S: string): Integer;
begin
  Result := ToIntOr(S, 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToInt64Def(const S: string): Int64;
begin
  Result := ToInt64Or(S, 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToInt(const S: string): Integer;
begin
  if not TryToInt(S, Result) then RaiseStrict('Integer', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToInt64(const S: string): Int64;
begin
  if not TryToInt64(S, Result) then RaiseStrict('Int64', S);
end;

{ Booleans }

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToBool(const S: string; out Value: Boolean): Boolean;
begin
  Result := TryStrToBool(S, Value);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToBoolOr(const S: string; const Default: Boolean): Boolean;
begin
  if not TryToBool(S, Result) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToBoolDef(const S: string): Boolean;
begin
  Result := ToBoolOr(S, false);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToBool(const S: string): Boolean;
begin
  if not TryToBool(S, Result) then RaiseStrict('Boolean', S);
end;

{ Floating-point (explicit FS) }

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToSingle(const S: string; out Value: Single; const FS: TFormatSettings): Boolean;
begin
  Result := TryStrToFloat(S, Value, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDouble(const S: string; out Value: Double; const FS: TFormatSettings): Boolean;
begin
  Result := TryStrToFloat(S, Value, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToExtended(const S: string; out Value: Extended; const FS: TFormatSettings): Boolean;
begin
  Result := TryStrToFloat(S, Value, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingleOr(const S: string; const Default: Single; const FS: TFormatSettings): Single;
begin
  if not TryToSingle(S, Result, FS) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDoubleOr(const S: string; const Default: Double; const FS: TFormatSettings): Double;
begin
  if not TryToDouble(S, Result, FS) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToExtendedOr(const S: string; const Default: Extended; const FS: TFormatSettings): Extended;
begin
  if not TryToExtended(S, Result, FS) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingleDef(const S: string; const FS: TFormatSettings): Single;
begin
  Result := ToSingleOr(S, 0, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDoubleDef(const S: string; const FS: TFormatSettings): Double;
begin
  Result := ToDoubleOr(S, 0, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToExtendedDef(const S: string; const FS: TFormatSettings): Extended;
begin
  Result := ToExtendedOr(S, 0, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingle(const S: string; const FS: TFormatSettings): Single;
begin
  if not TryToSingle(S, Result, FS) then RaiseStrict('Single', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDouble(const S: string; const FS: TFormatSettings): Double;
begin
  if not TryToDouble(S, Result, FS) then RaiseStrict('Double', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToExtended(const S: string; const FS: TFormatSettings): Extended;
begin
  if not TryToExtended(S, Result, FS) then RaiseStrict('Extended', S);
end;

{ Floating-point (Invariant FS) }

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToSingleInv(const S: string; out Value: Single): Boolean;
begin
  Result := TryToSingle(S, Value, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDoubleInv(const S: string; out Value: Double): Boolean;
begin
  Result := TryToDouble(S, Value, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToExtendedInv(const S: string; out Value: Extended): Boolean;
begin
  Result := TryToExtended(S, Value, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingleOrInv(const S: string; const Default: Single): Single;
begin
  Result := ToSingleOr(S, Default, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDoubleOrInv(const S: string; const Default: Double): Double;
begin
  Result := ToDoubleOr(S, Default, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToExtendedOrInv(const S: string; const Default: Extended): Extended;
begin
  Result := ToExtendedOr(S, Default, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingleDefInv(const S: string): Single;
begin
  Result := ToSingleOrInv(S, 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDoubleDefInv(const S: string): Double;
begin
  Result := ToDoubleOrInv(S, 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToExtendedDefInv(const S: string): Extended;
begin
  Result := ToExtendedOrInv(S, 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingleInv(const S: string): Single;
begin
  Result := ToSingle(S, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDoubleInv(const S: string): Double;
begin
  Result := ToDouble(S, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToExtendedInv(const S: string): Extended;
begin
  Result := ToExtended(S, InvariantFS);
end;

{ Date / Time (explicit FS) }

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDateTime(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean;
var
  Canonical: string;
  Input: string;
begin
  Input := Trim(S);

  if not TryStrToDateTime(Input, Value, FS) then
    Exit(False);

  // Re-format using the same rules and compare
  Canonical := FormatDateTime(FS.ShortDateFormat + ' ' + FS.LongTimeFormat, Value, FS);

  Result := SameText(Input, Canonical);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDate(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean;
var
  Input, Canonical: string;
begin
  Input := Trim(S);

  if not TryStrToDate(Input, Value, FS) then
    Exit(False);

  // Canonicalize using the same format settings and compare exactly.
  // Note: use ShortDateFormat for date-only.
  Canonical := FormatDateTime(FS.ShortDateFormat, Value, FS);

  Result := SameText(Input, Canonical);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToTime(const S: string; out Value: TDateTime; const FS: TFormatSettings): Boolean;
var
  Input, Canonical: string;
begin
  Input := Trim(S);

  if not TryStrToTime(Input, Value, FS) then
    Exit(False);

  // Canonicalize using the same format settings and compare exactly.
  // Prefer LongTimeFormat if present; otherwise ShortTimeFormat.
  if FS.LongTimeFormat <> '' then
    Canonical := FormatDateTime(FS.LongTimeFormat, Value, FS)
  else
    Canonical := FormatDateTime(FS.ShortTimeFormat, Value, FS);

  Result := SameText(Input, Canonical);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTimeOr(const S: string; const Default: TDateTime; const FS: TFormatSettings): TDateTime;
begin
  if not TryToDateTime(S, Result, FS) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateOr(const S: string; const Default: TDateTime; const FS: TFormatSettings): TDateTime;
begin
  if not TryToDate(S, Result, FS) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToTimeOr(const S: string; const Default: TDateTime; const FS: TFormatSettings): TDateTime;
begin
  if not TryToTime(S, Result, FS) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTimeDef(const S: string; const FS: TFormatSettings): TDateTime;
begin
  Result := ToDateTimeOr(S, 0, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateDef(const S: string; const FS: TFormatSettings): TDateTime;
begin
  Result := ToDateOr(S, 0, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToTimeDef(const S: string; const FS: TFormatSettings): TDateTime;
begin
  Result := ToTimeOr(S, 0, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTime(const S: string; const FS: TFormatSettings): TDateTime;
begin
  if not TryToDateTime(S, Result, FS) then RaiseStrict('TDateTime', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDate(const S: string; const FS: TFormatSettings): TDateTime;
begin
  if not TryToDate(S, Result, FS) then RaiseStrict('TDate', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToTime(const S: string; const FS: TFormatSettings): TDateTime;
begin
  if not TryToTime(S, Result, FS) then RaiseStrict('TTime', S);
end;

{ Date / Time (ISO 8601) }

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDateTimeISO8601(const S: string; out Value: TDateTime): Boolean;
begin
  Result := TryISO8601ToDate(S, Value, False);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTimeOrISO8601(const S: string; const Default: TDateTime): TDateTime;
begin
  if not TryToDateTimeISO8601(S, Result) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTimeDefISO8601(const S: string): TDateTime;
begin
  Result := ToDateTimeOrISO8601(S, 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTimeISO8601(const S: string): TDateTime;
begin
  if not TryToDateTimeISO8601(S, Result) then RaiseStrict('ISO-8601 TDateTime', S);
end;

{ Char }

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToChar(const S: string; out Value: Char): Boolean;
begin
  Result := Length(S) = 1;
  if Result then
    Value := S[1]
  else
    Value := #0;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCharOr(const S: string; const Default: Char): Char;
begin
  if not TryToChar(S, Result) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCharDef(const S: string): Char;
begin
  Result := ToCharOr(S, #0);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToChar(const S: string): Char;
begin
  if not TryToChar(S, Result) then RaiseStrict('Char', S);
end;

{ Unsigned integers }

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToUInt64(const S: string; out Value: UInt64): Boolean;
var
  Input: string;
  I64: Int64;
begin
  Input := Trim(S);

  // Disallow leading '-' explicitly
  if (Input = '') or (Input[1] = '-') then
    Exit(False);

  // Delphi doesn't always have TryStrToUInt64 across versions; do it safely via Int64 when possible
  // First try Int64 parse (covers up to High(Int64))
  if TryStrToInt64(Input, I64) then
  begin
    if I64 < 0 then Exit(False);
    Value := UInt64(I64);
    Exit(True);
  end;

  // If it's > High(Int64), parse manually (decimal)
  // Simple strict decimal parser:
  Value := 0;

  for var Ch in Input do
  begin
    if not CharInSet(Ch, ['0'..'9']) then
      Exit(False);

    var Digit := Ord(Ch) - Ord('0');

    // overflow check: Value*10 + Digit <= High(UInt64)
    if (Value > (High(UInt64) div 10)) or
       ((Value = (High(UInt64) div 10)) and (UInt64(Digit) > (High(UInt64) mod 10))) then
      Exit(False);

    Value := Value * 10 + UInt64(Digit);
  end;

  Result := True;
end;

{----------------------------------------------------------------------------------------------------------------------}
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

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToUInt64Or(const S: string; const Default: UInt64): UInt64;
begin
  if not TryToUInt64(S, Result) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToUInt32Or(const S: string; const Default: Cardinal): Cardinal;
begin
  if not TryToUInt32(S, Result) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToUInt64Def(const S: string): UInt64;
begin
  Result := ToUInt64Or(S, 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToUInt32Def(const S: string): Cardinal;
begin
  Result := ToUInt32Or(S, 0);
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

{ Currency }

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToCurrency(const S: string; out Value: Currency; const FS: TFormatSettings): Boolean;
begin
  Result := TryStrToCurr(Trim(S), Value, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToCurrencyInv(const S: string; out Value: Currency): Boolean;
begin
  Result := TryToCurrency(S, Value, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrencyOr(const S: string; const Default: Currency; const FS: TFormatSettings): Currency;
begin
  if not TryToCurrency(S, Result, FS) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrencyDef(const S: string; const FS: TFormatSettings): Currency;
begin
  Result := ToCurrencyOr(S, 0, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrency(const S: string; const FS: TFormatSettings): Currency;
begin
  if not TryToCurrency(S, Result, FS) then RaiseStrict('Currency', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrencyOrInv(const S: string; const Default: Currency): Currency;
begin
  Result := ToCurrencyOr(S, Default, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrencyDefInv(const S: string): Currency;
begin
  Result := ToCurrencyOrInv(S, 0);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToCurrencyInv(const S: string): Currency;
begin
  Result := ToCurrency(S, InvariantFS);
end;

{ GUID }

{----------------------------------------------------------------------------------------------------------------------}
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

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToGuidOr(const S: string; const Default: TGUID): TGUID;
begin
  if not TryToGuid(S, Result) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToGuidDef(const S: string): TGUID;
begin
  Result := ToGuidOr(S, TGUID.Empty);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToGuid(const S: string): TGUID;
begin
  if not TryToGuid(S, Result) then RaiseStrict('TGUID', S);
end;

{ Enum parsing }

{----------------------------------------------------------------------------------------------------------------------}
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

  // Optional ordinal parsing
  if AllowOrdinal and TryStrToInt(Input, Ordinal) then
  begin
    if (Ordinal < MinV) or (Ordinal > MaxV) then
      Exit(False);

    SetEnumOrdinal<T>(Ordinal, Value);
    Exit(True);
  end;

  // Exact match
  if not IgnoreCase then
  begin
    Ordinal := GetEnumValue(Info, Input);
    if (Ordinal < MinV) or (Ordinal > MaxV) then
      Exit(False);

    SetEnumOrdinal<T>(Ordinal, Value);
    Exit(True);
  end;

  // Case-insensitive match
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

{----------------------------------------------------------------------------------------------------------------------}
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

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToEnum<T>(
  const S: string;
  const IgnoreCase: Boolean;
  const AllowOrdinal: Boolean
): T;
begin
  if not TryToEnum<T>(S, Result, IgnoreCase, AllowOrdinal) then RaiseStrict('Enum', S);
end;

{ Bytes decoding }

{----------------------------------------------------------------------------------------------------------------------}
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

  if (Len = 0) then
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

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToBytesBase64(const S: string; out Value: TBytes): Boolean;
var
  Input, Canonical: string;
  Bytes: TBytes;
begin
  Input := Trim(S);

  // Empty string is valid => empty byte array
  if Input = '' then
  begin
    Value := nil;
    Exit(True);
  end;

  try
    Bytes := TNetEncoding.Base64.DecodeStringToBytes(Input);

    // Re-encode to canonical Base64 and compare
    Canonical := TNetEncoding.Base64.EncodeBytesToString(Bytes);

    // Base64 comparison should be case-sensitive and exact
    if Canonical <> Input then
      Exit(False);

    Value := Bytes;
    Result := True;
  except
    Value := nil;
    Result := False;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToBytesHexOr(const S: string; const Default: TBytes): TBytes;
begin
  if not TryToBytesHex(S, Result) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToBytesBase64Or(const S: string; const Default: TBytes): TBytes;
begin
  if not TryToBytesBase64(S, Result) then
    Result := Default;
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

{----------------------------------------------------------------------------------------------------------------------}
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
    otUByte:
      begin
        B := Byte(Ordinal);
        Move(B, Value, SizeOf(T));
      end;
    otSByte:
      begin
        SB := ShortInt(Ordinal);
        Move(SB, Value, SizeOf(T));
      end;
    otUWord:
      begin
        W := Word(Ordinal);
        Move(W, Value, SizeOf(T));
      end;
    otSWord:
      begin
        SW := SmallInt(Ordinal);
        Move(SW, Value, SizeOf(T));
      end;
    otULong:
      begin
        L := Cardinal(Ordinal);
        Move(L, Value, SizeOf(T));
      end;
    otSLong:
      begin
        SL := Integer(Ordinal);
        Move(SL, Value, SizeOf(T));
      end;
  else
    // Defensive fallback (shouldn't occur for enums)
    SL := Integer(Ordinal);
    Move(SL, Value, SizeOf(T));
  end;
end;

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
  Sign: Int64;
  SawDigit: Boolean;
  SawSep: Boolean;
  FracDigits: Integer;
  IntPart: UInt64;
  FracPart: UInt64;

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
    // Acc := Acc*10 + Digit with overflow check
    if (Acc > (High(UInt64) div 10)) or
       ((Acc = (High(UInt64) div 10)) and (Digit > (High(UInt64) mod 10))) then
      Exit(False);
    Acc := Acc * 10 + Digit;
    Result := True;
  end;

  function MaxAbsScaledCurrency: UInt64;
  begin
    // Currency is scaled Int64 (x 10000). Max abs is High(Int64) as positive magnitude.
    Result := UInt64(High(Int64));
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

    Value := SignedScaled / 10000.0; // exact for Currency scale
    Result := True;
  end;

var
  Digit: Byte;
  Negative: Boolean;
  ScaleTo4: UInt64;
  DecScale: UInt64;
  ScaledAbs: UInt64;
begin
  Value := 0;
  Result := False;

  // We only support 0..4 because Currency has 4 fixed decimal places.
  if (Decimals < 0) or (Decimals > 4) then
    Exit(False);

  Input := Trim(S);
  if Input = '' then
    Exit(False);

  // Strict: no spaces inside; no thousands separator; no currency string
  if (Pos(' ', Input) > 0) or (Pos(#9, Input) > 0) or (Pos(#10, Input) > 0) or (Pos(#13, Input) > 0) then
    Exit(False);

  if (FS.ThousandSeparator <> #0) and (FS.ThousandSeparator <> #$FFFF) then
    if Pos(FS.ThousandSeparator, Input) > 0 then
      Exit(False);

  if (FS.CurrencyString <> '') and (Pos(FS.CurrencyString, Input) > 0) then
    Exit(False);

  // Parse
  I := 1;
  Sign := 1;
  Negative := False;

  // Optional leading +/-
  if (Input[I] = '+') or (Input[I] = '-') then
  begin
    Negative := (Input[I] = '-');
    Inc(I);
    if I > Input.Length then
      Exit(False); // sign alone invalid
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
      if SawSep then
        Exit(False); // only one separator allowed
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
        if not AddDigit(IntPart, Digit) then
          Exit(False);
      end
      else
      begin
        Inc(FracDigits);

        if FracDigits > Decimals then
          Exit(False); // too many fractional digits

        if not AddDigit(FracPart, Digit) then
          Exit(False);
      end;

      Inc(I);
      Continue;
    end;

    // Any other character is illegal
    Exit(False);
  end;


  if not SawDigit then
    Exit(False);

  // Convert to Currency (scaled by 10000) WITHOUT rounding.
  // ScaledAbs = IntPart*10000 + FracPart*10^(4-FracDigits)

  if IntPart > (MaxAbsScaledCurrency div 10000) then
    Exit(False);

  ScaledAbs := IntPart * 10000;

  if FracDigits > 0 then
  begin
    ScaleTo4 := Pow10U(4 - FracDigits);

    if FracPart > (MaxAbsScaledCurrency div ScaleTo4) then
      Exit(False);

    ScaledAbs := ScaledAbs + (FracPart * ScaleTo4);
  end;

  Result := BuildCurrencyScaled(ScaledAbs, Negative);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToMoneyInv(const S: string; out Value: Currency; const Decimals: Integer): Boolean;
begin
  Result := TryToMoney(S, Value, Decimals, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoneyOr(
  const S: string;
  const Default: Currency;
  const Decimals: Integer;
  const FS: TFormatSettings
): Currency;
begin
  if not TryToMoney(S, Result, Decimals, FS) then
    Result := Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoneyDef(
  const S: string;
  const Decimals: Integer;
  const FS: TFormatSettings;
  const Default: Currency
): Currency;
begin
  Result := ToMoneyOr(S, Default, Decimals, FS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoney(const S: string; const Decimals: Integer; const FS: TFormatSettings): Currency;
begin
  if not TryToMoney(S, Result, Decimals, FS) then RaiseStrict('Money', S);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoneyOrInv(const S: string; const Default: Currency; const Decimals: Integer): Currency;
begin
  Result := ToMoneyOr(S, Default, Decimals, InvariantFS);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoneyDefInv(const S: string; const Decimals: Integer; const Default: Currency): Currency;
begin
  Result := ToMoneyOrInv(S, Default, Decimals);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToMoneyInv(const S: string; const Decimals: Integer): Currency;
begin
  Result := ToMoney(S, Decimals, InvariantFS);
end;

{ Floats - default locale overloads }

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToSingle(const S: string; out Value: Single): Boolean;
begin
  Result := TryToSingle(S, Value, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDouble(const S: string; out Value: Double): Boolean;
begin
  Result := TryToDouble(S, Value, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToExtended(const S: string; out Value: Extended): Boolean;
begin
  Result := TryToExtended(S, Value, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingleOr(const S: string; const Default: Single): Single;
begin
  Result := ToSingleOr(S, Default, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDoubleOr(const S: string; const Default: Double): Double;
begin
  Result := ToDoubleOr(S, Default, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToExtendedOr(const S: string; const Default: Extended): Extended;
begin
  Result := ToExtendedOr(S, Default, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingleDef(const S: string): Single;
begin
  Result := ToSingleOr(S, 0, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDoubleDef(const S: string): Double;
begin
  Result := ToDoubleOr(S, 0, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToExtendedDef(const S: string): Extended;
begin
  Result := ToExtendedOr(S, 0, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToSingle(const S: string): Single;
begin
  Result := ToSingle(S, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDouble(const S: string): Double;
begin
  Result := ToDouble(S, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToExtended(const S: string): Extended;
begin
  Result := ToExtended(S, System.SysUtils.FormatSettings);
end;

{ Date/Time - default locale overloads }

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDateTime(const S: string; out Value: TDateTime): Boolean;
begin
  Result := TryToDateTime(S, Value, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToDate(const S: string; out Value: TDateTime): Boolean;
begin
  Result := TryToDate(S, Value, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.TryToTime(const S: string; out Value: TDateTime): Boolean;
begin
  Result := TryToTime(S, Value, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTimeOr(const S: string; const Default: TDateTime): TDateTime;
begin
  Result := ToDateTimeOr(S, Default, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateOr(const S: string; const Default: TDateTime): TDateTime;
begin
  Result := ToDateOr(S, Default, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToTimeOr(const S: string; const Default: TDateTime): TDateTime;
begin
  Result := ToTimeOr(S, Default, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTimeDef(const S: string): TDateTime;
begin
  Result := ToDateTimeOr(S, 0, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateDef(const S: string): TDateTime;
begin
  Result := ToDateOr(S, 0, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToTimeDef(const S: string): TDateTime;
begin
  Result := ToTimeOr(S, 0, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDateTime(const S: string): TDateTime;
begin
  Result := ToDateTime(S, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToDate(const S: string): TDateTime;
begin
  Result := ToDate(S, System.SysUtils.FormatSettings);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TConvert.ToTime(const S: string): TDateTime;
begin
  Result := ToTime(S, System.SysUtils.FormatSettings);
end;

end.

