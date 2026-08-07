--  Base types and utilities for Langchain4a

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Langchain4a.Core is

   --  Prompt type
   type Prompt is new String;

   --  LLM response type
   type LLM_Response is record
      Text  : Unbounded_String;
      Tokens : Natural := 0;
   end record;

   --  Base class for LLM models
   type LLM_Model is abstract tagged private;

   --  Send a prompt to the model
   procedure Send_Prompt(M : in out LLM_Model; P : Prompt) is abstract;

   --  Get the last response
   function Get_Response(M : LLM_Model) return LLM_Response is abstract;

private
   type LLM_Model is abstract tagged record
      Name : Unbounded_String;
   end record;

end Langchain4a.Core;