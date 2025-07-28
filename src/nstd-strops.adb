--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

package body NStd.StrOps is

   function Init (S: String) return Str
   is
   begin
      return Result : Str do
         if S'Length > 0 then
            NStd.Byteops.Init (Result.Content, S);
         end if;
      end return;
   end init;

   function Init (S: Ada.Strings.Unbounded.Unbounded_String) return Str
   is
   begin
      return result: Str do
         NStd.Byteops.Init (Result.Content, S);
      end return;
   end Init;

   -- Clone --

   function Clone (Self : Str) return Str
   is
   begin
      return (Content => NStd.Byteops.Clone (Self.Content));
   end Clone;

   function Byte_Length (Self : Str) return SizeType is
   begin
      return NStd.Byteops.Length (Self.Content);
   end Byte_Length;

   -- Starts_With --
   
   function Starts_With (Self : Str; Prefix : Str) return Boolean
   is
   begin
      return NStd.Byteops.Starts_With (Self.Content, Prefix.Content);
   end Starts_With;

   function Starts_With (Self : Str; Prefix : String) return Boolean
   is
   begin
      return NStd.Byteops.Starts_With (Self.Content, Prefix);
   end Starts_With;

   function Ends_With (Self : Str; Suffix : Str) return Boolean
   is
   begin
      return NStd.Byteops.Ends_With (Self.Content, Suffix.Content);
   end Ends_With;

   function Ends_With (Self : Str; Suffix : String) return Boolean
   is
   begin
      return NStd.Byteops.Ends_With (Self.Content, Suffix);
   end Ends_With;

   function First (Self: Str) return Cursor
   is
      pragma Suppress (All_Checks);
      C : Cursor;
   begin
      C.Offset := NStd.Byteops.First (Self.Content);
      C.NextOffset := C.Offset;
      if NStd.Byteops.Has_Element (Self.Content, C.Offset) then
         C.CodePoint := NStd.Byteops.UTF8_Get (Self.Content, C.NextOffset);
      end if;

      return C;
   end First;

   function Next(self: Str; N: Cursor) return Cursor
   is
      pragma Suppress (All_Checks);
      Result : Cursor;
   begin
      Result.Offset := N.NextOffset;
      Result.NextOffset := N.NextOffset;
      if NStd.Byteops.Has_Element (Self.Content, N.NextOffset) then
         Result.Codepoint := NStd.Byteops.UTF8_Get (Self.Content, Result.NextOffset);
      end if;
      return Result;
   end Next;

   function Has_Element (Self: Str; n: Cursor) return Boolean
   is
      pragma Suppress (All_Checks);
      pragma Unreferenced (Self);
      use all type NStd.Byteops.Cursor;
   begin
      return N.Offset /= N.NextOffset;
   end Has_Element;

   function Unsafe_get(self: Str; n: Cursor) return Uint32
   is
      pragma Suppress(All_Checks);
   begin
      return N.CodePoint;
   end unsafe_get;
end NStd.StrOps;
