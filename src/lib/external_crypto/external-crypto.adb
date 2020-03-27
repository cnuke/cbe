--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

package body External.Crypto
with SPARK_Mode
is
   --
   --  Initialize_Object
   --
   procedure Initialize_Object (Obj : out Object_Type)
   is
   begin
      Obj := Initialized_Object;
   end Initialize_Object;

   --
   --  Initialized_Object
   --
   function Initialized_Object
   return Object_Type
   is (
      Jobs => (others => Invalid_Job),
      Keys => (others => Invalid_Key));

   --
   --  Set_Key
   --
   procedure Set_Key (
      Obj      : in out Object_Type;
      Key_Idx  :        Keys_Index_Type;
      Key_ID   :        CBE.Key_ID_Type;
      Key_Data :        Key_Data_Type)
   is
   begin

      Obj.Keys (Key_Idx) := (
         Data  => Key_Data,
         ID    => Key_ID,
         Valid => True);

   end Set_Key;

   --
   --  Execute_Decrypt
   --
   procedure Execute_Decrypt (
      Job      : in out Job_Type;
      Keys     :        Keys_Type;
      Progress : in out Boolean)
   is
   begin

      case Job.State is
      when Submitted =>

         Aes_Cbc_4k.Decrypt (
            Keys (1).Data,
            Aes_Cbc_4k.Block_Number_Type (
               CBE.Request.Block_Number (Job.Request)),
            Job.Cipher_Data,
            Job.Plain_Data);

         CBE.Request.Success (Job.Request, True);
         Job.State := Completed;
         Progress := True;

      when Completed =>

         null;

      end case;

   end Execute_Decrypt;

   --
   --  Execute_Encrypt
   --
   procedure Execute_Encrypt (
      Job      : in out Job_Type;
      Keys     :        Keys_Type;
      Progress : in out Boolean)
   is
   begin

      case Job.State is
      when Submitted =>

         Aes_Cbc_4k.Encrypt (
            Keys (1).Data,
            Aes_Cbc_4k.Block_Number_Type (
               CBE.Request.Block_Number (Job.Request)),
            Job.Plain_Data,
            Job.Cipher_Data);

         Job.State := Completed;
         CBE.Request.Success (Job.Request, True);
         Progress := True;

      when Completed =>

         null;

      end case;

   end Execute_Encrypt;

   --
   --  Execute
   --
   procedure Execute (
      Obj      : in out Object_Type;
      Progress :    out Boolean)
   is
   begin
      Progress := False;

      For_Each_Job :
      for Idx in Obj.Jobs'Range loop

         case Obj.Jobs (Idx).Operation is
         when Encrypt =>

            Execute_Encrypt (Obj.Jobs (Idx), Obj.Keys, Progress);

         when Decrypt =>

            Execute_Decrypt (Obj.Jobs (Idx), Obj.Keys, Progress);

         when Invalid =>

            null;

         end case;

      end loop For_Each_Job;

   end Execute;

   --
   --  Encryption_Request_Acceptable
   --
   function Encryption_Request_Acceptable (Obj : Object_Type)
   return Boolean
   is (for some Job of Obj.Jobs => Job.Operation = Invalid);

   --
   --  Decryption_Request_Acceptable
   --
   function Decryption_Request_Acceptable (Obj : Object_Type)
   return Boolean
   is (for some Job of Obj.Jobs => Job.Operation = Invalid);

   --
   --  Submit_Encryption_Request
   --
   procedure Submit_Encryption_Request (
      Obj        : in out Object_Type;
      Request    :        CBE.Request.Object_Type;
      Plain_Data :        Plain_Data_Type)
   is
   begin

      Find_Invalid_Job :
      for Idx in Obj.Jobs'Range loop

         if Obj.Jobs (Idx).Operation = Invalid then
            Obj.Jobs (Idx).Operation := Encrypt;
            Obj.Jobs (Idx).State := Submitted;
            Obj.Jobs (Idx).Request := Request;
            Obj.Jobs (Idx).Plain_Data := Plain_Data;
            return;
         end if;

      end loop Find_Invalid_Job;
      raise Program_Error;

   end Submit_Encryption_Request;

   --
   --  Submit_Decryption_Request
   --
   procedure Submit_Decryption_Request (
      Obj         : in out Object_Type;
      Request     :        CBE.Request.Object_Type;
      Cipher_Data :        Cipher_Data_Type)
   is
   begin

      Find_Invalid_Job :
      for Idx in Obj.Jobs'Range loop

         if Obj.Jobs (Idx).Operation = Invalid then
            Obj.Jobs (Idx).Operation := Decrypt;
            Obj.Jobs (Idx).State := Submitted;
            Obj.Jobs (Idx).Request := Request;
            Obj.Jobs (Idx).Cipher_Data := Cipher_Data;
            return;
         end if;

      end loop Find_Invalid_Job;
      raise Program_Error;

   end Submit_Decryption_Request;

   --
   --  Peek_Completed_Encryption_Request
   --
   function Peek_Completed_Encryption_Request (Obj : Object_Type)
   return CBE.Request.Object_Type
   is
   begin

      Find_Completed_Encrypt_Job :
      for Idx in Obj.Jobs'Range loop

         if Obj.Jobs (Idx).Operation = Encrypt and then
            Obj.Jobs (Idx).State = Completed
         then
            return Obj.Jobs (Idx).Request;
         end if;

      end loop Find_Completed_Encrypt_Job;
      return CBE.Request.Invalid_Object;

   end Peek_Completed_Encryption_Request;

   --
   --  Peek_Completed_Decryption_Request
   --
   function Peek_Completed_Decryption_Request (Obj : Object_Type)
   return CBE.Request.Object_Type
   is
   begin

      Find_Completed_Decrypt_Job :
      for Idx in Obj.Jobs'Range loop

         if Obj.Jobs (Idx).Operation = Decrypt and then
            Obj.Jobs (Idx).State = Completed
         then
            return Obj.Jobs (Idx).Request;
         end if;

      end loop Find_Completed_Decrypt_Job;
      return CBE.Request.Invalid_Object;

   end Peek_Completed_Decryption_Request;

   --
   --  Supply_Cipher_Data
   --
   procedure Supply_Cipher_Data (
      Obj         : in out Object_Type;
      Request     :        CBE.Request.Object_Type;
      Cipher_Data :    out Cipher_Data_Type;
      Success     :    out Boolean)
   is
   begin
      Success := False;

      Find_Corresponding_Job :
      for Idx in Obj.Jobs'Range loop

         if CBE.Request.Equal (Request, Obj.Jobs (Idx).Request) then

            if Obj.Jobs (Idx).State /= Completed then
               return;
            end if;

            Cipher_Data := Obj.Jobs (Idx).Cipher_Data;
            Obj.Jobs (Idx).Operation := Invalid;
            Success := True;
            return;

         end if;

      end loop Find_Corresponding_Job;

   end Supply_Cipher_Data;

   --
   --  Supply_Plain_Data
   --
   procedure Supply_Plain_Data (
      Obj        : in out Object_Type;
      Request    :        CBE.Request.Object_Type;
      Plain_Data :    out Plain_Data_Type;
      Success    :    out Boolean)
   is
   begin
      Success := False;

      Find_Corresponding_Job :
      for Idx in Obj.Jobs'Range loop

         if CBE.Request.Equal (Request, Obj.Jobs (Idx).Request) then

            if Obj.Jobs (Idx).State /= Completed then
               return;
            end if;

            Plain_Data := Obj.Jobs (Idx).Plain_Data;
            Obj.Jobs (Idx).Operation := Invalid;
            Success := True;
            return;

         end if;

      end loop Find_Corresponding_Job;

   end Supply_Plain_Data;

   --
   --  Invalid_Key
   --
   function Invalid_Key
   return Key_Type
   is (
      Valid => False,
      Data  => (others => Aes_Cbc_4k.Byte'First),
      ID    => CBE.Key_ID_Type'First);

   --
   --  Invalid_Job
   --
   function Invalid_Job
   return Job_Type
   is (
      Operation   => Invalid,
      State       => Job_State_Type'First,
      Request     => CBE.Request.Invalid_Object,
      Cipher_Data => (others => Aes_Cbc_4k.Byte'First),
      Plain_Data  => (others => Aes_Cbc_4k.Byte'First));

end External.Crypto;
