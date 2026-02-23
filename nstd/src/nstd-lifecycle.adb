--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--
with NStd.Unsafe;
with NStd.Memory;
with NStd.Ref_Counters;

package body NStd.Lifecycle is

   package Counters renames NStd.Ref_Counters;

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
   Limited_Reference : constant Address := Null_Address;
   Reference : constant Address := To_Address (SizeType (1));

   -- Finalize --
   procedure Finalize (Self : in out Limited_Address) is
   begin
      NStd.Memory.Free (Self.Addr);
   end Finalize;

   -- Adjust --

   procedure Adjust (Self : in out Refcounted_Mem) is
      pragma Suppress (All_Checks);
   begin
      if Self.Block.Length <= SSO_Max then
         --  If the string size is inferior to SSO_Max then the we need to
         --  adjust the address so that it points to the new object and not the
         --  former one.
         --  ??? Need to be reviewed ???
         Self.Block.Addr := Self'Address + SizeType (16);
      else
         if Self.Counter /= Null_Address then
            --  If the block is already refcounted, just increment the counter.
            Counters.Increment (Self.Counter);

         elsif Self.Block_Addr = Limited_Reference then
            --  On assignment of reference force cloning if this is a limited
            --  reference.
            Clone_And_Start_Refcounting (Self, Self.Block);

         end if;
      end if;
   end Adjust;

   -- Finalize --

   procedure Finalize (Self : in out Refcounted_Mem) is
      pragma Suppress (All_Checks);
      CA : constant System.Address := Self.Counter;
   begin
      --  SSO case or reference to non-managed memory block.
      if Self.Block.Length <= SSO_Max or else CA = Null_Address then
         Self.Block   := NStd.Mem.Empty_BLock;
         Self.Counter := Null_Address;
         return;
      end if;

      declare
         BA : constant System.Address := Self.Block_Addr;
      begin
         if Counters.Decrement (CA) then
            --  Free the memory block.
            NStd.Memory.Free (BA);

            --  In the case the counter was allocated separately also free it.
            if BA /= CA then
               NStd.Memory.Free (CA);
            end if;

            --  Reset the structure
            Self.Counter := Null_Address;
            Self.Block   := NStd.Mem.Empty_Block;
         end if;
      end;
   end Finalize;

   -- Start_Refcounting --

   procedure Start_Refcounting
      (Self  : in out Refcounted_Mem; Block : NStd.Mem.Block)
   is
      pragma Suppress (All_Checks);
   begin
      if Block.Length <= SSO_Max then
         Self.Block.Addr := Self'Address + 16;
         Self.Block.Length := Block.Length;
         Self.Block.Addr := NStd.Memory.memcpy
            (Self.Block.Addr, Block.Addr, Block.Length);
         --  As we are in charge of the original block of memory we need to
         --  release it.
         NStd.Memory.Free (Block.Addr);

      else
         Self.Block := Block;
         Self.Block_Addr := Block.Addr;

         --  We need a separate memory block for the counter in that case
         Self.Counter := NStd.Unsafe.Allocate (Counters.Counter'Size / 8);
         Counters.Initialize(Self.Counter);
      end if;
   end Start_Refcounting;

   procedure Start_Limited_Reference
       (Self  : in out Refcounted_Mem;
        Block : NStd.Mem.Block)
   is
      pragma Suppress (All_Checks);
   begin
      if Block.Length <= SSO_Max then
         Self.Block.Addr := Self'Address + 16;
         Self.Block.Addr := NStd.Memory.memcpy
            (Self.Block.Addr, Block.Addr, Block.Length);
         Self.Block.Length := Block.Length;
      else
         Self.Block := Block;
         Self.Block_Addr := Limited_Reference;

         --  This is a pure reference. No need for counters
         Self.Counter := System.Null_Address;
      end if;
   end Start_Limited_Reference;

   procedure Start_Reference
       (Self  : in out Refcounted_Mem;
        Block : NStd.Mem.Block)
   is
      pragma Suppress (All_Checks);
   begin
      if Block.Length <= SSO_Max then
         Self.Block.Addr := Self'Address + 16;
         Self.Block.Addr := NStd.Memory.memcpy
            (Self.Block.Addr, Block.Addr, Block.Length);
         Self.Block.Length := Block.Length;
      else
         Self.Block := Block;
         Self.Block_Addr := Reference;

         --  This is a pure reference. No need for counters
         Self.Counter := System.Null_Address;
      end if;
   end Start_Reference;

   procedure Clone_And_Start_Refcounting
      (Self : in out Refcounted_Mem; Block : NStd.Mem.Block)
   is
      pragma Suppress (All_Checks);
   begin
      if Block.Length <= SSO_Max then
         Self.Block.Addr := Self'Address + 16;
         Self.Block.Addr := NStd.Memory.memcpy
            (Self.Block.Addr, Block.Addr, Block.Length);
         Self.Block.Length := Block.Length;
      else
         --  Allocate needed data + size of counter address
         Self.Block_Addr := NStd.Unsafe.Allocate
            (Block.Length + Counters.Counter'Size / 8);
         Self.Block.Addr := NStd.Memory.memcpy
            (Self.Block_Addr + Counters.Counter'Size / 8,
             Block.Addr, Block.Length);
         Self.Counter := Self.Block_Addr;
         Self.Block.Length := Block.Length;
         Counters.Initialize (Self.Counter);
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
      if Self.Block.Length = 0 then
         return Empty_Refcounted_Mem;
      end if;

      if Abs_Last < -Self.Block.Length then
         return Empty_Refcounted_Mem;
      elsif Abs_Last < 0 then
         Abs_Last := Self.Block.Length + Abs_Last;
      elsif Abs_Last > Self.Block.Length then
         Abs_Last := Self.Block.Length;
      end if;

      if Abs_First < - Self.Block.Length then
         Abs_First := 0;
      elsif Abs_First < 0 then
         Abs_First := Self.Block.Length + Abs_First;
      end if;

      if Abs_First >= Abs_Last then
         return Empty_Refcounted_Mem;
      end if;

      Slice_Length := Abs_Last - Abs_First;

      if Slice_Length <= 16 then
         return Result : Refcounted_Mem do
            Result.Block.Addr := Result'Address + 16;
            Result.Block.Addr := NStd.Memory.memcpy
               (Result.Block.Addr,
                Self.Block.Addr + Abs_First,
                Slice_Length);
            Result.Block.Length := Slice_Length;
         end return;
      else
         return Result : Refcounted_Mem do
            Result.Block.Addr := Self.Block.Addr + First;
            Result.Block_Addr := Self.Block_Addr;
            Result.Block.Length := Slice_Length;
            Result.Counter := Self.Counter;

            if Self.Counter /= Null_Address then
               Counters.Increment (Self.Counter);
            elsif Self.Block_Addr = Limited_Reference then
               Clone_And_Start_Refcounting (Result, Result.Block);
            end if;
         end return;
      end if;
   end Slice;

   -- Block --

   function Block (Self : Refcounted_Mem) return NStd.Mem.Block is
   begin
      return Self.Block;
   end Block;

   function Addr (Self : Refcounted_Mem) return System.Address is
   begin
      return Self.Block.Addr;
   end Addr;

   function Length (Self : Refcounted_Mem) return SizeType is
   begin
      return Self.Block.Length;
   end Length;

   -- Reference_Count --

   function Reference_Count (Self : Refcounted_Mem) return UInt64 is
   begin
      if Self.Block.Length <= SSO_Max or else Self.Counter = Null_Address then
         return 0;
      else
         return Counters.Counter_Value (Self.Counter);
      end if;
   end Reference_Count;

end NStd.LifeCycle;
