--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

--  Our "C API" written in Ada

with System; use System;

package NStd.Unsafe is

   -----------------------
   -- Memory Management --
   -----------------------

   function Allocate (Length : SizeType) return Address
   with Inline => True;
   --  Allocate a new memory region of length Length
   --
   --  Storage_Error is raised whenever Length > ISize'Last - 1 or if the
   --  allocation fails (not enough memory, rlimit, ...).

   procedure Free (Self : Address)
   with Inline => True;
   --  Free a memory region

   function Clone (Addr : Address; Length : SizeType) return Address
   with Inline => True;
   --  Clone a memory region of length Length starting at Address Addr.
   --
   --  Storage_Error is raised in the allocation of the new region fails (See
   --  Allocate errors).

   procedure Reallocate (Addr : in out Address; Length : SizeType)
   with Inline => True;
   --  Reallocate a memory region to a new size. The new size can lower or
   --  higher then the previous size.
   --
   --  Storage_Error is raised in the allocation of the new region fails (See
   --  Allocate errors).

   procedure Copy
      (Src    : Address;
       Dst    : Address;
       Length : SizeType)
   with Inline => True;

   procedure Reallocate_And_Copy
      (Src          : Address;
       Src_Length   : SizeType;
       Dst          : in out Address;
       Dst_Offset   : SizeType;
       Dst_Length   : in out SizeType)
   with Inline => True;
   --  Copy Src of size Src_Length into Dst + Dst_Offset. Dst_Length is the
   --  length of the memory region starting at Dst. Note that resizing will
   --  allocate extra space.
   --
   --  If Src does not fit into Dst, then Dst is reallocated to make room for
   --  Src.
   --
   --  Storage_Error is raised if the reallocation of Dst fails (See
   --  Allocate errors).

   function Is_Equal
      (Left         : Address;
       Right        : Address;
       Left_Length  : SizeType;
       Right_Length : SizeType)
      return Boolean
   with Inline => True;
   --  Compare two memory regions and return True if they are equal
   
   function Addr (Self : Address; Offset : IndexType) return Address
   with Inline => True;
   --  Return Address at Self + Offset

   function Offset (Self : Address; Origin: Address) return IndexType
   with Inline => True;
   --  Return offset between Self and Origin (i.e Self - Origin)

   ----------------
   -- Memory I/O --
   ----------------

   function Get (Self : Address; Offset : SizeType) return Byte
   with Inline => True;

   procedure Set (Self : Address; Offset : SizeType; b : Byte)
   with Inline => True;

   ---------------------
   -- UTF-8 functions --
   ---------------------

   function Next_UTF8_Offset
      (Self   : Address;
       Offset : SizeType;
       Length : SizeType)
      return SizeType
   with Inline => True;

   function Get_UTF8
      (Self : Address; Offset : in out SizeType; Length : SizeType)
      return Uint32
   with Inline => True;

   ----------
   -- Misc --
   ----------

   function Reference (S : String) return Address
   with Inline => True;
   --  Create a reference to an Ada String memory address

end NStd.Unsafe;
