with Test_Assert;
with NStd.Byteops;

function Test return Integer is
   package A renames Test_Assert;
   use all type NStd.Byteops.Bytes;
   use all type NStd.Byteops.Cursor;
   use all type NStd.SizeType;
   use all type NStd.Byte;
   use all type NStd.UInt32;

   S1 : constant NStd.Byteops.Bytes := Clone ("0001230012200");
   Counter : Integer := 0;
   B : NStd.Byte;
   C : NStd.Byteops.Cursor;

   procedure Assert_UInt32 is new A.Generic_Assert (NStd.UInt32);
begin

   for B of S1 loop
      if B = '1' then
         Counter := Counter + 1;
      end if;
   end loop;
   A.Assert (Counter, 2);

   A.Assert (Get (S1, 0) = '0');
   A.Assert (Get (S1, 3) = '1');
   A.Assert (Get_Char (S1, 0) = '0');
   A.Assert (Get_Char (S1, 3) = '1');

   begin
      B := Get (S1, 24);
      A.Assert (False, B'Img);
   exception
      when Constraint_Error =>
         A.Assert (True);
      when others =>
         A.Assert (False);
   end;

   C := First (S1);
   A.Assert (UTF8_Get (S1, C) = 48);
   A.Assert (UTF8_Get (S1, C) = 48);
   A.Assert (UTF8_Get (S1, C) = 48);
   A.Assert (UTF8_Get (S1, C) = 49);
   C := UTF8_Next (S1, C);
   A.Assert (UTF8_Get (S1, C) = 51);

   declare
      UTF8_S : constant NStd.Byteops.Bytes := Parse_C_Literal ("0\xC2\x80");
   begin
      C := First (UTF8_S);
      Assert_UInt32 (UTF8_Get (UTF8_S, C), 48);
      Assert_UInt32 (UTF8_Get (UTF8_S, C), 128);
   end;
   return A.Report;

end Test;
