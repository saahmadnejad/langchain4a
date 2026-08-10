--  Main entry point for all langchain4a unit tests.
--  Run with: gnatmake -P tests/tests.gpr

with Ada.Text_IO;
with AUnit.Reporter.Text;
with AUnit.Run;

with Test_Suite;

procedure Test_Main is
   procedure Runner is new AUnit.Run.Test_Runner (Test_Suite.Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
begin
   Ada.Text_IO.Put_Line ("=== Langchain4a Test Suite ===");
   Ada.Text_IO.New_Line;

   Runner (Reporter);
end Test_Main;
