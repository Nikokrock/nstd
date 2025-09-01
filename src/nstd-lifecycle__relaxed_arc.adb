--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--
with NStd.Memory;
with NStd.Unsafe;
with NStd.Atomics;

package body NStd.Lifecycle is

   --  Max size for objects stored directly inside a refcounted_mem. Below that
   --  size the refcounted_mem object has the following structure:
   --
   --    Addr     8 bytes (= current address + 16)
   --    Length   8 bytes
   --    Data    16 bytes
   --
   --  When the size is strictly superior to 16 then the structure can be
   --  interpreted as follow:
   --
   --    Addr         8 bytes address of the data (an offset of Block_Addr)
   --    Length       8 bytes length of data in bytes
   --    Block_Addr   8 bytes address of the allocated block of memory
   --    Counter      8 bytes address of the counter. When the counter is
   --                         allocated at the same time as the data, the
   --                         adress of the counter is equal to Block_Addr.
   --                         If the Counter is a null address then the release
   --                         of the memory is manual.

   SSO_Max : constant SizeType := 16;

   -- Finalize --
   procedure Finalize (Self : in out Limited_Address) is
   begin
      NStd.Memory.Free (Self.Addr);
   end Finalize;

   -- Adjust --
   procedure Adjust (Self : in out Refcounted_Mem) is
      pragma Suppress (All_Checks);
   begin
      if Self.Length <= SSO_Max then
         Self.Addr := NStd.Unsafe.Addr (Self'Address, 16);
      else
         if Self.Counter /= Null_Address then
            NStd.Atomics.Increment (Self.Counter);
         else
            --  On assignment of reference force cloning
            Clone_And_Start_Refcounting (Self, Self.Addr, Self.Length);
         end if;
      end if;
   end Adjust;

   -- Finalize --
   procedure Finalize (Self : in out Refcounted_Mem) is
      pragma Suppress (All_Checks);
      CA : constant System.Address := Self.Counter;
   begin
      if Self.Length <= SSO_Max or else CA = Null_Address then
         Self.Length := 0;
         Self.Addr := Null_Address;
         Self.Counter := Null_Address;
         return;
      end if;

      declare
         BA : constant System.Address := Self.Block_Addr;
      begin
         if NStd.Atomics.Decrement (CA) then
            NStd.Memory.Free (BA);
            if BA /= CA then
               NStd.Memory.Free (CA);
            end if;
            Self.Counter := Null_Address;
            Self.Addr    := Null_Address;
            Self.Length  := 0;
         end if;
      end;
   end Finalize;

   -- Start_Refcounting --
   procedure Start_Refcounting
       (Self : in out Refcounted_Mem;
        Addr : System.Address;
        Size : SizeType)
   is
      pragma Suppress (All_Checks);
   begin
      if Size <= 16 then
         Self.Addr := NStd.Unsafe.Addr (Self'Address, 16);
         Self.Addr := NStd.Memory.memcpy (Self.Addr, Addr, Size);
         Self.Length := Size;
         --  As we are in charge of the original block of memory we need to
         --  release it.
         NStd.Memory.Free (Addr);
      else
         Self.Addr := Addr;
         Self.Block_Addr := Addr;
         Self.Length := Size;

         --  We need a separate memory block for the counter in that case
         Self.Counter := NStd.Unsafe.Allocate (8);
         NStd.Atomics.Initialize(Self.Counter);
      end if;
   end Start_Refcounting;

   procedure Start_Reference
       (Self : in out Refcounted_Mem;
        Addr : System.Address;
        Size : SizeType)
   is
      pragma Suppress (All_Checks);
   begin
      if Size <= 16 then
         Self.Addr := NStd.Unsafe.Addr (Self'Address, 16);
         Self.Addr := NStd.Memory.memcpy (Self.Addr, Addr, Size);
         Self.Length := Size;
         --  As we are in charge of the original block of memory we need to
         --  release it.
      else
         Self.Addr := Addr;
         Self.Block_Addr := Addr;
         Self.Length := Size;

         --  This is a pure reference. No need for counters
         Self.Counter := System.Null_Address;
      end if;
   end Start_Reference;

   procedure Clone_And_Start_Refcounting
      (Self         : in out Refcounted_Mem;
       Addr         : System.Address;
       Size         : SizeType)
   is
      pragma Suppress (All_Checks);
   begin
      if Size <= SSO_Max then
         Self.Addr := NStd.Unsafe.Addr (Self'Address, 16);
         Self.Addr := NStd.Memory.memcpy (Self.Addr, Addr, Size);
         Self.Length := Size;
      else
         Self.Block_Addr := NStd.Unsafe.Allocate (Size + 8);
         Self.Addr := NStd.Memory.memcpy
            (NStd.Unsafe.Addr (Self.Block_Addr, 8), Addr, Size);
         Self.Counter := Self.Block_Addr;
         Self.Length := Size;
         NStd.Atomics.Initialize (Self.Counter);
      end if;
   end;

   function Slice
      (Self  : Refcounted_Mem;
       First : SizeType;
       Last  : SizeType)
      return Refcounted_Mem
   is
      pragma Suppress (All_Checks);
      Abs_First : SizeType := First;
      Abs_Last  : SizeType := Last;
      Slice_Length : SizeType := 0;
   begin
      if Self.Length = 0 then
         return Empty_Refcounted_Mem;
      end if;

      if Abs_Last < -Self.Length then
         return Empty_Refcounted_Mem;
      elsif Abs_Last < 0 then
         Abs_Last := Self.Length + Abs_Last;
      elsif Abs_Last > Self.Length then
         Abs_Last := Self.Length;
      end if;

      if Abs_First < - Self.Length then
         Abs_First := 0;
      elsif Abs_First < 0 then
         Abs_First := Self.Length + Abs_First;
      end if;

      if Abs_First >= Abs_Last then
         return Empty_Refcounted_Mem;
      end if;

      Slice_Length := Abs_Last - Abs_First;

      if Slice_Length <= 16 then
         return Result : Refcounted_Mem do
            Result.Addr := NStd.Unsafe.Addr (Result'Address, 16);
            Result.Addr := NStd.Memory.memcpy
               (Result.Addr, Unsafe.Addr (Self.Addr, Abs_First), Slice_Length);
            Result.Length := Slice_Length;
         end return;
      else
         return Result : Refcounted_Mem do
            Result.Addr := Unsafe.Addr (Self.Addr, First);
            Result.Block_Addr := Self.Block_Addr;
            Result.Length := Slice_Length;
            Result.Counter := Self.Counter;
            NStd.Atomics.Increment (Self.Counter);
         end return;
      end if;
   end Slice;

   function Addr (Self : Refcounted_Mem) return System.Address is
   begin
      return Self.Addr;
   end Addr;

   function Length (Self : Refcounted_Mem) return SizeType is
   begin
      return Self.Length;
   end Length;

   -- Reference_Count --
   function Reference_Count (Self : Refcounted_Mem) return UInt64 is
   begin
      if Self.Length <= SSO_Max or else Self.Counter = Null_Address then
         return 0;
      else
         return NStd.Atomics.Counter_Value (Self.Counter);
      end if;
   end Reference_Count;
end NStd.LifeCycle;
