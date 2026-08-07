--  Memory types for storing conversation context

package Langchain4a.Memory is

   type Memory_Store is tagged private;

   --  Store a message in memory
   procedure Store(M : in out Memory_Store; Key, Value : String);

   --  Retrieve a message from memory
   function Retrieve(M : Memory_Store; Key : String) return String;

private
   type Memory_Store is tagged record
      null;
   end record;

end Langchain4a.Memory;