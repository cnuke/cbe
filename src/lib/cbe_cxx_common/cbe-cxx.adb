--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

package body CBE.CXX
with SPARK_Mode
is
   --
   --  CXX_Key_From_SPARK
   --
   function CXX_Key_From_SPARK (SPARK_Key : Key_Plaintext_Type)
   return CXX_Key_Type
   is
      CXX_Key : CXX_Key_Type;
   begin
      for Idx in CXX_Key.Value'Range loop
         CXX_Key.Value (Idx) := CXX_UInt8_Type (SPARK_Key.Value (Idx));
      end loop;
      CXX_Key.ID := CXX_Key_ID_Type (SPARK_Key.ID);
      return CXX_Key;
   end CXX_Key_From_SPARK;

   --
   --  CXX_Bool_To_SPARK
   --
   function CXX_Bool_To_SPARK (Input : CXX_Bool_Type)
   return Boolean
   is
   begin
      case Input is
      when 0 => return False;
      when 1 => return True;
      when others => raise Program_Error;
      end case;
   end CXX_Bool_To_SPARK;

   --
   --  CXX_Request_To_SPARK
   --
   function CXX_Request_To_SPARK (Input : CXX_Request_Type)
   return Request.Object_Type
   is
   begin
      case Input.Operation is
      when  0 => return Request.Invalid_Object;
      when  1 => return CXX_Request_Valid_To_SPARK (Input, Read);
      when  2 => return CXX_Request_Valid_To_SPARK (Input, Write);
      when  3 => return CXX_Request_Valid_To_SPARK (Input, Sync);
      when  4 => return CXX_Request_Valid_To_SPARK (Input, Create_Snapshot);
      when  5 => return CXX_Request_Valid_To_SPARK (Input, Discard_Snapshot);
      when  6 => return CXX_Request_Valid_To_SPARK (Input, Rekey);
      when  7 => return CXX_Request_Valid_To_SPARK (Input, Extend_VBD);
      when  8 => return CXX_Request_Valid_To_SPARK (Input, Extend_FT);
      when 10 => return CXX_Request_Valid_To_SPARK (Input, Resume_Rekeying);
      when 11 => return CXX_Request_Valid_To_SPARK (Input, Deinitialize);
      when 12 => return CXX_Request_Valid_To_SPARK (Input, Initialize);
      when others => raise Program_Error;
      end case;
   end CXX_Request_To_SPARK;

end CBE.CXX;
