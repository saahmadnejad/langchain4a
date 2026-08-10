--  Unit tests for Langchain4a library lifecycle (Version, Initialize, Finalize).

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

with Langchain4a;

package Langchain4a_Tests is

   type Test_Fixture is new AUnit.Test_Fixtures.Test_Fixture with record
      null;
   end record;

   overriding procedure Set_Up (T : in out Test_Fixture);
   overriding procedure Tear_Down (T : in out Test_Fixture);

   procedure Given_Library_When_VersionChecked_Then_CorrectVersionReturned
     (T : in out Test_Fixture);
   procedure Given_UninitializedLibrary_When_InitializeCalled_Then_NoExceptionRaised
     (T : in out Test_Fixture);
   procedure Given_InitializedLibrary_When_FinalizeCalled_Then_NoExceptionRaised
     (T : in out Test_Fixture);
   procedure Given_FinalizedLibrary_When_FinalizeCalledAgain_Then_NoExceptionRaised
     (T : in out Test_Fixture);
   procedure Given_UninitializedLibrary_When_FinalizeCalled_Then_NoExceptionRaised
     (T : in out Test_Fixture);

   function Suite return AUnit.Test_Suites.Access_Test_Suite;

end Langchain4a_Tests;
