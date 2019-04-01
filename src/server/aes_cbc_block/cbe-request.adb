--
-- Copyright (C) 2019 Genode Labs GmbH
--
-- This file is part of the Genode OS framework, which is distributed
-- under the terms of the GNU Affero General Public License version 3.
--

pragma Ada_2012;

package body CBE.Request
with Spark_Mode
is
	--
	-- Invalid_Object
	--
	function Invalid_Object
	return Object_Type
	is (
		Valid        => False,
		Operation    => Read,
		Success      => False,
		Block_Number => 0,
		Offset       => 0,
		Count        => 0,
		Tag          => 0);

	--
	-- Valid_Object
	--
	function Valid_Object(
		Op     : Request.Operation_Type;
		Succ   : Request.Success_Type;
		Blk_Nr : Request.Block_Number_Type;
		Off    : Offset_Type;
		Cnt    : Count_Type;
		Tg     : Tag_Type)
	return Object_Type
	is (
		Valid        => True,
		Operation    => Op,
		Success      => Succ,
		Block_Number => Blk_Nr,
		Offset       => Off,
		Count        => Cnt,
		Tag          => Tg);


	---------------
	-- Accessors --
	---------------

	function Valid       (Obj : Object_Type) return Boolean           is (Obj.Valid);
	function Operation   (Obj : Object_Type) return Operation_Type    is (Obj.Operation);
	function Success     (Obj : Object_Type) return Success_Type      is (Obj.Success);
	function Block_Number(Obj : Object_Type) return Block_Number_Type is (Obj.Block_Number);
	function Offset      (Obj : Object_Type) return Offset_Type       is (Obj.Offset);
	function Count       (Obj : Object_Type) return Count_Type        is (Obj.Count);
	function Tag         (Obj : Object_Type) return Tag_Type          is (Obj.Tag);

	procedure Success(
		Obj  : in out Object_Type;
		Succ : Success_Type)
	is
	begin
		Obj.Success := Succ;
	end Success;

end CBE.Request;
