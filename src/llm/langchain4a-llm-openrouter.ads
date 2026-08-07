--  OpenRouter LLM client (OpenAI-compatible API with extra headers)
--  Inherits Send_Prompt and Get_Response from OpenAI_Client,
--  overrides Build_Extra_Headers to inject HTTP-Referer and X-Title.

with Ada.Strings.Unbounded;
with Langchain4a.Core.Config;
with Langchain4a.LLM.OpenAI;

package Langchain4a.LLM.OpenRouter is

   type OpenRouter_Client is new Langchain4a.LLM.OpenAI.OpenAI_Client
   with private;

   procedure Configure
     (Client : in out OpenRouter_Client;
      Cfg    : Langchain4a.Core.Config.OpenRouter_Config);

   function Build_Extra_Headers
     (Client : OpenRouter_Client'Class) return String;

   --  Send_Prompt and Get_Response are inherited from OpenAI_Client

private

   type OpenRouter_Client is new Langchain4a.LLM.OpenAI.OpenAI_Client
   with record
      Site_URL  : Ada.Strings.Unbounded.Unbounded_String;
      App_Name  : Ada.Strings.Unbounded.Unbounded_String;
   end record;

end Langchain4a.LLM.OpenRouter;
