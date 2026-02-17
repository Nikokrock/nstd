NStd.Byteops
============

The ``Bytes`` object is the underlying container of the ``Str`` type except that
no encoding is enforced or checked.

Instantiation
-------------

``Bytes`` can be instantiated from standard Ada types such as ``String`` or
``Unbounded_String`` or even from another ``Bytes`` object using the ``Clone``
function or its ``+`` shortcut:

.. code-block:: ada

    declare
        My_Bytes      : Bytes := +"Hello World";
        My_Bytes_Copy : Bytes;
    begin
        My_Bytes := Clone ("Another String");
        My_Bytes_Copy := Clone (My_Bytes);
    end;

Using Clone always create a full copy of the underlying data. On the contrary
the following code will only create reference to the original content:

.. code-block:: ada

    declare
        My_Bytes     : Bytes := +"Hello World";
        My_Bytes_Ref : Bytes;
    begin
        My_Bytes_Ref := My_Bytes;
    end;

Each function that returns a Bytes object in the API always explicity document
whether the underlying content is copied or only referenced.

In real life application, it's not rare to interface with C library that may
allocate ``char *`` buffers. The API provides a few functions to import those
data without need for a copy:

.. code-block:: ada

    declare
        Some_Address : System.Address := Something;
        Some_Length  : NStd.SizeType  := Something_Length;
        My_Managed_Bytes   : Bytes := Acquire (Some_Address, Some_Length);
        My_Unmanaged_Bytes : Bytes := Reference (Some_Address, Some_Length);
    begin
        --  do stuff
    end;

In that example when My_Managed_Bytes is finalized, a call to ``free`` is done
to release the memory at Some_Address. Basically on object creation the Bytes
object assume the management of the memory block starting at Some_Address.

When using the Reference function, the release of the underlying memory region
is not handled by the Bytes object. This might be useful when the lifecycle of
the memory region is handled by another mechanism. Note that in the case a
Bytes object is created using the Reference method, then a subsequent assignment
to another Bytes object will cause the underlying data to be copied. The goal is
to limit the scope of that unmanaged data.

To ease interface with the standard Ada String object, a Reference method is
also available for that type. The main goal is to be able to pass without
performance cost Ada String objects to API handling only Bytes.

In addition to these basic constructors, some handy functions are provided such
as Parse_C_Literal to parse C-style escape sequences, or the multiply operator
to create a Bytes object using a repeating pattern.

Indexing and Slicing
--------------------

Indexing in Bytes object differs from String object in various ways

1. Index lower bounds is always 0
2. Index type is related to the architecture (64 bits or 32 bits). This means
   that a Bytes object can be larger than 2GB on 64 bits platforms. The exact
   limitation is ``2^63 - 2`` and ``2^32 - 2`` respectively.

Accessing the bytes of a Bytes object can be done using the safe
functions Get or Get_Char. In that case a Constraint_Error is raised if the
user query an element out of bounds. An Unsafe_Get function in which no checks
is performed is also provided. The main goal of this function is to implement
efficiently algorithms that iterate on the Bytes object. In that case the check
can often be discarded as the algorithm will ensure by construction that
only valid indexes will be used. Not using that **unsafe** function in those
cases introduce a strong performance penalty.

.. code-block:: ada

    declare
        My_Bytes : Bytes := +"abcedef";
        Counter  : SizeType := 0;
    begin
        for Idx in 0 .. Length (My_Bytes) - 1 loop
            if Get (My_Bytes) = 16#61# then
               Counter := Counter + 1;
            end if;
        end loop;
    end;

In the previous example, the code does in fact twice the bound check. Once for
the loop and once during ``Get`` call. Using the Unsafe method ensures the
checks is done once only.

The default Bytes iterator use the Unsafe_Get function and provides an efficient
and nice way to iterate on a Bytes object:

.. code-block:: ada

    declare
        My_Bytes : Bytes := +"abcedef";
        Counter  : SizeType := 0;
    begin
        for B of My_Bytes loop
            if B = 16#61# then
               Counter := Counter + 1;
            end if;
        end loop;
    end;

In order to get a slice of a Bytes object the API provides various functions.
The most general one is the Slice function. The function does not cause a copy
of the data. Providing that Bytes objects are immutable there is no aliasing
issue. The semantic of bounds passed to the Slice function is highly inspired on
the Python semantic: lower bound is included and higher bound is excluded.
Also negative bounds are interpreted as Length (Byte_Object) + Bound:

