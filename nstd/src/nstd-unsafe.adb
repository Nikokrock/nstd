--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with NStd.Memory;
with System.Address_To_Access_Conversions;
with System.Storage_Elements; use System.Storage_Elements;
with Interfaces.C;

package body NStd.Unsafe is

   --  This is a way to reference an arbitraty size region of memory and
   --  address it as an array of Byte.
   type Buffer is array (0 .. SizeType'Last) of Byte;
   pragma Suppress_Initialization (Buffer);

   package BufferOps is new System.Address_To_Access_Conversions(Buffer);
   use BufferOps;

   function Get_UTF8_Internal
      (Self      : in out Address;
       First_Byte : UInt32)
      return UInt32
   with Inline => False;

   procedure Reallocate_And_Copy_Internal
      (Src          : Address;
       Src_Length   : SizeType;
       Dst          : in out Address;
       Dst_Offset   : SizeType;
       Dst_Length   : in out SizeType);
   --  Part of Reallocate_And_Copy that is not inlined (called each time Dst
   --  needs to be resized).

   -- Allocate --

   function Allocate (Length : SizeType) return Address is
      Addr   : System.Address;
   begin
      if Length > SizeType'Last - 2 then
         raise Storage_Error with "allocation length too large";
      end if;

      if Length < 1 then
         raise Storage_Error with "allocation length should be > 0";
      end if;

      Addr := NStd.Memory.Malloc (Length);

      if Addr = Null_Address then
         raise Storage_Error with "memory allocation failed";
      end if;

      return Addr;
   end Allocate;

   -- Free --

   procedure Free (Self : Address) is
   begin
      NStd.Memory.Free (Self);
   end Free;

   -- Clone --

   function Clone(Addr: Address; Length: SizeType) return Address
   is
      Result : Address := Allocate (Length);
   begin
      Result := NStd.Memory.memcpy (Result, Addr, Length);
      return Result;
   end Clone;

   -- Reallocate --

   procedure Reallocate (Addr : in out Address; Length : SizeType) is
   begin
      if Length > ISize'Last - 1 then
         raise Storage_Error with "allocation length too large";
      end if;

      if Length < 0 then
         raise Storage_Error with "allocation length should be >= 0";
      end if;

      Addr := NStd.Memory.realloc (Addr, Length);

      if Addr = Null_Address and then Length > 0 then
         raise Storage_Error with "memory allocation failed";
      end if;
   end Reallocate;

   -- Copy --

   procedure Copy
      (Src    : Address;
       Dst    : Address;
       Length : SizeType)
   is
      pragma Warnings (Off);
      Dummy : Address;
      pragma Warnings (On);
   begin
      Dummy := NStd.Memory.Memcpy (Dst, Src, Length);
   end Copy;

   -- Reallocate_And_Copy --

   procedure Reallocate_And_Copy_Internal
      (Src          : Address;
       Src_Length   : SizeType;
       Dst          : in out Address;
       Dst_Offset   : SizeType;
       Dst_Length   : in out SizeType)
   is
      Dummy : Address;
   begin
      --  If called we are sure that there is not enough room in Dst.
      if Dst_Length = 0 then
         Dst_Length := 32;
      end if;

      --  Multiply by 2 until we reach the desired size
      while Dst_Length - Dst_Offset < Src_Length loop
         Dst_Length := Dst_Length * 2;
      end loop;

      if Dst = Null_Address then
         Dst := Allocate (Dst_Length);
      else
         Reallocate (Dst, Dst_Length);
      end if;

      Dummy := NStd.Memory.memcpy (Dst + Dst_Offset,
              Src,
              Src_Length);

   end Reallocate_And_Copy_Internal;

   procedure Reallocate_And_Copy
      (Src          : Address;
       Src_Length   : SizeType;
       Dst          : in out Address;
       Dst_Offset   : SizeType;
       Dst_Length   : in out SizeType)
   is
      Dummy : Address;
   begin
      if Dst_Length - Dst_Offset >= Src_Length then
         --  A Direct memcpy is possible here. This is the fastest path
         Dummy := NStd.Memory.memcpy (Dst + Dst_Offset,
                 Src,
                 Src_Length);
      else
         Reallocate_And_Copy_Internal
            (Src, Src_Length, Dst, Dst_Offset, Dst_Length);
      end if;
   end Reallocate_And_Copy;

   -- Is_Equal --

   function Is_Equal
      (Left         : Address;
       Right        : Address;
       Left_Length  : SizeType;
       Right_Length : SizeType)
      return Boolean
   is
   begin
      if Left_Length /= Right_Length then
         return False;
      elsif Left_Length = 0 then
         return True;
      elsif Left = Right then
         return True;
      else
         return NStd.Memory.Memcmp (Left, Right, Left_Length) = 0;
      end if;
   end Is_Equal;

   -- Addr --

   function Addr (Self : Address; Offset : SizeType) return Address is
      pragma Suppress (All_Checks);
   begin
      return System.Storage_Elements."+"
         (Self, System.Storage_Elements.Storage_Offset (Offset));
   end Addr;

   -- Offset --

   function Offset (Self : Address; Origin: Address) return SizeType is
   begin
      return SizeType (System.Storage_Elements."-" (Self, Origin));
   end Offset;

   -- Get --

   function Get (Self : Address; Offset: SizeType) return Byte is
      pragma Suppress(All_Checks);
   begin
      return To_Pointer(Self).all (Offset);
   end Get;

   -- Set --

   procedure Set (Self : Address; Offset : SizeType; b : Byte) is
      pragma Suppress(All_Checks);
   begin
      To_Pointer (Self).all (Offset) := b;
   end Set;

   function Get_UTF8_Internal
      (Self      : in out Address;
       First_Byte : UInt32)
      return UInt32
   is
      pragma Suppress(All_Checks);
      Result : UInt32 := First_Byte;

   begin
      if Result < 16#E0# then
         Result := Shift_Left (Result and 16#1F#, 6) or
            (UInt32 (Get (Self, 1)) and 16#3F#);
         Self := Addr (Self, 2);

      elsif Result < 16#F0# then
         Result := Shift_Left (Result and 16#0F#, 12) or
            (Shift_Left (UInt32 (Get (Self, 1)) and 16#3F#, 6)) or
            (UInt32 (Get (Self, 2)) and 16#3F#);
         Self := Addr (Self, 3);

      else
         Result := Shift_Left (Result and 16#07#, 18) or
            (Shift_Left (UInt32 (Get (Self, 1)) and 16#3F#, 12)) or
            (Shift_Left (UInt32 (Get (Self, 2)) and 16#3F#, 6)) or
            (UInt32 (Get (Self, 3)) and 16#3F#);
         Self := Addr (Self, 4);
      end if;

      return Result;
   end Get_UTF8_Internal;

   function Get_UTF8 (Self : in out Address) return UInt32 is
      pragma Suppress(All_Checks);
      --  binary_char : constant UInt32 := Uint32 (Get (Self, 0));
      binary_char : constant Byte := Get (Self, 0);
   begin
      -- fast path for ascii characters
      if binary_char < 128 then
         Self := Addr (Self, 1);
         return UInt32 (binary_char);
      else
         return Get_UTF8_Internal (Self, UInt32 (Binary_Char));
      end if;
   end Get_UTF8;

   function Validate_UTF8 (Self : Address; Length : SizeType) return Boolean is
      function Internal
         (Self : Address;
          Length : SizeType)
         return Interfaces.C.C_bool
      with Import => True,
           Convention => CPP,
           External_Name => "_ZN7simdutf13validate_utf8EPKcm";
   begin
      return Boolean (Internal (Self, Length));
   end Validate_UTF8;

   -- Reference --

   function Reference (S : String) return Address is
   begin
      if S'Length > 0 then
         return S (S'First)'Address;
      else
         return Null_Address;
      end if;
   end Reference;

   -- Starts_With --

   function Starts_With
      (Self   : Address;
       Length : SizeType;
       Prefix : Address;
       Prefix_Length : SizeType)
      return Boolean
   is
   begin
      if Prefix_Length = 0 then
         return True;
      elsif Length < Prefix_Length then
         return False;
      else
         return NStd.Memory.Memcmp
            (Dst => Self, Src => Prefix, Length => Prefix_Length) = 0;
      end if;
   end Starts_With;

end NStd.Unsafe;
