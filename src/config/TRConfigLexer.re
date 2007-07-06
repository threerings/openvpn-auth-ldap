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
#define YYCTXMARKER  _ctxMarker /* L-expression of type *YYCTYPE that is used for trailing context back tracking information */
#define YYFILL(n)    [self fill: n]	/* YYFILL(n) is called when the buffer needs (re)filling */

#define YYDEBUG(state, current) printf("state: %d, current: '%c' (%d)\n", state, current, current);

/*
 * Macros
 */

/* Increment line count */
#define INCR_LINE()	_lineNumber++

/* Switch to a start condition */
#define BEGIN(cond)	( _condition = LEXER_SC_ ## cond)

/* Declare a start condition */
#define SC(cond)	LEXER_SC_ ## cond: LEXER_SC_ ## cond

/* Check for end-of-input */
#define CHECK_EOI()	if (_eoi) { return NULL; }

/* Skip a token */
#define SKIP(cond)	CHECK_EOI(); goto LEXER_SC_ ## cond

/* Get the current token length */
#define TOKEN_LENGTH()	((_eoi ? _eoi : _cursor) - _token)

@implementation TRConfigLexer

- (void) dealloc {
	if (buffer)
		munmap(buffer, bufferLength);
	[super dealloc];
}

- (id) initWithFD: (int) fd {
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
	_lineNumber = 1;
	_condition = LEXER_SC_INITIAL;
	_cursor = buffer;
	_limit = _cursor + bufferLength - 1;

	return (self);
}

- (void) fill: (int) length {
	/* We just need to prevent re2c from walking off the end of our buffer */
	assert(_limit - _cursor >= 0);
	if (_cursor == _limit) {
		/* Save the cursor and signal EOI */
		_eoi = _cursor;
		_cursor = "\n";
	}
}

- (TRConfigToken *) scan {
	TRConfigToken *token;
	/*!re2c /* vim syntax fix */
	any = .;
	key = [A-Za-z0-9_-]+;
	*/

	switch (_condition) {
		case SC(INITIAL):
			_token = _cursor;
			/*!re2c /* vim syntax fix */

			/* Skip white space */
			[ \t]+ {
				SKIP(INITIAL);
			}

			/* Skip comments */
			"#".* {
				SKIP(INITIAL);
			}

			/* Keys */
			key {
				token = [[TRConfigToken alloc] initWithBytes: _token
								    numBytes: TOKEN_LENGTH()
								  lineNumber: _lineNumber
								     tokenID: TOKEN_KEY];
				BEGIN(VALUE);
				return token;
			}

			/* Sections */
			"<" {
				SKIP(SECTION);
			}

			/* Skip blank lines */
			"\n" {
				INCR_LINE();
				SKIP(INITIAL);
			}

			/* Handle unknown characters */
			any {
				// TODO explode here
				printf("Unknown character: '%c' (%d)\n", yych, yych);
				return NULL;
			}

			*/

			break;

		/* Section Declarations */
		case SC(SECTION):
			_token = _cursor;
			/*!re2c /* vim syntax fix */

			/* Unnamed section */
			key">" {
				/* Drop the trailing ">" */
				token = [[TRConfigToken alloc] initWithBytes: _token
								    numBytes: TOKEN_LENGTH() - 1
								  lineNumber: _lineNumber
								     tokenID: TOKEN_SECTION_START];
				return token;
			}

			/* Named section */
			key/[ \t]+ {
				token = [[TRConfigToken alloc] initWithBytes: _token
								    numBytes: TOKEN_LENGTH()
								  lineNumber: _lineNumber
								     tokenID: TOKEN_SECTION_START];
				BEGIN(SECTION_NAME);
				return token;
			}

			/* Section end */
			"/"key">" {
				/* Drop the leading '/' and trailing ">" */
				token = [[TRConfigToken alloc] initWithBytes: _token + 1
								    numBytes: TOKEN_LENGTH() - 2
								  lineNumber: _lineNumber
								     tokenID: TOKEN_SECTION_END];
				return token;
			}

			/* End of line returns to the initial state */
			"\n" {
				INCR_LINE();
				SKIP(INITIAL);
			}

			*/

			break;

		case SC(SECTION_NAME):
			_token = _cursor;
			/*!re2c /* vim syntax fix */
			/* Skip white space */
			[ \t]+ {
				SKIP(SECTION_NAME);
			}

			/* Section name */
			key">" {
				/* Drop the trailing ">" */
				token = [[TRConfigToken alloc] initWithBytes: _token
								    numBytes: TOKEN_LENGTH() - 1
								  lineNumber: _lineNumber
								     tokenID: TOKEN_SECTION_NAME];
				BEGIN(INITIAL);
				return token;
			}

			/* End of line returns to the initial state */
			"\n" {
				INCR_LINE();
				SKIP(INITIAL);
			}

			*/

		/* Values */
		case SC(VALUE):
			_token = _cursor;
			/*!re2c /* vim syntax fix */
			[ \t]+ {
				SKIP(VALUE);
			}

			/* Skip trailing comments */
			"#".* {
				SKIP(VALUE);
			}

			/* Value is a quoted string */
			"\"" {
				SKIP(STRING_VALUE);
			}

			/* Single word value, skip leading whitespace */
			[^ \t\n"]+ { /* " vim syntax fix */
				token = [[TRConfigToken alloc] initWithBytes: _token
								    numBytes: TOKEN_LENGTH()
								  lineNumber: _lineNumber
								     tokenID: TOKEN_VALUE];
				return token;
			}

			/* End of line returns to the initial state */
			"\n" {
				INCR_LINE();
				SKIP(INITIAL);
			}

			*/
			break;

		/* Quoted string values */
		case SC(STRING_VALUE):
			_token = _cursor;

			/*!re2c /* vim syntax fix */

			/* Skip trailing comments */
			"#".* {
				SKIP(STRING_VALUE);
			}

			/* Quoted strings */
			/* "\""[^\"]+"\"" { */
			[^"]+"\"" {
				/* Skip the trailing '"' */
				token = [[TRConfigToken alloc] initWithBytes: _token
								    numBytes: TOKEN_LENGTH() - 1
								  lineNumber: _lineNumber
								     tokenID: TOKEN_VALUE];
				return token;
			}

			/* End of line returns to the initial state */
			"\n" {
				INCR_LINE();
				SKIP(INITIAL);
			}

			*/
			break;

		default:
			/* Impossible */
			assert(0);
	}

	/* Never reached */
	return nil;
}

@end
