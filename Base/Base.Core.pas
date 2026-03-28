{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Core
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Defines fundamental types, helpers, and aliases shared across all Base units.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Core;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SyncObjs;

type
  { aliases for anonymous functions - reduces verbosity slightly }
  TInt = Integer;
  TStr = string;
  TBool = Boolean;

  { semantic abstractions for interface management }
  TSingleton = class(TNoRefCountObject);
  TTransient = class(TInterfacedObject);

  { predicates }
  TRefPredicate<T> = reference to function(const [ref] aItem: T): Boolean;
  TConstPredicate<T> = reference to function(const aItem: T): Boolean;
  TVarPredicate<T> = reference to function(var aItem: T): Boolean;

  { predicate with a var argument }
  TProcvar<T> = reference to procedure (var Arg1: T);

  { for working with most types }
  TConstProc<T> = reference to procedure (const Arg1: T);
  TConstProc<T1,T2> = reference to procedure (const Arg1: T1; const Arg2: T2);
  TConstProc<T1,T2,T3> = reference to procedure (const Arg1: T1; const Arg2: T2; const Arg3: T3);
  TConstProc<T1,T2,T3,T4> = reference to procedure (const Arg1: T1; const Arg2: T2; const Arg3: T3; const Arg4: T4);

  TConstFunc<T> = reference to function: T;
  TConstFunc<T,R> = reference to function (const Arg1: T): R;
  TConstFunc<T1,T2,R> = reference to function (const Arg1: T1; const Arg2: T2): R;
  TConstFunc<T1,T2,T3,R> = reference to function (const Arg1: T1; const Arg2: T2; const Arg3: T3): R;
  TConstFunc<T1,T2,T3,T4,R> = reference to function (const Arg1: T1; const Arg2: T2; const Arg3: T3; const Arg4: T4): R;

  { for efficiently working with records }
  TConstRefProc<T: record> = reference to procedure (const [ref] Arg1: T);
  TConstRefProc<T1,T2: record> = reference to procedure (const [ref] Arg1: T1; const [ref] Arg2: T2);
  TConstRefProc<T1,T2,T3: record> = reference to procedure (const [ref] Arg1: T1; const [ref] Arg2: T2; const [ref] Arg3: T3);
  TConstRefProc<T1,T2,T3,T4: record> = reference to procedure (const [ref] Arg1: T1; const [ref] Arg2: T2; const [ref] Arg3: T3; const [ref] Arg4: T4);

  TConstRefFunc<T:record; R> = reference to function (const [ref] Arg1: T): R;
  TConstRefFunc<T1,T2: record; R> = reference to function (const [ref] Arg1: T1; const [ref] Arg2: T2): R;
  TConstRefFunc<T1,T2,T3: record; R> = reference to function (const [ref] Arg1: T1; const [ref] Arg2: T2; const [ref] Arg3: T3): R;
  TConstRefFunc<T1,T2,T3,T4: record; R> = reference to function (const [ref] Arg1: T1; const [ref] Arg2: T2; const [ref] Arg3: T3; const [ref] Arg4: T4): R;

  /// <summary>
  /// Predefined IComparer<T> helpers (mostly thin wrappers over RTL singletons).
  /// </summary>
  Comparers = record
  strict private
    type
      TDescendingComparer<T> = class(TInterfacedObject, IComparer<T>)
      private
        fBase: IComparer<T>;
      public
        constructor Create(const ABase: IComparer<T>);
        function Compare(const aLeft, aRight: T): Integer;
      end;
  public
    /// <summary>Default comparer for T (TComparer&lt;T&gt;.Default).</summary>
    class function Default<T>: IComparer<T>; static;

    /// <summary>
    /// Returns a comparer that reverses the given comparer. If Base is nil, uses TComparer&lt;T&gt;.Default.
    /// </summary>
    class function Descending<T>(const aBase: IComparer<T> = nil): IComparer<T>; static;

    /// <summary>
    /// Case-insensitive, ordinal string comparer (RTL TIStringComparer.Ordinal).
    /// Suitable for Sort(...) and other ordering operations.
    /// </summary>
    class function StringIgnoreCase: IComparer<string>; static;

    /// <summary>
    /// Case-sensitive, ordinal string comparer (RTL TStringComparer.Ordinal).
    /// </summary>
    class function StringOrdinal: IComparer<string>; static;
  end;

  /// <summary>
  /// Predefined IEqualityComparer<T> helpers (mostly thin wrappers over RTL singletons).
  /// </summary>
  Equality = record
  public
    /// <summary>Default equality comparer for T (TEqualityComparer&lt;T&gt;.Default).</summary>
    class function Default<T>: IEqualityComparer<T>; static;

    /// <summary>
    /// Case-insensitive, ordinal string equality comparer (RTL TIStringComparer.Ordinal).
    /// Suitable for Distinct(...), dictionaries, sets.
    /// </summary>
    class function StringIgnoreCase: IEqualityComparer<string>; static;

    /// <summary>
    /// Case-sensitive, ordinal string equality comparer (RTL TStringComparer.Ordinal).
    /// </summary>
    class function StringOrdinal: IEqualityComparer<string>; static;
  end;

  {------------------ language extension functions ------------------ }

  ELetException = class(Exception);

  TLx = record
  strict private
    class procedure RaiseNotEnoughValues(const Need, Got: Integer); static;
  public
    class procedure Let<T>(out A, B: T; const V1, V2: T); overload; static;
    class procedure Let<T>(out A, B, C: T; const V1, V2, V3: T); overload; static;
    class procedure Let<T>(out A, B, C, D: T; const V1, V2, V3, V4: T); overload; static;
    class procedure Let<T>(out A, B, C, D, E: T; const V1, V2, V3, V4, V5: T); overload; static;

    class procedure Let<T1, T2>(out A: T1; out B: T2; const V1: T1; const V2: T2); overload; static;
    class procedure Let<T1, T2, T3>(out A: T1; out B: T2; out C: T3; const V1: T1; const V2: T2; const V3: T3); overload; static;
    class procedure Let<T1, T2, T3, T4>(out A: T1; out B: T2; out C: T3; out D: T4; const V1: T1; const V2: T2; const V3: T3; const V4: T4); overload; static;
    class procedure Let<T1, T2, T3, T4, T5>(out A: T1; out B: T2; out C: T3; out D: T4; out E: T5; const V1: T1; const V2: T2; const V3: T3; const V4: T4; const V5: T5); overload; static;

    class procedure Let<T>(out A, B: T; const Values: array of T); overload; static;
    class procedure Let<T>(out A, B, C: T; const Values: array of T); overload; static;
    class procedure Let<T>(out A, B, C, D: T; const Values: array of T); overload; static;
    class procedure Let<T>(out A, B, C, D, E: T; const Values: array of T); overload; static;

    class procedure LetOrDefault<T>(out A, B: T; const Values: array of T); overload; static;
    class procedure LetOrDefault<T>(out A, B, C: T; const Values: array of T); overload; static;
    class procedure LetOrDefault<T>(out A, B, C, D: T; const Values: array of T); overload; static;
    class procedure LetOrDefault<T>(out A, B, C, D, E: T; const Values: array of T); overload; static;

    class procedure LetOr<T>(out A, B: T; const Fallback: T; const Values: array of T); overload; static;
    class procedure LetOr<T>(out A, B, C: T; const Fallback: T; const Values: array of T); overload; static;
    class procedure LetOr<T>(out A, B, C, D: T; const Fallback: T; const Values: array of T); overload; static;
    class procedure LetOr<T>(out A, B, C, D, E: T; const Fallback: T; const Values: array of T); overload; static;

    class function Ensure<T>(const aComparer: IEqualityComparer<T> = nil): IEqualityComparer<T>; overload; static; inline;
    class function Ensure<T>(const aComparer: IComparer<T>): IComparer<T>; overload; static; inline;
  end;

implementation

{ TLx }

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.RaiseNotEnoughValues(const Need, Got: Integer);
begin
  raise ELetException.CreateFmt('Let: expected at least %d value(s) but got %d.', [Need, Got]);
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B: T; const V1, V2: T);
begin
  A := V1;
  B := V2;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C: T; const V1, V2, V3: T);
