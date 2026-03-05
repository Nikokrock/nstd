--  Copyright (C) 2026, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--
--  Provides a thin binding to SimdUTF C++ library. For documentation
--  check the Simdutf project. Ada function names map to the C/C++ name

with System; use System;
with NStd.Mem; use NStd.Mem;

package NStd.Simdutf is

   function Validate_UTF8 (Buf : Address; Len : SizeType) return Boolean
   with Inline_Always => True;

   function Validate_UTF8 (B : Block) return Boolean
   with Inline_Always => True;

   function Validate_ASCII (Buf : Address; Len : SizeType) return Boolean
   with Inline_Always => True;

   function Find
     (Start_Addr : Address; End_Addr : Address; B : Byte) return Address
   with Inline_Always => True;

end NStd.Simdutf;
