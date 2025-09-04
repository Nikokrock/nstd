with Test_Assert;
with NStd.Byteops;

function Test return Integer is
   package A renames Test_Assert;
   use all type NStd.Byteops.Bytes;

begin

   declare
      S : constant NStd.Byteops.Bytes := Parse_C_Literal ("a\n\nb\n");
      S2 : constant NStd.Byteops.Bytes := Parse_C_Literal ("a\n\nb");
   begin
      A.Assert (Trim (S) = S2);
      A.Assert (Trim_Trailing (S) = S2);
      A.Assert (Trim_Leading (S) = S);
   end;

   declare
      S : constant NStd.Byteops.Bytes := Parse_C_Literal ("\f\t\r\na\n\nb\n");
      S2 : constant NStd.Byteops.Bytes := Parse_C_Literal ("\f\t\r\na\n\nb");
      S3 : constant NStd.Byteops.Bytes := Parse_C_Literal ("a\n\nb");
      S4 : constant NStd.Byteops.Bytes := Parse_C_Literal ("a\n\nb\n");
   begin
      A.Assert (Trim (S) = S3);
      A.Assert (Trim_Trailing (S) = S2);
      A.Assert (Trim_Leading (S) = S4);
   end;

   declare
      S : constant NStd.Byteops.Bytes := Clone ("");
   begin
      A.Assert (Trim (S) = "");
      A.Assert (Trim_Trailing (S) = "");
      A.Assert (Trim_Leading (S) = "");
   end;
   return A.Report;

end Test;
