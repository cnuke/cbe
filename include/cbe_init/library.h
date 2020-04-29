/*
 * Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
 *
 * This file is part of the Consistent Block Encrypter project, which is
 * distributed under the terms of the GNU Affero General Public License
 * version 3.
 */

#ifndef _CBE_INIT__LIBRARY_H_
#define _CBE_INIT__LIBRARY_H_

/* CBE includes */
#include <cbe/types.h>
#include <cbe/spark_object.h>

namespace Cbe_init {

	class Library;

	Genode::uint32_t object_size(Library const &);

}

struct Cbe_init::Library : Cbe::Spark_object<60960>
{
	Library();

	bool client_request_acceptable() const;

	void submit_client_request(Cbe::Request const &request,
	                           Genode::uint32_t    key_id,
	                           Genode::uint64_t    vbd_max_lvl_idx,
	                           Genode::uint64_t    vbd_degree,
	                           Genode::uint64_t    vbd_nr_of_leafs,
	                           Genode::uint64_t    ft_max_lvl_idx,
	                           Genode::uint64_t    ft_degree,
	                           Genode::uint64_t    ft_nr_of_leafs);

	Cbe::Request peek_completed_client_request() const;

	void drop_completed_client_request(Cbe::Request const &req);

	void execute(Cbe::Io_buffer &io_buf);

	bool execute_progress() const;

	void io_request_completed(Cbe::Io_buffer::Index const &data_index,
	                          bool                  const  success);

	void has_io_request(Cbe::Request &, Cbe::Io_buffer::Index &) const;

	void io_request_in_progress(Cbe::Io_buffer::Index const &data_index);
};

#endif /* _CBE_INIT__LIBRARY_H_ */
