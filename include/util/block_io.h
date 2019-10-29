/*
 * Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
 *
 * This file is part of the Consistent Block Encrypter project, which is
 * distributed under the terms of the GNU Affero General Public License
 * version 3.
 */

#ifndef _BLOCK_IO_H_
#define _BLOCK_IO_H_

/* Genode includes */
#include <block_session/connection.h>


namespace Util {

	using namespace Genode;

	using sector_t = Block::sector_t;

	struct Block_io;
}; /* namespace Util */

/*
 * Block_io wraps a Block::Connection for synchronous operations
 */
struct Util::Block_io
{
	struct Io_error : Genode::Exception { };

	using Packet_descriptor = Block::Packet_descriptor;

	Block::Connection<>  &_block;
	Packet_descriptor     _p;

	/**
	 * Constructor
	 *
	 * \param block  reference to underlying Block::Connection
	 * \param block_size  logical block size of the Block::Connection
	 * \param lba         LBA to start access from
	 * \param count       number of LBAs to access
	 * \param write       set type of operation, write if true, read
	 *                    if false
	 *
	 * \throw Io_error
	 */
	Block_io(Block::Connection<> &block, size_t block_size,
	         sector_t lba, size_t count,
	         bool write = false, void const *data = nullptr, size_t len = 0)
	:
		_block(block),
		_p(_block.alloc_packet(block_size * count),
		   write ? Packet_descriptor::WRITE
		         : Packet_descriptor::READ, lba, count)
	{
		if (write) {
			if (data && len) {
				void *p = addr<void*>();
				Genode::memcpy(p, data, len);
			} else {
				Genode::error("invalid data for write");
				throw Io_error();
			}
		}

		_block.tx()->submit_packet(_p);
		_p = _block.tx()->get_acked_packet();
		if (!_p.succeeded()) {
			Genode::error("could not ", write ? "write" : "read",
			              " block-range [", _p.block_number(), ",",
			              _p.block_number() + count, ")");
			_block.tx()->release_packet(_p);
			throw Io_error();
		}
	}

	~Block_io() { _block.tx()->release_packet(_p); }

	template <typename T> T addr()
	{
		return reinterpret_cast<T>(_block.tx()->packet_content(_p));
	}
};

#endif /* _BLOCK_IO_H_ */
