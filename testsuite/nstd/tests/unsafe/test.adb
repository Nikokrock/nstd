with Test_Assert;
with NStd;
with NStd.Unsafe;
with NStd.Byteops;
with System;
with GNAT.IO;

function Test return Integer is
   package A renames Test_Assert;
   package IO renames GNAT.IO;

   use all type System.Address;
   use all type NStd.SizeType;
   use all type NStd.UInt32;

   procedure Assert_Allocate_Fail (Length : NStd.SizeType) is
      S : System.Address;
   begin
      S := NStd.Unsafe.Allocate (Length);
      Nstd.Unsafe.Free (S);
      A.Assert
         (False, "exception not raised for allocate of size" & Length'Img);
   exception
      when Storage_Error =>
         A.Assert (True, "exception raised for allocate of size" & Length'Img);
   end Assert_Allocate_Fail;

begin

   IO.Put_Line ("Basic allocation test");
   declare
      S : constant System.Address := NStd.Unsafe.Allocate (10);
   begin
      A.Assert (S /= System.Null_Address);
      Nstd.Unsafe.Free (S);
   end;

   IO.Put_Line ("Allocations that should fail");
   Assert_Allocate_Fail (0);
   Assert_Allocate_Fail (-10);
   Assert_Allocate_Fail (2 ** 54);
   Assert_Allocate_Fail (NStd.SizeType'Last);
   Assert_Allocate_Fail (NStd.SizeType'Last - 1);
   Assert_Allocate_Fail (NStd.SizeType'First);

   IO.Put_Line ("Get_UTF8 tests");
   declare
      use NStd.Byteops;
      S : constant Bytes := Parse_C_Literal
         ("a\xC5\x80\xE2\x82\xAC\xF0\x92\x82\xAC");
      S_Addr : System.Address := Addr (S);
   begin
      A.Assert (Integer(Nstd.Unsafe.Get_UTF8 (S_Addr)), 16#61#);
      A.Assert (Integer(Nstd.Unsafe.Get_UTF8 (S_Addr)), 16#0140#);
      A.Assert (Integer(Nstd.Unsafe.Get_UTF8 (S_Addr)), 16#20AC#);
      A.Assert (Integer(Nstd.Unsafe.Get_UTF8 (S_Addr)), 16#0120AC#);
   end;

   return A.Report;

end Test;
