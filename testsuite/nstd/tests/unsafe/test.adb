with Test_Assert;
with Test_Measure;
with NStd;
with NStd.Unsafe;
with NStd.Byteops;
with System;
with GNAT.IO;

function Test return Integer is
   package A renames Test_Assert;
   package IO renames GNAT.IO;
   package M renames Test_Measure;

   use all type System.Address;
   use all type NStd.SizeType;
   use all type NStd.UInt32;

   procedure Assert_Allocate_Fail (Length : NStd.SizeType) is
      S : System.Address;
   begin
      S := NStd.Unsafe.Allocate (Length);
      Nstd.Unsafe.Free (S);
      A.Assert
         (False, "exception not raised for allocate of size" & Length'Img);
   exception
      when Storage_Error =>
         A.Assert (True, "exception raised for allocate of size" & Length'Img);
   end Assert_Allocate_Fail;

begin

   IO.Put_Line ("Basic allocation test");
   declare
      S : constant System.Address := NStd.Unsafe.Allocate (10);
   begin
      A.Assert (S /= System.Null_Address);
      Nstd.Unsafe.Free (S);
   end;

   IO.Put_Line ("Allocations that should fail");
   Assert_Allocate_Fail (0);
   Assert_Allocate_Fail (-10);
   Assert_Allocate_Fail (2 ** 54);
   Assert_Allocate_Fail (NStd.SizeType'Last);
   Assert_Allocate_Fail (NStd.SizeType'Last - 1);
   Assert_Allocate_Fail (NStd.SizeType'First);

   IO.Put_Line ("Get_UTF8 tests");
   declare
      use NStd.Byteops;
      use all type NStd.UInt8;
      S : constant Bytes := Clone ("abc") * 100_000_000;
      S_Addr : System.Address := Addr (S);
      S_Offset : NStd.SizeType := 0;
      Counter : Integer := 0;
   begin
      M.Start_Measure;
      for C of S loop
         if C = 97 then
            Counter := Counter + 1;
         end if;
      end loop;
      M.End_Measure;
      M.Display_Measure ("byte iterator");
      A.Assert (Counter, 300_000);

      Counter := 0;
      S_Addr := Addr (S);
      M.Start_Measure;
      for Idx in 1 .. 300_000_000 loop
         if Nstd.Unsafe.Get_UTF8 (S_Addr) = 97 then
            Counter := Counter + 1;
         end if;
      end loop;
      M.End_Measure;
      M.Display_Measure ("get_utf8 (2)");
      A.Assert (Counter, 300_000);

      Counter := 0;
      M.Start_Measure;
      for C of S loop
         if C = 97 then
            Counter := Counter + 1;
         end if;
      end loop;
      M.End_Measure;
      M.Display_Measure ("time");
      A.Assert (Counter, 300_000);

   end;

   IO.Put_Line ("Get_UTF8 tests (3 byte characters)");
   declare
      use NStd.Byteops;
      use all type NStd.UInt8;
      S : constant Bytes := Parse_C_Literal ("\xE2\x82\xAC") * 100_000_000;
      S_Addr : System.Address := Addr (S);
      S_Offset : NStd.SizeType := 0;
      Counter : Integer := 0;
   begin
      M.Start_Measure;
      for C of S loop
         if C = 97 then
            Counter := Counter + 1;
         end if;
      end loop;
      M.End_Measure;
      M.Display_Measure ("byte iterator");
      A.Assert (Counter, 300_000);

      Counter := 0;
      S_Addr := Addr (S);
      M.Start_Measure;
      for Idx in 1 .. 100_000_000 loop
         if Nstd.Unsafe.Get_UTF8 (S_Addr) = 97 then
            Counter := Counter + 1;
         end if;
      end loop;
      M.End_Measure;
      M.Display_Measure ("get_utf8 (2)");
      A.Assert (Counter, 300_000);

      M.Start_Measure;
      A.Assert (Nstd.Unsafe.Validate_UTF8 (Addr (S), Length (S)));
      M.End_Measure;
      M.Display_Measure ("validation");

      M.Start_Measure;
      A.Assert (Nstd.Unsafe.Validate_UTF8 (Addr (S), Length (S)));
      M.End_Measure;
      M.Display_Measure ("validation");

   end;

   return A.Report;

end Test;
