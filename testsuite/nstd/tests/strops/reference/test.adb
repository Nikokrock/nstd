with Test_Assert;
with NStd; use NStd;
with NStd.Strops; use NStd.Strops;
with NStd.Byteops;
with System; use System;
with GNAT.IO;

function Test return Integer is
   package A renames Test_Assert;
begin

   GNAT.IO.Put_Line ("== Reference (String) ==");
   declare
      Src : constant String := "hello world";
      S   : constant Str := Reference (Src);
   begin
      A.Assert (S = "hello world");
      A.Assert (Byte_Length (S) = 11);
   end;

   GNAT.IO.Put_Line ("== Reference (Address, Length) ==");
   declare
      Src : constant String := "hello world";
      S   : constant Str := Reference (Src (Src'First)'Address, 5);
   begin
      A.Assert (S = "hello");
      A.Assert (Byte_Length (S) = 5);
   end;

   GNAT.IO.Put_Line ("== Byte_Length on various strings ==");
   declare
      Empty  : constant Str := Clone ("");
      Short  : constant Str := Clone ("a");
      Medium : constant Str := Clone ("0123456789");
   begin
      A.Assert (Byte_Length (Empty) = 0);
      A.Assert (Byte_Length (Short) = 1);
      A.Assert (Byte_Length (Medium) = 10);
   end;

   GNAT.IO.Put_Line ("== Addr returns non-null for non-empty ==");
   declare
      S : constant Str := Clone ("test");
   begin
      A.Assert (Addr (S) /= Null_Address);
   end;

   GNAT.IO.Put_Line ("== Clone from Bytes ==");
   declare
      B : constant NStd.Byteops.Bytes := NStd.Byteops.Clone ("byte data");
      S : constant Str := Clone (B, Check => False);
   begin
      A.Assert (Byte_Length (S) = 9);
   end;

   GNAT.IO.Put_Line ("== Reference shares memory ==");
   declare
      Src : constant String := "shared";
      S1  : constant Str := Reference (Src);
      S2  : constant Str := Reference (Src);
   begin
      A.Assert (S1 = S2);
   end;

   return A.Report;

end Test;
