--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

with Interfaces;
use Interfaces;

package body CBE
with SPARK_Mode
is
   function Snapshot_Valid (Snap : Snapshot_Type)
   return Boolean
   is
   begin
      case Snap.Valid is
      when 0      => return False;
      when 1      => return True;
      when others => raise Program_Error;
      end case;
   end Snapshot_Valid;

   procedure Snapshot_Valid (
      Snap  : in out Snapshot_Type;
      Valid :        Boolean)
   is
   begin
      case Valid is
      when False => Snap.Valid := 0;
      when True  => Snap.Valid := 1;
      end case;
   end Snapshot_Valid;

   procedure Block_Data_From_Unsigned_64 (
      Data : in out Block_Data_Type;
      Off  :        Block_Data_Index_Type;
      Int  :        Unsigned_64)
   is
   begin
      Data (Off + 7) := Byte_Type (Shift_Right (Int, 56) and 16#ff#);
      Data (Off + 6) := Byte_Type (Shift_Right (Int, 48) and 16#ff#);
      Data (Off + 5) := Byte_Type (Shift_Right (Int, 40) and 16#ff#);
      Data (Off + 4) := Byte_Type (Shift_Right (Int, 32) and 16#ff#);
      Data (Off + 3) := Byte_Type (Shift_Right (Int, 24) and 16#ff#);
      Data (Off + 2) := Byte_Type (Shift_Right (Int, 16) and 16#ff#);
      Data (Off + 1) := Byte_Type (Shift_Right (Int,  8) and 16#ff#);
      Data (Off + 0) := Byte_Type (Int                   and 16#ff#);
   end Block_Data_From_Unsigned_64;

   procedure Block_Data_From_Unsigned_32 (
      Data : in out Block_Data_Type;
      Off  :        Block_Data_Index_Type;
      Int  :        Unsigned_32)
   is
   begin
      Data (Off + 3) := Byte_Type (Shift_Right (Int, 24) and 16#ff#);
      Data (Off + 2) := Byte_Type (Shift_Right (Int, 16) and 16#ff#);
      Data (Off + 1) := Byte_Type (Shift_Right (Int,  8) and 16#ff#);
      Data (Off + 0) := Byte_Type (Int                   and 16#ff#);
   end Block_Data_From_Unsigned_32;

   procedure Block_Data_From_Boolean (
      Data : in out Block_Data_Type;
      Off  :        Block_Data_Index_Type;
      Bool :        Boolean)
   is
   begin
      Data (Off) := (if Bool then 1 else 0);
   end Block_Data_From_Boolean;

   procedure Block_Data_Zero_Fill (
      Data : in out Block_Data_Type;
      Off  :        Block_Data_Index_Type;
      Size :        Block_Data_Index_Type)
   is
   begin
      for Off_2 in 0 .. Size - 1 loop
         Data (Off + Off_2) := 0;
      end loop;
   end Block_Data_Zero_Fill;

   procedure Block_Data_From_Hash (
      Data   : in out Block_Data_Type;
      Off_In :        Block_Data_Index_Type;
      Hash   :        Hash_Type)
   is
      Off : Block_Data_Index_Type := Off_In;
   begin
      for Idx in Hash'Range loop
         Data (Off) := Hash (Idx);
         Off := Off + 1;
      end loop;
   end Block_Data_From_Hash;

   procedure Block_Data_From_Type_I_Node (
      Data   : in out Block_Data_Type;
      Off_In :        Block_Data_Index_Type;
      Node   :        Type_I_Node_Type)
   is
      Off : Block_Data_Index_Type := Off_In;
   begin
      Block_Data_From_Unsigned_64 (Data, Off, Unsigned_64 (Node.PBA));
      Off := Off + Unsigned_64'Size / Data (0)'Size;

      Block_Data_From_Unsigned_64 (Data, Off, Unsigned_64 (Node.Gen));
      Off := Off + Unsigned_64'Size / Data (0)'Size;

      Block_Data_From_Hash (Data, Off, Node.Hash);
      Off := Off + Hash_Type'Size / Data (0)'Size;

      Block_Data_Zero_Fill (Data, Off, Node.Padding'Size / Data (0)'Size);
   end Block_Data_From_Type_I_Node;

   procedure Block_Data_From_Type_I_Node_Block (
      Data  : out Block_Data_Type;
      Nodes :     Type_I_Node_Block_Type)
   is
      Off : Block_Data_Index_Type := 0;
   begin
      for Idx in Nodes'Range loop
         Off := Block_Data_Index_Type (
            (Idx * Type_I_Node_Type'Size) / Data (0)'Size);

         Block_Data_From_Type_I_Node (Data, Off, Nodes (Idx));
      end loop;
   end Block_Data_From_Type_I_Node_Block;

   procedure Block_Data_From_Type_II_Node (
      Data   : in out Block_Data_Type;
      Off_In :        Block_Data_Index_Type;
      Node   :        Type_II_Node_Type)
   is
      Off : Block_Data_Index_Type := Off_In;
   begin
      Block_Data_From_Unsigned_64 (Data, Off, Unsigned_64 (Node.PBA));
      Off := Off + Unsigned_64'Size / Data (0)'Size;

      Block_Data_From_Unsigned_64 (Data, Off, Unsigned_64 (Node.Last_VBA));
      Off := Off + Unsigned_64'Size / Data (0)'Size;

      Block_Data_From_Unsigned_64 (Data, Off, Unsigned_64 (Node.Alloc_Gen));
      Off := Off + Unsigned_64'Size / Data (0)'Size;

      Block_Data_From_Unsigned_64 (Data, Off, Unsigned_64 (Node.Free_Gen));
      Off := Off + Unsigned_64'Size / Data (0)'Size;

      Block_Data_From_Unsigned_32 (Data, Off, Unsigned_32 (Node.Last_Key_ID));
      Off := Off + Unsigned_32'Size / Data (0)'Size;

      Block_Data_From_Boolean (Data, Off, Node.Reserved);
      Off := Off + Node.Reserved'Size / Data (0)'Size;

      Block_Data_Zero_Fill (Data, Off, Node.Padding'Size / Data (0)'Size);
   end Block_Data_From_Type_II_Node;

   procedure Block_Data_From_Type_II_Node_Block (
      Data  : out Block_Data_Type;
      Nodes :     Type_II_Node_Block_Type)
   is
      Off : Block_Data_Index_Type := 0;
   begin
      for Idx in Nodes'Range loop
         Off := Block_Data_Index_Type (
            (Idx * Type_II_Node_Type'Size) / Data (0)'Size);

         Block_Data_From_Type_II_Node (Data, Off, Nodes (Idx));
      end loop;
   end Block_Data_From_Type_II_Node_Block;

   function Boolean_From_Block_Data (
      Data : Block_Data_Type;
      Off  : Block_Data_Index_Type)
   return Boolean
   is (
      if Data (Off + 0) = 1 then True else False);

   function Unsigned_32_From_Block_Data (
      Data : Block_Data_Type;
      Off  : Block_Data_Index_Type)
   return Unsigned_32
   is (
      Shift_Left (Unsigned_32 (Data (Off + 3)), 24) +
      Shift_Left (Unsigned_32 (Data (Off + 2)), 16) +
      Shift_Left (Unsigned_32 (Data (Off + 1)),  8) +
                  Unsigned_32 (Data (Off + 0)));

   function Unsigned_64_From_Block_Data (
      Data : Block_Data_Type;
      Off  : Block_Data_Index_Type)
   return Unsigned_64
   is (
      Shift_Left (Unsigned_64 (Data (Off + 7)), 56) +
      Shift_Left (Unsigned_64 (Data (Off + 6)), 48) +
      Shift_Left (Unsigned_64 (Data (Off + 5)), 40) +
      Shift_Left (Unsigned_64 (Data (Off + 4)), 32) +
      Shift_Left (Unsigned_64 (Data (Off + 3)), 24) +
      Shift_Left (Unsigned_64 (Data (Off + 2)), 16) +
      Shift_Left (Unsigned_64 (Data (Off + 1)),  8) +
                  Unsigned_64 (Data (Off + 0)));

   function Hash_From_Block_Data (
      Data : Block_Data_Type;
      Base : Block_Data_Index_Type)
   return Hash_Type
   is
      Result : Hash_Type;
      Off    : Block_Data_Index_Type := 0;
   begin
      for Idx in Result'Range loop
         Result (Idx) := Data (Base + Off);
         Off := Off + 1;
      end loop;
      return Result;
   end Hash_From_Block_Data;

   procedure Type_II_Node_Block_From_Block_Data (
      Nodes : out Type_II_Node_Block_Type;
      Data  :     Block_Data_Type)
   is
      Off : Block_Data_Index_Type;
   begin
      For_Nodes :
      for Idx in Nodes'Range loop
         Off := Block_Data_Index_Type (
            (Idx * Type_II_Node_Type'Size) / Data (0)'Size);

         Nodes (Idx).PBA := Physical_Block_Address_Type (
            Unsigned_64_From_Block_Data (Data, Off));
         Off := Off + Nodes (Idx).PBA'Size / Data (0)'Size;

         Nodes (Idx).Last_VBA := Virtual_Block_Address_Type (
            Unsigned_64_From_Block_Data (Data, Off));
         Off := Off + Nodes (Idx).Last_VBA'Size / Data (0)'Size;

         Nodes (Idx).Alloc_Gen := Generation_Type (
            Unsigned_64_From_Block_Data (Data, Off));
         Off := Off + Nodes (Idx).Alloc_Gen'Size / Data (0)'Size;

         Nodes (Idx).Free_Gen := Generation_Type (
            Unsigned_64_From_Block_Data (Data, Off));
         Off := Off + Nodes (Idx).Free_Gen'Size / Data (0)'Size;

         Nodes (Idx).Last_Key_ID := Key_ID_Storage_Type (
            Unsigned_32_From_Block_Data (Data, Off));
         Off := Off + Nodes (Idx).Last_Key_ID'Size / Data (0)'Size;

         Nodes (Idx).Reserved := Boolean_From_Block_Data (Data, Off);
         Nodes (Idx).Padding := (others => 0);
      end loop For_Nodes;
   end Type_II_Node_Block_From_Block_Data;

   procedure Type_I_Node_Block_From_Block_Data (
      Nodes : out Type_I_Node_Block_Type;
      Data  :     Block_Data_Type)
   is
      Off : Block_Data_Index_Type;
   begin
      For_Nodes :
      for Idx in Nodes'Range loop
         Off := Block_Data_Index_Type (
            (Idx * Type_I_Node_Type'Size) / Data (0)'Size);

         Nodes (Idx).PBA := Physical_Block_Address_Type (
            Unsigned_64_From_Block_Data (Data, Off));
         Off := Off + Nodes (Idx).PBA'Size / Data (0)'Size;

         Nodes (Idx).Gen := Generation_Type (
            Unsigned_64_From_Block_Data (Data, Off));
         Off := Off + Nodes (Idx).Gen'Size / Data (0)'Size;

         Nodes (Idx).Hash := Hash_From_Block_Data (Data, Off);
         Off := Off + Nodes (Idx).Hash'Size / Data (0)'Size;

         Nodes (Idx).Padding := (others => 0);
      end loop For_Nodes;
   end Type_I_Node_Block_From_Block_Data;

   procedure Block_Data_From_Key (
      Data     : in out Block_Data_Type;
      Data_Off :        Block_Data_Index_Type;
      Key      :        Key_Type)
   is
      Key_Off : Block_Data_Index_Type := Data_Off;
   begin
      Declare_Value_Off : declare
         Value_Off : Block_Data_Index_Type;
      begin
         For_Value_Items : for Idx in Key.Value'Range loop
            Value_Off := Key_Off + Block_Data_Index_Type (
               Idx * (Key.Value (0)'Size / Data (0)'Size));

            Data (Value_Off) := Key.Value (Idx);
         end loop For_Value_Items;
      end Declare_Value_Off;
      Key_Off := Key_Off + Key.Value'Size / Data (0)'Size;

      Block_Data_From_Unsigned_32 (Data, Key_Off, Unsigned_32 (Key.ID));
   end Block_Data_From_Key;

   procedure Block_Data_From_Snap (
      Data     : in out Block_Data_Type;
      Data_Off :        Block_Data_Index_Type;
      Snap     :        Snapshot_Type)
   is
      Snap_Off : Block_Data_Index_Type := Data_Off;
   begin
      Block_Data_From_Hash (Data, Snap_Off, Snap.Hash);
      Snap_Off := Snap_Off + Snap.Hash'Size / Data (0)'Size;

      Block_Data_From_Unsigned_64 (Data, Snap_Off, Unsigned_64 (Snap.PBA));
      Snap_Off := Snap_Off + Snap.PBA'Size / Data (0)'Size;

      Block_Data_From_Unsigned_64 (Data, Snap_Off, Unsigned_64 (Snap.Gen));
      Snap_Off := Snap_Off + Snap.Gen'Size / Data (0)'Size;

      Block_Data_From_Unsigned_64 (
         Data, Snap_Off, Unsigned_64 (Snap.Nr_Of_Leafs));
      Snap_Off := Snap_Off + Snap.Nr_Of_Leafs'Size / Data (0)'Size;

      Block_Data_From_Unsigned_32 (Data, Snap_Off, Unsigned_32 (Snap.Height));
      Snap_Off := Snap_Off + Snap.Height'Size / Data (0)'Size;

      Data (Snap_Off) := Byte_Type (Snap.Valid);
      Snap_Off := Snap_Off + Snap.Valid'Size / Data (0)'Size;

      Block_Data_From_Unsigned_32 (Data, Snap_Off, Unsigned_32 (Snap.ID));
      Snap_Off := Snap_Off + Snap.ID'Size / Data (0)'Size;

      Block_Data_From_Unsigned_32 (Data, Snap_Off, Unsigned_32 (Snap.Flags));
   end Block_Data_From_Snap;

   procedure Block_Data_From_Keys (
      Data     : in out Block_Data_Type;
      Data_Off :        Block_Data_Index_Type;
      Keys     :        Keys_Type)
   is
      Keys_Off : Block_Data_Index_Type := Data_Off;
      Key_Bytes : constant Natural := Keys (0)'Size / Data (0)'Size;
   begin
      For_Keys : for Idx in Keys'Range loop
         Keys_Off :=
           Data_Off + Block_Data_Index_Type (Natural (Idx) * Key_Bytes);

         Block_Data_From_Key (Data, Keys_Off, Keys (Idx));
      end loop For_Keys;
   end Block_Data_From_Keys;

   procedure Block_Data_From_Snapshots (
      Data     : in out Block_Data_Type;
      Data_Off :        Block_Data_Index_Type;
      Snaps    :        Snapshots_Type)
   is
      Snaps_Off : Block_Data_Index_Type := Data_Off;
      Snap_Bytes : constant Natural := Snaps (0)'Size / Data (0)'Size;
   begin
      For_Snaps : for Idx in Snaps'Range loop
         Snaps_Off :=
           Data_Off + Block_Data_Index_Type (Natural (Idx) * Snap_Bytes);

         Block_Data_From_Snap (Data, Snaps_Off, Snaps (Idx));
      end loop For_Snaps;
   end Block_Data_From_Snapshots;

   procedure Block_Data_From_Superblock (
      Data  : out Block_Data_Type;
      SB    :     Superblock_Type)
   is
      Off : Block_Data_Index_Type := 0;
   begin
      Block_Data_From_Keys (Data, Off, SB.Keys);
      Off := Off + SB.Keys'Size / Data (0)'Size;

      Block_Data_From_Snapshots (Data, Off, SB.Snapshots);
      Off := Off + SB.Snapshots'Size / Data (0)'Size;

      Block_Data_From_Unsigned_64 (
         Data, Off, Unsigned_64 (SB.Last_Secured_Generation));
      Off := Off + SB.Last_Secured_Generation'Size / Data (0)'Size;

      Block_Data_From_Unsigned_32 (Data, Off, Unsigned_32 (SB.Curr_Snap));
      Off := Off + SB.Curr_Snap'Size / Data (0)'Size;

      Block_Data_From_Unsigned_32 (Data, Off, Unsigned_32 (SB.Degree));
      Off := Off + SB.Degree'Size / Data (0)'Size;

      Block_Data_From_Unsigned_64 (Data, Off, Unsigned_64 (SB.Free_Gen));
      Off := Off + SB.Free_Gen'Size / Data (0)'Size;

      Block_Data_From_Unsigned_64 (Data, Off, Unsigned_64 (SB.Free_Number));
      Off := Off + SB.Free_Number'Size / Data (0)'Size;

      Block_Data_From_Hash (Data, Off, SB.Free_Hash);
      Off := Off + SB.Free_Hash'Size / Data (0)'Size;

      Block_Data_From_Unsigned_32 (Data, Off, Unsigned_32 (SB.Free_Height));
      Off := Off + SB.Free_Height'Size / Data (0)'Size;

      Block_Data_From_Unsigned_32 (Data, Off, Unsigned_32 (SB.Free_Degree));
      Off := Off + SB.Free_Degree'Size / Data (0)'Size;

      Block_Data_From_Unsigned_64 (Data, Off, Unsigned_64 (SB.Free_Leafs));
      Off := Off + SB.Free_Leafs'Size / Data (0)'Size;

      Block_Data_Zero_Fill (Data, Off, SB.Padding'Size / Data (0)'Size);
   end Block_Data_From_Superblock;

end CBE;
