unit Tests.Core.Collections;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Hash,
  DUnitX.TestFramework,
  Base.Core,
  Base.Collections;

type
  TFlagList = class(TList<Integer>)
  private
    FFlag: PBoolean;
  public
    constructor Create(AFlag: PBoolean);
    destructor Destroy; override;
  end;

  [TestFixture]
  TStreamFixture = class
  public
    [Test] procedure From_TakesOwnership_AndFreesContainerOnTransform;
    [Test] procedure Borrow_DoesNotFreeContainerOnTransform;
    [Test] procedure AsList_Borrowed_ClonesAndDoesNotTouchOriginal;
    [Test] procedure AsList_Owned_DetachesSameInstance;
    [Test] procedure Map_From_TakesOwnership_AndFreesContainer;
    [Test] procedure Map_Borrow_DoesNotFreeContainer;
    [Test] procedure Distinct_PreservesFirstOccurrenceOrder;
    [Test] procedure ComparersAndEquality;
    [Test] procedure Count_From_FreesOwnedContainer;
    [Test] procedure Count_Borrow_DoesNotFreeContainer;
    [Test] procedure Any_ShortCircuits;
    [Test] procedure Any_Borrow_DoesNotFreeContainer;
    [Test] procedure All_ShortCircuitsOnFirstFailure;
    [Test] procedure All_Empty_ReturnsTrue;
    [Test] procedure Reduce_FoldsLeft_FromSeed;
    [Test] procedure Reduce_Empty_ReturnsSeed;
    [Test] procedure AsArray_PreservesOrder;
    [Test] procedure AsArray_Borrow_DoesNotFreeContainer;
    [Test] procedure ForEach_VisitsItemsInOrder_AndConsumes;
    [Test] procedure FirstOrDefault_Empty_ReturnsDefault;
    [Test] procedure LastOrDefault_NonEmpty_ReturnsLast;
    [Test] procedure LastOrDefault_Empty_ReturnsDefault;
    [Test] procedure Reverse_ReversesOrder;
    [Test] procedure Concat_Array_AppendsInOrder;
    [Test] procedure Concat_List_AppendsInOrder;
    [Test] procedure Concat_Enumerator_AppendsInOrder;
    [Test] procedure Concat_List_OwnsListTrue_FreesSourceContainer;
    [Test] procedure Skip_Basic_SkipsFirstN;
    [Test] procedure Skip_OnDiscard_Owned_CallsForDroppedItems;
    [Test] procedure SkipWhile_SkipsLeadingMatchesOnly;
    [Test] procedure SkipWhile_OnDiscard_Owned_CallsForSkippedItems;
    [Test] procedure SkipLast_Basic_DropsLastN;
    [Test] procedure SkipLast_OnDiscard_Owned_CallsForDiscardedSuffix;
    [Test] procedure Take_Basic_KeepsFirstN;
    [Test] procedure Take_OnDiscard_Owned_CallsForDroppedItems;
    [Test] procedure TakeWhile_TakesLeadingMatchesOnly;
    [Test] procedure TakeWhile_OnDiscard_Owned_CallsForDiscardedItems;
    [Test] procedure TakeLast_Basic_KeepsLastN;
    [Test] procedure TakeLast_OnDiscard_Owned_CallsForDiscardedPrefix;
    [Test] procedure Peek_VisitsItemsInOrder_AndDoesNotConsume;
    [Test] procedure Map_Same_Allows_Transforms;
    [Test] procedure IsEmpty_Works;
    [Test] procedure None_Works;
    [Test] procedure Contains_CustomEquality_Works;
    [Test] procedure Contains_DefaultEquality_Works;
    [Test] procedure Terminal_Consumes_Stream_Guard;
    [Test] procedure Zip_List_ZipsToMinLength;
    [Test] procedure Zip_List_ZipsToMinLength_WithConstArray;
    [Test] procedure Transform_Exception_FreesOwnedBuffer_AndPoisonsStream;
    [Test] procedure GroupBy_GroupsAndPreservesOrder;
    [Test] procedure GroupBy_UsesCustomEqualityComparer;
    [Test] procedure GroupBy_ConsumesStream_Guard;
    [Test] procedure Partition_SplitsIntoMatchingAndNonMatching;

    [Test]
    [TestCase('Split at 0', '0')]
    [TestCase('Split at 2', '2')]
    [TestCase('Split at 5', '5')]
    procedure SplitAt_SplitsIntoPrefixAndSuffix(const aIndex:integer);

    [Test] procedure Filter_Specification_Works;
    [Test] procedure Partition_Specification_Works;
    [Test] procedure Any_Specification_Works;
    [Test] procedure All_Specification_Works;
    [Test] procedure DistinctBy_Works;
    [Test] procedure FlatMap_Works;
    [Test] procedure CountBy_Works;
    [Test] procedure Subtract_Should_Remove_Items_Present_In_Other_Source;
    [Test] procedure Union_Should_Combine_Stream_And_Other_Source_Without_Duplicates;
    [Test] procedure Intersect_Should_Keep_Items_Present_In_Other_Source;
    [Test] procedure SymmetricDifference_Should_Keep_Items_Present_In_Only_One_Source;
    [Test] procedure From_Should_Ingest_Sequence_And_Allow_Further_Processing;
  end;

  [TestFixture]
  TSliceFixture = class
  public
    [Test] procedure From_Should_Set_Low_High_Length_And_Count;
    [Test] procedure TryPut_Should_Update_Source_Item_Within_Current_Accessible_Range;
    [Test] procedure Fill_Should_Overwrite_Currently_Accessible_Items_Only;
    [Test] procedure Reverse_Should_Reverse_Currently_Accessible_Items;
    [Test] procedure Reverse_Should_Only_Reverse_Currently_Accessible_Items;
    [Test] procedure Sort_Should_Sort_Currently_Accessible_Items;
    [Test] procedure Sort_Should_Only_Sort_Currently_Accessible_Items;
    [Test] procedure ToSequence_Should_Copy_Currently_Accessible_Items;
    [Test] procedure ToSequence_Should_Copy_Only_Currently_Accessible_Items;
    [Test] procedure ToSubSlice_Should_Create_SubSlice_Within_Nominal_Window;
    [Test] procedure ToSubSlice_Should_Preserve_Nominal_Window_When_Source_Shrinks;
    [Test] procedure Enumerator_Should_Iterate_Currently_Accessible_Items_Only;
    [Test] procedure Enumerator_Should_Handle_Empty_Slice;
  end;

  [TestFixture]
  TSequenceFixture = class
  public
    [Test] procedure Fluent_Operations_Should_Produce_Expected_Result_And_Support_Search;
    [Test] procedure Reverse_Should_Return_Items_In_Opposite_Order;
    [Test] procedure Distinct_Should_Keep_First_Occurrences_In_Order;
    [Test] procedure Distinct_Should_Return_Duplicates_In_Out_List;
    [Test] procedure Skip_Should_Return_Suffix_After_Skipping_Count;
    [Test] procedure Skip_Should_Return_Empty_When_Count_Exceeds_Length;
    [Test] procedure Take_Should_Return_Prefix_Of_Requested_Count;
    [Test] procedure Take_Should_Return_Whole_Sequence_When_Count_Exceeds_Length;
    [Test] procedure ToArray_Should_Return_A_Copy_Of_Items;
    [Test] procedure ToArray_Should_Return_Detached_Copy;
    [Test] procedure Sort_Should_Return_Items_In_Ascending_Order;
    [Test] procedure EndsWith_Should_Return_True_For_Matching_Suffix;
    [Test] procedure StartsWith_Should_Return_True_For_Matching_Prefix;
    [Test] procedure SubSequence_Should_Return_Requested_Range;
    [Test] procedure SubSequence_Should_Clamp_Out_Of_Range_Bounds;
    [Test] procedure SubSequence_Should_Return_Empty_When_Low_Exceeds_High;
    [Test] procedure Equals_Should_Return_True_For_Equal_Sequences;
    [Test] procedure Equals_Should_Return_False_For_Different_Order;
    [Test] procedure Equals_Should_Return_False_For_Different_Length;
    [Test] procedure SetEquals_Should_Ignore_Order_And_Duplicates;
    [Test] procedure Overlaps_Should_Return_True_When_Sequences_Share_Any_Value;
    [Test] procedure Subtract_Should_Remove_Items_Present_In_Other_Source;
    [Test] procedure Union_Should_Combine_Items_Without_Duplicates;
    [Test] procedure Intersect_Should_Keep_Items_Present_In_Other_Source;
    [Test] procedure SymmetricDifference_Should_Keep_Items_Present_In_Only_One_Source;
    [Test] procedure Concat_Should_Append_Items_In_Order;
  end;

  [TestFixture]
  TIndexFixture = class
  public
    [Test] procedure Should_Initialize_Correctly;
    [Test] procedure Should_Convert_To_Types;
    [Test] procedure Should_Append_To_List;
  end;

  [TestFixture]
  TSelectionFixture = class
  public
    [Test] procedure Items_Should_Read_And_Write_Through_Selected_Pins;
    [Test] procedure TryPut_Should_Return_False_For_Invalid_Selection_Index;
    [Test] procedure ToArray_Should_Materialize_Selected_Values_In_Order;
    [Test] procedure Remove_Should_Remove_Pin_And_Shift_Selection_Order;
    [Test] procedure Clear_Should_Remove_All_Pins;
    [Test] procedure ToSequence_Should_Materialize_Selected_Values_In_Order;
    [Test] procedure CountOf_Should_Return_Number_Of_Matching_Selected_Values;
    [Test] procedure Any_Should_Return_True_When_Any_Selected_Value_Matches;
    [Test] procedure All_Should_Return_True_Only_When_All_Selected_Values_Match;
    [Test] procedure IndexOf_Should_Return_First_Matching_Selection_Index;
    [Test] procedure LastIndexOf_Should_Return_Last_Matching_Selection_Index;
    [Test] procedure ItemAt_Should_Return_Option_For_Valid_And_Invalid_Indices;
    [Test] procedure ToList_Should_Materialize_Selected_Values_In_Order;
  end;

