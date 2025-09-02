pragma Extensions_Allowed (On);
with NStd.Strops;

package NStd.Re is

   type Regexp is private;

   type Match is limited private;

   No_Match : constant Match;

   Regexp_Error : exception;
   --  Exception raised by most functions in case of error.

   function Compile (Pattern : NStd.Strops.Str) return Regexp;

   function Compile (Pattern : String) return Regexp;

   function Search (Self : Regexp; Content : NStd.Strops.Str) return Match;

   function Match_Group (Self : Match; Idx : Integer := 0) return NStd.Strops.Str;

   function Match_Count (Self : Match) return Integer;

   procedure Search_Next (Self : Regexp; Prev_Match : in out Match);
private

   procedure Finalize (Self : in out Regexp);

   procedure Adjust (Self : in out Regexp);

   procedure Finalize (Self : in out Match);

   type PCRE2_Regexp is new System.Address;
   type PCRE2_Match_Data is new System.Address;
   
   Null_Code       : PCRE2_Regexp := PCRE2_Regexp (System.Null_Address);
   Null_Match_Data : PCRE2_Match_Data := PCRE2_Match_Data (System.Null_Address);

   type Regexp is record
      Code : PCRE2_Regexp := Null_Code;
   end record
   with Finalizable =>
        (Finalize             => Finalize,
         Adjust               => Adjust,
         Relaxed_Finalization => True);

   type Match is record
      Data           : PCRE2_Match_Data := Null_Match_Data;
      Match_Status   : Integer          := 0;
      Subject_Offset : SizeType       := 0;
      OVector        : System.Address   := System.Null_Address;
      Content        : NStd.Strops.Str   := NStd.Strops.Empty_Str;
   end record
   with Finalizable =>
        (Finalize             => Finalize,
         Relaxed_Finalization => True);

   No_Match : constant Match :=
      (Data         => Null_Match_Data,
       Match_Status => 0,
       Subject_Offset => 0,
       OVector      => System.Null_Address,
       Content      => NStd.Strops.Empty_Str);

end NStd.Re;
