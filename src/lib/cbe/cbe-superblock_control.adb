--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

package body CBE.Superblock_Control
with SPARK_Mode
is
   --
   --  Initialize_Control
   --
   procedure Initialize_Control (Ctrl : out Control_Type)
   is
   begin
      Initialize_Each_Job :
      for Idx in Ctrl.Jobs'Range loop
         Job_Initialize (Ctrl.Jobs (Idx));
      end loop Initialize_Each_Job;
   end Initialize_Control;

   --
   --  Primitive_Acceptable
   --
   function Primitive_Acceptable (Ctrl : Control_Type)
   return Boolean
   is (for some Job of Ctrl.Jobs => Job.Operation = Invalid);

   --
   --  Submit_Primitive
   --
   procedure Submit_Primitive (
      Ctrl : in out Control_Type;
      Prim :        Primitive.Object_Type)
   is
   begin
      Find_Invalid_Job :
      for Idx in Ctrl.Jobs'Range loop
         if Ctrl.Jobs (Idx).Operation = Invalid then
            case Primitive.Tag (Prim) is
            when Primitive.Tag_Pool_SB_Ctrl_Init_Rekey =>

               Ctrl.Jobs (Idx).Operation := Initialize_Rekeying;
               Ctrl.Jobs (Idx).State := Submitted;
               Ctrl.Jobs (Idx).Submitted_Prim := Prim;
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
   function Peek_Completed_Primitive (Ctrl : Control_Type)
   return Primitive.Object_Type
   is
   begin
      Find_Completed_Job :
      for Idx in Ctrl.Jobs'Range loop
         if Ctrl.Jobs (Idx).Operation /= Invalid and then
            Ctrl.Jobs (Idx).State = Completed
         then
            return Ctrl.Jobs (Idx).Submitted_Prim;
         end if;
      end loop Find_Completed_Job;
      return Primitive.Invalid_Object;
   end Peek_Completed_Primitive;

   --
   --  Drop_Completed_Primitive
   --
   procedure Drop_Completed_Primitive (
      Ctrl : in out Control_Type;
      Prim :        Primitive.Object_Type)
   is
   begin
      Find_Corresponding_Job :
      for Idx in Ctrl.Jobs'Range loop
         if Ctrl.Jobs (Idx).Operation /= Invalid and then
            Ctrl.Jobs (Idx).State = Completed and then
            Primitive.Equal (Prim, Ctrl.Jobs (Idx).Submitted_Prim)
         then
            Ctrl.Jobs (Idx).Operation := Invalid;
            return;
         end if;
      end loop Find_Corresponding_Job;
      raise Program_Error;
   end Drop_Completed_Primitive;

   --
   --  Execute_Initialize_Rekeying
   --
   procedure Execute_Initialize_Rekeying (
      Job      : in out Job_Type;
      Job_Idx  :        Jobs_Index_Type;
      Progress : in out Boolean)
   is
   begin
      case Job.State is
      when Submitted =>

         Job.Generated_Prim := Primitive.Valid_Object (
            Op     => Primitive_Operation_Type'First,
            Succ   => False,
            Tg     => Primitive.Tag_SB_Ctrl_TA_Create_Key,
            Pl_Idx => Pool_Index_Type'First,
            Blk_Nr => Block_Number_Type'First,
            Idx    => Primitive.Index_Type (Job_Idx));

         Job.State := Create_Key_Pending;
         Progress := True;

      when others =>

         null;

      end case;
   end Execute_Initialize_Rekeying;

   --
   --  Execute
   --
   procedure Execute (
      Ctrl     : in out Control_Type;
      Progress : in out Boolean)
   is
   begin
      Execute_Each_Valid_Job :
      for Idx in Ctrl.Jobs'Range loop
         case Ctrl.Jobs (Idx).Operation is
         when Initialize_Rekeying =>
            Execute_Initialize_Rekeying (Ctrl.Jobs (Idx), Idx, Progress);
         when Invalid =>
            null;
         end case;
      end loop Execute_Each_Valid_Job;
   end Execute;

   --
   --  Peek_Generated_TA_Primitive
   --
   function Peek_Generated_TA_Primitive (Ctrl : Control_Type)
   return Primitive.Object_Type
   is
   begin
      Inspect_Each_Job :
      for Idx in Ctrl.Jobs'Range loop
         case Ctrl.Jobs (Idx).Operation is
         when Initialize_Rekeying =>
            case Ctrl.Jobs (Idx).State is
            when Create_Key_Pending =>
               return Ctrl.Jobs (Idx).Generated_Prim;
            when others =>
               null;
            end case;
         when Invalid =>
            null;
         end case;
      end loop Inspect_Each_Job;
      return Primitive.Invalid_Object;
   end Peek_Generated_TA_Primitive;

   --
   --  Drop_Generated_Primitive
   --
   procedure Drop_Generated_Primitive (
      Ctrl : in out Control_Type;
      Prim :        Primitive.Object_Type)
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin
      if Ctrl.Jobs (Idx).Operation /= Invalid then
         case Ctrl.Jobs (Idx).State is
         when Create_Key_Pending =>
            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then
               Ctrl.Jobs (Idx).State := Create_Key_In_Progress;
               return;
            end if;
            raise Program_Error;
         when others =>
            raise Program_Error;
         end case;
      end if;
      raise Program_Error;
   end Drop_Generated_Primitive;

   --
   --  Mark_Generated_Primitive_Complete
   --
   procedure Mark_Generated_Primitive_Complete (
      Ctrl : in out Control_Type;
      Prim :        Primitive.Object_Type)
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin
      if Ctrl.Jobs (Idx).Operation /= Invalid then
         case Ctrl.Jobs (Idx).State is
         when Create_Key_In_Progress =>
            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Submitted_Prim) then
               Ctrl.Jobs (Idx).State := Create_Key_Completed;
               return;
            end if;
            raise Program_Error;
         when others =>
            raise Program_Error;
         end case;
      end if;
      raise Program_Error;
   end Mark_Generated_Primitive_Complete;

   --
   --  Job_Initialize
   --
   procedure Job_Initialize (Job : out Job_Type)
   is
   begin
      Job := (
         Operation => Invalid,
         State => Job_State_Type'First,
         Submitted_Prim => Primitive.Invalid_Object,
         Generated_Prim => Primitive.Invalid_Object);
   end Job_Initialize;

end CBE.Superblock_Control;
