--  OpenRouter LLM client implementation

with Ada.Strings.Unbounded;

package body Langchain4a.LLM.OpenRouter is

   use Ada.Strings.Unbounded;

   ----------
   -- Public API
   ----------

   procedure Configure
     (Client : in out OpenRouter_Client;
      Cfg    : Langchain4a.Core.Config.OpenRouter_Config)
   is
      Base_Cfg : Langchain4a.Core.Config.OpenAI_Config;
   begin
      Base_Cfg.API_Key := Cfg.API_Key;
      Base_Cfg.Endpoint := Cfg.Endpoint;
      Base_Cfg.Model := Cfg.Model;
      Base_Cfg.Temperature := Cfg.Temperature;
      Base_Cfg.Max_Tokens := Cfg.Max_Tokens;
      Base_Cfg.Proxy := Cfg.Proxy;

      Langchain4a.LLM.OpenAI.Configure
        (Langchain4a.LLM.OpenAI.OpenAI_Client'Class (Client), Base_Cfg);

      Client.Site_URL := Cfg.Site_URL;
      Client.App_Name := Cfg.App_Name;
   end Configure;

   function Build_Extra_Headers
     (Client : OpenRouter_Client'Class) return String is
   begin
      if To_String (Client.Site_URL) /= "" then
         return "HTTP-Referer: " & To_String (Client.Site_URL)
                & ASCII.CR & ASCII.LF
                & (if To_String (Client.App_Name) /= ""
                   then "X-Title: " & To_String (Client.App_Name)
                          & ASCII.CR & ASCII.LF
                   else "");
      elsif To_String (Client.App_Name) /= "" then
         return "X-Title: " & To_String (Client.App_Name)
                  & ASCII.CR & ASCII.LF;
      else
         return "";
      end if;
   end Build_Extra_Headers;

end Langchain4a.LLM.OpenRouter;
