--  OpenAI-compatible LLM client implementation
--  Provides shared HTTP logic; subclasses (e.g. OpenRouter) override
--  Build_Extra_Headers to inject provider-specific headers.

with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Strings;
with Langchain4a.Net;

package body Langchain4a.LLM.OpenAI is

   use Ada.Strings.Unbounded;
   use Langchain4a.Net;

   package Fixed renames Ada.Strings.Fixed;

   ----------
   -- Public API
   ----------

   procedure Configure
     (Client : in out OpenAI_Client'Class;
      Cfg    : Langchain4a.Core.Config.OpenAI_Config) is
   begin
      Client.API_Key := Cfg.API_Key;
      Client.Endpoint := Cfg.Endpoint;
      Client.Model := Cfg.Model;
      Client.Temperature := Cfg.Temperature;
      Client.Max_Tokens := Cfg.Max_Tokens;
      Client.Proxy_Config := Cfg.Proxy;
   end Configure;

   procedure Toggle_Proxy (Client : in out OpenAI_Client'Class;
                           Enable  : Boolean) is
   begin
      if Enable then
         Client.Proxy_Config.Mode := Socks5;
      else
         Client.Proxy_Config.Mode := Disabled;
      end if;
   end Toggle_Proxy;

   function Build_Extra_Headers
     (Client : OpenAI_Client'Class) return String is
      pragma Unreferenced (Client);
   begin
      return "";
   end Build_Extra_Headers;

   overriding function Get_Response
     (Client : OpenAI_Client) return Langchain4a.Core.LLM_Response is
   begin
      return Client.Last_Response;
   end Get_Response;

   ----------
   -- Internal helpers (shared by OpenAI and OpenRouter)
   ----------

   function Build_Request_Body
     (Prompt : String;
      Model  : String;
      Temp   : Float;
      Tokens : Natural) return String
   is
      Msg_Escaped : Unbounded_String;
   begin
      for C of Prompt loop
         if C = '"' then
            Append (Msg_Escaped, '\');
         end if;
         Append (Msg_Escaped, C);
      end loop;

      return
        "{""model"": """ & Model & ""","
      & " ""messages"": [{""role"": ""user"", ""content"": """ & To_String (Msg_Escaped) & """}],"
      & " ""temperature"": " & Fixed.Trim (Float'Image (Temp), Ada.Strings.Both)
      & ", ""max_tokens"": " & Natural'Image (Tokens)
      & "}";
   end Build_Request_Body;

    procedure Store_Response
      (Client   : in out OpenAI_Client;
       Response : HTTP_Response) is
    begin
       if Response.Status_Code = 200 then
          Client.Last_Response.Text :=
            To_Unbounded_String
              (Extract_Json_String
                 (To_String (Response.Content), "content"));
          Client.Last_Response.Tokens :=
            Extract_Json_Integer
              (To_String (Response.Content), "total_tokens");
       else
          declare
             Err_Msg : constant String :=
               Extract_Json_String
                 (To_String (Response.Content), "message");
          begin
             Client.Last_Response.Text :=
               To_Unbounded_String
                 ("Error: "
                  & (if Err_Msg /= ""
                     then Err_Msg
                     else "HTTP " & Natural'Image (Response.Status_Code)));
             Client.Last_Response.Tokens := 0;
          end;
       end if;
    end Store_Response;

   ----------
   -- Send_Prompt
   ----------

   overriding procedure Send_Prompt (Client : in out OpenAI_Client;
                                     P : Langchain4a.Core.Prompt) is
      Prompt_Str : constant String := String (P);
      Req_Body   : constant String :=
        Build_Request_Body
          (Prompt_Str,
           To_String (Client.Model),
           Client.Temperature,
           Client.Max_Tokens);
      Extra_Hdrs : constant String :=
        Build_Extra_Headers (OpenAI_Client'Class (Client));
      Response   : constant HTTP_Response :=
        Perform_Request
          (URL           => To_String (Client.Endpoint),
           Method        => "POST",
           Content_Type  => "application/json",
           Data          => Req_Body,
           API_Key       => To_String (Client.API_Key),
           Extra_Headers => Extra_Hdrs,
           Proxy         => Client.Proxy_Config);
   begin
      Store_Response (Client, Response);
   end Send_Prompt;

end Langchain4a.LLM.OpenAI;