begin
  A := V1;
  B := V2;
  C := V3;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C, D: T; const V1, V2, V3, V4: T);
begin
  A := V1;
  B := V2;
  C := V3;
  D := V4;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C, D, E: T; const V1, V2, V3, V4, V5: T);
begin
  A := V1;
  B := V2;
  C := V3;
  D := V4;
  E := V5;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T1, T2>(out A: T1; out B: T2; const V1: T1; const V2: T2);
begin
  A := V1;
  B := V2;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T1, T2, T3>(out A: T1; out B: T2; out C: T3; const V1: T1; const V2: T2; const V3: T3);
begin
  A := V1;
  B := V2;
  C := V3;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T1, T2, T3, T4>(out A: T1; out B: T2; out C: T3; out D: T4; const V1: T1; const V2: T2; const V3: T3; const V4: T4);
begin
  A := V1;
  B := V2;
  C := V3;
  D := V4;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T1, T2, T3, T4, T5>(out A: T1; out B: T2; out C: T3; out D: T4; out E: T5; const V1: T1; const V2: T2; const V3: T3; const V4: T4; const V5: T5);
begin
  A := V1;
  B := V2;
  C := V3;
  D := V4;
  E := V5;
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B: T; const Values: array of T);
begin
  if Length(Values) < 2 then
    RaiseNotEnoughValues(2, Length(Values));

  A := Values[0];
  B := Values[1];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C: T; const Values: array of T);
