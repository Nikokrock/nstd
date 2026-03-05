--  Copyright (C) 2026, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception

with Interfaces.C;

package body NStd.Simdutf is

   function Validate_UTF8 (Buf : Address; Len : SizeType) return Boolean
   is
      function Internal
        (Buf : Address; Len : SizeType) return Interfaces.C.C_bool
      with Import => True,
        Convention => CPP,
        External_Name => "_ZN7simdutf13validate_utf8EPKcm";
   begin
      return Boolean (Internal (Buf, Len));
   end Validate_UTF8;

   function Validate_UTF8 (B : Block) return Boolean
   is
   begin
      return Validate_UTF8 (Buf => B.Addr, Len => B.Length);
   end Validate_UTF8;

   function Validate_ASCII (Buf : Address; Len : SizeType) return Boolean
   is
      function Internal
        (Buf : Address; Len : SizeType) return Interfaces.C.C_bool
      with Import => True,
        Convention => CPP,
        External_Name => "_ZN7simdutf14validate_asciiEPKcm";
   begin
      return Boolean (Internal (Buf, Len));
   end Validate_ASCII;

   function Find
     (Start_Addr : Address; End_Addr : Address; B : Byte)
     return Address
   is
      function Internal
         (Start_Addr : Address;
          End_Addr   : Address;
          B             : Byte)
         return Address
      with Import        => True,
           Convention    => CPP,
           External_Name => "_ZN7simdutf4findEPKcS1_c";

   begin
      return Internal (Start_Addr, End_Addr, B);
   end Find;

end NStd.Simdutf;
