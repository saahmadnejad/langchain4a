--  Backend tests for Langchain4a.Net.Perform_Request (plain HTTP path).
--  Spins up a local listener socket inside the test, no external services.

with AUnit.Assertions;
with AUnit.Test_Caller;
with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Net_Tests is

   type Test_Fixture is new AUnit.Test_Fixtures.Test_Fixture with record
      null;
   end record;

   --  Perform_Request tests (plain HTTP against local listener)
   procedure Given_LocalHttpListener_When_PostRequest_Then_StatusAndBodyParsed
     (T : in out Test_Fixture);
   procedure Given_UnsupportedScheme_When_Request_Then_SocketErrorRaised
     (T : in out Test_Fixture);

   function Suite return AUnit.Test_Suites.Access_Test_Suite;

end Net_Tests;
