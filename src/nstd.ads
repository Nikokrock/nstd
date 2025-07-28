--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with System.Storage_Elements;

package NStd is

   type UInt8 is mod 2 ** 8;
   pragma Provide_Shift_Operators(UInt8);

   type UInt16 is mod 2 ** 16;
   pragma Provide_Shift_Operators(UInt16);

   type UInt32 is mod 2 ** 32;
   pragma Provide_Shift_Operators(UInt32);

   type UInt64 is mod 2 ** 64;
   pragma Provide_Shift_Operators(UInt64);

   subtype Byte is UInt8;

   type ISize is new System.Storage_Elements.Storage_Offset;

   subtype IndexType is ISize;
   --  Type use for offset inside strings, bytes,...

   subtype SizeType is ISize;
   --  The APIs using SizeType do accept only Size in the range
   --  0 .. ISize'Last - 1, but declaring SizeType as a range leads to various
   --  range checks added everywhere in the case and can lead to strong
   --  performance issues.
   --  On 64bits platforms this means that the max size that can be allocated
   --  is 2 ^ 63 - 2 bytes
   --  On 32 bits platforms the max size is thus 2 ^ 31 - 2 bytes (~2GB)

   function As_Char (B: Byte) return Character
   with Inline => True;

   function Min (S1, S2: SizeType) return SizeType
   with Inline => True;

end NStd;
