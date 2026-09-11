--  Memory store implementation: bounded conversation history.

with Ada.Characters.Latin_1;
with Ada.Strings.Unbounded;

package body Langchain4a.Memory is

   use Ada.Strings.Unbounded;

   function Is_Valid_Role (Role : String) return Boolean is
     (Role = "user" or else Role = "assistant" or else Role = "system");

   procedure Trim_Oldest (M : in out Memory_Store) with
     Post => Natural (M.Messages.Length) <= M.Max_Messages;

   ----------
   --  Conversation API
   ----------

   procedure Add_Message (M : in out Memory_Store; Role, Content : String) is
   begin
      if not Is_Valid_Role (Role) then
         raise Constraint_Error with
           "Memory_Store: invalid role '" & Role & "'";
      end if;
      M.Messages.Append
        (Message'(Role    => To_Unbounded_String (Role),
                  Content => To_Unbounded_String (Content)));
      M.Trim_Oldest;
   end Add_Message;

   function Count (M : Memory_Store) return Natural is
   begin
      return Natural (M.Messages.Length);
   end Count;

   procedure Clear (M : in out Memory_Store) is
   begin
      M.Messages.Clear;
   end Clear;

   procedure Set_Max_Messages (M : in out Memory_Store; Max : Positive) is
   begin
      M.Max_Messages := Max;
      M.Trim_Oldest;
   end Set_Max_Messages;

   function Get_History (M : Memory_Store) return String is
      Result : Unbounded_String;
   begin
      for Msg of M.Messages loop
         if Length (Result) > 0 then
            Append (Result, Ada.Characters.Latin_1.LF);
         end if;
         Append (Result, To_String (Msg.Role));
         Append (Result, ": ");
         Append (Result, To_String (Msg.Content));
      end loop;
      return To_String (Result);
   end Get_History;

   ----------
   --  Internals
   ----------

   procedure Trim_Oldest (M : in out Memory_Store) is
   begin
      while Natural (M.Messages.Length) > M.Max_Messages loop
         M.Messages.Delete_First;
      end loop;
   end Trim_Oldest;

end Langchain4a.Memory;
