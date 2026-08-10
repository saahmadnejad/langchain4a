--  Root test suite: collects all sub-suites from individual test modules.

with AUnit.Test_Suites;

with Net_Json_Tests;
with Config_Tests;
with OpenRouter_Tests;
with OpenAI_Tests;
with Langchain4a_Tests;

package body Test_Suite is

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      S : constant AUnit.Test_Suites.Access_Test_Suite :=
            AUnit.Test_Suites.New_Suite;
   begin
      AUnit.Test_Suites.Add_Test (S, Net_Json_Tests.Suite);
      AUnit.Test_Suites.Add_Test (S, Config_Tests.Suite);
      AUnit.Test_Suites.Add_Test (S, OpenRouter_Tests.Suite);
      AUnit.Test_Suites.Add_Test (S, OpenAI_Tests.Suite);
      AUnit.Test_Suites.Add_Test (S, Langchain4a_Tests.Suite);
      return S;
   end Suite;

end Test_Suite;
