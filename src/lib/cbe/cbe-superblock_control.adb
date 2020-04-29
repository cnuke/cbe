--
--  Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
--  This file is part of the Consistent Block Encrypter project, which is
--  distributed under the terms of the GNU Affero General Public License
--  version 3.
--

pragma Ada_2012;

with SHA256_4K;

package body CBE.Superblock_Control
with SPARK_Mode
is
   --
   --  CBE_Hash_From_SHA256_4K_Hash
   --
   procedure CBE_Hash_From_SHA256_4K_Hash (
      CBE_Hash : out Hash_Type;
      SHA_Hash :     SHA256_4K.Hash_Type);

   --
   --  SHA256_4K_Data_From_CBE_Data
   --
   procedure SHA256_4K_Data_From_CBE_Data (
      SHA_Data : out SHA256_4K.Data_Type;
      CBE_Data :     Block_Data_Type);

   --
   --  Hash_Of_Superblock
   --
   function Hash_Of_Superblock (SB : Superblock_Type)
   return Hash_Type;

   --
   --  CBE_Hash_From_SHA256_4K_Hash
   --
   procedure CBE_Hash_From_SHA256_4K_Hash (
      CBE_Hash : out Hash_Type;
      SHA_Hash :     SHA256_4K.Hash_Type)
   is
      SHA_Idx : SHA256_4K.Hash_Index_Type := SHA256_4K.Hash_Index_Type'First;
   begin
      for CBE_Idx in CBE_Hash'Range loop
         CBE_Hash (CBE_Idx) := Byte_Type (SHA_Hash (SHA_Idx));
         if CBE_Idx < CBE_Hash'Last then
            SHA_Idx := SHA_Idx + 1;
         end if;
      end loop;
   end CBE_Hash_From_SHA256_4K_Hash;

   --
   --  SHA256_4K_Data_From_CBE_Data
   --
   procedure SHA256_4K_Data_From_CBE_Data (
      SHA_Data : out SHA256_4K.Data_Type;
      CBE_Data :     Block_Data_Type)
   is
      CBE_Idx : Block_Data_Index_Type := Block_Data_Index_Type'First;
   begin
      for SHA_Idx in SHA_Data'Range loop
         SHA_Data (SHA_Idx) := SHA256_4K.Byte (CBE_Data (CBE_Idx));
         if SHA_Idx < SHA_Data'Last then
            CBE_Idx := CBE_Idx + 1;
         end if;
      end loop;
   end SHA256_4K_Data_From_CBE_Data;

   --
   --  Hash_Of_Superblock
   --
   function Hash_Of_Superblock (SB : Superblock_Type)
   return Hash_Type
   is
   begin
      Declare_Hash_Data :
      declare
         SHA_Hash : SHA256_4K.Hash_Type;
         SHA_Data : SHA256_4K.Data_Type;
         CBE_Data : Block_Data_Type;
         CBE_Hash : Hash_Type;
      begin
         Block_Data_From_Superblock (CBE_Data, SB);
         SHA256_4K_Data_From_CBE_Data (SHA_Data, CBE_Data);
         SHA256_4K.Hash (SHA_Data, SHA_Hash);
         CBE_Hash_From_SHA256_4K_Hash (CBE_Hash, SHA_Hash);
         return CBE_Hash;
      end Declare_Hash_Data;

   end Hash_Of_Superblock;

   --
   --  Initialize_Control
   --
   procedure Initialize_Control (Ctrl : out Control_Type)
   is
   begin
      Initialize_Each_Job :
      for Idx in Ctrl.Jobs'Range loop
         Ctrl.Jobs (Idx) := (
            Operation => Invalid,
            State => Job_State_Type'First,
            Submitted_Prim => Primitive.Invalid_Object,
            Generated_Prim => Primitive.Invalid_Object,
            Key_Plaintext => (others => Byte_Type'First),
            Key_Ciphertext => (others => Byte_Type'First),
            Generation => Generation_Type'First,
            Hash => (others => Byte_Type'First));
      end loop Initialize_Each_Job;
   end Initialize_Control;

   --
   --  Primitive_Acceptable
   --
   function Primitive_Acceptable (Ctrl : Control_Type)
   return Boolean
   is (for some Job of Ctrl.Jobs => Job.Operation = Invalid);

   --
   --  Submit_Primitive
   --
   procedure Submit_Primitive (
      Ctrl : in out Control_Type;
      Prim :        Primitive.Object_Type)
   is
   begin
      Find_Invalid_Job :
      for Idx in Ctrl.Jobs'Range loop
         if Ctrl.Jobs (Idx).Operation = Invalid then
            case Primitive.Tag (Prim) is
            when Primitive.Tag_Pool_SB_Ctrl_Init_Rekey =>

               Ctrl.Jobs (Idx).Operation := Initialize_Rekeying;
               Ctrl.Jobs (Idx).State := Submitted;
               Ctrl.Jobs (Idx).Submitted_Prim := Prim;
               return;

            when Primitive.Tag_Pool_SB_Ctrl_Rekey_VBA =>

               Ctrl.Jobs (Idx).Operation := Rekey_VBA;
               Ctrl.Jobs (Idx).State := Submitted;
               Ctrl.Jobs (Idx).Submitted_Prim := Prim;
               return;

            when others =>

               raise Program_Error;

            end case;
         end if;
      end loop Find_Invalid_Job;

      raise Program_Error;
   end Submit_Primitive;

   --
   --  Peek_Completed_Primitive
   --
   function Peek_Completed_Primitive (Ctrl : Control_Type)
   return Primitive.Object_Type
   is
   begin
      Find_Completed_Job :
      for Idx in Ctrl.Jobs'Range loop
         if Ctrl.Jobs (Idx).Operation /= Invalid and then
            Ctrl.Jobs (Idx).State = Completed
         then
            return Ctrl.Jobs (Idx).Submitted_Prim;
         end if;
      end loop Find_Completed_Job;
      return Primitive.Invalid_Object;
   end Peek_Completed_Primitive;

   --
   --  Drop_Completed_Primitive
   --
   procedure Drop_Completed_Primitive (
      Ctrl : in out Control_Type;
      Prim :        Primitive.Object_Type)
   is
   begin
      Find_Corresponding_Job :
      for Idx in Ctrl.Jobs'Range loop
         if Ctrl.Jobs (Idx).Operation /= Invalid and then
            Ctrl.Jobs (Idx).State = Completed and then
            Primitive.Equal (Prim, Ctrl.Jobs (Idx).Submitted_Prim)
         then
            Ctrl.Jobs (Idx).Operation := Invalid;
            return;
         end if;
      end loop Find_Corresponding_Job;
      raise Program_Error;
   end Drop_Completed_Primitive;

   --
   --  Superblock_Enter_Rekeying_State
   --
   procedure Superblock_Enter_Rekeying_State (
      SB            : in out Superblock_Type;
      Key_Plaintext :        Key_Plaintext_Type)
   is
   begin

      if SB.State /= Normal then
         raise Program_Error;
      end if;

      SB.State := Rekeying;
      SB.Rekeying_Curr_VBA := 0;

      Declare_Key_Indices :
      declare
         Oldest_Key_Idx : Keys_Index_Type := Keys_Index_Type'First;
         Newest_Key_Idx : Keys_Index_Type := Keys_Index_Type'First;
      begin

         For_Each_Key_In_SB :
         for Key_Idx in SB.Keys'Range loop
            if SB.Keys (Key_Idx).ID < SB.Keys (Oldest_Key_Idx).ID then
               Oldest_Key_Idx := Key_Idx;
            end if;
            if SB.Keys (Key_Idx).ID > SB.Keys (Newest_Key_Idx).ID then
               Newest_Key_Idx := Key_Idx;
            end if;
         end loop For_Each_Key_In_SB;

         SB.Keys (Oldest_Key_Idx) := (
            Value => Key_Plaintext,
            ID => SB.Keys (Newest_Key_Idx).ID + 1);

      end Declare_Key_Indices;

   end Superblock_Enter_Rekeying_State;

   --
   --  Execute_Initialize_Rekeying
   --
   procedure Execute_Initialize_Rekeying (
      Job      : in out Job_Type;
      Job_Idx  :        Jobs_Index_Type;
      SB       : in out Superblock_Type;
      SB_Idx   : in out Superblocks_Index_Type;
      Progress : in out Boolean)
   is
   begin

      case Job.State is
      when Submitted =>

         Job.Generated_Prim := Primitive.Valid_Object_No_Pool_Idx (
            Op     => Primitive_Operation_Type'First,
            Succ   => False,
            Tg     => Primitive.Tag_SB_Ctrl_TA_Create_Key,
            Blk_Nr => Block_Number_Type'First,
            Idx    => Primitive.Index_Type (Job_Idx));

         Job.State := Create_Key_Pending;
         Progress := True;

      when Create_Key_Completed =>

         if not Primitive.Success (Job.Generated_Prim) then
            raise Program_Error;
         end if;

         Superblock_Enter_Rekeying_State (SB, Job.Key_Plaintext);

         Job.Generated_Prim := Primitive.Valid_Object_No_Pool_Idx (
            Op     => Primitive_Operation_Type'First,
            Succ   => False,
            Tg     => Primitive.Tag_SB_Ctrl_TA_Encrypt_Key,
            Blk_Nr => Block_Number_Type'First,
            Idx    => Primitive.Index_Type (Job_Idx));

         Job.State := Encrypt_Key_Pending;
         Progress := True;

      when Encrypt_Key_Completed =>

         if not Primitive.Success (Job.Generated_Prim) then
            raise Program_Error;
         end if;

         Job.Generated_Prim := Primitive.Valid_Object_No_Pool_Idx (
            Op     => Sync,
            Succ   => False,
            Tg     => Primitive.Tag_SB_Ctrl_Cache,
            Blk_Nr => Block_Number_Type'First,
            Idx    => Primitive.Index_Type (Job_Idx));

         Job.State := Sync_Cache_Pending;
         Progress := True;

      when Sync_Cache_Completed =>

         if not Primitive.Success (Job.Generated_Prim) then
            raise Program_Error;
         end if;

         Job.Generated_Prim := Primitive.Valid_Object_No_Pool_Idx (
            Op     => Write,
            Succ   => False,
            Tg     => Primitive.Tag_SB_Ctrl_Blk_IO_Write_SB,
            Blk_Nr => Block_Number_Type (SB_Idx),
            Idx    => Primitive.Index_Type (Job_Idx));

         Job.State := Write_SB_Pending;
         Progress := True;

      when Write_SB_Completed =>

         if not Primitive.Success (Job.Generated_Prim) then
            raise Program_Error;
         end if;

         Job.Generated_Prim := Primitive.Valid_Object_No_Pool_Idx (
            Op     => Sync,
            Succ   => False,
            Tg     => Primitive.Tag_SB_Ctrl_Blk_IO_Sync,
            Blk_Nr => Block_Number_Type (SB_Idx),
            Idx    => Primitive.Index_Type (Job_Idx));

         Job.State := Sync_Blk_IO_Pending;
         Progress := True;

      when Sync_Blk_IO_Completed =>

         if not Primitive.Success (Job.Generated_Prim) then
            raise Program_Error;
         end if;

         Job.Hash := Hash_Of_Superblock (SB);
         Job.Generation := SB.Snapshots (SB.Curr_Snap).Gen;
         Job.Generated_Prim := Primitive.Valid_Object_No_Pool_Idx (
            Op     => Primitive_Operation_Type'First,
            Succ   => False,
            Tg     => Primitive.Tag_SB_Ctrl_TA_Secure_SB,
            Blk_Nr => Block_Number_Type'First,
            Idx    => Primitive.Index_Type (Job_Idx));

         Job.State := Secure_SB_Pending;

         if SB_Idx < Superblocks_Index_Type'Last then
            SB_Idx := SB_Idx + 1;
         else
            SB_Idx := Superblocks_Index_Type'First;
         end if;

         SB.Snapshots (SB.Curr_Snap).Gen :=
            SB.Snapshots (SB.Curr_Snap).Gen + 1;

         Progress := True;

      when Secure_SB_Completed =>

         if not Primitive.Success (Job.Generated_Prim) then
            raise Program_Error;
         end if;

         SB.Last_Secured_Generation := Job.Generation;
         Primitive.Success (Job.Submitted_Prim, True);
         Job.State := Completed;
         Progress := True;

      when others =>

         null;

      end case;

   end Execute_Initialize_Rekeying;

   --
   --  Execute_Rekey_VBA
   --
   procedure Execute_Rekey_VBA (
      Job      : in out Job_Type;
      Job_Idx  :        Jobs_Index_Type;
      SB       :        Superblock_Type;
      Progress : in out Boolean)
   is
   begin

      case Job.State is
      when Submitted =>

         if SB.State = Rekeying then

            Job.Generated_Prim := Primitive.Valid_Object_No_Pool_Idx (
               Op     => Primitive_Operation_Type'First,
               Succ   => False,
               Tg     => Primitive.Tag_SB_Ctrl_VBD_Rkg,
               Blk_Nr => Block_Number_Type'First,
               Idx    => Primitive.Index_Type (Job_Idx));

            Job.State := Rekey_VBA_In_VBD_Pending;
            Progress := True;

         else

            raise Program_Error;

         end if;

      when others =>

         null;

      end case;

   end Execute_Rekey_VBA;

   --
   --  Execute
   --
   procedure Execute (
      Ctrl     : in out Control_Type;
      SB       : in out Superblock_Type;
      SB_Idx   : in out Superblocks_Index_Type;
      Progress : in out Boolean)
   is
   begin

      Execute_Each_Valid_Job :
      for Idx in Ctrl.Jobs'Range loop

         case Ctrl.Jobs (Idx).Operation is
         when Initialize_Rekeying =>

            Execute_Initialize_Rekeying (
               Ctrl.Jobs (Idx), Idx, SB, SB_Idx, Progress);

         when Rekey_VBA =>

            Execute_Rekey_VBA (
               Ctrl.Jobs (Idx), Idx, SB, Progress);

         when Invalid =>

            null;

         end case;

      end loop Execute_Each_Valid_Job;

   end Execute;

   --
   --  Peek_Generated_TA_Primitive
   --
   function Peek_Generated_TA_Primitive (Ctrl : Control_Type)
   return Primitive.Object_Type
   is
   begin
      Inspect_Each_Job :
      for Idx in Ctrl.Jobs'Range loop

         case Ctrl.Jobs (Idx).Operation is
         when Initialize_Rekeying =>

            case Ctrl.Jobs (Idx).State is
            when Create_Key_Pending |
                 Encrypt_Key_Pending |
                 Secure_SB_Pending
            =>

               return Ctrl.Jobs (Idx).Generated_Prim;

            when others =>

               null;

            end case;

         when others =>

            null;

         end case;

      end loop Inspect_Each_Job;
      return Primitive.Invalid_Object;
   end Peek_Generated_TA_Primitive;

   --
   --  Peek_Generated_VBD_Rkg_Primitive
   --
   function Peek_Generated_VBD_Rkg_Primitive (Ctrl : Control_Type)
   return Primitive.Object_Type
   is
   begin
      Inspect_Each_Job :
      for Idx in Ctrl.Jobs'Range loop

         case Ctrl.Jobs (Idx).Operation is
         when Rekey_VBA =>

            case Ctrl.Jobs (Idx).State is
            when Rekey_VBA_In_VBD_Pending =>

               return Ctrl.Jobs (Idx).Generated_Prim;

            when others =>

               null;

            end case;

         when others =>

            null;

         end case;

      end loop Inspect_Each_Job;
      return Primitive.Invalid_Object;
   end Peek_Generated_VBD_Rkg_Primitive;

   --
   --  Peek_Generated_Hash
   --
   function Peek_Generated_Hash (
      Ctrl : Control_Type;
      Prim : Primitive.Object_Type)
   return Hash_Type
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin
      if Ctrl.Jobs (Idx).Operation /= Invalid then

         case Ctrl.Jobs (Idx).State is
         when Secure_SB_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then
               return Ctrl.Jobs (Idx).Hash;
            end if;
            raise Program_Error;

         when others =>

            raise Program_Error;

         end case;

      end if;
      raise Program_Error;

   end Peek_Generated_Hash;

   --
   --  Peek_Generated_VBA
   --
   function Peek_Generated_VBA (
      Ctrl : Control_Type;
      Prim : Primitive.Object_Type;
      SB   : Superblock_Type)
   return Virtual_Block_Address_Type
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin

      case Ctrl.Jobs (Idx).Operation is
      when Rekey_VBA =>

         case Ctrl.Jobs (Idx).State is
         when Rekey_VBA_In_VBD_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) and then
               SB.State = Rekeying
            then
               return SB.Rekeying_Curr_VBA;
            else
               raise Program_Error;
            end if;

         when others =>

            raise Program_Error;

         end case;

      when others =>

         raise Program_Error;

      end case;

   end Peek_Generated_VBA;

   --
   --  Peek_Generated_Snapshots
   --
   function Peek_Generated_Snapshots (
      Ctrl : Control_Type;
      Prim : Primitive.Object_Type;
      SB   : Superblock_Type)
   return Snapshots_Type
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin

      case Ctrl.Jobs (Idx).Operation is
      when Rekey_VBA =>

         case Ctrl.Jobs (Idx).State is
         when Rekey_VBA_In_VBD_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) and then
               SB.State = Rekeying
            then
               return SB.Snapshots;
            else
               raise Program_Error;
            end if;

         when others =>

            raise Program_Error;

         end case;

      when others =>

         raise Program_Error;

      end case;

   end Peek_Generated_Snapshots;

   --
   --  Peek_Generated_Snapshots_Degree
   --
   function Peek_Generated_Snapshots_Degree (
      Ctrl : Control_Type;
      Prim : Primitive.Object_Type;
      SB   : Superblock_Type)
   return Tree_Degree_Type
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin

      case Ctrl.Jobs (Idx).Operation is
      when Rekey_VBA =>

         case Ctrl.Jobs (Idx).State is
         when Rekey_VBA_In_VBD_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) and then
               SB.State = Rekeying
            then
               return SB.Degree;
            else
               raise Program_Error;
            end if;

         when others =>

            raise Program_Error;

         end case;

      when others =>

         raise Program_Error;

      end case;

   end Peek_Generated_Snapshots_Degree;

   --
   --  Peek_Generated_Old_Key_ID
   --
   function Peek_Generated_Old_Key_ID (
      Ctrl : Control_Type;
      Prim : Primitive.Object_Type;
      SB   : Superblock_Type)
   return Key_ID_Type
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin

      case Ctrl.Jobs (Idx).Operation is
      when Rekey_VBA =>

         case Ctrl.Jobs (Idx).State is
         when Rekey_VBA_In_VBD_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) and then
               SB.State = Rekeying
            then

               Declare_Key_Indices :
               declare
                  Oldest_Key_Idx : Keys_Index_Type := Keys_Index_Type'First;
               begin

                  For_Each_Key_Idx :
                  for Key_Idx in SB.Keys'Range loop

                     if SB.Keys (Key_Idx).ID < SB.Keys (Oldest_Key_Idx).ID then
                        Oldest_Key_Idx := Key_Idx;
                     end if;

                  end loop For_Each_Key_Idx;
                  return SB.Keys (Oldest_Key_Idx).ID;

               end Declare_Key_Indices;

            else

               raise Program_Error;

            end if;

         when others =>

            raise Program_Error;

         end case;

      when others =>

         raise Program_Error;

      end case;

   end Peek_Generated_Old_Key_ID;

   --
   --  Peek_Generated_New_Key_ID
   --
   function Peek_Generated_New_Key_ID (
      Ctrl : Control_Type;
      Prim : Primitive.Object_Type;
      SB   : Superblock_Type)
   return Key_ID_Type
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin

      case Ctrl.Jobs (Idx).Operation is
      when Rekey_VBA =>

         case Ctrl.Jobs (Idx).State is
         when Rekey_VBA_In_VBD_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) and then
               SB.State = Rekeying
            then

               Declare_Key_Indices :
               declare
                  Newest_Key_Idx : Keys_Index_Type := Keys_Index_Type'First;
               begin

                  For_Each_Key_Idx :
                  for Key_Idx in SB.Keys'Range loop

                     if SB.Keys (Key_Idx).ID > SB.Keys (Newest_Key_Idx).ID then
                        Newest_Key_Idx := Key_Idx;
                     end if;

                  end loop For_Each_Key_Idx;
                  return SB.Keys (Newest_Key_Idx).ID;

               end Declare_Key_Indices;

            else

               raise Program_Error;

            end if;

         when others =>

            raise Program_Error;

         end case;

      when others =>

         raise Program_Error;

      end case;

   end Peek_Generated_New_Key_ID;

   --
   --  Peek_Generated_Key_Plaintext
   --
   function Peek_Generated_Key_Plaintext (
      Ctrl : Control_Type;
      Prim : Primitive.Object_Type)
   return Key_Plaintext_Type
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin
      if Ctrl.Jobs (Idx).Operation /= Invalid then

         case Ctrl.Jobs (Idx).State is
         when Encrypt_Key_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then
               return Ctrl.Jobs (Idx).Key_Plaintext;
            end if;
            raise Program_Error;

         when others =>

            raise Program_Error;

         end case;

      end if;
      raise Program_Error;

   end Peek_Generated_Key_Plaintext;

   --
   --  Peek_Generated_Cache_Primitive
   --
   function Peek_Generated_Cache_Primitive (Ctrl : Control_Type)
   return Primitive.Object_Type
   is
   begin
      Inspect_Each_Job :
      for Idx in Ctrl.Jobs'Range loop

         case Ctrl.Jobs (Idx).Operation is
         when Initialize_Rekeying =>

            case Ctrl.Jobs (Idx).State is
            when Sync_Cache_Pending =>

               return Ctrl.Jobs (Idx).Generated_Prim;

            when others =>

               null;

            end case;

         when others =>

            null;

         end case;

      end loop Inspect_Each_Job;
      return Primitive.Invalid_Object;
   end Peek_Generated_Cache_Primitive;

   --
   --  Peek_Generated_Blk_IO_Primitive
   --
   function Peek_Generated_Blk_IO_Primitive (Ctrl : Control_Type)
   return Primitive.Object_Type
   is
   begin

      Inspect_Each_Job :
      for Idx in Ctrl.Jobs'Range loop

         case Ctrl.Jobs (Idx).Operation is
         when Initialize_Rekeying =>

            case Ctrl.Jobs (Idx).State is
            when Sync_Blk_IO_Pending | Write_SB_Pending =>

               return Ctrl.Jobs (Idx).Generated_Prim;

            when others =>

               null;

            end case;

         when others =>

            null;

         end case;

      end loop Inspect_Each_Job;
      return Primitive.Invalid_Object;

   end Peek_Generated_Blk_IO_Primitive;

   --
   --  Drop_Generated_Primitive
   --
   procedure Drop_Generated_Primitive (
      Ctrl : in out Control_Type;
      Prim :        Primitive.Object_Type)
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin
      if Ctrl.Jobs (Idx).Operation /= Invalid then

         case Ctrl.Jobs (Idx).State is
         when Create_Key_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then
               Ctrl.Jobs (Idx).State := Create_Key_In_Progress;
               return;
            end if;
            raise Program_Error;

         when Encrypt_Key_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then
               Ctrl.Jobs (Idx).State := Encrypt_Key_In_Progress;
               return;
            end if;
            raise Program_Error;

         when Sync_Cache_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then
               Ctrl.Jobs (Idx).State := Sync_Cache_In_Progress;
               return;
            end if;
            raise Program_Error;

         when Write_SB_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then
               Ctrl.Jobs (Idx).State := Write_SB_In_Progress;
               return;
            end if;
            raise Program_Error;

         when Sync_Blk_IO_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then
               Ctrl.Jobs (Idx).State := Sync_Blk_IO_In_Progress;
               return;
            end if;
            raise Program_Error;

         when Secure_SB_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then
               Ctrl.Jobs (Idx).State := Secure_SB_In_Progress;
               return;
            end if;
            raise Program_Error;

         when Rekey_VBA_In_VBD_Pending =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then
               Ctrl.Jobs (Idx).State := Rekey_VBA_In_VBD_In_Progress;
               return;
            end if;
            raise Program_Error;

         when others =>

            raise Program_Error;

         end case;

      end if;
      raise Program_Error;

   end Drop_Generated_Primitive;

   --
   --  Mark_Generated_Prim_Complete_Key_Plaintext
   --
   procedure Mark_Generated_Prim_Complete_Key_Plaintext (
      Ctrl : in out Control_Type;
      Prim :        Primitive.Object_Type;
      Key  :        Key_Plaintext_Type)
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin
      if Ctrl.Jobs (Idx).Operation /= Invalid then

         case Ctrl.Jobs (Idx).State is
         when Create_Key_In_Progress =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then
               Ctrl.Jobs (Idx).State := Create_Key_Completed;
               Ctrl.Jobs (Idx).Key_Plaintext := Key;
               Ctrl.Jobs (Idx).Generated_Prim := Prim;
               return;
            end if;
            raise Program_Error;

         when others =>

            raise Program_Error;

         end case;

      end if;
      raise Program_Error;

   end Mark_Generated_Prim_Complete_Key_Plaintext;

   --
   --  Mark_Generated_Prim_Complete_Key_Ciphertext
   --
   procedure Mark_Generated_Prim_Complete_Key_Ciphertext (
      Ctrl : in out Control_Type;
      Prim :        Primitive.Object_Type;
      Key  :        Key_Ciphertext_Type)
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin
      if Ctrl.Jobs (Idx).Operation /= Invalid then

         case Ctrl.Jobs (Idx).State is
         when Encrypt_Key_In_Progress =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then

               Ctrl.Jobs (Idx).State := Encrypt_Key_Completed;
               Ctrl.Jobs (Idx).Key_Ciphertext := Key;
               Ctrl.Jobs (Idx).Generated_Prim := Prim;
               return;

            end if;
            raise Program_Error;

         when others =>

            raise Program_Error;

         end case;

      end if;
      raise Program_Error;

   end Mark_Generated_Prim_Complete_Key_Ciphertext;

   --
   --  Mark_Generated_Prim_Complete
   --
   procedure Mark_Generated_Prim_Complete (
      Ctrl : in out Control_Type;
      Prim :        Primitive.Object_Type)
   is
      Idx : constant Jobs_Index_Type :=
         Jobs_Index_Type (Primitive.Index (Prim));
   begin
      if Ctrl.Jobs (Idx).Operation /= Invalid then

         case Ctrl.Jobs (Idx).State is
         when Sync_Cache_In_Progress =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then

               Ctrl.Jobs (Idx).State := Sync_Cache_Completed;
               Ctrl.Jobs (Idx).Generated_Prim := Prim;
               return;

            end if;
            raise Program_Error;

         when Write_SB_In_Progress =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then

               Ctrl.Jobs (Idx).State := Write_SB_Completed;
               Ctrl.Jobs (Idx).Generated_Prim := Prim;
               return;

            end if;
            raise Program_Error;

         when Sync_Blk_IO_In_Progress =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then

               Ctrl.Jobs (Idx).State := Sync_Blk_IO_Completed;
               Ctrl.Jobs (Idx).Generated_Prim := Prim;
               return;

            end if;
            raise Program_Error;

         when Secure_SB_In_Progress =>

            if Primitive.Equal (Prim, Ctrl.Jobs (Idx).Generated_Prim) then

               Ctrl.Jobs (Idx).State := Secure_SB_Completed;
               Ctrl.Jobs (Idx).Generated_Prim := Prim;
               return;

            end if;
            raise Program_Error;

         when others =>

            raise Program_Error;

         end case;

      end if;
      raise Program_Error;

   end Mark_Generated_Prim_Complete;

end CBE.Superblock_Control;
