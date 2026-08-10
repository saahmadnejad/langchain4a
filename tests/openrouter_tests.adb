--  Unit tests for Langchain4a.LLM.OpenRouter client (Build_Extra_Headers, Configure).

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;

with Ada.Strings.Unbounded;
with Langchain4a.Core;
with Langchain4a.Core.Config;
with Langchain4a.LLM.OpenRouter;

package body OpenRouter_Tests is

   use AUnit.Assertions;
   use Ada.Strings.Unbounded;

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

   procedure Given_OpenRouterClient_When_SiteUrlAndAppNameSet_Then_RefererAndTitleHeadersReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Client : Langchain4a.LLM.OpenRouter.OpenRouter_Client;
      Cfg    : Langchain4a.Core.Config.OpenRouter_Config;
   begin
      --  Arrange
      Cfg.Site_URL := To_Unbounded_String ("https://my-app.example.com");
      Cfg.App_Name := To_Unbounded_String ("MyApp");
      Client.Configure (Cfg);

      --  Act
      declare
         Expected : constant String :=
           "HTTP-Referer: https://my-app.example.com" & ASCII.CR & ASCII.LF
           & "X-Title: MyApp" & ASCII.CR & ASCII.LF;
         Result : constant String :=
           Langchain4a.LLM.OpenRouter.Build_Extra_Headers (Client);
      begin
         --  Assert
         Assert (Result = Expected,
                 "Both headers should be present, got: " & Result);
      end;
   end Given_OpenRouterClient_When_SiteUrlAndAppNameSet_Then_RefererAndTitleHeadersReturned;

   procedure Given_OpenRouterClient_When_OnlySiteUrlSet_Then_RefererHeaderOnly
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Client : Langchain4a.LLM.OpenRouter.OpenRouter_Client;
      Cfg    : Langchain4a.Core.Config.OpenRouter_Config;
   begin
      --  Arrange
      Cfg.Site_URL := To_Unbounded_String ("https://my-app.example.com");
      Client.Configure (Cfg);

      --  Act
      declare
         Expected : constant String :=
           "HTTP-Referer: https://my-app.example.com" & ASCII.CR & ASCII.LF;
         Result : constant String :=
           Langchain4a.LLM.OpenRouter.Build_Extra_Headers (Client);
      begin
         --  Assert
         Assert (Result = Expected,
                 "Only HTTP-Referer should be present, got: " & Result);
      end;
   end Given_OpenRouterClient_When_OnlySiteUrlSet_Then_RefererHeaderOnly;

   procedure Given_OpenRouterClient_When_OnlyAppNameSet_Then_TitleHeaderOnly
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Client : Langchain4a.LLM.OpenRouter.OpenRouter_Client;
      Cfg    : Langchain4a.Core.Config.OpenRouter_Config;
   begin
      --  Arrange
      Cfg.App_Name := To_Unbounded_String ("MyApp");
      Client.Configure (Cfg);

      --  Act
      declare
         Expected : constant String := "X-Title: MyApp" & ASCII.CR & ASCII.LF;
         Result : constant String :=
           Langchain4a.LLM.OpenRouter.Build_Extra_Headers (Client);
      begin
         --  Assert
         Assert (Result = Expected,
                 "Only X-Title should be present, got: " & Result);
      end;
   end Given_OpenRouterClient_When_OnlyAppNameSet_Then_TitleHeaderOnly;

   procedure Given_OpenRouterClient_When_NeitherFieldSet_Then_EmptyHeadersReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Client : Langchain4a.LLM.OpenRouter.OpenRouter_Client;
      Cfg    : Langchain4a.Core.Config.OpenRouter_Config;
   begin
      --  Arrange (neither Site_URL nor App_Name set)
      Client.Configure (Cfg);

      --  Act
      --  Assert
      Assert (Langchain4a.LLM.OpenRouter.Build_Extra_Headers (Client) = "",
              "No extra headers when neither field is set");
   end Given_OpenRouterClient_When_NeitherFieldSet_Then_EmptyHeadersReturned;

   ----------
   --  Configure tests
   ----------

   procedure Given_OpenRouterClient_When_ConfigureCalled_Then_AllFieldsSetCorrectly
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Client : Langchain4a.LLM.OpenRouter.OpenRouter_Client;
      Cfg    : Langchain4a.Core.Config.OpenRouter_Config;
   begin
      --  Arrange
      Cfg.API_Key  := To_Unbounded_String ("sk-or-v1-configure-test");
      Cfg.Endpoint := To_Unbounded_String ("https://configure.example.com/api");
      Cfg.Model    := To_Unbounded_String ("configure-model");
      Cfg.Temperature := 0.42;
      Cfg.Max_Tokens := 999;
      Cfg.Site_URL := To_Unbounded_String ("https://configure-site.example.com");
      Cfg.App_Name := To_Unbounded_String ("ConfigureApp");

      --  Act
      Client.Configure (Cfg);

      --  Assert (verify via Build_Extra_Headers that Site_URL and App_Name were set)
      declare
         Expected : constant String :=
           "HTTP-Referer: https://configure-site.example.com" & ASCII.CR & ASCII.LF
           & "X-Title: ConfigureApp" & ASCII.CR & ASCII.LF;
      begin
         Assert (Langchain4a.LLM.OpenRouter.Build_Extra_Headers (Client) = Expected,
                 "Configure should set Site_URL and App_Name");
      end;
   end Given_OpenRouterClient_When_ConfigureCalled_Then_AllFieldsSetCorrectly;

   ----------
   --  Suite
   ----------

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      S : constant AUnit.Test_Suites.Access_Test_Suite :=
            AUnit.Test_Suites.New_Suite;
   begin
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("OpenRouter headers with both fields",
                           Given_OpenRouterClient_When_SiteUrlAndAppNameSet_Then_RefererAndTitleHeadersReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("OpenRouter headers only Site_URL",
                           Given_OpenRouterClient_When_OnlySiteUrlSet_Then_RefererHeaderOnly'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("OpenRouter headers only App_Name",
                           Given_OpenRouterClient_When_OnlyAppNameSet_Then_TitleHeaderOnly'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("OpenRouter headers neither set",
                           Given_OpenRouterClient_When_NeitherFieldSet_Then_EmptyHeadersReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("OpenRouter Configure sets all fields",
                           Given_OpenRouterClient_When_ConfigureCalled_Then_AllFieldsSetCorrectly'Access));
      return S;
   end Suite;

end OpenRouter_Tests;
