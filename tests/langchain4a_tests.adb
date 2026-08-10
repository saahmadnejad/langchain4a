--  Unit tests for Langchain4a library lifecycle (Version, Initialize, Finalize).

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;

with Langchain4a;

package body Langchain4a_Tests is

   use AUnit.Assertions;

   package Caller is new AUnit.Test_Caller (Test_Fixture);

   overriding procedure Set_Up (T : in out Test_Fixture) is
      pragma Unreferenced (T);
   begin
      --  Arrange: ensure library is finalized before each test
      Langchain4a.Finalize;
   end Set_Up;

   overriding procedure Tear_Down (T : in out Test_Fixture) is
      pragma Unreferenced (T);
   begin
      --  Cleanup: ensure library is finalized after each test
      Langchain4a.Finalize;
   end Tear_Down;

   procedure Given_Library_When_VersionChecked_Then_CorrectVersionReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      --  Act
      --  Assert
      Assert (Langchain4a.Version = "0.1.0",
              "Library version should be 0.1.0");
   end Given_Library_When_VersionChecked_Then_CorrectVersionReturned;

   procedure Given_UninitializedLibrary_When_InitializeCalled_Then_NoExceptionRaised
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange (library finalized in Set_Up)
      --  Act
      Langchain4a.Initialize;
      --  Assert
      Assert (True, "Initialize should complete without raising");
   end Given_UninitializedLibrary_When_InitializeCalled_Then_NoExceptionRaised;

   procedure Given_InitializedLibrary_When_FinalizeCalled_Then_NoExceptionRaised
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      Langchain4a.Initialize;
      --  Act
      Langchain4a.Finalize;
      --  Assert
      Assert (True, "Finalize after Initialize should complete without raising");
   end Given_InitializedLibrary_When_FinalizeCalled_Then_NoExceptionRaised;

   procedure Given_FinalizedLibrary_When_FinalizeCalledAgain_Then_NoExceptionRaised
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      Langchain4a.Initialize;
      Langchain4a.Finalize;
      --  Act
      Langchain4a.Finalize;
      --  Assert
      Assert (True, "Double Finalize should complete without raising");
   end Given_FinalizedLibrary_When_FinalizeCalledAgain_Then_NoExceptionRaised;

   procedure Given_UninitializedLibrary_When_FinalizeCalled_Then_NoExceptionRaised
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange (library finalized in Set_Up)
      --  Act
      Langchain4a.Finalize;
      --  Assert
      Assert (True, "Finalize without prior Initialize should complete without raising");
   end Given_UninitializedLibrary_When_FinalizeCalled_Then_NoExceptionRaised;

   ----------
   --  Suite
   ----------

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      S : constant AUnit.Test_Suites.Access_Test_Suite :=
            AUnit.Test_Suites.New_Suite;
   begin
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Version constant matches",
                           Given_Library_When_VersionChecked_Then_CorrectVersionReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Initialize without prior Finalize",
                           Given_UninitializedLibrary_When_InitializeCalled_Then_NoExceptionRaised'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Finalize after Initialize",
                           Given_InitializedLibrary_When_FinalizeCalled_Then_NoExceptionRaised'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Double Finalize is safe",
                           Given_FinalizedLibrary_When_FinalizeCalledAgain_Then_NoExceptionRaised'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Finalize without prior Initialize",
                           Given_UninitializedLibrary_When_FinalizeCalled_Then_NoExceptionRaised'Access));
      return S;
   end Suite;

end Langchain4a_Tests;
