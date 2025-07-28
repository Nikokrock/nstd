--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with NStd.Memory;
with System.Address_To_Access_Conversions;
with System.Storage_Elements; use System.Storage_Elements;

package body NStd.Unsafe is

   --  This is a way to reference an arbitraty size region of memory and
   --  address it as an array of Byte.
   type Buffer is array (0 .. SizeType'Last) of Byte;
   pragma Suppress_Initialization (Buffer);

   package BufferOps is new System.Address_To_Access_Conversions(Buffer);
   use BufferOps;

   function Next_UTF8_Offset_Internal
      (Self : Address; Offset : SizeType; Length : SizeType)
      return SizeType;
   --  Part of the Next_UTF8_Offset that is not inlined (called each time a
   --  non ASCII character is found).
  
   function Get_UTF8_Internal
      (Self : Address; Offset : in out SizeType; length: SizeType)
      return UInt32;
   --  Part of the Get_UTF8 that is not inlined (called each time a
   --  non ASCII character is found).
  
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
      if Length > ISize'Last - 1 then
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

      Dummy := NStd.Memory.memcpy (Addr (Dst, Dst_Offset),
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
         Dummy := NStd.Memory.memcpy (Addr (Dst, Dst_Offset),
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

   -- Next_UTF8_Offset --

   function Next_UTF8_Offset
      (Self : Address; Offset : SizeType; Length : SizeType) return SizeType
   is
   begin
      if Offset >= Length then
         return Offset;
      else
         if Get (Self, Offset) <= 16#7F# then
            return Offset + 1;
         else
            return Next_UTF8_Offset_Internal (Self, Offset, Length);
         end if;
      end if;
   end Next_UTF8_Offset;

   function Next_UTF8_Offset_Internal
      (Self : Address; Offset : SizeType; Length : SizeType)
      return SizeType
   is
      function has_continuation_bytes(num: SizeType) return Boolean;
      function has_continuation_bytes(num: SizeType) return Boolean
      is
      begin
         if Offset + num >= Length then
            return False;
         else
            for idx in 1 .. num loop
               if get(self, Offset + idx) <= 16#7F# or else
                  get(self, Offset + idx) >= 16#C0#
               then
                  return False;
               end if;
            end loop;
            return True;
         end if;
      end has_continuation_bytes;
      b : Byte;
   begin
      if Offset >= Length then
         return Offset;
      else
         -- Unicode standards now recommends to emit one error per bytes when
         -- an incomplete/invalid sequence is found. Thus we need to verify
         -- the complete sequence in order to ensure we can skip some
         -- bytes. For example E1,A0,20 which is a truncated 3 bytes sequence
         -- should not cause this function to skip the space character
         -- following the invalid sequence.
         b := get(self, Offset);
         if b <= 16#7F# then
            -- valid ascii chracter
            return Offset + 1;
         elsif b <= 16#BF# then
            -- unexpected continuation byte should be handled one error and
            -- thus consumed only one byte
            return Offset + 1;
         elsif b <= 16#DF# then
            -- 2 bytes sequence
            if has_continuation_bytes(1) then
               return Offset + 2;
            else
               return Offset + 1;
            end if;
         elsif b <= 16#EF# then
            -- 3 bytes sequence
            if has_continuation_bytes(2) then
               return Offset + 3;
            else
               return Offset + 1;
            end if;
         elsif b <= 16#F7# then
            -- 5 bytes sequence
            if has_continuation_bytes(3) then
               return Offset + 4;
            else
               return Offset + 1;
            end if;
         elsif b <= 16#FB# then
            -- 5 bytes sequence
            if has_continuation_bytes(4) then
               return Offset + 5;
            else
               return Offset + 1;
            end if;
         elsif b <= 16#FD# then
            -- 6 bytes sequence
            if has_continuation_bytes(5) then
               return Offset + 6;
            else
               return Offset + 1;
            end if;
         else
            -- invalid characters FE and FF
            return Offset + 1;
         end if;
      end if;
   end Next_UTF8_Offset_Internal;

   function Get_UTF8_Internal
      (Self : Address; Offset : in out SizeType; length: SizeType)
      return UInt32
   is
      pragma Suppress(All_Checks);
      Result : UInt32 := UInt32 (Get (Self, Offset));

   begin
      if (Result and 16#80#) = 0 then
         Offset := Offset + 1;

      elsif Result < 16#E0# then
         Result := Shift_Left (Result and 16#1F#, 6) or
            (UInt32 (Get (Self, Offset + 1)) and 16#3F#);
         Offset := Offset + 2;

      elsif Result < 16#F0# then
         Result := Shift_Left (Result, 12) or
            (Shift_Left (UInt32 (Get (Self, Offset + 1)) and 16#3F#, 6)) or
            (UInt32 (Get (Self, Offset + 2)) and 16#3F#);
         Offset := Offset + 3;

      else
         Result := Shift_Left (Result and 16#07#, 18) or
            (Shift_Left (UInt32 (Get (Self, Offset + 1)) and 16#3F#, 12)) or
            (Shift_Left (UInt32 (Get (Self, Offset + 2)) and 16#3F#, 6)) or
            (UInt32 (Get (Self, Offset + 3)) and 16#3F#);
         Offset := Offset + 4;
      end if;

      return Result;
   end Get_UTF8_Internal;

   function Get_UTF8
      (Self : Address; Offset : in out SizeType; Length : SizeType)
      return Uint32
   is
      pragma Suppress(All_Checks);
      binary_char : constant UInt32 := Uint32 (Get (Self, Offset));
   begin
      -- fast path for ascii characters
      if binary_char < 128 then
         Offset := Offset + 1;
         return binary_char;
      else
         return Get_UTF8_Internal (Self, Offset, Length);
      end if;
   end Get_UTF8;

   -- Reference --

   function Reference (S : String) return Address is
   begin
      if S'Length > 0 then
         return S (S'First)'Address;
      else
         return Null_Address;
      end if;
   end Reference;

end NStd.Unsafe;
