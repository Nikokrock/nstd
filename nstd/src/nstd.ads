--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with System.Storage_Elements;

package NStd is

   type SInt32 is new Integer;

   type SInt64 is new Long_Long_Integer;

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

   NOT_FOUND : constant SizeType := SizeType'Last;

   function As_Char (B: Byte) return Character
   with Inline => True;
   --  Return the character corresponding to Byte B

   function As_Byte (C : Character) return Byte
   with Inline_Always => True;
   --  Return the Byte corresponding to Character C

   function Min (S1, S2: SizeType) return SizeType
   with Inline => True;
   --  Return the Min between S1 and S2

   function "=" (B : Byte; C : Character) return Boolean
   with Inline_Always => True;
   --  Return True if C'Pos is equal to B

   function Hex (U : UInt64) return String;
   --  Return the hexadecimal representation of an UInt64

   function Hex (B : Byte) return String;
   --  Return the hexadecimal representation of a Byte

end NStd;
