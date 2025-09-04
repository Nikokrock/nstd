--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--
with Test_Assert;
with NStd.Byteops;
with NStd;

function Test return Integer is
   package A renames Test_Assert;
   use all type NStd.Byteops.Bytes;

begin
   --  Only a minimal test is needed as this iterator is merely a wrapper around
   --  the default Bytes iterator.
   declare
      S : constant NStd.Byteops.Bytes := +"01234567890";
      Zero_Count  : Integer := 0;
      Total_Count : Integer := 0;
   begin
      for C of Chars (S) loop
         Total_Count := Total_Count + 1;
         if C = '0' then
            Zero_Count := Zero_Count + 1;
         end if;
      end loop;

      A.Assert (Zero_Count = 2);
      A.Assert (Total_Count = 11);
   end;

   return A.Report;
end Test;
