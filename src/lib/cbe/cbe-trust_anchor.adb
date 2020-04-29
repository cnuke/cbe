--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

package body CBE.Trust_Anchor
with SPARK_Mode
is
   --
   --  Initialize_Anchor
   --
   procedure Initialize_Anchor (Anchor : out Anchor_Type)
   is
   begin
      Initialize_Each_Job :
      for Idx in Anchor.Jobs'Range loop

         Anchor.Jobs (Idx) := (
            Operation => Invalid,
            State => Job_State_Type'First,
            Submitted_Prim => Primitive.Invalid_Object,
            Key_Plaintext => (others => Byte_Type'First),
            Key_Ciphertext => (others => Byte_Type'First));

      end loop Initialize_Each_Job;

      Anchor.Next_Key_Plaintext_Byte := 65;
      Anchor.Next_Key_Ciphertext_Byte := 97;

   end Initialize_Anchor;

   --
   --  Primitive_Acceptable
   --
   function Primitive_Acceptable (Anchor : Anchor_Type)
   return Boolean
   is (for some Job of Anchor.Jobs => Job.Operation = Invalid);

   --
   --  Submit_Primitive
   --
   procedure Submit_Primitive (
      Anchor : in out Anchor_Type;
      Prim   :        Primitive.Object_Type)
   is
   begin
      Find_Invalid_Job :
      for Idx in Anchor.Jobs'Range loop
         if Anchor.Jobs (Idx).Operation = Invalid then
            case Primitive.Tag (Prim) is
            when Primitive.Tag_SB_Ctrl_TA_Create_Key =>

               Anchor.Jobs (Idx).Operation := Create_Key;
               Anchor.Jobs (Idx).State := Submitted;
               Anchor.Jobs (Idx).Submitted_Prim := Prim;
               return;

            when others =>

               raise Program_Error;

            end case;
         end if;
      end loop Find_Invalid_Job;

      raise Program_Error;
   end Submit_Primitive;

   --
   --  Submit_Primitive_Key_Plaintext
   --
   procedure Submit_Primitive_Key_Plaintext (
      Anchor : in out Anchor_Type;
      Prim   :        Primitive.Object_Type;
      Key    :        Key_Plaintext_Type)
   is
   begin
      Find_Invalid_Job :
      for Idx in Anchor.Jobs'Range loop
         if Anchor.Jobs (Idx).Operation = Invalid then
            case Primitive.Tag (Prim) is
            when Primitive.Tag_SB_Ctrl_TA_Encrypt_Key =>

               Anchor.Jobs (Idx).Operation := Encrypt_Key;
               Anchor.Jobs (Idx).State := Submitted;
               Anchor.Jobs (Idx).Submitted_Prim := Prim;
               Anchor.Jobs (Idx).Key_Plaintext := Key;
               return;

            when others =>

               raise Program_Error;

            end case;
         end if;
      end loop Find_Invalid_Job;

      raise Program_Error;
   end Submit_Primitive_Key_Plaintext;

   --
   --  Peek_Completed_Primitive
   --
   function Peek_Completed_Primitive (Anchor : Anchor_Type)
   return Primitive.Object_Type
   is
   begin
      Find_Completed_Job :
      for Idx in Anchor.Jobs'Range loop
         if Anchor.Jobs (Idx).Operation /= Invalid and then
            Anchor.Jobs (Idx).State = Completed
         then
            return Anchor.Jobs (Idx).Submitted_Prim;
         end if;
      end loop Find_Completed_Job;
      return Primitive.Invalid_Object;
   end Peek_Completed_Primitive;

   --
   --  Peek_Completed_Key_Plaintext
   --
   function Peek_Completed_Key_Plaintext (
      Anchor : Anchor_Type;
      Prim   : Primitive.Object_Type)
   return Key_Plaintext_Type
   is
   begin
      Find_Corresponding_Job :
      for Idx in Anchor.Jobs'Range loop
         if Anchor.Jobs (Idx).Operation = Create_Key and then
            Anchor.Jobs (Idx).State = Completed and then
            Primitive.Equal (Prim, Anchor.Jobs (Idx).Submitted_Prim)
         then
            return Anchor.Jobs (Idx).Key_Plaintext;
         end if;
      end loop Find_Corresponding_Job;
      raise Program_Error;
   end Peek_Completed_Key_Plaintext;

   --
   --  Peek_Completed_Key_Ciphertext
   --
   function Peek_Completed_Key_Ciphertext (
      Anchor : Anchor_Type;
      Prim   : Primitive.Object_Type)
   return Key_Ciphertext_Type
   is
   begin
      Find_Corresponding_Job :
      for Idx in Anchor.Jobs'Range loop

         if Anchor.Jobs (Idx).Operation = Encrypt_Key and then
            Anchor.Jobs (Idx).State = Completed and then
            Primitive.Equal (Prim, Anchor.Jobs (Idx).Submitted_Prim)
         then
            return Anchor.Jobs (Idx).Key_Ciphertext;
         end if;

      end loop Find_Corresponding_Job;
      raise Program_Error;

   end Peek_Completed_Key_Ciphertext;

   --
   --  Drop_Completed_Primitive
   --
   procedure Drop_Completed_Primitive (
      Anchor : in out Anchor_Type;
      Prim :        Primitive.Object_Type)
   is
   begin
      Find_Corresponding_Job :
      for Idx in Anchor.Jobs'Range loop
         if Anchor.Jobs (Idx).Operation /= Invalid and then
            Anchor.Jobs (Idx).State = Completed and then
            Primitive.Equal (Prim, Anchor.Jobs (Idx).Submitted_Prim)
         then
            Anchor.Jobs (Idx).Operation := Invalid;
            return;
         end if;
      end loop Find_Corresponding_Job;
      raise Program_Error;
   end Drop_Completed_Primitive;

   --
   --  Execute_Create_Key
   --
   procedure Execute_Create_Key (
      Anchor   : in out Anchor_Type;
      Idx      :        Jobs_Index_Type;
      Progress : in out Boolean)
   is
   begin
      case Anchor.Jobs (Idx).State is
      when Submitted =>

         Anchor.Jobs (Idx).Key_Plaintext := (
            others => Anchor.Next_Key_Plaintext_Byte);

         Anchor.Jobs (Idx).State := Completed;
         Anchor.Next_Key_Plaintext_Byte := Anchor.Next_Key_Plaintext_Byte + 1;
         Progress := True;

      when others =>

         null;

      end case;
   end Execute_Create_Key;

   --
   --  Execute_Encrypt_Key
   --
   procedure Execute_Encrypt_Key (
      Anchor   : in out Anchor_Type;
      Idx      :        Jobs_Index_Type;
      Progress : in out Boolean)
   is
   begin
      case Anchor.Jobs (Idx).State is
      when Submitted =>

         Anchor.Jobs (Idx).Key_Ciphertext := (
            others => Anchor.Next_Key_Ciphertext_Byte);

         Anchor.Jobs (Idx).State := Completed;
         Anchor.Next_Key_Ciphertext_Byte :=
            Anchor.Next_Key_Ciphertext_Byte + 1;

         Progress := True;

      when others =>

         null;

      end case;
   end Execute_Encrypt_Key;

   --
   --  Execute
   --
   procedure Execute (
      Anchor   : in out Anchor_Type;
      Progress : in out Boolean)
   is
   begin
      Execute_Each_Valid_Job :
      for Idx in Anchor.Jobs'Range loop

         case Anchor.Jobs (Idx).Operation is
         when Create_Key =>

            Execute_Create_Key (Anchor, Idx, Progress);

         when Encrypt_Key =>

            Execute_Encrypt_Key (Anchor, Idx, Progress);

         when Invalid =>

            null;

         end case;

      end loop Execute_Each_Valid_Job;
   end Execute;

end CBE.Trust_Anchor;
