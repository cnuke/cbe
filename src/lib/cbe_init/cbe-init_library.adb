--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

with CBE.Primitive;

package body CBE.Init_Library
with SPARK_Mode
is
   procedure Initialize_Object (Obj : out Object_Type)
   is
   begin
      Superblock_Initializer.Initialize_Object (Obj.SB_Init);
      VBD_Initializer.Initialize_Object (Obj.VBD_Init);
      Free_Tree_Initializer.Initialize_Object (Obj.FT_Init);
      Block_Allocator.Initialize_Object (
         Obj.Blk_Alloc, Nr_Of_Superblock_Slots);

      Obj.Blk_IO := Block_IO.Initialized_Object;
      Obj.Client_Req := Request.Invalid_Object;
      Obj.Client_Req_Complete := False;
      Obj.Execute_Progress := False;
      Trust_Anchor.Initialize_Anchor (Obj.TA);
   end Initialize_Object;

   function Client_Request_Acceptable (Obj : Object_Type)
   return Boolean
   is (Superblock_Initializer.Primitive_Acceptable (Obj.SB_Init));

   procedure Submit_Client_Request (
      Obj             : in out Object_Type;
      Req             :        Request.Object_Type;
      VBD_Max_Lvl_Idx :        Tree_Level_Index_Type;
      VBD_Degree      :        Tree_Degree_Type;
      VBD_Nr_Of_Leafs :        Tree_Number_Of_Leafs_Type;
      FT_Max_Lvl_Idx  :        Tree_Level_Index_Type;
      FT_Degree       :        Tree_Degree_Type;
      FT_Nr_Of_Leafs  :        Tree_Number_Of_Leafs_Type)
   is
   begin
      Superblock_Initializer.Submit_Primitive (
         Obj.SB_Init,
         Primitive.Valid_Object_No_Pool_Idx (
            Read, False, Primitive.Tag_Lib_SB_Init, 0, 0),
         VBD_Max_Lvl_Idx,
         VBD_Degree,
         VBD_Nr_Of_Leafs,
         FT_Max_Lvl_Idx,
         FT_Degree,
         FT_Nr_Of_Leafs,
         --  calculate MT data
         FT_Max_Lvl_Idx,
         FT_Degree,
         FT_Nr_Of_Leafs);

      Obj.Client_Req := Req;

   end Submit_Client_Request;

   function Peek_Completed_Client_Request (Obj : Object_Type)
   return Request.Object_Type
   is
   begin
      if not Obj.Client_Req_Complete then
         return Request.Invalid_Object;
      end if;
      return Obj.Client_Req;
   end Peek_Completed_Client_Request;

   procedure Drop_Completed_Client_Request (
      Obj : in out Object_Type;
      Req :        Request.Object_Type)
   is
   begin
      if not Request.Equal (Obj.Client_Req, Req) or else
         not Obj.Client_Req_Complete
      then
         raise Program_Error;
      end if;
      Obj.Client_Req := Request.Invalid_Object;
      Obj.Client_Req_Complete := False;
   end Drop_Completed_Client_Request;

   procedure Execute_Superblock_Initializer (
      Obj        : in out Object_Type;
      Blk_IO_Buf : in out Block_IO.Data_Type;
      First_PBA  :        Physical_Block_Address_Type;
      Nr_Of_PBAs :        Number_Of_Blocks_Type)
   is
   begin

      --
      --  Poke state machine of superblock initialization
      --
      Superblock_Initializer.Execute (Obj.SB_Init, First_PBA, Nr_Of_PBAs);
      if Superblock_Initializer.Execute_Progress (Obj.SB_Init) then
         Obj.Execute_Progress := True;
      end if;

      --
      --  Handle primitives generated by superblock initialization
      --
      Loop_SB_Init_Generated_Prims :
      loop
         Declare_SB_Init_Generated_Prim :
         declare
            Prim : constant Primitive.Object_Type :=
               Superblock_Initializer.Peek_Generated_Primitive (
                  Obj.SB_Init);
         begin
            exit Loop_SB_Init_Generated_Prims when
               not Primitive.Valid (Prim);

            if Primitive.Has_Tag_SB_Init_Blk_IO (Prim) then

               exit Loop_SB_Init_Generated_Prims when
                  not Block_IO.Primitive_Acceptable (Obj.Blk_IO);

               Declare_Data_Idx_1 :
               declare
                  Data_Idx : Block_IO.Data_Index_Type;
               begin

                  Block_IO.Submit_Primitive (
                     Obj.Blk_IO, Primitive.Tag_SB_Init_Blk_IO, Prim, Data_Idx);

                  case Primitive.Operation (Prim) is
                  when Sync =>

                     null;

                  when others =>

                     Blk_IO_Buf (Data_Idx) :=
                        Superblock_Initializer.Peek_Generated_Data (
                           Obj.SB_Init, Prim);

                  end case;

                  Superblock_Initializer.Drop_Generated_Primitive (
                     Obj.SB_Init, Prim);

                  Obj.Execute_Progress := True;

               end Declare_Data_Idx_1;

            elsif Primitive.Has_Tag_SB_Init_VBD_Init (Prim) then

               if VBD_Initializer.Primitive_Acceptable (Obj.VBD_Init) then

                  VBD_Initializer.Submit_Primitive (
                     Obj.VBD_Init, Prim,
                     Superblock_Initializer.Peek_Generated_Max_Lvl_Idx (
                        Obj.SB_Init, Prim),
                     Superblock_Initializer.Peek_Generated_Max_Child_Idx (
                        Obj.SB_Init, Prim),
                     Superblock_Initializer.Peek_Generated_Nr_Of_Leafs (
                        Obj.SB_Init, Prim));

                  Superblock_Initializer.Drop_Generated_Primitive (
                     Obj.SB_Init, Prim);

                  Obj.Execute_Progress := True;

               end if;

            elsif Primitive.Has_Tag_SB_Init_FT_Init (Prim) then

               if Free_Tree_Initializer.Primitive_Acceptable (Obj.FT_Init) then

                  Free_Tree_Initializer.Submit_Primitive (
                     Obj.FT_Init, Prim,
                     Superblock_Initializer.Peek_Generated_Max_Lvl_Idx (
                        Obj.SB_Init, Prim),
                     Superblock_Initializer.Peek_Generated_Max_Child_Idx (
                        Obj.SB_Init, Prim),
                     Superblock_Initializer.Peek_Generated_Nr_Of_Leafs (
                        Obj.SB_Init, Prim));

                  Superblock_Initializer.Drop_Generated_Primitive (
                     Obj.SB_Init, Prim);

                  Obj.Execute_Progress := True;

               end if;

            elsif Primitive.Has_Tag_SB_Init_MT_Init (Prim) then

               if Free_Tree_Initializer.Primitive_Acceptable (Obj.FT_Init) then

                  Free_Tree_Initializer.Submit_Primitive (
                     Obj.FT_Init, Prim,
                     Superblock_Initializer.Peek_Generated_Max_Lvl_Idx (
                        Obj.SB_Init, Prim),
                     Superblock_Initializer.Peek_Generated_Max_Child_Idx (
                        Obj.SB_Init, Prim),
                     Superblock_Initializer.Peek_Generated_Nr_Of_Leafs (
                        Obj.SB_Init, Prim));

                  Superblock_Initializer.Drop_Generated_Primitive (
                     Obj.SB_Init, Prim);

                  Obj.Execute_Progress := True;

               end if;

            elsif Primitive.Has_Tag_SB_Init_TA_Create_Key (Prim) then

               if Trust_Anchor.Primitive_Acceptable (Obj.TA) then

                  Trust_Anchor.Submit_Primitive (Obj.TA, Prim);

                  Superblock_Initializer.Drop_Generated_Primitive (
                     Obj.SB_Init, Prim);

                  Obj.Execute_Progress := True;

               end if;

            elsif Primitive.Has_Tag_SB_Init_TA_Encrypt_Key (Prim) then

               if Trust_Anchor.Primitive_Acceptable (Obj.TA) then

                  Trust_Anchor.Submit_Primitive_Key_Value_Plaintext (
                     Obj.TA, Prim,
                     Superblock_Initializer.Peek_Generated_Key_Value_Plaintext
                        (Obj.SB_Init, Prim));

                  Superblock_Initializer.Drop_Generated_Primitive (
                     Obj.SB_Init, Prim);

                  Obj.Execute_Progress := True;

               end if;

            else
               raise Program_Error;
            end if;

         end Declare_SB_Init_Generated_Prim;

      end loop Loop_SB_Init_Generated_Prims;

      if Primitive.Equal (
            Primitive.Valid_Object_No_Pool_Idx (
               Read, False, Primitive.Tag_Lib_SB_Init, 0, 0),
            Superblock_Initializer.Peek_Completed_Primitive (Obj.SB_Init))
      then
         Request.Success (Obj.Client_Req, True);
         Obj.Client_Req_Complete := True;
         Superblock_Initializer.Drop_Completed_Primitive (
            Obj.SB_Init,
            Primitive.Valid_Object_No_Pool_Idx (
               Read, False, Primitive.Tag_Lib_SB_Init, 0, 0));
      end if;

   end Execute_Superblock_Initializer;

   procedure Execute_VBD_Initializer (
      Obj        : in out Object_Type;
      Blk_IO_Buf : in out Block_IO.Data_Type)
   is
   begin

      --
      --  Poke state machine of VBD initialization
      --
      VBD_Initializer.Execute (Obj.VBD_Init);
      if VBD_Initializer.Execute_Progress (Obj.VBD_Init) then
         Obj.Execute_Progress := True;
      end if;

      --
      --  Handle primitives generated by VBD initialization
      --
      Loop_VBD_Init_Generated_Prims :
      loop
         Declare_VBD_Init_Generated_Prim :
         declare
            Prim : constant Primitive.Object_Type :=
               VBD_Initializer.Peek_Generated_Primitive (
                  Obj.VBD_Init);
         begin
            exit Loop_VBD_Init_Generated_Prims when
               not Primitive.Valid (Prim);

            if Primitive.Has_Tag_VBD_Init_Blk_Alloc (Prim) then

               exit Loop_VBD_Init_Generated_Prims when
                  not Block_Allocator.Primitive_Acceptable (Obj.Blk_Alloc);

               Block_Allocator.Submit_Primitive (Obj.Blk_Alloc, Prim);
               Obj.Execute_Progress := True;

            elsif Primitive.Has_Tag_VBD_Init_Blk_IO (Prim) then

               exit Loop_VBD_Init_Generated_Prims when
                  not Block_IO.Primitive_Acceptable (Obj.Blk_IO);

               Declare_Data_Idx_3 :
               declare
                  Data_Idx : Block_IO.Data_Index_Type;
               begin

                  Block_IO.Submit_Primitive (
                     Obj.Blk_IO, Primitive.Tag_VBD_Init_Blk_IO, Prim,
                     Data_Idx);

                  Blk_IO_Buf (Data_Idx) :=
                     VBD_Initializer.Peek_Generated_Data (
                        Obj.VBD_Init, Prim);

                  Obj.Execute_Progress := True;

               end Declare_Data_Idx_3;
            else
               raise Program_Error;
            end if;

            VBD_Initializer.Drop_Generated_Primitive (Obj.VBD_Init, Prim);

         end Declare_VBD_Init_Generated_Prim;

      end loop Loop_VBD_Init_Generated_Prims;

      --
      --  Handle primitives completed by VBD initialization
      --
      Loop_VBD_Init_Completed_Prims :
      loop
         Declare_VBD_Init_Completed_Prim :
         declare
            Prim : constant Primitive.Object_Type :=
               VBD_Initializer.Peek_Completed_Primitive (Obj.VBD_Init);
         begin
            exit Loop_VBD_Init_Completed_Prims when
               not Primitive.Valid (Prim);

            if Primitive.Has_Tag_SB_Init_VBD_Init (Prim) then

               Superblock_Initializer.
                  Mark_Generated_VBD_Init_Primitive_Complete (
                     Obj.SB_Init, Prim,
                     VBD_Initializer.Peek_Completed_Root (Obj.VBD_Init, Prim));

               Obj.Execute_Progress := True;
            else
               raise Program_Error;
            end if;

            VBD_Initializer.Drop_Completed_Primitive (Obj.VBD_Init, Prim);

         end Declare_VBD_Init_Completed_Prim;

      end loop Loop_VBD_Init_Completed_Prims;

   end Execute_VBD_Initializer;

   procedure Execute_Free_Tree_Initializer (
      Obj        : in out Object_Type;
      Blk_IO_Buf : in out Block_IO.Data_Type)
   is
   begin

      --
      --  Poke state machine of free-tree initialization
      --
      Free_Tree_Initializer.Execute (Obj.FT_Init);
      if Free_Tree_Initializer.Execute_Progress (Obj.FT_Init) then
         Obj.Execute_Progress := True;
      end if;

      --
      --  Handle primitives generated by free-tree initialization
      --
      Loop_FT_Init_Generated_Prims :
      loop
         Declare_FT_Init_Generated_Prim :
         declare
            Prim : constant Primitive.Object_Type :=
               Free_Tree_Initializer.Peek_Generated_Primitive (
                  Obj.FT_Init);
         begin
            exit Loop_FT_Init_Generated_Prims when
               not Primitive.Valid (Prim);

            if Primitive.Has_Tag_FT_Init_Blk_Alloc (Prim) then

               exit Loop_FT_Init_Generated_Prims when
                  not Block_Allocator.Primitive_Acceptable (Obj.Blk_Alloc);

               Block_Allocator.Submit_Primitive (Obj.Blk_Alloc, Prim);
               Obj.Execute_Progress := True;

            elsif Primitive.Has_Tag_FT_Init_Blk_IO (Prim) then

               exit Loop_FT_Init_Generated_Prims when
                  not Block_IO.Primitive_Acceptable (Obj.Blk_IO);

               Declare_Data_Idx_4 :
               declare
                  Data_Idx : Block_IO.Data_Index_Type;
               begin

                  Block_IO.Submit_Primitive (
                     Obj.Blk_IO, Primitive.Tag_FT_Init_Blk_IO, Prim, Data_Idx);

                  Blk_IO_Buf (Data_Idx) :=
                     Free_Tree_Initializer.Peek_Generated_Data (
                        Obj.FT_Init, Prim);

                  Obj.Execute_Progress := True;

               end Declare_Data_Idx_4;
            else
               raise Program_Error;
            end if;

            Free_Tree_Initializer.Drop_Generated_Primitive (Obj.FT_Init, Prim);

         end Declare_FT_Init_Generated_Prim;

      end loop Loop_FT_Init_Generated_Prims;

      --
      --  Handle primitives completed by free-tree initialization
      --
      Loop_FT_Init_Completed_Prims :
      loop
         Declare_FT_Init_Completed_Prim :
         declare
            Prim : constant Primitive.Object_Type :=
               Free_Tree_Initializer.Peek_Completed_Primitive (Obj.FT_Init);
         begin
            exit Loop_FT_Init_Completed_Prims when
               not Primitive.Valid (Prim);

            if Primitive.Has_Tag_SB_Init_FT_Init (Prim) then

               Superblock_Initializer.
                  Mark_Generated_FT_Init_Primitive_Complete (
                     Obj.SB_Init, Prim,
                     Free_Tree_Initializer.Peek_Completed_Root (
                        Obj.FT_Init, Prim));

               Obj.Execute_Progress := True;

            elsif Primitive.Has_Tag_SB_Init_MT_Init (Prim) then

               Superblock_Initializer.
                  Mark_Generated_FT_Init_Primitive_Complete (
                     Obj.SB_Init, Prim,
                     Free_Tree_Initializer.Peek_Completed_Root (
                        Obj.FT_Init, Prim));

               Obj.Execute_Progress := True;

            else
               raise Program_Error;
            end if;

            Free_Tree_Initializer.Drop_Completed_Primitive (Obj.FT_Init, Prim);

         end Declare_FT_Init_Completed_Prim;

      end loop Loop_FT_Init_Completed_Prims;

   end Execute_Free_Tree_Initializer;
   procedure Execute_Block_Allocator (Obj : in out Object_Type)
   is
   begin

      --
      --  Poke state machine of block allocator
      --
      Block_Allocator.Execute (Obj.Blk_Alloc);
      if Block_Allocator.Execute_Progress (Obj.Blk_Alloc) then
         Obj.Execute_Progress := True;
      end if;

      --
      --  Handle primitives completed by block allocator
      --
      Loop_Blk_Alloc_Completed_Prims :
      loop
         Declare_Blk_Alloc_Completed_Prim :
         declare
            Prim : constant Primitive.Object_Type :=
               Block_Allocator.Peek_Completed_Primitive (
                  Obj.Blk_Alloc);
         begin
            exit Loop_Blk_Alloc_Completed_Prims when
               not Primitive.Valid (Prim);

            if Primitive.Has_Tag_VBD_Init_Blk_Alloc (Prim) then

               VBD_Initializer.Mark_Generated_Primitive_Complete (
                  Obj.VBD_Init, Prim);

               Obj.Execute_Progress := True;

            elsif Primitive.Has_Tag_FT_Init_Blk_Alloc (Prim) then

               Free_Tree_Initializer.Mark_Generated_Primitive_Complete (
                  Obj.FT_Init, Prim);

               Obj.Execute_Progress := True;

            else
               raise Program_Error;
            end if;

            Block_Allocator.Drop_Completed_Primitive (Obj.Blk_Alloc, Prim);

         end Declare_Blk_Alloc_Completed_Prim;

      end loop Loop_Blk_Alloc_Completed_Prims;

   end Execute_Block_Allocator;

   procedure Execute_Block_IO (Obj : in out Object_Type)
   is
   begin
      Loop_Completed_Prims :
      loop
         Declare_Prim :
         declare
            Prim : constant Primitive.Object_Type :=
               Block_IO.Peek_Completed_Primitive (Obj.Blk_IO);
         begin
            exit Loop_Completed_Prims when not Primitive.Valid (Prim);

            if not Primitive.Success (Prim) then
               raise Program_Error;
            end if;

            if Primitive.Has_Tag_SB_Init_Blk_IO (Prim) then

               Superblock_Initializer.
                  Mark_Generated_Blk_IO_Primitive_Complete (
                     Obj.SB_Init, Prim);

            elsif Primitive.Has_Tag_VBD_Init_Blk_IO (Prim) then

               VBD_Initializer.Mark_Generated_Primitive_Complete (
                  Obj.VBD_Init, Prim);

            elsif Primitive.Has_Tag_FT_Init_Blk_IO (Prim) then

               Free_Tree_Initializer.Mark_Generated_Primitive_Complete (
                  Obj.FT_Init, Prim);

            else
               raise Program_Error;
            end if;

            Block_IO.Drop_Completed_Primitive (Obj.Blk_IO, Prim);

         end Declare_Prim;
         Obj.Execute_Progress := True;

      end loop Loop_Completed_Prims;
   end Execute_Block_IO;

   procedure Execute_TA (Obj : in out Object_Type)
   is
   begin
      Trust_Anchor.Execute (Obj.TA, Obj.Execute_Progress);
      Loop_Completed_TA_Prims :
      loop
         Declare_TA_Prim :
         declare
            Prim : constant Primitive.Object_Type :=
               Trust_Anchor.Peek_Completed_Primitive (Obj.TA);
         begin
            exit Loop_Completed_TA_Prims when not Primitive.Valid (Prim);

            if Primitive.Has_Tag_SB_Init_TA_Create_Key (Prim) then

               Superblock_Initializer.Mark_Generated_TA_CK_Primitive_Complete
                  (Obj.SB_Init, Prim,
                   Trust_Anchor.Peek_Completed_Key_Value_Plaintext (
                      Obj.TA, Prim));

            elsif Primitive.Has_Tag_SB_Init_TA_Encrypt_Key (Prim) then

               Superblock_Initializer.Mark_Generated_TA_EK_Primitive_Complete
                  (Obj.SB_Init, Prim,
                   Trust_Anchor.Peek_Completed_Key_Value_Ciphertext (
                      Obj.TA, Prim));

            else

               raise Program_Error;

            end if;

            Trust_Anchor.Drop_Completed_Primitive (Obj.TA, Prim);

         end Declare_TA_Prim;
         Obj.Execute_Progress := True;

      end loop Loop_Completed_TA_Prims;
   end Execute_TA;

   procedure Execute (
      Obj        : in out Object_Type;
      Blk_IO_Buf : in out Block_IO.Data_Type)
   is
   begin
      Obj.Execute_Progress := False;

      Execute_Superblock_Initializer (
         Obj, Blk_IO_Buf,
         Physical_Block_Address_Type (
            Block_Allocator.Peek_First_Blk (Obj.Blk_Alloc) -
               Nr_Of_Superblock_Slots),
         Block_Allocator.Peek_Nr_Of_Blks (Obj.Blk_Alloc) +
            Nr_Of_Superblock_Slots);

      Execute_VBD_Initializer (Obj, Blk_IO_Buf);
      Execute_Free_Tree_Initializer (Obj, Blk_IO_Buf);
      Execute_Block_Allocator (Obj);
      Execute_Block_IO (Obj);
      Execute_TA (Obj);
   end Execute;

   function Execute_Progress (Obj : Object_Type)
   return Boolean
   is (Obj.Execute_Progress);

   --
   --  Has_IO_Request
   --
   procedure Has_IO_Request (
      Obj      :     Object_Type;
      Req      : out Request.Object_Type;
      Data_Idx : out Block_IO.Data_Index_Type)
   is
      Prim : constant Primitive.Object_Type :=
         Block_IO.Peek_Generated_Blk_Dev_Primitive (Obj.Blk_IO);
   begin

      if Primitive.Valid (Prim) then

         Data_Idx := Block_IO.Peek_Generated_Data_Index (Obj.Blk_IO, Prim);
         Req      := Request.Valid_Object (
            Op     => Prim_Op_To_Req_Op (Primitive.Operation (Prim)),
            Succ   => False,
            Blk_Nr => Primitive.Block_Number (Prim),
            Off    => 0,
            Cnt    => 1,
            Key    => 0,
            Tg     => 0);

      else

         Req := Request.Invalid_Object;
         Data_Idx := Block_IO.Data_Index_Type'First;

      end if;

   end Has_IO_Request;

   procedure IO_Request_In_Progress (
      Obj      : in out Object_Type;
      Data_Idx :        Block_IO.Data_Index_Type)
   is
   begin
      Block_IO.Drop_Generated_Primitive_2 (Obj.Blk_IO, Data_Idx);
   end IO_Request_In_Progress;

   procedure IO_Request_Completed (
      Obj        : in out Object_Type;
      Data_Index :        Block_IO.Data_Index_Type;
      Success    :        Boolean)
   is
   begin
      Block_IO.Mark_Generated_Primitive_Complete (
         Obj.Blk_IO, Data_Index, Success);
   end IO_Request_Completed;

end CBE.Init_Library;
