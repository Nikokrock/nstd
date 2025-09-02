--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

package body NStd.Atomics is

   Seq_Cst : constant := 5;

   type Atomic_Unsigned is mod 2 ** 64 with Atomic;
   --  The Atomic attribute is important here to ensure that compiler does not
   --  attempt to to remove reference or reorder instructions

   function Atomic_Add_Fetch
     (Ptr   : System.Address;
      Val   : Atomic_Unsigned;
      Model : Integer := Seq_Cst)
     return Atomic_Unsigned;
   pragma Import (Intrinsic, Atomic_Add_Fetch, "__atomic_add_fetch");

   function Atomic_Sub_Fetch
     (Ptr   : System.Address;
      Val   : Atomic_Unsigned;
      Model : Integer := Seq_Cst)
     return Atomic_Unsigned;
   pragma Import (Intrinsic, Atomic_Sub_Fetch, "__atomic_sub_fetch");

   -- Initialize --
   procedure Initialize (Self : CounterRef) is
      pragma Suppress (All_Checks);
      C : Atomic_Unsigned;
      for C'Address use Self;
   begin
      C := 1;
   end Initialize;

   -- Increment --
   procedure Increment (Self : CounterRef) is
      pragma Suppress (All_Checks);
      pragma Warnings (Off);
      I : constant Atomic_Unsigned := Atomic_Add_Fetch (Self, 1);
      pragma Warnings (On);
   begin
      null;
   end Increment;

   -- Decrement --
   function Decrement (Self : CounterRef) return Boolean is
      pragma Suppress (All_Checks);
   begin
      return Atomic_Sub_Fetch (Self, 1) = 0;
   end Decrement;

   -- Counter_Value --
   function Counter_Value (Self : CounterRef) return UInt64 is
      Result : UInt64;
      for Result'Address use Self;
   begin
      return Result;
   end Counter_Value;

end NStd.Atomics;
