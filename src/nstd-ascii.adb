--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

package body NStd.ASCII is

   Byte_Value : constant array (0 .. 255) of Byte :=
      (255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
         0,   1,   2,   3,   4,   5,   6,   7,
         8,   9, 255, 255, 255, 255, 255, 255,
       255,  10,  11,  12,  13,  14,  15, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255,  10,  11,  12,  13,  14,  15, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255,
       255, 255, 255, 255, 255, 255, 255, 255);

   --  Create a mask that contains all ASCII whitespace characters. The shift
   --  by 1 is to ensure the mask fit in an unsigned 32bits.
   Whitespace_Mask : constant UInt32 :=
      Shift_Left (1, HT - 1) or Shift_Left (1, LF - 1) or
      Shift_Left (1, VT - 1) or Shift_Left (1, FF - 1) or
      Shift_Left (1, CR - 1) or Shift_Left (1, Space - 1);

   function Is_ASCII_Whitespace (C : UInt32) return Boolean is
      pragma Suppress (All_Checks);
   begin
      --  Whitespace check is branchless!
      return (Shift_Left (1, Integer (C - 1)) and Whitespace_Mask) > 0;
   end Is_ASCII_Whitespace;

   function Is_ASCII_Whitespace (B : Byte) return Boolean is
   begin
      return Is_ASCII_Whitespace (UInt32 (B));
   end Is_ASCII_Whitespace;

   function Hex_To_Byte (B : Byte) return Byte is
   begin
      return Byte_Value (Integer (B));
   end Hex_To_Byte;

end NStd.ASCII;
