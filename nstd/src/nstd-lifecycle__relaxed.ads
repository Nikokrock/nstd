--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--
pragma Extensions_Allowed (On);
with System; use System;
with NStd.Mem; use NStd.Mem;

package NStd.Lifecycle is

   type Limited_Address is limited record
      Addr : System.Address := Null_Address;
   end record
   with Finalizable =>
      (Finalize             => Finalize,
       Relaxed_Finalization => True);

   procedure Finalize (Self : in out Limited_Address);

   type Refcounted_Mem is private;
   --  An object to handle a possibly ref counted block of memory
   --
   --  The object supports various lifecycle modes. The mode is selected at
   --  object creation and cannot be changed afterwards
   --
   --  - Refcounted memory (Start_Refcounting or Clone_And_Start_Refcounting).
   --    In that mode copy and slice of the object do not lead to data copy.
   --    Only a atomic reference counter is updated. When the reference counter
   --    reach 0, the block of memory is automatically freed.
   --  - Limited reference. If the memory block is initialized using
   --    Start_Limited_Reference then no reference counter is used. On object
   --    copy or slice the object is fully copied.
   --  - Reference. Same as limited reference except that the reference can be
   --    copied.

   procedure Start_Reference
       (Self  : in out Refcounted_Mem; Block : NStd.Mem.Block)
   with Inline_Always => True;

   procedure Start_Limited_Reference
       (Self  : in out Refcounted_Mem; Block : NStd.Mem.Block)
   with Inline_Always => True;

   procedure Start_Refcounting
      (Self  : in out Refcounted_Mem; Block : NStd.Mem.Block)
   with Inline_Always => True;

   procedure Clone_And_Start_Refcounting
      (Self  : in out Refcounted_Mem; Block : NStd.Mem.Block)
   with Inline_Always => True;

   function Slice
      (Self  : Refcounted_Mem;
       First : SizeType;
       Last  : SizeType)
      return Refcounted_Mem;

   function Block (Self : Refcounted_Mem) return NStd.Mem.Block;

   function Length (Self : Refcounted_Mem) return SizeType
   with Inline_Always => True;

   function Reference_Count (Self : Refcounted_Mem) return UInt64;

   Empty_Refcounted_Mem : constant Refcounted_Mem;

private

   type Refcounted_Mem is record
      Block      : NStd.Mem.Block := NStd.Mem.Empty_Block;
      Counter    : System.Address := Null_Address;
      Block_Addr : System.Address := Null_Address;
   end record
   with Finalizable =>
      (Finalize             => Finalize,
       Adjust               => Adjust,
       Relaxed_Finalization => True);

   procedure Adjust (Self : in out Refcounted_Mem)
   with Inline => True;

   procedure Finalize (Self : in out Refcounted_Mem)
   with Inline => True;


   Empty_Refcounted_Mem : constant Refcounted_Mem :=
      (Empty_Block, Null_Address, Null_Address);

end NStd.Lifecycle;
