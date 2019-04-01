/*
 * Copyright (C) 2019 Genode Labs GmbH
 *
 * This file is part of the Genode OS framework, which is distributed
 * under the terms of the GNU Affero General Public License version 3.
 */

#ifndef _CBE_REQUEST_POOL_MODULE_H_
#define _CBE_REQUEST_POOL_MODULE_H_

/* local includes */
#include <types.h>
#include <spark_object.h>


namespace Cbe { namespace Module {

	class Request_pool;

} /* namespace Module */ } /* namespace Cbe */

struct Cbe::Module::Request_pool : Spark::Object<896>
{
	Request_pool(size_t size      = sizeof(Request_pool),
	             size_t req_size  = sizeof(Block::Request),
	             size_t prim_size = sizeof(Primitive));

	/**
	 * Check if the pool can accept a new request
	 *
	 * \return true if the request can be accepted, otherwise false
	 */
	bool request_acceptable() const;

	/**
	 * Submit a new request
	 *
	 * The request as well as the number of primitives will be stored
	 * internally.
	 *
	 * \param r  copy of request
	 * \param n  number of primitives
	 */
	void submit_request(Block::Request       const &request,
	                    Number_of_primitives const  num);

	/**
	 * Check for any pending request
	 *
	 * The method will return true as long as there is a pending
	 * request.
	 *
	 * \return true if a request is pending, otherwise false
	 */
	Block::Request peek_pending_request() const;

	/**
	 * Drop pending request
	 */
	void drop_pending_request(Block::Request const &req);

	/**
	 * Mark the primitive as completed
	 *
	 * \param p  reference to Primitive that is used to lookup
	 *           the corresponding internal primitive as completed
	 */
	void mark_completed_primitive(Cbe::Primitive const &p);

	/**
	 * Check for any completed request
	 *
	 * The method will return true as long as there is a completed
	 * request available.
	 *
	 * \return true if a request is pending, otherwise false
	 */
	Block::Request peek_completed_request() const;

	/**
	 * Take completed request
	 *
	 * This method must only be called after executing
	 * 'peek_completed_request' returned true.
	 *
	 * \return takes next completed request and removes it
	 *         from the module
	 */
	void drop_completed_request(Block::Request const &req);

	/**
	 * Get request for given tag
	 *
	 * The method checks if the given tag is valid and belongs to
	 * a known Block request. If all checks out it will return the
	 * corresponding Block request, otherwise a invalid one will
	 * by returned.
	 *
	 * \return a valid Block::Request for the given tag or an
	 *         an invalid one in case there is none
	 */
	Block::Request request_for_tag(Tag const tag) const;
};

#endif /* _CBE_REQUEST_POOL_MODULE_H_ */
