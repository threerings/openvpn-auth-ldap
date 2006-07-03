/*
 * TRConfig.h
 * Generic Configuration Parser
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

#ifndef TRCONFIG_H
#define TRCONFIG_H

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "TRObject.h"

/* A complex set of TRConfig* header dependencies dictates the following order
 * of declarations and includes */

/* Object Data Types */
typedef enum {
	TOKEN_DATATYPE_NONE,
	TOKEN_DATATYPE_INT
} TRConfigDataType;

#include "TRConfigToken.h"
#include "TRConfigLexer.h"

@protocol TRConfigDelegate
- (bool) setKey: (TRConfigToken *) name value: (TRConfigToken *) value;
- (bool) startSection: (TRConfigToken *) sectionType sectionName: (TRConfigToken *) name;
- (bool) endSection: (TRConfigToken *) sectionEnd;
@end

#include "TRConfigParser.h"

@interface TRConfig : TRObject {
	int _fd;
	id <TRConfigDelegate> _delegate;
}

- (id) initWithFD: (int) fd configDelegate: (id <TRConfigDelegate>) delegate;
- (bool) parseConfig;

@end

#endif /* TRCONFIG_H */
