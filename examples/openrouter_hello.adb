--  Example: Send a prompt to OpenRouter and print the response
--
--  Build (from project root):
--    gnatmake -P langchain4a.gpr \
--      -XBUILD_NAME=examples/openrouter_hello \
--      examples/openrouter_hello.adb
--  Or compile manually:
--    gcc -c -gnat2012 -gnatwU -Isrc -Isrc/core -Isrc/llm -Isrc/memory -Isrc/chains -Isrc/net examples/openrouter_hello.adb
--    gnatbind -n examples/openrouter_hello.ali
--    gnatlink examples/openrouter_hello.ali lib/liblangchain4a.a
--
--  Requires: OPENROUTER_API_KEY environment variable set

with Ada.Command_Line;
with Ada.Text_IO;
with Ada.Strings.Unbounded;

with Langchain4a;
with Langchain4a.Core;
with Langchain4a.Core.Config;
with Langchain4a.LLM.OpenRouter;

procedure Openrouter_Hello is
   use Ada.Text_IO;
   use Ada.Strings.Unbounded;

   Config : Langchain4a.Core.Config.Configuration;
   Client : Langchain4a.LLM.OpenRouter.OpenRouter_Client;

   Prompt_Text : constant String :=
     (if Ada.Command_Line.Argument_Count >= 1
      then Ada.Command_Line.Argument (1)
      else "Explain the difference between tagged and untagged types in Ada.");

begin
   Langchain4a.Initialize;

   --  Load configuration from environment variables
   Langchain4a.Core.Config.Load_From_Env (Config);

   if To_String (Config.OpenRouter_Cfg.API_Key) = "" then
      Put_Line ("Error: OPENROUTER_API_KEY environment variable not set.");
      Put_Line ("Copy .env.example to .env and fill in your key, or:");
      Put_Line ("  export OPENROUTER_API_KEY=sk-or-v1-...");
      return;
   end if;

   --  Configure the OpenRouter client
   Client.Configure (Config.OpenRouter_Cfg);

   Put_Line ("Sending prompt to OpenRouter...");
   Put_Line ("  Model: " & To_String (Config.OpenRouter_Cfg.Model));
   New_Line;

   --  Send the prompt (this performs the HTTP request)
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
   when others =>
      Langchain4a.Finalize;
      raise;
end Openrouter_Hello;
