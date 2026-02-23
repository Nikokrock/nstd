--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

package body NStd.Counters.Biased is

   use all type System.Address;

   --  This is a way to identify easily the current thread. The address of TID
   --  is enough to identify (the actual thread ID is not needed)
   TID : Integer := 0;
   pragma Thread_Local_Storage (TID);

   -- Initialize --
  
   procedure Initialize (Self : CounterRef) is
      pragma Suppress (All_Checks);
      C : aliased Counter;
      for C'Address use Self;
   begin
      C.ARC := 0;
      C.RC  := 1;
      C.Id  := TID'Address;
   end Initialize;

   -- Increment --

   procedure Increment (Self : CounterRef) is
      pragma Suppress (All_Checks);
      C : aliased Counter;
      for C'Address use Self;
   begin
      if TID'Address = C.Id then
	      C.RC := C.RC + 1;
      else
	      Nstd.Counters.Atomics.Increment (C.Arc'Address);
      end if;
   end Increment;

   -- Decrement --

   function Decrement (Self : CounterRef) return Boolean is
      pragma Suppress (All_Checks);
      C : aliased Counter;
      for C'Address use Self;
   begin
      if C.RC + UInt64 (C.ARC) = 1 then
         C.RC := 0;
         C.ARC := 0;
         return True;
      else
         if TID'Address = C.Id then
	         C.RC := C.RC - 1;
	      else
            declare
               Status : Boolean;
               pragma Unreferenced (Status);
            begin
               Status := NStd.Counters.Atomics.Decrement (C.ARC'Address);
            end;
	      end if;
         return False;
      end if;
   end Decrement;

   -- Counter_Value --

   function Counter_Value (Self : CounterRef) return UInt64 is
      Result : aliased Counter;
      for Result'Address use Self;
   begin
      return Result.RC + UInt64 (Result.ARC);
   end Counter_Value;

end NStd.Counters.Biased;
