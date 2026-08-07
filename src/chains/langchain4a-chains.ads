--  Chain types for orchestrating LLM operations

package Langchain4a.Chains is

   type Chain is abstract tagged private;

   --  Run a chain
   procedure Run(C : in out Chain) is abstract;

private
   type Chain is abstract tagged record
      null;
   end record;

end Langchain4a.Chains;