.. code-block:: ada

    declare
        Full : Bytes := +"0123456789";
        Sub  : Bytes;
    begin
        Sub := Slice (Full, 0, Length (Full));
        assert Sub = Full;
        assert Sub = "0123456789";

        Sub := Slice (Full, 0, 2);
        assert Sub = "01";

        Sub := Slice (Full, 1, 3);
        assert Sub = "12";

        --  Objects bounds are starting at 0 even when a slice is created.
        Sub := Slice (Sub, 0, 1);
        assert Sub = "1";

        Sub := Slice (Full, -2, -1);
        assert Sub = "8";

    end;

Also the function will never raise a Constraint_Error. If one of the bound is
outside the object bounds then the effective bound is ajusted to match the
object limits:

.. code-block:: ada

    declare
        Full : Bytes := +"0123456789";
        Sub  : Bytes;
    begin
        Sub := Slice (Full, 0, 42);
        assert Sub = "0123456789";
    end;

This departs significantly from usual Ada semantics, but provides some
advantages:

1. Ease interfacing with other languages such C
2. Reduce need for ``+1`` or ``-1`` compensations

The answer answer of Guido Van Rossum (Python's creator) gives a bit more
insight:

.. admonition:: Guido Van Rossum on 0-based indexing

    I was asked on Twitter why Python uses 0-based indexing, with a link to a
    new (fascinating) post on the subject
    (http://exple.tive.org/blarg/2013/10/22/citation-needed/). I recall thinking
    about it a lot; ABC, one of Python's predecessors, used 1-based indexing,
    while C, the other big influence, used 0-based. My first few programming
    languages (Algol, Fortran, Pascal) used 1-based or variable-based. I think
    that one of the issues that helped me decide was slice notation.

    Let's first look at use cases. Probably the most common use cases for
    slicing are "get the first n items" and "get the next n items starting at i"
    (the first is a special case of that for i == the first index). It would be
    nice if both of these could be expressed as without awkward +1 or -1
    compensations.

    Using 0-based indexing, half-open intervals, and suitable defaults (as
    Python ended up having), they are beautiful: a[:n] and a[i:i+n]; the former
    is long for a[0:n].

    Using 1-based indexing, if you want a[:n] to mean the first n elements, you
    either have to use closed intervals or you can use a slice notation that
    uses start and length as the slice parameters. Using half-open intervals
    just isn't very elegant when combined with 1-based indexing. Using closed
    intervals, you'd have to write a[i:i+n-1] for the n items starting at i. So
    perhaps using the slice length would be more elegant with 1-based indexing?
    Then you could write a[i:n]. And this is in fact what ABC did -- it used a
    different notation so you could write a@i|n.
    (See http://homepages.cwi.nl/~steven/abc/qr.html#EXPRESSIONS.)

    But how does the index:length convention work out for other use cases? TBH
    this is where my memory gets fuzzy, but I think I was swayed by the elegance
    of half-open intervals. Especially the invariant that when two slices are
    adjacent, the first slice's end index is the second slice's start index is
    just too beautiful to ignore. For example, suppose you split a string into
    three parts at indices i and j -- the parts would be a[:i], a[i:j],
    and a[j:].

    So that's why Python uses 0-based indexing.

The API offers more high-level functions that result in a slice being returned.
See Tail, Head, Trim, Trim_Leading, Trim_Trailing, ...

Iterators
---------

The API provides various iterators. This includes the default iterator by Byte:

.. code-block:: ada

    for B of My_Bytes loop
        [...]
    end loop;

A line iterator is also present:

.. code-block:: ada

    for L of Lines (My_Bytes) loop
        --  L is in that case a slice of the My_Bytes object.
        [...]
    end loop;

Queries
-------

The API provides the following functions:

.. csv-table::
    :header: "Function/Procedure", "Description"

    "=", "the equal operator allows comparison of a Bytes object with both Bytes and String"
    "Find", "find a given byte, character or pattern in a Bytes object"
    "RFind", "reverse find a given byte, character or pattern in a Bytes object"
    "Count", "count the number of occurence of a given byte"
    "Starts_With", "check for a prefix in a Bytes object"
    "Ends_With", "check for a suffix in a Bytes object"

See the package specification for a complete documentation.
