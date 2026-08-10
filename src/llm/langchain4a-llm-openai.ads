--  OpenAI-compatible LLM client (base for OpenRouter and direct OpenAI)

with Ada.Strings.Unbounded;
with Langchain4a.Core;
with Langchain4a.Core.Config;
with Langchain4a.Net;

package Langchain4a.LLM.OpenAI is

   type OpenAI_Client is new Langchain4a.Core.LLM_Model with private;

   procedure Configure
     (Client : in out OpenAI_Client'Class;
      Cfg    : Langchain4a.Core.Config.OpenAI_Config);

   procedure Toggle_Proxy (Client : in out OpenAI_Client'Class;
                          Enable  : Boolean);

   overriding procedure Send_Prompt (Client : in out OpenAI_Client;
                                      P : Langchain4a.Core.Prompt);

   overriding function Get_Response
     (Client : OpenAI_Client) return Langchain4a.Core.LLM_Response;

   function Build_Extra_Headers
     (Client : OpenAI_Client'Class) return String;

   function Build_Request_Body
     (Prompt    : String;
      Model     : String;
      Temperature : Float;
      Max_Tokens  : Natural) return String;

   procedure Store_Response
     (Client   : in out OpenAI_Client;
      Response : Langchain4a.Net.HTTP_Response);

private

   type OpenAI_Client is new Langchain4a.Core.LLM_Model with record
      API_Key       : Ada.Strings.Unbounded.Unbounded_String;
      Endpoint      : Ada.Strings.Unbounded.Unbounded_String;
      Model         : Ada.Strings.Unbounded.Unbounded_String;
      Temperature   : Float := 0.7;
      Max_Tokens    : Natural := 1024;
      Proxy_Config  : Langchain4a.Net.Proxy_Settings;
      Last_Response : Langchain4a.Core.LLM_Response;
   end record;

end Langchain4a.LLM.OpenAI;
