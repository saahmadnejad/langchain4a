--  Unit tests for Langchain4a.Memory conversation history.

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

with Ada.Characters.Latin_1;
with Ada.Strings.Unbounded;

with Langchain4a.Memory;

package body Memory_Tests is

   use AUnit.Assertions;
   use Langchain4a.Memory;

   package Caller is new AUnit.Test_Caller (Test_Fixture);

   overriding procedure Set_Up (T : in out Test_Fixture) is
      pragma Unreferenced (T);
   begin
      null;
   end Set_Up;

   overriding procedure Tear_Down (T : in out Test_Fixture) is
      pragma Unreferenced (T);
   begin
      null;
   end Tear_Down;

   --------------------------------------------------------------------------
   --  Add_Message / Count tests
   --------------------------------------------------------------------------

   procedure Given_EmptyStore_When_AddMessageCalled_Then_CountIsOne
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         M : Memory_Store;
      begin
         --  Act
         M.Add_Message ("user", "hello");
         --  Assert
         Assert (M.Count = 1, "Expected count of 1 after first message");
      end;
   end Given_EmptyStore_When_AddMessageCalled_Then_CountIsOne;

   procedure Given_StoreWithMessages_When_AddMessageCalled_Then_CountIncrements
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         M : Memory_Store;
      begin
         M.Add_Message ("user", "hello");
         M.Add_Message ("assistant", "hi there");
         --  Act
         M.Add_Message ("user", "goodbye");
         --  Assert
         Assert (M.Count = 3, "Expected count of 3 after three messages");
      end;
   end Given_StoreWithMessages_When_AddMessageCalled_Then_CountIncrements;

   --------------------------------------------------------------------------
   --  Get_History tests
   --------------------------------------------------------------------------

   procedure Given_StoreWithMessages_When_GetHistoryCalled_Then_RolePrefixedLinesReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         M : Memory_Store;
      begin
         M.Add_Message ("user", "hello");
         M.Add_Message ("assistant", "hi there");
         --  Act
         declare
            Result : constant String := M.Get_History;
         begin
            --  Assert
            Assert (Result = "user: hello" & Ada.Characters.Latin_1.LF & "assistant: hi there",
                    "Expected role-prefixed lines joined by LF");
         end;
      end;
   end Given_StoreWithMessages_When_GetHistoryCalled_Then_RolePrefixedLinesReturned;

   procedure Given_EmptyStore_When_GetHistoryCalled_Then_EmptyStringReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         M : Memory_Store;
      begin
         --  Act
         declare
            Result : constant String := M.Get_History;
         begin
            --  Assert
            Assert (Result = "", "Expected empty history for empty store");
         end;
      end;
   end Given_EmptyStore_When_GetHistoryCalled_Then_EmptyStringReturned;

   --------------------------------------------------------------------------
   --  Clear tests
   --------------------------------------------------------------------------

   procedure Given_StoreWithMessages_When_ClearCalled_Then_CountIsZero
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         M : Memory_Store;
      begin
         M.Add_Message ("user", "hello");
         M.Add_Message ("assistant", "hi");
         --  Act
         M.Clear;
         --  Assert
         Assert (M.Count = 0, "Expected count of 0 after Clear");
      end;
   end Given_StoreWithMessages_When_ClearCalled_Then_CountIsZero;

   --------------------------------------------------------------------------
   --  Role validation tests
   --------------------------------------------------------------------------

   procedure Given_InvalidRole_When_AddMessageCalled_Then_ConstraintErrorRaised
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         M : Memory_Store;
         Raised : Boolean := False;
      begin
         --  Act
         begin
            M.Add_Message ("assitant", "typo role");
         exception
            when Constraint_Error => Raised := True;
         end;
         --  Assert
         Assert (Raised, "Expected Constraint_Error for invalid role");
         Assert (M.Count = 0, "Expected no message stored on invalid role");
      end;
   end Given_InvalidRole_When_AddMessageCalled_Then_ConstraintErrorRaised;

   --------------------------------------------------------------------------
   --  Bounded-history tests
   --------------------------------------------------------------------------

   procedure Given_FullStore_When_AddMessageCalled_Then_OldestDropped
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         M : Memory_Store;
         Small_Max : constant := 3;
      begin
         M.Set_Max_Messages (Small_Max);
         M.Add_Message ("user", "one");
         M.Add_Message ("user", "two");
         M.Add_Message ("user", "three");
         --  Act
         M.Add_Message ("user", "four");
         --  Assert
         Assert (M.Count = Small_Max,
                 "Expected count capped at Max_Messages");
         Assert (M.Get_History = "user: two" & Ada.Characters.Latin_1.LF
                 & "user: three" & Ada.Characters.Latin_1.LF & "user: four",
                 "Expected oldest message dropped on overflow");
      end;
   end Given_FullStore_When_AddMessageCalled_Then_OldestDropped;

   procedure Given_StoreWithFiveMessages_When_MaxShrunkToTwo_Then_TwoNewestKept
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         M : Memory_Store;
      begin
         M.Add_Message ("user", "one");
         M.Add_Message ("user", "two");
         M.Add_Message ("user", "three");
         M.Add_Message ("user", "four");
         M.Add_Message ("user", "five");
         --  Act
         M.Set_Max_Messages (2);
         --  Assert
         Assert (M.Count = 2, "Expected count trimmed to new max");
         Assert (M.Get_History = "user: four" & Ada.Characters.Latin_1.LF
                 & "user: five",
                 "Expected two newest messages kept after shrink");
      end;
   end Given_StoreWithFiveMessages_When_MaxShrunkToTwo_Then_TwoNewestKept;

   --------------------------------------------------------------------------
   --  Suite
   --------------------------------------------------------------------------

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      S : constant AUnit.Test_Suites.Access_Test_Suite :=
            AUnit.Test_Suites.New_Suite;
   begin
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Add first message sets count to 1",
                           Given_EmptyStore_When_AddMessageCalled_Then_CountIsOne'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Add message increments count",
                           Given_StoreWithMessages_When_AddMessageCalled_Then_CountIncrements'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Get history returns role-prefixed lines",
                           Given_StoreWithMessages_When_GetHistoryCalled_Then_RolePrefixedLinesReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Get history on empty store returns empty",
                           Given_EmptyStore_When_GetHistoryCalled_Then_EmptyStringReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Clear resets count to zero",
                           Given_StoreWithMessages_When_ClearCalled_Then_CountIsZero'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Invalid role raises Constraint_Error",
                           Given_InvalidRole_When_AddMessageCalled_Then_ConstraintErrorRaised'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Overflow drops oldest message",
                           Given_FullStore_When_AddMessageCalled_Then_OldestDropped'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Shrinking max keeps newest messages",
                           Given_StoreWithFiveMessages_When_MaxShrunkToTwo_Then_TwoNewestKept'Access));
      return S;
   end Suite;

end Memory_Tests;
