--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

pragma Extensions_Allowed (On);
with System; use System;
with System.Atomic_Counters;

package Std.Lifecycle is

   TID : Integer := 0;
   pragma Thread_Local_Storage (TID);

   type Counter is record
      Rc  : UInt32;
      Arc : System.Atomic_Counters.Atomic_Counter;
      Id  : System.Address;
   end record;
   type CounterAccess is access all Counter;

   type Limited_Address is limited record
      Addr : System.Address := Null_Address;
   end record
   with Finalizable =>
      (Finalize   => Finalize,
       Relaxed_Finalization => True);

   procedure Finalize (Self : in out Limited_Address);

   type Refcounted_Address is record
      Addr         : System.Address := Null_Address;
      --  Alloc_Offset is substracted from Addr to find the memory address that
      --  was returned by the original malloc.
      Alloc_Offset : SizeType       := 0; 
      Counter      : CounterAccess  := null;  
   end record
   with Finalizable =>
      (Finalize   => Finalize,
       Adjust     => Adjust,
       Relaxed_Finalization => True);

   procedure Start_Refcounting
      (Self         : in out Refcounted_Address;
       Addr         : System.Address;
       Alloc_Offset : SizeType)
   with Inline_Always => True;

   procedure Clone_And_Start_Refcounting
      (Self         : in out Refcounted_Address;
       Addr         : System.Address;
       Size         : SizeType)
   with Inline_Always => True;

   procedure Increment (Self : in out Refcounted_Address)
   with Inline_Always => True;

   procedure Adjust (Self : in out Refcounted_Address);
   procedure Finalize (Self : in out Refcounted_Address);


end Std.Lifecycle;
