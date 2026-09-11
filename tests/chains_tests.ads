--  Unit tests for Langchain4a.Chains.Simple.

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

with Langchain4a.Core;
with Langchain4a.Chains.Simple;

package Chains_Tests is

   type Test_Fixture is new AUnit.Test_Fixtures.Test_Fixture with record
      null;
   end record;

   overriding procedure Set_Up (T : in out Test_Fixture);
   overriding procedure Tear_Down (T : in out Test_Fixture);

   --  Build_Prompt tests (no client needed)
   procedure Given_NoTemplateNoHistory_When_BuildPromptCalled_Then_InputOnlyReturned
     (T : in out Test_Fixture);
   procedure Given_TemplateSet_When_BuildPromptCalled_Then_TemplatePrepended
     (T : in out Test_Fixture);
   procedure Given_HistoryAndInput_When_BuildPromptCalled_Then_HistoryPrepended
     (T : in out Test_Fixture);
   procedure Given_TemplateAndHistory_When_BuildPromptCalled_Then_AllPartsJoinedByLF
     (T : in out Test_Fixture);

   --  Run tests (mock client)
   procedure Given_ConfiguredChain_When_RunCalled_Then_UserAndAssistantTurnsStored
     (T : in out Test_Fixture);
   procedure Given_RunCalled_When_RunCalledAgain_Then_HistoryFeedsSecondPrompt
     (T : in out Test_Fixture);
   procedure Given_UnconfiguredChain_When_RunCalled_Then_ConstraintErrorRaised
     (T : in out Test_Fixture);
   procedure Given_FailingClient_When_RunCalled_Then_HistoryUnchanged
     (T : in out Test_Fixture);

   function Suite return AUnit.Test_Suites.Access_Test_Suite;

end Chains_Tests;
