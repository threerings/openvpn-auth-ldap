/*
 * configlexer.re
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

#include "ConfigLexer.h"

#include "configparser.h"

/*
 * re2c Configuration
 */
#define YYCTYPE      char	/* Input Symbol Type */
#define YYCURSOR     cursor	/* L-expression of type *YYCTYPE that points to the current input symbol */
#define YYLIMIT      limit	/* Expression of type *YYCTYPE that marks the end of the buffer */
#define YYMARKER     marker	/* L-expression of type *YYCTYPE that is used for backtracking information */
#define YYFILL(n)    [self fill: n]	/* YYFILL(n) is called when the buffer needs (re)filling */

#define YYDEBUG(state, current) printf("state: %d, current: '%c' (%d)\n", state, current, current);

/*
 * Macros
 */

#define CHECKEOI()   if (eoi) { return; }

@implementation ConfigLexer

- (void) dealloc {
	if (buffer)
		munmap(buffer, bufferLength);
	[super free];
}

- (ConfigLexer *) initWithFD: (int) fd {
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
	cursor = buffer;
	limit = cursor + bufferLength - 1;

	return (self);
}

- (void) fill: (int) length {
	/* We just need to prevent re2c from walking off the end of our buffer */
	assert(limit - cursor >= 0);
	if (cursor == limit) {
		/* Signal EOI */
		cursor = "\n";
		eoi = true;
	}
}

- (void) scan {
/*!re2c
/* vim syntax fix */

	any = .;

*/

config:
	token = cursor;

/*!re2c
/* vim syntax fix */

	/* Skip comments */
	"#".* {
		goto config;
	}

	/* Skip leading whitespace and blank lines (but be sure to check for EOI) */
	[ \t\n]+ {
		CHECKEOI()
		goto config;
	}

	/* Handle keys */
	[A-Za-z_-]+ {
		printf("Key: %.*s\n", cursor - token, token);
		goto value;
	}

	/* Handle unknown characters */
	any {
		// TODO explode here
		goto config;
	}

*/

value:
	token = cursor;
/*!re2c
/* vim syntax fix */

	/* Skip leading whitespace */
	[ \t]+

	/* The value may contain anything except \n */
	.* {
		printf("Value: %.*s\n", cursor - token, token);
	}

	/* Handle EOI conditions */
	"\n" {
		CHECKEOI()
		goto config;
	}

*/
}

@end
