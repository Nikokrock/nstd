--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

with Ada.Strings.Unbounded;
with NStd.ByteOps;
with NStd.Lifecycle;

package NStd.MutableByteOps is

   type MutableBytes is limited private
   with Iterable => (First       => First,
                     Next        => Next,
                     Has_Element => Has_Element,
                     Element     => Unsafe_Get);
   type Cursor is private;

   function First (Self: MutableBytes) return Cursor
   with Inline => True;

   function Next (Self: MutableBytes; C: Cursor) return Cursor
   with Inline => True;

   function Length (Self: MutableBytes) return SizeType
   with Inline => True;

   function Has_Element (Self: MutableBytes; C : Cursor) return Boolean
   with Inline => True;

   function Unsafe_Get (Self: MutableBytes; C : Cursor) return Byte
   with Inline => True;

   function Move_To_Bytes (Self: in out MutableBytes) return NStd.ByteOps.Bytes;
   --  Move content from a MutableBytes object to a Bytes object.

   function As_String (Self: MutableBytes; First, Last: SizeType) return String;
   --  Get a slice of MutableBytes as a string. Note that tentative to create
   --  a slice of size > Integer'Last will result in a constraint error
   --  exception.

   procedure Append (Self: in out MutableBytes; Src: Byte);
   procedure Append (Self: in out MutableBytes; Src: Character);
   procedure Append (Self: in out MutableBytes; Src: NStd.ByteOps.Bytes);
   procedure Append (Self: in out MutableBytes; Src: MutableBytes);
   procedure Append (Self: in out MutableBytes; Src: String);
   procedure Append
      (Self: in out MutableBytes;
       Src:  Ada.Strings.Unbounded.Unbounded_String);
   --  Append elements to self.
   --
private

   type MutableBytes is record
      Content  : NStd.Lifecycle.Limited_Address;
      Capacity : SizeType := 0;
      Length   : SizeType := 0;
   end record;
   for MutableBytes'Alignment use Standard'Maximum_Alignment;

   type Cursor is new SizeType;
end NStd.MutableByteOps;

