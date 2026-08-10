--  Frontend + backend unit tests for Langchain4a.Net.JSON extraction.
--  Tests public functions Extract_Json_String and Extract_Json_Integer.

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

with Langchain4a.Net.JSON;

package Net_Json_Tests is

   type Test_Fixture is new AUnit.Test_Fixtures.Test_Fixture with record
      null;
   end record;

   overriding procedure Set_Up (T : in out Test_Fixture);
   overriding procedure Tear_Down (T : in out Test_Fixture);

   --  Extract_Json_String tests
   procedure Given_JsonObjectWithString_When_KeyProvided_Then_StringValueReturned
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithoutKey_When_KeyProvided_Then_EmptyStringReturned
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithEscapedQuote_When_KeyProvided_Then_QuoteUnescaped
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithEscapedNewline_When_KeyProvided_Then_LFReturned
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithEscapedTab_When_KeyProvided_Then_HTReturned
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithMultipleKeys_When_AnyKeyProvided_Then_CorrectValueReturned
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithWhitespace_When_KeyProvided_Then_ValueExtracted
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithSimilarKeyNames_When_ShortKeyProvided_Then_CorrectValueReturned
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithEmptyStringValue_When_KeyProvided_Then_EmptyStringReturned
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithNestedObject_When_KeyAfterNested_Then_ValueReturned
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithArrayValue_When_KeyProvided_Then_EmptyStringReturned
     (T : in out Test_Fixture);

   --  Extract_Json_Integer tests
   procedure Given_JsonObjectWithInteger_When_KeyProvided_Then_IntegerValueReturned
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithoutIntegerKey_When_KeyProvided_Then_ZeroReturned
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithZero_When_KeyProvided_Then_ZeroReturned
     (T : in out Test_Fixture);
   procedure Given_JsonObjectWithLargeInteger_When_KeyProvided_Then_LargeIntegerReturned
     (T : in out Test_Fixture);

   function Suite return AUnit.Test_Suites.Access_Test_Suite;

end Net_Json_Tests;
