--
-- Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
--
-- This file is part of the Consistent Block Encrypter project, which is
-- distributed under the terms of the GNU Affero General Public License
-- version 3.
--

pragma Ada_2012;

with CBE.Request;

package CBE.Primitive
with Spark_Mode
is
	pragma Pure;

	use type Request.Operation_Type;
	use type Request.Success_Type;
	use type Request.Block_Number_Type;

	type Index_Type  is mod 2**64;
	type Object_Type is private;

	--
	-- Invalid_Object
	--
	function Invalid_Object
	return Object_Type
	with Post => (not Valid(Invalid_Object'Result));

	--
	-- Valid_Object
	--
	function Valid_Object(
		Op     : Request.Operation_Type;
		Succ   : Request.Success_Type;
		Tg     : Request.Tag_Type;
		Blk_Nr : Request.Block_Number_Type;
		Idx    : Index_Type)
	return Object_Type
	with
		Post => (
			Valid(Valid_Object'Result) and then (
				Operation   (Valid_Object'Result) = Op     and
				Success     (Valid_Object'Result) = Succ   and
				Block_Number(Valid_Object'Result) = Blk_Nr and
				Index       (Valid_Object'Result) = Idx    and
				Request."="(Tag(Valid_Object'Result), Tg)));


	---------------
	-- Accessors --
	---------------

	function Valid(Obj : Object_Type)
	return Boolean;

	function Operation(Obj : Object_Type)
	return Request.Operation_Type
	with Pre => (Valid(Obj));

	function Success(Obj : Object_Type)
	return Request.Success_Type
	with Pre => (Valid(Obj));

	function Tag(Obj : Object_Type)
	return Request.Tag_Type
	with Pre => (Valid(Obj));

	function Block_Number(Obj : Object_Type)
	return Request.Block_Number_Type
	with Pre => (Valid(Obj));


	function Index(Obj : Object_Type)
	return Index_Type
	with Pre => (Valid(Obj));

private

	--
	-- Object_Type
	--
	type Object_Type is record
		Valid        : Boolean;
		Operation    : Request.Operation_Type;
		Success      : Request.Success_Type;
		Tag          : Request.Tag_Type;
		Block_Number : Request.Block_Number_Type;
		Index        : Index_Type;
	end record;

end CBE.Primitive;
