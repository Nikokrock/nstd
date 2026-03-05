with Test_Assert;
with NStd; use NStd;
with NStd.Strops; use NStd.Strops;
with GNAT.IO;

function Test return Integer is
   package A renames Test_Assert;
begin

   GNAT.IO.Put_Line ("== Basic slice ==");
   declare
      S : constant Str := Clone ("0123456789");
   begin
      A.Assert (Slice (S, 0, 5) = "01234");
      A.Assert (Slice (S, 5, 10) = "56789");
      A.Assert (Slice (S, 0, 10) = "0123456789");
      A.Assert (Slice (S, 3, 7) = "3456");
   end;

   GNAT.IO.Put_Line ("== Slice with empty result ==");
   declare
      S : constant Str := Clone ("0123456789");
   begin
      A.Assert (Slice (S, 5, 5) = "");
      A.Assert (Slice (S, 0, 0) = "");
   end;

   GNAT.IO.Put_Line ("== Slice with clamping ==");
   declare
      S : constant Str := Clone ("0123456789");
   begin
      A.Assert (Slice (S, 0, 100) = "0123456789");
      A.Assert (Slice (S, -5, 10) = "56789");
   end;

   GNAT.IO.Put_Line ("== Slice on empty string ==");
   declare
      S : constant Str := Clone ("");
   begin
      A.Assert (Slice (S, 0, 0) = "");
      A.Assert (Slice (S, 0, 10) = "");
   end;

   GNAT.IO.Put_Line ("== Slice and equality with Str ==");
   declare
      S1 : constant Str := Clone ("01234567890123456789");
      S2 : constant Str := Clone ("0123456789");
   begin
      A.Assert (Slice (S1, 0, 10) = S2);
      A.Assert (Slice (S1, 10, 20) = S2);
   end;

   return A.Report;

end Test;
