--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with NStd.ByteOps;
with Ada.Strings.Unbounded;

package NStd.StrOps is

   type Str is private
   with Iterable => (First       => First,
                     Next        => Next,
                     Has_Element => Has_Element,
                     Element     => Unsafe_Get);
   type Cursor is private;

   function Init (S: String) return Str;

   function Init (S: Ada.Strings.Unbounded.Unbounded_String) return Str;

   function Clone (Self : Str) return Str
   with Inline => True;
   --  Create a complete copy (including buffer) of a Str.

   function Byte_Length (Self : Str) return SizeType;

   function Starts_With (Self : Str; Prefix : Str) return Boolean
   with Inline => True;

   function Starts_With (Self : Str; Prefix : String) return Boolean
   with Inline => True;
   --  Return True if Self starts with Prefix
   
   function Ends_With (Self : Str; Suffix : Str) return Boolean
   with Inline => True;

   function Ends_With (Self : Str; Suffix : String) return Boolean
   with Inline => True;
   --  Return True if Self ends with Prefix

   --  To Implement --
   
   --  function Slice (Self : Str; First, Last : SizeType) return Str;

   --  function Head/Tail
   --  function Count
   --  function Find/Index per codepoint and per substring
   --  function Encode (for export to Bytes)
   --  Lower, Upper, Capitalize (which semantic?)
   --  Split (We need first a good vector type for Str)
   --  Split_Lines
   --  Strip
   --  Some functions need reverse equivalent
   --  A few functions on str property: is_digit, is_ascii, is_alnum, ...

   --  function Trim_ASCII (Self : Str) return Str;
   --  Return a Str with leading and trailing ASCII whitespaces removed

   --  function Trim_Leading_ASCII (Self : Str) return Str;
   --  Return a Str with leading ASCII whitespaces removed

   --  function Trim_Trailing_ASCII (Self : Str) return Str;
   --  Return a Str with trailing ASCII whitespaces removed
 
   ------------------------------
   --  Cursor based operations --
   ------------------------------

   function First (Self: Str) return Cursor
   with Inline => True;

   function Next (Self: Str; N: Cursor) return Cursor
   with Inline => True;

   function Has_Element (Self: Str; n: Cursor) return Boolean
   with Inline => True;

   function Unsafe_Get(Self: Str; N: Cursor) return Uint32
   with Inline => True;

private
   type Str is record
      Content : NStd.ByteOps.Bytes;
   end record;
   for Str'Alignment use Standard'Maximum_Alignment;
   --  Implementation note: we avoid using directly Bytes here in order to
   --  strong penalty on finalization.

   type Cursor is record
      Offset     : NStd.ByteOps.Cursor;
      NextOffset : NStd.ByteOps.Cursor;
      CodePoint  : UInt32;
   end record;
   -- Implementation note: have the next offset ready along with the codepoint
   -- at offset remove penalty of two lookups during iteration.
end NStd.StrOps;
