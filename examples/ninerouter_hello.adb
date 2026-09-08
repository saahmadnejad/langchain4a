--  Example: Get a response from a local 9Router (https://9router.com) gateway
--
--  9Router exposes an OpenAI-compatible API at http://localhost:20128/v1,
--  so the base OpenAI_Client works against it directly -- no subclassing
--  and no provider-specific headers needed.
--
--  Build (from project root):
--    alr exec -- gnatmake -P examples/ninerouter_hello.gpr
--  Run (sources .env if present):
--    ./run.sh ./examples/examples/ninerouter_hello "your prompt"
--
--  Requires: NINEROUTER_API_KEY environment variable set.
--  Copy the key from the 9Router dashboard (Providers -> CLI tools).

with Ada.Command_Line;
with Ada.Environment_Variables;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.Sockets;

with Langchain4a;
with Langchain4a.Core;
with Langchain4a.Core.Config;
with Langchain4a.LLM.OpenAI;

procedure Ninerouter_Hello is
   use Ada.Text_IO;
   use Ada.Strings.Unbounded;

   function Env_Or (Name, Default : String) return String is
     (if Ada.Environment_Variables.Value (Name, "") /= ""
      then Ada.Environment_Variables.Value (Name)
      else Default);

   Endpoint : constant String :=
     Env_Or ("NINEROUTER_ENDPOINT", "http://localhost:20128/v1/chat/completions");
   Model    : constant String :=
     Env_Or ("NINEROUTER_MODEL", "glm");
   API_Key  : constant String := Ada.Environment_Variables.Value ("NINEROUTER_API_KEY", "");

   Prompt_Text : constant String :=
     (if Ada.Command_Line.Argument_Count >= 1
      then Ada.Command_Line.Argument (1)
      else "Explain in one paragraph why Ada is a good fit for reliable software.");

   Cfg    : Langchain4a.Core.Config.OpenAI_Config;
   Client : Langchain4a.LLM.OpenAI.OpenAI_Client;
begin
   Langchain4a.Initialize;

   if API_Key = "" then
      Put_Line ("Error: NINEROUTER_API_KEY environment variable not set.");
      Put_Line ("Copy the API key from the 9Router dashboard and:");
      Put_Line ("  export NINEROUTER_API_KEY=your-9router-key");
      return;
   end if;

   --  Point the plain OpenAI-compatible client at the local 9Router gateway
   Cfg.API_Key     := To_Unbounded_String (API_Key);
   Cfg.Endpoint    := To_Unbounded_String (Endpoint);
   Cfg.Model       := To_Unbounded_String (Model);
   Cfg.Temperature := 0.7;
   Cfg.Max_Tokens  := 1024;

   Client.Configure (Cfg);

   Put_Line ("Sending prompt to 9Router...");
   Put_Line ("  Endpoint: " & Endpoint);
   Put_Line ("  Model:    " & Model);
   New_Line;

   Client.Send_Prompt (Langchain4a.Core.Prompt (Prompt_Text));

   --  Retrieve and display the response
   declare
      Response : constant Langchain4a.Core.LLM_Response := Client.Get_Response;
   begin
      Put_Line ("--- Response ---");
      Put_Line (To_String (Response.Text));
      Put_Line ("---");
      Put_Line ("Tokens used: " & Natural'Image (Response.Tokens));
   end;

   Langchain4a.Finalize;

exception
   when GNAT.Sockets.Socket_Error =>
      Put_Line ("Error: cannot reach 9Router at " & Endpoint);
      Put_Line ("Is it running?  Start it with:  9router");
      Langchain4a.Finalize;
   when others =>
      Langchain4a.Finalize;
      raise;
end Ninerouter_Hello;
