/*
 * TRPFAddress.m
 * OpenBSD PF Address
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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#ifdef HAVE_PF

#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include "TRPFAddress.h"
#include "LFString.h"

@implementation TRPFAddress

- (id) init {
	self = [super init];
	if (!self)
		return self;

	/* Initialize the pfr_addr structure */
	memset(&_addr, 0, sizeof(_addr));

	return self;
}


- (id) initWithPresentationAddress: (LFString *) address {
	if (![self init])
		return nil;

	/* Try IPv4, then IPv6 */
	if (inet_pton(AF_INET, [address cString], &_addr.pfra_ip4addr)) {
		_addr.pfra_af = AF_INET;
		_addr.pfra_net = 32;
		return self;
	} else if(inet_pton(AF_INET6, [address cString], &_addr.pfra_ip6addr)) {
		_addr.pfra_af = AF_INET6;
		_addr.pfra_net = 128;
		return self;
	}

	/* Fall through */
	[self release];
	return nil;
}

- (id) initWithPFRAddr: (struct pfr_addr *) pfrAddr {
	if (![self init])
		return nil;

	/* Copy the supplied pfr_addr structure */
	memcpy(&_addr, pfrAddr, sizeof(_addr));

	return self;
}

- (struct pfr_addr *) pfrAddr {
	return &_addr;
}

@end

#endif /* HAVE_PF */
