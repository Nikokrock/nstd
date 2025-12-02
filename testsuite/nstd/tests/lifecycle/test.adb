with Test_Assert;
with NStd; use NStd;
with NStd.Unsafe;
with NStd.Lifecycle;
with NStd.Mem; use NStd.Mem;
with GNAT.Source_Info;

function Test return Integer is
   package A renames Test_Assert;
   package Life renames NStd.Lifecycle;
   package SI renames GNAT.Source_Info;

   S1 : constant String := "ABCDEFGHIJ";
   S2 : constant String := "0123456789abcdefghijklmnopqrstuvwxyz";

   Mem1 : Life.Refcounted_Mem;
   Mem2 : Life.Refcounted_Mem;
   Mem3 : Life.Refcounted_Mem;
   Mem4 : Life.Refcounted_Mem;
   Mem5 : Life.Refcounted_Mem;

   Region : constant Block := Allocate (24);
   Region2 : constant Block := Allocate (8);

   procedure Assert_Char
      (M : Life.Refcounted_Mem; Idx : SizeType; C : Character;
       Location : String := SI.Source_Location);

   procedure Assert_Char
      (M : Life.Refcounted_Mem; Idx : SizeType; C : Character;
       Location : String := SI.Source_Location)
   is
      Result : constant Character :=
         As_Char (NStd.Unsafe.Get (Life.Block (M).Addr, Idx));
   begin
      if C /= Result then
         A.Assert
            (False,
             "expecting " & C & " but got " & Result &
             " at position" & Idx'Img,
             Location => Location);
      else
         A.Assert
            (True,
             "got expected character " & C & " at position" & Idx'Img,
             Location => Location);
      end if;
   end Assert_Char;

   procedure Assert_Equal
      (M1, M2   : Life.Refcounted_Mem;
       Id1, Id2 : SizeType;
       Location : String := SI.Source_Location);

   procedure Assert_Equal
      (M1, M2   : Life.Refcounted_Mem;
       Id1, Id2 : SizeType;
       Location : String := SI.Source_Location)
   is
      C1 : constant Character :=
         As_Char (NStd.Unsafe.Get (Life.Block (M1).Addr, Id1));
      C2 : constant Character :=
         As_Char (NStd.Unsafe.Get (Life.Block (M2).Addr, Id2));
   begin
      if C1 = C2 then
         A.Assert
            (True,
             "both memory have " & C1 & " character",
             Location => Location);
      else
         A.Assert
            (False,
             "non expected difference " & C1 & " vs " & C2,
             Location => Location);
      end if;
   end Assert_Equal;
begin
   --  Ensure the memory for Region2 is not set to 0 to ensure that we catch
   --  issues with implementations supporting SSO.
   for Idx in 0 .. 7 loop
      NStd.Unsafe.Set (Region2.Addr, SizeType (Idx), 42);
   end loop;

   --  Check Basic instantiation
   --  On a short string
   Life.Clone_And_Start_Refcounting (Mem1, (S1 (1)'Address, S1'Length));
   Assert_Char (Mem1, 0, 'A');
   Assert_Char (Mem1, 9, 'J');
   A.Assert (Life.Length (Mem1) = 10);

   --  On a bigger one
   Life.Clone_And_Start_Refcounting (Mem2, (S2 (1)'Address, S2'Length));
   Assert_Char (Mem2, 0, '0');
   Assert_Char (Mem2, 35, 'z');
   A.Assert
      (Life.Length (Mem2) = 36, "mem2 length is" & Life.Length (Mem2)'Img);

   --  Test some copying
   Mem3 := Mem2;
   A.Assert (Life.Length (Mem3) = Life.Length (Mem2));
   Assert_Equal (Mem3, Mem2, 0, 0);
   Assert_Equal (Mem3, Mem2, 35, 35);
   A.Assert (Life.Reference_Count (Mem2) = 2);

   --  Assignement of an already existing value
   Mem3 := Mem1;
   A.Assert (Life.Reference_Count (Mem2) = 1);
   A.Assert (Life.Length (Mem3) = Life.Length (Mem1));
   Assert_Equal (Mem3, Mem1, 0, 0);
   Assert_Equal (Mem3, Mem1, 9, 9);

   --  Copy of a null string
   Mem3 := Mem4;
   A.Assert (Life.Length (Mem3) = 0);
   A.Assert (Life.Reference_Count (Mem3) = 0);

   --  Another copy of a null string
   Mem3 := Mem5;
   A.Assert (Life.Length (Mem3) = 0);
   A.Assert (Life.Reference_Count (Mem3) = 0);
   A.Assert (Life.Reference_Count (Mem4) = 0);

   declare
      Mem : Life.Refcounted_Mem;
   begin
      Life.Start_Refcounting (Mem, Region);
      A.Assert (Life.Reference_Count (Mem) = 1);

      --  With small string optimisation (SSO), reference counting is disabled.
      Life.Start_Refcounting (Mem, Region2);
      A.Assert (Life.Reference_Count (Mem) = 0);
   end;

   declare
      Mem  : Life.Refcounted_Mem;
      Mem2 : Life.Refcounted_Mem;
   begin
      Life.Start_Limited_Reference (Mem, Region);
      A.Assert (Life.Reference_Count (Mem) = 0);

      Mem2 := Mem;
      A.Assert (Life.Reference_Count (Mem2) = 1);
   end;

   --  Slice tests
   Mem3 := Life.Slice (Mem2, 0, 36);
   A.Assert (Life.Length (Mem3) = 36);
   Assert_Char (Mem3, 0, '0');
   Assert_Char (Mem3, 35, 'z');

   Mem3 := Life.Slice (Mem2, 0, 20);
   A.Assert (Life.Length (Mem3) = 20);
   Assert_Char (Mem3, 0, '0');
   Assert_Char (Mem3, 19, 'j');

   Mem3 := Life.Slice (Mem2, 4, 20);
   A.Assert (Life.Length (Mem3) = 16);
   Assert_Char (Mem3, 0, '4');
   Assert_Char (Mem3, 15, 'j');

   Mem3 := Life.Slice (Mem2, 0, 64);
   A.Assert (Life.Length (Mem3) = 36);
   Assert_Char (Mem3, 0, '0');
   Assert_Char (Mem3, 35, 'z');

   Mem3 := Life.Slice (Mem2, 4, 4);
   A.Assert (Life.Length (Mem3) = 0);

   Mem3 := Life.Slice (Mem2, 5, 4);
   A.Assert (Life.Length (Mem3) = 0);

   Mem3 := Life.Slice (Mem2, 0, -36);
   A.Assert (Life.Length (Mem3) = 0);

   Mem3 := Life.Slice (Mem2, 0, -37);
   A.Assert (Life.Length (Mem3) = 0);

   Mem3 := Life.Slice (Mem2, -4, -2);
   A.Assert (Life.Length (Mem3) = 2);

   Mem3 := Life.Slice (Mem2, -37, -2);
   A.Assert (Life.Length (Mem3) = 34);

   Mem3 := Life.Slice (Mem2, -2, -4);
   A.Assert (Life.Length (Mem3) = 0);

   -- Slice of an empty string
   Mem3 := Life.Slice (Mem4, 0, 3000);
   A.Assert (Life.Length (Mem3) = 0);

   return A.Report;
end Test;