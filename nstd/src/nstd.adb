--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

package body NStd is

   Hex_Value : constant array (0 .. 15) of Character :=
      ('0', '1', '2', '3', '4', '5', '6', '7',
       '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');

   function As_Char (B: Byte) return Character
   is
   begin
      return Character'Val (B);
   end as_char;

   function As_Byte (C : Character) return Byte
   is
   begin
      return Character'Pos (C);
   end As_Byte;

   function Min (S1, S2: SizeType) return SizeType is
   begin
      if s1 < s2 then
         return s1;
      else
         return s2;
      end if;
   end Min;

   function "=" (B : Byte; C : Character) return Boolean is
   begin
      return B = As_Byte (C);
   end "=";

   -- Hex --

   function Hex (U : UInt64) return String is
      S  : String (1 .. 16);
   begin
      for Idx in 1 .. 16 loop
         S (Idx) := Hex_Value
            (Integer (Shift_Right (U, (16 - Idx) * 4) and 16#F#));
      end loop;

      return S;
   end Hex;

   function Hex (B : Byte) return String is
      S : String (1 .. 2);
   begin
      for Idx in 1 .. 2 loop
         S (Idx) := Hex_Value
            (Integer (Shift_Right (B, (2 - Idx) * 4) and 16#F#));
      end loop;

      return S;
   end Hex;

end NStd;
