--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

with CBE.Request;

package body CBE.CXX.CXX_Library
with SPARK_Mode
is
   function Object_Size (Obj : Library.Object_Type)
   return CXX_Object_Size_Type
   is (Obj'Size / 8);

   --
   --  Initialize_Object
   --
   procedure Initialize_Object (Obj : out Library.Object_Type)
   is
   begin
      Library.Initialize_Object (Obj);
   end Initialize_Object;

   --
   --  Info
   --
   procedure Info (
      Obj  :     Library.Object_Type;
      Info : out CXX_Info_Type)
   is
      SPARK_Info : Info_Type;
   begin
      Library.Info (Obj, SPARK_Info);
      Info := CXX_Info_From_SPARK (SPARK_Info);
   end Info;

   procedure Active_Snapshot_IDs (
      Obj :     Library.Object_Type;
      IDs : out Active_Snapshot_IDs_Type)
   is
   begin
      Library.Active_Snapshot_IDs (Obj, IDs);
   end Active_Snapshot_IDs;

   function Max_VBA (Obj : Library.Object_Type)
   return Virtual_Block_Address_Type
   is
   begin
      return Library.Max_VBA (Obj);
   end Max_VBA;

   --
   --  Execute
   --
   procedure Execute (
      Obj               : in out Library.Object_Type;
      IO_Buf            : in out Block_IO.Data_Type;
      Crypto_Plain_Buf  : in out Crypto.Plain_Buffer_Type;
      Crypto_Cipher_Buf : in out Crypto.Cipher_Buffer_Type)
   is
   begin
      Library.Execute (Obj, IO_Buf, Crypto_Plain_Buf, Crypto_Cipher_Buf);
   end Execute;

   function Client_Request_Acceptable (Obj : Library.Object_Type)
   return CXX_Bool_Type
   is (CXX_Bool_From_SPARK (Library.Client_Request_Acceptable (Obj)));

   procedure Submit_Client_Request (
      Obj : in out Library.Object_Type;
      Req :        CXX_Request_Type;
      ID  :        CXX_Snapshot_ID_Type)
   is
   begin
      Library.Submit_Client_Request (
         Obj, CXX_Request_To_SPARK (Req), Snapshot_ID_Type (ID));
   end Submit_Client_Request;

   function Peek_Completed_Client_Request (Obj : Library.Object_Type)
   return CXX_Request_Type
   is (
      CXX_Request_From_SPARK (
         Library.Peek_Completed_Client_Request (Obj)));

   procedure Drop_Completed_Client_Request (
      Obj : in out Library.Object_Type;
      Req :        CXX_Request_Type)
   is
   begin
      Library.Drop_Completed_Client_Request (Obj, CXX_Request_To_SPARK (Req));
   end Drop_Completed_Client_Request;

   procedure IO_Request_Completed (
      Obj        : in out Library.Object_Type;
      Data_Index :        CXX_Crypto_Cipher_Buffer_Index_Type;
      Success    :        CXX_Bool_Type)
   is
   begin
      Library.IO_Request_Completed (
         Obj, Block_IO.Data_Index_Type (Data_Index.Value),
         CXX_Bool_To_SPARK (Success));

   end IO_Request_Completed;

   procedure Has_IO_Request (
      Obj        :     Library.Object_Type;
      Req        : out CXX_Request_Type;
      Data_Index : out CXX_IO_Buffer_Index_Type)
   is
      SPARK_Req        : Request.Object_Type;
      SPARK_Data_Index : Block_IO.Data_Index_Type;
   begin
      Library.Has_IO_Request (Obj, SPARK_Req, SPARK_Data_Index);
      Req        := CXX_Request_From_SPARK (SPARK_Req);
      Data_Index := (Value => CXX_UInt32_Type (SPARK_Data_Index));
   end Has_IO_Request;

   procedure IO_Request_In_Progress (
      Obj        : in out Library.Object_Type;
      Data_Index :        CXX_IO_Buffer_Index_Type)
   is
   begin
      Library.IO_Request_In_Progress (
         Obj, Block_IO.Data_Index_Type (Data_Index.Value));
   end IO_Request_In_Progress;

   procedure Client_Data_Ready (
      Obj : in out Library.Object_Type;
      Req :    out CXX_Request_Type)
   is
      SPARK_Req : Request.Object_Type;
   begin
      Library.Client_Data_Ready (Obj, SPARK_Req);
      Req := CXX_Request_From_SPARK (SPARK_Req);
   end Client_Data_Ready;

   function Client_Data_Index (
      Obj : Library.Object_Type;
      Req : CXX_Request_Type)
   return CXX_Primitive_Index_Type
   is
   begin
      return CXX_Primitive_Index_Type (
         Library.Client_Data_Index (Obj, CXX_Request_To_SPARK (Req)));
   end Client_Data_Index;

   procedure Obtain_Client_Data (
      Obj              : in out Library.Object_Type;
      Req              :        CXX_Request_Type;
      Data_Index       :    out CXX_Crypto_Plain_Buffer_Index_Type;
      Data_Index_Valid :    out CXX_Bool_Type)
   is
      SPARK_Data_Index       : Crypto.Plain_Buffer_Index_Type;
      SPARK_Data_Index_Valid : Boolean;
   begin
      Library.Obtain_Client_Data (
         Obj, CXX_Request_To_SPARK (Req), SPARK_Data_Index,
         SPARK_Data_Index_Valid);

      Data_Index       := (Value => CXX_UInt32_Type (SPARK_Data_Index));
      Data_Index_Valid := CXX_Bool_From_SPARK (SPARK_Data_Index_Valid);
   end Obtain_Client_Data;

   procedure Client_Data_Required (
      Obj : in out Library.Object_Type;
      Req :    out CXX_Request_Type)
   is
      SPARK_Req : Request.Object_Type;
   begin
      Library.Client_Data_Required (Obj, SPARK_Req);
      Req := CXX_Request_From_SPARK (SPARK_Req);
   end Client_Data_Required;

   --
   --  Supply_Client_Data
   --
   procedure Supply_Client_Data (
      Obj      : in out Library.Object_Type;
      Req      :        CXX_Request_Type;
      Data     :        Block_Data_Type;
      Progress :    out CXX_Bool_Type)
   is
      SPARK_Progress : Boolean;
   begin
      Library.Supply_Client_Data (
         Obj, CXX_Request_To_SPARK (Req), Data, SPARK_Progress);
      Progress := CXX_Bool_From_SPARK (SPARK_Progress);
   end Supply_Client_Data;

   function Execute_Progress (Obj : Library.Object_Type)
   return CXX_Bool_Type
   is (CXX_Bool_From_SPARK (Library.Execute_Progress (Obj)));

   procedure Crypto_Add_Key_Required (
      Obj :     Library.Object_Type;
      Req : out CXX_Request_Type;
      Key : out CXX_Key_Type)
   is
      SPARK_Req : Request.Object_Type;
      SPARK_Key : Key_Plaintext_Type;
   begin
      Library.Crypto_Add_Key_Required (Obj, SPARK_Req, SPARK_Key);
      Req := CXX_Request_From_SPARK (SPARK_Req);
      Key := CXX_Key_From_SPARK (SPARK_Key);
   end Crypto_Add_Key_Required;

   procedure Crypto_Add_Key_Requested (
      Obj : in out Library.Object_Type;
      Req :        CXX_Request_Type)
   is
   begin
      Library.Crypto_Add_Key_Requested (Obj, CXX_Request_To_SPARK (Req));
   end Crypto_Add_Key_Requested;

   procedure Crypto_Add_Key_Completed (
      Obj : in out Library.Object_Type;
      Req :        CXX_Request_Type)
   is
   begin
      Library.Crypto_Add_Key_Completed (Obj, CXX_Request_To_SPARK (Req));
   end Crypto_Add_Key_Completed;

   procedure Crypto_Remove_Key_Required (
      Obj    :     Library.Object_Type;
      Req    : out CXX_Request_Type;
      Key_ID : out CXX_Key_ID_Type)
   is
      SPARK_Req : Request.Object_Type;
      SPARK_Key_ID : Key_ID_Type;
   begin
      Library.Crypto_Remove_Key_Required (Obj, SPARK_Req, SPARK_Key_ID);
      Req := CXX_Request_From_SPARK (SPARK_Req);
      Key_ID := CXX_Key_ID_Type (SPARK_Key_ID);
   end Crypto_Remove_Key_Required;

   procedure Crypto_Remove_Key_Requested (
      Obj : in out Library.Object_Type;
      Req :        CXX_Request_Type)
   is
   begin
      Library.Crypto_Remove_Key_Requested (Obj, CXX_Request_To_SPARK (Req));
   end Crypto_Remove_Key_Requested;

   procedure Crypto_Remove_Key_Completed (
      Obj : in out Library.Object_Type;
      Req :        CXX_Request_Type)
   is
   begin
      Library.Crypto_Remove_Key_Completed (Obj, CXX_Request_To_SPARK (Req));
   end Crypto_Remove_Key_Completed;

   procedure Crypto_Cipher_Data_Required (
      Obj        :     Library.Object_Type;
      Req        : out CXX_Request_Type;
      Data_Index : out CXX_Crypto_Plain_Buffer_Index_Type)
   is
      SPARK_Req        : Request.Object_Type;
      SPARK_Data_Index : Crypto.Plain_Buffer_Index_Type;
   begin
      Library.Crypto_Cipher_Data_Required (Obj, SPARK_Req, SPARK_Data_Index);
      Req        := CXX_Request_From_SPARK (SPARK_Req);
      Data_Index := (Value => CXX_UInt32_Type (SPARK_Data_Index));
   end Crypto_Cipher_Data_Required;

   procedure Crypto_Cipher_Data_Requested (
      Obj        : in out Library.Object_Type;
      Data_Index :        CXX_Crypto_Plain_Buffer_Index_Type)
   is
   begin
      Library.Crypto_Cipher_Data_Requested (
         Obj, Crypto.Plain_Buffer_Index_Type (Data_Index.Value));
   end Crypto_Cipher_Data_Requested;

   procedure Supply_Crypto_Cipher_Data (
      Obj        : in out Library.Object_Type;
      Data_Index :        CXX_Crypto_Cipher_Buffer_Index_Type;
      Data_Valid :        CXX_Bool_Type)
   is
   begin
      Library.Supply_Crypto_Cipher_Data (
         Obj, Crypto.Cipher_Buffer_Index_Type (Data_Index.Value),
         CXX_Bool_To_SPARK (Data_Valid));

   end Supply_Crypto_Cipher_Data;

   procedure Crypto_Plain_Data_Required (
      Obj        :     Library.Object_Type;
      Req        : out CXX_Request_Type;
      Data_Index : out CXX_Crypto_Cipher_Buffer_Index_Type)
   is
      SPARK_Req        : Request.Object_Type;
      SPARK_Data_Index : Crypto.Cipher_Buffer_Index_Type;
   begin
      Library.Crypto_Plain_Data_Required (Obj, SPARK_Req, SPARK_Data_Index);
      Req        := CXX_Request_From_SPARK (SPARK_Req);
      Data_Index := (Value => CXX_UInt32_Type (SPARK_Data_Index));
   end Crypto_Plain_Data_Required;

   procedure Crypto_Plain_Data_Requested (
      Obj        : in out Library.Object_Type;
      Data_Index :        CXX_Crypto_Cipher_Buffer_Index_Type)
   is
   begin
      Library.Crypto_Plain_Data_Requested (
         Obj, Crypto.Cipher_Buffer_Index_Type (Data_Index.Value));
   end Crypto_Plain_Data_Requested;

   procedure Supply_Crypto_Plain_Data (
      Obj        : in out Library.Object_Type;
      Data_Index :        CXX_Crypto_Plain_Buffer_Index_Type;
      Data_Valid :        CXX_Bool_Type)
   is
   begin
      Library.Supply_Crypto_Plain_Data (
         Obj, Crypto.Plain_Buffer_Index_Type (Data_Index.Value),
         CXX_Bool_To_SPARK (Data_Valid));
   end Supply_Crypto_Plain_Data;

end CBE.CXX.CXX_Library;
