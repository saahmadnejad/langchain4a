--  Unit tests for Langchain4a.Core.Config configuration loading.

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;

with GNAT.OS_Lib;
with Ada.Strings.Unbounded;

with Langchain4a.Net;

package body Config_Tests is

   use Ada.Strings.Unbounded;
   use AUnit.Assertions;
   use Langchain4a.Net;
   use Langchain4a.Core.Config;

   package Caller is new AUnit.Test_Caller (Test_Fixture);

   --  Environment variable keys used in tests
   OR_Key  : constant String := "OPENROUTER_API_KEY";
   OA_Key  : constant String := "OPENAI_API_KEY";
   OR_EP   : constant String := "OPENROUTER_ENDPOINT";
   OR_Mod  : constant String := "OPENROUTER_MODEL";
   OR_Tmp  : constant String := "OPENROUTER_TEMPERATURE";
   OR_MT   : constant String := "OPENROUTER_MAX_TOKENS";
   OR_URL  : constant String := "OPENROUTER_SITE_URL";
   OR_App  : constant String := "OPENROUTER_APP_NAME";
   OA_EP   : constant String := "OPENAI_ENDPOINT";
   OA_Mod  : constant String := "OPENAI_MODEL";
   OA_Tmp  : constant String := "OPENAI_TEMPERATURE";
   OA_MT   : constant String := "OPENAI_MAX_TOKENS";
   Proxy_M : constant String := "PROXY_MODE";
   Proxy_H : constant String := "PROXY_HOST";
   Proxy_P : constant String := "PROXY_PORT";

   --  Saved environment variable values (for restore in Tear_Down)
   Saved_OR_Key  : Unbounded_String;
   Saved_OA_Key  : Unbounded_String;
   Saved_OR_EP   : Unbounded_String;
   Saved_OR_Mod  : Unbounded_String;
   Saved_OR_Tmp  : Unbounded_String;
   Saved_OR_MT   : Unbounded_String;
   Saved_OR_URL  : Unbounded_String;
   Saved_OR_App  : Unbounded_String;
   Saved_OA_EP   : Unbounded_String;
   Saved_OA_Mod  : Unbounded_String;
   Saved_OA_Tmp  : Unbounded_String;
   Saved_OA_MT   : Unbounded_String;
   Saved_Proxy_M : Unbounded_String;
   Saved_Proxy_H : Unbounded_String;
   Saved_Proxy_P : Unbounded_String;

   ----------
   --  Helpers
   ----------

   function Get_Env (Name : String) return Unbounded_String is
   begin
      return To_Unbounded_String (GNAT.OS_Lib.Getenv (Name).all);
   exception
      when Constraint_Error =>
         return Null_Unbounded_String;
   end Get_Env;

   procedure Save_Env is
   begin
      Saved_OR_Key  := Get_Env (OR_Key);
      Saved_OA_Key  := Get_Env (OA_Key);
      Saved_OR_EP   := Get_Env (OR_EP);
      Saved_OR_Mod  := Get_Env (OR_Mod);
      Saved_OR_Tmp  := Get_Env (OR_Tmp);
      Saved_OR_MT   := Get_Env (OR_MT);
      Saved_OR_URL  := Get_Env (OR_URL);
      Saved_OR_App  := Get_Env (OR_App);
      Saved_OA_EP   := Get_Env (OA_EP);
      Saved_OA_Mod  := Get_Env (OA_Mod);
      Saved_OA_Tmp  := Get_Env (OA_Tmp);
      Saved_OA_MT   := Get_Env (OA_MT);
      Saved_Proxy_M := Get_Env (Proxy_M);
      Saved_Proxy_H := Get_Env (Proxy_H);
      Saved_Proxy_P := Get_Env (Proxy_P);
   end Save_Env;

   procedure Clear_All_Env is
   begin
      GNAT.OS_Lib.Setenv (OR_Key,  "");
      GNAT.OS_Lib.Setenv (OA_Key,  "");
      GNAT.OS_Lib.Setenv (OR_EP,   "");
      GNAT.OS_Lib.Setenv (OR_Mod,  "");
      GNAT.OS_Lib.Setenv (OR_Tmp,  "");
      GNAT.OS_Lib.Setenv (OR_MT,   "");
      GNAT.OS_Lib.Setenv (OR_URL,  "");
      GNAT.OS_Lib.Setenv (OR_App,  "");
      GNAT.OS_Lib.Setenv (OA_EP,   "");
      GNAT.OS_Lib.Setenv (OA_Mod,  "");
      GNAT.OS_Lib.Setenv (OA_Tmp,  "");
      GNAT.OS_Lib.Setenv (OA_MT,   "");
      GNAT.OS_Lib.Setenv (Proxy_M, "");
      GNAT.OS_Lib.Setenv (Proxy_H, "");
      GNAT.OS_Lib.Setenv (Proxy_P, "");
   end Clear_All_Env;

   procedure Restore_Env is
   begin
      GNAT.OS_Lib.Setenv (OR_Key,  To_String (Saved_OR_Key));
      GNAT.OS_Lib.Setenv (OA_Key,  To_String (Saved_OA_Key));
      GNAT.OS_Lib.Setenv (OR_EP,   To_String (Saved_OR_EP));
      GNAT.OS_Lib.Setenv (OR_Mod,  To_String (Saved_OR_Mod));
      GNAT.OS_Lib.Setenv (OR_Tmp,  To_String (Saved_OR_Tmp));
      GNAT.OS_Lib.Setenv (OR_MT,   To_String (Saved_OR_MT));
      GNAT.OS_Lib.Setenv (OR_URL,  To_String (Saved_OR_URL));
      GNAT.OS_Lib.Setenv (OR_App,  To_String (Saved_OR_App));
      GNAT.OS_Lib.Setenv (OA_EP,   To_String (Saved_OA_EP));
      GNAT.OS_Lib.Setenv (OA_Mod,  To_String (Saved_OA_Mod));
      GNAT.OS_Lib.Setenv (OA_Tmp,  To_String (Saved_OA_Tmp));
      GNAT.OS_Lib.Setenv (OA_MT,   To_String (Saved_OA_MT));
      GNAT.OS_Lib.Setenv (Proxy_M, To_String (Saved_Proxy_M));
      GNAT.OS_Lib.Setenv (Proxy_H, To_String (Saved_Proxy_H));
      GNAT.OS_Lib.Setenv (Proxy_P, To_String (Saved_Proxy_P));
   end Restore_Env;

   ----------
   --  Setup / Teardown
   ----------

   overriding procedure Set_Up (T : in out Test_Fixture) is
      pragma Unreferenced (T);
   begin
      --  Arrange: save current env and clear all vars
      Save_Env;
      Clear_All_Env;
   end Set_Up;

   overriding procedure Tear_Down (T : in out Test_Fixture) is
      pragma Unreferenced (T);
   begin
      --  Restore original env state
      Restore_Env;
   end Tear_Down;

   ----------
   --  Load_From_Env tests
   ----------

   procedure Given_EnvironmentVariablesSet_When_LoadFromEnvCalled_Then_AllFieldsPopulated
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Config : Langchain4a.Core.Config.Configuration;
   begin
      --  Arrange
      GNAT.OS_Lib.Setenv (OR_Key,  "sk-or-v1-test-key");
      GNAT.OS_Lib.Setenv (OA_Key,  "sk-openai-test-key");
      GNAT.OS_Lib.Setenv (OR_EP,   "https://env-router.example.com");
      GNAT.OS_Lib.Setenv (OR_Mod,  "env-model");
      GNAT.OS_Lib.Setenv (OR_Tmp,  "0.1");
      GNAT.OS_Lib.Setenv (OR_MT,   "512");
      GNAT.OS_Lib.Setenv (OR_URL,  "https://env-site.example.com");
      GNAT.OS_Lib.Setenv (OR_App,  "EnvApp");
      GNAT.OS_Lib.Setenv (OA_EP,   "https://env-openai.example.com");
      GNAT.OS_Lib.Setenv (OA_Mod,  "env-oa-model");
      GNAT.OS_Lib.Setenv (OA_Tmp,  "0.2");
      GNAT.OS_Lib.Setenv (OA_MT,   "256");

      --  Act
      Langchain4a.Core.Config.Load_From_Env (Config);

      --  Assert
      Assert (Config.Provider = OpenRouter,
              "Default provider should be OpenRouter");

      Assert (To_String (Config.OpenRouter_Cfg.API_Key) = "sk-or-v1-test-key",
              "OpenRouter API key mismatch");
      Assert (To_String (Config.OpenRouter_Cfg.Endpoint) = "https://env-router.example.com",
              "OpenRouter endpoint mismatch");
      Assert (To_String (Config.OpenRouter_Cfg.Model) = "env-model",
              "OpenRouter model mismatch");
      Assert (Config.OpenRouter_Cfg.Temperature = 0.1,
              "OpenRouter temperature mismatch");
      Assert (Config.OpenRouter_Cfg.Max_Tokens = 512,
              "OpenRouter max_tokens mismatch");
      Assert (To_String (Config.OpenRouter_Cfg.Site_URL) = "https://env-site.example.com",
              "OpenRouter site_url mismatch");
      Assert (To_String (Config.OpenRouter_Cfg.App_Name) = "EnvApp",
              "OpenRouter app_name mismatch");

      Assert (To_String (Config.OpenAI_Cfg.API_Key) = "sk-openai-test-key",
              "OpenAI API key mismatch");
      Assert (To_String (Config.OpenAI_Cfg.Endpoint) = "https://env-openai.example.com",
              "OpenAI endpoint mismatch");
      Assert (To_String (Config.OpenAI_Cfg.Model) = "env-oa-model",
              "OpenAI model mismatch");
      Assert (Config.OpenAI_Cfg.Temperature = 0.2,
              "OpenAI temperature mismatch");
      Assert (Config.OpenAI_Cfg.Max_Tokens = 256,
              "OpenAI max_tokens mismatch");
   end Given_EnvironmentVariablesSet_When_LoadFromEnvCalled_Then_AllFieldsPopulated;

   procedure Given_NoEnvironmentVariables_When_LoadFromEnvCalled_Then_DefaultsPreserved
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Config : Langchain4a.Core.Config.Configuration;
   begin
      --  Arrange (env already cleared in Set_Up)
      --  Act
      Langchain4a.Core.Config.Load_From_Env (Config);

      --  Assert
      Assert (Config.Provider = OpenRouter,
              "Default provider should be OpenRouter");

      Assert (To_String (Config.OpenRouter_Cfg.API_Key) = "",
              "Unset OpenRouter API key should be empty");
      Assert (To_String (Config.OpenAI_Cfg.API_Key) = "",
              "Unset OpenAI API key should be empty");

      Assert (To_String (Config.OpenRouter_Cfg.Endpoint)
                = "https://openrouter.ai/api/v1/chat/completions",
              "Default OpenRouter endpoint should be preserved");
      Assert (To_String (Config.OpenAI_Cfg.Endpoint)
                = "https://api.openai.com/v1/chat/completions",
              "Default OpenAI endpoint should be preserved");

      Assert (Config.OpenRouter_Cfg.Temperature = 0.7,
              "Default OpenRouter temperature should be 0.7");
      Assert (Config.OpenAI_Cfg.Temperature = 0.7,
              "Default OpenAI temperature should be 0.7");
      Assert (Config.OpenRouter_Cfg.Max_Tokens = 1024,
              "Default OpenRouter max_tokens should be 1024");
      Assert (Config.OpenAI_Cfg.Max_Tokens = 1024,
              "Default OpenAI max_tokens should be 1024");
   end Given_NoEnvironmentVariables_When_LoadFromEnvCalled_Then_DefaultsPreserved;

   procedure Given_OnlyOpenRouterApiKey_When_LoadFromEnvCalled_Then_OnlyRouterKeySet
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Config : Langchain4a.Core.Config.Configuration;
   begin
      --  Arrange
      GNAT.OS_Lib.Setenv (OR_Key, "sk-or-v1-only-router");

      --  Act
      Langchain4a.Core.Config.Load_From_Env (Config);

      --  Assert
      Assert (To_String (Config.OpenRouter_Cfg.API_Key) = "sk-or-v1-only-router",
              "OpenRouter key should be set");
      Assert (To_String (Config.OpenAI_Cfg.API_Key) = "",
              "OpenAI key should remain empty");
   end Given_OnlyOpenRouterApiKey_When_LoadFromEnvCalled_Then_OnlyRouterKeySet;

   procedure Given_ProxyEnvVars_When_LoadFromEnvCalled_Then_ProxyConfigured
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Config : Langchain4a.Core.Config.Configuration;
   begin
      --  Arrange
      GNAT.OS_Lib.Setenv (Proxy_M, "socks5");
      GNAT.OS_Lib.Setenv (Proxy_H, "10.0.0.1");
      GNAT.OS_Lib.Setenv (Proxy_P, "9050");

      --  Act
      Langchain4a.Core.Config.Load_From_Env (Config);

      --  Assert
      Assert (Config.OpenRouter_Cfg.Proxy.Mode = Socks5,
              "OpenRouter proxy mode should be Socks5");
      Assert (Config.OpenAI_Cfg.Proxy.Mode = Socks5,
              "OpenAI proxy mode should be Socks5");
      Assert (To_String (Config.OpenRouter_Cfg.Proxy.Host) = "10.0.0.1",
              "OpenRouter proxy host mismatch");
      Assert (Config.OpenRouter_Cfg.Proxy.Port = 9050,
              "OpenRouter proxy port mismatch");
      Assert (To_String (Config.OpenAI_Cfg.Proxy.Host) = "10.0.0.1",
              "OpenAI proxy host mismatch");
      Assert (Config.OpenAI_Cfg.Proxy.Port = 9050,
              "OpenAI proxy port mismatch");
   end Given_ProxyEnvVars_When_LoadFromEnvCalled_Then_ProxyConfigured;

   ----------
   --  Get_API_Key_From_Env tests
   ----------

   procedure Given_OpenRouterApiKeySet_When_GetApiKeyCalled_Then_KeyReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      GNAT.OS_Lib.Setenv (OR_Key, "sk-or-v1-env-key");

      --  Act
      declare
         Result : constant Unbounded_String :=
                    Langchain4a.Core.Config.Get_API_Key_From_Env;
      begin
         --  Assert
         Assert (To_String (Result) = "sk-or-v1-env-key",
                 "Get_API_Key_From_Env should return set key");
      end;
   end Given_OpenRouterApiKeySet_When_GetApiKeyCalled_Then_KeyReturned;

   procedure Given_NoApiKeySet_When_GetApiKeyCalled_Then_EmptyStringReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange (env already cleared)
      --  Act
      declare
         Result : constant Unbounded_String :=
                    Langchain4a.Core.Config.Get_API_Key_From_Env;
      begin
         --  Assert
         Assert (To_String (Result) = "",
                 "Get_API_Key_From_Env should return empty when unset");
      end;
   end Given_NoApiKeySet_When_GetApiKeyCalled_Then_EmptyStringReturned;

   ----------
   --  Accessor tests
   ----------

   procedure Given_OpenRouterApiKeySet_When_GetOpenRouterKeyCalled_Then_KeyReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      GNAT.OS_Lib.Setenv (OR_Key, "sk-or-v1-accessor");

      --  Act
      --  Assert
      Assert (To_String (Langchain4a.Core.Config.Get_OpenRouter_API_Key)
                = "sk-or-v1-accessor",
              "Get_OpenRouter_API_Key should return the env var value");
   end Given_OpenRouterApiKeySet_When_GetOpenRouterKeyCalled_Then_KeyReturned;

   procedure Given_OpenAiApiKeySet_When_GetOpenAiKeyCalled_Then_KeyReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      GNAT.OS_Lib.Setenv (OA_Key, "sk-openai-accessor");

      --  Act
      --  Assert
      Assert (To_String (Langchain4a.Core.Config.Get_OpenAI_API_Key)
                = "sk-openai-accessor",
              "Get_OpenAI_API_Key should return the env var value");
   end Given_OpenAiApiKeySet_When_GetOpenAiKeyCalled_Then_KeyReturned;

   ----------
   --  Load_Config tests (from file)
   ----------

   procedure Given_ValidConfigFile_When_LoadConfigCalled_Then_AllFieldsParsed
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Config : Langchain4a.Core.Config.Configuration;
   begin
      --  Arrange
      --  Act
      Langchain4a.Core.Config.Load_Config (Config, "tests/test_config.ini");

      --  Assert
      Assert (Config.Provider = OpenAI,
              "Provider should be OpenAI from config file");

      Assert (To_String (Config.OpenRouter_Cfg.Endpoint)
                = "https://test-router.example.com/api/v1/chat",
              "OpenRouter endpoint mismatch");
      Assert (To_String (Config.OpenRouter_Cfg.Model) = "test-model-v2",
              "OpenRouter model mismatch");
      Assert (Config.OpenRouter_Cfg.Temperature = 0.5,
              "OpenRouter temperature mismatch");
      Assert (Config.OpenRouter_Cfg.Max_Tokens = 2048,
              "OpenRouter max_tokens mismatch");
      Assert (To_String (Config.OpenRouter_Cfg.Site_URL)
                = "https://test-site.example.com",
              "OpenRouter site_url mismatch");
      Assert (To_String (Config.OpenRouter_Cfg.App_Name) = "TestApp",
              "OpenRouter app_name mismatch");

      Assert (To_String (Config.OpenAI_Cfg.Endpoint)
                = "https://test-openai.example.com/v1/chat",
              "OpenAI endpoint mismatch");
      Assert (To_String (Config.OpenAI_Cfg.Model) = "gpt-4-test",
              "OpenAI model mismatch");
      Assert (Config.OpenAI_Cfg.Temperature = 0.3,
              "OpenAI temperature mismatch");
      Assert (Config.OpenAI_Cfg.Max_Tokens = 512,
              "OpenAI max_tokens mismatch");
   end Given_ValidConfigFile_When_LoadConfigCalled_Then_AllFieldsParsed;

   procedure Given_ConfigFileWithComments_When_LoadConfigCalled_Then_CommentsIgnored
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Config : Langchain4a.Core.Config.Configuration;
   begin
      --  Arrange (test_config.ini has comments and blank lines)
      --  Act
      Langchain4a.Core.Config.Load_Config (Config, "tests/test_config.ini");

      --  Assert
      Assert (To_String (Config.OpenRouter_Cfg.Model) = "test-model-v2",
              "Should parse model correctly despite comments and blank lines");
      Assert (Config.Provider = OpenAI,
              "Provider should be parsed despite comments");
   end Given_ConfigFileWithComments_When_LoadConfigCalled_Then_CommentsIgnored;

   procedure Given_ConfigFileWithProxySettings_When_LoadConfigCalled_Then_ProxyParsed
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      Config : Langchain4a.Core.Config.Configuration;
   begin
      --  Arrange
      --  Act
      Langchain4a.Core.Config.Load_Config (Config, "tests/test_config.ini");

      --  Assert
      Assert (Config.OpenRouter_Cfg.Proxy.Mode = Socks5,
              "Proxy mode should be Socks5 from config");
      Assert (To_String (Config.OpenRouter_Cfg.Proxy.Host) = "192.168.1.100",
              "Proxy host mismatch");
      Assert (Config.OpenRouter_Cfg.Proxy.Port = 10808,
              "Proxy port mismatch");
      Assert (To_String (Config.OpenRouter_Cfg.Proxy.Username) = "proxyuser",
              "Proxy username mismatch");
      Assert (To_String (Config.OpenRouter_Cfg.Proxy.Password) = "proxypass",
              "Proxy password mismatch");
   end Given_ConfigFileWithProxySettings_When_LoadConfigCalled_Then_ProxyParsed;

   procedure Load_Missing_Config is
      Config : Langchain4a.Core.Config.Configuration;
   begin
      Langchain4a.Core.Config.Load_Config (Config, "tests/nonexistent_config.ini");
   end Load_Missing_Config;

   procedure Given_NonexistentConfigFile_When_LoadConfigCalled_Then_ExceptionRaised
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      --  Act / Assert
      Assert_Exception (Load_Missing_Config'Access,
                        "Load_Config should raise on missing file");
   end Given_NonexistentConfigFile_When_LoadConfigCalled_Then_ExceptionRaised;

   ----------
   --  Suite
   ----------

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      S : constant AUnit.Test_Suites.Access_Test_Suite :=
            AUnit.Test_Suites.New_Suite;
   begin
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Load_From_Env with all vars set",
                           Given_EnvironmentVariablesSet_When_LoadFromEnvCalled_Then_AllFieldsPopulated'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Load_From_Env with no vars (defaults)",
                           Given_NoEnvironmentVariables_When_LoadFromEnvCalled_Then_DefaultsPreserved'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Load_From_Env with only OpenRouter key",
                           Given_OnlyOpenRouterApiKey_When_LoadFromEnvCalled_Then_OnlyRouterKeySet'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Load_From_Env with proxy settings",
                           Given_ProxyEnvVars_When_LoadFromEnvCalled_Then_ProxyConfigured'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Get_API_Key_From_Env with key set",
                           Given_OpenRouterApiKeySet_When_GetApiKeyCalled_Then_KeyReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Get_API_Key_From_Env with key unset",
                           Given_NoApiKeySet_When_GetApiKeyCalled_Then_EmptyStringReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Get_OpenRouter_API_Key",
                           Given_OpenRouterApiKeySet_When_GetOpenRouterKeyCalled_Then_KeyReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Get_OpenAI_API_Key",
                           Given_OpenAiApiKeySet_When_GetOpenAiKeyCalled_Then_KeyReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Load_Config from valid file",
                           Given_ValidConfigFile_When_LoadConfigCalled_Then_AllFieldsParsed'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Load_Config with comments ignored",
                           Given_ConfigFileWithComments_When_LoadConfigCalled_Then_CommentsIgnored'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Load_Config with proxy settings parsed",
                           Given_ConfigFileWithProxySettings_When_LoadConfigCalled_Then_ProxyParsed'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Load_Config raises on missing file",
                           Given_NonexistentConfigFile_When_LoadConfigCalled_Then_ExceptionRaised'Access));
      return S;
   end Suite;

end Config_Tests;
