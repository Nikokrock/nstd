Overview
########

NSTD Project
************

The NSTD project provides the core packages of the library. The main focus is to
provide good containers for both Bytes and Unicode Strings.

In the standard Ada runtime, the type String is used to hold strings of a
constant size without any particular encoding. For example if compared with
Python, the type is closer to the ``bytes`` type than the ``str`` type. Ada also
provides various types of finite or non-finite sizes
(for example ``Unbounded_String``). In practice most of the time the user is
using ``String`` or ``Unbounded_String``. Each type has its own advantages and
incovenients. Passing from one type to another always requires data copy. Also,
contrary to modern languages both types are mutables. Most modern languages have
adopted a non-mutable type for the bytes container and provides during
construction phases a mutable type that is usually used to build the final
object.

To handle Unicode, Ada provides types such as Wide_Wide_String or Wide_String in
which the unit is respectively 32bits and 16bits. Note that none of this type
enforce Unicode validity. Only the the size of the manipulated code unit is
modified.

The project provides the following core types

.. csv-table:: Core types

   "",                                        "Non-Mutable", "Mutable"
   "Bytes (no encoding)",                     "Bytes",       "MutableBytes"
   "Unicode (encoding enforced and checked)", "Str",         "MutableStr"

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   nstd_byteops.rst
