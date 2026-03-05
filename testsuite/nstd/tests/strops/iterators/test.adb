with Test_Assert;
with NStd.Strops; use NStd.Strops;
with NStd; use NStd;
with GNAT.IO;

function Test return Integer is

   package A renames Test_Assert;

   S      : constant Str := Clone ("0001230012");
   Long_S : constant Str := S * (10 * 1024 * 1024);

   Counter : UInt64 := 0;
begin

   GNAT.IO.Put_Line ("== Count ASCII codepoints ==");
   for Codepoint of S loop
      if Codepoint = 16#30# then
         Counter := Counter + 1;
      end if;
   end loop;
   A.Assert (Counter = 5);

   Counter := 0;

   for Codepoint of Long_S loop
      if Codepoint = 16#30# then
         Counter := Counter + 1;
      end if;
   end loop;
   A.Assert (Counter = 5 * 10 * 1024 * 1024);

   GNAT.IO.Put_Line ("== Empty string iteration ==");
   Counter := 0;
   declare
      E : constant Str := Clone ("");
   begin
      for Codepoint of E loop
         Counter := Counter + 1;
      end loop;
      A.Assert (Counter = 0, "empty string yields no codepoints");
   end;

   GNAT.IO.Put_Line ("== Total codepoint count ==");
   Counter := 0;
   for Codepoint of S loop
      Counter := Counter + 1;
   end loop;
   A.Assert (Counter = 10, "10 ASCII chars = 10 codepoints");

   GNAT.IO.Put_Line ("== Codepoint values for ASCII ==");
   declare
      Abc : constant Str := Clone ("ABC");
      Idx : UInt64 := 0;
   begin
      for Codepoint of Abc loop
         case Idx is
            when 0 => A.Assert (Codepoint = 16#41#, "A = U+0041");
            when 1 => A.Assert (Codepoint = 16#42#, "B = U+0042");
            when 2 => A.Assert (Codepoint = 16#43#, "C = U+0043");
            when others => A.Assert (False, "unexpected codepoint");
         end case;
         Idx := Idx + 1;
      end loop;
      A.Assert (Idx = 3);
   end;

   GNAT.IO.Put_Line ("== Multibyte UTF-8: 2-byte ==");
   declare
      --  U+00E9 (e-acute) = C3 A9 in UTF-8
      S2 : constant Str := Clone ("" & Character'Val (16#C3#)
                                     & Character'Val (16#A9#),
                                  Check => False);
   begin
      Counter := 0;
      for Codepoint of S2 loop
         A.Assert (Codepoint = 16#E9#, "U+00E9");
         Counter := Counter + 1;
      end loop;
      A.Assert (Counter = 1, "one 2-byte codepoint");
   end;

   GNAT.IO.Put_Line ("== Multibyte UTF-8: 3-byte ==");
   declare
      --  U+20AC (euro sign) = E2 82 AC in UTF-8
      S3 : constant Str := Clone ("" & Character'Val (16#E2#)
                                     & Character'Val (16#82#)
                                     & Character'Val (16#AC#),
                                  Check => False);
   begin
      Counter := 0;
      for Codepoint of S3 loop
         A.Assert (Codepoint = 16#20AC#, "U+20AC");
         Counter := Counter + 1;
      end loop;
      A.Assert (Counter = 1, "one 3-byte codepoint");
   end;

   GNAT.IO.Put_Line ("== Multibyte UTF-8: 4-byte ==");
   declare
      --  U+1F600 (grinning face) = F0 9F 98 80 in UTF-8
      S4 : constant Str := Clone ("" & Character'Val (16#F0#)
                                     & Character'Val (16#9F#)
                                     & Character'Val (16#98#)
                                     & Character'Val (16#80#),
                                  Check => False);
   begin
      Counter := 0;
      for Codepoint of S4 loop
         A.Assert (Codepoint = 16#1F600#, "U+1F600");
         Counter := Counter + 1;
      end loop;
      A.Assert (Counter = 1, "one 4-byte codepoint");
   end;

   GNAT.IO.Put_Line ("== Mixed ASCII and multibyte ==");
   declare
      --  "a" (61) + U+00E9 (C3 A9) + "b" (62) = 4 bytes, 3 codepoints
      Mixed : constant Str := Clone ("a"
                                     & Character'Val (16#C3#)
                                     & Character'Val (16#A9#)
                                     & "b",
                                     Check => False);
      Idx : UInt64 := 0;
   begin
      for Codepoint of Mixed loop
         case Idx is
            when 0 => A.Assert (Codepoint = 16#61#, "a = U+0061");
            when 1 => A.Assert (Codepoint = 16#E9#, "e-acute = U+00E9");
            when 2 => A.Assert (Codepoint = 16#62#, "b = U+0062");
            when others => A.Assert (False, "unexpected codepoint");
         end case;
         Idx := Idx + 1;
      end loop;
      A.Assert (Idx = 3, "3 codepoints in mixed string");
   end;

   return A.Report;

end Test;
