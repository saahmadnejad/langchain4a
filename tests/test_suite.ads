--  Root test suite: collects all sub-suites from individual test modules.

with AUnit.Test_Suites;

with Net_Json_Tests;
with Config_Tests;
with OpenRouter_Tests;
with OpenAI_Tests;
with Langchain4a_Tests;

package Test_Suite is

   function Suite return AUnit.Test_Suites.Access_Test_Suite;

end Test_Suite;
