--  Unit tests for Langchain4a.LLM.OpenRouter client (Build_Extra_Headers, Configure).

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

with Ada.Strings.Unbounded;

with Langchain4a.Core.Config;

package OpenRouter_Tests is

   type Test_Fixture is new AUnit.Test_Fixtures.Test_Fixture with record
      null;
   end record;

   overriding procedure Set_Up (T : in out Test_Fixture);
   overriding procedure Tear_Down (T : in out Test_Fixture);

   --  Build_Extra_Headers tests
   procedure Given_OpenRouterClient_When_SiteUrlAndAppNameSet_Then_RefererAndTitleHeadersReturned
     (T : in out Test_Fixture);
   procedure Given_OpenRouterClient_When_OnlySiteUrlSet_Then_RefererHeaderOnly
     (T : in out Test_Fixture);
   procedure Given_OpenRouterClient_When_OnlyAppNameSet_Then_TitleHeaderOnly
     (T : in out Test_Fixture);
   procedure Given_OpenRouterClient_When_NeitherFieldSet_Then_EmptyHeadersReturned
     (T : in out Test_Fixture);

   --  Configure tests
   procedure Given_OpenRouterClient_When_ConfigureCalled_Then_AllFieldsSetCorrectly
     (T : in out Test_Fixture);

   function Suite return AUnit.Test_Suites.Access_Test_Suite;

end OpenRouter_Tests;
