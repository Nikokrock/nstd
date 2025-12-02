with Test_Assert;
with NStd.Byteops;

function Test return Integer is
   package A renames Test_Assert;
   use all type NStd.Byteops.Bytes;
   use all type NStd.ISize;
begin

   declare
      S1 : constant NStd.Byteops.Bytes := +"0123456789";
      S2 : constant NStd.Byteops.Bytes := +"01234567890123456789";
   begin
      A.Assert (Slice (S2, 0, 10) = S1);
      A.Assert (Slice (S2, 0, 10) = "0123456789");
      A.Assert (Slice (S2, -10, Length (S2)) = "0123456789");
      A.Assert (Slice (S2, 0, 4242) = S2);
      A.Assert (Head (S2, 10) = S1);
      A.Assert (Tail (S2, 10) = S1);
   end;

   return A.Report;

end Test;
