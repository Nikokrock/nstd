with Test_Assert;
with Test_Measure;
with NStd;
with NStd.Unsafe;
with NStd.Byteops;
with System;
with GNAT.IO;
with NStd.Mem;

function Test return Integer is
   package A renames Test_Assert;
   package IO renames GNAT.IO;
   package M renames Test_Measure;
   package Mem renames NStd.Mem;

   use all type System.Address;
   use all type NStd.SizeType;
   use all type NStd.UInt32;

   procedure Assert_Allocate_Fail (Length : NStd.SizeType) is
      B : Mem.Block;
   begin
      B := Mem.Allocate (Length);
      Mem.Free (B);
      A.Assert
         (False, "exception not raised for allocate of size" & Length'Img);
   exception
      when Storage_Error =>
         A.Assert (True, "exception raised for allocate of size" & Length'Img);
   end Assert_Allocate_Fail;

begin

   IO.Put_Line ("Basic allocation test");
   declare
      B : Mem.Block := Mem.Allocate (10);
   begin
      A.Assert (B.Addr /= System.Null_Address);
      A.Assert (B.Length = 10);
      Mem.Free (B);
   end;

   IO.Put_Line ("Free empty block");
   declare
      B : Mem.Block := Mem.Empty_Block;
   begin
      Mem.Free (B);
      A.Assert (B.Length = 0);
      A.Assert (B.Addr = System.Null_Address);
   end;

   IO.Put_Line ("Allocations that should fail");
   Assert_Allocate_Fail (0);
   Assert_Allocate_Fail (-10);
   Assert_Allocate_Fail (2 ** 54);
   Assert_Allocate_Fail (NStd.SizeType'Last);
   Assert_Allocate_Fail (NStd.SizeType'Last - 1);
   Assert_Allocate_Fail (NStd.SizeType'First);

   return A.Report;

end Test;
