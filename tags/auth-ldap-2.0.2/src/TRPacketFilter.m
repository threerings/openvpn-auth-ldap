/*
 * TRPacketFilter.m
 * Interface to OpenBSD pf
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
 * Copyright (c) 2006 Three Rings Design, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of any contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include "TRPacketFilter.h"
#include "TRPFAddress.h"
#include "LFString.h"

#ifdef HAVE_PF

#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

@implementation TRPacketFilter

/**
 * PF-specific strerror.
 * Provides useful error messages for bizzare PF error codes.
 */
+ (const char *) strerror: (int) pferrno {
	const char *string;

	switch (pferrno) {
		case ESRCH:
			/* Returned when a table, etc, is not found.
			 * "No such process" doesn't make much sense here. */
			string = "No such PF entry.";
			break;
		default:
			string = strerror(errno);
			break;
	}
	
	return string;
}

- (id) init {
	self = [super init];
	if (!self)
		return self;

	/* Open a reference to /dev/pf */
	if ((_fd = open(PF_DEV_PATH, O_RDWR)) == -1) {
		/* Failed to open! */
		int saved_errno = errno;
		[self release];
		errno = saved_errno;
		return nil;
	}

	return self;
}

- (void) dealloc {
	close(_fd);
	[super dealloc];
}

/* !Return an array of table names */
- (TRArray *) tables {
	TRArray *result = nil;
	struct pfioc_table io;
	struct pfr_table *table;
	int size, i;

	/* Initialize the io structure */
	memset(&io, 0, sizeof(io));
	io.pfrio_esize = sizeof(struct pfr_table);

	/* First attempt with a reasonable buffer size - 32 tables */
	size = sizeof(struct pfr_table) * 32;
	io.pfrio_buffer = xmalloc(size);

	/* Loop until success. */
	while (1) {
		io.pfrio_size = size;
		if (ioctl(_fd, DIOCRGETTABLES, &io) == -1) {
			int saved_errno = errno;
			free(io.pfrio_buffer);
			errno = saved_errno;
			return nil;
		}

		/* Do we need a larger buffer? */
		if (io.pfrio_size > size) {
			/* Allocate the suggested space */
			size = io.pfrio_size;
			io.pfrio_buffer = xrealloc(io.pfrio_buffer, size);
		} else {
			/* Success! Exit the loop */
			break;
		}
	}

	/* Iterate over the returned tables, building our array */
	result = [[TRArray alloc] init];

	size = io.pfrio_size / sizeof(struct pfr_table);
	table = (struct pfr_table *) io.pfrio_buffer;
	for (i = 0; i < size; i++) {
		LFString *name = [[LFString alloc] initWithCString: table->pfrt_name];
		[result addObject: name];
		[name release];
		table++;
	}

	free(io.pfrio_buffer);
	return result;
}

/*! Clear all addreses from the specified table. */
- (BOOL) clearAddressesFromTable: (LFString *) tableName {
	struct pfioc_table io;

	/* Initialize the io structure */
	memset(&io, 0, sizeof(io));

	/* Copy in the table name */
	strcpy(io.pfrio_table.pfrt_name, [tableName cString]);

	/* Issue the ioctl */
	if (ioctl(_fd, DIOCRCLRADDRS, &io) == -1) {
		return false;
	}

	return true;
}

/*! Add an address to the specified table. */
- (BOOL) addAddress: (TRPFAddress *) address toTable: (LFString *) tableName {
	struct pfioc_table io;

	/* Initialize the io structure */
	memset(&io, 0, sizeof(io));
	io.pfrio_esize = sizeof(struct pfr_addr);

	/* Build the request */
	strcpy(io.pfrio_table.pfrt_name, [tableName cString]);
	io.pfrio_buffer = [address pfrAddr];
	io.pfrio_size = 1;

	/* Issue the ioctl */
	if (ioctl(_fd, DIOCRADDADDRS, &io) == -1) {
		return false;
	}

	if (io.pfrio_nadd != 1) {
		return false;
	}

	return true;
}

/*! Delete an address from the specified table. */
- (BOOL) deleteAddress: (TRPFAddress *) address fromTable: (LFString *) tableName {
	struct pfioc_table io;

	/* Initialize the io structure */
	memset(&io, 0, sizeof(io));
	io.pfrio_esize = sizeof(struct pfr_addr);

	/* Build the request */
	strcpy(io.pfrio_table.pfrt_name, [tableName cString]);
	io.pfrio_buffer = [address pfrAddr];
	io.pfrio_size = 1;

	/* Issue the ioctl */
	if (ioctl(_fd, DIOCRDELADDRS, &io) == -1) {
		return false;
	}

	if (io.pfrio_ndel != 1) {
		return false;
	}

	return true;
}



/*! Return an array of all addresses from the specified table. */
- (TRArray *) addressesFromTable: (LFString *) tableName {
	TRArray *result = nil;
	struct pfioc_table io;
	struct pfr_addr *pfrAddr;
	int size, i;

	/* Initialize the io structure */
	memset(&io, 0, sizeof(io));
	io.pfrio_esize = sizeof(struct pfr_addr);

	/* Copy in the table name */
	strcpy(io.pfrio_table.pfrt_name, [tableName cString]);

	/* First attempt with a reasonable buffer size - 32 addresses */
	size = 32;
	io.pfrio_buffer = xmalloc(size * sizeof(struct pfr_addr));

	/* Loop until success. */
	while (1) {
		io.pfrio_size = size;
		if (ioctl(_fd, DIOCRGETADDRS, &io) == -1) {
			int saved_errno = errno;
			free(io.pfrio_buffer);
			errno = saved_errno;
			return nil;
		}

		/* Do we need a larger buffer? */
		if (io.pfrio_size > size) {
			/* Allocate the suggested space */
			size = io.pfrio_size;
			io.pfrio_buffer = xrealloc(io.pfrio_buffer, size * sizeof(struct pfr_addr));
		} else {
			/* Success! Exit the loop */
			break;
		}
	}

	/* Iterate over the returned addresses, building our array */
	result = [[TRArray alloc] init];

	pfrAddr = (struct pfr_addr *) io.pfrio_buffer;
	for (i = 0; i < io.pfrio_size; i++) {
		TRPFAddress *address = [[TRPFAddress alloc] initWithPFRAddr: pfrAddr];
		[result addObject: address];
		[address release];
		pfrAddr++;
	}

	free(io.pfrio_buffer);
	return result;

}

@end

#endif /* HAVE_PF */
