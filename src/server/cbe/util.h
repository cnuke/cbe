/*
 * Copyright (C) 2019 Genode Labs GmbH, Componolit GmbH, secunet AG
 *
 * This file is part of the Consistent Block Encrypter project, which is
 * distributed under the terms of the GNU Affero General Public License
 * version 3.
 */

#ifndef _UTIL_H_
#define _UTIL_H_

/* Genode includes */
#include <base/fixed_stdint.h>
#include <block_session/connection.h>
#include <util/misc_math.h>
#include <util/string.h>


namespace Util {

	using namespace Genode;

	/*
	 * Wrapper to get suffixed uint64_t values
	 */
	class Number_of_bytes
	{
		uint64_t _n;

		public:

		/**
		 * Default constructor
		 */
		Number_of_bytes() : _n(0) { }

		/**
		 * Constructor, to be used implicitly via assignment operator
		 */
		Number_of_bytes(Genode::uint64_t n) : _n(n) { }

		/**
		 * Convert number of bytes to 'size_t' value
		 */
		operator Genode::uint64_t() const { return _n; }

		void print(Output &output) const
		{
			using Genode::print;

			enum { KB = 1024UL, MB = KB*1024UL, GB = MB*1024UL };

			if      (_n      == 0) print(output, 0);
			else if (_n % GB == 0) print(output, _n/GB, "G");
			else if (_n % MB == 0) print(output, _n/MB, "M");
			else if (_n % KB == 0) print(output, _n/KB, "K");
			else                   print(output, _n);
		}
	};

	inline size_t ascii_to(const char *s, Number_of_bytes &result)
	{
		unsigned long res = 0;

		/* convert numeric part of string */
		int i = ascii_to_unsigned(s, res, 0);

		/* handle suffixes */
		if (i > 0)
			switch (s[i]) {
				case 'G': res *= 1024;
				case 'M': res *= 1024;
				case 'K': res *= 1024; i++;
				default: break;
			}

		result = res;
		return i;
	}
};

#endif /* _UTIL_H_ */
