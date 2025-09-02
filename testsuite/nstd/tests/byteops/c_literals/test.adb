with Test_Assert;
with NStd.Byteops;

function Test return Integer is
   package A renames Test_Assert;
   use all type NStd.Byteops.Bytes;
   use all type NStd.SizeType;
   use all type NStd.UInt8;

   B : NStd.Byteops.Bytes;
begin
   B := Parse_C_Literal ("b\nc\n\r");
   A.Assert (B = "b" & ASCII.LF & "c" & ASCII.LF & ASCII.CR);
   B := Parse_C_Literal ("escape: \a\b\e\f\n\r\t\v\\\'\""\?");
   A.Assert (B = "escape: " & ASCII.BEL & ASCII.BS & ASCII.ESC & ASCII.FF &
             ASCII.LF & ASCII.CR & ASCII.HT & ASCII.VT & "\'""?");

   B := Parse_C_Literal ("escape: \x41\x7a\x7A");
   A.Assert (B = "escape: Azz", "" & Get (B, Length (B) - 1)'Img);

   B := Parse_C_Literal ("\xFF");
   A.Assert (Get (B, Length (B) - 1) = 16#FF#);
   B := Parse_C_Literal ("\xff");
   A.Assert (Get (B, Length (B) - 1) = 16#FF#);

   begin
      B := Parse_C_Literal ("\x");
      A.Assert (False);
   exception
      when Constraint_Error =>
         A.Assert (True);
      when others =>
         A.Assert (False);
   end;

   begin
      B := Parse_C_Literal ("\g");
      A.Assert (False);
   exception
      when Constraint_Error =>
         A.Assert (True);
      when others =>
         A.Assert (False);
   end;

   begin
      B := Parse_C_Literal ("\");
      A.Assert (False);
   exception
      when Constraint_Error =>
         A.Assert (True);
      when others =>
         A.Assert (False);
   end;

   begin
      B := Parse_C_Literal ("\xj0");
      A.Assert (False);
   exception
      when Constraint_Error =>
         A.Assert (True);
      when others =>
         A.Assert (False);
   end;

   begin
      B := Parse_C_Literal ("\x0");
      A.Assert (False);
   exception
      when Constraint_Error =>
         A.Assert (True);
      when others =>
         A.Assert (False);
   end;

   begin
      B := Parse_C_Literal ("\x0j");
      A.Assert (False);
   exception
      when Constraint_Error =>
         A.Assert (True);
      when others =>
         A.Assert (False);
   end;

   return A.Report;
end Test;
