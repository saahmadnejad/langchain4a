--  Frontend + backend unit tests for Langchain4a.Net.JSON extraction.

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;

with Langchain4a.Net.JSON;

package body Net_Json_Tests is

   use AUnit.Assertions;
   use Langchain4a.Net.JSON;

   package Caller is new AUnit.Test_Caller (Test_Fixture);

   overriding procedure Set_Up (T : in out Test_Fixture) is
      pragma Unreferenced (T);
   begin
      null;
   end Set_Up;

   overriding procedure Tear_Down (T : in out Test_Fixture) is
      pragma Unreferenced (T);
   begin
      null;
   end Tear_Down;

   --------------------------------------------------------------------------
   --  Extract_Json_String tests
   --------------------------------------------------------------------------

   procedure Given_JsonObjectWithString_When_KeyProvided_Then_StringValueReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      --  Act
      declare
         Result : constant String :=
           Extract_Json_String ("{""key"": ""value""}", "key");
      begin
         --  Assert
         Assert (Result = "value",
                 "Expected 'value' for simple string key");
      end;
   end Given_JsonObjectWithString_When_KeyProvided_Then_StringValueReturned;

   procedure Given_JsonObjectWithoutKey_When_KeyProvided_Then_EmptyStringReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      --  Act
      declare
         Result : constant String :=
           Extract_Json_String ("{""foo"": ""bar""}", "key");
      begin
         --  Assert
         Assert (Result = "",
                 "Missing key should return empty string");
      end;
   end Given_JsonObjectWithoutKey_When_KeyProvided_Then_EmptyStringReturned;

   procedure Given_JsonObjectWithEscapedQuote_When_KeyProvided_Then_QuoteUnescaped
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         JSON : constant String :=
           "{""key"": ""hello \""world\"""" }";
      begin
         --  Act
         declare
            Result : constant String := Extract_Json_String (JSON, "key");
         begin
            --  Assert
            Assert (Result = "hello ""world""",
                    "Escaped quotes should be unescaped, got: " & Result);
         end;
      end;
   end Given_JsonObjectWithEscapedQuote_When_KeyProvided_Then_QuoteUnescaped;

   procedure Given_JsonObjectWithEscapedNewline_When_KeyProvided_Then_LFReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         JSON : constant String :=
           "{""key"": ""hello\nworld""}";
      begin
         --  Act
         declare
            Result : constant String := Extract_Json_String (JSON, "key");
         begin
            --  Assert
            Assert (Result = "hello" & ASCII.LF & "world",
                    "Escaped newline should produce LF");
         end;
      end;
   end Given_JsonObjectWithEscapedNewline_When_KeyProvided_Then_LFReturned;

   procedure Given_JsonObjectWithEscapedTab_When_KeyProvided_Then_HTReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         JSON : constant String :=
           "{""key"": ""col1\tcol2""}";
      begin
         --  Act
         declare
            Result : constant String := Extract_Json_String (JSON, "key");
         begin
            --  Assert
            Assert (Result = "col1" & ASCII.HT & "col2",
                    "Escaped tab should produce HT");
         end;
      end;
   end Given_JsonObjectWithEscapedTab_When_KeyProvided_Then_HTReturned;

   procedure Given_JsonObjectWithMultipleKeys_When_AnyKeyProvided_Then_CorrectValueReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         JSON : constant String :=
           "{""a"": ""1"", ""b"": ""2"", ""c"": ""3""}";
      begin
         --  Act
         declare
            Val_A : constant String := Extract_Json_String (JSON, "a");
            Val_B : constant String := Extract_Json_String (JSON, "b");
            Val_C : constant String := Extract_Json_String (JSON, "c");
         begin
            --  Assert
            Assert (Val_A = "1", "Extract key a");
            Assert (Val_B = "2", "Extract key b");
            Assert (Val_C = "3", "Extract key c");
         end;
      end;
   end Given_JsonObjectWithMultipleKeys_When_AnyKeyProvided_Then_CorrectValueReturned;

   procedure Given_JsonObjectWithWhitespace_When_KeyProvided_Then_ValueExtracted
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         JSON : constant String := "{ ""key"": ""value"" }";
      begin
         --  Act
         declare
            Result : constant String := Extract_Json_String (JSON, "key");
         begin
            --  Assert
            Assert (Result = "value",
                    "Should extract value with whitespace around braces");
         end;
      end;
   end Given_JsonObjectWithWhitespace_When_KeyProvided_Then_ValueExtracted;

   procedure Given_JsonObjectWithSimilarKeyNames_When_ShortKeyProvided_Then_CorrectValueReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         JSON : constant String :=
           "{""content"": ""hello"", ""my_content"": ""world""}";
      begin
         --  Act
         declare
            Val_Short : constant String := Extract_Json_String (JSON, "content");
            Val_Long  : constant String := Extract_Json_String (JSON, "my_content");
         begin
            --  Assert
            Assert (Val_Short = "hello",
                    "Should find 'content', not 'my_content'");
            Assert (Val_Long = "world",
                    "Should find 'my_content'");
         end;
      end;
   end Given_JsonObjectWithSimilarKeyNames_When_ShortKeyProvided_Then_CorrectValueReturned;

   procedure Given_JsonObjectWithEmptyStringValue_When_KeyProvided_Then_EmptyStringReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      --  Act
      declare
         Result : constant String :=
           Extract_Json_String ("{""key"": """"}", "key");
      begin
         --  Assert
         Assert (Result = "",
                 "Empty string value should return empty");
      end;
   end Given_JsonObjectWithEmptyStringValue_When_KeyProvided_Then_EmptyStringReturned;

   procedure Given_JsonObjectWithNestedObject_When_KeyAfterNested_Then_ValueReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         JSON : constant String :=
           "{""outer"": {""inner"": ""value""}, ""key"": ""found""}";
      begin
         --  Act
         declare
            Result : constant String := Extract_Json_String (JSON, "key");
         begin
            --  Assert
            Assert (Result = "found",
                    "Should extract value after nested object");
         end;
      end;
   end Given_JsonObjectWithNestedObject_When_KeyAfterNested_Then_ValueReturned;

   procedure Given_JsonObjectWithArrayValue_When_KeyProvided_Then_EmptyStringReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      declare
         JSON : constant String :=
           "{""key"": [1, 2, 3]}";
      begin
         --  Act
         declare
            Result : constant String := Extract_Json_String (JSON, "key");
         begin
            --  Assert
            Assert (Result = "",
                    "Array value should return empty (not a JSON string)");
         end;
      end;
   end Given_JsonObjectWithArrayValue_When_KeyProvided_Then_EmptyStringReturned;

   --------------------------------------------------------------------------
   --  Extract_Json_Integer tests
   --------------------------------------------------------------------------

   procedure Given_JsonObjectWithInteger_When_KeyProvided_Then_IntegerValueReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      --  Act
      declare
         Result : constant Natural :=
           Extract_Json_Integer ("{""key"": 42}", "key");
      begin
         --  Assert
         Assert (Result = 42, "Expected 42 for integer value");
      end;
   end Given_JsonObjectWithInteger_When_KeyProvided_Then_IntegerValueReturned;

   procedure Given_JsonObjectWithoutIntegerKey_When_KeyProvided_Then_ZeroReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      --  Act
      declare
         Result : constant Natural :=
           Extract_Json_Integer ("{""foo"": 42}", "key");
      begin
         --  Assert
         Assert (Result = 0, "Missing integer key should return 0");
      end;
   end Given_JsonObjectWithoutIntegerKey_When_KeyProvided_Then_ZeroReturned;

   procedure Given_JsonObjectWithZero_When_KeyProvided_Then_ZeroReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      --  Act
      declare
         Result : constant Natural :=
           Extract_Json_Integer ("{""key"": 0}", "key");
      begin
         --  Assert
         Assert (Result = 0, "Expected 0 for zero integer value");
      end;
   end Given_JsonObjectWithZero_When_KeyProvided_Then_ZeroReturned;

   procedure Given_JsonObjectWithLargeInteger_When_KeyProvided_Then_LargeIntegerReturned
     (T : in out Test_Fixture)
   is
      pragma Unreferenced (T);
   begin
      --  Arrange
      --  Act
      declare
         Result : constant Natural :=
           Extract_Json_Integer ("{""key"": 999999}", "key");
      begin
         --  Assert
         Assert (Result = 999999, "Expected 999999 for large integer value");
      end;
   end Given_JsonObjectWithLargeInteger_When_KeyProvided_Then_LargeIntegerReturned;

   --------------------------------------------------------------------------
   --  Suite
   --------------------------------------------------------------------------

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      S : constant AUnit.Test_Suites.Access_Test_Suite :=
            AUnit.Test_Suites.New_Suite;
   begin
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract simple JSON string",
                           Given_JsonObjectWithString_When_KeyProvided_Then_StringValueReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract missing key returns empty",
                           Given_JsonObjectWithoutKey_When_KeyProvided_Then_EmptyStringReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract escaped quote in JSON",
                           Given_JsonObjectWithEscapedQuote_When_KeyProvided_Then_QuoteUnescaped'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract escaped newline in JSON",
                           Given_JsonObjectWithEscapedNewline_When_KeyProvided_Then_LFReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract escaped tab in JSON",
                           Given_JsonObjectWithEscapedTab_When_KeyProvided_Then_HTReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract multiple keys from JSON",
                           Given_JsonObjectWithMultipleKeys_When_AnyKeyProvided_Then_CorrectValueReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract with whitespace tolerance",
                           Given_JsonObjectWithWhitespace_When_KeyProvided_Then_ValueExtracted'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract similar key names",
                           Given_JsonObjectWithSimilarKeyNames_When_ShortKeyProvided_Then_CorrectValueReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract empty string value",
                           Given_JsonObjectWithEmptyStringValue_When_KeyProvided_Then_EmptyStringReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract value after nested object",
                           Given_JsonObjectWithNestedObject_When_KeyAfterNested_Then_ValueReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract array value returns empty",
                           Given_JsonObjectWithArrayValue_When_KeyProvided_Then_EmptyStringReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract simple integer",
                           Given_JsonObjectWithInteger_When_KeyProvided_Then_IntegerValueReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract integer missing key returns 0",
                           Given_JsonObjectWithoutIntegerKey_When_KeyProvided_Then_ZeroReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract zero integer value",
                           Given_JsonObjectWithZero_When_KeyProvided_Then_ZeroReturned'Access));
      AUnit.Test_Suites.Add_Test
        (S, Caller.Create ("Extract large integer value",
                           Given_JsonObjectWithLargeInteger_When_KeyProvided_Then_LargeIntegerReturned'Access));
      return S;
   end Suite;

end Net_Json_Tests;
