/*
 * TRLocalPacketFilter.m vi:ts=4:sw=4:expandtab:
 * Interface to local OpenBSD /dev/pf
 *
 * Author: Landon Fuller <landonf@threerings.net>
 *
 * Copyright (c) 2006 - 2007 Three Rings Design, Inc.
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

#include "TRLocalPacketFilter.h"
#include "TRPFAddress.h"

#include <TRLog.h>
#include <util/TRString.h>
#include <util/xmalloc.h>

#ifdef HAVE_PF

#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <assert.h>


/* Private Methods */

@interface TRLocalPacketFilter (Private)
+ (pferror_t) mapErrno;
- (int) ioctl: (unsigned long) request withArgp: (void *) argp;
- (BOOL) pfFromAddress: (TRPFAddress *) source pfaddr: (struct pfr_addr *) dest;
- (TRPFAddress *) addressFromPF: (struct pfr_addr *) pfaddr;
@end


/**
 * An interface to a local OpenBSD Packet Filter.
 */
@implementation TRLocalPacketFilter

/**
 * Initialize a new instance.
 */
- (id) init {
    self = [super init];
    if (self == nil)
        return self;

    _fd = -1;
    return self;
}


/**
 * Open a reference to /dev/pf. Must be called before
 * any other PF methods.
 */
- (pferror_t) open {
    /* Open a reference to /dev/pf */
    if ((_fd = open(PF_DEV_PATH, O_RDWR)) == -1)
        return [TRLocalPacketFilter mapErrno];
    else
        return PF_SUCCESS;
}


/**
 * Close and release any open references to /dev/pf.
 * This is called automatically when the object is released.
 */
- (void) close {
    if (_fd != -1) {
        close(_fd);
        _fd = -1;
    }
}


- (void) dealloc {
    [self close];
    [super dealloc];
}


