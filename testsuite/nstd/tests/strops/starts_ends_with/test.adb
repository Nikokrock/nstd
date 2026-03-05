with Test_Assert;
with NStd.Strops; use NStd.Strops;
with GNAT.IO;

function Test return Integer is
   package A renames Test_Assert;
begin

   GNAT.IO.Put_Line ("== Starts_With (Str, String) ==");
   declare
      S : constant Str := Clone ("hello world");
   begin
      A.Assert (Starts_With (S, "hello"));
      A.Assert (Starts_With (S, "hello world"));
      A.Assert (Starts_With (S, ""));
      A.Assert (not Starts_With (S, "world"));
      A.Assert (not Starts_With (S, "hello world and more"));
      A.Assert (not Starts_With (S, "Hello"));
   end;

   GNAT.IO.Put_Line ("== Starts_With (Str, Str) ==");
   declare
      S      : constant Str := Clone ("hello world");
      Prefix : constant Str := Clone ("hello");
      Full   : constant Str := Clone ("hello world");
      Empty  : constant Str := Clone ("");
      Bad    : constant Str := Clone ("world");
      Long   : constant Str := Clone ("hello world and more");
   begin
      A.Assert (Starts_With (S, Prefix));
      A.Assert (Starts_With (S, Full));
      A.Assert (Starts_With (S, Empty));
      A.Assert (not Starts_With (S, Bad));
      A.Assert (not Starts_With (S, Long));
      A.Assert (not Starts_With (Empty, Prefix));
      A.Assert (Starts_With (Empty, Empty));
   end;

   GNAT.IO.Put_Line ("== Ends_With (Str, String) ==");
   declare
      S : constant Str := Clone ("hello world");
   begin
      A.Assert (Ends_With (S, "world"));
      A.Assert (Ends_With (S, "hello world"));
      A.Assert (Ends_With (S, ""));
      A.Assert (not Ends_With (S, "hello"));
      A.Assert (not Ends_With (S, "and hello world"));
      A.Assert (not Ends_With (S, "World"));
   end;

   GNAT.IO.Put_Line ("== Ends_With (Str, Str) ==");
   declare
      S      : constant Str := Clone ("hello world");
      Suffix : constant Str := Clone ("world");
      Full   : constant Str := Clone ("hello world");
      Empty  : constant Str := Clone ("");
      Bad    : constant Str := Clone ("hello");
      Long   : constant Str := Clone ("and hello world");
   begin
      A.Assert (Ends_With (S, Suffix));
      A.Assert (Ends_With (S, Full));
      A.Assert (Ends_With (S, Empty));
      A.Assert (not Ends_With (S, Bad));
      A.Assert (not Ends_With (S, Long));
      A.Assert (not Ends_With (Empty, Suffix));
      A.Assert (Ends_With (Empty, Empty));
   end;

   GNAT.IO.Put_Line ("== UTF-8 multibyte strings ==");
   declare
      S      : constant Str := Clone ("caf" & Character'Val (16#C3#)
                                             & Character'Val (16#A9#),
                                       Check => False);
      Prefix : constant Str := Clone ("caf");
      Suffix : constant Str := Clone (
         "" & Character'Val (16#C3#) & Character'Val (16#A9#),
         Check => False);
   begin
      A.Assert (Starts_With (S, Prefix));
      A.Assert (Starts_With (S, "caf"));
      A.Assert (Ends_With (S, Suffix));
   end;

   return A.Report;

end Test;
