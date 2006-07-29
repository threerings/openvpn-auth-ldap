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
#include "LFString.h"

#ifdef HAVE_PF

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/pfvar.h>

#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <err.h>

@implementation TRPacketFilter

- (id) init {
	self = [super init];
	if (!self)
		return self;

	/* Open a reference to /dev/pf */
	if ((_fd = open(PF_DEV_PATH, O_RDWR)) == -1) {
		/* Failed to open! */
		warn("Failed to open %s: ", PF_DEV_PATH);
		[self release];
		return nil;
	}

	return self;
}

- (void) dealloc {
	close(_fd);
	[super dealloc];
}

- (void) _logIOFailure: (const char *) request {
	warn("pf ioctl request %s failed: ", request);
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
			[self _logIOFailure: "DIOCRGETTABLES"];
			free(io.pfrio_buffer);
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

/*! Clear all addreses from the given table. */
- (BOOL) clearAddressesFromTable: (LFString *) tableName {
	struct pfioc_table io;

	/* Initialize the io structure */
	memset(&io, 0, sizeof(io));
	io.pfrio_esize = sizeof(struct pfr_table);

	/* Copy in the table name */
	strcpy(io.pfrio_table.pfrt_name, [tableName cString]);

	/* Issue the ioctl */
	if (ioctl(_fd, DIOCRCLRADDRS, &io) == -1) {
		[self _logIOFailure: "DIOCRCLRADDRS"];
		return false;
	}

	return true;
}

@end

#endif /* HAVE_PF */
