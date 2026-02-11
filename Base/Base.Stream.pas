{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Stream
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Provides an eager, declarative stream abstraction for processing collections.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Stream;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Base.Core,
  Base.Specifications;

type
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
        procedure SetList(const Value: TList<T>);
        function GetOwnsList: Boolean;
        procedure SetOwnsList(Value: Boolean);
        function GetConsumed: Boolean;
        procedure SetConsumed(Value: Boolean);
        procedure CheckNotConsumed;
        procedure CheckDisposable(const aOnDiscard: TConstProc<T>);
        procedure Terminate;
        property List: TList<T> read GetList write SetList;
      end;

      TState = class(TInterfacedObject, IState)
      private
        fList: TList<T>;
        fOwnsList: Boolean;
        fConsumed: Boolean;
      public
        constructor Create(AList: TList<T>; AOwnsList: Boolean);

        function GetList: TList<T>;
        procedure SetList(const aValue: TList<T>);
        function GetOwnsList: Boolean;
        procedure SetOwnsList(aValue: Boolean);
        function GetConsumed: Boolean;
        procedure SetConsumed(aValue: Boolean);
        procedure CheckNotConsumed;
        procedure CheckDisposable(const aOnDiscard: TConstProc<T>);
        procedure Terminate;
        property List: TList<T> read GetList write SetList;
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
      /// <remarks>
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each discarded item.
      ///  <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its buffer;
      ///  otherwise an exception is raised.
      /// </remarks>
      function Filter(const aSpec: ISpecification<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>; overload;

      /// <summary>
      ///  Filters the stream, keeping only items where <paramref name="aPredicate"/> returns True.
      ///  Preserves source order. This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each discarded item.
      ///  <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its buffer;
      ///  otherwise an exception is raised.
      /// </remarks>
      function Filter(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>; overload;

      /// <summary>
      ///  Maps each item using <paramref name="aMapper"/> to produce a stream of a different element type.
      ///  Preserves source order. This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each original item after it has
      ///  been mapped. <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its
      ///  buffer; otherwise an exception is raised.
      /// </remarks>
      function Map<U>(const aMapper: TConstFunc<T, U>; const aOnDiscard: TConstProc<T> = nil): TPipe<U>; overload;

      /// <summary>
      ///  Maps each item to a new value of the same type using <paramref name="aMapper"/>.
      ///  Preserves source order. This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each original item after it has
      ///  been mapped. <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its
      ///  buffer; otherwise an exception is raised.
      /// </remarks>
      function Map(const aMapper: TConstFunc<T, T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>; overload;

      /// <summary>
      ///  Removes duplicate items using the provided equality comparer and preserves the first occurrence
      ///  of each distinct value. This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aEquality"/> is nil, <c>TEqualityComparer&lt;T&gt;.Default</c> is used.
      ///  If <paramref name="AOnDiscard"/> is provided, it is invoked for each item that is removed as a duplicate.
      ///  <paramref name="AOnDiscard"/> is only permitted when the stream currently owns its buffer; otherwise
      ///  an exception is raised.
      /// </remarks>
      function Distinct(const aEquality: IEqualityComparer<T> = nil; const AOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Removes duplicate items by key, preserving the first occurrence of each distinct key.
      ///  This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aKeyEquality"/> is nil, <c>TEqualityComparer&lt;TKey&gt;.Default</c> is used.
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each item removed as a duplicate.
      ///  <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its buffer; otherwise
      ///  an exception is raised.
      /// </remarks>
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
      /// <remarks>
      ///  Ownership: the mapper must return a newly allocated TList&lt;U&gt; (or nil).
      ///  Stream takes ownership of each returned list container and will free it after copying/consuming its items.
      ///  Stream never frees the items (only the list container).
      /// </remarks>
      function FlatMap<U>(const aMapper: TConstFunc<T, TList<U>>): TPipe<U>;

      /// <summary>
      ///  Sorts the stream according to the provided comparer. This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="AComparer"/> is nil, <c>TComparer&lt;T&gt;.Default</c> is used.
      ///  Sorting stability is not guaranteed (inherits the behavior of <c>TList.Sort</c>).
      /// </remarks>
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
      /// <remarks>
      ///  If <paramref name="aOwnsList"/> is True, the list container <paramref name="aList"/> is freed after its items
      ///  have been copied. The stream never assumes ownership of items, only the list container when requested.
      /// </remarks>
      function Concat(const aList: TList<T>; aOwnsList: Boolean): TPipe<T>; overload;

      /// <summary>
      ///  Concatenates the current stream with all items produced by <paramref name="aEnum"/>.
      ///  This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOwnsEnum"/> is True, the enumerator <paramref name="aEnum"/> is freed after enumeration.
      /// </remarks>
      function Concat(aEnum: TEnumerator<T>; aOwnsEnum: Boolean = False): TPipe<T>; overload;

      /// <summary>
      ///  Keeps the first <paramref name="aCount"/> items (in order). This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each discarded item.
      ///  <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its buffer; otherwise
      ///  an exception is raised.
      /// </remarks>
      function Take(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Keeps items from the start of the stream while <paramref name="aPredicate"/> returns True.
      ///  Stops at the first False. This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each discarded item after the first False.
      ///  <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its buffer; otherwise
      ///  an exception is raised.
      /// </remarks>
      function TakeWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Keeps the last <paramref name="aCount"/> items (in order). This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each discarded item from the prefix.
      ///  <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its buffer; otherwise
      ///  an exception is raised.
      /// </remarks>
      function TakeLast(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Skips the first <paramref name="aCount"/> items and keeps the remainder (in order).
      ///  This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each skipped item.
      ///  <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its buffer; otherwise
      ///  an exception is raised.
      /// </remarks>
      function Skip(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Skips items from the start of the stream while <paramref name="aPredicate"/> returns True.
      ///  Once the predicate returns False, all remaining items are kept (predicate is not evaluated further).
      ///  This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each skipped item.
      ///  <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its buffer; otherwise
      ///  an exception is raised.
      /// </remarks>
      function SkipWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Skips the last <paramref name="aCount"/> items and keeps the prefix (in order).
      ///  This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each discarded item from the suffix.
      ///  <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its buffer; otherwise
      ///  an exception is raised.
      /// </remarks>
      function SkipLast(const aCount: Integer; const aOnDiscard: TConstProc<T> = nil): TPipe<T>;

      /// <summary>
      ///  Observes items in the stream without changing them. Invokes <paramref name="aAction"/> for each item,
      ///  passing a zero-based index and the item value. This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  Intended for logging, debugging, metrics, and tracing. Avoid side effects that change program meaning.
      /// </remarks>
      function Peek(const aAction: TConstProc<Integer, T>): TPipe<T>;

      /// <summary>
      ///  Zips the stream with <paramref name="aOther"/> pairwise (index, left, right) using <paramref name="aZipper"/>.
      ///  Stops at the shorter sequence. This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOwnsList"/> is True, the list container <paramref name="aOther"/> is freed after processing.
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each unpaired item remaining in the current stream
      ///  (i.e. items beyond the zipped length). <paramref name="aOnDiscard"/> is only permitted when the stream currently
      ///  owns its buffer; otherwise an exception is raised.
      ///  If <paramref name="aOnDiscardOther"/> is provided, it is invoked for each unpaired item remaining in <paramref name="aOther"/>.
      /// <paramref name="aOnDiscardOther"/> requires <paramref name="aOwnsList"/> = True.
      /// </remarks>
      function Zip<T2, TResult>(
        const aOther: TList<T2>;
        aOwnsList: Boolean;
        const aZipper: TConstFunc<Integer, T, T2, TResult>;
        const aOnDiscard: TConstProc<T> = nil;
        const aOnDiscardOther: TConstProc<T2> = nil
      ): TPipe<TResult>; overload;

      /// <summary>
      ///  Zips the stream with <paramref name="aOther"/> pairwise (index, left, right) using <paramref name="aZipper"/>.
      ///  Stops at the shorter sequence. This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each unpaired item remaining in the current stream.
      ///  <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its buffer; otherwise an exception is raised.
      /// </remarks>
      function Zip<T2, TResult>(
        const aOther: array of T2;
        const aZipper: TConstFunc<Integer, T, T2, TResult>;
        const aOnDiscard: TConstProc<T> = nil
      ): TPipe<TResult>; overload;

      /// <summary>
      ///  Zips the stream with items produced by <paramref name="aEnum"/> pairwise (index, left, right) using <paramref name="aZipper"/>.
      ///  Stops when either sequence ends. This is a transform (does not consume the stream).
      /// </summary>
      /// <remarks>
      ///  If <paramref name="aOwnsEnum"/> is True, the enumerator <paramref name="aEnum"/> is freed after processing.
      ///  If <paramref name="aOnDiscard"/> is provided, it is invoked for each unpaired item remaining in the current stream.
      ///  <paramref name="aOnDiscard"/> is only permitted when the stream currently owns its buffer; otherwise an exception is raised.
      ///  If <paramref name="aOnDiscardOther"/> is provided, it is invoked for each unpaired item remaining in the enumerator.
      ///  <paramref name="aOnDiscardOther"/> requires <paramref name="aOwnsEnum"/> = True.
      /// </remarks>
      function Zip<T2, TResult>(
        aEnum: TEnumerator<T2>;
        aOwnsEnum: Boolean;
        const aZipper: TConstFunc<Integer, T, T2, TResult>;
        const aOnDiscard: TConstProc<T> = nil;
        const aOnDiscardOther: TConstProc<T2> = nil
      ): TPipe<TResult>; overload;

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
      ///  Returns the number of items in the stream and consumes the stream.
      /// </summary>
      function Count: Integer;

      /// <summary>
      ///  Counts items in the stream by a key produced by <paramref name="aKeySelector"/> and consumes the stream.
      /// </summary>
      /// <remarks>
      ///  The returned dictionary is owned by the caller.
      ///  If <paramref name="aEquality"/> is nil, <c>TEqualityComparer&lt;TKey&gt;.Default</c> is used.
      /// </remarks>
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
      /// <remarks>
      ///  If <paramref name="aEquality"/> is nil, <c>TEqualityComparer&lt;T&gt;.Default</c> is used.
      /// </remarks>
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
      /// <remarks>
      ///  The returned dictionary and all group lists are owned by the caller.
      ///  Grouping preserves the original order of items within each group.
      ///  If <paramref name="aEquality"/> is nil, <c>TEqualityComparer&lt;TKey&gt;.Default</c> is used.
      ///  Stream never assumes ownership of items.
      /// </remarks>
      function GroupBy<TKey>(
        const aKeySelector: TConstFunc<T, TKey>;
        const aEquality: IEqualityComparer<TKey> = nil): TDictionary<TKey, TList<T>>;

      /// <summary>
      ///  Splits the stream into two lists based on <paramref name="aPredicate"/>.
      ///  Items for which the predicate returns True are placed in the first list;
      ///  all other items are placed in the second list.
      ///  This is a terminal operation and consumes the stream.
      /// </summary>
      /// <remarks>
      ///  Both returned lists are owned by the caller.
      ///  The relative order of items is preserved in each list.
      ///  Stream never assumes ownership of items.
      /// </remarks>
      function Partition(const aPredicate: TConstPredicate<T>): TPair<TList<T>, TList<T>>; overload;

      /// <summary>
      ///  Splits the stream into two lists based on <paramref name="aSpec"/> and consumes the stream.
      ///  Items for which the specification is satisfied are placed in the first list;
      ///  all other items are placed in the second list.
      /// </summary>
      /// <remarks>
      ///  Both returned lists are owned by the caller.
      ///  The relative order of items is preserved in each list.
      ///  Stream never assumes ownership of items.
      /// </remarks>
      function Partition(const aSpec: ISpecification<T>): TPair<TList<T>, TList<T>>; overload;

      /// <summary>
      ///  Splits the stream into two lists at <paramref name="aIndex"/> and consumes the stream.
      ///  The first list contains the first <paramref name="aIndex"/> items; the second contains the remaining items.
      /// </summary>
      /// <remarks>
      ///  Both returned lists are owned by the caller.
      ///  The relative order of items is preserved in each list.
      ///  Stream never assumes ownership of items.
      /// </remarks>
      function SplitAt(const aIndex: Integer): TPair<TList<T>, TList<T>>;
    end;

  public
    /// <summary>
    /// Takes ownership of the list container. Stream may free it when replaced/consumed.
    /// Items are never freed by Stream.
    /// </summary>
    class function From<T>(const aList: TList<T>): TPipe<T>; overload; static;

    /// <summary>
    /// Borrows the list container. Stream never frees it.
    /// Items are never freed by Stream.
    /// </summary>
    class function Borrow<T>(const aList: TList<T>): TPipe<T>; overload; static;

    /// <summary>
    /// Materializes an internal list buffer from the array (owned by Stream until detached).
    /// </summary>
    class function From<T>(const aValues: array of T): TPipe<T>; overload; static;

    /// <summary>
    /// Materializes an internal list buffer from an enumerator (owned by Stream until detached).
    /// OwnsEnum controls whether the enumerator is freed.
    /// </summary>
    class function From<T>(aEnum: TEnumerator<T>; aOwnsEnum: Boolean = False): TPipe<T>; overload; static;
  end;

implementation

uses
  Base.Integrity;

{ Stream.TPipe<T>.TState }

{----------------------------------------------------------------------------------------------------------------------}
constructor Stream.TPipe<T>.TState.Create(aList: TList<T>; aOwnsList: Boolean);
begin
  inherited Create;

  fList := aList;
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

{----------------------------------------------------------------------------------------------------------------------}
procedure Stream.TPipe<T>.TState.CheckDisposable(const aOnDiscard: TConstProc<T>);
begin
  Ensure.IsFalse(Assigned(aOnDiscard) and (not fOwnsList), 'Use Stream.From(list) or omit OnDiscard.');
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

  Ensure.IsAssigned(fState.List, 'Stream has no buffer');

  Result := if fState.GetOwnsList then fState.List else TList<T>.Create(fState.List);

  FState.SetOwnsList(false);
  FState.SetList(nil);
  FState.SetConsumed(true);
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.AsArray: TArray<T>;
begin
  try
    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(FState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(@aKeySelector, 'KeySelector is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(@aPredicate, 'Predicate is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(aSpec, 'Spec is nil');

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
    Ensure.IsAssigned(@aPredicate, 'Predicate is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(aSpec, 'Spec is nil');

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
    Ensure.IsAssigned(@aReducer, 'Reducer is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(@aAction, 'Action is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(@aPredicate, 'Predicate is nil');

    Result := not Any(aPredicate);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Contains(const aValue: T; const aEquality: IEqualityComparer<T>): Boolean;
begin
  try
    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

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
  Ensure.IsAssigned(@aKeySelector, 'KeySelector is nil')
        .IsAssigned(fState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(@aPredicate, 'Predicate is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

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
    Ensure.IsAssigned(aSpec, 'Spec is nil');

    Result := Partition(
      function(const item: T): Boolean
      begin
        Result := aSpec.IsSatisfiedBy(item);
      end);

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
          .IsAssigned(fState.List, 'Stream has no buffer');

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
function Stream.TPipe<T>.Distinct(const aEquality: IEqualityComparer<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  lSeen: TDictionary<T, Byte>;
  lItem: T;
  i: Integer;
  scope: TScope;
begin
  try
    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := fState.List.Count;

    lSeen := scope.Owns(TDictionary<T, Byte>.Create(aEquality));
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

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
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
    Ensure.IsAssigned(@aKeySelector, 'KeySelector is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

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

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.FlatMap<U>(const aMapper: TConstFunc<T, TList<U>>): TPipe<U>;
var
  scope : TScope;
begin
  try
    Ensure.IsAssigned(@aMapper, 'Mapper is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

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

    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

    if aComparer = nil then
      lCmp := TComparer<T>.Default
    else
      lCmp := AComparer;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count;
    list.AddRange(fState.List);
    list.Sort(lCmp);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Reverse: TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count;

    for var i := Pred(fState.List.Count) downto 0 do
      list.Add(fState.List[i]);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Concat(const aValues: array of T): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(fState.List, 'Stream has no buffer');

    FState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count + Length(aValues);
    list.AddRange(fState.List);

    for var i := Low(aValues) to High(aValues) do
      list.Add(aValues[i]);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Concat(const aList: TList<T>; aOwnsList: Boolean): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(aList, 'List is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    FState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count + aList.Count;
    list.AddRange(fState.List);
    list.AddRange(aList);

    if aOwnsList then
      aList.Free;

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Concat(aEnum: TEnumerator<T>; aOwnsEnum: Boolean): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(aEnum, 'Enum is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    FState.CheckNotConsumed;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count;
    list.AddRange(fState.List);

    while aEnum.MoveNext do
      list.Add(aEnum.Current);

    if aOwnsEnum then
      aEnum.Free;

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Filter(const aSpec: ISpecification<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
begin
  try
    Ensure.IsAssigned(aSpec, 'Spec is nil');

    Result := Filter(
      function(const item: T): Boolean
      begin
        Result := aSpec.IsSatisfiedBy(item);
      end,
      aOnDiscard);

  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Filter(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aPredicate, 'Predicate is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

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

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Map<U>(const aMapper: TConstFunc<T, U>; const aOnDiscard: TConstProc<T>): TPipe<U>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aMapper, 'Mapper is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

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
    Ensure.IsAssigned(@aMapper, 'Mapper is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

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
          .IsAssigned(fState.List, 'Stream has no buffer');

    FState.CheckNotConsumed;
    FState.CheckDisposable(aOnDiscard);

    var lCount := if aCount > fState.List.Count then fState.List.Count else aCount;

    var list := scope.Owns(TList<T>.Create);
    list.Capacity := lCount;

    for var i := 0 to Pred(lCount) do
      list.Add(fState.List[i]);

    if Assigned(aOnDiscard) then
      for var i := lCount to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TakeWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aPredicate, 'Predicate is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

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

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.TakeLast(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aCount >= 0, 'Count must be >= 0')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var lCount := if aCount > fState.List.Count then fState.List.Count else aCount;

    var startIdx := fState.List.Count - lCount;
    var list := scope.Owns(TList<T>.Create);

    list.Capacity := lCount;

    if Assigned(aOnDiscard) then
      for var i := 0 to Pred(startIdx) do
        aOnDiscard(fState.List[i]);

    for var i := startIdx to Pred(fState.List.Count) do
      list.Add(fState.List[i]);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Skip(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aCount >= 0, 'Count must be >= 0')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var lCount := if aCount > fState.List.Count then fState.List.Count else aCount;

    var startIdx := lCount;
    var list := scope.Owns(TList<T>.Create);

    list.Capacity := fState.List.Count - startIdx;

    if Assigned(aOnDiscard) then
      for var i := 0 to Pred(startIdx) do
        aOnDiscard(fState.List[I]);

    for var i := startIdx to Pred(fState.List.Count) do
      list.Add(fState.List[I]);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.SkipWhile(const aPredicate: TConstPredicate<T>; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aPredicate, 'Predicate is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

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

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.SkipLast(const aCount: Integer; const aOnDiscard: TConstProc<T>): TPipe<T>;
var
  scope: TScope;
begin
  try
    Ensure.IsTrue(aCount >= 0, 'Count must be >= 0')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var dropCount := if aCount > fState.List.Count then fState.List.Count else aCount;
    var keepCount := fState.List.Count - DropCount;

    var list := scope.Owns(TList<T>.Create);

    list.Capacity := keepCount;

    for var i := 0 to Pred(KeepCount) do
      list.Add(fState.List[i]);

    if Assigned(aOnDiscard) then
      for var i := KeepCount to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    fState.SetList(scope.Release(list));
    fState.SetOwnsList(true);

    Result := Self;
  except
    fState.Terminate;
    raise;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Peek(const aAction: TConstProc<Integer, T>): TPipe<T>;
begin
  try
    Ensure.IsAssigned(@aAction, 'Action is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

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
  const aOther: TList<T2>;
  aOwnsList: Boolean;
  const aZipper: TConstFunc<Integer, T, T2, TResult>;
  const aOnDiscard: TConstProc<T>;
  const aOnDiscardOther: TConstProc<T2>
): TPipe<TResult>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aOther, 'Other is nil')
          .IsAssigned(@aZipper, 'Zipper is nil')
          .IsAssigned(fState.List, 'Stream has no buffer')
          .IsFalse(Assigned(aOnDiscardOther) and (not aOwnsList), 'OnDiscardOther requires aOwnsList=True');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

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
  const aOnDiscard: TConstProc<T>
  ): TPipe<TResult>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aOther, 'Other is nil')
          .IsAssigned(@aZipper, 'Zipper is nil')
          .IsAssigned(fState.List, 'Stream has no buffer');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var n := if Length(aOther) < fState.List.Count then Length(aOther) else fState.List.Count;

    var list := scope.Owns(TList<TResult>.Create);
    list.Capacity := n;

    for var i := 0 to Pred(N) do
      list.Add(aZipper(i, FState.List[i], aOther[i]));

    if Assigned(aOnDiscard) then
      for var i := n to Pred(fState.List.Count) do
        aOnDiscard(FState.List[i]);

    Result := Stream.TPipe<TResult>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
function Stream.TPipe<T>.Zip<T2, TResult>(
  aEnum: TEnumerator<T2>;
  aOwnsEnum: Boolean;
  const aZipper: TConstFunc<Integer, T, T2, TResult>;
  const aOnDiscard: TConstProc<T>;
  const aOnDiscardOther: TConstProc<T2>
  ): TPipe<TResult>;
var
  scope: TScope;
begin
  try
    Ensure.IsAssigned(@aEnum, 'Enum is nil')
          .IsAssigned(@aZipper, 'Zipper is nil')
          .IsAssigned(fState.List, 'Stream has no buffer')
          .IsFalse(Assigned(aOnDiscardOther) and (not aOwnsEnum), 'OnDiscardOther requires aOwnsEnum=True');

    fState.CheckNotConsumed;
    fState.CheckDisposable(aOnDiscard);

    var list := scope.Owns(TList<TResult>.Create);
    list.Capacity := fState.List.Count;

    var n := 0;

    for var i := 0 to Pred(fState.List.Count) do
    begin
      if not aEnum.MoveNext then break;
      list.Add(aZipper(i, fState.List[i], aEnum.Current));
      Inc(n);
    end;

    if Assigned(aOnDiscard) then
      for var i := n to Pred(fState.List.Count) do
        aOnDiscard(fState.List[i]);

    if Assigned(aOnDiscardOther) then
      while aEnum.MoveNext do
        aOnDiscardOther(aEnum.Current);

    if aOwnsEnum then
      aEnum.Free;

    Result := Stream.TPipe<TResult>.CreatePipe(scope.Release(list), true);

  finally
    fState.Terminate;
  end;
end;

{ Stream factories }

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(const aList: TList<T>): TPipe<T>;
begin
  Ensure.IsAssigned(aList, 'List is nil');

  Result := TPipe<T>.CreatePipe(aList, true);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.Borrow<T>(const aList: TList<T>): TPipe<T>;
begin
  Ensure.IsAssigned(aList, 'List is nil');

  Result := TPipe<T>.CreatePipe(aList, false);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(const aValues: array of T): TPipe<T>;
begin
  var list := TList<T>.Create(aValues);

  Result := TPipe<T>.CreatePipe(list, true);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Stream.From<T>(aEnum: TEnumerator<T>; aOwnsEnum: Boolean): TPipe<T>;
begin
  Ensure.IsAssigned(aEnum, 'Enum is nil');

  var list := TList<T>.Create;

  while aEnum.MoveNext do
    list.Add(aEnum.Current);

  Result := TPipe<T>.CreatePipe(list, true);

  if aOwnsEnum then
    aEnum.Free;
end;

end.
