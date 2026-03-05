--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with NStd.Unsafe;
with NStd.Memory;
with NStd.ASCII;
with NStd.Simdutf;
pragma Warnings(Off);
with Ada.Strings.Unbounded.Aux;
with NStd.MutableByteOps;
with NStd.Mem; use NStd.Mem;
pragma Warnings(On);

package body NStd.ByteOps is

   -- Init --

   function Clone (Str: String) return Bytes
   is
   begin
      return Result: Bytes do
         if Str'Length > 0 then
            NStd.Lifecycle.Clone_And_Start_Refcounting
               (Result.Content, Ref (Str));
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
                (Str_Access(1)'Address, SizeType (Str_Length)));
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
                  NStd.Unsafe.Copy
                     (Final_Addr,
                      Final_Addr + Allocated,
                      Final_Length - Allocated);
               end if;

               NStd.Lifecycle.Start_Refcounting
                  (Result.Content,
                   (Final_Addr, Final_Length));
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
            NStd.Lifecycle.Start_Refcounting (Result.Content, (Addr, Length));
         end if;
      end return;
   end Acquire;

   function Reference (Addr : System.Address; Length : SizeType) return Bytes
   is
   begin
      return Result : Bytes do
         if Length > 0 then
            NStd.Lifecycle.Start_Reference (Result.Content, (Addr, Length));
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
         if NStd.Lifecycle.Block (Self.Content).Length > 0 then
            NStd.Lifecycle.Clone_And_Start_Refcounting
               (Result.Content, NStd.Lifecycle.Block (Self.Content));
         end if;
      end return;
   end Clone;

   -- Length --

   function Length (Self : Bytes) return SizeType is
   begin
      return NStd.Lifecycle.Block (Self.Content).Length;
   end Length;

   -- Addr --

   function Addr (Self : Bytes) return System.Address is
   begin
      return NStd.Lifecycle.Block (Self.Content).Addr;
   end Addr;

   -- Starts_With --

   function Starts_With (Self : Bytes; Prefix : Bytes) return Boolean
   is
   begin
      return Unsafe.Starts_With
         (Self   => NStd.Lifecycle.Block (Self.Content).Addr,
          Length => NStd.Lifecycle.Block (Self.Content).Length,
          Prefix => NStd.Lifecycle.Block (Prefix.Content).Addr,
          Prefix_Length => NStd.Lifecycle.Block (Prefix.Content).Length);
   end Starts_With;

   function Starts_With (Self : Bytes; Prefix : String) return Boolean
   is
   begin
      if Prefix'Length = 0 then
         return True;
      elsif Length (Self) < Prefix'Length then
         return False;
      else
         return NStd.Memory.Memcmp
            (Dst    => Addr (Self),
             Src    => Unsafe.Reference (Prefix),
             Length => Prefix'Length) = 0;
      end if;
   end Starts_With;

   -- Ends_With --

   function Ends_With (Self : Bytes; Suffix : Bytes) return Boolean
   is
   begin
      if Length (Suffix) = 0 then
         return True;
      elsif Length (Self) < Length (Suffix) then
         return False;
      else
         return NStd.Memory.Memcmp
            (Dst    => Addr (Self) + (Length (Self) - Length (Suffix)),
             Src    => Addr (Suffix),
             Length => Length (Suffix)) = 0;
      end if;
   end Ends_With;

   function Ends_With (Self : Bytes; Suffix : String) return Boolean
   is
   begin
      if Suffix'Length = 0 then
         return True;

      elsif Length (Self) < Suffix'Length then
         return False;

      else
         return NStd.Memory.Memcmp
            (Dst    => Addr (Self) + (Length (Self) - Suffix'Length),
             Src    => Unsafe.Reference (Suffix),
             Length => Suffix'Length) = 0;
      end if;
   end Ends_With;

   function "=" (Left : Bytes; Right : Bytes) return Boolean is
   begin
      return Is_Content_Equal
         (NStd.Lifecycle.Block (Left.Content),
          NStd.Lifecycle.Block (Right.Content));
   end "=";

   function "=" (Left : Bytes; Right : String) return Boolean is
   begin
      return Unsafe.Is_Equal
         (NStd.Lifecycle.Block (Left.Content).Addr,
          Unsafe.Reference (Right),
          NStd.Lifecycle.Block (Left.Content).Length,
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
      if Length (Self) = 0 then
         return Self;
      end if;

      declare
         Start_Idx : SizeType := NStd.Lifecycle.Block (Self.Content).Length;
         End_Idx   : SizeType := NStd.Lifecycle.Block (Self.Content).Length;
      begin
         for Idx in 0 .. End_Idx - 1 loop
            if not NStd.ASCII.Is_ASCII_Whitespace (Unsafe_Get (Self, Idx)) then
               Start_Idx := Idx;
               exit;
            end if;
         end loop;

         for Idx in reverse Start_Idx + 1 .. NStd.Lifecycle.Block (Self.Content).Length loop
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
      if Length (Self) = 0 then
         return Self;
      end if;

      declare
         Start_Idx : SizeType := Length (Self);
      begin
         for Idx in 0 .. Length (Self) - 1 loop
            if not NStd.ASCII.Is_ASCII_Whitespace (Unsafe_Get (Self, Idx)) then
               Start_Idx := Idx;
               exit;
            end if;
         end loop;

         return Slice (Self, Start_Idx, Length (Self));
      end;
   end Trim_Leading;

   function Trim_Trailing (Self : Bytes) return Bytes is
   begin
      if Length (Self) = 0 then
         return Self;
      end if;

      declare
         End_Idx : SizeType := 0;
      begin
         for Idx in reverse 1 .. Length (Self) loop
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
      if Index < Length (Self) then
         return Unsafe.Get (Addr (Self), Index);
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
      return Unsafe.Get (Addr (Self), Index);
   end unsafe_get;

   function Concat (B1, B2 : Bytes) return Bytes is
   begin
      if Length (B1) = 0 then
         return B2;
      elsif Length (B2) = 0 then
         return B1;
      else
         return Result: Bytes do
            declare
               B : constant Block := Allocate (Length (B1) + Length (B2));
            begin
               NStd.Unsafe.Copy (Addr (B1), B.Addr, Length (B1));
               NStd.Unsafe.Copy (Addr (B2), B.Addr + Length (B1), Length (B2));
               NStd.Lifecycle.Start_Refcounting (Result.Content, B);
            end;
         end return;
      end if;
   end Concat;

   function First (Self: Bytes) return Cursor is
   begin
      return (Addr (Self), Addr (Self) + Length (Self));
   end First;

   function Unsafe_Get (Self : Bytes; C : Cursor) return Byte
   is
      pragma Suppress(All_Checks);
      pragma Unreferenced (Self);
   begin
      return Unsafe.Get (C.Current, 0);
   end Unsafe_Get;

   function Next (Self : Bytes; C : Cursor) return Cursor is
      pragma Suppress (All_Checks);
      pragma Unreferenced (Self);
   begin
      return (C.Current + 1, C.Last);
   end;

   function Has_Element (Self : Bytes; C : Cursor) return Boolean is
      pragma Suppress (All_Checks);
      pragma Unreferenced (Self);
   begin
      return C.Current < C.Last;
   end Has_Element;

   function Slice
      (Self : Bytes; C : in out Cursor; Length : SizeType) return Bytes is
   begin
      return Slice
         (Self, C.Current - Addr (Self), C.Current - Addr (Self) + Length);
   end Slice;

   function Unsafe_Get_UInt64 (Self : Bytes; C : in out Cursor) return UInt64
   is
      pragma Unreferenced (Self);
      Result : UInt64;
      for Result'Address use C.Current;
   begin
      C.Current := C.Current + 8;
      return Result;
   end Unsafe_Get_UInt64;

   function Unsafe_Get_UInt32 (Self : Bytes; C : in out Cursor) return UInt32
   is
      pragma Unreferenced (Self);
      Result : UInt32;
      for Result'Address use C.Current;
   begin
      C.Current := C.Current + 4;
      return Result;
   end Unsafe_Get_UInt32;

   -- Find --

   function Find (Self : Bytes; B : Byte) return SizeType
   is
      pragma Suppress(All_Checks);

      function Internal_Find
         (C_Start : Address;
          C_End   : Address;
          B       : Byte) return Address
      with Import        => True,
           Convention    => CPP,
           External_Name => "_ZN7simdutf4findEPKcS1_c";

   begin
      if Length (Self) = 0 then
         return NOT_FOUND;
      end if;

      declare
         Result_Address : constant Address :=
           Internal_Find (Addr (Self), Addr (Self) + Length (Self), B);
         Result_Offset : constant SizeType := Result_Address - Addr (Self);

      begin
         if Result_Offset >= Length (Self) then
            return NOT_FOUND;
         else
            return Result_Offset;
         end if;
      end;
   end Find;

   function Find (Self : Bytes; B : Byte; First : SizeType) return SizeType
   is
      pragma Suppress(All_Checks);

      function Internal
         (C_Start : Address;
          C_End   : Address;
          B       : Byte) return Address
      with Import        => True,
           Convention    => CPP,
           External_Name => "_ZN7simdutf4findEPKcS1_c";

   begin
      if First < 0 or else First >= Length (Self) then
         return NOT_FOUND;
      end if;

      declare
         Start_Addr : constant Address := Addr (Self) + First;
         End_Addr : constant Address := Addr (Self) + Length (Self);
         Result_Addr : constant Address := Internal (Start_Addr, End_Addr, B);
         Result_Offset : constant SizeType := Result_Addr - Addr (Self);

      begin
         if Result_Offset >= Length (Self) then
            return NOT_FOUND;
         else
            return Result_Offset;
         end if;
      end;
   end Find;

   function Find (Self : Bytes; C : Character) return SizeType is
   begin
      return Find (Self, As_Byte (C));
   end Find;

   function Find
     (Self : Bytes; C : Character; First : SizeType)
      return SizeType
   is
   begin
      return Find (Self, As_Byte (C), First);
   end Find;

   -- RFind --

   function RFind (Self : Bytes; B : Byte) return SizeType
   is
      pragma Suppress(All_Checks);

      function memrchr
         (Haystack : Address;
          Needle   : Byte;
          H_Length : SizeType) return Address
      with Import        => True,
           Convention    => C,
           External_Name => "memrchr";

   begin
      if Length (Self) = 0 then
         return NOT_FOUND;
      end if;

      declare
         Result_Addr : constant Address := memrchr
           (Addr (Self), B, Length (Self));
      begin
         if Result_Addr = Null_Address then
            return NOT_FOUND;
         else
            return Result_Addr - Addr (Self);
         end if;
      end;
   end RFind;

   function RFind (Self : Bytes; B : Byte; Last : SizeType) return SizeType
   is
      pragma Suppress(All_Checks);

      function memrchr
         (Haystack : Address;
          Needle   : Byte;
          H_Length : SizeType) return Address
      with Import        => True,
           Convention    => C,
           External_Name => "memrchr";

   begin
      if Last > Length (Self) or else Last <= 0 then
         return NOT_FOUND;
      end if;

      declare

         Result_Addr : constant Address := memrchr (Addr (Self), B, Last);
      begin
         if Result_Addr = Null_Address then
            return NOT_FOUND;
         else
            return Result_Addr - Addr (Self);
         end if;
      end;
   end RFind;
   -- Find --

   function Find (Self : Bytes; Pattern : Bytes) return SizeType
   is
      function sz_find
         (Haystack : Address;
	       H_Length : SizeType;
	       Needle   : Address;
	       N_Length : SizeType)
         return Address;
      pragma Import (C, sz_find, "sz_find");

   begin
      if Length (Pattern) = 0 then
         return 0;

      elsif Length (Self) < Length (Pattern) then
         return NOT_FOUND;

      else
         declare
            Result_Addr : constant Address := sz_find
               (Addr (Self), Length (Self), Addr (Pattern), Length (Pattern));
         begin
            if Result_Addr = Null_Address then
               return NOT_FOUND;
            else
               return Result_Addr - Addr (Self);
            end if;
         end;
      end if;
   end Find;

   -- RFind --

   function RFind (Self : Bytes; Pattern : Bytes) return SizeType
   is

      function sz_find
         (Haystack : Address;
	       H_Length : SizeType;
	       Needle   : Address;
	       N_Length : SizeType)
         return Address;
      pragma Import (C, sz_find, "sz_rfind");

   begin
      if Length (Pattern) = 0 then
         return 0;
      elsif Length (Self) < Length (Pattern) then
         return NOT_FOUND;
      else
         declare
            Result_Addr : constant Address := sz_find
               (Addr (Self), Length (Self), Addr (Pattern), Length (Pattern));
         begin
            if Result_Addr = Null_Address then
               return NOT_FOUND;
            else
               return Result_Addr - Addr (Self);
            end if;
         end;
      end if;
   end RFind;

   function Count (Self: Bytes; B: Byte; Index: SizeType := 0) return SizeType
   is
      Result  : SizeType := 0;
      Cindex  : SizeType := Index;
   begin
      if Length (Self) = 0 then
         return 0;
      else
         while Cindex < Length (Self) loop
            Cindex := Find (Self, B => B, First => Cindex);
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
            Result.Last := Length (Self.Content);
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
            Result.Last := Length (Self.Content);
         end if;
      end return;
   end Next_Line;

   function Has_Line (Self : Line_Iterator; C : Line_Cursor) return Boolean is
   begin
      return C.First < Length (Self.Content);
   end Has_Line;

   -- Chars --

   function Chars (Self : Bytes) return Character_Iterator is
   begin
      return (Content => Self);
   end Chars;

   -- First_Char --

   function First_Char (Self : Character_Iterator) return Character_Cursor
   is
   begin
      return (C => First (Self.Content));
   end First_Char;

   -- Unsafe_Get_Char --

   function Unsafe_Get_Char
      (Self : Character_Iterator; C : Character_Cursor) return Character
   is
   begin
      return as_char (Unsafe_Get (Self.Content, C => C.C));
   end Unsafe_Get_Char;

   -- Next_Char --

   function Next_Char
      (Self : Character_Iterator; C : Character_Cursor) return Character_Cursor
   is
   begin
      return (C => Next (Self.Content, C.C));
   end Next_Char;

   -- Has_Char --

   function Has_Char
      (Self : Character_Iterator; C : Character_Cursor) return Boolean
   is
   begin
      return Has_Element (Self.Content, C.C);
   end Has_Char;

   function Hex (Self : Bytes) return String is
      S : String (1 .. Integer (Length (Self) * 3));
   begin
      for I in 0 .. Length (Self) - 1 loop
         S (Integer (I * 3) + 1) := ' ';
         S (Integer (I * 3 + 2) .. Integer (I * 3 + 3)) :=
            Hex (Unsafe_Get (Self, I));
      end loop;

      return S;
   end Hex;

   -- Validate_UTF8 --

   function Validate_UTF8 (Self : Bytes) return Boolean is
   begin
      return NStd.Simdutf.Validate_UTF8
        (Buf => Addr (Self), Len => Length (Self));
   end Validate_UTF8;

end NStd.ByteOps;