implementation

uses
  Base.Integrity;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.ToList_Should_Materialize_Selected_Values_In_Order;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);
  var list3 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([10, 11, 12]);
  list2.AddRange([20, 21, 22]);
  list3.AddRange([30, 31, 32, 33]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 2); // 12
  sel.Add(list2, 0); // 20
  sel.Add(list3, 1); // 31

  var r := scope.Owns(sel.ToList);

  Assert.AreEqual(3, r.Count);
  Assert.AreEqual(12, r[0]);
  Assert.AreEqual(20, r[1]);
  Assert.AreEqual(31, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.ItemAt_Should_Return_Option_For_Valid_And_Invalid_Indices;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([10, 11, 12]);
  list2.AddRange([20, 21, 22]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 2); // 12
  sel.Add(list2, 0); // 20

  var a := sel.ItemAt(0);
  var b := sel.ItemAt(1);
  var c := sel.ItemAt(-1);
  var d := sel.ItemAt(2);

  Assert.IsTrue(a.IsSome);
  Assert.AreEqual(12, a.Value);

  Assert.IsTrue(b.IsSome);
  Assert.AreEqual(20, b.Value);

  Assert.IsTrue(c.IsNone);
  Assert.IsTrue(d.IsNone);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.LastIndexOf_Should_Return_Last_Matching_Selection_Index;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);
  var list3 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([10, 11, 12]);
  list2.AddRange([20, 11, 22]);
  list3.AddRange([11, 31, 32, 33]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 1); // 11
  sel.Add(list2, 0); // 20
  sel.Add(list2, 1); // 11
  sel.Add(list3, 0); // 11

  Assert.AreEqual(3, sel.LastIndexOf(11));
  Assert.AreEqual(1, sel.LastIndexOf(20));
  Assert.AreEqual(-1, sel.LastIndexOf(99));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.IndexOf_Should_Return_First_Matching_Selection_Index;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);
  var list3 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([10, 11, 12]);
  list2.AddRange([20, 11, 22]);
  list3.AddRange([11, 31, 32, 33]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 1); // 11
  sel.Add(list2, 0); // 20
  sel.Add(list2, 1); // 11
  sel.Add(list3, 0); // 11

  Assert.AreEqual(0, sel.IndexOf(11));
  Assert.AreEqual(1, sel.IndexOf(20));
  Assert.AreEqual(-1, sel.IndexOf(99));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.All_Should_Return_True_Only_When_All_Selected_Values_Match;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([11, 11]);
  list2.AddRange([11, 22]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 0); // 11
  sel.Add(list1, 1); // 11

  Assert.IsTrue(sel.All(11));
  Assert.IsFalse(sel.All(22));

  sel.Add(list2, 1); // 22

  Assert.IsFalse(sel.All(11));
  Assert.IsFalse(sel.All(22));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.Any_Should_Return_True_When_Any_Selected_Value_Matches;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([10, 11, 12]);
  list2.AddRange([20, 21, 22]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 0); // 10
  sel.Add(list1, 2); // 12
  sel.Add(list2, 1); // 21

  Assert.IsTrue(sel.Any(12));
  Assert.IsTrue(sel.Any(21));
  Assert.IsFalse(sel.Any(99));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.CountOf_Should_Return_Number_Of_Matching_Selected_Values;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);
  var list3 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([10, 11, 12]);
  list2.AddRange([20, 11, 22]);
  list3.AddRange([11, 31, 32, 33]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 1); // 11
  sel.Add(list2, 1); // 11
  sel.Add(list3, 0); // 11
  sel.Add(list3, 3); // 33

  Assert.AreEqual(3, sel.CountOf(11));
  Assert.AreEqual(1, sel.CountOf(33));
  Assert.AreEqual(0, sel.CountOf(99));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.ToSequence_Should_Materialize_Selected_Values_In_Order;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);
  var list3 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([10, 11, 12]);
  list2.AddRange([20, 21, 22]);
  list3.AddRange([30, 31, 32, 33]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 1); // 11
  sel.Add(list2, 2); // 22
  sel.Add(list3, 0); // 30

  var seq := sel.ToSequence;
  var r := seq.ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(11, r[0]);
  Assert.AreEqual(22, r[1]);
  Assert.AreEqual(30, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.Clear_Should_Remove_All_Pins;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([10, 11, 12]);
  list2.AddRange([20, 21, 22]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 0);
  sel.Add(list2, 1);

  Assert.AreEqual(2, sel.Count);
  Assert.IsFalse(sel.IsEmpty);

  sel.Clear;

  Assert.AreEqual(0, sel.Count);
  Assert.AreEqual(-1, sel.High);
  Assert.IsTrue(sel.IsEmpty);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.Remove_Should_Remove_Pin_And_Shift_Selection_Order;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);
  var list3 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([10, 11, 12]);
  list2.AddRange([20, 21, 22]);
  list3.AddRange([30, 31, 32, 33]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 0); // 10
  sel.Add(list2, 1); // 21
  sel.Add(list3, 3); // 33

  sel.Remove(1);

  Assert.AreEqual(2, sel.Count);
  Assert.AreEqual(1, sel.High);
  Assert.IsFalse(sel.IsEmpty);

  Assert.AreEqual(10, sel[0]);
  Assert.AreEqual(33, sel[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.ToArray_Should_Materialize_Selected_Values_In_Order;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);
  var list3 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([10, 11, 12]);
  list2.AddRange([20, 21, 22]);
  list3.AddRange([30, 31, 32, 33]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 2); // 12
  sel.Add(list2, 0); // 20
  sel.Add(list3, 1); // 31

  var r := sel.ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(12, r[0]);
  Assert.AreEqual(20, r[1]);
  Assert.AreEqual(31, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.TryPut_Should_Return_False_For_Invalid_Selection_Index;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);
  list.AddRange([10, 20, 30]);

  var sel := scope.Owns(TSelection<Integer>.Create);
  sel.Add(list, 1); // 20

  Assert.IsTrue(sel.TryPut(0, 99));
  Assert.AreEqual(99, list[1]);
  Assert.AreEqual(99, sel[0]);

  Assert.IsFalse(sel.TryPut(-1, 123));
  Assert.IsFalse(sel.TryPut(1, 123));

  Assert.AreEqual(99, list[1]);
  Assert.AreEqual(99, sel[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSelectionFixture.Items_Should_Read_And_Write_Through_Selected_Pins;
var
  scope: TScope;
begin
  var list1 := scope.Owns(TList<Integer>.Create);
  var list2 := scope.Owns(TList<Integer>.Create);
  var list3 := scope.Owns(TList<Integer>.Create);

  list1.AddRange([10, 11, 12]);
  list2.AddRange([20, 21, 22]);
  list3.AddRange([30, 31, 32, 33]);

  var sel := scope.Owns(TSelection<Integer>.Create);

  sel.Add(list1, 0); // 10
  sel.Add(list2, 1); // 21
  sel.Add(list3, 3); // 33

  Assert.AreEqual(3, sel.Count);
  Assert.AreEqual(2, sel.High);
  Assert.IsFalse(sel.IsEmpty);

  Assert.AreEqual(10, sel[0]);
  Assert.AreEqual(21, sel[1]);
  Assert.AreEqual(33, sel[2]);

  sel[0] := 100;
  sel[1] := 210;
  sel[2] := 330;

  Assert.AreEqual(100, list1[0]);
  Assert.AreEqual(210, list2[1]);
  Assert.AreEqual(330, list3[3]);

  Assert.AreEqual(100, sel[0]);
  Assert.AreEqual(210, sel[1]);
  Assert.AreEqual(330, sel[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TIndexFixture.Should_Append_To_List;
var
  index: TIndex<integer>;
  scope: TScope;
begin
  var list := scope.Owns(TList<integer>.Create([1, 2, 3]));

  index := [4, 5];

  index.AppendTo(list);

  Assert.AreEqual(5, list.Count);

  Assert.AreEqual(1, list[0]);
  Assert.AreEqual(2, list[1]);
  Assert.AreEqual(3, list[2]);
  Assert.AreEqual(4, list[3]);
  Assert.AreEqual(5, list[4]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TIndexFixture.Should_Convert_To_Types;
var
  index: TIndex<integer>;
  scope: TScope;
begin
  index := [1, 12, 23, 34];

  var list := scope.Owns(index.ToList);

  Assert.AreEqual(4, list.Count);

  Assert.AreEqual(1,  list[0]);
  Assert.AreEqual(12, list[1]);
  Assert.AreEqual(23, list[2]);
  Assert.AreEqual(34, list[3]);

  var arr := index.ToArray;

  Assert.AreEqual(4, Length(arr));

  Assert.AreEqual(1,  list[0]);
  Assert.AreEqual(12, list[1]);
  Assert.AreEqual(23, list[2]);
  Assert.AreEqual(34, list[3]);

  var seq := index.ToSequence;

  Assert.AreEqual(4, seq.Count);

  Assert.AreEqual(1,  seq[0]);
  Assert.AreEqual(12, seq[1]);
  Assert.AreEqual(23, seq[2]);
  Assert.AreEqual(34, seq[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TIndexFixture.Should_Initialize_Correctly;
var
  index: TIndex<integer>;
  scope: TScope;
begin
  var list := scope.Owns(TList<integer>.Create([5, 6, 7]));

  index := [1, 2, 3, 4];

  Assert.IsFalse(index.IsEmpty);
  Assert.AreEqual(4, index.Count);
  Assert.AreEqual(3, index.High);

  Assert.AreEqual(1, index[0]);
  Assert.AreEqual(2, index[1]);
  Assert.AreEqual(3, index[2]);
  Assert.AreEqual(4, index[3]);

  index := [];

  Assert.IsTrue(index.IsEmpty);
  Assert.AreEqual(0, index.Count);
  Assert.AreEqual(-1, index.High);

  index := list;

  Assert.AreEqual(5, index[0]);
  Assert.AreEqual(6, index[1]);
  Assert.AreEqual(7, index[2]);

  index := TSequence<integer>.From([1, 2]);

  Assert.AreEqual(2, index.Count);
  Assert.AreEqual(1, index[0]);
  Assert.AreEqual(2, index[1]);

  index := TSegment<integer>.From(list, 0, 1);

  Assert.AreEqual(2, index.Count);
  Assert.AreEqual(5, index[0]);
  Assert.AreEqual(6, index[1]);

  index := TSlice<integer>.From(list, 0, 2);

  Assert.AreEqual(3, index.Count);
  Assert.AreEqual(5, index[0]);
  Assert.AreEqual(6, index[1]);
  Assert.AreEqual(7, index[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Concat_Should_Append_Items_In_Order;
begin
  var r := TSequence<Integer>.From([1, 2, 3])
                             .Concat([4, 5, 6])
                             .ToArray;

  Assert.AreEqual(6, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
  Assert.AreEqual(5, r[4]);
  Assert.AreEqual(6, r[5]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.SymmetricDifference_Should_Keep_Items_Present_In_Only_One_Source;
begin
  var r := TSequence<Integer>.From([1, 2, 2, 3])
                             .SymmetricDifference([2, 3, 4, 4, 5])
                             .ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(4, r[1]);
  Assert.AreEqual(5, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Intersect_Should_Keep_Items_Present_In_Other_Source;
begin
  var r := TSequence<Integer>.From([1, 2, 3, 4, 5])
                             .Intersect([2, 4, 6])
                             .ToArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(2, r[0]);
  Assert.AreEqual(4, r[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Union_Should_Combine_Items_Without_Duplicates;
begin
  var r := TSequence<Integer>.From([1, 2, 2, 3])
                             .Union([2, 3, 4, 4, 5])
                             .ToArray;

  Assert.AreEqual(5, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
  Assert.AreEqual(5, r[4]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Subtract_Should_Remove_Items_Present_In_Other_Source;
begin
  var r := TSequence<Integer>.From([1, 2, 3, 4, 5])
                             .Subtract([2, 4])
                             .ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(3, r[1]);
  Assert.AreEqual(5, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Overlaps_Should_Return_True_When_Sequences_Share_Any_Value;
begin
  var s := TSequence<Integer>.From([1, 2, 3]);

  Assert.IsTrue(s.Overlaps([3, 4, 5]));
  Assert.IsTrue(s.Overlaps([2]));
  Assert.IsFalse(s.Overlaps([4, 5, 6]));
  Assert.IsFalse(s.Overlaps([]));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.SetEquals_Should_Ignore_Order_And_Duplicates;
begin
  var s: TSequence<integer> := [1, 1, 2, 3];

  Assert.IsTrue(s.SetEquals([3, 2, 1]));
  Assert.IsTrue(s.SetEquals([1, 2, 2, 3, 3]));
  Assert.IsFalse(s.SetEquals([1, 2, 4]));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Equals_Should_Return_True_For_Equal_Sequences;
begin
  var a := TSequence<Integer>.From([1, 2, 3, 4]);
  var b := TSequence<Integer>.From([1, 2, 3, 4]);

  Assert.IsTrue(a.Equals(b));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Equals_Should_Return_False_For_Different_Order;
begin
  var a := TSequence<Integer>.From([1, 2, 3, 4]);
  var b := TSequence<Integer>.From([1, 3, 2, 4]);

  Assert.IsFalse(a.Equals(b, nil));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Equals_Should_Return_False_For_Different_Length;
begin
  var a := TSequence<Integer>.From([1, 2, 3, 4]);
  var b := TSequence<Integer>.From([1, 2, 3]);

  Assert.IsFalse(a.Equals(b, nil));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.SubSequence_Should_Return_Requested_Range;
begin
  var r := TSequence<Integer>.From([1, 2, 3, 4, 5])
                             .SubSequence(1, 3)
                             .ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(2, r[0]);
  Assert.AreEqual(3, r[1]);
  Assert.AreEqual(4, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.SubSequence_Should_Clamp_Out_Of_Range_Bounds;
begin
  var r := TSequence<Integer>.From([1, 2, 3, 4, 5])
                             .SubSequence(-5, 99)
                             .ToArray;

  Assert.AreEqual(5, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
  Assert.AreEqual(5, r[4]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.SubSequence_Should_Return_Empty_When_Low_Exceeds_High;
begin
  var r := TSequence<Integer>.From([1, 2, 3, 4, 5])
                             .SubSequence(4, 2)
                             .ToArray;

  Assert.AreEqual(0, Length(r));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.StartsWith_Should_Return_True_For_Matching_Prefix;
begin
  var s := TSequence<Integer>.From([1, 2, 3, 4, 5]);

  Assert.IsTrue(s.StartsWith([1, 2]));
  Assert.IsTrue(s.StartsWith([1, 2, 3, 4, 5]));
  Assert.IsTrue(s.StartsWith([]));
  Assert.IsFalse(s.StartsWith([2, 3]));
  Assert.IsFalse(s.StartsWith([1, 2, 3, 4, 5, 6]));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.EndsWith_Should_Return_True_For_Matching_Suffix;
begin
  var s := TSequence<Integer>.From([1, 2, 3, 4, 5]);

  Assert.IsTrue(s.EndsWith([4, 5]));
  Assert.IsTrue(s.EndsWith([1, 2, 3, 4, 5]));
  Assert.IsTrue(s.EndsWith([]));
  Assert.IsFalse(s.EndsWith([3, 5]));
  Assert.IsFalse(s.EndsWith([1, 2, 3, 4, 5, 6]));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Sort_Should_Return_Items_In_Ascending_Order;
begin
  var r := TSequence<Integer>
              .From([5, 3, 1, 2, 4])
              .Sorted
              .ToArray;

  Assert.AreEqual(5, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
  Assert.AreEqual(5, r[4]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.ToArray_Should_Return_A_Copy_Of_Items;
begin
  var s := TSequence<Integer>.From([1, 2, 3]);
  var a := s.ToArray;

  Assert.AreEqual(3, Length(a));
  Assert.AreEqual(1, a[0]);
  Assert.AreEqual(2, a[1]);
  Assert.AreEqual(3, a[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.ToArray_Should_Return_Detached_Copy;
begin
  var s := TSequence<Integer>.From([1, 2, 3]);
  var a := s.ToArray;

  a[0] := 99;

  var r := s.ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Take_Should_Return_Prefix_Of_Requested_Count;
begin
  var r := TSequence<Integer>.From([1, 2, 3, 4, 5])
                             .Take(3)
                             .ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Take_Should_Return_Whole_Sequence_When_Count_Exceeds_Length;
begin
  var r := TSequence<Integer>.From([1, 2, 3])
                             .Take(10)
                             .ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Skip_Should_Return_Empty_When_Count_Exceeds_Length;
begin
  var r := TSequence<Integer>.From([1, 2, 3])
                             .Skip(10)
                             .ToArray;

  Assert.AreEqual(0, Length(r));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Skip_Should_Return_Suffix_After_Skipping_Count;
begin
  var r := TSequence<Integer>.From([1, 2, 3, 4, 5])
                             .Skip(2)
                             .ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(3, r[0]);
  Assert.AreEqual(4, r[1]);
  Assert.AreEqual(5, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Distinct_Should_Return_Duplicates_In_Out_List;
var
  dups: TList<Integer>;
begin
  dups := nil;
  try
    var r := TSequence<Integer>
                .From([5, 3, 1, 3, 2, 4, 2, 5, 4])
                .Distinct(dups)
                .ToArray;

    Assert.AreEqual(5, Length(r));
    Assert.AreEqual(5, r[0]);
    Assert.AreEqual(3, r[1]);
    Assert.AreEqual(1, r[2]);
    Assert.AreEqual(2, r[3]);
    Assert.AreEqual(4, r[4]);

    Assert.IsNotNull(dups);

    Assert.AreEqual(4, dups.Count);
    Assert.AreEqual(3, dups[0]);
    Assert.AreEqual(2, dups[1]);
    Assert.AreEqual(5, dups[2]);
    Assert.AreEqual(4, dups[3]);
  finally
    dups.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Distinct_Should_Keep_First_Occurrences_In_Order;
begin
  var r := TSequence<Integer>.From([5, 3, 1, 3, 2, 4, 2, 5, 4])
                             .Distinct
                             .ToArray;

  Assert.AreEqual(5, Length(r));
  Assert.AreEqual(5, r[0]);
  Assert.AreEqual(3, r[1]);
  Assert.AreEqual(1, r[2]);
  Assert.AreEqual(2, r[3]);
  Assert.AreEqual(4, r[4]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Reverse_Should_Return_Items_In_Opposite_Order;
begin
  var r := TSequence<Integer>.From([2, 3, 4]).Reversed.ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(4, r[0]);
  Assert.AreEqual(3, r[1]);
  Assert.AreEqual(2, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSequenceFixture.Fluent_Operations_Should_Produce_Expected_Result_And_Support_Search;
begin
  var s := TSequence<Integer>
             .From([5, 3, 1, 3, 2, 4, 2, 5, 4])
             .Distinct
             .Sorted
             .Skip(1)
             .Take(3)
             .Reversed;

  var r := s.ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(4, r[0]);
  Assert.AreEqual(3, r[1]);
  Assert.AreEqual(2, r[2]);

  Assert.IsTrue(s.Contains(3));
  Assert.IsFalse(s.Contains(99));

  Assert.AreEqual(1, s.IndexOf(3, 0, nil));
  Assert.AreEqual(2, s.IndexOf(2, 0, nil));
  Assert.AreEqual(-1, s.IndexOf(99, 0, nil));

  Assert.AreEqual(1, s.LastIndexOf(3));
  Assert.AreEqual(2, s.LastIndexOf(2));
  Assert.AreEqual(-1, s.LastIndexOf(99));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.Enumerator_Should_Iterate_Currently_Accessible_Items_Only;
var
  scope: TScope;
  list: TList<Integer>;
  s: TSlice<Integer>;
  r: TArray<Integer>;
  i: Integer;
begin
  list := scope.Owns(TList<Integer>.Create);
  list.AddRange([10, 20, 30, 40, 50]);

  s := TSlice<Integer>.From(list, 1, 3);

  list.DeleteRange(2, 3); // list becomes [10, 20], slice Count becomes 1

  SetLength(r, 0);
  i := 0;

  for var item in s do
  begin
    SetLength(r, i + 1);
    r[i] := item;
    Inc(i);
  end;

  Assert.AreEqual(1, Length(r));
  Assert.AreEqual(20, r[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.Enumerator_Should_Handle_Empty_Slice;
var
  scope: TScope;
  list: TList<Integer>;
  s: TSlice<Integer>;
  count: Integer;
begin
  list := scope.Owns(TList<Integer>.Create);
  list.AddRange([10, 20, 30]);

  s := TSlice<Integer>.From(list, 1, 2);
  list.Clear; // slice Count becomes 0

  count := 0;

  for var item in s do
    Inc(count);

  Assert.AreEqual(0, count);
  Assert.IsTrue(s.IsEmpty);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.ToSubSlice_Should_Preserve_Nominal_Window_When_Source_Shrinks;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 20, 30, 40, 50]);

  var s := TSlice<Integer>.From(list, 1, 3);
  var sub := s.ToSubSlice(1, 2);

  list.DeleteRange(3, 2); // list becomes [10, 20, 30]

  Assert.AreEqual(2, sub.Low);
  Assert.AreEqual(3, sub.High);
  Assert.AreEqual(2, sub.Length);
  Assert.AreEqual(1, sub.Count);
  Assert.IsFalse(sub.IsEmpty);

  Assert.AreEqual(30, sub[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.ToSubSlice_Should_Create_SubSlice_Within_Nominal_Window;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 20, 30, 40, 50]);

  var s := TSlice<Integer>.From(list, 1, 3);
  var sub := s.ToSubSlice(1, 2);

  Assert.AreEqual(2, sub.Low);
  Assert.AreEqual(3, sub.High);
  Assert.AreEqual(2, sub.Length);
  Assert.AreEqual(2, sub.Count);
  Assert.IsFalse(sub.IsEmpty);

  Assert.AreEqual(30, sub[0]);
  Assert.AreEqual(40, sub[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.ToSequence_Should_Copy_Currently_Accessible_Items;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 20, 30, 40, 50]);

  var s := TSlice<Integer>.From(list, 1, 3);
  var seq := s.ToSequence;
  var r := seq.ToArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(20, r[0]);
  Assert.AreEqual(30, r[1]);
  Assert.AreEqual(40, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.ToSequence_Should_Copy_Only_Currently_Accessible_Items;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 20, 30, 40, 50]);

  var s := TSlice<Integer>.From(list, 1, 3);

  list.DeleteRange(2, 3); // list becomes [10, 20], slice Count becomes 1

  var seq := s.ToSequence;
  var r := seq.ToArray;

  Assert.AreEqual(1, Length(r));
  Assert.AreEqual(20, r[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.Sort_Should_Sort_Currently_Accessible_Items;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 40, 20, 30, 50]);

  var s := TSlice<Integer>.From(list, 1, 3);

  var n := s.Sort;

  Assert.AreEqual(3, n);

  Assert.AreEqual(10, list[0]);
  Assert.AreEqual(20, list[1]);
  Assert.AreEqual(30, list[2]);
  Assert.AreEqual(40, list[3]);
  Assert.AreEqual(50, list[4]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.Sort_Should_Only_Sort_Currently_Accessible_Items;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 40, 20, 30, 50]);

  var s := TSlice<Integer>.From(list, 1, 3);

  list.DeleteRange(2, 3); // list becomes [10, 40], slice Count becomes 1

  var n := s.Sort;

  Assert.AreEqual(1, n);

  Assert.AreEqual(10, list[0]);
  Assert.AreEqual(40, list[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.Reverse_Should_Reverse_Currently_Accessible_Items;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 20, 30, 40, 50]);

  var s := TSlice<Integer>.From(list, 1, 3);

  var n := s.Reverse;

  Assert.AreEqual(3, n);

  Assert.AreEqual(10, list[0]);
  Assert.AreEqual(40, list[1]);
  Assert.AreEqual(30, list[2]);
  Assert.AreEqual(20, list[3]);
  Assert.AreEqual(50, list[4]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.Reverse_Should_Only_Reverse_Currently_Accessible_Items;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 20, 30, 40, 50]);

  var s := TSlice<Integer>.From(list, 1, 3);

  list.DeleteRange(2, 3); // list becomes [10, 20], slice Count becomes 1

  var n := s.Reverse;

  Assert.AreEqual(1, n);

  Assert.AreEqual(10, list[0]);
  Assert.AreEqual(20, list[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.Fill_Should_Overwrite_Currently_Accessible_Items_Only;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 20, 30, 40, 50]);

  var s := TSlice<Integer>.From(list, 1, 3);

  var n := s.Fill(99);

  Assert.AreEqual(3, n);

  Assert.AreEqual(10, list[0]);
  Assert.AreEqual(99, list[1]);
  Assert.AreEqual(99, list[2]);
  Assert.AreEqual(99, list[3]);
  Assert.AreEqual(50, list[4]);

  list.DeleteRange(2, 3);

  n := s.Fill(99);

  Assert.AreEqual(1, n);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.TryPut_Should_Update_Source_Item_Within_Current_Accessible_Range;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 20, 30, 40, 50]);

  var s := TSlice<Integer>.From(list, 1, 3);

  Assert.IsTrue(s.TryPut(1, 99));

  Assert.AreEqual(10, list[0]);
  Assert.AreEqual(20, list[1]);
  Assert.AreEqual(99, list[2]);
  Assert.AreEqual(40, list[3]);
  Assert.AreEqual(50, list[4]);

  Assert.AreEqual(20, s[0]);
  Assert.AreEqual(99, s[1]);
  Assert.AreEqual(40, s[2]);

  list.Clear;

  Assert.IsFalse(s.TryPut(1, 99));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TSliceFixture.From_Should_Set_Low_High_Length_And_Count;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 20, 30, 40, 50]);

  var s := TSlice<Integer>.From(list, 1, 3);

  Assert.AreEqual(1, s.Low);
  Assert.AreEqual(3, s.High);
  Assert.AreEqual(3, s.Length);
  Assert.AreEqual(3, s.Count);
  Assert.IsFalse(s.IsEmpty);

  Assert.AreEqual(20, s[0]);
  Assert.AreEqual(30, s[1]);
  Assert.AreEqual(40, s[2]);

  list.DeleteRange(2, 3);

  Assert.AreEqual(1, s.Low);
  Assert.AreEqual(3, s.High);
  Assert.AreEqual(3, s.Length);
  Assert.AreEqual(1, s.Count);
  Assert.IsFalse(s.IsEmpty);

  list.Clear;

  Assert.AreEqual(1, s.Low);
  Assert.AreEqual(3, s.High);
  Assert.AreEqual(3, s.Length);
  Assert.AreEqual(0, s.Count);
  Assert.IsTrue(s.IsEmpty);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.From_Should_Ingest_Sequence_And_Allow_Further_Processing;
begin
  var seq := TSequence<Integer>.From([1, 2, 3, 4, 5, 6]);

  var r := Stream.From<integer>(seq)
                 .Filter(
                   function(const aValue: Integer): Boolean
                   begin
                     Result := (aValue mod 2) = 0;
                   end)
                 .AsArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(2, r[0]);
  Assert.AreEqual(4, r[1]);
  Assert.AreEqual(6, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Subtract_Should_Remove_Items_Present_In_Other_Source;
begin
  var r := Stream.From<Integer>([1, 2, 3, 4, 5])
                 .Subtract([2, 4])
                 .AsArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(3, r[1]);
  Assert.AreEqual(5, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Union_Should_Combine_Stream_And_Other_Source_Without_Duplicates;
begin
  var r := Stream.From<Integer>([1, 2, 2, 3])
                 .Union([2, 3, 4, 4, 5])
                 .AsArray;

  Assert.AreEqual(5, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
  Assert.AreEqual(5, r[4]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Intersect_Should_Keep_Items_Present_In_Other_Source;
begin
  var r := Stream.From<Integer>([1, 2, 3, 4, 5])
                 .Intersect([2, 4, 6])
                 .AsArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(2, r[0]);
  Assert.AreEqual(4, r[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.SymmetricDifference_Should_Keep_Items_Present_In_Only_One_Source;
begin
  var r := Stream.From<Integer>([1, 2, 2, 3])
                 .SymmetricDifference([2, 3, 4, 4, 5])
                 .AsArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(4, r[1]);
  Assert.AreEqual(5, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.CountBy_Works;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<string>.Create(['a','b','a','c','b','a']));

  var dict := Stream
    .From<string>(src)
    .CountBy<string>(function(const s: string): string begin Result := s; end);

  scope.Owns(dict);

  Assert.IsTrue(dict.ContainsKey('a'));
  Assert.IsTrue(dict.ContainsKey('b'));
  Assert.IsTrue(dict.ContainsKey('c'));

  Assert.AreEqual(3, dict['a']);
  Assert.AreEqual(2, dict['b']);
  Assert.AreEqual(1, dict['c']);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.FlatMap_Works;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1,2,3]));

  var dst := Stream
      .From<Integer>(src)
      .FlatMap<Integer>(
        function(const n: Integer): TList<Integer>
        begin
          Result := TList<Integer>.Create;
          Result.Add(n);
          Result.Add(n * 10);
        end)
      .AsArray;

  Assert.AreEqual(6, Length(dst));

  Assert.AreEqual(1,  dst[0]);
  Assert.AreEqual(10, dst[1]);
  Assert.AreEqual(2,  dst[2]);
  Assert.AreEqual(20, dst[3]);
  Assert.AreEqual(3,  dst[4]);
  Assert.AreEqual(30, dst[5]);
end;


{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.DistinctBy_Works;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<string>.Create(['a', 'A', 'b', 'B', 'a']));

  var dst := Stream
      .From<string>(src)
      .DistinctBy<string>(function(const s: string): string begin Result := s.ToLower; end)
      .AsArray;

  Assert.AreEqual(2, Length(dst));
  Assert.AreEqual('a', dst[0]);
  Assert.AreEqual('b', dst[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.All_Specification_Works;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1,3,5]));

  var spec := TSpecification<Integer>.FromPredicate(
    function(const n: Integer): Boolean
    begin
      Result := Odd(n);
    end
  );

  Assert.IsTrue(Stream.From<Integer>(src).All(spec));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Any_Specification_Works;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([2,4,6,7]));

  var spec := TSpecification<Integer>.FromPredicate(
    function(const n: Integer): Boolean
    begin
      Result := Odd(n);
    end
  );

  Assert.IsTrue(Stream.From<Integer>(src).Any(spec));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Partition_Specification_Works;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1,2,3,4,5]));

  var spec := TSpecification<Integer>.FromPredicate(
    function(const n: Integer): Boolean
    begin
      Result := Odd(n);
    end
  );

  var pair := Stream.From<Integer>(src).Partition(spec);

  var odds := scope.Owns(pair.Key);
  var evens := scope.Owns(pair.Value);

  Assert.AreEqual(3, odds.Count);
  Assert.AreEqual(1, odds[0]);
  Assert.AreEqual(3, odds[1]);
  Assert.AreEqual(5, odds[2]);

  Assert.AreEqual(2, evens.Count);
  Assert.AreEqual(2, evens[0]);
  Assert.AreEqual(4, evens[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Filter_Specification_Works;
var
  scope: TScope;
begin
  var src := scope.Owns(TList<Integer>.Create([1,2,3,4,5]));

  var spec := TSpecification<Integer>.FromPredicate(
    function(const n: Integer): Boolean
    begin
      Result := Odd(n);
    end
  );

  var dst := scope.Owns(
    Stream.From<Integer>(src)
      .Filter(spec)
      .AsList
  );

  Assert.AreEqual(3, dst.Count);
  Assert.AreEqual(1, dst[0]);
  Assert.AreEqual(3, dst[1]);
  Assert.AreEqual(5, dst[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.From_TakesOwnership_AndFreesContainerOnTransform;
var
  scope: TScope;
begin
  var freed := false;

  var list := TFlagList.Create(@freed);

  list.AddRange([1,2,3,4]);

  var r := Stream
    .Consume<Integer>(list)
    .Filter(function(const x:TInt): Boolean begin Result := (x mod 2) = 0; end)
    .AsList;

  scope.Owns(r);

  Assert.IsTrue(freed, 'Expected original list container to be freed after first transform');

  Assert.AreEqual(2, r.Count);
  Assert.AreEqual(2, r[0]);
  Assert.AreEqual(4, r[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Map_Borrow_DoesNotFreeContainer;
var
  scope: TScope;
begin
  var freed := false;

  var list := scope.Owns(TFlagList.Create(@freed));

  list.AddRange([10, 20, 30]);

  var r := Stream
      .From<Integer>(list)
      .Map<TInt>(function(const X: TInt): TInt begin Result := X + 1; end)
      .AsList;

  scope.Owns(r);

  Assert.IsFalse(Freed, 'Borrowed list container must not be freed during Map');

  Assert.AreEqual(3, r.Count);
  Assert.AreEqual(11, r[0]);
  Assert.AreEqual(21, r[1]);
  Assert.AreEqual(31, r[2]);

  Assert.AreEqual(3, list.Count);
  Assert.AreEqual(10, list[0]);
  Assert.AreEqual(20, list[1]);
  Assert.AreEqual(30, list[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Map_From_TakesOwnership_AndFreesContainer;
var
  scope: TScope;
begin
  var freed := false;

  var list := TFlagList.Create(@freed);

  list.AddRange([1, 2, 3]);

  var r := Stream
    .Consume<Integer>(list)
    .Map<string>(function(const X: TInt): string begin Result := 'v' + X.ToString; end)
    .AsList;

  scope.Owns(r);

  Assert.IsTrue(freed, 'Expected original list container to be freed during Map');

  Assert.AreEqual(3, r.Count);
  Assert.AreEqual('v1', r[0]);
  Assert.AreEqual('v2', r[1]);
  Assert.AreEqual('v3', r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Distinct_PreservesFirstOccurrenceOrder;
begin
  var r := Stream.From<Integer>([3, 1, 3, 2, 1, 2, 4]).Distinct.AsList;
  try
    Assert.AreEqual(4, r.Count);
    Assert.AreEqual(3, r[0]);
    Assert.AreEqual(1, r[1]);
    Assert.AreEqual(2, r[2]);
    Assert.AreEqual(4, r[3]);
  finally
    r.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Borrow_DoesNotFreeContainerOnTransform;
var
  scope: TScope;
begin
  var freed := false;

  var list := scope.Owns(TFlagList.Create(@freed));

  list.AddRange([1,2,3,4]);

  var r := Stream
      .From<Integer>(list)
      .Filter(function(const x: TInt): Boolean begin Result := x > 2;end)
      .AsList;

  scope.Owns(r);

  Assert.IsFalse(Freed, 'Borrowed list container must not be freed by Stream');

  Assert.AreEqual(2, r.Count);
  Assert.AreEqual(3, r[0]);
  Assert.AreEqual(4, r[1]);

  Assert.AreEqual(4, list.Count);
  Assert.AreEqual(1, list[0]);
  Assert.AreEqual(2, list[1]);
  Assert.AreEqual(3, list[2]);
  Assert.AreEqual(4, list[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.AsList_Borrowed_ClonesAndDoesNotTouchOriginal;
var
  scope: TScope;
begin
  var list := scope.Owns(TList<Integer>.Create);

  list.AddRange([10, 20, 30]);

  var r := scope.Owns(Stream.From<Integer>(list).AsList);

  Assert.IsTrue(r <> list, 'Borrowed AsList must return a clone');

  Assert.AreEqual(3, r.Count);
  Assert.AreEqual(10, r[0]);
  Assert.AreEqual(20, r[1]);
  Assert.AreEqual(30, r[2]);

  r.Add(40);

  Assert.AreEqual(3, list.Count);
  Assert.AreEqual(4, r.Count);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.AsList_Owned_DetachesSameInstance;
var
  scope: TScope;
begin
  var list := TList<Integer>.Create;

  list.AddRange([1,2,3]);

  var r := scope.Owns(Stream.Consume<Integer>(list).AsList);

  Assert.AreSame(list, R);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.ComparersAndEquality;
var
  scope: TScope;
begin
  var l1 := scope.Owns(Stream
    .From<string>(['A', 'a', 'B', 'b', 'B'])
    .Distinct(Equality.StringIgnoreCase)
    .AsList);

  Assert.AreEqual(2, l1.Count);
  Assert.AreEqual('A', l1[0]);
  Assert.AreEqual('B', l1[1]);

  var l2 := scope.Owns(Stream
    .From<Integer>([3, 1, 2, 2])
    .Sort(Comparers.Descending<Integer>)
    .AsList);

  Assert.AreEqual(4, l2.Count);
  Assert.AreEqual(3, l2[0]);
  Assert.AreEqual(2, l2[1]);
  Assert.AreEqual(2, l2[2]);
  Assert.AreEqual(1, l2[3]);

  var l3 := scope.Owns(Stream
    .From<string>(['b', 'A', 'a', 'C'])
    .Sort(Comparers.Descending<string>(Comparers.StringIgnoreCase))
    .AsList);

  Assert.AreEqual(4, l3.Count);
  Assert.AreEqual('C', l3[0]);
  Assert.AreEqual('b', l3[1]);
  Assert.IsTrue((l3[2] = 'A') or (l3[2] = 'a'));
  Assert.IsTrue((l3[3] = 'A') or (l3[3] = 'a'));
  Assert.AreEqual(l3[2], l3[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Count_From_FreesOwnedContainer;
begin
  var freed := false;

  var lList := TFlagList.Create(@Freed);
  lList.AddRange([1, 2, 3]);

  var n := Stream.Consume<Integer>(lList).Count;

  Assert.AreEqual(3, n);
  Assert.IsTrue(Freed, 'Expected owned list container to be freed by Count terminal');
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Count_Borrow_DoesNotFreeContainer;
var
  scope: TScope;
begin
  var freed := False;

  var lList := scope.Owns(TFlagList.Create(@Freed));

  lList.AddRange([1, 2, 3]);

  var n := Stream.From<Integer>(lList).Count;

  Assert.AreEqual(3, n);
  Assert.IsFalse(Freed, 'Borrowed list container must not be freed by Count terminal');

  Assert.AreEqual(3, lList.Count);
  Assert.AreEqual(1, lList[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Any_ShortCircuits;
begin
  var calls := 0;

  var found := Stream
    .From<Integer>([1, 2, 3, 4, 5])
    .Any(function(const X: TInt): Boolean begin Inc(calls); Result := X = 3; end);

  Assert.IsTrue(found);

  Assert.AreEqual(3, calls);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Any_Borrow_DoesNotFreeContainer;
var
  scope: TScope;
begin
  var freed := False;

  var lList := scope.Owns(TFlagList.Create(@Freed));

  lList.AddRange([1, 2, 3]);

  var found := Stream
    .From<Integer>(lList)
    .Any(function(const X: TInt): Boolean begin Result := X = 2; end);

  Assert.IsTrue(found);
  Assert.IsFalse(freed, 'Borrowed list container must not be freed by Any terminal');

  Assert.AreEqual(3, lList.Count);
  Assert.AreEqual(1, lList[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.All_ShortCircuitsOnFirstFailure;
begin
  var calls := 0;

  var ok := Stream
    .From<Integer>([2, 4, 6, 7, 8])
    .All(function(const X: TInt): Boolean begin Inc(Calls); Result := (X mod 2) = 0; end);

  Assert.IsFalse(Ok);
  Assert.AreEqual(4, Calls);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.All_Empty_ReturnsTrue;
begin
  var list := TList<Integer>.Create;

  var ok := Stream
    .Consume<Integer>(list)
    .All(function(const X: TInt): Boolean begin Result := X > 0; end);

  Assert.IsTrue(Ok);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Reduce_FoldsLeft_FromSeed;
begin
  var sum := Stream
    .From<Integer>([1, 2, 3])
    .Reduce<Integer>(10, function(const Acc, N: TInt): TInt begin Result := Acc + N; end);

  Assert.AreEqual(16, Sum);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Reduce_Empty_ReturnsSeed;
begin
  var lList := TList<Integer>.Create;

  var r := Stream
    .Consume<Integer>(lList)
    .Reduce<Integer>(42, function(const Acc, N: TInt): TInt begin Result := Acc + N; end);

  Assert.AreEqual(42, r);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.AsArray_PreservesOrder;
begin
  var a := Stream.From<Integer>([5, 2, 9]).AsArray;

  Assert.AreEqual(3, Length(a));
  Assert.AreEqual(5, a[0]);
  Assert.AreEqual(2, a[1]);
  Assert.AreEqual(9, a[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.AsArray_Borrow_DoesNotFreeContainer;
var
  scope: TScope;
begin
  var freed := False;

  var list := scope.Owns(TFlagList.Create(@Freed));

  list.AddRange([1, 2, 3]);

  var a := Stream.From<Integer>(list).AsArray;

  Assert.AreEqual(3, Length(a));
  Assert.AreEqual(1, a[0]);
  Assert.AreEqual(2, a[1]);
  Assert.AreEqual(3, a[2]);

  Assert.IsFalse(freed, 'Borrowed list container must not be freed by AsArray terminal');
  Assert.AreEqual(3, list.Count);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.ForEach_VisitsItemsInOrder_AndConsumes;
var
  scope: TScope;
begin
  var seen := scope.Owns(TList<Integer>.Create);

  Stream
    .From<Integer>([3, 1, 4])
    .ForEach(procedure(const x: TInt) begin Seen.Add(x); end);

  Assert.AreEqual(3, seen.Count);
  Assert.AreEqual(3, seen[0]);
  Assert.AreEqual(1, seen[1]);
  Assert.AreEqual(4, seen[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.FirstOrDefault_Empty_ReturnsDefault;
begin
  var list := TList<Integer>.Create;
  var val  := Stream.Consume<Integer>(list).FirstOrDefault;

  Assert.AreEqual(0, val);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.LastOrDefault_NonEmpty_ReturnsLast;
begin
  var v := Stream.From<Integer>([5, 9, 1]).LastOrDefault;
  Assert.AreEqual(1, v);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.LastOrDefault_Empty_ReturnsDefault;
begin
  var l := TList<Integer>.Create;
  var v := Stream.Consume<Integer>(l).LastOrDefault;
  Assert.AreEqual(0, v);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Reverse_ReversesOrder;
begin
  var r := Stream.From<Integer>([1, 2, 3, 4]).Reverse.AsArray;

  Assert.AreEqual(4, Length(r));
  Assert.AreEqual(4, r[0]);
  Assert.AreEqual(3, r[1]);
  Assert.AreEqual(2, r[2]);
  Assert.AreEqual(1, r[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Concat_Array_AppendsInOrder;
begin
  var r := Stream.From<Integer>([1, 2]).Concat([3, 4]).AsArray;

  Assert.AreEqual(4, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Concat_List_AppendsInOrder;
var
  scope: TScope;
begin
  var extra := scope.Owns(TList<Integer>.Create);

  extra.AddRange([3, 4]);

  var r := Stream.From<Integer>([1, 2]).Concat(Extra).AsArray;

  Assert.AreEqual(4, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Concat_Enumerator_AppendsInOrder;
var
  scope: TScope;
begin
  var extra := scope.Owns(TList<Integer>.Create);

  extra.AddRange([3, 4]);

  var e := Extra.GetEnumerator;
  var r := Stream.From<Integer>([1, 2]).Concat(E).AsArray;

  Assert.AreEqual(4, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Concat_List_OwnsListTrue_FreesSourceContainer;
begin
  var freed := false;
  var extra := TFlagList.Create(@freed);

  extra.AddRange([3, 4]);

  var r := Stream.From<Integer>([1, 2]).Concat(TSource<Integer>.Consume(extra)).AsArray;

  Assert.IsTrue(freed, 'Expected concat source list container to be freed when OwnsList=True');
  Assert.AreEqual(4, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
  Assert.AreEqual(4, r[3]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Take_Basic_KeepsFirstN;
begin
  var r := Stream.From<Integer>([1, 2, 3, 4, 5]).Take(3).AsArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Take_OnDiscard_Owned_CallsForDroppedItems;
var
  scope: TScope;
begin
  var dropped := scope.Owns(TList<Integer>.Create);

  var r := Stream
    .From<Integer>([1, 2, 3, 4, 5])
    .Take(2, procedure(const x: TInt) begin Dropped.Add(x); end).AsArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);

  Assert.AreEqual(3, dropped.Count);
  Assert.AreEqual(3, dropped[0]);
  Assert.AreEqual(4, dropped[1]);
  Assert.AreEqual(5, dropped[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Skip_Basic_SkipsFirstN;
begin
  var r := Stream.From<Integer>([1, 2, 3, 4, 5]).Skip(2).AsArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(3, r[0]);
  Assert.AreEqual(4, r[1]);
  Assert.AreEqual(5, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Skip_OnDiscard_Owned_CallsForDroppedItems;
var
  scope: TScope;
begin
  var dropped := scope.Owns(TList<Integer>.Create);

  var r := Stream
    .From<Integer>([1, 2, 3, 4, 5])
    .Skip(3, procedure(const x: TInt) begin dropped.Add(x); end)
    .AsArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(4, r[0]);
  Assert.AreEqual(5, r[1]);

  Assert.AreEqual(3, dropped.Count);
  Assert.AreEqual(1, dropped[0]);
  Assert.AreEqual(2, dropped[1]);
  Assert.AreEqual(3, dropped[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.SkipWhile_SkipsLeadingMatchesOnly;
begin
  var r := Stream
    .From<Integer>([1, 2, 3, 1, 4])
    .SkipWhile(function(const x: TInt): Boolean begin Result := x < 3; end)
    .AsArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(3, r[0]);
  Assert.AreEqual(1, r[1]);
  Assert.AreEqual(4, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.SkipWhile_OnDiscard_Owned_CallsForSkippedItems;
var
  scope: TScope;
begin
  var dropped := scope.Owns(TList<Integer>.Create);

  var r := Stream
      .From<Integer>([1, 2, 3, 4])
      .SkipWhile(
          function(const x: TInt): Boolean begin Result := x < 3; end,
          procedure(const X: TInt) begin dropped.Add(x); end)
      .AsArray;

  Assert.AreEqual(2, Length(R));
  Assert.AreEqual(3, r[0]);
  Assert.AreEqual(4, r[1]);

  Assert.AreEqual(2, dropped.Count);
  Assert.AreEqual(1, dropped[0]);
  Assert.AreEqual(2, dropped[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.SkipLast_Basic_DropsLastN;
begin
  var r := Stream.From<Integer>([1, 2, 3, 4, 5]).SkipLast(2).AsArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.SkipLast_OnDiscard_Owned_CallsForDiscardedSuffix;
var
  scope: TScope;
begin
  var dropped := scope.Owns(TList<Integer>.Create);

  var r := Stream
    .From<Integer>([1, 2, 3, 4, 5])
    .SkipLast(2, procedure(const x: TInt) begin dropped.Add(x); end)
    .AsArray;

  Assert.AreEqual(3, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
  Assert.AreEqual(3, r[2]);

  Assert.AreEqual(2, Dropped.Count);
  Assert.AreEqual(4, Dropped[0]);
  Assert.AreEqual(5, Dropped[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.TakeWhile_TakesLeadingMatchesOnly;
begin
  var r := Stream
    .From<Integer>([1, 2, 3, 1, 4])
    .TakeWhile(function(const x: TInt): Boolean begin Result := x < 3;end)
    .AsArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.TakeWhile_OnDiscard_Owned_CallsForDiscardedItems;
var
  scope: TScope;
begin
  var dropped := scope.Owns(TList<Integer>.Create);

  var r := Stream
      .From<Integer>([1, 2, 3, 4])
      .TakeWhile(
          function(const x: TInt): Boolean begin Result := x < 3; end,
          procedure(const x: TInt) begin dropped.Add(x); end)
      .AsArray;

  Assert.AreEqual(2, Length(R));
  Assert.AreEqual(1, r[0]);
  Assert.AreEqual(2, r[1]);

  Assert.AreEqual(2, dropped.Count);
  Assert.AreEqual(3, dropped[0]);
  Assert.AreEqual(4, dropped[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.TakeLast_Basic_KeepsLastN;
begin
  var r := Stream.From<Integer>([1, 2, 3, 4, 5]).TakeLast(2).AsArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(4, r[0]);
  Assert.AreEqual(5, r[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.TakeLast_OnDiscard_Owned_CallsForDiscardedPrefix;
var
  scope: TScope;
begin
  var dropped := scope.Owns(TList<Integer>.Create);

  var r := Stream
      .From<Integer>([1, 2, 3, 4, 5])
      .TakeLast(2, procedure(const x: Integer) begin dropped.Add(X); end)
      .AsArray;

  Assert.AreEqual(2, Length(r));
  Assert.AreEqual(4, r[0]);
  Assert.AreEqual(5, r[1]);

  Assert.AreEqual(3, dropped.Count);
  Assert.AreEqual(1, dropped[0]);
  Assert.AreEqual(2, dropped[1]);
  Assert.AreEqual(3, dropped[2]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Peek_VisitsItemsInOrder_AndDoesNotConsume;
var
  scope: TScope;
begin
  var seen := scope.Owns(TList<Integer>.Create);

  var r := Stream
        .From<Integer>([3, 1, 4])
        .Peek(procedure(const idx, x: TInt) begin seen.Add(x); end)
        .Count;

  Assert.AreEqual(3, seen.Count);
  Assert.AreEqual(3, seen[0]);
  Assert.AreEqual(1, seen[1]);
  Assert.AreEqual(4, seen[2]);

  Assert.AreEqual(3, r);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Map_Same_Allows_Transforms;
begin
  var r := Stream
        .From<string>([' HI', 'hI ', ' hi ', 'Hi'])
        .Map(function(const s: string):string begin Result := s.Trim.ToLower; end)
        .Distinct
        .AsArray;

  Assert.AreEqual(1, Length(r));
  Assert.AreEqual('hi', r[0]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.IsEmpty_Works;
begin
  Assert.IsTrue(Stream.From<Integer>([]).IsEmpty);
  Assert.IsFalse(Stream.From<Integer>([1]).IsEmpty);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.None_Works;
begin
  Assert.IsTrue(Stream
    .From<Integer>([1, 3, 5])
    .None(function(const x: TInt): Boolean begin Result := x mod 2 = 0; end));

  Assert.IsFalse(Stream
    .From<Integer>([1, 2, 3])
    .None(function(const x: TInt): Boolean begin Result := X mod 2 = 0; end));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Contains_DefaultEquality_Works;
begin
  Assert.IsTrue(Stream.From<Integer>([1, 2, 3]).Contains(2));
  Assert.IsFalse(Stream.From<Integer>([1, 2, 3]).Contains(4));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Terminal_Consumes_Stream_Guard;
begin
  var p := Stream.From<Integer>([1, 2, 3]);
  var q := p;
  var n := p.Count;

  Assert.AreEqual(3, n);

  Assert.WillRaise(
    procedure begin q.Filter(function(const x: TInt): Boolean begin Result := x > 0; end); end,
    EArgumentException);

  Assert.WillRaise(
    procedure begin q.AsList.Free; end,
    EArgumentException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Contains_CustomEquality_Works;
begin
  Assert.IsTrue(Stream.From<string>(['A', 'b']).Contains('a', Equality.StringIgnoreCase));
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Zip_List_ZipsToMinLength;
var
  scope: TScope;
begin
  var other := scope.Owns(TList<Integer>.Create);

  other.AddRange([10, 20]);

  var r := Stream
    .From<Integer>([1, 2, 3])
    .Zip<Integer, string>(
        other,
        function(const idx, a, b: TInt): string begin Result := a.ToString + ':' + b.ToString; end)
    .AsArray;

    Assert.AreEqual(2, Length(r));
    Assert.AreEqual('1:10', r[0]);
    Assert.AreEqual('2:20', r[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Zip_List_ZipsToMinLength_WithConstArray;
begin
  var r := Stream
    .From<Integer>([1, 2, 3])
    .Zip<Integer, string>(
        [10, 20],
        function(const idx, a, b: TInt): string begin Result := a.ToString + ':' + b.ToString; end)
    .AsArray;

    Assert.AreEqual(2, Length(r));
    Assert.AreEqual('1:10', r[0]);
    Assert.AreEqual('2:20', r[1]);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Transform_Exception_FreesOwnedBuffer_AndPoisonsStream;
begin
  var freed := False;

  // Owned list container (Stream.From takes ownership of the list)
  var l := TFlagList.Create(@freed);
  l.AddRange([1, 2, 3]);

  var p := Stream.Consume<Integer>(l);
  var q := p; // copy intentional for test: shared internal state

  // Map throws on the second element
  Assert.WillRaise(
    procedure
    begin
      p.Map<Integer>(
        function(const x: Integer): Integer
        begin
          if x = 2 then
            raise Exception.Create('boom');
          Result := x;
        end);
    end,
    Exception);

  // The owned buffer must be freed even though no terminal ran
  Assert.IsTrue(freed, 'Expected owned buffer to be freed when transform raises');

  // Stream should be poisoned/consumed after a failed transform
  Assert.WillRaise(
    procedure
    begin
      q.Count;
    end,
    EArgumentException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.GroupBy_GroupsAndPreservesOrder;
begin
  var groups := Stream
      .From<Integer>([1, 2, 3, 4, 5, 6])
      .GroupBy<TInt>(function(const X: TInt): TInt begin Result := x mod 2; end);

  try
    Assert.IsTrue(groups.ContainsKey(0));
    Assert.IsTrue(groups.ContainsKey(1));

    Assert.AreEqual(3, groups[0].Count);
    Assert.AreEqual(2, groups[0][0]);
    Assert.AreEqual(4, groups[0][1]);
    Assert.AreEqual(6, groups[0][2]);

    Assert.AreEqual(3, groups[1].Count);
    Assert.AreEqual(1, groups[1][0]);
    Assert.AreEqual(3, groups[1][1]);
    Assert.AreEqual(5, groups[1][2]);
  finally
    for var list in groups.Values do
      list.Free;

    groups.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.GroupBy_UsesCustomEqualityComparer;
begin
  var eq := TEqualityComparer<string>.Construct(
    function(const L, R: string): Boolean
    begin
      Result := SameText(L, R);
    end,
    function(const S: string): Integer
    begin
      Result := THashBobJenkins.GetHashValue(PChar(AnsiLowerCase(S))^, Length(S) * SizeOf(Char), 0);
    end
  );

  var groups := Stream
    .From<string>(['A', 'a', 'B'])
    .GroupBy<string>(function(const S: string): string begin Result := S; end, eq);

  try
    Assert.AreEqual(2, groups.Count);

    var hasA := False;

    for var key in groups.Keys do
      if SameText(key, 'a') then
      begin
        hasA := true;

        Assert.AreEqual(2, groups[key].Count);
        Assert.AreEqual('A', groups[key][0]);
        Assert.AreEqual('a', groups[key][1]);
      end;
    Assert.IsTrue(hasA);
  finally
    for var list in groups.Values do
      list.Free;

    groups.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.GroupBy_ConsumesStream_Guard;
begin
  var p := Stream.From<Integer>([1, 2, 3]);
  var q := p;
  var g := p.GroupBy<TInt>(function(const x: TInt): TInt begin Result := x mod 2; end);

  try
    // ok
  finally
    for var l in g.Values do
      l.Free;

    g.Free;
  end;

  Assert.WillRaise(procedure begin Q.Count; end, EArgumentException);
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.Partition_SplitsIntoMatchingAndNonMatching;
begin
  var p := Stream
    .From<Integer>([1, 2, 3, 4, 5])
    .Partition(function(const x: TInt): boolean begin Result := (x mod 2) = 0; end);

  try
    // Matching (even)
    Assert.AreEqual(2, P.Key.Count);
    Assert.AreEqual(2, P.Key[0]);
    Assert.AreEqual(4, P.Key[1]);

    // Non-matching (odd)
    Assert.AreEqual(3, P.Value.Count);
    Assert.AreEqual(1, P.Value[0]);
    Assert.AreEqual(3, P.Value[1]);
    Assert.AreEqual(5, P.Value[2]);
  finally
    p.Key.Free;
    p.Value.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
procedure TStreamFixture.SplitAt_SplitsIntoPrefixAndSuffix(const aIndex:integer);
const
  ITEMS: array of integer = [0, 1, 2, 3, 4];
begin
  var p := Stream.From<Integer>(ITEMS).SplitAt(aIndex);
  try
    Assert.AreEqual(aIndex, p.Key.Count, Format('Left list should have %d items', [aIndex + 1]));

    for var i := 0 to Pred(aIndex) do
      Assert.AreEqual(i, p.Key[i]);

    var n := Length(ITEMS) - aIndex;

    Assert.AreEqual(n, p.Value.Count, Format('Right list should have %d items', [n]));

    for var i := 0 to Pred(p.Value.Count) do
      Assert.AreEqual(i + aIndex, p.Value[i]);
  finally
    P.Key.Free;
    P.Value.Free;
  end;
end;

{ TFlagList }

{----------------------------------------------------------------------------------------------------------------------}
constructor TFlagList.Create(AFlag: PBoolean);
begin
  inherited Create;
  FFlag := AFlag;
end;

{----------------------------------------------------------------------------------------------------------------------}
destructor TFlagList.Destroy;
begin
  if Assigned(FFlag) then
    FFlag^ := True;

  inherited;
end;

initialization
  TDUnitX.RegisterTestFixture(TStreamFixture);

end.
