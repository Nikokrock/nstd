with Ada.Calendar; use Ada.Calendar;
with Ada.Text_IO;

package body Test_Measure is
   Start : Time;

   procedure Start_Measure is
   begin
      Start := Clock;
   end Start_Measure;

   procedure End_Measure is
   begin
      Measure_Time := Clock - Start;
   end End_Measure;

   procedure End_Measure (Message : String; Compare_With : Duration := 0.0) is
   begin
      End_Measure;
      Display_Measure (Message, Compare_With);
   end End_Measure;

   procedure Display_Measure (Message : String; Compare_With : Duration := 0.0; Iterations : Integer := 1)
   is
   begin
      if Compare_With > 0.0 then
         declare
            Ratio : constant Long_Float :=
              Long_Float (Measure_Time) / Long_Float (Iterations) / Long_Float (Compare_With) * 100.0;
         begin
            Ada.Text_IO.Put_Line
               (Message & ":" &
                Integer (Ratio)'Img & "% compared to baseline");
         end;
      end if;
      Ada.Text_IO.Put_Line (Message & ":" & Duration'Image (Measure_Time / Duration (Iterations)) & "s total time");
   end Display_Measure;
end Test_Measure;
