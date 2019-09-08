--
-- Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
-- This file is part of the Consistent Block Encrypter project, which is
-- distributed under the terms of the GNU Affero General Public License
-- version 3.
--

pragma Ada_2012;

with CBE.Pool;
with CBE.Splitter;
with CBE.Crypto;
with CBE.Cache;
with CBE.Cache_Flusher;
with CBE.Virtual_Block_Device;
with CBE.Write_Back;
with CBE.Sync_Superblock;
with CBE.Free_Tree;
with CBE.Block_IO;
with CBE.Request;
with CBE.Primitive;

package CBE.Library
with Spark_Mode
is
--	FIXME cannot be pure yet because of CBE.Crypto
--	pragma Pure;

	type Object_Type is private;

	--
	-- Constructor
	--
	-- \param  now     current time as timestamp
	-- \param  sync    interval in ms after which the current generation
	--                 should be sealed
	-- \param  secure  interval in ms after which the current super-block
	--                 should be secured
	-- \param  block   reference to the Block::Connection used by the I/O
	--                 module
	-- \param  sbs     array of all super-blocks, will be copied
	--
	-- \param  current_sb  super-block that should be used initially
	--
	procedure Initialize_Object (
		Obj     : out Object_Type;
		Now     :     Timestamp_Type;
		Sync    :     Timestamp_Type;
		Secure  :     Timestamp_Type;
		SBs     :     Super_Blocks_Type;
		Curr_SB :     Super_Blocks_Index_Type);

	--
	-- Return a timeout request with the objective of synchronization
	-- generated by the CBE during a previous operation. If the returned
	-- timeout request is invalid, then no timeout request is pending.
	--
	function Peek_Sync_Timeout_Request (Obj : Object_Type)
	return Timeout_Request_Type;

	--
	-- Return a timeout request with the objective of securing
	-- generated by the CBE during a previous operation. If the returned
	-- timeout request is invalid, then no timeout request is pending.
	--
	function Peek_Secure_Timeout_Request (Obj : Object_Type)
	return Timeout_Request_Type;

	--
	-- Ackowledge that a synchronization timeout has been set according
	-- to the previously peek'd timeout request of the CBE
	--
	procedure Ack_Sync_Timeout_Request (Obj : in out Object_Type);

	--
	-- Ackowledge that a securing timeout has been set according
	-- to the previously peek'd timeout request of the CBE
	--
	procedure Ack_Secure_Timeout_Request (Obj : in out Object_Type);

	--
	-- Check if the CBE can accept a new requeust
	--
	-- \return true if a request can be accepted, otherwise false
	--
	function Request_Acceptable (Obj : Object_Type)
	return Boolean;

	--
	-- Submit a new request
	--
	-- This method must only be called after executing 'Request_Acceptable'
	-- returned true.
	--
	-- \param Req  block request
	--
	procedure Submit_Request (
		Obj : in out Object_Type;
		Req :        Request.Object_Type);

	--
	-- Check for any completed request
	--
	-- \return a valid block request will be returned if there is an
	--         completed request, otherwise an invalid one
	--
	function Peek_Completed_Request (Obj : Object_Type)
	return Request.Object_Type;

	--
	-- Drops the completed request
	--
	-- This method must only be called after executing
	-- 'Peek_Completed_Request' returned a valid request.
	--
	procedure Drop_Completed_Request (
		Obj : in out Object_Type;
		Req :        Request.Object_Type);

	--
	-- Return a request for the backend block session
	--
	-- \param Req  return valid request in case the is one pending that
	--             needs data, otherwise an invalid one is returned
	--
	procedure Need_Data (
		Obj : in out Object_Type;
		Req :    out Request.Object_Type);

	--
	-- Take read request for backend block session
	--
	-- \param Req       reference to the request from the CBE
	-- \param Progress  return true if the CBE could process the request
	--
	procedure Take_Read_Data (
		Obj      : in out Object_Type;
		Req      :        Request.Object_Type;
		Progress :    out Boolean);

	--
	-- Acknowledge read request to the backend block session
	--
	-- The given data will be transfered to the CBE.
	--
	-- \param Req       reference to the request from the CBE
	-- \param Data      reference to the data associated with the request
	-- \param Progress  return true if the CBE acknowledged the request
	--
	procedure Ack_Read_Data (
		Obj      : in out Object_Type;
		Req      :        Request.Object_Type;
		Data     :        Block_Data_Type;
		Progress :    out Boolean);

	--
	-- Take write request for the backend block session
	--
	-- The CBE will transfer the payload to the given data.
	--
	-- \param Req       reference to the request processed by the CBE
	-- \param Data      reference to the data associated with the request
	-- \param Progress  return true if the CBE could process the request
	--
	procedure Take_Write_Data (
		Obj      : in out Object_Type;
		Req      :        Request.Object_Type;
		Data     :    out Block_Data_Type;
		Progress :    out Boolean);

	--
	-- Acknowledge write request to backend block session
	--
	-- \param Req       reference to the request processed by the CBE
	-- \param Progress  return true if the CBE acknowledged the request
	--
	procedure Ack_Write_Data (
		Obj      : in out Object_Type;
		Req      :        Request.Object_Type;
		Progress :    out Boolean);

	--
	-- Return a request that provides data to the frontend block data
	--
	-- \param Req  return valid request in case the is one pending that
	--             needs data, otherwise an invalid one is returned
	--
	procedure Have_Data (
		Obj : in out Object_Type;
		Req :    out Request.Object_Type);

	--
	-- Get primitive index
	--
	function Give_Data_Index (
		Obj : Object_Type;
		Req : Request.Object_Type)
	return Primitive.Index_Type;

	--
	-- Request access to the Block::Request data for storing data
	--
	-- \param Req       reference to the request processed by the CBE
	-- \param Data      data associated with the request
	-- \param Progress  return 'True' if the CBE could process the request
	--
	procedure Give_Read_Data (
		Obj      : in out Object_Type;
		Req      :        Request.Object_Type;
		Data     :    out Crypto.Plain_Data_Type;
		Progress :    out Boolean);

	--
	-- Request access to the Block::Request data for reading data
	--
	-- \param Request  reference to the Block::Request processed
	--                 by the CBE
	-- \param Data     reference to the data associated with the
	--                 Block::Request
	--
	-- \return  true if the CBE could process the request
	--
	function Give_Write_Data (
		Obj  : in out Object_Type;
		Now  :        Timestamp_Type;
		Req  :        Request.Object_Type;
		Data :        Block_Data_Type)
	return Boolean;

	--
	-- Execute one loop of the CBE
	--
	-- \param  now               current time as timestamp
	-- \param  show_progress     if true, generate a LOG message of the current
	--                           progress (basically shows the progress state of
	--                           all modules)
	-- \param  show_if_progress  if true, generate LOG message only when progress was
	--                           acutally made
	--
	procedure Execute (
		Obj              : in out Object_Type;
		Now              :        Timestamp_Type);
