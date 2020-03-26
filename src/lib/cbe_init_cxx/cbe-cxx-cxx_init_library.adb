--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

with CBE.Request;

package body CBE.CXX.CXX_Init_Library
with SPARK_Mode
is
   function Object_Size (Obj : Init_Library.Object_Type)
   return CXX_Object_Size_Type
   is (Obj'Size / 8);

   procedure Initialize_Object (Obj : out Init_Library.Object_Type)
   is
   begin
      Init_Library.Initialize_Object (Obj);
   end Initialize_Object;

   function Client_Request_Acceptable (Obj : Init_Library.Object_Type)
   return CXX_Bool_Type
   is (CXX_Bool_From_SPARK (Init_Library.Client_Request_Acceptable (Obj)));

   procedure Submit_Client_Request (
      Obj             : in out Init_Library.Object_Type;
      Req             :        CXX_Request_Type;
      Key_ID          :        CXX_Key_ID_Type;
      VBD_Max_Lvl_Idx :        CXX_Tree_Level_Index_Type;
      VBD_Degree      :        CXX_Tree_Degree_Type;
      VBD_Nr_Of_Leafs :        CXX_Tree_Number_Of_Leafs_Type;
      FT_Max_Lvl_Idx  :        CXX_Tree_Level_Index_Type;
      FT_Degree       :        CXX_Tree_Degree_Type;
      FT_Nr_Of_Leafs  :        CXX_Tree_Number_Of_Leafs_Type)
   is
   begin
      Init_Library.Submit_Client_Request (
         Obj, CXX_Request_To_SPARK (Req),
         Key_ID_Type (Key_ID),
         Tree_Level_Index_Type (VBD_Max_Lvl_Idx),
         Tree_Degree_Type (VBD_Degree),
         Tree_Number_Of_Leafs_Type (VBD_Nr_Of_Leafs),
         Tree_Level_Index_Type (FT_Max_Lvl_Idx),
         Tree_Degree_Type (FT_Degree),
         Tree_Number_Of_Leafs_Type (FT_Nr_Of_Leafs));

   end Submit_Client_Request;

   function Peek_Completed_Client_Request (Obj : Init_Library.Object_Type)
   return CXX_Request_Type
   is (
      CXX_Request_From_SPARK (
         Init_Library.Peek_Completed_Client_Request (Obj)));

   procedure Drop_Completed_Client_Request (
      Obj : in out Init_Library.Object_Type;
      Req :        CXX_Request_Type)
   is
   begin
      Init_Library.Drop_Completed_Client_Request (
         Obj, CXX_Request_To_SPARK (Req));
   end Drop_Completed_Client_Request;

   procedure Execute (
      Obj    : in out Init_Library.Object_Type;
      IO_Buf : in out Block_IO.Data_Type)
   is
   begin
      Init_Library.Execute (Obj, IO_Buf);
   end Execute;

   function Execute_Progress (Obj : Init_Library.Object_Type)
   return CXX_Bool_Type
   is (CXX_Bool_From_SPARK (Init_Library.Execute_Progress (Obj)));

   procedure IO_Request_Completed (
      Obj        : in out Init_Library.Object_Type;
      Data_Index :        CXX_Crypto_Cipher_Buffer_Index_Type;
      Success    :        CXX_Bool_Type)
   is
   begin
      Init_Library.IO_Request_Completed (
         Obj, Block_IO.Data_Index_Type (Data_Index.Value),
         CXX_Bool_To_SPARK (Success));

   end IO_Request_Completed;

   procedure Has_IO_Request (
      Obj        :     Init_Library.Object_Type;
      Req        : out CXX_Request_Type;
      Data_Index : out CXX_IO_Buffer_Index_Type)
   is
      SPARK_Req        : Request.Object_Type;
      SPARK_Data_Index : Block_IO.Data_Index_Type;
   begin
      Init_Library.Has_IO_Request (Obj, SPARK_Req, SPARK_Data_Index);
      Req        := CXX_Request_From_SPARK (SPARK_Req);
      Data_Index := (Value => CXX_UInt32_Type (SPARK_Data_Index));
   end Has_IO_Request;

   procedure IO_Request_In_Progress (
      Obj        : in out Init_Library.Object_Type;
      Data_Index :        CXX_IO_Buffer_Index_Type)
   is
   begin
      Init_Library.IO_Request_In_Progress (
         Obj, Block_IO.Data_Index_Type (Data_Index.Value));
   end IO_Request_In_Progress;

end CBE.CXX.CXX_Init_Library;
