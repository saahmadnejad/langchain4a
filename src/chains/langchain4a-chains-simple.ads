--  Simple sequential chain: prompt template + conversation memory + one LLM call.

private with Ada.Strings.Unbounded;

with Langchain4a.Core;
private with Langchain4a.Memory;

package Langchain4a.Chains.Simple is

   type Simple_Chain is new Chain with private;

   --  Wire the chain to a client (not owned; must outlive the chain)
   --  and an optional system-prompt template prepended to each request.
   procedure Configure
     (C        : in out Simple_Chain;
      Client   : access Langchain4a.Core.LLM_Model'Class;
      Template : String := "");

   --  Set the user input consumed by the next Run
   procedure Set_Input (C : in out Simple_Chain; Input : String);

   --  Prompt sent to the model: Template & LF & History & LF & Input
   --  (empty sections skipped, history excludes the current input)
   function Build_Prompt (C : Simple_Chain) return String;

   --  Same, with the input given explicitly (testability / ad-hoc use)
   function Build_Prompt (C : Simple_Chain; Input : String) return String;

   --  Send the prompt, record user/assistant turns in memory,
   --  store the model reply retrievable via Get_Output.
   overriding procedure Run (C : in out Simple_Chain);

   --  Reply text of the last Run ("" before the first Run)
   function Get_Output (C : Simple_Chain) return String;

   --  Serialized conversation history held by the chain
   function Get_History (C : Simple_Chain) return String;

private

   type Simple_Chain is new Chain with record
      Client      : access Langchain4a.Core.LLM_Model'Class;
      Memory      : Langchain4a.Memory.Memory_Store;
      Template    : Ada.Strings.Unbounded.Unbounded_String;
      User_Input  : Ada.Strings.Unbounded.Unbounded_String;
      Last_Output : Ada.Strings.Unbounded.Unbounded_String;
   end record;

end Langchain4a.Chains.Simple;
