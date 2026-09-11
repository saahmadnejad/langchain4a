--  Unit tests for Langchain4a.Chains.Simple.

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

with Ada.Characters.Latin_1;
with Ada.Strings.Unbounded;

with Langchain4a.Core;
with Langchain4a.Chains.Simple;

package body Chains_Tests is

   use AUnit.Assertions;
   use Langchain4a.Core;
   use Langchain4a.Chains.Simple;

   package Caller is new AUnit.Test_Caller (Test_Fixture);

   --------------------------------------------------------------------------
   --  Mock client: records last prompt, replies with a canned response.
   --  Library-level: Simple_Chain stores access, pointee must outlive
   --  any single test procedure.
   --------------------------------------------------------------------------

   Mock_Failure : exception;

   type Mock_Client is new LLM_Model with record
      Sent       : Ada.Strings.Unbounded.Unbounded_String;
      Reply_Text : Ada.Strings.Unbounded.Unbounded_String;
      Fails      : Boolean := False;
   end record;

   overriding procedure Send_Prompt (M : in out Mock_Client; P : Prompt);
   overriding function Get_Response (M : Mock_Client) return LLM_Response;

   overriding procedure Send_Prompt (M : in out Mock_Client; P : Prompt) is
   begin
      if M.Fails then
         raise Mock_Failure with "mock network failure";
      end if;
      M.Sent := Ada.Strings.Unbounded.To_Unbounded_String (String (P));
   end Send_Prompt;

   overriding function Get_Response (M : Mock_Client) return LLM_Response is
   begin
      return LLM_Response'
        (Text   => M.Reply_Text,
         Tokens => 0);
   end Get_Response;

   Mock : aliased Mock_Client;

   overriding procedure Set_Up (T : in out Test_Fixture) is
      pragma Unreferenced (T);
   begin
      Mock.Sent := Ada.Strings.Unbounded.Null_Unbounded_String;
      Mock.Reply_Text := Ada.Strings.Unbounded.Null_Unbounded_String;
   end Set_Up;

   overriding procedure Tear_Down (T : in out Test_Fixture) is
      pragma Unreferenced (T);
   begin
      null;
   end Tear_Down;

   --------------------------------------------------------------------------
   --  Build_Prompt tests
   --------------------------------------------------------------------------

   procedure Given_NoTemplateNoHistory_When_BuildPromptCalled_Then_InputOnlyReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         C : Simple_Chain;
      begin
         --  Act
         declare
            Result : constant String := C.Build_Prompt ("hello");
         begin
            --  Assert
            Assert (Result = "hello", "Expected input-only prompt");
         end;
      end;
   end Given_NoTemplateNoHistory_When_BuildPromptCalled_Then_InputOnlyReturned;

   procedure Given_TemplateSet_When_BuildPromptCalled_Then_TemplatePrepended
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         C : Simple_Chain;
      begin
         C.Configure (Client => null, Template => "You are terse.");
         --  Act
         declare
            Result : constant String := C.Build_Prompt ("hello");
         begin
            --  Assert
            Assert (Result = "You are terse." & Ada.Characters.Latin_1.LF & "hello",
                    "Expected template prepended before input");
         end;
      end;
   end Given_TemplateSet_When_BuildPromptCalled_Then_TemplatePrepended;

   procedure Given_HistoryAndInput_When_BuildPromptCalled_Then_HistoryPrepended
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         C    : Simple_Chain;
      begin
         Mock.Reply_Text :=
           Ada.Strings.Unbounded.To_Unbounded_String ("hi there");
         C.Configure (Client => Mock'Access, Template => "");
         C.Set_Input ("hello");
         C.Run;
         --  Act
         declare
            Result : constant String := C.Build_Prompt ("next question");
         begin
            --  Assert
            Assert (Result = "user: hello" & Ada.Characters.Latin_1.LF
                    & "assistant: hi there" & Ada.Characters.Latin_1.LF
                    & "next question",
                    "Expected history lines before new input");
         end;
      end;
   end Given_HistoryAndInput_When_BuildPromptCalled_Then_HistoryPrepended;

   procedure Given_TemplateAndHistory_When_BuildPromptCalled_Then_AllPartsJoinedByLF
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         C    : Simple_Chain;
      begin
         Mock.Reply_Text :=
           Ada.Strings.Unbounded.To_Unbounded_String ("hi there");
         C.Configure (Client => Mock'Access, Template => "You are terse.");
         C.Set_Input ("hello");
         C.Run;
         --  Act
         declare
            Result : constant String := C.Build_Prompt ("next question");
         begin
            --  Assert
            Assert (Result = "You are terse." & Ada.Characters.Latin_1.LF
                    & "user: hello" & Ada.Characters.Latin_1.LF
                    & "assistant: hi there" & Ada.Characters.Latin_1.LF
                    & "next question",
                    "Expected template, history, input joined by LF");
         end;
      end;
   end Given_TemplateAndHistory_When_BuildPromptCalled_Then_AllPartsJoinedByLF;

   --------------------------------------------------------------------------
   --  Run tests
   --------------------------------------------------------------------------

   procedure Given_ConfiguredChain_When_RunCalled_Then_UserAndAssistantTurnsStored
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         C    : Simple_Chain;
      begin
         Mock.Reply_Text :=
           Ada.Strings.Unbounded.To_Unbounded_String ("mock reply");
         C.Configure (Client => Mock'Access);
         C.Set_Input ("hello");
         --  Act
         C.Run;
         --  Assert
         Assert (C.Get_Output = "mock reply",
                 "Expected mock reply stored as output");
         Assert (C.Get_History = "user: hello" & Ada.Characters.Latin_1.LF & "assistant: mock reply",
                 "Expected user and assistant turns in history");
      end;
   end Given_ConfiguredChain_When_RunCalled_Then_UserAndAssistantTurnsStored;

   procedure Given_RunCalled_When_RunCalledAgain_Then_HistoryFeedsSecondPrompt
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         C    : Simple_Chain;
      begin
         Mock.Reply_Text :=
           Ada.Strings.Unbounded.To_Unbounded_String ("first reply");
         C.Configure (Client => Mock'Access);
         C.Set_Input ("first question");
         C.Run;
         --  Act
         C.Set_Input ("second question");
         Mock.Reply_Text :=
           Ada.Strings.Unbounded.To_Unbounded_String ("second reply");
         C.Run;
         --  Assert
         Assert (Ada.Strings.Unbounded.To_String (Mock.Sent) =
                   "user: first question" & Ada.Characters.Latin_1.LF
                   & "assistant: first reply" & Ada.Characters.Latin_1.LF
                   & "second question",
                 "Expected second prompt to contain prior history");
         Assert (C.Get_History =
                   "user: first question" & Ada.Characters.Latin_1.LF
                   & "assistant: first reply" & Ada.Characters.Latin_1.LF
                   & "user: second question" & Ada.Characters.Latin_1.LF
                   & "assistant: second reply",
                 "Expected four turns in history after two runs");
      end;
   end Given_RunCalled_When_RunCalledAgain_Then_HistoryFeedsSecondPrompt;

   procedure Given_UnconfiguredChain_When_RunCalled_Then_ConstraintErrorRaised
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         C : Simple_Chain;
         Raised : Boolean := False;
      begin
         C.Set_Input ("hello");
         --  Act
         begin
            C.Run;
         exception
            when Constraint_Error => Raised := True;
         end;
         --  Assert
         Assert (Raised, "Expected Constraint_Error from unconfigured Run");
      end;
   end Given_UnconfiguredChain_When_RunCalled_Then_ConstraintErrorRaised;

   procedure Given_FailingClient_When_RunCalled_Then_HistoryUnchanged
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         C : Simple_Chain;
         Raised : Boolean := False;
      begin
         Mock.Reply_Text :=
           Ada.Strings.Unbounded.To_Unbounded_String ("should not appear");
         C.Configure (Client => Mock'Access);
         C.Set_Input ("hello");
         Mock.Fails := True;
         --  Act
         begin
            C.Run;
         exception
            when Mock_Failure => Raised := True;
         end;
         --  Assert
         Assert (Raised, "Expected Send_Prompt failure to propagate");
         Assert (C.Get_History = "",
                 "Expected history untouched after failed Run");
         Assert (C.Get_Output = "",
                 "Expected output untouched after failed Run");
      end;
   end Given_FailingClient_When_RunCalled_Then_HistoryUnchanged;

   --------------------------------------------------------------------------
   --  Suite
   --------------------------------------------------------------------------

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      S : constant AUnit.Test_Suites.Access_Test_Suite :=
            AUnit.Test_Suites.New_Suite;
   begin
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Build prompt with no template or history",
                           Given_NoTemplateNoHistory_When_BuildPromptCalled_Then_InputOnlyReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Build prompt prepends template",
                           Given_TemplateSet_When_BuildPromptCalled_Then_TemplatePrepended'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Build prompt prepends history",
                           Given_HistoryAndInput_When_BuildPromptCalled_Then_HistoryPrepended'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Build prompt joins template, history, input",
                           Given_TemplateAndHistory_When_BuildPromptCalled_Then_AllPartsJoinedByLF'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Run stores user and assistant turns",
                           Given_ConfiguredChain_When_RunCalled_Then_UserAndAssistantTurnsStored'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Second run feeds history into prompt",
                           Given_RunCalled_When_RunCalledAgain_Then_HistoryFeedsSecondPrompt'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Run without client raises Constraint_Error",
                           Given_UnconfiguredChain_When_RunCalled_Then_ConstraintErrorRaised'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Failed Send_Prompt leaves history unchanged",
                           Given_FailingClient_When_RunCalled_Then_HistoryUnchanged'Access));
      return S;
   end Suite;

end Chains_Tests;
