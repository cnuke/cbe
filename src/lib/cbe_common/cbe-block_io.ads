--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

with CBE.Primitive;
with CBE.Request;

package CBE.Block_IO
with SPARK_Mode
is
   pragma Pure;

   type Object_Type is private;

   type Data_Index_Type is range 0 .. 0;

   type Num_Entries_Type is range 0 .. Data_Index_Type'Last + 1;

   type Data_Type
   is array (Data_Index_Type) of Block_Data_Type with Size => Block_Size;

   --
   --  Initialize_Object
   --
   --  FIXME will not be used anymore when the library module is in spark
   --
   procedure Initialize_Object (Obj : out Object_Type);

   --
   --  Initialized_Object
   --
   function Initialized_Object
   return Object_Type;

   --
   --  Check if the module can accept new primitives
   --
   --  \return true if a primitive can be accepted, otherwise false
   --
   function Primitive_Acceptable (Obj : Object_Type) return Boolean;

   --
   --  Submit a new primitive
   --
   --  The primitive will be copied to the internal buffer and the Block_data
   --  reference will be stored as a reference. The method may only be called
   --  after 'acceptable' was executed and returned true. The new primitive is
   --  marked as pending and waits for execution.
   --
   --  \param Prim  reference to the Primitive
   --  \param Data  reference to a Block_data object
   --
   procedure Submit_Primitive (
      Obj  : in out Object_Type;
      Tag  :        Primitive.Tag_Type;
      Prim :        Primitive.Object_Type);

   procedure Submit_Primitive (
      Obj        : in out Object_Type;
      Tag        :        Primitive.Tag_Type;
      Prim       :        Primitive.Object_Type;
      Data_Index :    out Data_Index_Type);

   --
   --  Submit_Primitive_Req
   --
   procedure Submit_Primitive_Req (
      Obj  : in out Object_Type;
      Tag  :        Primitive.Tag_Type;
      Prim :        Primitive.Object_Type;
      Req  :        Request.Object_Type);

   --
   --  FIXME This function is currently only needed for reading actual data
   --        blocks (Tag_Decrypt). In this case we have to remember the
   --        expected hash - that we received from the VBD - somewhere until
   --        the data is available. The VBD forgets the hash once it has
   --        delivered the completed primitive.
   --
   procedure Submit_Primitive_Decrypt (
      Obj    : in out Object_Type;
      Prim   :        Primitive.Object_Type;
      Hash   :        Hash_Type;
      Key_ID :        Key_ID_Type);

   --
   --  Peek_Completed_Primitive
   --
   function Peek_Completed_Primitive (Obj : Object_Type)
   return Primitive.Object_Type;

   --
   --  Peek_Completed_Key_ID
   --
   function Peek_Completed_Key_ID (
      Obj  : Object_Type;
      Prim : Primitive.Object_Type)
   return Key_ID_Type;

   --
   --  Get access to the data of a completed primitive
   --
   --  This method must only be called after executing
   --  'peek_completed_primitive' returned a valid primitive.
   --
   --  \param Prim  reference to the completed primitive
   --
   --  \return reference to the data
   --
   function Peek_Completed_Data_Index (Obj : Object_Type)
   return Data_Index_Type;

   --
   --  Get the original tag of the submitted primitive
   --
   --  This method must only be called after executing
   --  'peek_completed_primitive' returned a valid primitive.
   --
   --  \param Prim  refrence to the completed primitive
   --
   --  \return original tag of the submitted primitive
   --
   function Peek_Completed_Tag (
      Obj  : Object_Type;
      Prim : Primitive.Object_Type)
   return Primitive.Tag_Type;

   function Peek_Completed_Hash (
      Obj  : Object_Type;
      Prim : Primitive.Object_Type)
   return Hash_Type;

   --
   --  Take the next completed primitive
   --
   --  This method must only be called after executing
   --  'peek_completed_primitive' returned true.
   --
   --  It takes next valid completed primitive and removes it
   --  from the module
   --
   procedure Drop_Completed_Primitive (
      Obj  : in out Object_Type;
      Prim :        Primitive.Object_Type);

   --
   --  Check for any generated primitive
   --
   --  The method will always a return a primitive and the caller
   --  always has to check if the returned primitive is in fact a
   --  valid one.
   --
   --  \return a valid Primitive will be returned if there is an
   --         generated primitive pending, otherwise an invalid one
   --
   function Peek_Generated_Primitive (Obj : Object_Type)
   return Primitive.Object_Type;

   --
   --  Get index for the data block of the generated primitive
   --
   --  This method must only be called after 'peek_generated_io_primitive'
   --  returned a valid primitive.
   --
   --  \param p  reference to the completed primitive
   --
   --  \return index for data block
   --
   function Peek_Generated_Data_Index (
      Obj  : Object_Type;
      Prim : Primitive.Object_Type)
   return Data_Index_Type;

   --
   --  Discard given generated primitive
   --
   --  This method must only be called after 'peek_generated_io_primitive'
   --  returned a valid primitive.
   --
   --  \param Prim  reference to primitive
   --
   procedure Drop_Generated_Primitive (
      Obj  : in out Object_Type;
      Prim :        Primitive.Object_Type);

   --
   --  Discard given generated primitive
   --
   --  This method must only be called after 'peek_generated_io_primitive'
   --  returned a valid primitive.
   --
   --  \param Prim  reference to primitive
   --
   procedure Drop_Generated_Primitive_2 (
      Obj      : in out Object_Type;
      Data_Idx :        Data_Index_Type);

   procedure Mark_Generated_Primitive_Complete (
      Obj      : in out Object_Type;
      Data_Idx :        Data_Index_Type;
      Success  :        Boolean);

private

   type Entry_State_Type is (Unused, Pending, In_Progress, Complete);

   type Entry_Type is record
      Orig_Tag   : Primitive.Tag_Type;
      Prim       : Primitive.Object_Type;
      Hash       : Hash_Type;
      Hash_Valid : Boolean;
      State      : Entry_State_Type;
      Key_ID     : Key_ID_Type;
      Req        : Request.Object_Type;
   end record;

   type Entries_Type is array (Data_Index_Type'Range) of Entry_Type;

   --
   --  Object_Type
   --
   type Object_Type is record
      Entries      : Entries_Type;
      Used_Entries : Num_Entries_Type;
   end record;

end CBE.Block_IO;
