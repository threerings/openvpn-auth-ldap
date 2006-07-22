/*
 * TRConfigLexer.h
 * Configuration Lexer
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

#include <ldap.h>

#include "TRObject.h"
#include "LFString.h"

#include "TRConfig.h"

#ifndef TRCONFIGLEXER_H
#define TRCONFIGLEXER_H

typedef enum {
	LEXER_SC_INITIAL,
	LEXER_SC_SECTION,
	LEXER_SC_SECTION_NAME,
	LEXER_SC_VALUE,
	LEXER_SC_STRING_VALUE
} LexerStartCondition;

@interface TRConfigLexer : TRObject {
	/* Input buffer */
	char *buffer;
	size_t bufferLength;

	/* re2c lexer state */
	char *_cursor;
	char *_limit;
	char *_marker;
	char *_ctxMarker;
	char *_token;
	char *_eoi;
	unsigned int _lineNumber;
	LexerStartCondition _condition;
}

- (id) initWithFD: (int) fd;

- (TRConfigToken *) scan;

@end

#endif /* TRCONFIGLEXER_H */
