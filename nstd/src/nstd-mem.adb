with NStd.Memory;
with Ada.Unchecked_Conversion;

package body NStd.Mem is

   function Internal_To_SizeType is
      new Ada.Unchecked_Conversion (Address, SizeType);
   function Internal_To_Address is
      new Ada.Unchecked_Conversion (SizeType, Address);

   function "-" (Left, Right: Address) return SizeType is
   begin
      return SizeType (System.Storage_Elements."-" (Left, Right));
   end "-";

   -- To_SizeType --

   function To_SizeType (Self : Address) return SizeType
   is
   begin
      return Internal_To_SizeType (Self);
   end To_SizeType;

   -- To_Address --

   function To_Address (Self : SizeType) return Address
   is
   begin
      return Internal_To_Address (Self);
   end To_Address;

   -- Allocate --

   function Allocate (Length : SizeType) return Block is
      Result : Block;
   begin
      if Length > SizeType'Last - 2 then
         raise Storage_Error with "allocation length too large";
      end if;

      if Length < 1 then
         raise Storage_Error with "allocation length should be > 0";
      end if;

      Result.Addr := NStd.Memory.Malloc (Length);
      Result.Length := Length;

      if Result.Addr = Null_Address then
         raise Storage_Error with "memory allocation failed";
      end if;

      return Result;
   end Allocate;

   -- Free --

   procedure Free (Self : in out Block) is
   begin
      if Self.Addr /= Null_Address then
         NStd.Memory.Free (Self.Addr);
         Self := Empty_Block;
      end if;
   end Free;

   -- Clone --

   function Clone (Self : Block) return Block
   is
      Result : Block;
   begin
      if Self.Addr /= Null_Address then
         Result := Allocate (Self.Length);
         Result.Addr := NStd.Memory.memcpy
            (Result.Addr, Self.Addr, Self.Length);
      else
         Result := Empty_Block;
      end if;

      return Result;
   end Clone;

   -- Reallocate --

   procedure Reallocate (Self : in out Block; Length : SizeType) is
   begin
      if Length > ISize'Last - 1 then
         raise Storage_Error with "allocation length too large";
      end if;

      if Length < 1 then
         raise Storage_Error with "allocation length should be >= 1";
      end if;

      Self.Addr := NStd.Memory.realloc (Self.Addr, Length);
      Self.Length := Length;

      if Self.Addr = Null_Address then
         raise Storage_Error with "memory allocation failed";
      end if;

   end Reallocate;

   function Ref (Self : String) return Block is
      pragma Suppress (All_Checks);
   begin
      if Self'Length > 0 then
         return (Addr => Self (Self'First)'Address, Length => Self'Length);
      else
         return Empty_Block;
      end if;
   end Ref;

   function Is_Content_Equal (Left : Block; Right : Block) return Boolean is
   begin
      if Left.Length /= Right.Length then
         return False;
      elsif Left.Length = 0 then
         return True;
      elsif Left.Addr = Right.Addr then
         return True;
      else
         return NStd.Memory.Memcmp (Left.Addr, Right.Addr, Left.Length) = 0;
      end if;
   end Is_Content_Equal;

end NStd.Mem;
