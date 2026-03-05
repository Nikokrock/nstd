with Test_Assert;
with System;
with NStd; use NStd;
with NStd.Strops; use NStd.Strops;
with NStd.Byteops;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNAT.IO;

function Test return Integer is
   package A renames Test_Assert;

   S1  : constant String := "0123456789";
   BadS : constant String := "" & Character'Val (16#81#);
   US1 : constant Unbounded_String := To_Unbounded_String ("0123456789");
   US2 : constant Unbounded_String := To_Unbounded_String
      ("abcdefghijklmnopqrstuvwxyz");
   US3 : constant Unbounded_String := To_Unbounded_String (BadS);
   B, B2, B3 : Str;
begin
   -- Test various constructors
   B := Clone (S1);
   A.Assert (B = S1);
   B := Clone ("");
   A.Assert
      (B = "",
       "check equality of string of length" & Byte_Length (B)'Img);

   B := Clone (S1);
   A.Assert (B = S1);
   B := Clone ("");
   A.Assert (B = "");
   
   B := Clone (US1);
   A.Assert (B = S1);

   B := Clone (US2);
   A.Assert (B = To_String (US2));

   begin
      B := Clone (US3);
      A.Assert (False, "Exception not raised");
   exception
      when Invalid_UTF8 =>
         A.Assert (True, "Exception raised");
      when others =>
         A.Assert (False, "Wrong exception");
   end;

   begin
      B := Clone (US3, Check => False);
      A.Assert (True, "Exception not raised!");
   exception
      when others =>
         A.Assert (False, "No exception should be raised");
   end;

   begin
      B := Clone (BadS);
      A.Assert (False, "Exception not raised");
   exception
      when Invalid_UTF8 =>
         A.Assert (True, "Exception raised");
      when others =>
         A.Assert (False, "Wrong exception");
   end;

   begin
      B := Clone (BadS, Check => False);
      A.Assert (True, "Exception not raised!");
   exception
      when others =>
         A.Assert (False, "No exception should be raised");
   end;

   declare
      use NStd.Byteops;
      Byte_Object : Bytes := Clone (S1);
      Bad_Byte_Object : Bytes := Clone (BadS);
   begin
      B := Clone (Byte_Object);

      begin
         B := Clone (Bad_Byte_Object);
         A.Assert (False, "Exception not raised");
      exception
         when Invalid_UTF8 =>
            A.Assert (True, "Exception raised");
         when others =>
            A.Assert (False, "Wrong exception");
      end;

      begin
         B := Clone (Bad_Byte_Object, Check => False);
         A.Assert (True, "Exception not raised!");
      exception
         when others =>
            A.Assert (False, "No exception should be raised");
      end;
   end;

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

   return A.Report;

end Test;
