--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with NStd.Unsafe;
with NStd.Memory;
with NStd.ASCII;
pragma Warnings(Off);
with Ada.Strings.Unbounded.Aux;
pragma Warnings(On);

package body NStd.ByteOps is

   function memchr(self: Bytes; b: Byte; index: SizeType:=0) return SizeType;
   -- Binding to memchr C function. If a character is not found then
   -- SizeType'Last is returned.

   -----------
   -- Bytes --
   -----------

   procedure Init (Self: in out Bytes; Str: String) is
   begin
      NStd.Lifecycle.Finalize (Self.Content);
      if Str'Length > 0 then
         NStd.Lifecycle.Clone_And_Start_Refcounting
            (Self.Content,
             Unsafe.Reference (Str),
             Str'Length);
         Self.Length  := SizeType (Str'Length);
      end if;
   end Init;

   function Init (Str: String) return Bytes
   is
   begin
      return Result: Bytes do
         Init (Result, Str);
      end return;
   end init;

   procedure Init
      (Self: in out Bytes; Str: Ada.Strings.Unbounded.Unbounded_String)
   is
      use Ada.Strings.Unbounded.Aux;
      Str_Length: Natural;
      Str_Access: Big_String_Access;
   begin
      NStd.Lifecycle.Finalize (Self.Content);
      Get_String(Str, Str_Access, Str_Length);
      if Str_Length > 0 then
         NStd.Lifecycle.Start_Refcounting
            (Self.Content,
             Unsafe.Clone (Str_Access(1)'Address, SizeType (Str_Length)),
             0);
         Self.Length  := SizeType (Str_Length);
      end if;
   end Init;

   function Init
      (Str: Ada.Strings.Unbounded.Unbounded_String)
      return Bytes
   is
   begin
      return Result: Bytes do
         Init (Result, Str);
      end return;
   end init;

   function Init (Addr : System.Address; Length : SizeType) return Bytes is
   begin
      return Result : Bytes do
         if Length > 0 then
            Result.Length := Length;
            NStd.Lifecycle.Start_Refcounting (Result.Content, Addr, 0);
         end if;
      end return;
   end Init;

   -- Clone --

   function Clone (Self : Bytes) return Bytes
   is
   begin
      return Result: Bytes do
         if Self.Length > 0 then
            NStd.Lifecycle.Start_Refcounting
               (Result.Content,
                Unsafe.Clone (Self.Content.Addr, Self.Length),
                0);
            Result.Length := Self.Length;
         end if;
      end return;
   end Clone;

   -- Length --
   
   function Length (Self : Bytes) return SizeType is
   begin
      return Self.Length;
   end Length;

   -- Starts_With --

   function Starts_With (Self : Bytes; Prefix : Bytes) return Boolean
   is
   begin
      if Prefix.Length = 0 then
         return True;
      elsif Self.Length < Prefix.Length then
         return False;
      else
         return NStd.Memory.Memcmp
            (Dst    => Self.Content.Addr,
             Src    => Prefix.Content.Addr,
             Length => Prefix.Length) = 0;
      end if;
   end Starts_With;

   function Starts_With (Self : Bytes; Prefix : String) return Boolean
   is
   begin
      if Prefix'Length = 0 then
         return True;
      elsif Self.Length < Prefix'Length then
         return False;
      else
         return NStd.Memory.Memcmp
            (Dst    => Self.Content.Addr,
             Src    => Unsafe.Reference (Prefix),
             Length => Prefix'Length) = 0;
      end if;
   end Starts_With;

   -- Ends_With --

   function Ends_With (Self : Bytes; Suffix : Bytes) return Boolean
   is
   begin
      if Suffix.Length = 0 then
         return True;
      elsif Self.Length < Suffix.Length then
         return False;
      else
         return NStd.Memory.Memcmp
            (Dst    => Unsafe.Addr
               (Self.Content.Addr, Self.Length - Suffix.Length),
             Src    => Suffix.Content.Addr,
             Length => Suffix.Length) = 0;
      end if;
   end Ends_With;

   function Ends_With (Self : Bytes; Suffix : String) return Boolean
   is
   begin
      if Suffix'Length = 0 then
         return True;
      elsif Self.Length < Suffix'Length then
         return False;
      else
         return NStd.Memory.Memcmp
            (Dst    => Unsafe.Addr
               (Self.Content.Addr, Self.Length - Suffix'Length),
             Src    => Unsafe.Reference (Suffix),
             Length => Suffix'Length) = 0;
      end if;
   end Ends_With;

   function "=" (Left : Bytes; Right : Bytes) return Boolean is
   begin
      return Unsafe.Is_Equal
         (Left.Content.Addr, Right.Content.Addr, Left.Length, Right.Length);
   end "=";

   function "=" (Left : Bytes; Right : String) return Boolean is
   begin
      return Unsafe.Is_Equal
         (Left.Content.Addr,
          Unsafe.Reference (Right),
          Left.Length,
          SizeType (Right'Length)); 
   end "=";

   function Slice (Self: Bytes; First, Last: SizeType) return Bytes is
   begin
      if Last > Self.Length or else Last <= First then
         return Empty_Bytes;
      end if;

      return result: Bytes do
         if self.length > 0 then
            result.content := self.content;
            result.content.addr := Unsafe.Addr (Self.Content.Addr, First);
            result.content.alloc_offset := self.content.alloc_offset + first;
            result.length := last - first;
            NStd.Lifecycle.Increment (Result.Content);
         end if;
      end return;
   end Slice;

   -- Trim --

   function Trim (Self : Bytes) return Bytes is
   begin
      if Self.Length = 0 then
         return Self;
      end if;

      declare
         Start_Idx : SizeType := Self.Length;
         End_Idx   : SizeType := Self.Length;
      begin
         for Idx in 0 .. End_Idx - 1 loop
            if not NStd.ASCII.Is_ASCII_Whitespace (Unsafe_Get (Self, Idx)) then
               Start_Idx := Idx;
               exit;
            end if;
         end loop;

         for Idx in reverse Start_Idx + 1 .. Self.Length loop
            if not NStd.ASCII.Is_ASCII_Whitespace (Unsafe_Get (Self, Idx - 1)) then
               End_Idx := Idx;
               exit;
            end if;
         end loop;

         return Slice (Self, Start_Idx, End_Idx);
      end;
   end Trim;

   function Trim_Leading (Self : Bytes) return Bytes is
   begin
      if Self.Length = 0 then
         return Self;
      end if;

      declare
         Start_Idx : SizeType := Self.Length;
      begin
         for Idx in 0 .. Self.Length - 1 loop
            if not NStd.ASCII.Is_ASCII_Whitespace (Unsafe_Get (Self, Idx)) then
               Start_Idx := Idx;
               exit;
            end if;
         end loop;

         return Slice (Self, Start_Idx, Self.Length);
      end;
   end Trim_Leading;

   function Trim_Trailing (Self : Bytes) return Bytes is
   begin
      if Self.Length = 0 then
         return Self;
      end if;

      declare
         End_Idx : SizeType := 0;
      begin
         for Idx in reverse 1 .. Self.Length loop
            if not NStd.ASCII.Is_ASCII_Whitespace (Unsafe_Get (Self, Idx - 1)) then
               End_Idx := Idx;
               exit;
            end if;
         end loop;

         return Slice (Self, 0, End_Idx);
      end;
   end Trim_Trailing;

   function Get (Self: Bytes; Index : SizeType) return Byte
   is
      pragma Suppress(All_Checks);
   begin
      if Index < Self.Length then
         return Unsafe.Get (Self.Content.Addr, Index);
      else
         raise Constraint_Error with "element" & Index'Img;
      end if;
   end get;

   function Get_Char (Self : Bytes; Index : SizeType) return Character is
   begin
      return as_char (Get (Self, Index));
   end get_char;

   function Unsafe_Get (Self : Bytes; Index : SizeType) return Byte
   is
      pragma Suppress(All_Checks);
   begin
      return Unsafe.Get (Self.Content.Addr, Index);
   end unsafe_get;

   function First (Self: Bytes) return Cursor is
      pragma Unreferenced (Self);
   begin
      return Cursor (0);
   end First;

   function Unsafe_Get (Self : Bytes; C : Cursor) return Byte
   is
      pragma Suppress(All_Checks);
   begin
      return Unsafe.Get (Self.Content.Addr, SizeType (C));
   end Unsafe_Get;

   function Next (Self : Bytes; C : Cursor) return Cursor is
      pragma Suppress (All_Checks);
   begin
      return C + 1;
   end;

   function Has_Element (Self : Bytes; C : Cursor) return Boolean is
      pragma Suppress (All_Checks);
   begin
      return SizeType (C) < Self.Length;
   end Has_Element;

   function UTF8_Next (Self : Bytes; C : Cursor) return Cursor
   is
      pragma Suppress(All_Checks);
   begin
      return Cursor
         (Unsafe.Next_UTF8_Offset (Self.Content.Addr, SizeType (C), Self.Length));
   end UTF8_Next;

   function UTF8_Get (Self : Bytes; C : in out Cursor) return UInt32 is
   begin
      return Unsafe.Get_UTF8 (Self.Content.Addr, SizeType (C), Self.Length);
   end UTF8_Get;

   function memchr(self: Bytes; b: Byte; index: SizeType:=0) return SizeType is

      function internal
         (addr: System.Address; i: Integer; size: SizeType) return System.Address;
      pragma Import(C, internal, "memchr");

      result: System.Address;
      use all type System.Address;
   begin
      result := internal
         (Unsafe.Addr (self.content.Addr, index),
          Integer(b),
          self.length - index);
      if result = System.Null_Address then
         return SizeType'Last;
      end if;

      return Unsafe.Offset (Result, Self.Content.Addr);
   end memchr;

   function find (Self: Bytes; B : Byte; Index : SizeType:=0) return SizeType is
      pragma Suppress(All_Checks);
   begin
      if self.length = 0 then
         return SizeType'Last;
      else
         -- This probably deserves a modern implementation that takes advantage
         -- of SSE, Neon or other SIMD extensions. In the meantime probe using
         -- naive approach for at most 16 characters and if the byte is not
         -- found delegate to memchr which is faster when byte frequency is not
         -- too high.
         declare
            last_searched: constant SizeType := min
               (self.length - 1, index + 16);
         begin
            -- Naive search is faster when frequency is high
            for idx in index .. last_searched loop
               if Unsafe.Get(self.content.addr, idx) = b then
                  return idx;
               end if;
            end loop;
            
            -- Character is not in the first 16, delegate to memchr based
            -- search
            if last_searched < self.length - 1 then
               return memchr(self, b => b, index => last_searched + 1);
            else
               return Not_Found;
            end if;
         end;
      end if;
   end find;

   function Find
      (Self : Bytes; Pattern : Bytes; Index : SizeType := 0) return SizeType
   is
   begin
      return 0;

   end Find;

   function count(self: Bytes; b: Byte; index: SizeType := 0) return SizeType
   is
      result  : SizeType := 0;
      cindex  : SizeType := index;
      nothing : SizeType := 0;
   begin
      if self.length = 0 then
         return 0;
      else
         while cindex <= self.length loop
            if nothing = 16 then
               cindex := find(self, b => b, index => cindex);
               exit when cindex = SizeType'Last;
               result := result + 1;
               nothing := 0;
            else
               if Unsafe.Get (self.content.addr, cindex) = b then
                  result := result + 1;
                  nothing := 0;
               else
                  nothing := nothing + 1;
               end if;
            end if;

            cindex := cindex + 1;
         end loop;
      end if;           
      return result;
   end count;

   function Lines (Self : Bytes) return Line_Iterator is
   begin
      return (Content => Self);
   end Lines;

   function First_Line (Self : Line_Iterator) return Line_Cursor is
   begin
      return Result: Line_Cursor do
         Result.First := 0;
         Result.Last := Find (Self.Content, NStd.ASCII.LF, 0);
         if Result.Last = Not_Found then
            Result.Last := Self.Content.Length;
         end if;
      end return;
   end First_Line;

   function Unsafe_Get_Line (Self : Line_Iterator; C : Line_Cursor) return Bytes
   is
   begin
      return Slice (Self.Content, C.First, C.Last);
   end Unsafe_Get_Line;

   function Next_Line (Self : Line_Iterator; C : Line_Cursor) return Line_Cursor
   is
   begin
      return Result : Line_Cursor do
         Result.First := C.Last + 1;
         Result.Last := Find (Self.Content, NStd.ASCII.LF, Result.First);
         if Result.Last = Not_Found then
            Result.Last := Self.Content.Length;
         end if;
      end return;
   end Next_Line;

   function Has_Line (Self : Line_Iterator; C : Line_Cursor) return Boolean is
   begin
      return C.First < Self.Content.Length; 
   end Has_Line;
end NStd.ByteOps;
