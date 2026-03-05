with Test_Assert;
with NStd.Strops; use NStd.Strops;
with GNAT.IO;

function Test return Integer is
   package A renames Test_Assert;
begin

   GNAT.IO.Put_Line ("== Hex on ASCII string ==");
   declare
      S : constant Str := Clone ("AB");
   begin
      --  'A' = 0x41, 'B' = 0x42
      --  ByteOps.Hex format is " XX" per byte
      A.Assert (Hex (S) = " 41 42");
   end;

   GNAT.IO.Put_Line ("== Hex on single byte ==");
   declare
      S : constant Str := Clone ("0");
   begin
      --  '0' = 0x30
      A.Assert (Hex (S) = " 30");
   end;

   GNAT.IO.Put_Line ("== Hex on empty string ==");
   declare
      S : constant Str := Clone ("");
   begin
      A.Assert (Hex (S) = "");
   end;

   GNAT.IO.Put_Line ("== Hex on multibyte UTF-8 ==");
   declare
      --  U+00E9 (e-acute) encodes as C3 A9 in UTF-8
      S : constant Str := Clone ("" & Character'Val (16#C3#)
                                    & Character'Val (16#A9#),
                                 Check => False);
   begin
      A.Assert (Hex (S) = " C3 A9");
   end;

   return A.Report;

end Test;
