--  Backend tests for Langchain4a.Net.Perform_Request (plain HTTP path).
--  A listener task serves one fixed HTTP response on demand; tests hit it
--  through the public API. No external services required.

with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Streams;
with GNAT.Sockets;

with AUnit.Assertions;

with Langchain4a.Net;

package body Net_Tests is

   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use Ada.Streams;
   use GNAT.Sockets;

   package Fixed renames Ada.Strings.Fixed;

   Fixed_Response : constant String :=
     "HTTP/1.1 200 OK" & ASCII.CR & ASCII.LF
     & "Content-Type: application/json" & ASCII.CR & ASCII.LF
     & "Connection: close" & ASCII.CR & ASCII.LF
     & "Content-Length: 17" & ASCII.CR & ASCII.LF
     & ASCII.CR & ASCII.LF
     & "{""content"": ""hi""}";

   --  Serves one Fixed_Response to a single connection, then terminates.
   task type Responder is
      entry Start (Port : out Natural);
   end Responder;

   task body Responder is
      Addr   : Sock_Addr_Type :=
        (Family => Family_Inet,
         Addr    => Inet_Addr ("127.0.0.1"),
         Port    => 0);
      Server : Socket_Type;
      Client : Socket_Type;
      From   : Sock_Addr_Type;
      Buf    : Stream_Element_Array (1 .. 4096);
      Last   : Stream_Element_Offset;
      Sent   : Stream_Element_Offset;
      Sea    : constant Stream_Element_Array
        (1 .. Stream_Element_Offset (Fixed_Response'Length)) :=
        (for I in 1 .. Stream_Element_Offset (Fixed_Response'Length) =>
           Stream_Element (Character'Pos
             (Fixed_Response (Positive (I)))));
   begin
      Create_Socket (Server, Family_Inet, Socket_Stream);
      Set_Socket_Option (Server, Socket_Level, (Reuse_Address, True));
      Bind_Socket (Server, Addr);
      Addr := Get_Socket_Name (Server);
      Listen_Socket (Server, 1);
      accept Start (Port : out Natural) do
         Port := Natural (Addr.Port);
      end Start;

      --  Serve exactly one request, then shut down
      Accept_Socket (Server, Client, From);
      Receive_Socket (Client, Buf, Last);  --  drain request
      Send_Socket (Client, Sea, Sent);
      Close_Socket (Client);
      Close_Socket (Server);
   end Responder;

   ----------
   --  Tests
   ----------

   procedure Given_LocalHttpListener_When_PostRequest_Then_StatusAndBodyParsed
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
      R    : Responder;
      Port : Natural;
      Resp : Langchain4a.Net.HTTP_Response;
   begin
      --  Arrange
      R.Start (Port);

      --  Act
      Resp := Langchain4a.Net.Perform_Request
        (URL     => "http://127.0.0.1:" & Fixed.Trim (Port'Image, Ada.Strings.Both) & "/v1/x",
         Method  => "POST",
         Data    => "{""x"": 1}",
         API_Key => "test-key");

      --  Assert
      Assert (Resp.Status_Code = 200, "expected status 200");
      Assert
        (To_String (Resp.Content) = "{""content"": ""hi""}",
         "expected fixed body, got: " & To_String (Resp.Content));
   end Given_LocalHttpListener_When_PostRequest_Then_StatusAndBodyParsed;

   procedure Given_UnsupportedScheme_When_Request_Then_SocketErrorRaised
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Act + Assert: scheme validation fires before any network I/O
      declare
         Ignored : Langchain4a.Net.HTTP_Response;
         pragma Unreferenced (Ignored);
      begin
         Ignored := Langchain4a.Net.Perform_Request
           (URL     => "ftp://example.com/file",
            Method  => "POST",
            Data    => "");
         Assert (False, "expected Socket_Error for unsupported scheme");
      exception
         when GNAT.Sockets.Socket_Error =>
            null;
      end;
   end Given_UnsupportedScheme_When_Request_Then_SocketErrorRaised;

   ----------
   --  Suite
   ----------

   package Caller is new AUnit.Test_Caller (Test_Fixture);

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      S : constant AUnit.Test_Suites.Access_Test_Suite :=
        AUnit.Test_Suites.New_Suite;
   begin
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create
           ("Perform_Request: plain HTTP against local listener parses 200",
            Given_LocalHttpListener_When_PostRequest_Then_StatusAndBodyParsed'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create
           ("Perform_Request: unsupported scheme raises Socket_Error",
            Given_UnsupportedScheme_When_Request_Then_SocketErrorRaised'Access));
      return S;
   end Suite;

end Net_Tests;
