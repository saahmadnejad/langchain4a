--  Memory types for storing conversation context

private with Ada.Containers.Vectors;
private with Ada.Strings.Unbounded;

package Langchain4a.Memory is

   type Memory_Store is tagged private;

   --  Maximum number of messages kept; oldest dropped on overflow
   Default_Max_Messages : constant := 100;

   --  Store a message in memory (legacy key-value form; appends as user turn)
   procedure Store (M : in out Memory_Store; Key, Value : String);

   --  Retrieve a message from memory (legacy key-value form; returns "")
   function Retrieve (M : Memory_Store; Key : String) return String;

   --  Append a conversation message with an explicit role ("user"/"assistant")
   procedure Add_Message (M : in out Memory_Store; Role, Content : String);

   --  Number of stored messages
   function Count (M : Memory_Store) return Natural;

   --  Remove all messages
   procedure Clear (M : in out Memory_Store);

   --  Set the maximum number of messages kept; oldest dropped if shrinking
   procedure Set_Max_Messages (M : in out Memory_Store; Max : Positive);

   --  Serialize history as role-prefixed lines, e.g. "user: hello\nassistant: hi"
   function Get_History (M : Memory_Store) return String;

private

   type Message is record
      Role    : Ada.Strings.Unbounded.Unbounded_String;
      Content : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   package Message_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Message);

   type Memory_Store is tagged record
      Messages     : Message_Vectors.Vector;
      Max_Messages : Positive := Default_Max_Messages;
   end record;

end Langchain4a.Memory;