--		Show_Progress    :        Boolean;
--		Show_If_Progress :        Boolean);

	--
	-- Get highest virtual-block-address useable by the current active snapshot
	--
	-- \return  highest addressable virtual-block-address
	--
	function Max_VBA (Obj : Object_Type)
	return Virtual_Block_Address_Type;

	function Execute_Progress(Obj : Object_Type)
	return Boolean;

private

	type Free_Tree_Retry_Count_Type is mod 2**32;

	Free_Tree_Retry_Limit : constant := 3;

	--
	-- Defining the structure here is just an interims solution
	-- and should be properly managed, especially handling more
	-- than one request is "missing".
	--
	type Request_Primitive_Type is record
		Req         : Request.Object_Type;
		Prim        : Primitive.Object_Type;
		Tag         : Tag_Type;
		In_Progress : Boolean;
	end record;

	function Request_Primitive_Invalid
	return Request_Primitive_Type
	is (
		Req         => Request.Invalid_Object,
		Prim        => Primitive.Invalid_Object,
		Tag         => Tag_Invalid,
		In_Progress => False);

	type Object_Type is record
		Sync_Interval           : Timestamp_Type;
		Last_Time               : Timestamp_Type;
		Secure_Interval         : Timestamp_Type;
		Last_Secure_Time        : Timestamp_Type;
		Sync_Timeout_Request    : Timeout_Request_Type;
		Secure_Timeout_Request  : Timeout_Request_Type;
		Execute_Progress        : Boolean;
		Request_Pool_Obj        : Pool.Object_Type;
		Splitter_Obj            : Splitter.Object_Type;
		Crypto_Obj              : Crypto.Object_Type;
		Crypto_Data             : Block_Data_Type;
		IO_Obj                  : Block_IO.Object_Type;
		IO_Data                 : Block_IO.Data_Type;
		Cache_Obj               : Cache.Object_Type;
		Cache_Data              : Cache.Cache_Data_Type;
		Cache_Job_Data          : Cache.Cache_Job_Data_Type;
		Cache_Flusher_Obj       : Cache_Flusher.Object_Type;
		Trans_Data              : Translation_Data_Type;
		VBD                     : Virtual_Block_Device.Object_Type;
		Write_Back_Obj          : Write_Back.Object_Type;
		Write_Back_Data         : Write_Back.Data_Type;
		Sync_SB_Obj             : Sync_Superblock.Object_Type;
		Free_Tree_Obj           : Free_Tree.Object_Type;
		Free_Tree_Retry_Count   : Free_Tree_Retry_Count_Type;
		Free_Tree_Trans_Data    : Translation_Data_Type;
		Free_Tree_Query_Data    : Query_Data_Type;
		Super_Blocks            : Super_Blocks_Type;
		Cur_SB                  : Superblock_Index_Type;
		Cur_Gen                 : Generation_Type;
		Last_Secured_Generation : Generation_Type;
		Cur_Snap                : Snapshot_ID_Type;
		Last_Snapshot_ID        : Snapshot_ID_Type;
		Seal_Generation         : Boolean;
		Secure_Superblock       : Boolean;
		Superblock_Dirty        : Boolean;
		Front_End_Req_Prim      : Request_Primitive_Type;
		Back_End_Req_Prim       : Request_Primitive_Type;
	end record;

	function Super_Block_Snapshot_Slot (SB : Super_Block_Type)
	return Snapshot_ID_Type;

	function Discard_Snapshot (Active_Snaps : in out Snapshots_Type;
	                           Curr_Snap_ID :        Snapshot_ID_Type)
	return Boolean;

	function Timeout_Request_Valid (Time : Timestamp_Type)
	return Timeout_Request_Type;

	function Timeout_Request_Invalid
	return Timeout_Request_Type;

end CBE.Library;
