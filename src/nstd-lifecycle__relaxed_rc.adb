--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with Std.Memory;
with Ada.Unchecked_Deallocation;
with Std.Unsafe;
with System.Address_To_Access_Conversions;

package body Std.Lifecycle is

   package CounterOps is new System.Address_To_Access_Conversions (Counter);

   procedure Free is new Ada.Unchecked_Deallocation(Counter, CounterAccess);

   procedure Finalize (Self : in out Limited_Address) is
   begin
      Std.Memory.Free (Self.Addr);
   end Finalize;

   procedure Adjust (Self : in out Refcounted_Address) is
   begin
      if Self.Addr /= Null_Address then
         Self.Counter.all := Self.Counter.all + 1;
      end if;
   end Adjust;

   procedure Finalize (Self : in out Refcounted_Address) is
   begin
      if Self.Addr /= Null_Address then
         Self.Counter.all := Self.Counter.all - 1;
         if Self.Counter.all = 0 then 
            declare
               A  : constant System.Address := Std.Unsafe.Addr (Self.Addr, - Self.Alloc_Offset);
               AC : constant System.Address := CounterOps.To_Address (CounterOps.Object_Pointer (Self.Counter));
            begin
               Std.Memory.Free (A);
               if A /= AC then
                  Free (Self.Counter);
               end if;
            end;
         end if;
      end if;
   end Finalize;

   procedure Start_Refcounting
       (Self         : in out Refcounted_Address;
        Addr         : System.Address;
        Alloc_Offset : SizeType)
   is
   begin
      Self.Addr := Addr;
      Self.Alloc_Offset := Alloc_Offset;
      Self.Counter := new Counter;
      Self.Counter.all := 1;
   end Start_Refcounting;

   procedure Clone_And_Start_Refcounting
      (Self         : in out Refcounted_Address;
       Addr         : System.Address;
       Size         : SizeType)
   is
      Block_Address : System.Address := Std.Unsafe.Allocate (Size + 8);
   begin
      Self.Addr := Std.Memory.memcpy(Std.Unsafe.Addr (Block_Address, 8), Addr, Size);
      Self.Alloc_Offset := 8;
      Self.Counter := CounterAccess (CounterOps.To_Pointer (Block_Address));
   end;

   procedure Increment
      (Self : in out Refcounted_Address)
   is
   begin
      Self.Counter.all := Self.Counter.all + 1;
   end Increment;
end Std.LifeCycle;
