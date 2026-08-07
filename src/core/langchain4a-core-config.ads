--  Configuration types and loading for Langchain4a

with Ada.Strings.Unbounded;
with Langchain4a.Net;

package Langchain4a.Core.Config is

   use Ada.Strings.Unbounded;
   use Langchain4a.Net;

   type Provider_Kind is (OpenRouter, OpenAI);

   type OpenRouter_Config is record
      API_Key     : Unbounded_String;
      Endpoint    : Unbounded_String :=
        To_Unbounded_String ("https://openrouter.ai/api/v1/chat/completions");
      Model       : Unbounded_String;
      Temperature : Float := 0.7;
      Max_Tokens  : Natural := 1024;
      Proxy       : Proxy_Settings;
      Site_URL    : Unbounded_String;
      App_Name    : Unbounded_String;
   end record;

   type OpenAI_Config is record
      API_Key     : Unbounded_String;
      Endpoint    : Unbounded_String :=
        To_Unbounded_String ("https://api.openai.com/v1/chat/completions");
      Model       : Unbounded_String;
      Temperature : Float := 0.7;
      Max_Tokens  : Natural := 1024;
      Proxy       : Proxy_Settings;
   end record;

   type Configuration is record
      Provider       : Provider_Kind := OpenRouter;
      OpenRouter_Cfg : OpenRouter_Config;
      OpenAI_Cfg     : OpenAI_Config;
   end record;

   --  Load configuration from a file
   procedure Load_Config (Config : out Configuration; File_Path : String);

   --  Load configuration from environment variables
   procedure Load_From_Env (Config : out Configuration);

   --  Load API key from environment variable (secure)
   function Get_API_Key_From_Env return Unbounded_String;

   --  Convenience accessors
   function Get_OpenRouter_API_Key return Unbounded_String;
   function Get_OpenAI_API_Key return Unbounded_String;

end Langchain4a.Core.Config;
