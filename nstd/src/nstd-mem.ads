--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception

with System; use System;
with Ada.Strings.Unbounded;

package NStd.Mem is

   --  function "-" (Left, Right: Address) return SizeType
   --  with Inline => True;

   function To_SizeType (Self : Address) return SizeType
   with Inline_Always => True;
   --  Unchecked conversion of an address to an integrer type

   function To_Address (Self : SizeType) return Address
   with Inline_Always => True;
   --  Unchecked converstion of an int to an address

   type Block is record
      Addr   : Address  := Null_Address;
      Length : SizeType := 0;
   end record;

   Empty_Block : constant Block := (Addr => System.Null_Address, Length => 0);

   function Allocate (Length : SizeType) return Block
   with Inline => True;
   --  Allocate a new memory region of length Length
   --
   --  Storage_Error is raised whenever Length > ISize'Last - 1 or if the
   --  allocation fails (not enough memory, rlimit, ...).

   procedure Free (Self : in out Block)
   with Inline => True;
   --  Free a memory region

   function Clone (Self : Block) return Block
   with Inline => True;
   --  Clone a memory region of length Length starting at Address Addr.
   --
   --  Storage_Error is raised in the allocation of the new region fails (See
   --  Allocate errors).

   procedure Reallocate (Self : in out Block; Length : SizeType)
   with Inline => True;
   --  Reallocate a memory region to a new size. The new size can lower or
   --  higher then the previous size.
   --
   --  Storage_Error is raised in the allocation of the new region fails (See
   --  Allocate errors).

   function Ref (Self : String) return Block
   with Inline => True;
   --  Get a reference to the block of memory containing a given string.

   function Ref (Self : Ada.Strings.Unbounded.Unbounded_String) return Block
   with Inline => True;

   function Is_Content_Equal (Left : Block; Right : Block) return Boolean
   with Inline => True;
   --  Compare two memory regions and return True if there content is equal.

end NStd.Mem;
