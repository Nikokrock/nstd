--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

package body NStd is

   function As_Char (B: Byte) return Character
   is
   begin
      return Character'Val (B);
   end as_char;

   function Min (S1, S2: SizeType) return SizeType is
   begin
      if s1 < s2 then
         return s1;
      else
         return s2;
      end if;
   end Min;

end NStd;
