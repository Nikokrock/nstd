--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with NStd.Unsafe;
with NStd.Memory;
with NStd.ASCII;
pragma Warnings(Off);
with Ada.Strings.Unbounded.Aux;
with NStd.MutableByteOps;
pragma Warnings(On);

package body NStd.ByteOps is

   function memchr(self: Bytes; b: Byte; index: SizeType:=0) return SizeType;
   -- Binding to memchr C function. If a character is not found then
   -- SizeType'Last is returned.

   -- Init --

   function Clone (Str: String) return Bytes
   is
   begin
      return Result: Bytes do
         if Str'Length > 0 then
            NStd.Lifecycle.Clone_And_Start_Refcounting
               (Result.Content, Unsafe.Reference (Str), Str'Length);
         end if;
      end return;
   end Clone;

   function Clone
      (Str: Ada.Strings.Unbounded.Unbounded_String)
      return Bytes
   is
      use Ada.Strings.Unbounded.Aux;
      Str_Length: Natural;
      Str_Access: Big_String_Access;
   begin
      return Result: Bytes do
         Get_String (Str, Str_Access, Str_Length);
         if Str_Length > 0 then
            NStd.Lifecycle.Clone_And_Start_Refcounting
               (Result.Content,
                Str_Access(1)'Address,
                SizeType (Str_Length));
         end if;
      end return;
   end Clone;

   -- * --

   function "*" (Pattern : Bytes; N : SizeType) return Bytes
   is
   begin
      --  Check that condition ???
      if N > 0 and then Length (Pattern) >= SizeType'Last / N then
         raise Constraint_Error with "string too big";
      end if;

      return Result: Bytes do
         declare
            Final_Length : constant SizeType := Length (Pattern) * N;
            Final_Addr : System.Address;
            Allocated : SizeType := 0;

         begin
            if Final_Length > 0 then
               Final_Addr := NStd.Unsafe.Allocate (Final_Length);
               NStd.Unsafe.Copy (Addr (Pattern), Final_Addr, Length (Pattern));
               Allocated := Length (Pattern);

               while Allocated <= Final_Length / 2 loop
                  NStd.Unsafe.Copy (Final_Addr, Final_Addr + Allocated, Allocated);
                  Allocated := Allocated * 2;
               end loop;

               if Allocated < Final_Length then
                  NStd.Unsafe.Copy (Final_Addr, Final_Addr + Allocated, Final_Length - Allocated);
               end if;

               NStd.Lifecycle.Start_Refcounting
                  (Result.Content,
                   Final_Addr,
                   Final_Length);
            end if;
         end;

      end return;
   end "*";

   -- Parse_C_Literal --

   function Parse_C_Literal (Str : String) return Bytes is
      use NStd.MutableByteOps;
      Buffer : MutableBytes;
      Idx    : Integer := Str'First;
   begin
      loop
         exit when Idx > Str'Last;

         if Str (Idx) = '\' then
            Idx := Idx + 1;

            if Idx > Str'Last then
               raise Constraint_Error with "invalid pattern";
            end if;

            case Str (Idx) is
               when 'a' => Append (Buffer, NStd.ASCII.BEL);
               when 'b' => Append (Buffer, NStd.ASCII.BS);
               when 'e' => Append (Buffer, NStd.ASCII.ESC);
               when 'f' => Append (Buffer, NStd.ASCII.FF);
               when 'n' => Append (Buffer, NStd.ASCII.LF);
               when 'r' => Append (Buffer, NStd.ASCII.CR);
               when 't' => Append (Buffer, NStd.ASCII.HT);
               when 'v' => Append (Buffer, NStd.ASCII.VT);
               when '\' => Append (Buffer, NStd.ASCII.Backslash);
               when ''' => Append (Buffer, NStd.ASCII.Apostrophe);
               when '"' => Append (Buffer, NStd.ASCII.Quotation_Mark);
               when '?' => Append (Buffer, NStd.ASCII.Question_Mark);
               when 'x' =>
                  if Idx + 2 > Str'Last then
                     raise Constraint_Error;
                  end if;

                  declare
                     High_Char : constant Byte := NStd.As_Byte (Str (Idx + 1));
                     Low_Char  : constant Byte := NStd.As_Byte (Str (Idx + 2));
                     High, Low : Byte := 0;
                  begin

                     High := NStd.ASCII.Hex_To_Byte (High_Char);
                     if High = NStd.ASCII.Hex_To_Byte_Error then
                        raise Constraint_Error;
                     end if;

                     Low := NStd.ASCII.Hex_To_Byte (Low_Char);
                     if Low = NStd.ASCII.Hex_To_Byte_Error then
                        raise Constraint_Error;
                     end if;

                     Idx := Idx + 2;
                     Append (Buffer, High * 16 + Low);
                  end;
               when others =>
                  raise Constraint_Error;
            end case;
         else
            Append (Buffer, Str (Idx));
         end if;

         Idx := Idx + 1;
      end loop;

      return Move_To_Bytes (Buffer);
   end Parse_C_Literal;

   function Acquire (Addr : System.Address; Length : SizeType) return Bytes is
   begin
      return Result : Bytes do
         if Length > 0 then
            NStd.Lifecycle.Start_Refcounting (Result.Content, Addr, Length);
         end if;
      end return;
   end Acquire;

   function Reference (Addr : System.Address; Length : SizeType) return Bytes
   is
   begin
      return Result : Bytes do
         if Length > 0 then
            NStd.Lifecycle.Start_Reference (Result.Content, Addr, Length);
         end if;
      end return;
   end Reference;

   function Reference (Str : String) return Bytes is
   begin
      if Str'Length > 0 then
         return Reference (Str (Str'First)'Address, SizeType (Str'Length));
      else
         declare
            Result : Bytes;
         begin
            return Result;
         end;
      end if;
   end Reference;

   -- Clone --

   function Clone (Self : Bytes) return Bytes
   is
   begin
      return Result: Bytes do
         if NStd.Lifecycle.Length (Self.Content) > 0 then
            NStd.Lifecycle.Clone_And_Start_Refcounting
               (Result.Content,
                NStd.Lifecycle.Addr (Self.Content),
                NStd.Lifecycle.Length (Self.Content));
         end if;
      end return;
   end Clone;

   -- Length --

   function Length (Self : Bytes) return SizeType is
   begin
      return NStd.Lifecycle.Length (Self.Content);
   end Length;

   function Addr (Self : Bytes) return System.Address is
   begin
      return NStd.Lifecycle.Addr (Self.Content);
   end Addr;

   -- Starts_With --

   function Starts_With (Self : Bytes; Prefix : Bytes) return Boolean
   is
   begin
      return Unsafe.Starts_With
         (Self   => NStd.Lifecycle.Addr (Self.Content),
          Length => NStd.Lifecycle.Length (Self.Content),
          Prefix => NStd.Lifecycle.Addr (Prefix.Content),
          Prefix_Length => NStd.Lifecycle.Length (Prefix.Content));
   end Starts_With;

   function Starts_With (Self : Bytes; Prefix : String) return Boolean
   is
   begin
      if Prefix'Length = 0 then
         return True;
      elsif NStd.Lifecycle.Length (Self.Content) < Prefix'Length then
         return False;
      else
         return NStd.Memory.Memcmp
            (Dst    => NStd.Lifecycle.Addr (Self.Content),
             Src    => Unsafe.Reference (Prefix),
             Length => Prefix'Length) = 0;
      end if;
   end Starts_With;

   -- Ends_With --

   function Ends_With (Self : Bytes; Suffix : Bytes) return Boolean
   is
   begin
      if NStd.Lifecycle.Length (Suffix.Content) = 0 then
         return True;
      elsif NStd.Lifecycle.Length (Self.Content) < NStd.Lifecycle.Length (Suffix.Content) then
         return False;
      else
         return NStd.Memory.Memcmp
            (Dst    => Unsafe.Addr
               (NStd.Lifecycle.Addr (Self.Content),
                NStd.Lifecycle.Length (Self.Content) - NStd.Lifecycle.Length (Suffix.Content)),
             Src    => NStd.Lifecycle.Addr (Suffix.Content),
             Length => NStd.Lifecycle.Length (Suffix.Content)) = 0;
      end if;
   end Ends_With;

   function Ends_With (Self : Bytes; Suffix : String) return Boolean
   is
   begin
      if Suffix'Length = 0 then
         return True;
      elsif NStd.Lifecycle.Length (Self.Content) < Suffix'Length then
         return False;
      else
         return NStd.Memory.Memcmp
            (Dst    => Unsafe.Addr
               (NStd.Lifecycle.Addr (Self.Content),
                NStd.Lifecycle.Length (Self.Content) - Suffix'Length),
             Src    => Unsafe.Reference (Suffix),
             Length => Suffix'Length) = 0;
      end if;
   end Ends_With;

   function "=" (Left : Bytes; Right : Bytes) return Boolean is
   begin
      return Unsafe.Is_Equal
         (NStd.Lifecycle.Addr (Left.Content),
          NStd.Lifecycle.Addr (Right.Content),
          NStd.Lifecycle.Length (Left.Content),
          NStd.Lifecycle.Length (Right.Content));
   end "=";

   function "=" (Left : Bytes; Right : String) return Boolean is
   begin
      return Unsafe.Is_Equal
         (NStd.Lifecycle.Addr (Left.Content),
          Unsafe.Reference (Right),
          NStd.Lifecycle.Length (Left.Content),
          SizeType (Right'Length));
   end "=";

   function Slice (Self: Bytes; First, Last: SizeType) return Bytes is
   begin
      return result: Bytes do
         Result.content := NStd.Lifecycle.Slice (Self.Content, First, Last);
      end return;
   end Slice;

   -- Head --

   function Head (Self : Bytes; N : SizeType) return Bytes is
   begin
      return Slice (Self, First => 0, Last => N);
   end Head;

   function Tail (Self : Bytes; N : SizeType) return Bytes is
   begin
      return Slice (Self, Length (Self) - N, Length (Self));
   end Tail;
   -- Trim --

   function Trim (Self : Bytes) return Bytes is
   begin
      if NStd.Lifecycle.Length (Self.Content) = 0 then
         return Self;
      end if;

      declare
         Start_Idx : SizeType := NStd.Lifecycle.Length (Self.Content);
         End_Idx   : SizeType := NStd.Lifecycle.Length (Self.Content);
      begin
         for Idx in 0 .. End_Idx - 1 loop
            if not NStd.ASCII.Is_ASCII_Whitespace (Unsafe_Get (Self, Idx)) then
               Start_Idx := Idx;
               exit;
            end if;
         end loop;

         for Idx in reverse Start_Idx + 1 .. NStd.Lifecycle.Length (Self.Content) loop
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
      if NStd.Lifecycle.Length (Self.Content) = 0 then
         return Self;
      end if;

      declare
         Start_Idx : SizeType := NStd.Lifecycle.Length (Self.Content);
      begin
         for Idx in 0 .. NStd.Lifecycle.Length (Self.Content) - 1 loop
            if not NStd.ASCII.Is_ASCII_Whitespace (Unsafe_Get (Self, Idx)) then
               Start_Idx := Idx;
               exit;
            end if;
         end loop;

         return Slice (Self, Start_Idx, NStd.Lifecycle.Length (Self.Content));
      end;
   end Trim_Leading;

   function Trim_Trailing (Self : Bytes) return Bytes is
   begin
      if NStd.Lifecycle.Length (Self.Content) = 0 then
         return Self;
      end if;

      declare
         End_Idx : SizeType := 0;
      begin
         for Idx in reverse 1 .. NStd.Lifecycle.Length (Self.Content) loop
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
      if Index < NStd.Lifecycle.Length (Self.Content) then
         return Unsafe.Get (NStd.Lifecycle.Addr (Self.Content), Index);
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
      return Unsafe.Get (NStd.Lifecycle.Addr (Self.Content), Index);
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
      return Unsafe.Get (NStd.Lifecycle.Addr (Self.Content), SizeType (C));
   end Unsafe_Get;

   function Next (Self : Bytes; C : Cursor) return Cursor is
      pragma Suppress (All_Checks);
      pragma Unreferenced (Self);
   begin
      return C + 1;
   end;

   function Has_Element (Self : Bytes; C : Cursor) return Boolean is
      pragma Suppress (All_Checks);
   begin
      return SizeType (C) < NStd.Lifecycle.Length (Self.Content);
   end Has_Element;

   function UTF8_Next (Self : Bytes; C : Cursor) return Cursor
   is
      pragma Suppress(All_Checks);
   begin
      return Cursor
         (Unsafe.Next_UTF8_Offset (NStd.Lifecycle.Addr (Self.Content), SizeType (C), NStd.Lifecycle.Length (Self.Content)));
   end UTF8_Next;

   function UTF8_Get (Self : Bytes; C : in out Cursor) return UInt32 is
   begin
      return Unsafe.Get_UTF8 (NStd.Lifecycle.Addr (Self.Content), SizeType (C), NStd.Lifecycle.Length (Self.Content));
   end UTF8_Get;

   function memchr(self: Bytes; b: Byte; index: SizeType:=0) return SizeType is

      function internal
         (addr: System.Address; i: Integer; size: SizeType) return System.Address;
      pragma Import(C, internal, "memchr");

      result: System.Address;
      use all type System.Address;
   begin
      result := internal
         (Unsafe.Addr (NStd.Lifecycle.Addr (Self.Content), index),
          Integer(b),
          NStd.Lifecycle.Length (Self.Content) - index);
      if result = System.Null_Address then
         return SizeType'Last;
      end if;

      return Unsafe.Offset (Result, NStd.Lifecycle.Addr (Self.Content));
   end memchr;

   function Find (Self : Bytes; B : Byte; Index : SizeType:=0) return SizeType
   is
      pragma Suppress(All_Checks);
   begin
      if NStd.Lifecycle.Length (Self.Content) = 0 then
         return SizeType'Last;
      else
         -- This probably deserves a modern implementation that takes advantage
         -- of SSE, Neon or other SIMD extensions. In the meantime probe using
         -- naive approach for at most 16 characters and if the byte is not
         -- found delegate to memchr which is faster when byte frequency is not
         -- too high.
         declare
            last_searched: constant SizeType := min
               (NStd.Lifecycle.Length (Self.Content) - 1, index + 16);
         begin
            -- Naive search is faster when frequency is high
            for idx in index .. last_searched loop
               if Unsafe.Get(NStd.Lifecycle.Addr (Self.Content), idx) = b then
                  return idx;
               end if;
            end loop;

            -- Character is not in the first 16, delegate to memchr based
            -- search
            if last_searched < NStd.Lifecycle.Length (Self.Content) - 1 then
               return memchr(self, b => b, index => last_searched + 1);
            else
               return Not_Found;
            end if;
         end;
      end if;
   end Find;

   function Find
      (Self : Bytes; Pattern : Bytes; Index : SizeType := 0) return SizeType
   is
   begin
      return 0;
   end Find;

   function Count (Self: Bytes; B: Byte; Index: SizeType := 0) return SizeType
   is
      Result  : SizeType := 0;
      Cindex  : SizeType := Index;
   begin
      if NStd.Lifecycle.Length (Self.Content) = 0 then
         return 0;
      else
         while Cindex < NStd.Lifecycle.Length (Self.Content) loop
            Cindex := Find (Self, B => B, Index => Cindex);
            exit when Cindex = SizeType'Last;
            Result := Result + 1;
            Cindex := Cindex + 1;
         end loop;
      end if;
      return Result;
   end Count;

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
            Result.Last := NStd.Lifecycle.Length (Self.Content.Content);
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
         Result.Last := Find (Self.Content,NStd.ASCII.LF, Result.First);
         if Result.Last = Not_Found then
            Result.Last := NStd.Lifecycle.Length (Self.Content.Content);
         end if;
      end return;
   end Next_Line;

   function Has_Line (Self : Line_Iterator; C : Line_Cursor) return Boolean is
   begin
      return C.First < NStd.Lifecycle.Length (Self.Content.Content);
   end Has_Line;
end NStd.ByteOps;
