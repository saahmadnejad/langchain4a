--  JSON extraction utilities for parsing JSON response bodies.
--  Separated from Langchain4a.Net to follow the Single Responsibility
--  Principle (SRP): JSON parsing is independent of HTTP/networking.

package Langchain4a.Net.JSON is

   function Extract_Json_String (JSON, Key : String) return String;
   --  Extract a string value for Key from a JSON document.
   --  Returns "" if the key is not found.

   function Extract_Json_Integer (JSON, Key : String) return Natural;
   --  Extract an integer value for Key from a JSON document.
   --  Returns 0 if the key is not found.

private

   function Find_Key (JSON, Key : String) return Natural;
   --  Locate the position immediately after "Key": in JSON.
   --  Returns 0 if the key is not found or is a substring of a longer key.

end Langchain4a.Net.JSON;
