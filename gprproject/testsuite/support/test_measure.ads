package Test_Measure is

   procedure Start_Measure;
   procedure End_Measure;
   procedure Display_Measure (Message : String; Compare_With : Duration := 0.0;
                              Iterations : Integer := 1);
   procedure End_Measure (Message : String; Compare_With : Duration := 0.0);

end Test_Measure;
