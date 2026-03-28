{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Collections
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Provides a few useful collections.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Collections;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Base.Core,
  Base.Integrity;

type
  ISpecification<T> = interface
    ['{E516E6C7-2E3A-4F16-94DE-F041C3E125B9}']
    function IsSatisfiedBy(const Candidate: T): Boolean;

    function AndAlso(const aOther: ISpecification<T>): ISpecification<T>;
    function OrElse(const aOther: ISpecification<T>): ISpecification<T>;
    function NotThis: ISpecification<T>;
  end;

  IAndSpecification<T> = interface(ISpecification<T>)
    ['{9F734B3F-1F3C-4A1B-9D91-6A2D2F2A2B6B}']
    function Left: ISpecification<T>;
    function Right: ISpecification<T>;
  end;

  IOrSpecification<T> = interface(ISpecification<T>)
    ['{4E1A1C6F-1C06-4DF0-9C0D-7E56E0BE9F7B}']
    function Left: ISpecification<T>;
    function Right: ISpecification<T>;
  end;

  INotSpecification<T> = interface(ISpecification<T>)
    ['{B5B1D1F0-8E88-4E76-A0AA-7A6A9A1B3C2C}']
    function Inner: ISpecification<T>;
  end;

  /// <remarks>
  /// Specification composition is explicit. Grouping is defined by nesting
  /// (AndAlso / OrElse calls), not by operator precedence. It's just like function calls.
  /// </remarks>
  TSpecification<T> = class(TInterfacedObject, ISpecification<T>)
  public
    function IsSatisfiedBy(const aCandidate: T): Boolean; virtual; abstract;

    function AndAlso(const aOther: ISpecification<T>): ISpecification<T>;
    function OrElse(const aOther: ISpecification<T>): ISpecification<T>;
    function NotThis: ISpecification<T>;

    class function FromPredicate(const aPredicate: TConstPredicate<T>): ISpecification<T>; static;
  end;

  TAndSpecification<T> = class(TSpecification<T>, IAndSpecification<T>)
  private
    fLeft, fRight: ISpecification<T>;
  public
    constructor Create(const aLeft, aRight: ISpecification<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;

    function Left: ISpecification<T>;
    function Right: ISpecification<T>;
  end;

  TOrSpecification<T> = class(TSpecification<T>, IOrSpecification<T>)
  private
    fLeft, fRight: ISpecification<T>;
  public
    constructor Create(const aLeft, aRight: ISpecification<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;

    function Left: ISpecification<T>;
    function Right: ISpecification<T>;
  end;

  TNotSpecification<T> = class(TSpecification<T>, INotSpecification<T>)
  private
    fInner: ISpecification<T>;
  public
    constructor Create(const aInner: ISpecification<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;

    function Inner: ISpecification<T>;
  end;

  TPredicateSpecification<T> = class(TSpecification<T>)
  private
    FPredicate: TConstPredicate<T>;
  public
    constructor Create(const aPredicate: TConstPredicate<T>);
    function IsSatisfiedBy(const aCandidate: T): Boolean; override;
  end;

  TItemsEnumerator<T> = class
  private
    fPos:    integer;
    fCount:  integer;
    fSource: TArray<T>;
  public
    constructor Create(const [ref] aSource: TArray<T>; const aCount: integer);

    function MoveNext: boolean;
    function GetCurrent: T;

    property Current: T read GetCurrent;
  end;

  /// <summary>
  ///  A general purpose read-only collection input adapter.
  /// </summary>
  TItems<T> = record
  private
    fItems: TArray<T>;
    fCount: integer;
    fHigh:  integer;

    function GetItem(const aIndex: Integer): T; inline;

  public
    property Items[const aIndex: integer]: T read GetItem; default;
    property Count: Integer read fCount;
    property High: Integer read fHigh;

    function IsEmpty: boolean; inline;
    function AsList: TList<T>;
    function AsArray: TArray<T>;

    function GetEnumerator: TItemsEnumerator<T>;

    procedure AppendTo(const aList: TList<T>);

    // copies source items only
    class operator Implicit(const aArray: TArray<T>): TItems<T>; static;

    // copies source items and consumes enumerator
    class operator Implicit(const aEnum: TEnumerator<T>): TItems<T>; static;

    // copies source items only
    class operator Implicit(const aEnum: TEnumerable<T>): TItems<T>; static;

    // copies source items only
    class operator Implicit(const aList: TList<T>): TItems<T>; static;

    // copies source items only
    class function From(const aItems: array of T): TItems<T>; static;

    // copies source items and consumes list
    class function Consume(const aList: TList<T>): TItems<T>; static;
  end;

  /// <summary>
  ///  Used for iterating over a range of items in a list.
  /// </summary>
  TSequenceEnumerator<T> = class
  private
    fPos:    integer;
    fCount:  integer;
    fSource: TArray<T>;
  public
    constructor Create(const [ref] aSource: TArray<T>; const aCount: integer);

    function MoveNext: boolean;
    function GetCurrent: T;

    property Current: T read GetCurrent;
  end;

  /// <summary>
  ///  An immutable value sequence of items, backed by an internal array.
  ///  The sequence owns its internal storage, but does not assume ownership
  ///  of referenced objects contained within it. You can use it, and forget about it.
  /// </summary>
  /// <remarks>
  ///  TSequence is designed to be more lightweight than Stream, and useful as the
  ///  value boundary for comparisons, matching, sorting, distinct operations, and
  ///  other sequence-oriented logic where stability and immutability are important.
  ///
  ///  Range-based sequence operations are best-effort. Requested bounds are clamped to the
  ///  nearest valid range, and if no valid range remains, the result is an empty sequence.
  ///
  ///  In general:
  ///  - TSequence is for stable values and simple sequence operations.
  ///  - Stream is for richer transformation and query operations.
  /// </remarks>
  TSequence<T> = record
  private
    fItems: TArray<T>;
    fCount: integer;

    function GetItem(const aIndex: integer): T;
    function GetFirst: TOption<T>;
    function GetLast: TOption<T>;
    function GetIsEmpty: boolean;

  public
    property Item[const aIndex: integer]: T read GetItem; default;
    property Count: integer read fCount;
    property First: TOption<T> read GetFirst;
    property Last:  TOption<T> read GetLast;
    property IsEmpty: boolean read GetIsEmpty;

    function ItemAt(const aIndex: integer): TOption<T>;

    function GetEnumerator: TSequenceEnumerator<T>;

    function Sorted(const aComparer: IComparer<T> = nil): TSequence<T>; overload;
    function Reversed: TSequence<T>; overload;

    function Distinct(const aComparer: IEqualityComparer<T> = nil): TSequence<T>; overload;
    function Distinct(out aDuplicates: TList<T>; const aComparer: IEqualityComparer<T> = nil): TSequence<T>; overload;

    function Subsequence(const aLowIndex: integer; const aHighIndex: integer): TSequence<T>;
    function Take(const aCount: integer): TSequence<T>;
    function Skip(const aCount: integer): TSequence<T>;

    function Contains(const aValue: T; const aComparer: IEqualityComparer<T> = nil): boolean;
    function IndexOf(const aValue: T; const aStartIndex: integer = 0; const aComparer: IEqualityComparer<T> = nil): integer;
    function LastIndexOf(const aValue: T; const aComparer: IEqualityComparer<T> = nil): integer;

    function StartsWith(const aOther: TItems<T>; const aComparer: IEqualityComparer<T> = nil): boolean; overload;
    function StartsWith(const aOther: array of T; const aComparer: IEqualityComparer<T> = nil): boolean; overload;

    function EndsWith(const aOther: TItems<T>; const aComparer: IEqualityComparer<T> = nil): boolean; overload;
    function EndsWith(const aOther: array of T; const aComparer: IEqualityComparer<T> = nil): boolean; overload;

    function Subtract(const aOther: TItems<T>; const aComparer: IEqualityComparer<T> = nil): TSequence<T>; overload;
    function Subtract(const aOther: array of T; const aComparer: IEqualityComparer<T> = nil): TSequence<T>; overload;

    function Union(const aOther: TItems<T>; const aComparer: IEqualityComparer<T> = nil): TSequence<T>; overload;
    function Union(const aOther: array of T; const aComparer: IEqualityComparer<T> = nil): TSequence<T>; overload;

    function Intersect(const aOther: TItems<T>; const aComparer: IEqualityComparer<T> = nil): TSequence<T>; overload;
    function Intersect(const aOther: array of T; const aComparer: IEqualityComparer<T> = nil): TSequence<T>; overload;

    function SymmetricDifference(const aOther: TItems<T>; const aComparer: IEqualityComparer<T> = nil): TSequence<T>; overload;
    function SymmetricDifference(const aOther: array of T; const aComparer: IEqualityComparer<T> = nil): TSequence<T>; overload;

    function SetEquals(const aOther: TItems<T>; const aComparer: IEqualityComparer<T> = nil): boolean; overload;
    function SetEquals(const aOther: array of T; const aComparer: IEqualityComparer<T> = nil): boolean; overload;

    function Overlaps(const aOther: TItems<T>; const aComparer: IEqualityComparer<T> = nil): boolean; overload;
    function Overlaps(const aOther: array of T; const aComparer: IEqualityComparer<T> = nil): boolean; overload;

    function ToArray: TArray<T>;
    function ToList: TList<T>;

    function Collect(const aList: TList<T>; const aClearFirst: boolean = false): integer;

    function Equals(const aOther: TItems<T>; const aComparer: IEqualityComparer<T> = nil): boolean; overload;

    class operator Implicit(const aSequence: TSequence<T>): TItems<T>; static;
    class operator Implicit(const aSource: array of T): TSequence<T>; static;

    class function From(const aSource: TItems<T>): TSequence<T>; overload; static;
    class function From(const aSource: array of T): TSequence<T>; overload; static;
    class function From(const aSource: TList<T>; const aLowIndex: integer; const aHighIndex: integer): TSequence<T>; overload; static;
    class function From(const aSource: TArray<T>; const aLowIndex: integer; const aHighIndex: integer): TSequence<T>;  overload; static;
  end;

  TSegmentEnumerator<T> = class
  private
    fPos: integer;
    fSource: TList<T>;
    fHigh: integer;
  public
    function MoveNext: boolean;
    function GetCurrent: T;

    property Current: T read GetCurrent;

    constructor Create(const aSource: TList<T>; const aLowIndex, aCount: integer);
  end;

  /// <summary>
  ///  A static readonly view over a list. It does not own the source list.
  ///
  ///  It uses a fixed identity, variable accessibility model:
  ///     - the view identity is fixed: Low, High, Length
  ///     - the currently accessible range depends on the current source list count
  ///     - all reads respect current accessibility, not just nominal slice length
  /// </summary>
  TSegment<T> = record
  private
    fSource: TList<T>;
    fLow:    integer;
    fHigh:   integer;
    fLength: integer;

    function GetCount: integer; inline;
    function GetItem(const aIndex: integer): T;
    function GetIsEmpty: boolean; inline;
  public
    /// <summary>
    ///  Gets the item at the specified index.
    /// </summary>
    property Item[const aIndex: integer]: T read GetItem; default;

    /// <summary>
    ///  The number of items currently available in the segment.
    /// </summary>
    property Count: integer read GetCount;

    /// <summary>
    ///  The fixed low index into source list.
    /// </summary>
    property Low: integer read fLow;

    /// <summary>
    ///  The fixed high index into the source list.
    /// </summary>
    property High: integer read fHigh;

    /// <summary>
    ///  The fixed segment length.
    /// </summary>
    property Length: integer read fLength;

    /// <summary>
    ///  Returns true if the segment has no available items.
    /// </summary>
    property IsEmpty: boolean read GetIsEmpty;

    /// <summary>
    ///  Returns an option representing the item at the specified index.
    /// </summary>
    function ItemAt(const aIndex: integer): TOption<T>;

    /// <summary>
    ///  Returns true if the index is within the currently available range of items.
    /// </summary>
    function ContainsIndex(const aIndex: integer): boolean;

    /// <summary>
    ///  Returns a sequence of available values.
    /// </summary>
    function ToSequence: TSequence<T>;

    /// <summary>
    ///  Returns a sub-segment in the specified range.
    /// </summary>
    function ToSubSegment(const aLow, aHigh: integer): TSegment<T>;

    /// <summary>
    ///  Returns an enumerator for the available values.
    /// </summary>
    function GetEnumerator: TSegmentEnumerator<T>;

    /// <summary>
    ///  Creates a segment for the specified range over the specified source.
    /// </summary>
    class function From(
      const aSource: TList<T>;
      const aLow: integer;
      const aHigh: integer): TSegment<T>; overload; static;
  end;

  TSliceEnumerator<T> = class
  private
    fPos: integer;
    fSource: TList<T>;
    fHigh: integer;
  public
    function MoveNext: boolean;
    function GetCurrent: T;

    property Current: T read GetCurrent;

    constructor Create(const aSource: TList<T>; const aLowIndex, aCount: integer);
  end;

  /// <summary>
  ///  A static read/write view over a list. It does not own the source list.
  ///
  ///  It uses a fixed identity, variable accessibility model:
  ///     - the view identity is fixed: Low, High, Length
  ///     - the currently accessible range depends on the current source list count
  ///     - all reads/writes respect current accessibility, not just nominal slice length
  /// </summary>
  TSlice<T> = record
  private
    fSource: TList<T>;
    fLow:    integer;
    fHigh:   integer;
    fLength: integer;

    function GetCount: integer; inline;
    function GetItem(const aIndex: integer): T;
    function GetIsEmpty: boolean; inline;
    procedure SetItem(const aIndex: integer; const aValue: T);
  public
    /// <summary>
    ///  Gets the item at the specified index.
    /// </summary>
    property Item[const aIndex: integer]: T read GetItem write SetItem; default;

    /// <summary>
    ///  The number of items currently available in the segment.
    /// </summary>
    property Count: integer read GetCount;

    /// <summary>
    ///  The fixed low index into source list.
    /// </summary>
    property Low: integer read fLow;

    /// <summary>
    ///  The fixed high index into the source list.
    /// </summary>
    property High: integer read fHigh;

    /// <summary>
    ///  The fixed segment length.
    /// </summary>
    property Length: integer read fLength;

    /// <summary>
    ///  Returns true if the segment has no available items.
    /// </summary>
    property IsEmpty: boolean read GetIsEmpty;

    /// <summary>
    ///  Returns an option representing the item at the specified index.
    /// </summary>
    function ItemAt(const aIndex: integer): TOption<T>;

    /// <summary>
    ///  Sets the value of the specified index.
    /// </summary>
    function TryPut(const aIndex: integer; const aValue: T): boolean;

    /// <summary>
    ///  Sets the accessible indexes to the specified value, returns the applied count.
    /// </summary>
    function Fill(const aValue: T): Integer;

    /// <summary>
    ///  Sets the accessible indexes to default(T), returns the applied count.
    /// </summary>
    function Reset: Integer;

    /// <summary>
    ///  Reverses the accessible values.
    /// </summary>
    function Reverse: Integer;

    /// <summary>
    ///  Sorts the accessible values, returns the count of values.
    /// </summary>
    function Sort(const aComparer: IComparer<T> = nil): Integer;

    /// <summary>
    ///  Swaps the values, returns true if successful.
    /// </summary>
    function TrySwap(const aLeft, aRight: Integer): Boolean;

    /// <summary>
    ///  Returns true if the index is within the currently available range of items.
    /// </summary>
    function ContainsIndex(const aIndex: integer): boolean;

    /// <summary>
    ///  Returns a sequence of available values.
    /// </summary>
    function ToSequence: TSequence<T>;

    /// <summary>
    ///  Returns a segment,
    /// </summary>
    function ToSegment: TSegment<T>;

    /// <summary>
    ///  Returns a sub-segment in the specified range.
    /// </summary>
    function ToSubSegment(const aLow, aHigh: integer): TSegment<T>;

    /// <summary>
    ///  Returns a sub-slice in the specified range.
    /// </summary>
    function ToSubSlice(const aLow, aHigh: integer): TSlice<T>;

    /// <summary>
    ///  Returns an enumerator for the available values.
    /// </summary>
    function GetEnumerator: TSliceEnumerator<T>;

    /// <summary>
    ///  Creates a slice for the specified range over the specified source.
    /// </summary>
    class function From(
      const aSource: TList<T>;
      const aLow: integer;
      const aHigh: integer): TSlice<T>; overload; static;
  end;

  TSourceEnumerator<T> = class
  private
    fPos:    integer;
    fCount:  integer;
    fSource: TArray<T>;
  public
    constructor Create(const [ref] aSource: TArray<T>; const aCount: integer);

    function MoveNext: boolean;
    function GetCurrent: T;

    property Current: T read GetCurrent;
  end;

  /// <summary>
  ///  A more universal read-only collection input adapter, containing base collection types.
  /// </summary>
  TSource<T> = record
  private
    fItems: TArray<T>;
    fCount: integer;
    fHigh:  integer;

    function GetItem(const aIndex: Integer): T; inline;

  public
    property Items[const aIndex: integer]: T read GetItem; default;
    property Count: Integer read fCount;
    property High: Integer read fHigh;

    function IsEmpty: boolean; inline;
    function AsList: TList<T>;
    function AsArray: TArray<T>;

    function GetEnumerator: TSourceEnumerator<T>;

    procedure AppendTo(const aList: TList<T>);

    // copies source items only
    class operator Implicit(const aArray: TArray<T>): TSource<T>; static;

    // copies source items only
    class operator Implicit(const aSeq: TSequence<T>): TSource<T>; static;

    // copies source items only
    class operator Implicit(const aList: TList<T>): TSource<T>; static;

    // copies source items only
    class operator Implicit(const aSegment: TSegment<T>): TSource<T>; static;

    // copies source items only
    class operator Implicit(const aSlice: TSlice<T>): TSource<T>; static;

    // copies source items only
    class operator Implicit(const aEnum: TEnumerable<T>): TSource<T>; static;

    // copies source items and consumes enumerator
    class operator Implicit(const aEnum: TEnumerator<T>): TSource<T>; static;

    // copies source items only
    class function From(const aItems: array of T): TSource<T>; static;

    // copies source items and consumes list
    class function Consume(const aList: TList<T>): TSource<T>; static;
  end;

  /// <summary>
  ///  Stream provides an eager, declarative pipeline for processing collections in Delphi.
  ///
  ///  Streams are intended to be used in a strict pipeline style:
  ///    Ingest - Transform - Terminate.
  ///
  ///  Stream operations are eager and ownership-aware:
  ///  - Stream may own internal list containers, but never owns items.
  ///  - Item disposal occurs only when explicitly requested via OnDiscard callbacks.
  ///  - All terminal operations consume the stream; using a stream after consumption raises an exception.
  ///
  ///  Stream is designed for clarity and correctness over micro-performance and should not be used in hot paths.
  /// </summary>
  Stream = record
  public type
    TPipe<T> = record
    private type
      IState = interface
        ['{7D0D82C9-9B6B-4E6A-8EAA-0C3A2E0D1E3E}']
        function GetList: TList<T>;
        function GetOwnsList: Boolean;
        function GetConsumed: Boolean;

        procedure SetOwnsList(Value: Boolean);
        procedure SetList(const Value: TList<T>);
        procedure SetConsumed(Value: Boolean);
        procedure CheckNotConsumed;
        procedure Terminate;

        property List: TList<T> read GetList write SetList;
      end;

      TState = class(TInterfacedObject, IState)
      private
        fList: TList<T>;
        fOwnsList: Boolean;
        fConsumed: Boolean;
      public
        function GetList: TList<T>;
        function GetOwnsList: Boolean;
        function GetConsumed: Boolean;

        procedure SetList(const aValue: TList<T>);
        procedure SetOwnsList(aValue: Boolean);

        procedure SetConsumed(aValue: Boolean);
        procedure CheckNotConsumed;
        procedure Terminate;

        property List: TList<T> read GetList write SetList;

        constructor Create(AList: TList<T>; AOwnsList: Boolean);
      end;

    private
      fState: IState;

      class function CreatePipe(aList: TList<T>; aOwnsList: Boolean): TPipe<T>; static;
    public
      { transformers }

      /// <summary>
      ///  Filters the stream using a specification (keeps items where Spec is satisfied).
      ///  Preserves source order. This is a transform (does not consume the stream).
      /// </summary>
      function Filter(const aSpec: ISpecification<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>; overload;

      /// <summary>
      ///  Filters the stream, keeping only items where <paramref name="aPredicate"/> returns True.
      ///  Preserves source order. This is a transform (does not consume the stream).
      /// </summary>
      function Filter(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>; overload;

      /// <summary>
      ///  Maps each item using <paramref name="aMapper"/> to produce a stream of a different element type.
      ///  Preserves source order. This is a transform (does not consume the stream).
      /// </summary>
      function Map<U>(const aMapper: TConstFunc<T, U>; const aOnDiscard: TConstProc<T> = nil): TPipe<U>; overload;

      /// <summary>
      ///  Maps each item to a new value of the same type using <paramref name="aMapper"/>.
      ///  Preserves source order. This is a transform (does not consume the stream).
      /// </summary>
      function Map(const aMapper: TConstFunc<T, T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>; overload;

      /// <summary>
      ///  Removes duplicate items using the provided equality comparer and preserves the first occurrence
      ///  of each distinct value. This is a transform (does not consume the stream).
      /// </summary>
      function Distinct(const aComparer: IEqualityComparer<T> = nil; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Removes duplicate items by key, preserving the first occurrence of each distinct key.
      ///  This is a transform (does not consume the stream).
      /// </summary>
      function DistinctBy<TKey>(
        const aKeySelector: TConstFunc<T, TKey>;
        const aKeyEquality: IEqualityComparer<TKey> = nil;
        const aOnDiscard: TConstProc<T> = nil
      ): TPipe<T>;

      /// <summary>
      ///  Maps each item to a list of results and flattens (concatenates) them into a single stream.
      ///  Preserves source order: for each source item in order, its mapped list items are appended in order.
      ///  This is a transform (does not consume the stream).
      /// </summary>
      function FlatMap<U>(const aMapper: TConstFunc<T, TList<U>>): TPipe<U>;

      /// <summary>
      ///  Sorts the stream according to the provided comparer. This is a transform (does not consume the stream).
      /// </summary>
      function Sort(const AComparer: IComparer<T> = nil): TPipe<T>;

      /// <summary>
      ///  Reverses the order of items in the stream. This is a transform (does not consume the stream).
      /// </summary>
      function Reverse: TPipe<T>;

      /// <summary>
      ///  Concatenates the current stream with the supplied values (appends them in order).
      ///  This is a transform (does not consume the stream).
      /// </summary>
      function Concat(const aValues: array of T): TPipe<T>; overload;

      /// <summary>
      ///  Concatenates the current stream with all items from <paramref name="aList"/> (appends them in order).
      ///  This is a transform (does not consume the stream).
      /// </summary>
      function Concat(const aSource: TSource<T>): TPipe<T>; overload;

      /// <summary>
      ///  Keeps the first <paramref name="aCount"/> items (in order). This is a transform (does not consume the stream).
      /// </summary>
      function Take(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Keeps items from the start of the stream while <paramref name="aPredicate"/> returns True.
      ///  Stops at the first False. This is a transform (does not consume the stream).
      /// </summary>
      function TakeWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Keeps the last <paramref name="aCount"/> items (in order). This is a transform (does not consume the stream).
      /// </summary>
      function TakeLast(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Keeps items from the start of the stream until <paramref name="aPredicate"/> returns True.
      ///  Once the predicate returns True, all remaining items are removed (predicate is not evaluated further).
      ///  This is a transform (does not consume the stream).
      /// </summary>
      function TakeUntil(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Skips the first <paramref name="aCount"/> items and keeps the remainder (in order).
      ///  This is a transform (does not consume the stream).
      /// </summary>
      function Skip(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Skips items from the start of the stream while <paramref name="aPredicate"/> returns True.
      ///  Once the predicate returns False, all remaining items are kept (predicate is not evaluated further).
      ///  This is a transform (does not consume the stream).
      /// </summary>
      function SkipWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Skips the last <paramref name="aCount"/> items and keeps the prefix (in order).
      ///  This is a transform (does not consume the stream).
      /// </summary>
      function SkipLast(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Skips items from the start of the stream until <paramref name="aPredicate"/> returns True.
      ///  Once the predicate returns True, all remaining items are kept (predicate is not evaluated further).
      ///  This is a transform (does not consume the stream).
      /// </summary>
      function SkipUntil(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Observes items in the stream without changing them. Invokes <paramref name="aAction"/> for each item,
      ///  passing a zero-based index and the item value. This is a transform (does not consume the stream).
      /// </summary>
      function Peek(const aAction: TConstProc<Integer, T>): TPipe<T>;

      /// <summary>
      ///  Zips the stream with <paramref name="aOther"/> pairwise (index, left, right) using <paramref name="aZipper"/>.
      ///  Stops at the shorter sequence. This is a transform (does not consume the stream).
      /// </summary>
      function Zip<T2, TResult>(
        const aOther: TSource<T2>;
        const aZipper: TConstFunc<Integer, T, T2, TResult>;
        const aOnDiscard: TConstProc<T> = nil;
        const aOnDiscardOther: TConstProc<T2> = nil
      ): TPipe<TResult>; overload;

      /// <summary>
      ///  Zips the stream with <paramref name="aOther"/> pairwise (index, left, right) using <paramref name="aZipper"/>.
      ///  Stops at the shorter sequence. This is a transform (does not consume the stream).
      /// </summary>
      function Zip<T2, TResult>(
        const aOther: array of T2;
        const aZipper: TConstFunc<Integer, T, T2, TResult>;
        const aOnDiscard: TConstProc<T> = nil;
        const aOnDiscardOther: TConstProc<T2> = nil
      ): TPipe<TResult>; overload;

      /// <summary>
      /// Subtracts the items in the specified other source from the Stream.
      /// If aComparer is nil, the default equality comparer for T is used.
      /// </summary>
      function Subtract(
        const aOther: TSource<T>;
        const aComparer: IEqualityComparer<T> = nil;
        const aOnDiscard: TConstProc<T> = nil
      ): TPipe<T>; overload;

      /// <summary>
      /// Subtracts the items in the the specified other source from the Stream.
      /// If aComparer is nil, the default equality comparer for T is used.
      /// </summary>
      function Subtract(
        const aOther: array of T;
        const aComparer: IEqualityComparer<T> = nil;
        const aOnDiscard: TConstProc<T> = nil
      ): TPipe<T>; overload;

      function Intersect(
        const aOther: TSource<T>;
        const aComparer: IEqualityComparer<T> = nil;
        const aOnDiscard: TConstProc<T> = nil
      ): TPipe<T>; overload;

      function Intersect(
        const aItems: array of T;
        const aComparer: IEqualityComparer<T> = nil;
        const aOnDiscard: TConstProc<T> = nil
      ): TPipe<T>; overload;

      function Union(
        const aOther: TSource<T>;
        const aComparer: IEqualityComparer<T> = nil;
        const aOnDiscard: TConstProc<T> = nil;
        const aOnDiscardOther: TConstProc<T> = nil
      ): TPipe<T>; overload;

      function Union(
        const aOther: array of T;
        const aComparer: IEqualityComparer<T> = nil;
        const aOnDiscard: TConstProc<T> = nil;
        const aOnDiscardOther: TConstProc<T> = nil
      ): TPipe<T>; overload;

      function SymmetricDifference(
        const aOther: TSource<T>;
        const aComparer: IEqualityComparer<T> = nil;
        const aOnDiscard: TConstProc<T> = nil;
        const aOnDiscardOther: TConstProc<T> = nil
      ): TPipe<T>; overload;

      function SymmetricDifference(
        const aOther: array of T;
        const aComparer: IEqualityComparer<T> = nil;
        const aOnDiscard: TConstProc<T> = nil;
        const aOnDiscardOther: TConstProc<T> = nil
      ): TPipe<T>; overload;

      { terminators }

      /// <summary>
      ///  Materializes the stream as a list and consumes the stream.
      ///  The caller owns the returned list container.
      /// </summary>
      function AsList: TList<T>;

      /// <summary>
      ///  Materializes the stream as a dynamic array (TArray&lt;T&gt;) and consumes the stream.
      /// </summary>
      function AsArray: TArray<T>;

      /// <summary>
      ///  Materializes the stream as a sequence.
      /// </summary>
      function AsSequence: TSequence<T>;

      /// <summary>
      ///  Returns the number of items in the stream and consumes the stream.
      /// </summary>
      function Count: Integer;

      /// <summary>
      ///  Counts items in the stream by a key produced by <paramref name="aKeySelector"/> and consumes the stream.
      /// </summary>
      function CountBy<TKey>(
        const aKeySelector: TConstFunc<T, TKey>;
        const aEquality: IEqualityComparer<TKey> = nil
      ): TDictionary<TKey, Integer>;

      /// <summary>
      ///  Returns True if any item satisfies <paramref name="aPredicate"/>. Short-circuits and consumes the stream.
      /// </summary>
      function Any(const aPredicate: TConstPredicate<T>): Boolean; overload;

      /// <summary>
      ///  Returns True if any item satisfies <paramref name="aSpec"/>. Short-circuits and consumes the stream.
      /// </summary>
      function Any(const aSpec: ISpecification<T>): Boolean; overload;

      /// <summary>
      ///  Returns True if all items satisfy <paramref name="aPredicate"/>. Short-circuits and consumes the stream.
      /// </summary>
      function All(const aPredicate: TConstPredicate<T>): Boolean; overload;

      /// <summary>
      ///  Returns True if all items satisfy <paramref name="aSpec"/>. Short-circuits and consumes the stream.
      /// </summary>
      function All(const aSpec: ISpecification<T>): Boolean; overload;

      /// <summary>
      ///  Reduces (folds) the stream into an accumulator starting from <paramref name="aSeed"/> using <paramref name="aReducer"/>.
      ///  Preserves source order and consumes the stream.
      /// </summary>
      function Reduce<TAcc>(const aSeed: TAcc; const aReducer: TConstFunc<TAcc, T, TAcc>): TAcc;

      /// <summary>
      ///  Returns the first item in the stream; if empty, returns <paramref name="aDefault"/>.
      ///  Consumes the stream.
      /// </summary>
      function FirstOr(const aDefault: T): T;

      /// <summary>
      ///  Returns the first item in the stream; if empty, returns <paramref name="aDefault"/>.
      ///  Consumes the stream.
      /// </summary>
      function FirstOrDefault: T;

      /// <summary>
      ///  Returns the last item in the stream; if empty, returns <paramref name="aDefault"/>.
      ///  Consumes the stream.
      /// </summary>
      function LastOr(const aDefault: T): T;

      /// <summary>
      ///  Returns the last item in the stream; if empty, returns <c>Default(T)</c>.
      ///  Consumes the stream.
      /// </summary>
      function LastOrDefault: T;

      /// <summary>
      ///  Returns True if the stream contains no items and consumes the stream.
      /// </summary>
      function IsEmpty: Boolean;

      /// <summary>
      ///  Returns True if no items satisfy <paramref name="aPredicate"/>. Short-circuits and consumes the stream.
      /// </summary>
      function None(const aPredicate: TConstPredicate<T>): Boolean;

      /// <summary>
      ///  Returns True if the stream contains <paramref name="aValue"/> according to <paramref name="aEquality"/>.
      ///  Short-circuits and consumes the stream.
      /// </summary>
      function Contains(const aValue: T; const aEquality: IEqualityComparer<T> = nil): Boolean;

      /// <summary>
      ///  Invokes <paramref name="aAction"/> for each item in the stream and consumes the stream.
      /// </summary>
      procedure ForEach(const aAction: TConstProc<T>);

      /// <summary>
      ///  Groups the items in the stream by a key produced by <paramref name="aKeySelector"/>.
      ///  Each distinct key maps to a list of items that share that key.
      ///  This is a terminal operation and consumes the stream.
      /// </summary>
      function GroupBy<TKey>(
        const aKeySelector: TConstFunc<T, TKey>;
        const aEquality: IEqualityComparer<TKey> = nil): TDictionary<TKey, TList<T>>; overload;

      /// <summary>
      ///  Splits the stream into two lists based on <paramref name="aPredicate"/>.
      ///  Items for which the predicate returns True are placed in the first list;
      ///  all other items are placed in the second list.
      ///  This is a terminal operation and consumes the stream.
      /// </summary>
      function Partition(const aPredicate: TConstPredicate<T>): TPair<TList<T>, TList<T>>; overload;

      /// <summary>
      ///  Splits the stream into two lists based on <paramref name="aSpec"/> and consumes the stream.
      ///  Items for which the specification is satisfied are placed in the first list;
      ///  all other items are placed in the second list.
      /// </summary>
      function Partition(const aSpec: ISpecification<T>): TPair<TList<T>, TList<T>>; overload;

      /// <summary>
      ///  Splits the stream into two lists at <paramref name="aIndex"/> and consumes the stream.
      ///  The first list contains the first <paramref name="aIndex"/> items; the second contains the remaining items.
      /// </summary>
      function SplitAt(const aIndex: Integer): TPair<TList<T>, TList<T>>;
    end;

  public
    /// <summary>
    /// Ingests items from the list - does not take ownership of the list.
    /// Items are never freed by Stream automatically.
    /// </summary>
    class function From<T>(const aList: TList<T>): TPipe<T>; overload; static;

    /// <summary>
    /// Ingests items from the source.
    /// Items are never freed by Stream automatically.
    /// </summary>
    class function From<T>(const aSource: TSource<T>): TPipe<T>; overload; static;

    /// <summary>
    /// Ingests items from the array.
    /// Items are never freed by Stream automatically.
    /// </summary>
    class function From<T>(const aValues: array of T): TPipe<T>; overload; static;

    /// <summary>
    /// Ingests items from the list - takes ownership of the list.
    /// Items are never freed by Stream automatically.
    /// </summary>
    class function Consume<T>(const aList: TList<T>): TPipe<T>; overload; static;

    /// <summary>
    /// Ingest items from an enumerator - takes ownership of  the enumerator.
    /// Items are never freed by Stream automatically.
    /// </summary>
    class function Consume<T>(aEnum: TEnumerator<T>): TPipe<T>; overload; static;
  end;

  TIndexSource = (isNone, isArray, isList);

  /// <summary>
  ///  A lightweight read-only index over a collection.
  ///
  ///  TIndex<T> does not own the source collection. It captures a transient
  ///  indexed view at adaptation time, which means:
  ///
  ///   - Count is fixed
  ///   - The indexer may still read through to the underlying source
  ///
  ///  If detached or thread-safe access is required, prefer TItems<T> or
  ///  TSource<T>, which materialize their views. If synchronization is not a
  ///  concern, TIndex<T> is the lighter-weight option.
  ///
  ///  TIndex<T> can be suitable as a boundary object in multi-threaded scenarios,
  ///  if count never decreases during the index's lifetime.
  /// </summary>
  TIndex<T> = record
  private
    fArray: TArray<T>;
    fList:  TList<T>;
    fType:  TIndexSource;
    fCount: integer;
    fHigh:  integer;

    function GetItem(const aIndex: Integer): T; inline;

  public
    property Items[const aIndex: integer]: T read GetItem; default;
    property Count: Integer read fCount;
    property High: Integer read fHigh;

    function IsEmpty: boolean; inline;

    function AppendTo(const aList: TList<T>): Integer;

    function ToList: TList<T>;
    function ToArray: TArray<T>;
    function ToSequence: TSequence<T>;

    // copies source items only
    class operator Implicit(const aArray: TArray<T>): TIndex<T>; static;

    // copies source items and consumes enumerator
    class operator Implicit(const aEnum: TEnumerator<T>): TIndex<T>; static;

    // copies source items only
    class operator Implicit(const aEnum: TEnumerable<T>): TIndex<T>; static;

    // copies source items only
    class operator Implicit(const aList: TList<T>): TIndex<T>; static;

    // copies source items only
    class operator Implicit(const aSegment: TSegment<T>): TIndex<T>; static;

    // copies source items only
    class operator Implicit(const aSlice: TSlice<T>): TIndex<T>; static;

    // copies source items only
    class operator Implicit(const aSeq: TSequence<T>): TIndex<T>; static;

    // copies source items only
    class function From(const aItems: array of T): TIndex<T>; static;

    // copies source items and consumes list
    class function Consume(const aList: TList<T>): TIndex<T>; static;
  end;

  TPin<T> = class
  private
    fSource: TList<T>;
    fIndex:  integer;
  public
    function GetItem: T;
    procedure SetItem(const aValue: T);

    constructor Create(const aSource: TList<T>; const aIndex: integer);
  end;

  /// <summary>
  ///  A borrowed ordered selection of items referenced by (Source, Index) pins.
  ///
  ///  TSelection<T> is a non-contiguous projection over one or more TList<T>
  ///  instances. Unlike TSegment<T> and TSlice<T>, which represent contiguous
  ///  windows over a single source list, TSelection<T> stores an ordered list of
  ///  explicit references to items across one or more source lists.
  ///
  ///  The selection itself is mutable in structure:
  ///   - pins can be added
  ///   - pins can be removed
  ///   - the selection can be cleared
  ///
  ///  Dereferenced values can also be read and written through the selection,
  ///  which means writing through the selection updates the underlying source
  ///  item at the pinned (Source, Index) location.
  ///
  ///  Ownership / validity policy:
  ///   - TSelection<T> does not own its source lists
  ///   - TSelection<T> does not own the pinned items
  ///   - TSelection<T> does not stabilize or track source mutation
  ///   - callers are responsible for ensuring that pinned source lists remain
  ///     alive and that pinned indices remain valid for the intended lifetime of
  ///     the selection
  ///
  ///  If a source list is destroyed, or if a pinned index becomes invalid due to
  ///  source mutation, strict access may raise an exception and safe access will
  ///  fail in the corresponding safe API.
  ///
  ///  TSelection<T> is intended to model arbitrary picked items, such as:
  ///   - selected cells
  ///   - game-board lines / diagonals
  ///   - sparse picks across one or more lists
  ///
  ///  When a stable detached value is required, materialize the selection via
  ///  ToSequence, ToArray, or ToList.
  /// </summary>
  TSelection<T> = class
  private
    fPins: TList<TPin<T>>;
    fComparer: IEqualityComparer<T>;

    function GetCount: integer;
    function GetHigh: integer;
    function GetIsEmpty: boolean;
    function GetItem(const aIndex: integer): T;

    procedure SetItem(const aIndex: integer; const aValue: T);
    procedure ValidateIndex(const aIndex: integer); inline;
  public
    property Items[const aIndex: integer]: T read GetItem write SetItem; default;
    property Count: integer read GetCount;
    property High: integer read GetHigh;
    property IsEmpty: boolean read GetIsEmpty;

    function ItemAt(const aIndex: integer): TOption<T>;
    function TryPut(const aIndex: integer; const aValue: T): boolean;

    function All(const aValue: T): boolean;
    function Any(const aValue: T): boolean;
    function CountOf(const aValue: T): integer;
    function IndexOf(const aValue: T; const aStartIndex: integer = 0): integer;
    function LastIndexOf(const aValue: T): integer;

    function GetEnumerator: TEnumerator<TPin<T>>;

    function ToList: TList<T>;
    function ToArray: TArray<T>;
    function ToSequence: TSequence<T>;

    procedure Add(const aSource: TList<T>; const aIndex: integer);
    procedure Remove(const aIndex: integer);
    procedure Clear;

    constructor Create(const aComparer: IEqualityComparer<T> = nil);
    destructor Destroy; override;
  end;

implementation

{ TSegmentEnumerator<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TSequenceEnumerator<T>.Create(const [ref] aSource: TArray<T>; const aCount: integer);
begin
  fSource := aSource;
  fPos    := -1;
  fCount  := aCount;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequenceEnumerator<T>.GetCurrent: T;
begin
  Result :=  fSource[fPos];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequenceEnumerator<T>.MoveNext: boolean;
begin
  Inc(fPos);
  Result := fPos < fCount;
end;

{ TSequence<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.GetItem(const aIndex: integer): T;
begin
  Ensure.IsGreater(0, fCount, 'index out of range, the sequence is empty');
  Ensure.InExcRange(aIndex, 0, fCount);

  Result := fItems[aIndex];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.ItemAt(const aIndex: integer): TOption<T>;
begin
  if fCount > aIndex then
    Result.SetSome(fItems[aIndex]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.GetFirst: TOption<T>;
begin
  if fCount > 0 then
    Result.SetSome(fItems[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.GetLast:TOption<T>;
begin
  if fCount > 0 then
    Result.SetSome(fItems[fCount - 1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Subsequence(const aLowIndex, aHighIndex: integer): TSequence<T>;
begin
  if fCount = 0 then exit(Self);

  var hi  := if aHighIndex >= fCount then Pred(fCount) else aHighIndex;
  var lo  := if aLowIndex >= 0 then aLowIndex else 0;
  var len := hi - lo + 1;

  if len < 1 then exit;

  SetLength(Result.fItems, len);

  for var i := 0 to Pred(len) do
    Result.fItems[i] := GetItem(lo + i);

  Result.fCount := len;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.GetEnumerator: TSequenceEnumerator<T>;
begin
  Result := TSequenceEnumerator<T>.Create(fItems, fCount);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.GetIsEmpty: boolean;
begin
  Result := fCount = 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Collect(const aList: TList<T>; const aClearFirst: boolean): integer;
begin
  Ensure.IsTrue(aList <> nil, 'Unable to collect results into an unassigned list');

  if aClearFirst then
    aList.Clear;

  if fCount <> 0 then
    aList.AddRange(fItems);

  Result := fCount;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Distinct(const aComparer: IEqualityComparer<T> = nil): TSequence<T>;
var
  scope: TScope;
begin
  if fCount = 0 then exit(Self);

  var cmp := if Assigned(aComparer) then aComparer else TEqualityComparer<T>.Default;

  var seen := scope.Owns(TDictionary<T, integer>.Create(cmp));
  var list  := scope.Owns(TList<T>.Create);

  for var item in fItems do
    if not seen.ContainsKey(item) then
    begin
      seen.Add(item, 0);
      list.Add(item);
    end;

  Result.fItems := list.ToArray;
  Result.fCount := list.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Distinct(out aDuplicates: TList<T>; const aComparer: IEqualityComparer<T> = nil): TSequence<T>;
var
  scope: TScope;
begin
  if fCount = 0 then exit(Self);

  var cmp := if Assigned(aComparer) then aComparer else TEqualityComparer<T>.Default;

  var seen := scope.Owns(TDictionary<T, integer>.Create(cmp));
  var list := scope.Owns(TList<T>.Create);

  aDuplicates := scope.Owns(TList<T>.Create);

  for var item in fItems do
    if seen.ContainsKey(item) then
      aDuplicates.Add(item)
    else
    begin
      seen.Add(item, 0);
      list.Add(item);
    end;

  Result.fItems := list.ToArray;
  Result.fCount := list.Count;

  scope.Release(aDuplicates);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Sorted(const aComparer: IComparer<T>): TSequence<T>;
begin
  if fCount = 0 then exit(Self);

  var cmp := TLx.Ensure<T>(aComparer);

  Result.fItems := Copy(fItems);
  Result.fCount := fCount;

  TArray.Sort<T>(Result.fItems, cmp);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Contains(const aValue: T; const aComparer: IEqualityComparer<T>): boolean;
begin
  Result := IndexOf(aValue, 0, aComparer) <> -1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.IndexOf(const aValue: T; const aStartIndex: integer; const aComparer: IEqualityComparer<T>): integer;
begin
  Result := -1;

  var idx := if aStartIndex >= 0 then aStartIndex else 0;

  if idx >= fCount then exit;

  var cmp := TLx.Ensure<T>(aComparer);

  for var i := idx to Pred(fCount) do
    if cmp.Equals(fItems[i], aValue) then exit(i);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.LastIndexOf(const aValue: T; const aComparer: IEqualityComparer<T> = nil): integer;
begin
  Result := -1;

  if fCount = 0 then exit;

  var cmp := TLx.Ensure<T>(aComparer);

  for var i := Pred(fCount) downto 0 do
    if cmp.Equals(fItems[i], aValue) then exit(i);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.StartsWith(const aOther: array of T; const aComparer: IEqualityComparer<T>): boolean;
begin
  Result := StartsWith(TItems<T>.From(aOther), aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.StartsWith(const aOther: TItems<T>; const aComparer: IEqualityComparer<T>): boolean;
begin
  var len := aOther.fCount;

  if len = 0 then exit(true);
  if len > fCount then exit(false);

  var cmp := TLx.Ensure<T>(aComparer);

  for var i := 0 to Pred(len) do
    if not cmp.Equals(fItems[i], aOther[i]) then exit(false);

  Result := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.EndsWith(const aOther: array of T; const aComparer: IEqualityComparer<T>): boolean;
begin
  Result := EndsWith(TItems<T>.From(aOther), aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.EndsWith(const aOther: TItems<T>; const aComparer: IEqualityComparer<T>): boolean;
begin
  var len := aOther.Count;

  if len = 0 then exit(true);
  if len > fCount then exit(false);

  var cmp := TLx.Ensure<T>(aComparer);

  var lo := fCount - len;

  for var i := 0 to Pred(len) do
    if not cmp.Equals(fItems[lo + i], aOther[i]) then exit(false);

  Result := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Subtract(const aOther: TItems<T>; const aComparer: IEqualityComparer<T>): TSequence<T>;
var
  scope: TScope;
begin
  if aOther.IsEmpty or (fCount = 0) then exit(self);

  var cmp := TLx.Ensure<T>(aComparer);

  var excluded := scope.Owns(TDictionary<T, Byte>.Create(cmp));

  for var i := 0 to aOther.High do
  begin
    var item := aOther[i];

    if not excluded.ContainsKey(item) then
      excluded.Add(item, 0);
  end;

  var list := scope.Owns(TList<T>.Create);
  list.Capacity := fCount;

  for var i := 0 to Pred(fCount) do
    if not excluded.ContainsKey(fItems[i]) then
      list.Add(fItems[i]);

  Result := TSequence<T>.From(list.ToArray);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Subtract(const aOther: array of T; const aComparer: IEqualityComparer<T>): TSequence<T>;
begin
  Result := Subtract(TItems<T>.From(aOther), aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Union(const aOther: TItems<T>; const aComparer: IEqualityComparer<T>): TSequence<T>;
var
  scope: TScope;
begin
  if aOther.IsEmpty then exit(Self);

  if fCount = 0 then exit(TSequence<T>.From(aOther));

  var cmp := TLx.Ensure<T>(aComparer);

  var seen := scope.Owns(TDictionary<T, Byte>.Create(cmp));
  var list := scope.Owns(TList<T>.Create);

  list.Capacity := fCount + aOther.Count;

  for var i := 0 to Pred(fCount) do
  begin
    var item := fItems[i];

    if not seen.ContainsKey(item) then
    begin
      seen.Add(item, 0);
      list.Add(item);
    end;
  end;

  for var i := 0 to aOther.High do
  begin
    var item := aOther[i];

    if not seen.ContainsKey(item) then
    begin
      seen.Add(item, 0);
      list.Add(item);
    end;
  end;

  Result := TSequence<T>.From(list.ToArray);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Union(const aOther: array of T; const aComparer: IEqualityComparer<T>): TSequence<T>;
begin
  Result := Union(TItems<T>.From(aOther), aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Intersect(const aOther: TItems<T>; const aComparer: IEqualityComparer<T>): TSequence<T>;
var
  scope: TScope;
begin
  if (aOther.IsEmpty) or (fCount = 0) then exit(TSequence<T>.From([]));

  var cmp := TLx.Ensure<T>(aComparer);

  var included := scope.Owns(TDictionary<T, Byte>.Create(cmp));

  for var i := 0 to aOther.High do
  begin
    var item := aOther[i];

    if not included.ContainsKey(item) then
      included.Add(item, 0);
  end;

  var list := scope.Owns(TList<T>.Create);
  list.Capacity := fCount;

  for var i := 0 to Pred(fCount) do
    if included.ContainsKey(fItems[i]) then
      list.Add(fItems[i]);

  Result := TSequence<T>.From(list.ToArray);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Intersect(const aOther: array of T; const aComparer: IEqualityComparer<T>): TSequence<T>;
begin
  Result := Intersect(TItems<T>.From(aOther), aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.SymmetricDifference(const aOther: TItems<T>; const aComparer: IEqualityComparer<T>): TSequence<T>;
var
  scope: TScope;
begin
  var cmp := TLx.Ensure<T>(aComparer);

  var seenSelf  := scope.Owns(TDictionary<T, Byte>.Create(cmp));
  var seenOther := scope.Owns(TDictionary<T, Byte>.Create(cmp));
  var seenOut   := scope.Owns(TDictionary<T, Byte>.Create(cmp));
  var list      := scope.Owns(TList<T>.Create);

  for var i := 0 to Pred(fCount) do
  begin
    var item := fItems[i];

    if not seenSelf.ContainsKey(item) then
      seenSelf.Add(item, 0);
  end;

  for var i := 0 to aOther.High do
  begin
    var item := aOther[i];

    if not seenOther.ContainsKey(item) then
      seenOther.Add(item, 0);
  end;

  list.Capacity := seenSelf.Count + seenOther.Count;

  for var i := 0 to Pred(fCount) do
  begin
    var item := fItems[i];

    if not seenOther.ContainsKey(item) then
      if not seenOut.ContainsKey(item) then
      begin
        seenOut.Add(item, 0);
        list.Add(item);
      end;
  end;

  for var i := 0 to aOther.High do
  begin
    var item := aOther[i];

    if not seenSelf.ContainsKey(item) then
      if not seenOut.ContainsKey(item) then
      begin
        seenOut.Add(item, 0);
        list.Add(item);
      end;
  end;

  Result := TSequence<T>.From(list.ToArray);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.SymmetricDifference(const aOther: array of T; const aComparer: IEqualityComparer<T>): TSequence<T>;
begin
  Result := SymmetricDifference(TItems<T>.From(aOther), aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.SetEquals(const aOther: TItems<T>; const aComparer: IEqualityComparer<T>): boolean;
var
  scope: TScope;
begin
  var cmp := TLx.Ensure<T>(aComparer);

  var seenSelf  := scope.Owns(TDictionary<T, Byte>.Create(cmp));
  var seenOther := scope.Owns(TDictionary<T, Byte>.Create(cmp));

  for var i := 0 to Pred(fCount) do
  begin
    var item := fItems[i];

    if not seenSelf.ContainsKey(item) then
      seenSelf.Add(item, 0);
  end;

  for var i := 0 to aOther.High do
  begin
    var item := aOther[i];

    if not seenOther.ContainsKey(item) then
      seenOther.Add(item, 0);
  end;

  if seenSelf.Count <> seenOther.Count then
    Exit(False);

  for var pair in seenSelf do
    if not seenOther.ContainsKey(pair.Key) then
      Exit(False);

  Result := True;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.SetEquals(const aOther: array of T; const aComparer: IEqualityComparer<T>): boolean;
begin
  Result := SetEquals(TItems<T>.From(aOther), aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Reversed: TSequence<T>;
var
  scope: TScope;
begin
  if fCount = 0 then exit(Self);

  var items := scope.Owns(ToList);

  items.Reverse;

  Result.fItems := items.ToArray;
  Result.fCount := items.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Overlaps(const aOther: TItems<T>; const aComparer: IEqualityComparer<T>): boolean;
var
  scope: TScope;
begin
  if (fCount = 0) or (aOther.IsEmpty) then exit(False);

  var cmp := TLx.Ensure<T>(aComparer);
  var seen := scope.Owns(TDictionary<T, Byte>.Create(cmp));

  for var i := 0 to Pred(fCount) do
  begin
    var item := fItems[i];

    if not seen.ContainsKey(item) then
      seen.Add(item, 0);
  end;

  for var i := 0 to aOther.High do
    if seen.ContainsKey(aOther[i]) then
      Exit(True);

  Result := False;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Overlaps(const aOther: array of T; const aComparer: IEqualityComparer<T>): boolean;
begin
  Result := Overlaps(TItems<T>.From(aOther), aComparer);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Equals(const aOther: TItems<T>; const aComparer: IEqualityComparer<T>): boolean;
begin
  if aOther.fCount <> fCount then exit(false);

  if fCount = 0 then exit(true);

  var cmp := TLx.Ensure<T>(aComparer);

  for var i := 0 to Pred(aOther.Count) do
    if not cmp.Equals(fItems[i], aOther.fItems[i]) then exit(false);

  Result := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Take(const aCount: integer): TSequence<T>;
begin
  Result := Subsequence(0, Pred(aCount));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.Skip(const aCount: integer): TSequence<T>;
begin
  Result := Subsequence(aCount, Pred(fCount));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.ToArray: TArray<T>;
begin
  if fCount = 0 then exit;

  Result := Copy(fItems);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSequence<T>.ToList: TList<T>;
begin
  Result := TList<T>.Create;

  if fCount <> 0 then
    Result.AddRange(fItems);
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TSequence<T>.Implicit(const aSequence: TSequence<T>): TItems<T>;
begin
  Result.fItems := Copy(aSequence.fItems);
  Result.fCount := aSequence.Count;
  Result.fHigh  := aSequence.Count - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TSequence<T>.Implicit(const aSource: array of T): TSequence<T>;
begin
  Result.fCount := 0;

  var len := Length(aSource);

  if len = 0 then exit;

  SetLength(Result.fItems, len);

  for var i := 0 to High(aSource) do
    Result.fItems[i] := aSource[i];

  Result.fCount := len;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TSequence<T>.From(const aSource: TItems<T>): TSequence<T>;
begin
  Result.fCount := 0;

  var len := aSource.Count;

  if len = 0 then exit;

  SetLength(Result.fItems, len);

  for var i := 0 to Pred(len) do
    Result.fItems[i] := aSource[i];

  Result.fCount := len;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TSequence<T>.From(const aSource: array of T): TSequence<T>;
begin
  Result.fCount := 0;

  var len := Length(aSource);

  if len = 0 then exit;

  SetLength(Result.fItems, len);

  for var i := 0 to Pred(len) do
    Result.fItems[i] := aSource[i];

  Result.fCount := len;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TSequence<T>.From(const aSource: TArray<T>; const aLowIndex, aHighIndex: integer): TSequence<T>;
begin
  Result.fCount := 0;

  if not Assigned(aSource) then exit;

  var len := Length(aSource);
  var hi  := if aHighIndex >= len then Pred(len) else aHighIndex;
  var low := if aLowIndex >= 0 then aLowIndex else 0;

  len := hi - low + 1;

  if len < 1 then exit;

  SetLength(Result.fItems, len);

  for var i := 0 to Pred(len) do
    Result.fItems[i] := aSource[low + i];

  Result.fCount := len;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TSequence<T>.From(const aSource: TList<T>; const aLowIndex, aHighIndex: integer): TSequence<T>;
begin
  Result.fCount := 0;

  if aSource = nil then exit;

  var len := aSource.Count;
  var hi  := if aHighIndex >= len then Pred(len) else aHighIndex;
  var low := if aLowIndex >= 0 then aLowIndex else 0;

  len := hi - low + 1;

  if len < 1 then exit;

  SetLength(Result.fItems, len);

  for var i := 0 to Pred(len) do
    Result.fItems[i] := aSource[low + i];

  Result.fCount := len;
end;

{ Stream.TPipe<T>.TState }

{----------------------------------------------------------------------------------------------------------------------}
constructor Stream.TPipe<T>.TState.Create(aList: TList<T>; aOwnsList: Boolean);
begin
  inherited Create;

  fList     := aList;
  fOwnsList := aOwnsList;
  fConsumed := false;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TState.GetConsumed: Boolean;
begin
  Result := fConsumed;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TState.GetList: TList<T>;
begin
  Result := fList;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TState.GetOwnsList: Boolean;
begin
  Result := fOwnsList;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.SetConsumed(aValue: Boolean);
begin
  fConsumed := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.SetList(const aValue: TList<T>);
begin
  if (Assigned(fList)) and (fOwnsList) then
  begin
    fList.Free;
    fList := nil;
  end;

  fList := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.SetOwnsList(aValue: Boolean);
begin
  fOwnsList := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.Terminate;
begin
  SetList(nil);

  fOwnsList := false;
  fConsumed := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.CheckNotConsumed;
begin
  Ensure.IsFalse(fConsumed, 'Stream has been consumed');
end;

{ Stream.TPipe<T> }

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.TPipe<T>.CreatePipe(aList: TList<T>; aOwnsList: Boolean): TPipe<T>;
begin
  Result.fState := TState.Create(aList, aOwnsList);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.AsList: TList<T>;
begin
  fState.CheckNotConsumed;

  Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

  Result := if fState.GetOwnsList then fState.List else TList<T>.Create(fState.List);

  FState.SetOwnsList(false);
  FState.SetList(nil);
  FState.SetConsumed(true);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.AsSequence: TSequence<T>;
begin
  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    Result := TSequence<T>.From(fState.List);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.AsArray: TArray<T>;
begin
  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    SetLength(Result, fState.List.Count);

    for var i := 0 to Pred(fState.List.Count) do
      Result[I] := fState.List[I];

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Count: Integer;
begin
  try
    Ensure.IsTrue(Assigned(FState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    Result := FState.List.Count;

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.CountBy<TKey>(
  const aKeySelector: TConstFunc<T, TKey>;
  const aEquality: IEqualityComparer<TKey>
): TDictionary<TKey, Integer>;
var
  count: Integer;
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(aKeySelector), 'KeySelector is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    FState.CheckNotConsumed;

    var eq := if aEquality <> nil then aEquality else TEqualityComparer<TKey>.Default;

    var map := scope.Owns(TDictionary<TKey, Integer>.Create(eq));

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var key := aKeySelector(fState.List[i]);

      if map.TryGetValue(key, count) then
        map[key] := count + 1
      else
        map.Add(key, 1);
    end;

    Result := scope.Release(map);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Any(const aPredicate: TConstPredicate<T>): Boolean;
begin
  try
    Ensure.IsTrue(Assigned(aPredicate), 'Predicate is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    FState.CheckNotConsumed;

    Result := False;

    for var i := 0 to Pred(fState.List.Count) do
      if aPredicate(fState.List[i]) then
      begin
        Result := True;
        Break;
      end;

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Any(const aSpec: ISpecification<T>): Boolean;
begin
  try
    Ensure.IsTrue(Assigned(aSpec), 'Spec is nil');

    Result := Any(
      function(const item: T): Boolean
      begin
        Result := aSpec.IsSatisfiedBy(item);
      end
    );

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.All(const aPredicate: TConstPredicate<T>): Boolean;
begin
  try
    Ensure.IsTrue(Assigned(aPredicate), 'Predicate is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    FState.CheckNotConsumed;

    Result := True;

    for var i := 0 to Pred(fState.List.Count) do
      if not aPredicate(fState.List[i]) then
      begin
        Result := False;
        Break;
      end;

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.All(const aSpec: ISpecification<T>): Boolean;
begin
  try
    Ensure.IsTrue(Assigned(aSpec), 'Spec is nil');

    Result := All(
      function(const item: T): Boolean
      begin
        Result := aSpec.IsSatisfiedBy(item);
      end);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Reduce<TAcc>(const aSeed: TAcc; const aReducer: TConstFunc<TAcc, T, TAcc>): TAcc;
begin
  try
    Ensure.IsTrue(Assigned(aReducer), 'Reducer is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    FState.CheckNotConsumed;

    var acc := aSeed;

    for var i := 0 to Pred(fState.List.Count) do
      acc := aReducer(acc, fState.List[i]);

    Result := acc;

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.ForEach(const aAction: TConstProc<T>);
begin
  try
    Ensure.IsTrue(Assigned(aAction), 'Action is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    FState.CheckNotConsumed;

    for var i := 0 to Pred(fState.List.Count) do
      aAction(fState.List[i]);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.FirstOrDefault: T;
begin
  Result := FirstOr(Default(T));
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.FirstOr(const aDefault: T): T;
begin
  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    FState.CheckNotConsumed;

    if fState.List.Count > 0 then
      Result := fState.List[0]
    else
      Result := aDefault;

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.LastOrDefault: T;
begin
  Result := LastOr(Default(T));
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.LastOr(const aDefault: T): T;
begin
  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    FState.CheckNotConsumed;

    if fState.List.Count > 0 then
      Result := fState.List[Pred(fState.List.Count)]
    else
      Result := aDefault;

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.IsEmpty: Boolean;
begin
  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    FState.CheckNotConsumed;

    Result := fState.List.Count = 0;

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.None(const aPredicate: TConstPredicate<T>): Boolean;
begin
  try
    Ensure.IsTrue(Assigned(aPredicate), 'Predicate is nil');

    Result := not Any(aPredicate);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Contains(const aValue: T; const aEquality: IEqualityComparer<T>): Boolean;
begin
  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    FState.CheckNotConsumed;

    var eq := if aEquality = nil then TEqualityComparer<T>.Default else aEquality;

    Result := false;

    for var i := 0 to Pred(fState.List.Count - 1) do
      if Eq.Equals(fState.List[i], aValue) then
      begin
        Result := True;
        Break;
      end;

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.GroupBy<TKey>(
  const aKeySelector: TConstFunc<T, TKey>;
  const aEquality: IEqualityComparer<TKey>
): TDictionary<TKey, TList<T>>;
var
  scope: TScope;
  Bucket: TList<T>;
begin
  Ensure.IsTrue(Assigned(aKeySelector), 'KeySelector is nil')
        .IsTrue(Assigned(fState.List), 'Stream has no buffer');

  fState.CheckNotConsumed;

  var eq := if Assigned(aEquality) then aEquality else TEqualityComparer<TKey>.Default;
  var dict := scope.Owns(TDictionary<TKey, TList<T>>.Create(Eq));

  try
    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];
      var key := aKeySelector(item);

      if not dict.TryGetValue(key, bucket) then
      begin
        bucket := TList<T>.Create;
        Dict.Add(key, bucket);
      end;

      Bucket.Add(item);
    end;

    Result := scope.Release(dict);

    fState.Terminate;
  except
    for Bucket in dict.Values do
      Bucket.Free;

    fState.Terminate;

    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Partition(const aPredicate: TConstPredicate<T>): TPair<TList<T>, TList<T>>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(aPredicate), 'Predicate is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var trueList := scope.Owns(TList<T>.Create);
    var falseList := scope.Owns(TList<T>.Create);

    var cap := fState.List.Count div 2;

    trueList.Capacity  := cap;
    falseList.Capacity := cap;

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];

      if aPredicate(item) then
        trueList.Add(item)
      else
        falseList.Add(item);
    end;

    Result := TPair<TList<T>, TList<T>>.Create(scope.Release(trueList), scope.Release(falseList));

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Partition(const aSpec: ISpecification<T>): TPair<TList<T>, TList<T>>;
begin
  try
    Ensure.IsTrue(Assigned(aSpec), 'Spec is nil');

    Result := Partition(
      function(const item: T): Boolean
      begin
        Result := aSpec.IsSatisfiedBy(item);
      end
    );

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.SplitAt(const aIndex: Integer): TPair<TList<T>, TList<T>>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aIndex >= 0, 'Index must be >= 0')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var leftList := scope.Owns(TList<T>.Create);
    var rightList := scope.Owns(TList<T>.Create);

    var cut := if aIndex > fState.List.Count then fState.List.Count else aIndex;

    leftList.Capacity  := cut;
    rightList.Capacity := fState.List.Count - cut;

    for var i := 0 to Pred(Cut) do
      leftList.Add(fState.List[i]);

    for var i := Cut to Pred(fState.List.Count) do
      rightList.Add(fState.List[i]);

    Result := TPair<TList<T>, TList<T>>.Create(scope.Release(leftList), scope.Release(rightList));

  finally
    fState.Terminate;
  end;
end;


{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Distinct(const aComparer: IEqualityComparer<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  lSeen: TDictionary<T, Byte>;
  lItem: T;
  i: Integer;
  scope: TScope;
begin
  try
    fState.CheckNotConsumed;

    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := fState.List.Count;

    lSeen := scope.Owns(TDictionary<T, Byte>.Create(aComparer));
    lSeen.Capacity := fState.List.Count;

    for i := 0 to Pred(fState.List.Count) do
    begin
      lItem := fState.List[i];

      if lSeen.ContainsKey(lItem) then
      begin
        if Assigned(AOnDiscard) then
           aOnDiscard(lItem);

        continue;
      end;

      lSeen.Add(lItem, 0);
      list.Add(lItem);
    end;

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.DistinctBy<TKey>(
  const aKeySelector: TConstFunc<T, TKey>;
  const aKeyEquality: IEqualityComparer<TKey>;
  const aOnDiscard: TConstProc<T>
): TPipe<T>;
var
  scope : TScope;
begin
  try
    Ensure.IsTrue(Assigned(aKeySelector), 'KeySelector is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := fState.List.Count;

    var eq   := if aKeyEquality <> nil then aKeyEquality else TEqualityComparer<TKey>.Default;
    var seen := scope.Owns(TDictionary<TKey, Byte>.Create(eq));

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];
      var key := aKeySelector(item);

      if seen.ContainsKey(key) then
      begin
        if Assigned(AOnDiscard) then
           aOnDiscard(item);

        continue;
      end;

      seen.Add(key, 0);
      list.Add(item);
    end;

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.FlatMap<U>(const aMapper: TConstFunc<T, TList<U>>): TPipe<U>;
var
  scope : TScope;
begin
  try
    Ensure.IsTrue(Assigned(aMapper), 'Mapper is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var list := scope.Owns(TList<U>.Create);

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item  := fState.List[i];
      var inner := aMapper(item);

      if inner <> nil then
      begin
        list.AddRange(inner);
        inner.Free;
      end;
    end;

    Result := Stream.TPipe<U>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Sort(const AComparer: IComparer<T>): TPipe<T>;
var
  scope: TScope;
  lCmp: IComparer<T>;
begin
  try
    fState.CheckNotConsumed;

    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    if aComparer = nil then
      lCmp := TComparer<T>.Default
    else
      lCmp := AComparer;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count;
    list.AddRange(fState.List);
    list.Sort(lCmp);

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Reverse: TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count;

    for var i := Pred(fState.List.Count) downto 0 do
      list.Add(fState.List[i]);

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Concat(const aValues: array of T): TPipe<T>;
begin
  Result := Concat(TSource<T>.From(aValues));
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Concat(const aSource: TSource<T>): TPipe<T>;
var
  scope: TScope;
begin
  if aSource.IsEmpty then exit(Self);

  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    FState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count + aSource.Count;
    list.AddRange(fState.List);

    aSource.AppendTo(list);

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Subtract(
  const aOther: array of T;
  const aComparer: IEqualityComparer<T>;
  const aOnDiscard: TConstProc<T>
): TPipe<T>;
begin
  Result := Subtract(TSource<T>.From(aOther));
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Subtract(
  const aOther: TSource<T>;
  const aComparer: IEqualityComparer<T>;
  const aOnDiscard: TConstProc<T>
): TPipe<T>;
var
  scope: TScope;
begin
  if aOther.IsEmpty then exit(Self);

  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);
    var cmp  := TLx.Ensure<T>(aComparer);

    var excluded := scope.Owns(TDictionary<T, Byte>.Create(cmp));

    for var i := 0 to aOther.High do
    begin
      var item := aOther[i];

      if not excluded.ContainsKey(item) then
        excluded.Add(item, 0);
    end;

    list.Capacity := fState.List.Count;

    var disposing := Assigned(aOnDiscard);

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];

      if not excluded.ContainsKey(item) then
        list.Add(item)
      else if disposing then
        aOnDiscard(item);
    end;

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Intersect(
  const aItems: array of T;
  const aComparer: IEqualityComparer<T>;
  const aOnDiscard: TConstProc<T>
): TPipe<T>;
begin
  Result := Intersect(TSource<T>.From(aItems), aComparer, aOnDiscard);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Intersect(
  const aOther: TSource<T>;
  const aComparer: IEqualityComparer<T>;
  const aOnDiscard: TConstProc<T>
): TPipe<T>;
var
  scope: TScope;
begin
  if aOther.IsEmpty then
  begin
    if Assigned(aOnDiscard) then
      for var i := 0 to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    fState.SetList(TList<T>.Create);
    fState.SetOwnsList(True);

    exit(Self);
  end;

  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);
    var cmp  := TLx.Ensure<T>(aComparer);

    var included := scope.Owns(TDictionary<T, Byte>.Create(cmp));

    for var i := 0 to aOther.High do
    begin
      var item := aOther[i];

      if not included.ContainsKey(item) then
        included.Add(item, 0);
    end;

    list.Capacity := fState.List.Count;

    var disposing := Assigned(aOnDiscard);

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];

      if included.ContainsKey(item) then
        list.Add(item)
      else if disposing then
        aOnDiscard(item);
    end;

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Union(
  const aOther: array of T;
  const aComparer: IEqualityComparer<T>;
  const aOnDiscard,
  aOnDiscardOther: TConstProc<T>
): TPipe<T>;
begin
  Result := Union(TSource<T>.From(aOther), aComparer, aOnDiscard, aOnDiscardOther);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Union(
  const aOther: TSource<T>;
  const aComparer: IEqualityComparer<T>;
  const aOnDiscard,
  aOnDiscardOther: TConstProc<T>
): TPipe<T>;
var
  scope: TScope;
begin
  if aOther.IsEmpty then exit(Self);

  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);
    var cmp  := TLx.Ensure<T>(aComparer);
    var seen := scope.Owns(TDictionary<T, Byte>.Create(cmp));

    list.Capacity := fState.List.Count + aOther.Count;

    var disposing := Assigned(aOnDiscard);
    var disposingOther := Assigned(aOnDiscardOther);

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];

      if not seen.ContainsKey(item) then
      begin
        seen.Add(item, 0);
        list.Add(item);
      end
      else if disposing then
        aOnDiscard(item);
    end;

    for var i := 0 to aOther.High do
    begin
      var item := aOther[i];

      if not seen.ContainsKey(item) then
      begin
        seen.Add(item, 0);
        list.Add(item);
      end
      else if disposingOther then
        aOnDiscardOther(item);
    end;

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.SymmetricDifference(
  const aOther: array of T;
  const aComparer: IEqualityComparer<T>;
  const aOnDiscard,
  aOnDiscardOther: TConstProc<T>
): TPipe<T>;
begin
  Result := SymmetricDifference(TSource<T>.From(aOther), aComparer, aOnDiscard, aOnDiscardOther);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.SymmetricDifference(
  const aOther: TSource<T>;
  const aComparer: IEqualityComparer<T>;
  const aOnDiscard,
  aOnDiscardOther: TConstProc<T>
): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var cmp  := TLx.Ensure<T>(aComparer);
    var list := scope.Owns(TList<T>.Create);

    var seenStream := scope.Owns(TDictionary<T, Byte>.Create(cmp));
    var seenOther  := scope.Owns(TDictionary<T, Byte>.Create(cmp));
    var seenList   := scope.Owns(TDictionary<T, Byte>.Create(cmp));

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];

      if not seenStream.ContainsKey(item) then
        seenStream.Add(item, 0);
    end;

    for var i := 0 to aOther.High do
    begin
      var item := aOther[i];

      if not seenOther.ContainsKey(item) then
        seenOther.Add(item, 0);
    end;

    list.Capacity := seenStream.Count + seenOther.Count;

    var disposing := Assigned(aOnDiscard);
    var disposingOther := Assigned(aOnDiscardOther);

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];

      if seenOther.ContainsKey(item) then
      begin
        if disposing then
          aOnDiscard(item);
      end
      else
      begin
        if not seenList.ContainsKey(item) then
        begin
          list.Add(item);
          seenList.Add(item, 0);
        end;
      end;
    end;

    for var i := 0 to aOther.High do
    begin
      var item := aOther[i];

      if seenStream.ContainsKey(item) then
      begin
        if disposingOther then
          aOnDiscardOther(item);
      end
      else
      begin
        if not seenList.ContainsKey(item) then
        begin
          list.Add(item);
          seenList.Add(item, 0);
        end;
      end;
    end;

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Filter(const aSpec: ISpecification<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
begin
  try
    Ensure.IsTrue(Assigned(aSpec), 'Spec is nil');

    Result := Filter(
      function(const item: T): Boolean
      begin
        Result := aSpec.IsSatisfiedBy(item);
      end,
      aOnDiscard);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Filter(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(aPredicate), 'Predicate is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := fState.List.Count;

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];

      if aPredicate(item) then
        list.Add(item)
      else if Assigned(aOnDiscard) then
        aOnDiscard(item);
    end;

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Map<U>(const aMapper: TConstFunc<T, U>; const aOnDiscard: TConstProc<T>): TPipe<U>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(aMapper), 'Mapper is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var list := scope.Owns(TList<U>.Create);
    list.Capacity := fState.List.Count;

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];
      list.Add(aMapper(item));

      if Assigned(aOnDiscard) then
        aOnDiscard(item);
    end;

    Result := Stream.TPipe<U>.CreatePipe(scope.Release(list), true);
  finally
    fState.Terminate;
  end;
end;
{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Map(const aMapper: TConstFunc<T, T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(aMapper), 'Mapper is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := fState.List.Count;

    for var i := 0 to Pred(fState.List.Count) do
    begin
      var item := fState.List[i];
      list.Add(aMapper(item));

      if Assigned(aOnDiscard) then
        aOnDiscard(item);
    end;

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);
  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Take(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aCount >= 0, 'Count must be >= 0')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    FState.CheckNotConsumed;

    var lCount := if aCount > fState.List.Count then fState.List.Count else aCount;

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := lCount;

    for var i := 0 to Pred(lCount) do
      list.Add(fState.List[i]);

    if Assigned(aOnDiscard) then
      for var i := lCount to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TakeWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(aPredicate), 'Predicate is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var lCount := 0;

    while (lCount < fState.List.Count) and aPredicate(fState.List[lCount]) do
      Inc(lCount);

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := lCount;

    for var i := 0 to Pred(lCount) do
      list.Add(fState.List[i]);

    if Assigned(aOnDiscard) then
      for var i := lCount to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TakeUntil(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(aPredicate), 'Predicate is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var lCount := 0;

    while (lCount < fState.List.Count) and not aPredicate(fState.List[lCount]) do
      Inc(lCount);

    if lCount = fState.List.Count then exit(Self);

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := lCount;

    for var i := 0 to Pred(lCount) do
      list.Add(fState.List[i]);

    if Assigned(aOnDiscard) then
      for var i := lCount to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TakeLast(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aCount >= 0, 'Count must be >= 0')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var lCount := if aCount > fState.List.Count then fState.List.Count else aCount;

    var startIdx := fState.List.Count - lCount;
    var list := scope.Owns(TList<T>.Create);

    list.Capacity := lCount;

    if Assigned(aOnDiscard) then
      for var i := 0 to Pred(startIdx) do
        aOnDiscard(fState.List[i]);

    for var i := startIdx to Pred(fState.List.Count) do
      list.Add(fState.List[i]);

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Skip(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aCount >= 0, 'Count must be >= 0')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var lCount := if aCount > fState.List.Count then fState.List.Count else aCount;

    var startIdx := lCount;
    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count - startIdx;

    if Assigned(aOnDiscard) then
      for var i := 0 to Pred(startIdx) do
        aOnDiscard(fState.List[I]);

    for var i := startIdx to Pred(fState.List.Count) do
      list.Add(fState.List[I]);

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.SkipWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(aPredicate), 'Predicate is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var startIdx := 0;

    while (startIdx < fState.List.Count) and aPredicate(fState.List[startIdx]) do
    begin
      if Assigned(aOnDiscard) then
        aOnDiscard(fState.List[startIdx]);

      Inc(startIdx);
    end;

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := fState.List.Count - startIdx;

    for var i := startIdx to Pred(fState.List.Count) do
      list.Add(fState.List[i]);

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.SkipLast(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aCount >= 0, 'Count must be >= 0')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var dropCount := if aCount > fState.List.Count then fState.List.Count else aCount;
    var keepCount := fState.List.Count - DropCount;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := keepCount;

    for var i := 0 to Pred(KeepCount) do
      list.Add(fState.List[i]);

    if Assigned(aOnDiscard) then
      for var i := KeepCount to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.SkipUntil(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(aPredicate), 'Predicate is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var source  := fState.List;
    var results := scope.Owns(TList<T>.Create);

    var cnt := source.Count;
    var hi  := source.Count - 1;

    var startIdx := cnt;

    for var i := 0 to hi do
      if aPredicate(source[i]) then
      begin
        startIdx := i;
        Break;
      end;

    if Assigned(aOnDiscard) then
      for var i := 0 to Pred(startIdx) do
        aOnDiscard(source[i]);

    if startIdx < cnt then
    begin
      results.Capacity := cnt - startIdx;

      for var i := startIdx to hi do
        results.Add(source[i]);
    end;

    Result := Stream.TPipe<T>.CreatePipe(scope.Release(results), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Peek(const aAction: TConstProc<Integer, T>): TPipe<T>;
begin
  try
    Ensure.IsTrue(Assigned(aAction), 'Action is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    for var i := 0 to Pred(fState.List.Count) do
      aAction(i, fState.List[i]);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Zip<T2, TResult>(
  const aOther: TSource<T2>;
  const aZipper: TConstFunc<Integer, T, T2, TResult>;
  const aOnDiscard: TConstProc<T>;
  const aOnDiscardOther: TConstProc<T2>
): TPipe<TResult>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(Assigned(aZipper), 'Zipper is nil')
          .IsTrue(Assigned(fState.List), 'Stream has no buffer');

    fState.CheckNotConsumed;

    var n := if aOther.Count < fState.List.Count then aOther.Count else fState.List.Count;

    var list := scope.Owns(TList<TResult>.Create);
    list.Capacity := n;

    for var i := 0 to Pred(N) do
      list.Add(aZipper(i, fState.List[i], aOther[i]));

    if Assigned(aOnDiscard) then
      for var i := n to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    if Assigned(aOnDiscardOther) then
      for var i := n to Pred(aOther.Count) do
        aOnDiscardOther(aOther[I]);

    Result := Stream.TPipe<TResult>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Zip<T2, TResult>(
  const aOther: array of T2;
  const aZipper: TConstFunc<Integer, T, T2, TResult>;
  const aOnDiscard: TConstProc<T>;
  const aOnDiscardOther: TConstProc<T2>
): TPipe<TResult>;
begin
  Result := Zip<T2, TResult>(TSource<T2>.From(aOther), aZipper, aOnDiscard, aOnDiscardOther);
end;

{ Stream factories }

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.Consume<T>(const aList: TList<T>): TPipe<T>;
begin
  Ensure.IsTrue(Assigned(aList), 'List is nil');

  Result := TPipe<T>.CreatePipe(aList, true);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(const aList: TList<T>): TPipe<T>;
begin
  Ensure.IsTrue(Assigned(aList), 'List is nil');

  Result := TPipe<T>.CreatePipe(aList, false);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(const aSource: TSource<T>): TPipe<T>;
begin
  var list := TList<T>.Create(aSource.fItems);

  Result := TPipe<T>.CreatePipe(list, true);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(const aValues: array of T): TPipe<T>;
begin
  var list := TList<T>.Create(aValues);

  Result := TPipe<T>.CreatePipe(list, true);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.Consume<T>(aEnum: TEnumerator<T>): TPipe<T>;
begin
  Ensure.IsTrue(Assigned(aEnum), 'Enum is nil');

  var list := TList<T>.Create;

  while aEnum.MoveNext do
    list.Add(aEnum.Current);

  Result := TPipe<T>.CreatePipe(list, true);

  aEnum.Free;
end;

{ TSpecification<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TSpecification<T>.AndAlso(const aOther: ISpecification<T>): ISpecification<T>;
begin
  Ensure.IsTrue(Assigned(aOther), 'Other specification is nil');
  Result := TAndSpecification<T>.Create(ISpecification<T>(Self), aOther);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSpecification<T>.OrElse(const aOther: ISpecification<T>): ISpecification<T>;
begin
  Ensure.IsTrue(Assigned(aOther), 'Other specification is nil');
  Result := TOrSpecification<T>.Create(ISpecification<T>(Self), aOther);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSpecification<T>.NotThis: ISpecification<T>;
begin
  Result := TNotSpecification<T>.Create(ISpecification<T>(Self));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TSpecification<T>.FromPredicate(const aPredicate: TConstPredicate<T>): ISpecification<T>;
begin
  Ensure.IsTrue(Assigned(aPredicate), 'Predicate is nil');

  Result := TPredicateSpecification<T>.Create(APredicate);
end;

{ TAndSpecification<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TAndSpecification<T>.Create(const aLeft, aRight: ISpecification<T>);
begin
  inherited Create;

  Ensure.IsTrue(Assigned(aLeft),  'Left specification is nil')
        .IsTrue(Assigned(aRight), 'Right specification is nil');

  fLeft  := aLeft;
  fRight := aRight;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TAndSpecification<T>.Left: ISpecification<T>;
begin
  Result := fLeft;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TAndSpecification<T>.Right: ISpecification<T>;
begin
  Result := fRight;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TAndSpecification<T>.IsSatisfiedBy(const aCandidate: T): Boolean;
begin
  Result := fLeft.IsSatisfiedBy(aCandidate) and fRight.IsSatisfiedBy(aCandidate);
end;

{ TOrSpecification<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TOrSpecification<T>.Create(const aLeft, aRight: ISpecification<T>);
begin
  inherited Create;

  Ensure.IsTrue(Assigned(aLeft), 'Left specification is nil')
        .IsTrue(Assigned(aRight), 'Right specification is nil');

  fLeft  := aLeft;
  fRight := aRight;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOrSpecification<T>.Left: ISpecification<T>;
begin
  Result := fLeft;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOrSpecification<T>.Right: ISpecification<T>;
begin
  Result := fRight;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TOrSpecification<T>.IsSatisfiedBy(const aCandidate: T): Boolean;
begin
  Result := fLeft.IsSatisfiedBy(aCandidate) or fRight.IsSatisfiedBy(aCandidate);
end;

{ TNotSpecification<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TNotSpecification<T>.Create(const aInner: ISpecification<T>);
begin
  inherited Create;

  Ensure.IsTrue(Assigned(aInner), 'Inner specification is nil');

  fInner := aInner;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TNotSpecification<T>.Inner: ISpecification<T>;
begin
  Result := fInner;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TNotSpecification<T>.IsSatisfiedBy(const aCandidate: T): Boolean;
begin
  Result := not fInner.IsSatisfiedBy(aCandidate);
end;

{ TPredicateSpecification<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TPredicateSpecification<T>.Create(const aPredicate: TConstPredicate<T>);
begin
  inherited Create;

  Ensure.IsTrue(Assigned(aPredicate), 'Predicate is nil');

  fPredicate := aPredicate;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TPredicateSpecification<T>.IsSatisfiedBy(const aCandidate: T): Boolean;
begin
  Result := fPredicate(aCandidate);
end;

{ TSource<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TSource<T>.GetItem(const aIndex: Integer): T;
const
  ERR = 'Index out of range error';
begin
  Ensure.IsGreater(-1, aIndex, ERR)
        .IsLess(fCount, aIndex, ERR);

  Result := fItems[aIndex];
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TSource<T>.Implicit(const aArray: TArray<T>): TSource<T>;
begin
  Result.fItems := Copy(aArray);
  Result.fCount := Length(aArray);
  Result.fHigh  := Result.fCount - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TSource<T>.Implicit(const aEnum: TEnumerator<T>): TSource<T>;
var
  scope: TScope;
begin
  Result.fCount := 0;

  if aEnum <> nil then
  begin
    scope.Owns(aEnum);

    var list := scope.Owns(TList<T>.Create);

    while aEnum.MoveNext do
      list.Add(aEnum.Current);

    Result.fItems := list.ToArray;
    Result.fCount := list.Count;
  end;

  Result.fHigh := Result.fCount - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TSource<T>.Implicit(const aSeq: TSequence<T>): TSource<T>;
begin
  Result.fItems := aSeq.ToArray;
  Result.fCount := aSeq.Count;
  Result.fHigh  := aSeq.Count - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TSource<T>.Implicit(const aList: TList<T>): TSource<T>;
begin
  Result.fItems := aList.ToArray;
  Result.fCount := aList.Count;
  Result.fHigh  := aList.Count - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TSource<T>.Implicit(const aSegment: TSegment<T>): TSource<T>;
begin
  var seq := aSegment.ToSequence;

  Result.fItems := seq.ToArray;
  Result.fCount := Seq.Count;
  Result.fHigh  := Seq.Count - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TSource<T>.Implicit(const aSlice: TSlice<T>): TSource<T>;
begin
  var seq := aSlice.ToSequence;

  Result.fItems := seq.ToArray;
  Result.fCount := Seq.Count;
  Result.fHigh  := Seq.Count - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TSource<T>.Implicit(const aEnum: TEnumerable<T>): TSource<T>;
begin
  Result.fCount := 0;

  if aEnum <> nil then
  begin
    Result.fItems := aEnum.ToArray;
    Result.fCount := Length(Result.fItems);
  end;

  Result.fHigh := Result.fCount - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSource<T>.IsEmpty: boolean;
begin
  Result := fCount = 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSource<T>.AppendTo(const aList: TList<T>);
begin
  for var i := 0 to fHigh do
    aList.Add(fItems[i]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSource<T>.GetEnumerator: TSourceEnumerator<T>;
begin
  Result := TSourceEnumerator<T>.Create(fItems, fCount);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSource<T>.AsArray: TArray<T>;
begin
  Result := Copy(fItems);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSource<T>.AsList: TList<T>;
begin
  Result := TList<T>.Create;

  for var i := 0 to fHigh do
    Result.Add(fItems[i]);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TSource<T>.Consume(const aList: TList<T>): TSource<T>;
var
  scope: TScope;
begin
  Result.fCount := 0;

  if aList <> nil then
  begin
    scope.Owns(aList);

    Result.fItems := aList.ToArray;
    Result.fCount := aList.Count;
  end;

  Result.fHigh  := Result.fCount - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TSource<T>.From(const aItems: array of T): TSource<T>;
begin
  Result.fCount := 0;
  Result.fHigh  := -1;

  var len := Length(aItems);

  if len = 0 then exit;

  SetLength(Result.fItems, len);

  var hi := len - 1;

  for var i := 0 to hi do
    Result.fItems[i] := aItems[i];

  Result.fCount := len;
  Result.fHigh  := hi;
end;

{ TSourceEnumerator<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TSourceEnumerator<T>.Create(const [ref] aSource: TArray<T>; const aCount: integer);
begin
  fSource := aSource;
  fPos    := -1;
  fCount  := aCount;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSourceEnumerator<T>.GetCurrent: T;
begin
  Result :=  fSource[fPos];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSourceEnumerator<T>.MoveNext: boolean;
begin
  Inc(fPos);
  Result := fPos < fCount;
end;

{ TSegmentEnumerator<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TSegmentEnumerator<T>.Create(const aSource: TList<T>; const aLowIndex, aCount: integer);
begin
  fSource := aSource;
  fPos    := aLowIndex - 1;
  fHigh   := aLowIndex + aCount - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSegmentEnumerator<T>.GetCurrent: T;
begin
  Result := fSource[fPos];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSegmentEnumerator<T>.MoveNext: boolean;
begin
  Inc(fPos);
  Result := (fPos <= fHigh) and (fPos < fSource.Count);
end;

{ TSegment<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TSegment<T>.ContainsIndex(const aIndex: integer): boolean;
begin
  Result := (aIndex >= 0) and (aIndex < Count);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TSegment<T>.From(const aSource: TList<T>; const aLow, aHigh: integer): TSegment<T>;
begin
  Ensure.IsTrue(aSource <> nil, 'Source list is nil error')
        .IsGreaterOrEqual(0, aLow, 'Low index is out of range')
        .IsLessOrEqual(aHigh, aLow, 'Low index must be less or equal to high index.');

  Result.fSource := aSource;
  Result.fLow    := aLow;
  Result.fHigh   := aHigh;
  Result.fLength := aHigh - aLow + 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSegment<T>.GetCount: integer;
begin
  var realHigh := fSource.Count - 1;

  if realHigh > fHigh then
    realHigh := fHigh;

  if realHigh < fLow then exit(0);

  Result := realHigh - fLow + 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSegment<T>.GetIsEmpty: boolean;
begin
  Result := Count = 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSegment<T>.GetItem(const aIndex: integer): T;
const
  ERR = 'index is out of range (%d), segment count is %d.';
begin
  var n := Count;

  Ensure.IsGreaterOrEqual(0, aIndex, Format(ERR, [aIndex, n]))
        .IsLess(n, aIndex, Format(ERR, [aIndex, n]));

  var idx := fLow + aIndex;

  Result := fSource[idx];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSegment<T>.ItemAt(const aIndex: integer): TOption<T>;
begin
  if (aIndex >= 0) and (aIndex < Count) then
  begin
    var idx := fLow + aIndex;
    Result.SetSome(fSource[idx]);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSegment<T>.GetEnumerator: TSegmentEnumerator<T>;
begin
  Result := TSegmentEnumerator<T>.Create(fSource, fLow, Count);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSegment<T>.ToSequence;
begin
  Result := TSequence<T>.From(fSource, fLow, fLow + Count - 1)
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSegment<T>.ToSubSegment(const aLow, aHigh: integer): TSegment<T>;
begin
  Ensure.IsGreater(-1, aLow)
        .IsLessOrEqual(aHigh, aLow)
        .IsLess(fLength, aHigh);

  Result := TSegment<T>.From(fSource, fLow + aLow, fLow + aHigh);
end;

{ TSliceEnumerator<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TSliceEnumerator<T>.Create(const aSource: TList<T>; const aLowIndex, aCount: integer);
begin
  fSource := aSource;
  fPos    := aLowIndex - 1;
  fHigh   := aLowIndex + aCount - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSliceEnumerator<T>.GetCurrent: T;
begin
  Result := fSource[fPos];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSliceEnumerator<T>.MoveNext: boolean;
begin
  Inc(fPos);
  Result := (fPos <= fHigh) and (fPos < fSource.Count);
end;

{ TSegment<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.ContainsIndex(const aIndex: integer): boolean;
begin
  Result := (aIndex >= 0) and (aIndex < Count);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TSlice<T>.From(const aSource: TList<T>; const aLow, aHigh: integer): TSlice<T>;
begin
  Ensure.IsTrue(aSource <> nil, 'Source list is nil error')
        .IsGreaterOrEqual(0, aLow, 'Low index is out of range')
        .IsLessOrEqual(aHigh, aLow, 'Low index must be less or equal to high index.');

  Result.fSource := aSource;
  Result.fLow    := aLow;
  Result.fHigh   := aHigh;
  Result.fLength := aHigh - aLow + 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.GetCount: integer;
begin
  var realHigh := fSource.Count - 1;

  if realHigh > fHigh then
    realHigh := fHigh;

  if realHigh < fLow then exit(0);

  Result := realHigh - fLow + 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.GetIsEmpty: boolean;
begin
  Result := Count = 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.GetItem(const aIndex: integer): T;
const
  ERR = 'index is out of range (%d), segment count is %d.';
begin
  var n := Count;

  var msg := Format(ERR, [aIndex, n]);

  Ensure.IsGreaterOrEqual(0, aIndex, msg)
        .IsLess(n, aIndex, msg);

  var idx := fLow + aIndex;

  Result := fSource[idx];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.ItemAt(const aIndex: integer): TOption<T>;
begin
  if (aIndex >= 0) and (aIndex < Count) then
  begin
    var idx := fLow + aIndex;
    Result.SetSome(fSource[idx]);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.TryPut(const aIndex: integer; const aValue: T): boolean;
begin
  Result := false;

  var n := Count;

  if (aIndex >= 0) and (aIndex < n) then
  begin
    var idx := fLow + aIndex;
    fSource[idx] := aValue;

    Result := true;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSlice<T>.SetItem(const aIndex: integer; const aValue: T);
const
  ERR = 'index is out of range (%d), slice count is %d.';
begin
  var n := Count;

  var msg := Format(ERR, [aIndex, n]);

  Ensure.IsGreaterOrEqual(0, aIndex, msg)
        .IsLess(n, aIndex, msg);

  var idx := fLow + aIndex;

  fSource[idx] := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.Fill(const aValue: T): Integer;
begin
  Result := Count;

  for var i := 0 to Pred(Result) do
    fSource[fLow + i] := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.Reset: Integer;
begin
  Result := Fill(Default(T));
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.Reverse: Integer;
begin
  Result := Count;

  var i := 0;
  var j := Result - 1;

  while i < j do
  begin
    var li := fLow + i;
    var rj := fLow + j;

    var tmp := fSource[li];

    fSource[li] := fSource[rj];
    fSource[rj] := tmp;

    Inc(i);
    Dec(j);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.Sort(const aComparer: IComparer<T> = nil): Integer;
begin
  Result := Count;

  if Result <= 1 then
    Exit;

  var cmp := TLx.Ensure<T>(aComparer);

  TArray.Sort<T>(fSource.List, cmp, fLow, Result);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.TrySwap(const aLeft, aRight: Integer): Boolean;
begin
  var n := Count;

  Result := (aLeft >= 0) and (aLeft < n) and (aRight >= 0) and (aRight < n);

  if not Result then exit;

  var li := fLow + aLeft;
  var ri := fLow + aRight;

  var tmp := fSource[li];

  fSource[li] := fSource[ri];
  fSource[ri] := tmp;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.GetEnumerator: TSliceEnumerator<T>;
begin
  Result := TSliceEnumerator<T>.Create(fSource, fLow, Count);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.ToSequence;
begin
  Result := TSequence<T>.From(fSource, fLow, fLow + Count - 1)
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.ToSegment: TSegment<T>;
begin
  Result := TSegment<T>.From(fSource, fLow, fHigh);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.ToSubSegment(const aLow, aHigh: integer): TSegment<T>;
begin
  Ensure.IsGreater(-1, aLow)
        .IsLessOrEqual(aHigh, aLow)
        .IsLess(fLength, aHigh);

  Result := TSegment<T>.From(fSource, fLow + aLow, fLow + aHigh);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSlice<T>.ToSubSlice(const aLow, aHigh: integer): TSlice<T>;
begin
  Ensure.IsGreater(-1, aLow)
        .IsLessOrEqual(aHigh, aLow)
        .IsLess(fLength, aHigh);

  Result := TSlice<T>.From(fSource, fLow + aLow, fLow + aHigh);
end;

{ TItemsEnumerator<T> }

{----------------------------------------------------------------------------------------------------------------------}
constructor TItemsEnumerator<T>.Create(const [ref] aSource: TArray<T>; const aCount: integer);
begin
  fSource := aSource;
  fPos    := -1;
  fCount  := aCount;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TItemsEnumerator<T>.GetCurrent: T;
begin
  Result :=  fSource[fPos];
end;

{----------------------------------------------------------------------------------------------------------------------}
function TItemsEnumerator<T>.MoveNext: boolean;
begin
  Inc(fPos);
  Result := fPos < fCount;
end;

{ TItems<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TItems<T>.GetItem(const aIndex: Integer): T;
const
  ERR = 'Index out of range error';
begin
  Ensure.IsGreater(-1, aIndex, ERR)
        .IsLess(fCount, aIndex, ERR);

  Result := fItems[aIndex];
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TItems<T>.Implicit(const aArray: TArray<T>): TItems<T>;
begin
  Result.fItems := Copy(aArray);
  Result.fCount := Length(aArray);
  Result.fHigh  := Result.fCount - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TItems<T>.Implicit(const aEnum: TEnumerator<T>): TItems<T>;
var
  scope: TScope;
begin
  Result.fCount := 0;

  if aEnum <> nil then
  begin
    scope.Owns(aEnum);

    var list := scope.Owns(TList<T>.Create);

    while aEnum.MoveNext do
      list.Add(aEnum.Current);

    Result.fItems := list.ToArray;
    Result.fCount := list.Count;
  end;

  Result.fHigh := Result.fCount - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TItems<T>.Implicit(const aEnum: TEnumerable<T>): TItems<T>;
begin
  Result.fCount := 0;

  if aEnum <> nil then
  begin
    Result.fItems := aEnum.ToArray;
    Result.fCount := Length(Result.fItems);
  end;

  Result.fHigh := Result.fCount - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TItems<T>.Implicit(const aList: TList<T>): TItems<T>;
begin
  Result.fCount := 0;

  if Assigned(aList) then
  begin
    Result.fItems := aList.ToArray;
    Result.fCount := aList.Count;
  end;

  Result.fHigh := Result.fCount - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TItems<T>.IsEmpty: boolean;
begin
  Result := fCount = 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TItems<T>.AppendTo(const aList: TList<T>);
begin
  for var i := 0 to fHigh do
    aList.Add(fItems[i]);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TItems<T>.GetEnumerator: TItemsEnumerator<T>;
begin
  Result := TItemsEnumerator<T>.Create(fItems, fCount);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TItems<T>.AsArray: TArray<T>;
begin
  Result := Copy(fItems);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TItems<T>.AsList: TList<T>;
begin
  Result := TList<T>.Create;

  for var i := 0 to fHigh do
    Result.Add(fItems[i]);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TItems<T>.Consume(const aList: TList<T>): TItems<T>;
var
  scope: TScope;
begin
  Result.fCount := 0;

  if aList <> nil then
  begin
    scope.Owns(aList);

    Result.fItems := aList.ToArray;
    Result.fCount := aList.Count;
  end;

  Result.fHigh := Result.fCount - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TItems<T>.From(const aItems: array of T): TItems<T>;
begin
  Result.fCount := 0;
  Result.fHigh  := -1;

  var len := Length(aItems);

  if len = 0 then exit;

  SetLength(Result.fItems, len);

  var hi := len - 1;

  for var i := 0 to hi do
    Result.fItems[i] := aItems[i];

  Result.fCount := len;
  Result.fHigh  := hi;
end;

{ TIndex<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TIndex<T>.GetItem(const aIndex: Integer): T;
const
  INDEX_ERR     = 'Index out of range error';
  NO_SOURCE_ERR = 'Unknown source error';
begin
  Ensure.IsTrue((aIndex >= 0) and (aIndex <= fHigh), INDEX_ERR)
        .IsTrue(fType in [isArray, isList], NO_SOURCE_ERR);

  case fType of
    isArray: Result := fArray[aIndex];
    isList:  Result := fList[aIndex];
  else
    // keep compiler happy - unreachable code.
    Result := default(T);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TIndex<T>.IsEmpty: boolean;
begin
  Result := fCount = 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TIndex<T>.AppendTo(const aList: TList<T>): Integer;
begin
  Ensure.IsTrue(aList <> nil, 'Unable to append items into an unassigned list');

  for var i := 0 to fHigh do
    aList.Add(Self[i]);

  Result := fCount;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TIndex<T>.ToArray: TArray<T>;
begin
  case fType of
    isNone:  Result := nil;
    isArray: Result := Copy(fArray, 0, fCount);
    isList:
      begin
        Result := fList.ToArray;
        SetLength(Result, fCount);
      end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TIndex<T>.ToList: TList<T>;
begin
  Result := nil;

  case fType of
    isNone:  Result := TList<T>.Create;
    isArray: Result := TList<T>.Create(Copy(fArray, 0, fCount));
    isList:
      begin
        Result := TList<T>.Create;
        Result.Capacity := fCount;

        for var i := 0 to fHigh do
          Result.Add(fList[i]);
      end;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TIndex<T>.ToSequence: TSequence<T>;
begin
  case fType of
    isNone:  Result := TSequence<T>.From([]);
    isArray: Result := TSequence<T>.From(fArray, 0, fHigh);
    isList:  Result := TSequence<T>.From(fList, 0, fHigh);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TIndex<T>.Implicit(const aEnum: TEnumerator<T>): TIndex<T>;
var
  scope: TScope;
begin
  Result.fCount := 0;
  Result.fHigh  := -1;
  Result.fType  := isNone;

  if aEnum = nil then exit;

  scope.Owns(aEnum);

  var list := scope.Owns(TList<T>.Create);

  while aEnum.MoveNext do
    list.Add(aEnum.Current);

  Result.fArray := list.ToArray;
  Result.fCount := list.Count;
  Result.fHigh  := list.Count - 1;
  Result.fType  := isArray;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TIndex<T>.Implicit(const aArray: TArray<T>): TIndex<T>;
begin
  Result.fCount := 0;
  Result.fHigh  := -1;
  Result.fType  := isNone;

  var len := Length(aArray);

  if len = 0 then exit;

  Result.fArray := aArray;
  Result.fCount := len;
  Result.fHigh  := len - 1;
  Result.fType  := isArray;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TIndex<T>.Implicit(const aList: TList<T>): TIndex<T>;
begin
  Result.fCount := 0;
  Result.fHigh  := -1;
  Result.fType  := isNone;

  if (aList = nil) or (aList.Count = 0) then exit;

  Result.fList  := aList;
  Result.fCount := aList.Count;
  Result.fHigh  := aList.Count - 1;
  Result.fType  := isList;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TIndex<T>.Implicit(const aEnum: TEnumerable<T>): TIndex<T>;
begin
  Result.fCount := 0;
  Result.fHigh  := -1;
  Result.fType  := isNone;

  if aEnum = nil then exit;

  Result.fArray := aEnum.ToArray;
  Result.fCount := Length(Result.fArray);
  Result.fHigh  := Result.fCount - 1;
  Result.fType  := isArray;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TIndex<T>.Implicit(const aSegment: TSegment<T>): TIndex<T>;
begin
  var seq := aSegment.ToSequence;

  Result.fArray := Copy(seq.fItems);
  Result.fCount := Seq.Count;
  Result.fHigh  := Seq.Count - 1;
  Result.fType  := isArray;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TIndex<T>.Implicit(const aSlice: TSlice<T>): TIndex<T>;
begin
  var seq := aSlice.ToSequence;

  Result.fArray := Copy(seq.fItems);
  Result.fCount := Seq.Count;
  Result.fHigh  := Seq.Count - 1;
  Result.fType  := isArray;
end;

{----------------------------------------------------------------------------------------------------------------------}
class operator TIndex<T>.Implicit(const aSeq: TSequence<T>): TIndex<T>;
begin
  Result.fArray := Copy(aSeq.fItems);
  Result.fCount := aSeq.Count;
  Result.fHigh  := aSeq.Count - 1;
  Result.fType  := isArray;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TIndex<T>.From(const aItems: array of T): TIndex<T>;
begin
  Result.fCount := 0;
  Result.fHigh  := -1;
  Result.fType  := isNone;

  var len := Length(aItems);

  if len = 0 then exit;

  SetLength(Result.fArray, len);

  var hi := len - 1;

  for var i := 0 to hi do
    Result.fArray[i] := aItems[i];

  Result.fCount := len;
  Result.fHigh  := hi;
  Result.fType  := isArray;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function TIndex<T>.Consume(const aList: TList<T>): TIndex<T>;
var
  scope: TScope;
begin
  Result.fCount := 0;
  Result.fHigh  := -1;
  Result.fType  := isNone;

  if aList = nil then exit;

  scope.Owns(aList);

  Result.fArray := aList.ToArray;
  Result.fCount := aList.Count;

  Result.fHigh := Result.fCount - 1;
end;

{ TPin<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TPin<T>.GetItem: T;
begin
  Result := fSource[fIndex];
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TPin<T>.SetItem(const aValue: T);
begin
  fSource[fIndex] := aValue;
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TPin<T>.Create(const aSource: TList<T>; const aIndex: integer);
const
  NO_SOURCE = 'Source list is nil error.';
  NO_ITEM   = 'Index is out of range error.';
begin
  Ensure.IsTrue(aSource <> nil, NO_SOURCE)
        .IsLess(aSource.Count, aIndex, NO_ITEM);

  fSource := aSource;
  fIndex  := aIndex;
end;

{ TSelection<T> }

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.GetCount: integer;
begin
  Result := fPins.Count;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.GetHigh: integer;
begin
  Result := fPins.Count - 1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.GetIsEmpty: boolean;
begin
  Result := fPins.Count = 0;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.GetItem(const aIndex: integer): T;
begin
  ValidateIndex(aIndex);

  Result := fPins[aIndex].GetItem;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelection<T>.SetItem(const aIndex: integer; const aValue: T);
begin
  ValidateIndex(aIndex);

  fPins[aIndex].SetItem(aValue);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.ItemAt(const aIndex: integer): TOption<T>;
begin
  if (aIndex >= 0) and (aIndex < fPins.Count) then
    Result.SetSome(fPins[aIndex].GetItem);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.GetEnumerator: TEnumerator<TPin<T>>;
begin
  Result := fPins.GetEnumerator;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.ToArray: TArray<T>;
begin
  SetLength(Result, fPins.Count);

  for var i := 0 to Pred(fPins.Count) do
    Result[i] := fPins[i].GetItem;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.ToList: TList<T>;
begin
  Result := TList<T>.Create;
  Result.Capacity := fPins.Count;

  for var i := 0 to Pred(fPins.Count) do
    Result.Add(fPins[i].GetItem);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.ToSequence: TSequence<T>;
var
  scope: TScope;
begin
  var list := Scope.Owns(TList<T>.Create);

  for var i := 0 to Pred(fPins.Count) do
    list.Add(fPins[i].GetItem);

  Result := TSequence<T>.From(list);
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.TryPut(const aIndex: integer; const aValue: T): boolean;
begin
  if (aIndex < 0) or (aIndex >= fPins.Count) then exit(false);

  fPins[aIndex].SetItem(aValue);

  Result := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelection<T>.Add(const aSource: TList<T>; const aIndex: integer);
begin
  fPins.Add(TPin<T>.Create(aSource, aIndex));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelection<T>.Remove(const aIndex: integer);
begin
  ValidateIndex(aIndex);

  fPins.ExtractAt(aIndex).Free;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelection<T>.ValidateIndex(const aIndex: integer);
const
  NO_ITEM   = 'Index is out of range error.';
begin
  Ensure.IsTrue((aIndex >= 0) and (aIndex <= Pred(fPins.Count)), NO_ITEM);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelection<T>.Clear;
begin
  for var i := 0 to Pred(fPins.Count) do
    fPins[i].Free;

 fPins.Clear;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.All(const aValue: T): boolean;
begin
  for var i := 0 to Pred(fPins.Count) do
    if not fComparer.Equals(aValue, fPins[i].GetItem) then exit(false);

  Result := true;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.Any(const aValue: T): boolean;
begin
  for var i := 0 to Pred(fPins.Count) do
    if fComparer.Equals(aValue, fPins[i].GetItem) then exit(true);

  Result := false;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.IndexOf(const aValue: T; const aStartIndex: integer): integer;
begin
  for var i := aStartIndex to Pred(fPins.Count) do
    if fComparer.Equals(aValue, fPins[i].GetItem) then exit(i);

  Result := -1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.LastIndexOf(const aValue: T): integer;
begin
  for var i := Pred(fPins.Count) downto 0 do
    if fComparer.Equals(aValue, fPins[i].GetItem) then exit(i);

  Result := -1;
end;

{----------------------------------------------------------------------------------------------------------------------}
function TSelection<T>.CountOf(const aValue: T): integer;
begin
  Result := 0;

  for var i := 0 to Pred(fPins.Count) do
    if fComparer.Equals(aValue, fPins[i].GetItem) then Inc(Result);
end;

{----------------------------------------------------------------------------------------------------------------------}
constructor TSelection<T>.Create(const aComparer: IEqualityComparer<T> = nil);
begin
  fComparer := TLx.Ensure<T>(aComparer);
  fPins := TList<TPin<T>>.Create;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TSelection<T>.Destroy;
begin
  if fPins <> nil then
  begin
    Clear;
    fPins.Free;
  end;

  inherited;
end;

end.
