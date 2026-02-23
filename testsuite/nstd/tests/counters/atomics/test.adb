with Test_Assert;
with NStd.Counters.Atomics;
with System;
with NStd;

function Test return Integer is
   package A renames Test_Assert;
   package Atomics renames NStd.Counters.Atomics;
   use all type NStd.UInt64;

   C : aliased NStd.Uint64 := 1;
   CA : constant System.Address := C'Address;
begin
   Atomics.Initialize (CA);
   Atomics.Increment (CA);
   Atomics.Increment (CA);

   A.Assert (not Atomics.Decrement (CA), "counter should still be at 2");
   A.Assert (Atomics.Counter_Value (CA) = 2);
   A.Assert (not Atomics.Decrement (CA), "counter should still be at 1");
   A.Assert (Atomics.Decrement (CA), "counter should still be at 0");
   A.Assert (Integer (Atomics.Counter'Size), 64);
   return A.Report;
end Test;
