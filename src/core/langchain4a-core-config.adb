--  Configuration types and loading for Langchain4a.

with Ada.Text_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with GNAT.OS_Lib;
with Langchain4a.Net;

package body Langchain4a.Core.Config is

   use Ada.Text_IO;
   use Ada.Strings.Unbounded;
   use Langchain4a.Net;

   function Get_Env (Key : String) return String is
   begin
      return GNAT.OS_Lib.Getenv (Key).all;
   exception
      when Constraint_Error =>
         return "";
   end Get_Env;

   function Parse_Proxy_Mode (Val : String) return Proxy_Mode is
     (if Val = "socks5" then Socks5 else Disabled);

   ----------
   --  Proxy field setters (shared by Load_Config and Load_From_Env)
   --  Each sets the field on BOTH OpenRouter and OpenAI configs,
   --  ensuring proxy settings stay in sync across providers (SRP).
   ----------

   procedure Set_Proxy_Mode (Config : in out Configuration; Mode : Proxy_Mode) is
   begin
      Config.OpenRouter_Cfg.Proxy.Mode := Mode;
      Config.OpenAI_Cfg.Proxy.Mode := Mode;
   end Set_Proxy_Mode;

   procedure Set_Proxy_Host (Config : in out Configuration; Host : String) is
   begin
      Config.OpenRouter_Cfg.Proxy.Host := To_Unbounded_String (Host);
      Config.OpenAI_Cfg.Proxy.Host := To_Unbounded_String (Host);
   end Set_Proxy_Host;

   procedure Set_Proxy_Port (Config : in out Configuration; Port : Natural) is
   begin
      Config.OpenRouter_Cfg.Proxy.Port := Port;
      Config.OpenAI_Cfg.Proxy.Port := Port;
   end Set_Proxy_Port;

   procedure Set_Proxy_User (Config : in out Configuration; User : String) is
   begin
      Config.OpenRouter_Cfg.Proxy.Username := To_Unbounded_String (User);
      Config.OpenAI_Cfg.Proxy.Username := To_Unbounded_String (User);
   end Set_Proxy_User;

   procedure Set_Proxy_Pass (Config : in out Configuration; Pass : String) is
   begin
      Config.OpenRouter_Cfg.Proxy.Password := To_Unbounded_String (Pass);
      Config.OpenAI_Cfg.Proxy.Password := To_Unbounded_String (Pass);
   end Set_Proxy_Pass;

   ----------
   --  Load_Config
   ----------

   procedure Load_Config (Config : out Configuration; File_Path : String) is
      File : File_Type;
      Line : String (1 .. 256);
      Last : Natural;
   begin
      Open (File, In_File, File_Path);
      while not End_Of_File (File) loop
         Get_Line (File, Line, Last);
         declare
            Full_Line : constant String :=
              Ada.Strings.Fixed.Trim (Line (1 .. Last), Ada.Strings.Both);
         begin
            if Full_Line'Length > 0 and then Full_Line (Full_Line'First) /= '#' then
               declare
                  Eq_Pos : constant Natural :=
                    Ada.Strings.Fixed.Index (Full_Line, "=");
               begin
                  if Eq_Pos > 0 then
                     declare
                        Key : constant String :=
                          Ada.Strings.Fixed.Trim (Full_Line (Full_Line'First .. Eq_Pos - 1),
                                                  Ada.Strings.Both);
                        Val : constant String :=
                          Ada.Strings.Fixed.Trim (Full_Line (Eq_Pos + 1 .. Full_Line'Last),
                                                  Ada.Strings.Both);
                     begin
                        if Key = "provider" then
                           if Val = "openrouter" then
                              Config.Provider := OpenRouter;
                           elsif Val = "openai" then
                              Config.Provider := OpenAI;
                           end if;
                        elsif Key = "openrouter_endpoint" then
                           Config.OpenRouter_Cfg.Endpoint := To_Unbounded_String (Val);
                        elsif Key = "openrouter_model" then
                           Config.OpenRouter_Cfg.Model := To_Unbounded_String (Val);
                        elsif Key = "openrouter_temperature" then
                           Config.OpenRouter_Cfg.Temperature := Float'Value (Val);
                        elsif Key = "openrouter_max_tokens" then
                           Config.OpenRouter_Cfg.Max_Tokens := Natural'Value (Val);
                        elsif Key = "openrouter_site_url" then
                           Config.OpenRouter_Cfg.Site_URL := To_Unbounded_String (Val);
                        elsif Key = "openrouter_app_name" then
                           Config.OpenRouter_Cfg.App_Name := To_Unbounded_String (Val);
                        elsif Key = "openai_endpoint" then
                           Config.OpenAI_Cfg.Endpoint := To_Unbounded_String (Val);
                        elsif Key = "openai_model" then
                           Config.OpenAI_Cfg.Model := To_Unbounded_String (Val);
                        elsif Key = "openai_temperature" then
                           Config.OpenAI_Cfg.Temperature := Float'Value (Val);
                        elsif Key = "openai_max_tokens" then
                           Config.OpenAI_Cfg.Max_Tokens := Natural'Value (Val);
                        elsif Key = "proxy_mode" then
                           Set_Proxy_Mode (Config, Parse_Proxy_Mode (Val));
                        elsif Key = "proxy_host" then
                           Set_Proxy_Host (Config, Val);
                        elsif Key = "proxy_port" then
                           Set_Proxy_Port (Config, Natural'Value (Val));
                        elsif Key = "proxy_user" then
                           Set_Proxy_User (Config, Val);
                        elsif Key = "proxy_pass" then
                           Set_Proxy_Pass (Config, Val);
                        end if;
                     end;
                  end if;
               end;
            end if;
         end;
      end loop;
      Close (File);
   exception
      when others =>
         if Is_Open (File) then
            Close (File);
         end if;
         raise;
   end Load_Config;

   ----------
   --  Load_From_Env
   ----------

   procedure Load_From_Env (Config : out Configuration) is
   begin
      Config.OpenRouter_Cfg.API_Key :=
        To_Unbounded_String (Get_Env ("OPENROUTER_API_KEY"));
      Config.OpenAI_Cfg.API_Key :=
        To_Unbounded_String (Get_Env ("OPENAI_API_KEY"));

      --  OpenRouter settings
      declare
         Env_EP   : constant String := Get_Env ("OPENROUTER_ENDPOINT");
         Env_Mod  : constant String := Get_Env ("OPENROUTER_MODEL");
         Env_Tmp  : constant String := Get_Env ("OPENROUTER_TEMPERATURE");
         Env_MT   : constant String := Get_Env ("OPENROUTER_MAX_TOKENS");
         Env_URL  : constant String := Get_Env ("OPENROUTER_SITE_URL");
         Env_App  : constant String := Get_Env ("OPENROUTER_APP_NAME");
      begin
         if Env_EP /= "" then
            Config.OpenRouter_Cfg.Endpoint := To_Unbounded_String (Env_EP);
         end if;
         if Env_Mod /= "" then
            Config.OpenRouter_Cfg.Model := To_Unbounded_String (Env_Mod);
         end if;
         if Env_Tmp /= "" then
            Config.OpenRouter_Cfg.Temperature := Float'Value (Env_Tmp);
         end if;
         if Env_MT /= "" then
            Config.OpenRouter_Cfg.Max_Tokens := Natural'Value (Env_MT);
         end if;
         if Env_URL /= "" then
            Config.OpenRouter_Cfg.Site_URL := To_Unbounded_String (Env_URL);
         end if;
         if Env_App /= "" then
            Config.OpenRouter_Cfg.App_Name := To_Unbounded_String (Env_App);
         end if;
      end;

      --  OpenAI settings
      declare
         Env_EP   : constant String := Get_Env ("OPENAI_ENDPOINT");
         Env_Mod  : constant String := Get_Env ("OPENAI_MODEL");
         Env_Tmp  : constant String := Get_Env ("OPENAI_TEMPERATURE");
         Env_MT   : constant String := Get_Env ("OPENAI_MAX_TOKENS");
      begin
         if Env_EP /= "" then
            Config.OpenAI_Cfg.Endpoint := To_Unbounded_String (Env_EP);
         end if;
         if Env_Mod /= "" then
            Config.OpenAI_Cfg.Model := To_Unbounded_String (Env_Mod);
         end if;
         if Env_Tmp /= "" then
            Config.OpenAI_Cfg.Temperature := Float'Value (Env_Tmp);
         end if;
         if Env_MT /= "" then
            Config.OpenAI_Cfg.Max_Tokens := Natural'Value (Env_MT);
         end if;
      end;

      --  Proxy settings (shared across both providers)
      declare
         Mode_Str : constant String := Get_Env ("PROXY_MODE");
         Host_Str : constant String := Get_Env ("PROXY_HOST");
         Port_Str : constant String := Get_Env ("PROXY_PORT");
         User_Str : constant String := Get_Env ("PROXY_USER");
         Pass_Str : constant String := Get_Env ("PROXY_PASS");
      begin
         if Mode_Str = "socks5" then
            Set_Proxy_Mode (Config, Socks5);
            Set_Proxy_Host (Config, Host_Str);
            Set_Proxy_Port (Config,
                            (if Port_Str /= "" then Natural'Value (Port_Str) else 0));
            Set_Proxy_User (Config, User_Str);
            Set_Proxy_Pass (Config, Pass_Str);
         end if;
      end;
   end Load_From_Env;

   ----------
   --  API key accessors
   ----------

   function Get_API_Key_From_Env return Unbounded_String is
      Key : constant String := Get_Env ("OPENROUTER_API_KEY");
   begin
      return To_Unbounded_String (Key);
   end Get_API_Key_From_Env;

   function Get_OpenRouter_API_Key return Unbounded_String is
   begin
      return To_Unbounded_String (Get_Env ("OPENROUTER_API_KEY"));
   end Get_OpenRouter_API_Key;

   function Get_OpenAI_API_Key return Unbounded_String is
   begin
      return To_Unbounded_String (Get_Env ("OPENAI_API_KEY"));
   end Get_OpenAI_API_Key;

end Langchain4a.Core.Config;
