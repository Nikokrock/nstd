--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

--  Import of OS primitive to manage memory: allocation, deallocation, copy,
--  move, compare, ...

with System;

package NStd.Memory is

   function Malloc (Size: SizeType) return System.Address;
   pragma Import(C, Malloc, "malloc");

   function Realloc
      (Src: System.Address; Size: SizeType) return System.Address;
   pragma Import(C, Realloc, "realloc");

   function Memcpy
      (Dst, Src: System.Address; Length: SizeType) return System.Address;
   pragma Import(C, Memcpy, "memcpy");

   function Memcmp (Dst, Src: System.Address; Length: SizeType) return Integer;
   pragma Import(C, Memcmp, "memcmp");

   procedure Memmove (Dst, Src: System.Address; Length: SizeType);
   pragma Import(C, Memmove, "memmove");

   procedure Free (Addr: System.Address);
   pragma Import(C, Free, "free");

   function Memmem
      (Src            : System.Address;
       Src_Length     : SizeType;
       Pattern        : System.Address;
       Pattern_Length : SizeType)
      return SizeType;
   pragma Import (C, Memmem, "memmem");
                     
end NStd.Memory;
