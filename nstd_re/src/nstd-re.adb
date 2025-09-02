with NStd.Unsafe;

package body NStd.Re is

   PCRE2_NO_UTF_CHECK : constant UInt32 := 16#40_00_00_00#;

   -- C binding to PCRE2 API --

   function PCRE2_Get_Error_Message
      (Error_Code : Integer;
       Buffer     : System.Address;
       Size       : SizeType)
      return Integer;
   pragma Import (C, PCRE2_Get_Error_Message, "pcre2_get_error_message_8");

   function PCRE2_Match_Data_Create_From_Pattern
      (Code    : PCRE2_Regexp;
       Context : System.Address := System.Null_Address)
      return PCRE2_Match_Data;
   pragma Import
      (C,
       PCRE2_Match_Data_Create_From_Pattern,
       "pcre2_match_data_create_from_pattern_8");

   procedure PCRE2_Match_Data_Free (Self : PCRE2_Match_Data);
   pragma Import (C, PCRE2_Match_Data_Free, "pcre2_match_data_free_8");

   function PCRE2_Match
      (Code : PCRE2_Regexp;
       Subject : System.Address;
       Subject_Length : SizeType;
       Subject_Offset : SizeType;
       Options        : UInt32;
       Match_Data     : PCRE2_Match_Data;
       Match_Context  : System.Address := System.Null_Address)
      return Integer;
   pragma Import (C, PCRE2_Match, "pcre2_match_8");
   
   function PCRE2_Compile
      (Pattern      : System.Address;
       Length       : SizeType;
       Options      : NStd.UInt32;
       Error_Code   : out Integer;
       Error_Offset : out SizeType;
       Context      : System.Address)
      return PCRE2_Regexp;
   pragma Import (C, PCRE2_Compile, "pcre2_compile_8");

   function PCRE2_Get_Ovector_Pointer
      (Match_Data : PCRE2_Match_Data) return System.Address;
   pragma Import (C, PCRE2_Get_Ovector_Pointer, "pcre2_get_ovector_pointer_8");

   -- Raise_Regexp_Error --
   
   procedure Raise_Regexp_Error
      (Error_Code   : Integer;
       Error_Offset : SizeType := -1);

   procedure Raise_Regexp_Error
      (Error_Code   : Integer;
       Error_Offset : SizeType := -1)
   is
      --  Is there a way to avoid the warning on the fact that
      --  Error_Message is never assigned ?
      pragma Warnings (Off);
      Error_Message : aliased String (1 .. 256);
      pragma Warnings (On);
      Error_Message_Last : Integer;
   begin
      Error_Message_Last := PCRE2_Get_Error_Message
         (Error_Code, NStd.Unsafe.Reference (Error_Message), 256);

      --  If the buffer is too small, the message is truncated. The message
      --  size in that case is 255 and not 256 because of the trailing ASCII
      --  null character.
      if Error_Message_Last < 0 then
         Error_Message_Last := 255;
      end if;

      if Error_Offset >= 0 then
         raise Regexp_Error with
            Error_Message (1 .. Error_Message_Last) &
            " at offset" & Error_Offset'Img;
      else
         raise Regexp_Error with
            Error_Message (1 .. Error_Message_Last);
      end if;
   end Raise_Regexp_Error;

   -- Compile --

   function Compile (Pattern : String) return Regexp
   is
      Result       : Regexp;
      Error_Code   : Integer;
      Error_Offset : SizeType;
   begin
      Result.Code := PCRE2_Compile
         (NStd.Unsafe.Reference (Pattern),
          Pattern'Length,
          0,
          Error_Code,
          Error_Offset,
          System.Null_Address);

      if Result.Code = Null_Code then
         Raise_Regexp_Error
            (Error_Code => Error_Code, Error_Offset => Error_Offset);
      end if;
      return Result;
   end Compile;

   function Compile (Pattern : NStd.Strops.Str) return Regexp
   is
      Result       : Regexp;
      Error_Code   : Integer;
      Error_Offset : SizeType;
   begin
      Result.Code := PCRE2_Compile
         (NStd.Strops.Addr (Pattern),
          NStd.Strops.Byte_Length (Pattern),
          PCRE2_NO_UTF_CHECK,
          Error_Code,
          Error_Offset,
          System.Null_Address);

      if Result.Code = Null_Code then
         Raise_Regexp_Error
            (Error_Code => Error_Code, Error_Offset => Error_Offset);
      end if;
      return Result;
   end Compile;

   function Search (Self : Regexp; Content : NStd.Strops.Str) return Match
   is
   begin
      return Result : Match do
         Result.Data := PCRE2_Match_Data_Create_From_Pattern (Self.Code);
         Result.Match_Status := PCRE2_Match
            (Code    => Self.Code,
             Subject => NStd.Strops.Addr (Content),
             Subject_Length  => NStd.Strops.Byte_Length (Content),
             Subject_Offset  => 0,
             Options => 0,
             Match_Data => Result.Data);
         if Result.Match_Status > 0 then
            Result.OVector := PCRE2_Get_Ovector_Pointer (Result.Data);
            Result.Content := Content;
            Result.Subject_Offset := 0;
         else
            PCRE2_Match_Data_Free (Result.Data);
            Result.Data := Null_Match_Data;
            Result.Match_Status := 0;
            Result.Subject_Offset := 0;
            Result.OVector := System.Null_Address;
         end if;
      end return;
   end Search;

   procedure Search_Next (Self : Regexp; Prev_Match : in out Match) is
   begin
      declare
         Start_Addr : constant System.Address := Prev_Match.OVector;
         End_Addr   : constant System.Address := NStd.Unsafe.Addr
            (Prev_Match.OVector, SizeType (8));
         Start_Idx  : aliased SizeType;
         for Start_Idx'Address use Start_Addr;
         End_Idx  : aliased SizeType;
         for End_Idx'Address use End_Addr;

         Start_Offset : SizeType := End_Idx;
      begin
         --  If the previous match was for an empty string, we are finished if
         --  we are at the end of the subject. Otherwise, arrange to run
         --  another match at the same point to see if a non-empty match can
         --  be found.
         if Start_Idx = End_Idx then
            null;
         else
            if Start_Offset <= Prev_Match.Subject_Offset then
               Start_Offset := Prev_Match.Subject_Offset + 1;
               --  need to be a next utf8 !!!!
            end if;
         end if;

         Prev_Match.Match_Status := PCRE2_Match
            (Code    => Self.Code,
             Subject => NStd.Strops.Addr (Prev_Match.Content),
             Subject_Length  => NStd.Strops.Byte_Length (Prev_Match.Content),
             Subject_Offset  => Start_Offset,
             Options => 0,
             Match_Data => Prev_Match.Data);
         if Prev_Match.Match_Status > 0 then
            Prev_Match.OVector := PCRE2_Get_Ovector_Pointer (Prev_Match.Data);
            Prev_Match.Subject_Offset := Start_Offset;
         else
            PCRE2_Match_Data_Free (Prev_Match.Data);
            Prev_Match.Data := Null_Match_Data;
            Prev_Match.Match_Status := 0;
            Prev_Match.Subject_Offset := 0;
            Prev_Match.OVector := System.Null_Address;
         end if;
      end;
   end Search_Next;

   function Match_Group (Self : Match; Idx : Integer := 0) return NStd.Strops.Str is
   begin
      if Idx >= Self.Match_Status then
         raise Constraint_Error with "invalid match group" & Idx'Img;
      end if;

      declare
         Start_Addr : constant System.Address := NStd.Unsafe.Addr (Self.OVector, SizeType (Idx) * 2 * 8);
         End_Addr   : constant System.Address := NStd.Unsafe.Addr (Self.OVector, (SizeType (Idx) * 2 + 1) * 8);
         Start_Idx  : aliased SizeType;
         for Start_Idx'Address use Start_Addr;
         End_Idx  : aliased SizeType;
         for End_Idx'Address use End_Addr;
      begin
         return NStd.Strops.Slice (Self.Content, Start_Idx, End_Idx);
      end;
   end Match_Group;

   -- Finalize --
   procedure Finalize (Self : in out Match) is
   begin
      if Self.Data /= Null_Match_Data then
         PCRE2_Match_Data_Free (Self.Data);
         Self.Data := Null_Match_Data;
      end if;
   end Finalize;

   procedure Finalize (Self : in out Regexp) is
      procedure Internal (Code : PCRE2_Regexp);
      pragma Import (C, Internal, "pcre2_code_free_8");
   begin
      if Self.Code /= Null_Code then
         Internal (Self.Code);
         Self.Code := Null_Code;
      end if;
   end Finalize;

   -- Adjust --

   procedure Adjust (Self : in out Regexp) is
      function Internal (Code : PCRE2_Regexp) return PCRE2_Regexp;
      pragma Import (C, Internal, "pcre2_code_copy_8");
   begin
      if Self.Code /= Null_Code then
         Self.Code := Internal (Self.Code);
      end if;
   end Adjust;

   function Match_Count (Self : Match) return Integer is
   begin
      if Self.Match_Status > 0 then
         return Self.Match_Status;
      else
         return 0;
      end if;
   end Match_Count;
end NStd.Re;