begin
  if Length(Values) < 3 then
    RaiseNotEnoughValues(3, Length(Values));

  A := Values[0];
  B := Values[1];
  C := Values[2];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C, D: T; const Values: array of T);
begin
  if Length(Values) < 4 then
    RaiseNotEnoughValues(4, Length(Values));

  A := Values[0];
  B := Values[1];
  C := Values[2];
  D := Values[3];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.Let<T>(out A, B, C, D, E: T; const Values: array of T);
begin
  if Length(Values) < 5 then
    RaiseNotEnoughValues(5, Length(Values));

  A := Values[0];
  B := Values[1];
  C := Values[2];
  D := Values[3];
  E := Values[4];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOrDefault<T>(out A, B: T; const Values: array of T);
begin
  A := Default(T);
  B := Default(T);

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOrDefault<T>(out A, B, C: T; const Values: array of T);
begin
  A := Default(T);
  B := Default(T);
  C := Default(T);

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOrDefault<T>(out A, B, C, D: T; const Values: array of T);
begin
  A := Default(T);
  B := Default(T);
  C := Default(T);
  D := Default(T);

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
  if Length(Values) > 3 then D := Values[3];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOrDefault<T>(out A, B, C, D, E: T; const Values: array of T);
begin
  A := Default(T);
  B := Default(T);
  C := Default(T);
  D := Default(T);
  E := Default(T);

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
  if Length(Values) > 3 then D := Values[3];
  if Length(Values) > 4 then E := Values[4];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOr<T>(out A, B: T; const Fallback: T; const Values: array of T);
begin
  A := Fallback;
  B := Fallback;

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOr<T>(out A, B, C: T; const Fallback: T; const Values: array of T);
begin
  A := Fallback;
  B := Fallback;
  C := Fallback;

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOr<T>(out A, B, C, D: T; const Fallback: T; const Values: array of T);
begin
  A := Fallback;
  B := Fallback;
  C := Fallback;
  D := Fallback;

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
  if Length(Values) > 3 then D := Values[3];
end;

{----------------------------------------------------------------------------------------------------------------------}
class procedure TLx.LetOr<T>(out A, B, C, D, E: T; const Fallback: T; const Values: array of T);
begin
  A := Fallback;
  B := Fallback;
  C := Fallback;
  D := Fallback;
  E := Fallback;

  if Length(Values) > 0 then A := Values[0];
  if Length(Values) > 1 then B := Values[1];
  if Length(Values) > 2 then C := Values[2];
  if Length(Values) > 3 then D := Values[3];
  if Length(Values) > 3 then D := Values[4];
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TLx.Ensure<T>(const aComparer: IEqualityComparer<T>): IEqualityComparer<T>;
begin
 Result := if Assigned(aComparer) then aComparer else TEqualityComparer<T>.Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TLx.Ensure<T>(const aComparer: IComparer<T>): IComparer<T>;
begin
 Result := if Assigned(aComparer) then aComparer else TComparer<T>.Default;
end;


{ Comparers.TDescendingComparer<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor Comparers.TDescendingComparer<T>.Create(const aBase: IComparer<T>);
begin
  inherited Create;

  fBase := aBase;

  if fBase = nil then
    fBase := TComparer<T>.Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Comparers.TDescendingComparer<T>.Compare(const aLeft, aRight: T): Integer;
begin
  // Reverse order
  Result := fBase.Compare(aRight, aLeft);
end;

{ Comparers }

{----------------------------------------------------------------------------------------------------------------------}
class function Comparers.Default<T>: IComparer<T>;
begin
  Result := TComparer<T>.Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Comparers.Descending<T>(const aBase: IComparer<T>): IComparer<T>;
begin
  Result := TDescendingComparer<T>.Create(aBase);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Comparers.StringIgnoreCase: IComparer<string>;
begin
  // TIStringComparer.Ordinal is case-insensitive ordinal and implements IComparer<string>
  Result := TIStringComparer.Ordinal;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Comparers.StringOrdinal: IComparer<string>;
begin
  // TStringComparer.Ordinal is case-sensitive ordinal and implements IComparer<string>
  Result := TStringComparer.Ordinal;
end;

{ Equality }

{----------------------------------------------------------------------------------------------------------------------}
class function Equality.Default<T>: IEqualityComparer<T>;
begin
  Result := TEqualityComparer<T>.Default;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Equality.StringIgnoreCase: IEqualityComparer<string>;
begin
  // TIStringComparer.Ordinal also implements IEqualityComparer<string>
  Result := TIStringComparer.Ordinal;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Equality.StringOrdinal: IEqualityComparer<string>;
begin
  // TStringComparer.Ordinal also implements IEqualityComparer<string>
  Result := TStringComparer.Ordinal;
end;

end.

