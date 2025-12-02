with Test_Assert;
with NStd.Byteops;

function Test return Integer is
   package A renames Test_Assert;
   use all type NStd.Byteops.Bytes;
   use all type NStd.Byteops.Cursor;
   use all type NStd.SizeType;
   use all type NStd.Byte;

   S1 : constant NStd.Byteops.Bytes := Clone ("0001230012200");
   Counter : Integer := 0;
   B : NStd.Byte;

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

   return A.Report;

end Test;
