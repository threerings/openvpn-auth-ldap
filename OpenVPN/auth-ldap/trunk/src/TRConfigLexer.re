/*
 * TRConfigLexer.re
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
 * 3. Neither the name of the copyright holders nor the names of any contributors
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

#include <stdio.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>

#include "TRConfigLexer.h"

#include "TRConfigParser.h"

/*
 * re2c Configuration
 */
#define YYCTYPE      char	/* Input Symbol Type */
#define YYCURSOR     _cursor	/* L-expression of type *YYCTYPE that points to the current input symbol */
#define YYLIMIT      _limit	/* Expression of type *YYCTYPE that marks the end of the buffer */
#define YYMARKER     _marker	/* L-expression of type *YYCTYPE that is used for backtracking information */
#define YYFILL(n)    [self fill: n]	/* YYFILL(n) is called when the buffer needs (re)filling */

#define YYDEBUG(state, current) printf("state: %d, current: '%c' (%d)\n", state, current, current);

/*
 * Macros
 */

/* Switch to a start condition */
#define BEGIN(cond)	( _condition = LEXER_SC_ ## cond)

/* Declare a start condition */
#define SC(cond)	LEXER_SC_ ## cond: LEXER_SC_ ## cond

/* Check for end-of-input */
#define CHECK_EOI()	if (_eoi) { return NULL; }

/* Skip a token */
#define SKIP(cond)	CHECK_EOI(); goto LEXER_SC_ ## cond

@implementation TRConfigLexer

- (void) dealloc {
	if (buffer)
		munmap(buffer, bufferLength);
	[super free];
}

- (TRConfigLexer *) initWithFD: (int) fd {
	struct stat statbuf;

	/* Initialize */
	self = [self init];
	if (self == NULL)
		return (self);

	/* Mmap() source file
	 * Unless our caller botched something, this should never fail */
	assert((fstat(fd, &statbuf) == 0));
	bufferLength = statbuf.st_size;
	buffer = mmap(NULL, bufferLength, PROT_READ, MAP_SHARED, fd, 0);
	assert(buffer != MAP_FAILED);

	/* Initialize lexer state */
	_condition = LEXER_SC_INITIAL;
	_cursor = buffer;
	_limit = _cursor + bufferLength - 1;

	return (self);
}

- (void) fill: (int) length {
	/* We just need to prevent re2c from walking off the end of our buffer */
	assert(_limit - _cursor >= 0);
	if (_cursor == _limit) {
		/* Signal EOI */
		_cursor = "\n";
		_eoi = true;
	}
}

- (TRConfigToken *) scan {
	TRConfigToken *token;
/*!re2c
/* vim syntax fix */

	any = .;

*/

	switch (_condition) {
		case SC(INITIAL):
			_token = _cursor;
			/*!re2c /* vim syntax fix */

			/* Skip comments */
			"#".* {
				_token = _cursor;
				SKIP(INITIAL);
			}

			/* Skip leading whitespace and blank lines */
			[ \t\n]+ {
				_token = _cursor;
				SKIP(INITIAL);
			}

			/* Handle keys */
			[A-Za-z_-]+ {
				token = [[TRConfigToken alloc] init];
				printf("Key: '%.*s'\n", _cursor - _token, _token);
				// token->_id = KEY;
				BEGIN(VALUE);
				return token;
			}

			/* Handle unknown characters */
			any {
				// TODO explode here
				return NULL;
			}
			*/
			break;

		/* Parse setting values */
		case SC(VALUE):
			_token = _cursor;
			/*!re2c /* vim syntax fix */

			/* Skip leading/trailing whitespace */
			[ \t]+ {
				SKIP(VALUE);
			}

			/* The value may contain anything except \n, and any leading or trailing
			 * whitespace is skipped */
			[^ \t].*[^ \t\n] {
				token = [[TRConfigToken alloc] init];
				printf("Value: '%.*s'\n", _cursor - _token, _token);
				// token->id = VALUE;
				BEGIN(INITIAL);
				return token;
			}

			/* Handle EOI conditions */
			"\n" {
				CHECK_EOI();
			}

			*/
			break;
		default:
			/* Impossible */
			assert(0);
	}
}

@end
