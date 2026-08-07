--  Main package for Langchain4a library
--  A LangChain-inspired library for building LLM-powered applications in Ada

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Langchain4a is
   pragma Elaborate_Body;

   --  Library version
   Version : constant String := "0.1.0";

   --  Lifecycle
   procedure Initialize;
   procedure Finalize;

private
   Initialized : Boolean := False;
end Langchain4a;