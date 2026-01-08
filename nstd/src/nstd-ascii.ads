--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

package NStd.ASCII is

   NUL   : constant := 16#00#;
   BEL   : constant := 16#07#;
   BS    : constant := 16#08#;
   HT    : constant := 16#09#;
   LF    : constant := 16#0A#;
   VT    : constant := 16#0B#;
   FF    : constant := 16#0C#;
   CR    : constant := 16#0D#;
   ESC   : constant := 16#1B#;
   Space          : constant := 16#20#;
   Quotation_Mark : constant := 16#22#;
   Apostrophe     : constant := 16#27#;
   Question_Mark  : constant := 16#3F#;
   Backslash      : constant := 16#5C#;

   function Is_ASCII_Whitespace (B : Byte) return Boolean
   with Inline => True;

   function Is_ASCII_Whitespace (C : UInt32) return Boolean
   with Inline => True;

   Hex_To_Byte_Error : constant Byte := 255;

   function Hex_To_Byte (B : Byte) return Byte
   with Inline_Always => True;

end NStd.ASCII;

