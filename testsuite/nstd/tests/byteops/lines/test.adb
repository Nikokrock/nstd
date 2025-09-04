with Test_Assert;
with NStd.Byteops;
with NStd;

function Test return Integer is
   package A renames Test_Assert;
   use all type NStd.Byteops.Bytes;

begin

   declare
      S : constant NStd.Byteops.Bytes := Parse_C_Literal ("a\n\nb\n");
      S_Lines : constant NStd.Byteops.Line_Iterator := Lines (S);
      Line_Count : Integer := 0;
   begin
      for Line of S_Lines loop
         Line_Count := Line_Count + 1;
         if Line_Count = 3 then
            A.Assert (Line = "b");
         end if;
      end loop;

      A.Assert (Line_Count = 3);
   end;

   declare
      S : constant NStd.Byteops.Bytes := Parse_C_Literal ("oneline");
      S_Lines : constant NStd.Byteops.Line_Iterator := Lines (S);
      Line_Count : Integer := 0;
   begin
      for Line of S_Lines loop
         Line_Count := Line_Count + 1;
         if Line_Count = 1 then
            A.Assert (Line = "oneline");
         end if;
      end loop;

      A.Assert (Line_Count = 1);
   end;

   declare
      S : constant NStd.Byteops.Bytes := Parse_C_Literal ("");
      S_Lines : constant NStd.Byteops.Line_Iterator := Lines (S);
      Line_Count : Integer := 0;
   begin
      for Line of S_Lines loop
         Line_Count := Line_Count + 1;
      end loop;

      A.Assert (Line_Count = 0);
   end;

   return A.Report;

end Test;
