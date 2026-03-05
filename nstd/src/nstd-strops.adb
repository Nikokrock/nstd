--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with NStd.Unsafe;
with NStd.Simdutf;
with NStd.Mem; use NStd.Mem;

package body NStd.StrOps is

   -- Clone --

   function Clone (S: String; Check : Boolean := True) return Str
   is
   begin
      if Check and then
        not NStd.Simdutf.Validate_UTF8 (NStd.Mem.Ref (S))
      then
         raise Invalid_UTF8;
      end if;

      return Result : Str do
         if S'Length > 0 then
            Result.Content := NStd.Byteops.Clone (S);
         end if;
      end return;
   end Clone;

   function Clone (S: Unbounded_String; Check : Boolean := True) return Str
   is
   begin
      if Check and then
        not NStd.Simdutf.Validate_UTF8 (NStd.Mem.Ref (S))
      then
         raise Invalid_UTF8;
      end if;

      return result: Str do
         Result.Content := NStd.Byteops.Clone (S);
      end return;
   end Clone;

   function Clone (S : NStd.Byteops.Bytes; Check : Boolean := True) return Str
   is
   begin
      if Check and then not NStd.Byteops.Validate_UTF8 (S) then
         raise Invalid_UTF8;
      end if;
      return (Content => NStd.Byteops.Clone (S));
   end Clone;

   function Clone (Self : Str) return Str
   is
   begin
      -- Cloning a Str does not require a check
      return (Content => NStd.Byteops.Clone (Self.Content));
   end Clone;

   function "*" (Pattern : Str; N : SizeType) return Str is
   begin
      return (Content => NStd.Byteops."*" (Pattern.Content, N));
   end "*";

   function Reference (Addr : System.Address; Length : SizeType) return Str
   is
   begin
      return (Content => NStd.Byteops.Reference (Addr, Length));
   end Reference;

   function Reference (S : String) return Str
   is
   begin
      return (Content => NStd.Byteops.Reference (S));
   end Reference;

   function Byte_Length (Self : Str) return SizeType is
   begin
      return NStd.Byteops.Length (Self.Content);
   end Byte_Length;

   function Addr (Self : Str) return System.Address is
   begin
      return NStd.Byteops.Addr (Self.Content);
   end Addr;

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
      if Byte_Length (Self) = 0 then
         C := (Null_Address, Null_Address, 0);
      else
         C.Addr := Addr (Self);
         C.Addr_Limit := Addr (Self) + Byte_Length (Self);
         C.Codepoint := NStd.Unsafe.Get_UTF8 (C.Addr);
      end if;

      return C;
   end First;

   function Next(self: Str; N: Cursor) return Cursor
   is
      pragma Suppress (All_Checks);
      pragma Unreferenced (Self);
      Result : Cursor;
   begin
      if N.Addr >= N.Addr_Limit then
         Result := (Null_Address, Null_Address, 0);
      else
         Result.Addr := N.Addr;
         Result.Addr_Limit := N.Addr_Limit;
         Result.Codepoint := NStd.Unsafe.Get_UTF8 (Result.Addr);
      end if;
      return Result;
   end Next;

   function Has_Element (Self: Str; n: Cursor) return Boolean
   is
      pragma Suppress (All_Checks);
      pragma Unreferenced (Self);
   begin
      return N.Addr /= Null_Address;
   end Has_Element;

   function Unsafe_get(self: Str; n: Cursor) return Uint32
   is
      pragma Suppress(All_Checks);
      pragma Unreferenced (Self);
   begin
      return N.CodePoint;
   end unsafe_get;

   function Slice (Self : Str; First, Last : SizeType) return Str
   is
   begin
      return (Content => NStd.Byteops.Slice (Self.Content, First, Last));
   end;

   function Hex (Self : Str) return String is
   begin
      return NStd.Byteops.Hex (Self.Content);
   end Hex;

   function "=" (Left, Right : Str) return Boolean is
      use all type NStd.Byteops.Bytes;
   begin
      return Left.Content = Right.Content;
   end "=";

   function "=" (Left : Str; Right : String) return Boolean is
      use all type NStd.Byteops.Bytes;
   begin
      return Left.Content = Right;
   end "=";

end NStd.StrOps;
