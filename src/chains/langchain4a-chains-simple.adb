--  Simple sequential chain implementation.

with Ada.Characters.Latin_1;
with Ada.Strings.Unbounded;

with Langchain4a.Memory;

package body Langchain4a.Chains.Simple is

   use Ada.Strings.Unbounded;
   use Langchain4a.Memory;

   procedure Configure
     (C        : in out Simple_Chain;
      Client   : access Langchain4a.Core.LLM_Model'Class;
      Template : String := "")
   is
   begin
      C.Client := Client;
      C.Template := To_Unbounded_String (Template);
   end Configure;

   procedure Set_Input (C : in out Simple_Chain; Input : String) is
   begin
      C.User_Input := To_Unbounded_String (Input);
   end Set_Input;

   function Build_Prompt (C : Simple_Chain) return String is
   begin
      return Build_Prompt (C, To_String (C.User_Input));
   end Build_Prompt;

   function Build_Prompt (C : Simple_Chain; Input : String) return String is
      Parts : Unbounded_String;
   begin
      if Length (C.Template) > 0 then
         Append (Parts, To_String (C.Template));
      end if;
      if C.Memory.Count > 0 then
         if Length (Parts) > 0 then
            Append (Parts, Ada.Characters.Latin_1.LF);
         end if;
         Append (Parts, C.Memory.Get_History);
      end if;
      if Length (Parts) > 0 then
         Append (Parts, Ada.Characters.Latin_1.LF);
      end if;
      Append (Parts, Input);
      return To_String (Parts);
   end Build_Prompt;

   overriding procedure Run (C : in out Simple_Chain) is
      Input : constant String := To_String (C.User_Input);
   begin
      if C.Client = null then
         raise Constraint_Error with "Simple_Chain: no client configured";
      end if;

      --  On Send_Prompt failure the exception propagates and neither
      --  turn is recorded: history stays untouched.
      C.Client.Send_Prompt
        (Langchain4a.Core.Prompt (Build_Prompt (C, Input)));
      C.Last_Output := C.Client.Get_Response.Text;

      C.Memory.Add_Message ("user", Input);
      C.Memory.Add_Message ("assistant", To_String (C.Last_Output));
   end Run;

   function Get_Output (C : Simple_Chain) return String is
   begin
      return To_String (C.Last_Output);
   end Get_Output;

   function Get_History (C : Simple_Chain) return String is
   begin
      return C.Memory.Get_History;
   end Get_History;

end Langchain4a.Chains.Simple;
