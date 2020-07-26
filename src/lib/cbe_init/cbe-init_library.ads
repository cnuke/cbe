--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

with CBE.Superblock_Initializer;
with CBE.VBD_Initializer;
with CBE.Free_Tree_Initializer;
with CBE.Block_Allocator;
with CBE.Block_IO;
with CBE.Request;
with CBE.Trust_Anchor;
with CBE.TA_Request;

package CBE.Init_Library
with SPARK_Mode
is
   pragma Pure;

   type Object_Type is private;

   procedure Initialize_Object (Obj : out Object_Type);

   function Client_Request_Acceptable (Obj : Object_Type)
   return Boolean;

   procedure Submit_Client_Request (
      Obj             : in out Object_Type;
      Req             :        Request.Object_Type;
      VBD_Max_Lvl_Idx :        Tree_Level_Index_Type;
      VBD_Degree      :        Tree_Degree_Type;
      VBD_Nr_Of_Leafs :        Tree_Number_Of_Leafs_Type;
      FT_Max_Lvl_Idx  :        Tree_Level_Index_Type;
      FT_Degree       :        Tree_Degree_Type;
      FT_Nr_Of_Leafs  :        Tree_Number_Of_Leafs_Type);

   function Peek_Completed_Client_Request (Obj : Object_Type)
   return Request.Object_Type;

   procedure Drop_Completed_Client_Request (
      Obj : in out Object_Type;
      Req :        Request.Object_Type);

   procedure IO_Request_Completed (
      Obj        : in out Object_Type;
      Data_Index :        Block_IO.Data_Index_Type;
      Success    :        Boolean);

   procedure Has_IO_Request (
      Obj      :     Object_Type;
      Req      : out Request.Object_Type;
      Data_Idx : out Block_IO.Data_Index_Type);

   procedure IO_Request_In_Progress (
      Obj      : in out Object_Type;
      Data_Idx :        Block_IO.Data_Index_Type);

   procedure Peek_Generated_TA_Request (
      Obj :     Object_Type;
      Req : out TA_Request.Object_Type);

   procedure Drop_Generated_TA_Request (
      Obj : in out Object_Type;
      Req :        TA_Request.Object_Type);

   procedure Peek_Generated_TA_SB_Hash (
      Obj  :     Object_Type;
      Req  :     TA_Request.Object_Type;
      Hash : out Hash_Type);

   procedure Peek_Generated_TA_Key_Cipher (
      Obj       :     Object_Type;
      Req       :     TA_Request.Object_Type;
      Key_Value : out Key_Value_Ciphertext_Type);

   procedure Peek_Generated_TA_Key_Plain (
      Obj       :     Object_Type;
      Req       :     TA_Request.Object_Type;
      Key_Value : out Key_Value_Plaintext_Type);

   procedure Mark_Generated_TA_Create_Key_Request_Complete (
      Obj       : in out Object_Type;
      Req       :        TA_Request.Object_Type;
      Key_Value :        Key_Value_Plaintext_Type);

   procedure Mark_Generated_TA_Secure_SB_Request_Complete (
      Obj       : in out Object_Type;
      Req       :        TA_Request.Object_Type);

   procedure Mark_Generated_TA_Decrypt_Key_Request_Complete (
      Obj       : in out Object_Type;
      Req       :        TA_Request.Object_Type;
      Key_Value :        Key_Value_Plaintext_Type);

   procedure Mark_Generated_TA_Encrypt_Key_Request_Complete (
      Obj       : in out Object_Type;
      Req       :        TA_Request.Object_Type;
      Key_Value :        Key_Value_Ciphertext_Type);

   procedure Execute (
      Obj        : in out Object_Type;
      Blk_IO_Buf : in out Block_IO.Data_Type);

   function Execute_Progress (Obj : Object_Type)
   return Boolean;

private

   type Object_Type is record
      SB_Init             : Superblock_Initializer.Object_Type;
      VBD_Init            : VBD_Initializer.Object_Type;
      FT_Init             : Free_Tree_Initializer.Object_Type;
      Blk_Alloc           : Block_Allocator.Object_Type;
      Blk_IO              : Block_IO.Object_Type;
      Client_Req          : Request.Object_Type;
      Client_Req_Complete : Boolean;
      Execute_Progress    : Boolean;
      TA                  : Trust_Anchor.Anchor_Type;
   end record;

   procedure Execute_Superblock_Initializer (
      Obj        : in out Object_Type;
      Blk_IO_Buf : in out Block_IO.Data_Type;
      First_PBA  :        Physical_Block_Address_Type;
      Nr_Of_PBAs :        Number_Of_Blocks_Type);

   procedure Execute_VBD_Initializer (
      Obj        : in out Object_Type;
      Blk_IO_Buf : in out Block_IO.Data_Type);

   procedure Execute_Free_Tree_Initializer (
      Obj        : in out Object_Type;
      Blk_IO_Buf : in out Block_IO.Data_Type);

   procedure Execute_Block_Allocator (Obj : in out Object_Type);

   procedure Execute_Block_IO (Obj : in out Object_Type);

   procedure Execute_TA (Obj : in out Object_Type);

end CBE.Init_Library;
