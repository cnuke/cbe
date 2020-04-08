--
--  Copyright (C) 2020 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

with CBE.Primitive;

package CBE.Sync_Superblock
with SPARK_Mode
is
   pragma Pure;

   type Object_Type is private;

   --
   --  Initialize_Object
   --
   procedure Initialize_Object (Obj : out Object_Type);

   --
   --  Request_Acceptable
   --
   function Request_Acceptable (Obj : Object_Type)
   return Boolean;

   --
   --  Submit_Request
   --
   procedure Submit_Request (
      Obj        : out Object_Type;
      Pool_Index :     Pool_Index_Type;
      Idx        :     Superblocks_Index_Type;
      Gen        :     Generation_Type);

   --
   --  Execute
   --
   procedure Execute (
      Obj      : in out Object_Type;
      Progress : in out Boolean);

   --
   --  Peek_Completed_Primitive
   --
   function Peek_Completed_Primitive (Obj : Object_Type)
   return Primitive.Object_Type;

   --
   --  Peek_Completed_Generation
   --
   function Peek_Completed_Generation (
      Obj  : Object_Type;
      Prim : Primitive.Object_Type)
   return Generation_Type;

   --
   --  Drop_Completed_Primitive
   --
   procedure Drop_Completed_Primitive (
      Obj  : in out Object_Type;
      Prim :        Primitive.Object_Type)
   with
      Pre => Primitive.Valid (Prim);

   --
   --  Peek_Generated_Primitive
   --
   function Peek_Generated_Primitive (Obj : Object_Type)
   return Primitive.Object_Type;

   --
   --  Drop_Generated_Primitive
   --
   procedure Drop_Generated_Primitive (
      Obj  : in out Object_Type;
      Prim :        Primitive.Object_Type)
   with
      Pre => Primitive.Valid (Prim);

   --
   --  Mark_Generated_Primitive_Complete
   --
   procedure Mark_Generated_Primitive_Complete (
      Obj  : in out Object_Type;
      Prim :        Primitive.Object_Type);

private

   type State_Type is (
      Invalid,
      Cache_Flush_Pending,
      Cache_Flush_In_Progress,
      Cache_Flush_Complete,
      Write_SB_Pending,
      Write_SB_In_Progress,
      Write_SB_Complete,
      Sync_Pending,
      Sync_In_Progress,
      Sync_Complete);

   function To_String (State : State_Type) return String
   is (
      case State is
      when Invalid                 => "Invalid",
      when Cache_Flush_Pending     => "Cache_Flush_Pending",
      when Cache_Flush_In_Progress => "Cache_Flush_In_Progress",
      when Cache_Flush_Complete    => "Cache_Flush_Complete",
      when Write_SB_Pending        => "Write_SB_Pending",
      when Write_SB_In_Progress    => "Write_SB_In_Progress",
      when Write_SB_Complete       => "Write_SB_Complete",
      when Sync_Pending            => "Sync_Pending",
      when Sync_In_Progress        => "Sync_In_Progress",
      when Sync_Complete           => "Sync_Complete");

   type Object_Type is record
      State           : State_Type;
      Index           : Superblocks_Index_Type;
      Pool_Index_Slot : Pool_Index_Slot_Type;
      Gen             : Generation_Type;
      Success         : Boolean;
   end record;

end CBE.Sync_Superblock;
