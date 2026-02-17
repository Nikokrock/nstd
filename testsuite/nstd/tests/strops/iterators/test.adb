with Test_Assert;
with NStd.Strops; use NStd.Strops;
with NStd; use NStd;

function Test return Integer is

   package A renames Test_Assert;

   S      : constant Str := Clone ("0001230012");
   Long_S : constant Str := S * (10 * 1024 * 1024);

   Counter : UInt64 := 0;
begin

   for Codepoint of S loop
      if Codepoint = 16#30# then
         Counter := Counter + 1;
      end if;
   end loop;
   A.Assert (Counter = 5);

   Counter := 0;

   for Codepoint of Long_S loop
      if Codepoint = 16#30# then
         Counter := Counter + 1;
      end if;
   end loop;
   A.Assert (Counter = 5 * 10 * 1024 * 1024);

   return A.Report;

end Test;