/** Return an array of table names */
- (pferror_t) tables: (TRArray **) result {
    TRArray *tables = nil;
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
        if ([self ioctl: DIOCRGETTABLES withArgp: &io] == -1) {
            pferror_t ret;

            ret = [TRLocalPacketFilter mapErrno];
            free(io.pfrio_buffer);
            *result = nil;
            return ret;
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
    tables = [[TRArray alloc] init];

    size = io.pfrio_size / sizeof(struct pfr_table);
    table = (struct pfr_table *) io.pfrio_buffer;
    for (i = 0; i < size; i++) {
        TRString *name = [[TRString alloc] initWithCString: table->pfrt_name];
        [tables addObject: name];
        [name release];
        table++;
    }

    free(io.pfrio_buffer);
    *result = [tables autorelease];
    return PF_SUCCESS;
}


/**
 * Clear all addreses from the specified table.
 */
- (pferror_t) flushTable: (TRString *) tableName {
    struct pfioc_table io;

    /* Validate name */
    if ([tableName length] > sizeof(io.pfrio_table.pfrt_name))
        return PF_ERROR_INVALID_NAME;

    /* Initialize the io structure */
    memset(&io, 0, sizeof(io));

    /* Copy in the table name */
    strcpy(io.pfrio_table.pfrt_name, [tableName cString]);

    /* Issue the ioctl */
    if ([self ioctl: DIOCRCLRADDRS withArgp: &io] == -1) {
        return [TRLocalPacketFilter mapErrno];
    }

    return PF_SUCCESS;
}

/**
 * Add an address to the specified table.
 */
- (pferror_t) addAddress: (TRPFAddress *) address toTable: (TRString *) tableName {
    struct pfioc_table io;
    struct pfr_addr addr;

    /* Validate name */
    if ([tableName length] > sizeof(io.pfrio_table.pfrt_name))
        return PF_ERROR_INVALID_NAME;

    /* Initialize the io structure */
    memset(&io, 0, sizeof(io));
    io.pfrio_esize = sizeof(struct pfr_addr);

    /* Build the request */
    strcpy(io.pfrio_table.pfrt_name, [tableName cString]);

    if ([self pfFromAddress: address pfaddr: &addr] != true)
        return PF_ERROR_INTERNAL;    
    io.pfrio_buffer = &addr;

    io.pfrio_size = 1;

    /* Issue the ioctl */
    if ([self ioctl: DIOCRADDADDRS withArgp: &io] == -1) {
        return [TRLocalPacketFilter mapErrno];
    }

    if (io.pfrio_nadd != 1) {
        return PF_ERROR_INTERNAL;
    }

    return PF_SUCCESS;
}


/**
 * Delete an address from the specified table.
 */
- (pferror_t) deleteAddress: (TRPFAddress *) address fromTable: (TRString *) tableName {
    struct pfioc_table io;
    struct pfr_addr addr;

    /* Validate name */
    if ([tableName length] > sizeof(io.pfrio_table.pfrt_name))
        return PF_ERROR_INVALID_NAME;

    /* Initialize the io structure */
    memset(&io, 0, sizeof(io));
    io.pfrio_esize = sizeof(struct pfr_addr);

    /* Build the request */
    strcpy(io.pfrio_table.pfrt_name, [tableName cString]);

    if ([self pfFromAddress: address pfaddr: &addr] != true)
        return PF_ERROR_INTERNAL;    

    io.pfrio_buffer = &addr;
    io.pfrio_size = 1;

    /* Issue the ioctl */
    if ([self ioctl: DIOCRDELADDRS withArgp: &io] == -1) {
        return [TRLocalPacketFilter mapErrno];
    }

    if (io.pfrio_ndel != 1) {
        return PF_ERROR_INTERNAL;
    }

    return PF_SUCCESS;
}


/**
 * Return an array of all addresses from the specified table.
 */
- (pferror_t) addressesFromTable: (TRString *) tableName withResult: (TRArray **) result {
    TRArray *addresses = nil;
    struct pfioc_table io;
    struct pfr_addr *pfrAddr;
    int size, i;

    /* Validate name */
    if ([tableName length] > sizeof(io.pfrio_table.pfrt_name)) {
        *result = nil;
        return PF_ERROR_INVALID_NAME;
    }

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
        if ([self ioctl: DIOCRGETADDRS withArgp: &io] == -1) {
            pferror_t ret;

            ret = [TRLocalPacketFilter mapErrno];
            free(io.pfrio_buffer);
            *result = nil;
            return ret;
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
    addresses = [[TRArray alloc] init];

    pfrAddr = (struct pfr_addr *) io.pfrio_buffer;
    for (i = 0; i < io.pfrio_size; i++) {
        TRPFAddress *address = [self addressFromPF: pfrAddr];
        [addresses addObject: address];
        [address release];
        pfrAddr++;
    }

    free(io.pfrio_buffer);
    *result = [addresses autorelease];
    return PF_SUCCESS;
}

@end


/**
 * TRLocalPacketFilter Private Methods
 * @internal
 */
@implementation TRLocalPacketFilter (Private)

/**
 * Map PF errno values to pferror_t values
 */
+ (pferror_t) mapErrno {
    switch (errno) {
        case ESRCH:
            /* Returned when a table, etc, is not found.
             * "No such process" doesn't make much sense here. */
            return PF_ERROR_NOT_FOUND;

        case EINVAL:
            return PF_ERROR_INVALID_ARGUMENT;

        case EPERM:
            /* Returned when /dev/pf can't be opened, and? */
            return PF_ERROR_PERMISSION;

        default:
            return PF_ERROR_UNKNOWN;
            break;
    }
}

/* ioctl() with an extra seat-belt. */
- (int) ioctl: (unsigned long) request withArgp: (void *) argp {
    assert(_fd >= 0);
    return ioctl(_fd, request, argp);
}


/**
 * Create a new TRPFAddress address with the provided pfr_addr structure.
 */
- (TRPFAddress *) addressFromPF: (struct pfr_addr *) pfaddr {
    TRPortableAddress addr;

    /* Initialize the addr structure */
    memset(&addr, 0, sizeof(addr));
    addr.family = pfaddr->pfra_af;
    addr.netmask = pfaddr->pfra_net;

    switch (addr.family) {
        case (AF_INET):
            memcpy(&addr.ip4_addr, &pfaddr->pfra_ip4addr, sizeof(addr.ip4_addr));
            break;
        case (AF_INET6):
            memcpy(&addr.ip6_addr, &pfaddr->pfra_ip6addr, sizeof(addr.ip6_addr));
            break;
        default:
            [TRLog debug: "Unsupported address family: %d", addr.family];
            return nil;
    }

    return [[TRPFAddress alloc] initWithPortableAddress: &addr];
}


/**
 * Copies the address' struct pfr_addr representation
 * to the provided destination pointer.
 */
- (BOOL) pfFromAddress: (TRPFAddress *) source pfaddr: (struct pfr_addr *) dest {
    TRPortableAddress addr;

    [source address: &addr];

    memset(dest, 0, sizeof(*dest));
    dest->pfra_af = addr.family;
    dest->pfra_net = addr.netmask;

    switch (addr.family) {
        case (AF_INET):
            memcpy(&dest->pfra_ip4addr, &addr.ip4_addr, sizeof(dest->pfra_ip4addr));
            return true;
        case (AF_INET6):
            memcpy(&dest->pfra_ip6addr, &addr.ip6_addr, sizeof(dest->pfra_ip6addr));
            return true;
        default:
            /* Should be unreachable, as long as we're */
            [TRLog debug: "Unsupported address family: %d", addr.family];
            return false;
    }

    return false;
}

@end

#endif /* HAVE_PF */
