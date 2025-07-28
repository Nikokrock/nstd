--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with System; use System;
with Ada.Finalization;
with System.Atomic_Counters;

package NStd.Lifecycle is

   subtype Counter is System.Atomic_Counters.Atomic_Counter;
   type CounterAccess is access all Counter;

   type Limited_Address is new Ada.Finalization.Limited_Controlled with record
      Addr : System.Address := Null_Address;
   end record;

   procedure Finalize (Self : in out Limited_Address);

   type Refcounted_Address is new Ada.Finalization.Controlled with record
      Addr    : System.Address := Null_Address;

      --  Alloc_Offset is substracted from Addr to find the memory address that
      --  was returned by the original malloc.
      Alloc_Offset : SizeType       := 0;
      Counter      : CounterAccess  := null;
   end record;

   procedure Start_Refcounting
      (Self         : in out Refcounted_Address;
       Addr         : System.Address;
       Alloc_Offset : SizeType)
   with Inline => True;

   procedure Clone_And_Start_Refcounting
      (Self         : in out Refcounted_Address;
       Addr         : System.Address;
       Size         : SizeType)
   with Inline => True;

   procedure Increment (Self : in out Refcounted_Address)
   with Inline => True;

   procedure Adjust (Self : in out Refcounted_Address);
   procedure Finalize (Self : in out Refcounted_Address);

   Empty_Refcounted_Address : Refcounted_Address;
end NStd.Lifecycle;
