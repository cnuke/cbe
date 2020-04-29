--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

with CBE.Primitive;

package CBE.Trust_Anchor
with SPARK_Mode
is
   pragma Pure;

   type Anchor_Type is private;

   --
   --  Initialize_Anchor
   --
   procedure Initialize_Anchor (Anchor : out Anchor_Type);

   --
   --  Primitive_Acceptable
   --
   function Primitive_Acceptable (Anchor : Anchor_Type)
   return Boolean;

   --
   --  Submit_Primitive
   --
   procedure Submit_Primitive (
      Anchor : in out Anchor_Type;
      Prim   :        Primitive.Object_Type);

   --
   --  Submit_Primitive_Key_Plaintext
   --
   procedure Submit_Primitive_Key_Plaintext (
      Anchor : in out Anchor_Type;
      Prim   :        Primitive.Object_Type;
      Key    :        Key_Plaintext_Type);

   --
   --  Submit_Primitive_Hash
   --
   procedure Submit_Primitive_Hash (
      Anchor : in out Anchor_Type;
      Prim   :        Primitive.Object_Type;
      Hash   :        Hash_Type);

   --
   --  Peek_Completed_Primitive
   --
   function Peek_Completed_Primitive (Anchor : Anchor_Type)
   return Primitive.Object_Type;

   --
   --  Peek_Completed_Key_Plaintext
   --
   function Peek_Completed_Key_Plaintext (
      Anchor : Anchor_Type;
      Prim   : Primitive.Object_Type)
   return Key_Plaintext_Type;

   --
   --  Peek_Completed_Key_Ciphertext
   --
   function Peek_Completed_Key_Ciphertext (
      Anchor : Anchor_Type;
      Prim   : Primitive.Object_Type)
   return Key_Ciphertext_Type;

   --
   --  Drop_Completed_Primitive
   --
   procedure Drop_Completed_Primitive (
      Anchor : in out Anchor_Type;
      Prim :        Primitive.Object_Type);

   --
   --  Execute
   --
   procedure Execute (
      Anchor   : in out Anchor_Type;
      Progress : in out Boolean);

private

   Nr_Of_Jobs : constant := 2;

   type Jobs_Index_Type is range 0 .. Nr_Of_Jobs - 1;

   type Job_Operation_Type is (
      Invalid,
      Create_Key,
      Secure_Superblock,
      Encrypt_Key);

   type Job_State_Type is (
      Submitted,
      Completed);

   type Job_Type is record
      Operation : Job_Operation_Type;
      State : Job_State_Type;
      Submitted_Prim : Primitive.Object_Type;
      Key_Plaintext : Key_Plaintext_Type;
      Key_Ciphertext : Key_Ciphertext_Type;
      Hash : Hash_Type;
   end record;

   type Jobs_Type is array (Jobs_Index_Type) of Job_Type;

   type Anchor_Type is record
      Jobs : Jobs_Type;
      Next_Key_Plaintext_Byte : Byte_Type;
      Next_Key_Ciphertext_Byte : Byte_Type;
      Secured_SB_Hash : Hash_Type;
   end record;

   --
   --  Execute_Secure_SB
   --
   procedure Execute_Secure_SB (
      Anchor   : in out Anchor_Type;
      Idx      :        Jobs_Index_Type;
      Progress : in out Boolean);

   --
   --  Execute_Create_Key
   --
   procedure Execute_Create_Key (
      Anchor   : in out Anchor_Type;
      Idx      :        Jobs_Index_Type;
      Progress : in out Boolean);

   --
   --  Execute_Encrypt_Key
   --
   procedure Execute_Encrypt_Key (
      Anchor   : in out Anchor_Type;
      Idx      :        Jobs_Index_Type;
      Progress : in out Boolean);

end CBE.Trust_Anchor;
