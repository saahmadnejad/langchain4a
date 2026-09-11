--  Unit tests for Langchain4a.Memory conversation history.

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

with Langchain4a.Memory;

package Memory_Tests is

   type Test_Fixture is new AUnit.Test_Fixtures.Test_Fixture with record
      null;
   end record;

   overriding procedure Set_Up (T : in out Test_Fixture);
   overriding procedure Tear_Down (T : in out Test_Fixture);

   --  Add_Message / Count tests
   procedure Given_EmptyStore_When_AddMessageCalled_Then_CountIsOne
     (T : in out Test_Fixture);
   procedure Given_StoreWithMessages_When_AddMessageCalled_Then_CountIncrements
     (T : in out Test_Fixture);

   --  Get_History tests
   procedure Given_StoreWithMessages_When_GetHistoryCalled_Then_RolePrefixedLinesReturned
     (T : in out Test_Fixture);
   procedure Given_EmptyStore_When_GetHistoryCalled_Then_EmptyStringReturned
     (T : in out Test_Fixture);

   --  Clear tests
   procedure Given_StoreWithMessages_When_ClearCalled_Then_CountIsZero
     (T : in out Test_Fixture);

   --  Role validation tests
   procedure Given_InvalidRole_When_AddMessageCalled_Then_ConstraintErrorRaised
     (T : in out Test_Fixture);

   --  Bounded-history tests
   procedure Given_FullStore_When_AddMessageCalled_Then_OldestDropped
     (T : in out Test_Fixture);
   procedure Given_StoreWithFiveMessages_When_MaxShrunkToTwo_Then_TwoNewestKept
     (T : in out Test_Fixture);

   function Suite return AUnit.Test_Suites.Access_Test_Suite;

end Memory_Tests;
