--  Shared network types: proxy settings and HTTP responses.
--  JSON extraction utilities live in Langchain4a.Net.JSON (separate package,
--  following the Single Responsibility Principle).

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

end Langchain4a.Net;
