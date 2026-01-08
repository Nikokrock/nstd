--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--
with Test_Assert;
with NStd; use NStd;

function Test return Integer is
   package A renames Test_Assert;

   U1 : constant UInt64 := 1;
   U2 : constant UInt64 := 16#FFFF_FFFF_FFFF_FFFF#;

   B1 : constant Byte := 16#41#;
   B2 : constant Byte := 16#00#;
begin
   A.Assert (Hex (U1), "0000000000000001");
   A.Assert (Hex (U2), "FFFFFFFFFFFFFFFF");
   A.Assert (Hex (B1), "41");
   A.Assert (Hex (B2), "00");
   A.Assert (B1 = 'A');
   A.Assert (As_Byte ('A') = 'A');
   A.Assert (As_Char (B1) = 'A');
   A.Assert (Min (0, 42) = 0);
   A.Assert (Min (42, 0) = 0);
   return A.Report;
end Test;
