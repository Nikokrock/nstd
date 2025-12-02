with Test_Assert;
with System;
with NStd.Byteops;
with NStd;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNAT.IO;

function Test return Integer is
   package A renames Test_Assert;
   use all type NStd.Byteops.Bytes;
   use all type NStd.SizeType;

   S1  : constant String := "0123456789";
   US1 : constant Unbounded_String := To_Unbounded_String ("0123456789");
   US2 : constant Unbounded_String := To_Unbounded_String
      ("abcdefghijklmnopqrstuvwxyz");
   B, B2, B3 : NStd.Byteops.Bytes;
begin
   -- Test various constructors
   B := NStd.Byteops.Clone (S1);
   A.Assert (B = S1);
   B := NStd.Byteops.Clone ("");
   A.Assert
      (B = "",
       "check equality of string of length" & NStd.Byteops.Length (B)'Img);

   B := Clone (S1);
   A.Assert (B = S1);
   B := Clone ("");
   A.Assert (B = "");
   
   B := Clone (US1);
   A.Assert (B = S1);

   B := Clone (US2);
   A.Assert (B = To_String (US2));

   B := Clone (To_Unbounded_String (""));
   A.Assert (B = "");

   B := Clone (US2);
   A.Assert (B = To_String (US2));

   B := Clone (To_Unbounded_String (""));
   A.Assert (B = "");

   B := Clone (US2);
   B2 := Clone (US2);
   B3 := Clone (B);

   A.Assert (B = B2);
   A.Assert (B3 = B2);
   A.Assert (B3 = B);

   B := Clone (Clone (""));
   A.Assert (B = "");

   GNAT.IO.Put_Line ("== Test multiply operator ==");
   B := Clone ("ab") * 4;
   A.Assert (B = "abababab");
   B := Clone ("ab") * 5;
   A.Assert (B = "ababababab");
   B := Clone ("") * 4;
   A.Assert (B = "");
   B := Clone ("ab") * 0;
   A.Assert (B = "");

   begin
      B := Clone ("012345") * (NStd.SizeType'Last - 3);
   exception
      when Constraint_Error =>
         A.Assert (True, "constraint_error raised");
   end;

   A.Assert (Count (Reference ("0123456789"), 16#30#) = 1);
   A.Assert (Count (Reference ("01234567890123456789"), 16#30#) = 2);
   A.Assert (Count (Reference (""), 16#30#) = 0);
   A.Assert (Count (Reference (System.Null_Address, 0), 16#30#) = 0);
   return A.Report;


end Test;
