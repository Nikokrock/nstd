--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with System;
with NStd.Counters.Atomics;

package NStd.Counters.Biased is

   type Counter is private;

   subtype CounterRef is System.Address;
   --  Address needs to point to a region of memory of at least 8 bytes
   --  (64bits). By using a 64bits counter, it means that no overflow check is
   --  needed.

   procedure Increment (Self : CounterRef)
   with Inline_Always => True;

   function Decrement (Self : CounterRef) return Boolean
   with Inline_Always => True;

   procedure Initialize (Self : CounterRef)
   with Inline_Always => True;

   function Counter_Value (Self : CounterRef) return UInt64
   with Inline_Always => True;

private

   type Counter is record
      RC  : UInt64;
      ARC : NStd.Counters.Atomics.Counter;
      Id  : System.Address;
   end record;

end NStd.Counters.Biased;
