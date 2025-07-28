--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

package NStd.ASCII is

   HT : constant := 16#09#;
   LF : constant := 16#0A#;
   VT : constant := 16#0B#;
   FF : constant := 16#0C#;
   CR : constant := 16#0D#;
   Space : constant := 16#20#;

   function Is_ASCII_Whitespace (B : Byte) return Boolean
   with Inline => True;

   function Is_ASCII_Whitespace (C : UInt32) return Boolean
   with Inline => True;

end NStd.ASCII;

