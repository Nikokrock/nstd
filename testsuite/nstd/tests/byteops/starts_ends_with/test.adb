with Test_Assert;
with NStd.Byteops;

function Test return Integer is
   package A renames Test_Assert;
   use all type NStd.Byteops.Bytes;

begin

   declare
      S1 : constant NStd.Byteops.Bytes := Parse_C_Literal ("a\x00bc");
      Prefix1 : constant NStd.Byteops.Bytes := Parse_C_Literal ("a\x00b");
      Suffix1 : constant NStd.Byteops.Bytes := Clone ("c");
      Pattern2 : constant NStd.Byteops.Bytes := Clone ("");
      Pattern3 : constant NStd.Byteops.Bytes := Clone ("verylonglonglonglong");
   begin
      A.Assert (Starts_With (S1, Prefix1));
      A.Assert (Ends_With (S1, Suffix1));
      A.Assert (Ends_With (S1, Pattern2));
      A.Assert (not Ends_With (S1, Pattern3));
   end;

   declare
      S1 : constant NStd.Byteops.Bytes := Clone ("prefix-suffix");
   begin
      A.Assert (Starts_With (S1, "prefix-"));
      A.Assert (Ends_With (S1, "-suffix"));
      A.Assert (not Starts_With (S1, "pra"));
      A.Assert (not Ends_With (S1, "prefix-"));
      A.Assert (Starts_With (S1, ""));
      A.Assert (Ends_With (S1, ""));
      A.Assert (not Starts_With (S1, "prefixlongerthanthestringtocheck"));
      A.Assert (not Ends_With (S1, "suffixlongerthanthestringtocheck"));
   end;

   return A.Report;

end Test;
