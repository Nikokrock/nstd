with Test_Assert;
with NStd.Byteops; use NStd.Byteops;
with NStd; use NStd;
with GNAT.IO;

function Test return Integer is
   package A renames Test_Assert;

   Empty_S : constant Bytes := +"";
begin
   GNAT.IO.Put_Line ("Byte Find tests");
   declare
      S : constant Bytes := +"012_456789_";
   begin
      GNAT.IO.Put_Line ("  Find without offset");
      A.Assert (Find (S, As_Byte ('a')) = NOT_FOUND);
      A.Assert (Find (S, As_Byte ('1')) = 1);
      A.Assert (Find (S, As_Byte ('0')) = 0);
      A.Assert (Find (S, '_') = 3);

      A.Assert (Find (Empty_S, As_Byte ('a')) = NOT_FOUND);
      A.Assert (Find (Empty_S, '_') = NOT_FOUND);

      GNAT.IO.Put_Line (" Find with first");
      A.Assert (Find (S, '1', 2) = NOT_FOUND);
      A.Assert (Find (S, '_', 4) = 10);
      A.Assert (Find (S, '_', 3) = 3);

      A.Assert (Find (S, '_', -2) = NOT_FOUND);
      A.Assert (Find (S, '_', 10) = 10);
      A.Assert (Find (S, '_', 11) = NOT_FOUND);
      A.Assert (Find (S, '_', 12) = NOT_FOUND);
   end;

   GNAT.IO.Put_Line ("Byte RFind tests");
   declare
      S : constant Bytes := +"0_23456789_";
   begin
      GNAT.IO.Put_Line ("  Find without offset");
      A.Assert (RFind (S, As_Byte ('_')) = 10);
      A.Assert (RFind (S, As_Byte ('_'), 9) = 1);
      A.Assert (RFind (S, As_Byte ('_'), 10) = 1);
      A.Assert (RFind (S, As_Byte ('_'), 11) = 10);
      A.Assert (RFind (S, As_Byte ('_'), 12) = NOT_FOUND);
      A.Assert (RFind (S, As_Byte ('_'), -2) = NOT_FOUND);
      A.Assert (RFind (S, As_Byte ('A'), 11) = NOT_FOUND);
      A.Assert (RFind (S, As_Byte ('A')) = NOT_FOUND);
      A.Assert (RFind (Empty_S, As_Byte('_')) = NOT_FOUND);
   end;

   GNAT.IO.Put_Line ("Find pattern");
   declare
      S         : constant Bytes := +"01234567890123456789";
      Match     : constant Bytes := +"23";
      Non_Match : constant Bytes := +"35";
      Big_Non_Match : constant Bytes := +"012345678901234567891";
   begin
      A.Assert (Find (S, Match) = 2);
      A.Assert (Find (S, Non_Match) = NOT_FOUND);
      A.Assert (Find (S, Big_Non_Match) = NOT_FOUND);
      A.Assert (Find (S, Empty_S) = 0);
      A.Assert (Find (Empty_S, Empty_S) = 0);
      A.Assert (Find (Empty_S, Non_Match) = NOT_FOUND);
   end;

   GNAT.IO.Put_Line ("RFind pattern");
   declare
      S         : constant Bytes := +"01234567890123456789";
      Match     : constant Bytes := +"23";
      Non_Match : constant Bytes := +"35";
      Big_Non_Match : constant Bytes := +"012345678901234567891";
   begin
      A.Assert (RFind (S, Match) = 12);
      A.Assert (RFind (S, Non_Match) = NOT_FOUND);
      A.Assert (RFind (S, Big_Non_Match) = NOT_FOUND);
      A.Assert (RFind (S, Empty_S) = 0);
      A.Assert (RFind (Empty_S, Empty_S) = 0);
      A.Assert (RFind (Empty_S, Non_Match) = NOT_FOUND);
   end;

   return A.Report;

end Test;
