--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

package body CBE.VBD_Rekeying
with SPARK_Mode
is
   --
   --  Initialize_Rekeying
   --
   procedure Initialize_Rekeying (Rkg : out Rekeying_Type)
   is
   begin
      Initialize_Each_Job :
      for Idx in Rkg.Jobs'Range loop
         Rkg.Jobs (Idx) := (
            Operation => Invalid,
            State => Job_State_Type'First,
            Submitted_Prim => Primitive.Invalid_Object,
            Generated_Prim => Primitive.Invalid_Object,
            Snapshots => (others => Snapshot_Invalid),
            Snapshots_Degree => Tree_Degree_Type'First,
            Snapshot_Idx => Snapshots_Index_Type'First,
            First_Snapshot => Boolean'First,
            Old_Key_ID => Key_ID_Type'First,
            New_Key_ID => Key_ID_Type'First,
            T1_Blks => (others => (others => Type_1_Node_Invalid)),
            T1_Blks_Old_PBAs => (others => Physical_Block_Address_Type'First),
            T1_Blk_Idx => Tree_Level_Index_Type'First,
            Data_Blk => (others => Byte_Type'First),
            Data_Blk_Old_PBA => Physical_Block_Address_Type'First,
            VBA => Virtual_Block_Address_Type'First);
      end loop Initialize_Each_Job;
   end Initialize_Rekeying;

   --
   --  Primitive_Acceptable
   --
   function Primitive_Acceptable (Rkg : Rekeying_Type)
   return Boolean
   is (for some Job of Rkg.Jobs => Job.Operation = Invalid);

   --
   --  Submit_Primitive
   --
   procedure Submit_Primitive (
      Rkg  : in out Rekeying_Type;
      Prim :        Primitive.Object_Type)
   is
   begin
      Find_Invalid_Job :
      for Idx in Rkg.Jobs'Range loop
         if Rkg.Jobs (Idx).Operation = Invalid then
            case Primitive.Tag (Prim) is
            when Primitive.Tag_SB_Ctrl_VBD_Rkg =>

               Rkg.Jobs (Idx).Operation := Rekey_VBA;
               Rkg.Jobs (Idx).State := Submitted;
               Rkg.Jobs (Idx).Submitted_Prim := Prim;
               return;

            when others =>

               raise Program_Error;

            end case;
         end if;
      end loop Find_Invalid_Job;

      raise Program_Error;
   end Submit_Primitive;

   --
   --  Peek_Completed_Primitive
   --
   function Peek_Completed_Primitive (Rkg : Rekeying_Type)
   return Primitive.Object_Type
   is
   begin
      Find_Completed_Job :
      for Idx in Rkg.Jobs'Range loop
         if Rkg.Jobs (Idx).Operation /= Invalid and then
            Rkg.Jobs (Idx).State = Completed
         then
            return Rkg.Jobs (Idx).Submitted_Prim;
         end if;
      end loop Find_Completed_Job;
      return Primitive.Invalid_Object;
   end Peek_Completed_Primitive;

   --
   --  Drop_Completed_Primitive
   --
   procedure Drop_Completed_Primitive (
      Rkg  : in out Rekeying_Type;
      Prim :        Primitive.Object_Type)
   is
   begin
      Find_Corresponding_Job :
      for Idx in Rkg.Jobs'Range loop
         if Rkg.Jobs (Idx).Operation /= Invalid and then
            Rkg.Jobs (Idx).State = Completed and then
            Primitive.Equal (Prim, Rkg.Jobs (Idx).Submitted_Prim)
         then
            Rkg.Jobs (Idx).Operation := Invalid;
            return;
         end if;
      end loop Find_Corresponding_Job;
      raise Program_Error;
   end Drop_Completed_Primitive;

   --
   --  Execute_Rekey_VBA
   --
   procedure Execute_Rekey_VBA (
      Job      : in out Job_Type;
      Job_Idx  :        Jobs_Index_Type;
      Progress : in out Boolean)
   is
   begin

      case Job.State is
      when Submitted =>

         Job.Generated_Prim := Primitive.Valid_Object_No_Pool_Idx (
            Op     => Read,
            Succ   => False,
            Tg     => Primitive.Tag_VBD_Rkg_Cache,
            Blk_Nr => Block_Number_Type (Job.Snapshots (Job.Snapshot_Idx).PBA),
            Idx    => Primitive.Index_Type (Job_Idx));

         Job.State := Read_Root_Node_Pending;
         Progress := True;

      when others =>

         null;

      end case;

   end Execute_Rekey_VBA;

   --
   --  Execute
   --
   procedure Execute (
      Rkg      : in out Rekeying_Type;
      Progress : in out Boolean)
   is
   begin

      Execute_Each_Valid_Job :
      for Idx in Rkg.Jobs'Range loop

         case Rkg.Jobs (Idx).Operation is
         when Rekey_VBA =>

            Execute_Rekey_VBA (Rkg.Jobs (Idx), Idx, Progress);

         when Invalid =>

            null;

         end case;

      end loop Execute_Each_Valid_Job;

   end Execute;

   --
   --  Peek_Generated_Cache_Primitive
   --
   function Peek_Generated_Cache_Primitive (Rkg : Rekeying_Type)
   return Primitive.Object_Type
   is
   begin

      Inspect_Each_Job :
      for Idx in Rkg.Jobs'Range loop

         case Rkg.Jobs (Idx).Operation is
         when Rekey_VBA =>

            case Rkg.Jobs (Idx).State is
            when Read_Root_Node_Pending =>

               return Rkg.Jobs (Idx).Generated_Prim;

            when others =>

               null;

            end case;

         when others =>

            null;

         end case;

      end loop Inspect_Each_Job;
      return Primitive.Invalid_Object;

   end Peek_Generated_Cache_Primitive;

   --
   --  Peek_Generated_Blk_Data
   --
   function Peek_Generated_Blk_Data (
      Rkg  : in out Rekeying_Type;
      Prim :        Primitive.Object_Type)
   return Block_Data_Type
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));

      Blk_Data : Block_Data_Type;
   begin
      if Rkg.Jobs (Idx).Operation /= Invalid then

         case Rkg.Jobs (Idx).State is
         when Write_Root_Node_Pending =>

            if not Primitive.Equal (Prim, Rkg.Jobs (Idx).Generated_Prim) then
               raise Program_Error;
            end if;

            Block_Data_From_Type_1_Node_Block (
               Blk_Data, Rkg.Jobs (Idx).T1_Blks (Rkg.Jobs (Idx).T1_Blk_Idx));

            return Blk_Data;

         when others =>

            raise Program_Error;

         end case;

      end if;
      raise Program_Error;

   end Peek_Generated_Blk_Data;

   --
   --  Drop_Generated_Primitive
   --
   procedure Drop_Generated_Primitive (
      Rkg  : in out Rekeying_Type;
      Prim :        Primitive.Object_Type)
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin
      if Rkg.Jobs (Idx).Operation /= Invalid then

         case Rkg.Jobs (Idx).State is
         when Read_Root_Node_Pending =>

            if not Primitive.Equal (Prim, Rkg.Jobs (Idx).Generated_Prim) then
               raise Program_Error;
            end if;

            Rkg.Jobs (Idx).State := Read_Root_Node_In_Progress;
            return;

         when others =>

            raise Program_Error;

         end case;

      end if;
      raise Program_Error;

   end Drop_Generated_Primitive;

   --
   --  Mark_Generated_Prim_Completed_Blk_Data
   --
   procedure Mark_Generated_Prim_Completed_Blk_Data (
      Rkg      : in out Rekeying_Type;
      Prim     :        Primitive.Object_Type;
      Blk_Data :        Block_Data_Type)
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin
      if Rkg.Jobs (Idx).Operation /= Invalid then

         case Rkg.Jobs (Idx).State is
         when Read_Root_Node_In_Progress =>

            if not Primitive.Equal (Prim, Rkg.Jobs (Idx).Generated_Prim) then
               raise Program_Error;
            end if;

            Rkg.Jobs (Idx).State := Read_Root_Node_Completed;
            Rkg.Jobs (Idx).Generated_Prim := Prim;
            Type_1_Node_Block_From_Block_Data (
               Rkg.Jobs (Idx).T1_Blks (Rkg.Jobs (Idx).T1_Blk_Idx), Blk_Data);

            return;

         when others =>

            raise Program_Error;

         end case;

      end if;
      raise Program_Error;

   end Mark_Generated_Prim_Completed_Blk_Data;

   --
   --  Mark_Generated_Prim_Completed
   --
   procedure Mark_Generated_Prim_Completed (
      Rkg  : in out Rekeying_Type;
      Prim :        Primitive.Object_Type)
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin
      if Rkg.Jobs (Idx).Operation /= Invalid then

         case Rkg.Jobs (Idx).State is
         when Write_Root_Node_In_Progress =>

            if not Primitive.Equal (Prim, Rkg.Jobs (Idx).Generated_Prim) then
               raise Program_Error;
            end if;

            Rkg.Jobs (Idx).State := Write_Root_Node_Completed;
            Rkg.Jobs (Idx).Generated_Prim := Prim;
            return;

         when others =>

            raise Program_Error;

         end case;

      end if;
      raise Program_Error;

   end Mark_Generated_Prim_Completed;

end CBE.VBD_Rekeying;
