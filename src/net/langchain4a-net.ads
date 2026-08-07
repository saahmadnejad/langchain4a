--  Shared network types: proxy settings, HTTP responses, JSON utilities

with Ada.Strings.Unbounded;
with Ada.Streams;

package Langchain4a.Net is

   use Ada.Strings.Unbounded;

   type Proxy_Mode is (Disabled, Socks5);

   type Proxy_Settings is record
      Mode     : Proxy_Mode := Disabled;
      Host     : Unbounded_String;
      Port     : Natural := 0;
      Username : Unbounded_String;
      Password : Unbounded_String;
   end record;

   type HTTP_Response is record
      Status_Code : Natural := 0;
      Content     : Unbounded_String;
   end record;

   function Perform_Request
     (URL          : String;
      Method       : String  := "POST";
      Content_Type : String  := "application/json";
      Data         : String  := "";
      API_Key      : String  := "";
      Extra_Headers : String := "";
      Proxy        : Proxy_Settings := (others => <>))
      return HTTP_Response;

   function Extract_Json_String (JSON, Key : String) return String;
   --  Extract a string value for @Key from a JSON document.
   --  Returns "" if the key is not found.

   function Extract_Json_Integer (JSON, Key : String) return Natural;
   --  Extract an integer value for @Key from a JSON document.
   --  Returns 0 if the key is not found.

end Langchain4a.Net;
