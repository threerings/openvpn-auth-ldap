/*
 * TRLocalPacketFilter.h vi:ts=4:sw=4:expandtab:
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

#ifdef HAVE_CONFIG_H
#import <config.h>
#endif

#ifdef HAVE_PF

#import "TRObject.h"
#import "TRPacketFilter.h"
#import "TRArray.h"
#import "TRPFAddress.h"
#import "TRString.h"

/* pf includes */
#import <sys/types.h>
#import <sys/ioctl.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/pfvar.h>

@interface TRLocalPacketFilter : TRObject <TRPacketFilter> {
@private
    /** Cached reference to /dev/pf. */
    int _fd;
}

- (pferror_t) open;
- (void) close;

- (pferror_t) tables: (TRArray **) result;
- (pferror_t) flushTable: (TRString *) tableName;
- (pferror_t) addAddress: (TRPFAddress *) address toTable: (TRString *) tableName;
- (pferror_t) deleteAddress: (TRPFAddress *) address fromTable: (TRString *) tableName;
- (pferror_t) addressesFromTable: (TRString *) tableName withResult: (TRArray **) result;

@end

#endif /* HAVE_PF */
