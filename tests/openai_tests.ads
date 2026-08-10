--  Unit tests for Langchain4a.LLM.OpenAI base client (Configure, Toggle_Proxy, etc.).

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

with Ada.Strings.Unbounded;

with Langchain4a.LLM.OpenAI;

package OpenAI_Tests is

   type Test_Fixture is new AUnit.Test_Fixtures.Test_Fixture with record
      null;
   end record;

   overriding procedure Set_Up (T : in out Test_Fixture);
   overriding procedure Tear_Down (T : in out Test_Fixture);

   --  Build_Extra_Headers tests
   procedure Given_OpenAiBaseClient_When_NoExtraHeadersNeeded_Then_EmptyHeadersReturned
     (T : in out Test_Fixture);

   --  Configure tests
   procedure Given_OpenAiBaseClient_When_ConfigureCalled_Then_ClientConfiguredWithoutError
     (T : in out Test_Fixture);

   --  Toggle_Proxy tests
   procedure Given_OpenAiBaseClient_When_ToggleProxyOn_Then_NoExceptionRaised
     (T : in out Test_Fixture);
   procedure Given_OpenAiBaseClient_When_ToggleProxyOff_Then_NoExceptionRaised
     (T : in out Test_Fixture);

    --  Get_Response tests
    procedure Given_UnconfiguredOpenAiClient_When_GetResponseCalled_Then_EmptyResponseReturned
      (T : in out Test_Fixture);

    --  Build_Request_Body tests
    procedure Given_SimplePrompt_When_BuildRequestBodyCalled_Then_ValidJsonReturned
      (T : in out Test_Fixture);
    procedure Given_PromptWithDoubleQuote_When_BuildRequestBodyCalled_Then_QuoteEscaped
      (T : in out Test_Fixture);
    procedure Given_ZeroTemperature_When_BuildRequestBodyCalled_Then_TemperatureIncluded
      (T : in out Test_Fixture);

    --  Store_Response tests
    procedure Given_SuccessfulResponse_When_StoreResponseCalled_Then_ContentExtracted
      (T : in out Test_Fixture);
    procedure Given_ErrorResponse_When_StoreResponseCalled_Then_ErrorMessageStored
      (T : in out Test_Fixture);

   function Suite return AUnit.Test_Suites.Access_Test_Suite;

end OpenAI_Tests;
