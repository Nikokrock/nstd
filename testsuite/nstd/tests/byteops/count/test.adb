with Test_Assert;
with NStd.Byteops;
with NStd.ASCII;

function Test return Integer is
   package A renames Test_Assert;
   use all type NStd.Byteops.Bytes;
   use all type NStd.SizeType;

   S1 : constant NStd.Byteops.Bytes := Clone ("0001230012200");
   S2 : constant NStd.Byteops.Bytes := Parse_C_Literal ("\n\n\n");
   S3 : constant NStd.Byteops.Bytes := Parse_C_Literal ("\x00\x00\x00");
   S4 : constant NStd.Byteops.Bytes := Clone ("");
   S5 : constant NStd.Byteops.Bytes := Clone (
      "00000000000000000000001000000000000000000000000000000000000000010001");
begin
   A.Assert (Count (S1, NStd.As_Byte ('0')) = 7);
   A.Assert (Count (S1, NStd.As_Byte ('1')) = 2);
   A.Assert (Count (S1, NStd.As_Byte ('2')) = 3);
   A.Assert (Count (S1, NStd.As_Byte ('3')) = 1);
   A.Assert (Count (S1, 0) = 0, Count (S1, 0)'Img);

   A.Assert (Count (S2, NStd.ASCII.LF) = 3);
   A.Assert (Count (S2, NStd.ASCII.LF, 0) = 3);
   A.Assert (Count (S2, NStd.ASCII.LF, 1) = 2);
   A.Assert (Count (S2, NStd.ASCII.LF, 2) = 1);
   A.Assert (Count (S2, NStd.ASCII.LF , 3) = 0);

   A.Assert (Count (S3, 0) = 3);

   A.Assert (Count (S4, 0) = 0);
   A.Assert (Count (S5, NStd.As_Byte ('1')) = 3);
   A.Assert (Count (S5, NStd.As_Byte ('2')) = 0);
   return A.Report;

end Test;
