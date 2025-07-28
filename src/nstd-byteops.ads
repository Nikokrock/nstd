--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with Ada.Strings.Unbounded;
with System;
with NStd.Lifecycle;

package NStd.ByteOps is

   --  Bytes is an efficient non-mutable container that manage a contiguous
   --  array of bytes.
   type Bytes is private
   with Iterable => (First       => First,
                     Next        => Next,
                     Has_Element => Has_Element,
                     Element     => Unsafe_Get);
   Empty_Bytes : constant Bytes;

   type Cursor is private;
   --  Cursor for Bytes and MutableBytes

   type Line_Iterator is private
   with Iterable => (First       => First_Line,
                     Next        => Next_Line,
                     Has_Element => Has_Line,
                     Element     => Unsafe_Get_Line);

   type Line_Cursor is private;
   --  Wrapper around bytes that allows iteration on lines

   Not_Found : constant SizeType := SizeType'Last;

   function Init (Str: String) return Bytes;
   procedure Init (Self: in out Bytes; str: String);
   -- Initialize a bytes object from an Ada string

   function Init
      (str: Ada.Strings.Unbounded.Unbounded_String)
      return Bytes;
   procedure Init
      (self: in out Bytes; str: Ada.Strings.Unbounded.Unbounded_String);
   --  Initialize a bytes object from an Ada Unbounded_String

   function Init (Addr : System.Address; Length : SizeType) return Bytes;
   --  Initialize from a memory region. The function assume that management
   --  of the memory region is delegated to the Bytes type (i.e: deallocation).

   function Clone (Self : Bytes) return Bytes;
   --  Clone Bytes (including content). If regular assignment is used only a
   --  reference is created.
   --  Note: In multi-tasking environment it might be a good idea to clone
   --  strings when passing data from a task to another in order to avoid
   --  contention issues due to reference counting.

   function Length (Self : Bytes) return SizeType
   with Inline => True;
   --  Return the length in bytes of Self.

   function Starts_With (Self : Bytes; Prefix : Bytes) return Boolean
   with Inline => True;

   function Starts_With (Self : Bytes; Prefix : String) return Boolean
   with Inline => True; 
   --  Return True if Self starts with Prefix

   function Ends_With (Self : Bytes; Suffix : Bytes) return Boolean
   with Inline => True;

   function Ends_With (Self : Bytes; Suffix : String) return Boolean
   with Inline => True;
   --  Return True if Self ends with Suffix

   function Slice (Self : Bytes; First, Last : SizeType) return Bytes;
   --  function Head (Self : Bytes; Size : SizeType) return Bytes;
   --  function Tail (Self : Bytes; Size : SizeType) return Bytes;
   --  Create a slice object. Last refers to the first element not part of
   --  of the slice

   function Trim (Self : Bytes) return Bytes;
   --  Trim leading and trailing ASCII whitespaces.

   function Trim_Leading (Self : Bytes) return Bytes;
   --  Trim leading ASCII whitespaces.

   function Trim_Trailing (Self : Bytes) return Bytes;
   --  Trim trailing ASCII whitespaces.

   function "=" (Left, Right : Bytes) return Boolean;
   function "=" (Left : Bytes; Right : String) return Boolean;
   -- Implement equal operator

   function Find
      (Self : Bytes; B : Byte; Index : SizeType := 0) return SizeType
   with Inline => True;

   function Find
      (Self : Bytes; Pattern : Bytes; Index : SizeType := 0) return SizeType;

   function Count
      (Self: Bytes; B : Byte; Index : SizeType := 0) return SizeType;

   function Get (Self : Bytes; Index : SizeType) return Byte
   with Inline => True;

   function Get_Char (Self : Bytes; Index : SizeType) return Character
   with Inline => True;

   function Unsafe_Get (Self : Bytes; Index : SizeType) return Byte
   with Inline => True;

   --------------------------
   -- Operations on Cursor --
   --------------------------

   function First (Self: Bytes) return Cursor
   with Inline => True;

   function Unsafe_Get (Self : Bytes; C : Cursor) return Byte
   with Inline_Always => True;

   function Next (Self : Bytes; C : Cursor) return Cursor
   with Inline_Always => True;

   function Has_Element (Self : Bytes; C : Cursor) return Boolean
   with Inline_Always => True;

   function UTF8_Next (Self : Bytes; C : Cursor) return Cursor
   with Inline => True;

   function UTF8_Get (Self : Bytes; C : in out Cursor) return UInt32
   with Inline_Always => True;

   -------------------
   -- Line Iterator --
   -------------------

   function Lines (Self : Bytes) return Line_Iterator;

   function First_Line (Self : Line_Iterator) return Line_Cursor;

   function Unsafe_Get_Line (Self : Line_Iterator; C : Line_Cursor) return Bytes;

   function Next_Line (Self : Line_Iterator; C : Line_Cursor) return Line_Cursor;

   function Has_Line (Self : Line_Iterator; C : Line_Cursor) return Boolean;

private

   type Bytes is record
      -- a bytes with offset set to 1 and length to 0 is used to marked an
      -- unitialized Bytes
      Length       : SizeType       := 0;
      Content      : NStd.Lifecycle.Refcounted_Address;
   end record;
   for Bytes'Alignment use Standard'Maximum_Alignment;

   Empty_Bytes : constant Bytes := (0, NStd.Lifecycle.Empty_Refcounted_Address);

   type Cursor is new SizeType;

   type Line_Cursor is record
      First : SizeType := 0;
      Last  : SizeType := 0;
   end record;

   type Line_Iterator is record
      Content : Bytes;
   end record;
end NStd.ByteOps;
