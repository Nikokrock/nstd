--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--
pragma Extensions_Allowed (On);
with System; use System;

package NStd.Lifecycle is

   type Limited_Address is limited record
      Addr : System.Address := Null_Address;
   end record
   with Finalizable =>
      (Finalize             => Finalize,
       Relaxed_Finalization => True);

   procedure Finalize (Self : in out Limited_Address);

   type Refcounted_Mem is private;

   procedure Start_Reference
       (Self : in out Refcounted_Mem;
        Addr : System.Address;
        Size : SizeType)
   with Inline_Always => True;

   procedure Start_Refcounting
      (Self : in out Refcounted_Mem;
       Addr : System.Address;
       Size : SizeType)
   with Inline_Always => True;

   procedure Clone_And_Start_Refcounting
      (Self         : in out Refcounted_Mem;
       Addr         : System.Address;
       Size         : SizeType)
   with Inline_Always => True;

   function Slice
      (Self  : Refcounted_Mem;
       First : SizeType;
       Last  : SizeType)
      return Refcounted_Mem;

   function Addr (Self : Refcounted_Mem) return System.Address
   with Inline_Always => True;

   function Length (Self : Refcounted_Mem) return SizeType
   with Inline_Always => True;

   function Reference_Count (Self : Refcounted_Mem) return UInt64;

   procedure Adjust (Self : in out Refcounted_Mem)
   with Inline => True;

   procedure Finalize (Self : in out Refcounted_Mem)
   with Inline => True;

   Empty_Refcounted_Mem : constant Refcounted_Mem;

private

   type Refcounted_Mem is record
      Addr       : System.Address := Null_Address;
      Length     : SizeType       := 0;
      Counter    : System.Address := Null_Address;
      Block_Addr : System.Address := Null_Address;
   end record
   with Finalizable =>
      (Finalize             => Finalize,
       Adjust               => Adjust,
       Relaxed_Finalization => True);

   Empty_Refcounted_Mem : constant Refcounted_Mem :=
      (Null_Address, 0, Null_Address, Null_Address);

end NStd.Lifecycle;
