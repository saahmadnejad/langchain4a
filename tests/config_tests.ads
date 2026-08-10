--  Unit tests for Langchain4a.Core.Config configuration loading.
--  Tests Load_From_Env, Load_Config, Get_API_Key_From_Env, and accessors.

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

with GNAT.OS_Lib;
with Ada.Strings.Unbounded;

with Langchain4a.Core.Config;
with Langchain4a.Net;

package Config_Tests is

   type Test_Fixture is new AUnit.Test_Fixtures.Test_Fixture with record
      null;
   end record;

   overriding procedure Set_Up (T : in out Test_Fixture);
   overriding procedure Tear_Down (T : in out Test_Fixture);

   --  Load_From_Env tests
   procedure Given_EnvironmentVariablesSet_When_LoadFromEnvCalled_Then_AllFieldsPopulated
     (T : in out Test_Fixture);
   procedure Given_NoEnvironmentVariables_When_LoadFromEnvCalled_Then_DefaultsPreserved
     (T : in out Test_Fixture);
   procedure Given_OnlyOpenRouterApiKey_When_LoadFromEnvCalled_Then_OnlyRouterKeySet
     (T : in out Test_Fixture);
   procedure Given_ProxyEnvVars_When_LoadFromEnvCalled_Then_ProxyConfigured
     (T : in out Test_Fixture);

   --  Get_API_Key_From_Env tests
   procedure Given_OpenRouterApiKeySet_When_GetApiKeyCalled_Then_KeyReturned
     (T : in out Test_Fixture);
   procedure Given_NoApiKeySet_When_GetApiKeyCalled_Then_EmptyStringReturned
     (T : in out Test_Fixture);

   --  Accessor tests
   procedure Given_OpenRouterApiKeySet_When_GetOpenRouterKeyCalled_Then_KeyReturned
     (T : in out Test_Fixture);
   procedure Given_OpenAiApiKeySet_When_GetOpenAiKeyCalled_Then_KeyReturned
     (T : in out Test_Fixture);

   --  Load_Config tests (from file)
   procedure Given_ValidConfigFile_When_LoadConfigCalled_Then_AllFieldsParsed
     (T : in out Test_Fixture);
   procedure Given_ConfigFileWithComments_When_LoadConfigCalled_Then_CommentsIgnored
     (T : in out Test_Fixture);
   procedure Given_ConfigFileWithProxySettings_When_LoadConfigCalled_Then_ProxyParsed
     (T : in out Test_Fixture);
   procedure Given_NonexistentConfigFile_When_LoadConfigCalled_Then_ExceptionRaised
     (T : in out Test_Fixture);

   function Suite return AUnit.Test_Suites.Access_Test_Suite;

end Config_Tests;
