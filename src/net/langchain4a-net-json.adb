--  JSON extraction utilities for parsing JSON response bodies.

with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

package body Langchain4a.Net.JSON is

   use Ada.Strings.Unbounded;

   -----------------
   -- Find_Key --
   -----------------

   function Find_Key (JSON, Key : String) return Natural is
      Search : constant String := '"' & Key & '"' & ":";
      Pos    : Natural := Ada.Strings.Fixed.Index (JSON, Search);
   begin
      while Pos > 0 loop
         --  Ensure the key is properly bounded: it must not be part of
         --  a longer identifier (e.g. "my_content").  In valid JSON a key
         --  is preceded by '{', '[' or ',', never by a letter.
         if Pos = 1 or else JSON (Pos - 1) in '{' | '[' | ',' | ' ' | ASCII.HT | ASCII.LF | ASCII.CR then
            return Pos + Search'Length;
         end if;
         Pos := Ada.Strings.Fixed.Index (JSON, Search, Pos + 1);
      end loop;
      return 0;
   end Find_Key;

   ------------------------
   -- Extract_Json_String --
   ------------------------

   function Extract_Json_String (JSON, Key : String) return String is
      Value_Pos : constant Natural := Find_Key (JSON, Key);
   begin
      if Value_Pos = 0 or else Value_Pos > JSON'Last then
         return "";
      end if;

      declare
         Rest_Str : constant String := JSON (Value_Pos .. JSON'Last);
         Rest     : String (1 .. Rest_Str'Length);
         S_Pos    : Natural := 1;
      begin
         Rest := Rest_Str;

         while S_Pos <= Rest'Length
           and then Rest (S_Pos) in ' ' | ASCII.HT | ASCII.LF | ASCII.CR
         loop
            S_Pos := S_Pos + 1;
         end loop;

         if S_Pos > Rest'Length or else Rest (S_Pos) /= '"' then
            return "";
         end if;

         S_Pos := S_Pos + 1;
         declare
            Result  : Unbounded_String;
            Escaped : Boolean := False;
         begin
            while S_Pos <= Rest'Length loop
               if Escaped then
                  case Rest (S_Pos) is
                     when '"'  => Append (Result, '"');
                     when '\' => Append (Result, '\');
                     when '/'  => Append (Result, '/');
                     when 'n'  => Append (Result, ASCII.LF);
                     when 't'  => Append (Result, ASCII.HT);
                     when 'r'  => Append (Result, ASCII.CR);
                     when others => Append (Result, Rest (S_Pos));
                  end case;
                  Escaped := False;
               elsif Rest (S_Pos) = '\' then
                  Escaped := True;
               elsif Rest (S_Pos) = '"' then
                  exit;
               else
                  Append (Result, Rest (S_Pos));
               end if;
               S_Pos := S_Pos + 1;
            end loop;
            return To_String (Result);
         end;
      end;
   end Extract_Json_String;

   -------------------------
   -- Extract_Json_Integer --
   -------------------------

   function Extract_Json_Integer (JSON, Key : String) return Natural is
      Value_Pos : constant Natural := Find_Key (JSON, Key);
   begin
      if Value_Pos = 0 or else Value_Pos > JSON'Last then
         return 0;
      end if;

      declare
         Rest_Str : constant String := JSON (Value_Pos .. JSON'Last);
         Rest     : String (1 .. Rest_Str'Length);
         S_Pos    : Natural := 1;
      begin
         Rest := Rest_Str;

         while S_Pos <= Rest'Length
           and then Rest (S_Pos) in ' ' | ASCII.HT | ASCII.LF | ASCII.CR
         loop
            S_Pos := S_Pos + 1;
         end loop;

         if S_Pos > Rest'Length then
            return 0;
         end if;

         declare
            Num_Start : constant Natural := S_Pos;
            Num_End   : Natural := S_Pos;
         begin
            while Num_End <= Rest'Length
              and then Rest (Num_End) in '0' .. '9'
            loop
               Num_End := Num_End + 1;
            end loop;
            Num_End := Num_End - 1;

            if Num_End >= Num_Start then
               return Natural (Integer'Value (Rest (Num_Start .. Num_End)));
            else
               return 0;
            end if;
         end;
      end;
   end Extract_Json_Integer;

end Langchain4a.Net.JSON;
