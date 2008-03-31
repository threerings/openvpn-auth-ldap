/*
 * TRPFAddress.m vi:ts=4:sw=4:expandtab:
 * OpenBSD PF Address
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

#include <string.h>

#include <TRVPNPlugin.h>

/**
 * Represents a single IPv4 or IPv6 address, for use with PF.
 */
@implementation TRPFAddress

- (id) init {
    self = [super init];
    if (!self)
        return self;

    /* Initialize the TRPortableAddress structure */
    memset(&_addr, 0, sizeof(_addr));

    return self;
}

/**
 * Initialize with an IPv4 or IPv6 address string.
 * @param address An IPv4 or IPv6 address in human-readable format (eg 127.0.0.1 or ::1)
 */
- (id) initWithPresentationAddress: (TRString *) address {
    if (![self init])
        return nil;

    /* Try IPv4, then IPv6 */
    if (inet_pton(AF_INET, [address cString], &_addr.ip4_addr)) {
        _addr.family = AF_INET;
        _addr.netmask = 32;
        return self;
    } else if(inet_pton(AF_INET6, [address cString], &_addr.ip6_addr)) {
        _addr.family = AF_INET6;
        _addr.netmask = 128;
        return self;
    }

    /* Fall through */
    [self release];
    return nil;
}

/**
 * Initialize from the provided TRPortableAddress representation.
 */
- (id) initWithPortableAddress: (TRPortableAddress *) address {
    if (![self init])
        return nil;

    memcpy(&_addr, address, sizeof(_addr));
    return self;
}


/**
 * Copies the address' TRPortableAddress representation
 * to the provided destination pointer.
 */
- (void) address: (TRPortableAddress *) dest {
    memcpy(dest, &_addr, sizeof(*dest));
}

@end
