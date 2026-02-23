--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

package body NStd.Counters.Simple is

   -- Initialize --

   procedure Initialize (Self : CounterRef) is
      pragma Suppress (All_Checks);
      C : Counter;
      for C'Address use Self;
   begin
      C := 1;
   end Initialize;

   -- Increment --
   procedure Increment (Self : CounterRef) is
      pragma Suppress (All_Checks);
      C : Counter;
      for C'Address use Self;
   begin
      C := C + 1;
   end Increment;

   -- Decrement --
   function Decrement (Self : CounterRef) return Boolean is
      pragma Suppress (All_Checks);
      C : Counter;
      for C'Address use Self;
   begin
      if C = 1 then
         C := 0;
         return True;
      else
         C := C - 1;
         return False;
      end if;
   end Decrement;

   -- Counter_Value --
   function Counter_Value (Self : CounterRef) return UInt64 is
      C : Counter;
      for C'Address use Self;
   begin
      return UInt64 (C);
   end Counter_Value;

end NStd.Counters.Simple;
