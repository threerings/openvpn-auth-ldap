/*
 * TRPacketFilter.h vi:ts=4:sw=4:expandtab:
 * Generic interface to the OpenBSD Packet Filter
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

#import "TRObject.h"
#import "TRArray.h"
#import "TRString.h"
#import "TRPFAddress.h"

typedef enum {
    PF_SUCCESS                  = 0,    /* No error occured. */
    PF_ERROR_NOT_FOUND          = 1,    /* Unknown (eg, table) name. */
    PF_ERROR_INVALID_NAME       = 2,    /* Invalid (eg, table) name. */
    PF_ERROR_UNAVAILABLE        = 3,    /* PF unavailable (eg, could not open /dev/pf). */
    PF_ERROR_PERMISSION         = 4,    /* PF permission denied (eg, insufficient permissions to /dev/pf). */
    PF_ERROR_INVALID_ARGUMENT   = 5,    /* An invalid argument was supplied. */
    PF_ERROR_INTERNAL           = 6,    /* An internal error occured. */
    PF_ERROR_UNKNOWN            = 7     /* An unknown error occured. */
} pferror_t;

/**
 * Packet Filter Class Protocol.
 */
@protocol TRPacketFilter <TRObject>

/**
 * Open a reference to the underlying packet filter implementation.
 */
- (pferror_t) open;

/**
 * Close any references to the underlying packet filter implementation,
 * and free any associated resources.
 */
- (void) close;

/**
 * Return a list of packet filter tables in result.
 * @param result A pointer in which a pointer to the result array will be placed. The array will be auto-released.
 * @return A PF_SUCCESS on success, otherwise, a pferror_t failure code.
 */
- (pferror_t) tables: (TRArray **) result;

/**
 * Flush all addresses from the specified table.
 * @param tableName The table to flush.
 * @return A PF_SUCCESS on success, otherwise, a pferror_t failure code.
 */
- (pferror_t) flushTable: (TRString *) tableName;

/**
 * Add an address to the specified table.
 * @param address The address to add.
 * @param tableName The address will be added to this table.
 * @return A PF_SUCCESS on success, otherwise, a pferror_t failure code.
 */
- (pferror_t) addAddress: (TRPFAddress *) address toTable: (TRString *) tableName;

/**
 * Delete an address from the specified table.
 * @param address The address to delete.
 * @param tableName The address will be deleted to this table.
 * @return A PF_SUCCESS on success, otherwise, a pferror_t failure code.
 */
- (pferror_t) deleteAddress: (TRPFAddress *) address fromTable: (TRString *) tableName;

/**
 * Return a list of packet filter tables in result.
 * @param tableName The name from which to gather the list of addresses.
 * @param result A pointer in which a pointer to the result array will be placed. The array will be auto-released.
 * @return A PF_SUCCESS on success, otherwise, a pferror_t failure code.
 */
- (pferror_t) addressesFromTable: (TRString *) tableName withResult: (TRArray **) result;
@end

/*
 * Packet Filter Utility Class
 */
@interface TRPacketFilterUtil : TRObject

+ (char *) stringForError: (pferror_t) error;

@end
