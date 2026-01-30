--  Copyright (C) 2025, AdaCore
--  Copyright (C) 2025, Nicolas Roche
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-Exception
--

--  Documentation Label: bytes
--
--  Package to manage contiguous array of bytes.

with System; use System;
with Ada.Strings.Unbounded;
with NStd.Lifecycle;

package NStd.ByteOps is

   type Bytes is private
   with Iterable => (First       => First,
                     Next        => Next,
                     Has_Element => Has_Element,
                     Element     => Unsafe_Get);
   --  Bytes is an efficient non-mutable container that manage a contiguous
   --  array of bytes. Assignments and slices share the same data as the
   --  original object (no data copy).
   --
   --  Note that for the sake of compatibility with other languages, the indexes
   --  for a Bytes object B are taken in the range 0 .. Len (B) - 1
   --
   --  Functions dealing with slices use exclusive ranges (i.e include the
   --  lower bound but exclude the upper bound). Some languages do provide
   --  syntax for inclusive ranges (Rust, Ruby), but most languages (e.g., Go,
   --  Python, JavaScript, Rust) default to exclusive ranges.

   Empty_Bytes : constant Bytes;
   --  Represents a constant empty Bytes container, initialized with no data.

   type Cursor is private;
   --  The Cursor type represents a position within a Bytes container and is
   --  used to iterate over or index into the byte array efficiently. It enables
   --  safe traversal and access to elements, supporting both standard and UTF-8
   --  aware iteration patterns. Cursors are typically obtained via the First
   --  function and advanced using Next or UTF8_Next, and are checked for
   --  validity with Has_Element.

   Not_Found : constant SizeType := SizeType'Last;

   ------------------
   -- Constructors --
   ------------------

   function Clone (Self : Bytes) return Bytes;
   function Clone (Str : String) return Bytes;
   function Clone (Str : Ada.Strings.Unbounded.Unbounded_String) return Bytes;
   --  Initialize a Bytes object from Bytes, String, or
   --  Ada.Strings.Unbounded.Unbounded_String
   --
   --  Clone always performs a deep copy of the data, ensuring the new Bytes
   --  object owns its own memory. In contrast, assignment or slicing operations
   --  share data with the original object. In some contexts, such as
   --  multitasking, users may want to ensure that data is fully copied using
   --  the Clone operation rather than regular assignment.

   function "+" (Str : Bytes) return Bytes renames Clone;
   function "+" (Str : String) return Bytes renames Clone;
   function "+" (Str : Ada.Strings.Unbounded.Unbounded_String) return Bytes
   renames Clone;
   --  Equivalent of Clone using a unary operator; unlike assignment or slicing,
   --  this performs a deep copy of the data, ensuring memory ownership and
   --  thread safety. Syntax example: My_Str := +"data to import"

   function Acquire (Addr : System.Address; Length : SizeType) return Bytes;
   --  Initialize from a memory region. The function assumes that ownership and
   --  management of the memory region, including freeing it when no longer
   --  needed, is delegated to the Bytes container.
   --
   --  WARNING: After calling Acquire, the caller must not free, mutate, or
   --  reference the memory region at Addr. Violating this requirement will
   --  result in undefined behavior or program errors, as the Bytes container
   --  expects exclusive control and lifetime management of the memory block.

   function Reference
      (Addr : System.Address; Length : SizeType) return Bytes;
   --  Make a reference to a memory region that is not managed by the Bytes
   --  container. Note that contrary to other Bytes objects, an assignment or
   --  slicing will cause the reference data to be copied.
   --
   --  The caller is responsible for ensuring that the referenced memory region
   --  remains valid and unmodified for the lifetime of the Bytes object.
   --  Mutating or freeing the memory while it is referenced by the Bytes object
   --  will result in undefined behavior or program errors.

   function Reference (Str : String) return Bytes;
   --  Make a reference to an Ada String. Note that contrary to other Bytes
   --  objects, an assignment or slicing will cause the reference data to be
   --  copied. The main usage is using Ada Strings as parameter of functions
   --  taking Bytes without need for a copy.
   --
   --  The caller is responsible for ensuring that the referenced memory region
   --  remains valid and unmodified for the lifetime of the Bytes object.
   --  Mutating or freeing the memory while it is referenced by the Bytes object
   --  will result in undefined behavior or program errors.

   function Parse_C_Literal (Str : String) return Bytes;
   --  Parse a string interpreting C-style escape sequences.
   --
   --  The following escape sequences are supported:
   --
   --     \a    0x07  Alert
   --     \b    0x08  Backspace
   --     \e    0x1B  Escape
   --     \f    0x0C  Formfeed
   --     \n    0x0A  Newline
   --     \r    0x0D  Carriage Return
   --     \t    0x09  Horizontal Tab
   --     \v    0x0B  Vertical Tab
   --     \\    0x5C  Backslash
   --     \'    0x27  Apostrophe/Single quotation mark
   --     \"    0x22  Double quotation mark
   --     \?    0x3F  Question mark
   --     \xhh  0xhh  Byte whose numerical hexadecimal value is hh (both lower
   --                 and upper case digits are supported)

   function "*" (Pattern : Bytes; N : SizeType) return Bytes;
   --  Repeat a pattern N times.
   --
   --  If N is 0 or the Pattern is empty the result is an empty Bytes object.

   function Length (Self : Bytes) return SizeType
   with Inline_Always => True;
   --  Return the number of bytes in Self.

   function Addr (Self : Bytes) return System.Address
   with Inline_Always => True;
   --  Return the address of the data held by Bytes.
   --
   --  The associated memory region should not be mutated, as Bytes is designed
   --  as a non-mutable container. Mutating the memory region may lead to
   --  undefined behavior or program errors. The main use of this function is to
   --  interface with C functions expecting char * buffers.

   function Starts_With (Self : Bytes; Prefix : Bytes) return Boolean
   with Inline => True;
   function Starts_With (Self : Bytes; Prefix : String) return Boolean
   with Inline => True;
   --  Return whether Self starts with Prefix.
   --
   --  If Prefix is empty, the result is always True.
   --  If Prefix is longer than Self, the result is always False.

   function Ends_With (Self : Bytes; Suffix : Bytes) return Boolean
   with Inline => True;
   function Ends_With (Self : Bytes; Suffix : String) return Boolean
   with Inline => True;
   --  Return whether Self ends with Suffix.
   --
   --  If Suffix is empty, the result is always True.
   --  If Suffix is longer than Self, the result is always False.

   function Slice (Self : Bytes; First, Last : SizeType) return Bytes
   with Inline => True;
   --  Return a Slice of Self that starts at First and ends at the byte
   --  preceeding Last (thus following convention used by most other languages).
   --  For example, Slice (S, 0, Length (S)) returns all bytes from index 0 up
   --  to but not including Length (S) (i.e: the result is equal to S).
   --
   --  The function also accepts negative values for First and Last (as in
   --  languages such as Python). In that case, the offset is calculated as:
   --  Length (S) + First and Length (S) + Last, respectively.
   --
   --  The function never raises an exception in case one of the lower or
   --  the upper bound of the original object is exceeded. In that case the
   --  bounds are adjusted to fit within the valid range of the original object.
   --  As a consequence, The function may return a Bytes object smaller than the
   --  requested range if bounds are exceeded.

   function Head (Self : Bytes; N : SizeType) return Bytes
   with Inline_Always => True;
   --  Return a Bytes object containing the N first bytes of Self. As for Slice,
   --  the underlying data is not copied; the returned slice shares memory with
   --  the original object and remains non-mutable, ensuring thread-safety.
   --
   --  The function is equivalent to Slice (Self, 0, N). As such, negative
   --  values for N are interpreted as Length (Self) + N.

   function Tail (Self : Bytes; N : SizeType) return Bytes
   with Inline_Always => True;
   --  Return a Bytes object containing the N last bytes of Self. As for Slice,
   --  the underlying data is not copied; the returned slice shares memory with
   --  the original object and remains non-mutable, ensuring thread-safety.
   --
   --  The function is equivalent to
   --  Slice (Self, Length (Self) - N, Length (Self)). As such, negative
   --  values for N are interpreted as Length (Self) + N. So in that case the
   --  function can be interpreted as all the bytes of Self starting from index
   --  -N.

   function Trim (Self : Bytes) return Bytes;
   --  Return a new Bytes object where leading and trailing ASCII whitespaces
   --  from Self are trimmed. This is considered as a Slice operation. So no
   --  copy of the data is performed.

   function Trim_Leading (Self : Bytes) return Bytes;
   --  Return a new Bytes object where leading ASCII whitespaces from Self are
   --  trimmed. This is considered as a Slice operation. So no copy of the data
   --  is performed.

   function Trim_Trailing (Self : Bytes) return Bytes;
   --  Return a new Bytes object where trailing ASCII whitespaces from Self are
   --  trimmed. This is considered as a Slice operation. So no copy of the data
   --  is performed.

   function "=" (Left, Right : Bytes) return Boolean;
   function "=" (Left : Bytes; Right : String) return Boolean;
   --  Return True if the data managed by Left and Right is equal.
   --
   --  For the overload with Bytes and String, equality is determined by
   --  comparing the length and byte values of both; no implicit conversions or
   --  normalization (such as encoding changes or whitespace trimming) are
   --  performed.

   function Find (Self : Bytes; B : Byte; Index : SizeType := 0) return SizeType
   with Inline => True;
   --  Find a byte B in Self at a position greater than or equal to Index. If
   --  B is found then the function returns the associated Index. Otherwise, the
   --  function returns the special value Not_Found.

   function Find
      (Self : Bytes; Pattern : Bytes; Index : SizeType := 0) return SizeType;
   --  Find the Pattern in Self at a position greater than or equal to Index. If
   --  Pattern is found then the function returns the associated Index.
   --  Otherwise, the function returns the special value Not_Found.

   function Count
      (Self: Bytes; B : Byte; Index : SizeType := 0) return SizeType;
   --  Return the number of times B is found in Self at a position greater than
   --  or equal to Index.

   function Get (Self : Bytes; Index : SizeType) return Byte
   with Inline => True;
   --  Return byte value of Self at position Index.
   --  If Index is out of bounds, Constraint_Error is raised.

   function Get_Char (Self : Bytes; Index : SizeType) return Character
   with Inline => True;
   --  Return byte value of Self at position Index as an Ada Character.
   --  If Index is out of bounds, Constraint_Error is raised.

   function Unsafe_Get (Self : Bytes; Index : SizeType) return Byte
   with Inline => True;
   --  Return byte value of Self at position Index.
   --
   --  WARNING: This function does not check if Index is within valid bounds and
   --  is unsafe. It should only be used when the caller can guarantee that
   --  Index is valid; misuse may result in undefined behavior or program
   --  errors. The main usage is to iterate on a Bytes object without the
   --  overhead of bounds checking on each iteration.

   function Concat (B1, B2 : Bytes) return Bytes;
   function "&" (B1, B2 : Bytes) return Bytes renames Concat;
   --  Concatenate two bytes object. If one of the object is empty a reference
   --  to the other one is returned. If you need to do an undefinite number of
   --  of concatenation, probably using a MutableBytes object and then
   --  converting it to Bytes is a better approach.

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

   function Slice
      (Self : Bytes; C : in out Cursor; Length : SizeType) return Bytes;

   -------------------
   -- Line Iterator --
   -------------------

   type Line_Iterator is private
   with Iterable => (First       => First_Line,
                     Next        => Next_Line,
                     Has_Element => Has_Line,
                     Element     => Unsafe_Get_Line);

   type Line_Cursor is private;
   --  Wrapper around bytes that allows iteration on lines

   function Lines (Self : Bytes) return Line_Iterator;

   function First_Line (Self : Line_Iterator) return Line_Cursor;

   function Unsafe_Get_Line (Self : Line_Iterator; C : Line_Cursor) return Bytes;

   function Next_Line (Self : Line_Iterator; C : Line_Cursor) return Line_Cursor;

   function Has_Line (Self : Line_Iterator; C : Line_Cursor) return Boolean;

   ------------------------
   -- Character Iterator --
   ------------------------

   type Character_Iterator is private
   with Iterable => (First       => First_Char,
                     Next        => Next_Char,
                     Has_Element => Has_Char,
                     Element     => Unsafe_Get_Char);

   type Character_Cursor is private;
   --  Wrapper around bytes that allows iteration on characters rather than
   --  bytes

   function Chars (Self : Bytes) return Character_Iterator;

   function First_Char (Self : Character_Iterator) return Character_Cursor;

   function Unsafe_Get_Char
      (Self : Character_Iterator; C : Character_Cursor) return Character;

   function Next_Char
      (Self : Character_Iterator; C : Character_Cursor) return Character_Cursor;

   function Has_Char
      (Self : Character_Iterator; C : Character_Cursor) return Boolean;


private

   type Bytes is record
      -- a bytes with offset set to 1 and length to 0 is used to marked an
      -- unitialized Bytes
      Content      : NStd.Lifecycle.Refcounted_Mem;
   end record;

   Empty_Bytes : constant Bytes :=
      (Content => NStd.Lifecycle.Empty_Refcounted_Mem);

   type Cursor is record
      Current : Address;
      Last    : Address;
   end record;
   --  ??? Change cursor type to an address to simplify arithmetic during
   --  loops

   type Line_Cursor is record
      First : SizeType := 0;
      Last  : SizeType := 0;
   end record;

   type Line_Iterator is record
      Content : Bytes;
   end record;

   type Character_Cursor is record
      C : Cursor;
   end record;

   type Character_Iterator is record
      Content : Bytes;
   end record;

end NStd.ByteOps;
