--  HTTP client with SOCKS5 proxy and TLS support

with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with GNAT.Sockets;
with Interfaces.C;
with Interfaces.C.Strings;
with SSL.Thin;
with System;

package body Langchain4a.Net is

   use Ada.Strings.Unbounded;
   use Ada.Streams;
   use Interfaces.C;
   use GNAT.Sockets;
   use SSL.Thin;
   use System;

   package Cstr renames Interfaces.C.Strings;
   package Fixed renames Ada.Strings.Fixed;

   ----------
   -- Helpers
   ----------

   function To_SEA (Str : String) return Stream_Element_Array is
   begin
      if Str'Length = 0 then
         return (1 .. 0 => 0);
      end if;
      declare
         Result : Stream_Element_Array (1 .. Stream_Element_Offset (Str'Length));
      begin
         for I in Str'Range loop
            Result (Stream_Element_Offset (I - Str'First + 1)) :=
              Character'Pos (Str (I));
         end loop;
         return Result;
      end;
   end To_SEA;

   ------------------
   -- URL parsing   --
   ------------------

   type Parsed_URL is record
      Scheme  : Unbounded_String;
      Host    : Unbounded_String;
      Port    : Natural := 443;
      Path    : Unbounded_String;
   end record;

    function Parse_URL (URL : String) return Parsed_URL is
       Result : Parsed_URL;
       Work   : Unbounded_String := To_Unbounded_String (URL);
       Sep    : Natural;
    begin
       --  Scheme
       Sep := Fixed.Index (To_String (Work), "://");
       if Sep > 0 then
          Result.Scheme := To_Unbounded_String
            (To_String (Work) (1 .. Sep - 1));
          Work := To_Unbounded_String
            (To_String (Work) (Sep + 3 .. To_String (Work)'Last));
       end if;

       --  Path
       Sep := Fixed.Index (To_String (Work), "/");
       if Sep > 0 then
          Result.Path := To_Unbounded_String
            (To_String (Work) (Sep .. To_String (Work)'Last));
          declare
             Host_Part : constant String :=
               To_String (Work) (1 .. Sep - 1);
             Colon     : constant Natural := Fixed.Index (Host_Part, ":");
          begin
             if Colon > 0 then
                Result.Host := To_Unbounded_String (Host_Part (1 .. Colon - 1));
                Result.Port :=
                  Natural (Integer'Value (Host_Part (Colon + 1 .. Host_Part'Last)));
             else
                Result.Host := To_Unbounded_String (Host_Part);
                if To_String (Result.Scheme) = "https" then
                   Result.Port := 443;
                else
                   Result.Port := 80;
                end if;
             end if;
          end;
       else
          Result.Host := Work;
          if To_String (Result.Scheme) = "https" then
             Result.Port := 443;
         else
            Result.Port := 80;
         end if;
         Result.Path := To_Unbounded_String ("/");
      end if;

      return Result;
   end Parse_URL;

    -------------------------
    -- Chunked decoding   --
    -------------------------

    function DeChunk (Chunked_Body : String) return String is
       Result     : Unbounded_String;
       Pos        : Positive := Chunked_Body'First;
       Chunk_Size : Natural;
       Hex_Digit  : Character;
    begin
       while Pos <= Chunked_Body'Last loop
          --  Parse hex chunk size up to '\r'
          Chunk_Size := 0;
          loop
             exit when Pos > Chunked_Body'Last or else Chunked_Body (Pos) = ASCII.CR;
             Hex_Digit := Chunked_Body (Pos);
             Chunk_Size := Chunk_Size * 16;
             if Hex_Digit in '0' .. '9' then
                Chunk_Size := Chunk_Size + Character'Pos (Hex_Digit) - Character'Pos ('0');
             elsif Hex_Digit in 'A' .. 'F' then
                Chunk_Size :=
                  Chunk_Size + Character'Pos (Hex_Digit) - Character'Pos ('A') + 10;
             elsif Hex_Digit in 'a' .. 'f' then
                Chunk_Size :=
                  Chunk_Size + Character'Pos (Hex_Digit) - Character'Pos ('a') + 10;
             end if;
             Pos := Pos + 1;
          end loop;

          --  Skip \r\n
          Pos := Pos + 1;  --  skip CR
          if Pos <= Chunked_Body'Last and then Chunked_Body (Pos) = ASCII.LF then
             Pos := Pos + 1;  --  skip LF
          end if;

          --  Read chunk data
          if Chunk_Size = 0 then
             exit;
          end if;
          declare
             Chunk_Data : constant String :=
               Chunked_Body (Pos .. Pos + Chunk_Size - 1);
          begin
             Append (Result, Chunk_Data);
          end;
          Pos := Pos + Chunk_Size;

          --  Skip trailing \r\n
          if Pos <= Chunked_Body'Last and then Chunked_Body (Pos) = ASCII.CR then
             Pos := Pos + 1;
          end if;
          if Pos <= Chunked_Body'Last and then Chunked_Body (Pos) = ASCII.LF then
             Pos := Pos + 1;
          end if;
       end loop;

       return To_String (Result);
    end DeChunk;

    -------------------------
    -- JSON extraction    --
    -------------------------

    function Find_Key (JSON, Key : String) return Natural is
       Search : constant String := '"' & Key & """:";
       Pos    : Natural := Fixed.Index (JSON, Search);
    begin
       while Pos > 0 loop
          --  Ensure the key is properly bounded: it must not be part of
          --  a longer identifier (e.g. "my_content").  In valid JSON a key
          --  is preceded by '{', '[' or ',', never by a letter or '"'.
          if Pos = 1 or else JSON (Pos - 1) in '{' | '[' | ',' | ' ' | ASCII.HT | ASCII.LF | ASCII.CR then
             return Pos + Search'Length;
          end if;
          Pos := Fixed.Index (JSON, Search, Pos + 1);
       end loop;
       return 0;
    end Find_Key;

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

    -------------------------
    -- SOCKS5 support     --
    -------------------------

    function Host_Is_IP (Host : String) return Boolean is
       Dot_Count : Natural := 0;
    begin
       if Host'Length = 0 then
          return False;
       end if;
       for C of Host loop
          if C in '0' .. '9' then
             null;
          elsif C = '.' then
             Dot_Count := Dot_Count + 1;
          else
             return False;
          end if;
       end loop;
       return Dot_Count = 3;
    end Host_Is_IP;

    procedure Socks5_Tunnel
     (Socket       : in out GNAT.Sockets.Socket_Type;
      Proxy_Host   : String;
      Proxy_Port   : Natural;
      Target_Host  : String;
      Target_Port  : Natural;
      Username     : String := "";
      Password     : String := "")
    is
       pragma Unreferenced (Username, Password);
    begin
       --  Resolve and connect to SOCKS5 proxy
       declare
          Proxy_IP   : constant Inet_Addr_Type :=
            (if Host_Is_IP (Proxy_Host)
             then Inet_Addr (Proxy_Host)
             else Addresses (Get_Host_By_Name (Proxy_Host), 1));
          Proxy_Addr : constant Sock_Addr_Type :=
            (Family => Family_Inet,
             Addr   => Proxy_IP,
             Port   => Port_Type (Proxy_Port));
       begin
          Connect_Socket (Socket, Proxy_Addr);
       end;

      --  SOCKS5 greeting: version=5, 1 method, no-auth
      declare
         Greeting : constant Stream_Element_Array := (5, 1, 0);
         Reply    : Stream_Element_Array (1 .. 2);
         Last     : Stream_Element_Offset;
      begin
         Send_Socket (Socket, Greeting, Last);
         Receive_Socket (Socket, Reply, Last);

         if Last < 2 or else Reply (2) = 16#FF# then
            raise Socket_Error with "SOCKS5: no acceptable auth method";
         end if;
      end;

      --  SOCKS5 CONNECT request: ATYP=domain (3)
      declare
         Host_Bytes  : constant Stream_Element_Array := To_SEA (Target_Host);
         Port_Hi     : constant Stream_Element := Stream_Element (Target_Port / 256);
         Port_Lo     : constant Stream_Element := Stream_Element (Target_Port mod 256);
         Buf_Len     : constant Stream_Element_Offset := 4 + 1 + Host_Bytes'Length + 2;
         Connect_Req : Stream_Element_Array (1 .. Buf_Len);
         Idx         : Stream_Element_Offset := 1;
         Reply       : Stream_Element_Array (1 .. 10);
         Last        : Stream_Element_Offset;
      begin
         Connect_Req (Idx) := 5;  Idx := Idx + 1;
         Connect_Req (Idx) := 1;  Idx := Idx + 1;
         Connect_Req (Idx) := 0;  Idx := Idx + 1;
         Connect_Req (Idx) := 3;  Idx := Idx + 1;
         Connect_Req (Idx) := Stream_Element (Target_Host'Length);
         Idx := Idx + 1;
         Connect_Req (Idx .. Idx + Host_Bytes'Length - 1) := Host_Bytes;
         Idx := Idx + Host_Bytes'Length;
         Connect_Req (Idx) := Port_Hi;  Idx := Idx + 1;
         Connect_Req (Idx) := Port_Lo;

         Send_Socket (Socket, Connect_Req, Last);
         Receive_Socket (Socket, Reply, Last);

         if Last < 2 or else Reply (2) /= 0 then
            raise Socket_Error with "SOCKS5: connect failed (REP="
              & Stream_Element'Image (Reply (2)) & ")";
         end if;
      end;
   end Socks5_Tunnel;

   --------------------------
   --  TLS over socket     --
   --------------------------

    function Wrap_With_TLS
     (Socket : GNAT.Sockets.Socket_Type; Host : String)
      return SSL_Handle
   is
      Ctx    : SSL_CTX;
      Handle : SSL_Handle;
      FD     : constant int := int (To_C (Socket));
      Ret    : int;
   begin
      Ctx := SSL_CTX_new (TLS_method);
      if Ctx = Null_CTX then
         raise Socket_Error with "SSL_CTX_new failed";
      end if;

      SSL_CTX_set_verify (Ctx, SSL_VERIFY_NONE, Null_Pointer);

      Handle := SSL_new (Ctx);
      if Handle = Null_Handle then
         SSL_CTX_free (Ctx);
         raise Socket_Error with "SSL_new failed";
      end if;

      Ret := SSL_set_fd (Handle, FD);
      if Ret <= 0 then
         SSL_free (Handle);
         SSL_CTX_free (Ctx);
         raise Socket_Error with "SSL_set_fd failed";
      end if;

      --  Set SNI hostname
      declare
         Host_Arr : constant Interfaces.C.char_array := Interfaces.C.To_C (Host);
         Ignored  : long := SSL_set_tlsext_host_name (Handle, Host_Arr);
         pragma Unreferenced (Ignored);
      begin
         null;
      end;

      Ret := SSL_connect (Handle);
      if Ret <= 0 then
         SSL_free (Handle);
         SSL_CTX_free (Ctx);
         raise Socket_Error with "SSL_connect failed";
      end if;

       return Handle;
    end Wrap_With_TLS;

    --------------------------
    --  poll-based timeout  --
    --------------------------

    type Pollfd is record
       Fd      : Interfaces.C.int;
       Events    : Interfaces.C.short;
       Revents   : Interfaces.C.short;
    end record;
    pragma Convention (C, Pollfd);

    POLLIN : constant := 1;

    function C_Poll
      (Fds     : access Pollfd;
       Nfds    : Interfaces.C.int;
       Timeout : Interfaces.C.int) return Interfaces.C.int;
    pragma Import (C, C_Poll, "poll");

     function Wait_For_Data
      (Socket  : GNAT.Sockets.Socket_Type;
       Timeout_Sec : Natural) return Boolean is
        Pfd : aliased Pollfd;
        Ret : Interfaces.C.int;
    begin
       Pfd := (Fd => Interfaces.C.int (GNAT.Sockets.To_C (Socket)), Events => POLLIN, Revents => 0);
       Ret := C_Poll (Pfd'Unchecked_Access, 1, Interfaces.C.int (Timeout_Sec * 1000));
       return Ret > 0;
    end Wait_For_Data;

    procedure TLS_Read_All
      (Handle    : SSL_Handle;
       Socket    : GNAT.Sockets.Socket_Type;
       Response  : out Unbounded_String) is
        Buffer     : Stream_Element_Array (1 .. 8192);
        Ret        : int;
        Read_Count : Natural := 0;
    begin
       Response := Null_Unbounded_String;
       loop
          exit when not Wait_For_Data (Socket, 5);
          Ret := SSL_read (Handle, Buffer (Buffer'First)'Address, int (Buffer'Length));
          exit when Ret <= 0;
          for I in 1 .. Natural (Ret) loop
             Append (Response, Character'Val (Buffer (Stream_Element_Offset (I))));
          end loop;
          exit when Read_Count >= 50;
          Read_Count := Read_Count + 1;
       end loop;
    end TLS_Read_All;

   procedure TLS_Write_All
     (Handle     : SSL_Handle;
      Data       : Stream_Element_Array;
      Sent_Last  : out Stream_Element_Offset) is
      Ret       : int;
      Offset    : Stream_Element_Offset := Data'First;
      Remaining : Stream_Element_Offset;
   begin
      Sent_Last := Data'First - 1;
      loop
         Remaining := Data'Last - Offset + 1;
         exit when Remaining <= 0;
         Ret := SSL_write (Handle, Data (Offset)'Address, int (Integer (Remaining)));
         exit when Ret <= 0;
         Offset := Offset + Stream_Element_Offset (Ret);
         Sent_Last := Offset - 1;
      end loop;
   end TLS_Write_All;

   --------------------------
   --  HTTP client         --
   --------------------------

    function Perform_Request
      (URL          : String;
       Method       : String  := "POST";
       Content_Type : String  := "application/json";
       Data         : String  := "";
       API_Key      : String  := "";
       Extra_Headers : String := "";
       Proxy        : Proxy_Settings := (others => <>))
       return HTTP_Response
   is
      Parsed   : constant Parsed_URL := Parse_URL (URL);
      Host     : constant String := To_String (Parsed.Host);
      Port     : constant Positive := (if Parsed.Port = 0 then 443 else Positive (Parsed.Port));
      Path     : constant String := To_String (Parsed.Path);
      Socket   : GNAT.Sockets.Socket_Type;
      Handle   : SSL_Handle;
      Resp     : HTTP_Response;
      All_Data : Unbounded_String;
   begin
       GNAT.Sockets.Create_Socket (Socket, Family_Inet, GNAT.Sockets.Socket_Stream);

       if Proxy.Mode = Socks5 then
          Socks5_Tunnel (Socket, To_String (Proxy.Host), Proxy.Port,
                         Host, Port,
                         To_String (Proxy.Username), To_String (Proxy.Password));
       else
          declare
             Host_IP    : Inet_Addr_Type;
             Srv_Addr   : Sock_Addr_Type;
          begin
             if Host_Is_IP (Host) then
                Host_IP := Inet_Addr (Host);
             else
                declare
                   Host_Entry : constant Host_Entry_Type := Get_Host_By_Name (Host);
                begin
                   if Addresses_Length (Host_Entry) > 0 then
                      Host_IP := Addresses (Host_Entry, 1);
                   else
                      Host_IP := Inet_Addr ("127.0.0.1");
                   end if;
                end;
             end if;
             Srv_Addr := (Family => Family_Inet, Addr => Host_IP,
                          Port   => Port_Type (Port));
             Connect_Socket (Socket, Srv_Addr);
          end;
       end if;

      --  TLS handshake
      Handle := Wrap_With_TLS (Socket, Host);

       --  Build and send HTTP request
       declare
          Req_Line  : constant String := Method & " " & Path & " HTTP/1.1"
                        & ASCII.CR & ASCII.LF;
          Headers   : Unbounded_String :=
            To_Unbounded_String ("Host: " & Host & ASCII.CR & ASCII.LF);
          Len_Str   : constant String :=
            Fixed.Trim (Data'Length'Image, Ada.Strings.Both);
       begin
          Append (Headers, "User-Agent: Langchain4a/0.1" & ASCII.CR & ASCII.LF);
           Append (Headers, "Connection: close" & ASCII.CR & ASCII.LF);
           if API_Key /= "" then
             Append (Headers, "Authorization: Bearer " & API_Key & ASCII.CR & ASCII.LF);
          end if;
          if Content_Type /= "" then
             Append (Headers, "Content-Type: " & Content_Type & ASCII.CR & ASCII.LF);
          end if;
          if Extra_Headers /= "" then
             Append (Headers, Extra_Headers);
          end if;
          declare
             Full_Req : constant String :=
               Req_Line & To_String (Headers)
                 & "Content-Length: " & Len_Str
                 & ASCII.CR & ASCII.LF & ASCII.CR & ASCII.LF & Data;
            Sent_Last : Stream_Element_Offset;
         begin
            TLS_Write_All (Handle, To_SEA (Full_Req), Sent_Last);
         end;
      end;

       --  Read full response
       TLS_Read_All (Handle, Socket, All_Data);

       --  Parse status code and split headers/body
       declare
          Full_Response : constant String := To_String (All_Data);
          CRLF_CRLF     : constant String := (ASCII.CR & ASCII.LF & ASCII.CR & ASCII.LF);
          Header_End    : constant Natural := Fixed.Index (Full_Response, CRLF_CRLF);
       begin
          if Header_End > 0 then
             declare
                Headers : constant String := Full_Response (1 .. Header_End - 1);
                Status_Pos  : constant Natural := Fixed.Index (Headers, " ");
                Body_Part    : constant String :=
                  Full_Response (Header_End + CRLF_CRLF'Length .. Full_Response'Last);
                Is_Chunked : constant Boolean :=
                  Fixed.Index (Headers, "Transfer-Encoding: chunked") > 0;
                DeChunked    : constant String :=
                  (if Is_Chunked then DeChunk (Body_Part) else Body_Part);
             begin
                if Status_Pos > 0
                 and then Status_Pos + 3 <= Headers'Last
                then
                   declare
                      Codes : constant String := Headers (Status_Pos + 1 .. Status_Pos + 3);
                   begin
                      if Codes (Codes'First) in '0' .. '9' then
                         Resp.Status_Code := Natural (Integer'Value (Codes));
                      end if;
                   end;
                end if;
                Resp.Content := To_Unbounded_String (DeChunked);
             end;
          else
             Resp.Content := To_Unbounded_String (Full_Response);
          end if;
       end;

      --  Cleanup
      declare
         Ignored : int := SSL_shutdown (Handle);
         pragma Unreferenced (Ignored);
      begin
         null;
      end;
      SSL_free (Handle);
      GNAT.Sockets.Close_Socket (Socket);

      return Resp;
   exception
      when others =>
         GNAT.Sockets.Close_Socket (Socket);
         raise;
   end Perform_Request;

end Langchain4a.Net;
