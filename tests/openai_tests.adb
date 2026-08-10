--  Unit tests for Langchain4a.LLM.OpenAI base client (Configure, Toggle_Proxy, etc.).

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;

with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Langchain4a.Net;
with Langchain4a.Core;
with Langchain4a.Core.Config;
with Langchain4a.LLM.OpenAI;

package body OpenAI_Tests is

   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use Langchain4a.Net;

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

   ----------
   --  Build_Extra_Headers tests
   ----------

   procedure Given_OpenAiBaseClient_When_NoExtraHeadersNeeded_Then_EmptyHeadersReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Client : Langchain4a.LLM.OpenAI.OpenAI_Client;
   begin
      --  Arrange
      --  Act
      declare
         Result : constant String :=
           Langchain4a.LLM.OpenAI.Build_Extra_Headers (Client);
      begin
         --  Assert
         Assert (Result = "",
                 "OpenAI base client should return empty extra headers");
      end;
   end Given_OpenAiBaseClient_When_NoExtraHeadersNeeded_Then_EmptyHeadersReturned;

   ----------
   --  Configure tests
   ----------

   procedure Given_OpenAiBaseClient_When_ConfigureCalled_Then_ClientConfiguredWithoutError
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Client : Langchain4a.LLM.OpenAI.OpenAI_Client;
      Cfg    : Langchain4a.Core.Config.OpenAI_Config;
   begin
      --  Arrange
      Cfg.API_Key := To_Unbounded_String ("sk-test-configure");
      Cfg.Endpoint := To_Unbounded_String ("https://configure-test.example.com");
      Cfg.Model := To_Unbounded_String ("gpt-4o");
      Cfg.Temperature := 0.3;
      Cfg.Max_Tokens := 7;

      --  Act
      Client.Configure (Cfg);

      --  Assert
      Assert (True, "Configure should complete without raising");
   end Given_OpenAiBaseClient_When_ConfigureCalled_Then_ClientConfiguredWithoutError;

   ----------
   --  Toggle_Proxy tests
   ----------

   procedure Given_OpenAiBaseClient_When_ToggleProxyOn_Then_NoExceptionRaised
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Client : Langchain4a.LLM.OpenAI.OpenAI_Client;
   begin
      --  Arrange
      --  Act
      Client.Toggle_Proxy (True);

      --  Assert
      Assert (True, "Toggle_Proxy(True) should complete without raising");
   end Given_OpenAiBaseClient_When_ToggleProxyOn_Then_NoExceptionRaised;

   procedure Given_OpenAiBaseClient_When_ToggleProxyOff_Then_NoExceptionRaised
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Client : Langchain4a.LLM.OpenAI.OpenAI_Client;
   begin
      --  Arrange
      --  Act
      Client.Toggle_Proxy (False);

      --  Assert
      Assert (True, "Toggle_Proxy(False) should complete without raising");
   end Given_OpenAiBaseClient_When_ToggleProxyOff_Then_NoExceptionRaised;

   ----------
   --  Get_Response tests
   ----------

   procedure Given_UnconfiguredOpenAiClient_When_GetResponseCalled_Then_EmptyResponseReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Client : Langchain4a.LLM.OpenAI.OpenAI_Client;
   begin
      --  Arrange
      --  Act
      declare
         Resp : constant Langchain4a.Core.LLM_Response := Client.Get_Response;
      begin
         --  Assert
         Assert (Resp.Text = Null_Unbounded_String,
                 "Initial response text should be empty");
         Assert (Resp.Tokens = 0,
                 "Initial response tokens should be 0");
      end;
    end Given_UnconfiguredOpenAiClient_When_GetResponseCalled_Then_EmptyResponseReturned;

    ----------
    --  Build_Request_Body tests
    ----------

    procedure Given_SimplePrompt_When_BuildRequestBodyCalled_Then_ValidJsonReturned
      (T : in out Test_Fixture)
    is
       pragma Unreferenced (T);
    begin
       --  Arrange
       declare
          Prompt : constant String := "Hello, world!";
          Model  : constant String := "gpt-4o";
          Temp   : constant Float := 0.7;
          Tokens : constant Natural := 100;
       begin
          --  Act
          declare
             Result : constant String :=
               Langchain4a.LLM.OpenAI.Build_Request_Body
                 (Prompt, Model, Temp, Tokens);
          begin
             --  Assert
         Assert (Ada.Strings.Fixed.Index (Result, "{""model"": ""gpt-4o""") > 0,
                 "Should contain model field, got: " & Result);
         Assert (Ada.Strings.Fixed.Index (Result, """content"": ""Hello, world!""") > 0,
                 "Should contain content field, got: " & Result);
          Assert (Ada.Strings.Fixed.Index (Result, """temperature"": 7.00000E-01") > 0,
                  "Should contain temperature in scientific notation, got: " & Result);
          Assert (Ada.Strings.Fixed.Index (Result, """max_tokens"":  100") > 0,
                  "Should contain max_tokens, got: " & Result);
          end;
       end;
    end Given_SimplePrompt_When_BuildRequestBodyCalled_Then_ValidJsonReturned;

    procedure Given_PromptWithDoubleQuote_When_BuildRequestBodyCalled_Then_QuoteEscaped
      (T : in out Test_Fixture)
    is
       pragma Unreferenced (T);
    begin
       --  Arrange
       declare
          Prompt : constant String := "Say ""hello""";
          Model  : constant String := "gpt-3.5-turbo";
          Temp   : constant Float := 0.0;
          Tokens : constant Natural := 512;
       begin
          --  Act
          declare
             Result : constant String :=
               Langchain4a.LLM.OpenAI.Build_Request_Body
                 (Prompt, Model, Temp, Tokens);
          begin
             --  Assert
         declare
            Escaped_Quote : constant String := '\' & '"';
         begin
            Assert (Ada.Strings.Fixed.Index (Result, Escaped_Quote) > 0,
                    "Double quote in prompt should be escaped with backslash");
         end;
          end;
       end;
    end Given_PromptWithDoubleQuote_When_BuildRequestBodyCalled_Then_QuoteEscaped;

    procedure Given_ZeroTemperature_When_BuildRequestBodyCalled_Then_TemperatureIncluded
      (T : in out Test_Fixture)
    is
       pragma Unreferenced (T);
    begin
       --  Arrange
       declare
          Prompt : constant String := "test";
       begin
          --  Act
          declare
             Result : constant String :=
               Langchain4a.LLM.OpenAI.Build_Request_Body
                 (Prompt, "gpt-4o", 0.0, 10);
          begin
             --  Assert
          Assert (Ada.Strings.Fixed.Index (Result, """temperature"": 0.00000E+00") > 0,
                  "Temperature 0.0 (scientific notation) should appear in JSON body, got: " & Result);
          end;
       end;
    end Given_ZeroTemperature_When_BuildRequestBodyCalled_Then_TemperatureIncluded;

    ----------
    --  Store_Response tests
    ----------

    procedure Given_SuccessfulResponse_When_StoreResponseCalled_Then_ContentExtracted
      (T : in out Test_Fixture)
    is
       pragma Unreferenced (T);
    begin
       --  Arrange
       declare
          JSON   : constant String :=
            "{""id"": ""abc123"", ""choices"": [{""message"": {""content"": ""Hello from AI""}}], ""usage"": {""total_tokens"": 42}}";
          Resp   : constant HTTP_Response :=
            (Status_Code => 200,
             Content     => To_Unbounded_String (JSON));
          Client : Langchain4a.LLM.OpenAI.OpenAI_Client;
       begin
          --  Act
          Langchain4a.LLM.OpenAI.Store_Response (Client, Resp);

          --  Assert
          declare
             Stored : constant Langchain4a.Core.LLM_Response :=
               Client.Get_Response;
          begin
             Assert (To_String (Stored.Text) = "Hello from AI",
                     "Content should be extracted from successful response");
             Assert (Stored.Tokens = 42,
                     "Total tokens should be extracted from successful response");
          end;
       end;
    end Given_SuccessfulResponse_When_StoreResponseCalled_Then_ContentExtracted;

    procedure Given_ErrorResponse_When_StoreResponseCalled_Then_ErrorMessageStored
      (T : in out Test_Fixture)
    is
       pragma Unreferenced (T);
    begin
       --  Arrange
       declare
          JSON   : constant String :=
            "{""message"": ""Invalid API key""}";
          Resp   : constant HTTP_Response :=
            (Status_Code => 401,
             Content     => To_Unbounded_String (JSON));
          Client : Langchain4a.LLM.OpenAI.OpenAI_Client;
       begin
          --  Act
          Langchain4a.LLM.OpenAI.Store_Response (Client, Resp);

          --  Assert
          declare
             Stored : constant Langchain4a.Core.LLM_Response :=
               Client.Get_Response;
          begin
             Assert (To_String (Stored.Text) = "Error: Invalid API key",
                     "Error message should be extracted from response");
             Assert (Stored.Tokens = 0,
                     "Tokens should be 0 for error response");
          end;
       end;
    end Given_ErrorResponse_When_StoreResponseCalled_Then_ErrorMessageStored;

   ----------
   --  Suite
   ----------

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      S : constant AUnit.Test_Suites.Access_Test_Suite :=
            AUnit.Test_Suites.New_Suite;
   begin
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("OpenAI base Build_Extra_Headers returns empty",
                           Given_OpenAiBaseClient_When_NoExtraHeadersNeeded_Then_EmptyHeadersReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("OpenAI Configure does not raise",
                           Given_OpenAiBaseClient_When_ConfigureCalled_Then_ClientConfiguredWithoutError'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("OpenAI Toggle_Proxy On does not raise",
                           Given_OpenAiBaseClient_When_ToggleProxyOn_Then_NoExceptionRaised'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("OpenAI Toggle_Proxy Off does not raise",
                           Given_OpenAiBaseClient_When_ToggleProxyOff_Then_NoExceptionRaised'Access));
      AUnit.Test_Suites.Add_Test
         (S, Caller.Create ("OpenAI Get_Response returns initial defaults",
                            Given_UnconfiguredOpenAiClient_When_GetResponseCalled_Then_EmptyResponseReturned'Access));
      AUnit.Test_Suites.Add_Test
         (S, Caller.Create ("OpenAI Build_Request_Body produces valid JSON",
                            Given_SimplePrompt_When_BuildRequestBodyCalled_Then_ValidJsonReturned'Access));
      AUnit.Test_Suites.Add_Test
         (S, Caller.Create ("OpenAI Build_Request_Body escapes double quotes",
                            Given_PromptWithDoubleQuote_When_BuildRequestBodyCalled_Then_QuoteEscaped'Access));
      AUnit.Test_Suites.Add_Test
         (S, Caller.Create ("OpenAI Build_Request_Body includes zero temperature",
                            Given_ZeroTemperature_When_BuildRequestBodyCalled_Then_TemperatureIncluded'Access));
      AUnit.Test_Suites.Add_Test
         (S, Caller.Create ("OpenAI Store_Response extracts content on success",
                            Given_SuccessfulResponse_When_StoreResponseCalled_Then_ContentExtracted'Access));
      AUnit.Test_Suites.Add_Test
         (S, Caller.Create ("OpenAI Store_Response stores error message",
                            Given_ErrorResponse_When_StoreResponseCalled_Then_ErrorMessageStored'Access));
      return S;
   end Suite;

end OpenAI_Tests;
