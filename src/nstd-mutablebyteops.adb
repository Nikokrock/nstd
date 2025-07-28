--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with NStd.Unsafe;

package body NStd.MutableByteOps is

   function First (Self: MutableBytes) return Cursor is
      pragma Unreferenced (Self);
   begin
      return 0;
   end First;

   function Next (Self: MutableBytes; C : Cursor) return Cursor is
      pragma Unreferenced (Self);
   begin
      return C + 1;
   end Next;

   function Length (Self : MutableBytes) return SizeType is
   begin
      return Self.Length;
   end Length;

   function Has_Element (Self : MutableBytes; C : Cursor) return Boolean is
   begin
      return SizeType (C) < Self.Length;
   end Has_Element;

   function Unsafe_Get(Self : MutableBytes; C : Cursor) return Byte
   is
      pragma Suppress(All_Checks);
   begin
      return Unsafe.Get (self.content.addr, SizeType (C));
   end unsafe_get;

   function Move_to_bytes(self: in out MutableBytes) return NStd.ByteOps.Bytes is
      Result : NStd.ByteOps.Bytes;
   begin
      --  Allocate the Bytes object
      Result := NStd.ByteOps.Init (Self.Content.Addr, Self.Length);

      --  Release the MutableBytes one by resetting it
      Self.Content.Addr := System.Null_Address;
      Self.Length := 0;
      Self.Capacity := 0;

      return Result;
   end move_to_bytes;

   procedure non_inlined_append(self: in out MutableBytes; src: Byte) is
      addr : System.Address;
   begin
      if self.length = 0 then
         addr := Unsafe.Allocate (32);
         self.content.Addr := addr;
         self.capacity := 32;
         self.length := 1;
      else
         self.capacity := self.capacity * 2;
         Unsafe.Reallocate (self.content.Addr, self.capacity);
         self.length := self.length + 1;
      end if;

      Unsafe.Set (self.content.Addr, self.length - 1, src);

   end non_inlined_append;

   procedure append(self: in out MutableBytes; src: Byte) is
   begin
      if self.length < self.capacity then
         Unsafe.Set (self.content.Addr, self.length, src);
         self.length := self.length + 1;
      else
         Non_Inlined_Append(self, src);
      end if;
   end append;

   procedure append(self: in out MutableBytes; src: NStd.ByteOps.Bytes) is
   begin
      null;
   end append;

      procedure append(self: in out MutableBytes; src: MutableBytes) is
   begin
      null;
   end append;

   procedure Append (Self: in out MutableBytes; Src: String) is
   begin
      Unsafe.Reallocate_And_Copy
         (Unsafe.Reference (Src),
          SizeType (Src'Length),
          Self.Content.Addr,
          Self.Length,
          Self.Capacity);
   end append;

   procedure append
      (self: in out MutableBytes;
       src:  Ada.Strings.Unbounded.Unbounded_String) is
   begin
      null;
   end append;

   function As_String (Self: MutableBytes; First, Last: SizeType) return String
   is
   begin
      if Last <= First then
         return "";
      end if;

      if Last - First > SizeType (Integer'Last) then
         raise Constraint_Error;
      end if;

      if Last > Self.Length then
         raise Constraint_Error;
      end if;

      declare
         Result : String (1 .. Integer (Last - First));
      begin
         Unsafe.Copy
            (Unsafe.Addr (Self.Content.Addr, First),
             Unsafe.Reference (Result),
             Last - First);
         return Result;
      end;
   end As_string;

end NStd.MutableByteOps;

