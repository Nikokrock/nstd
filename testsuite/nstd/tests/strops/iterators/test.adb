with Test_Assert;
with Test_Measure; use Test_Measure;
with NStd.Strops; use NStd.Strops;
with NStd.Byteops; use NStd.Byteops;
with NStd; use NStd;

function Test return Integer is
   package A renames Test_Assert;

   S      : constant Str := Clone ("0001230012");
   Long_S : constant Str := S * (100 * 1024 * 1024);

   B      : constant Bytes := Clone ("0001230012");
   Long_B : constant Bytes := B * (100 * 1024 * 1024);
   Byte_Measure : Duration;

   Counter : UInt64 := 0;
begin

   for Codepoint of S loop
      if Codepoint = 16#30# then
         Counter := Counter + 1;
      end if;
   end loop;
   A.Assert (Counter = 5);

   Start_Measure;
   Counter := 0;
   for B of Long_B loop
      if B = 16#30# then
         Counter := Counter + 1;
      end if;
   end loop;
   End_Measure;
   Display_Measure ("counter" & Counter'Img);
   Byte_Measure := Measure_Time;

   Start_Measure;
   Counter := 0;
   for Codepoint of Long_S loop
      if Codepoint = 16#30# then
         Counter := Counter + 1;
      end if;
   end loop;
   End_Measure;
   Display_Measure ("counter" & Counter'Img, Compare_With=>Byte_Measure);
   A.Assert (Counter = 144);
   return A.Report;

end Test;
