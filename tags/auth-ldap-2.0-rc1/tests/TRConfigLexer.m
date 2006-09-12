/*
 * TRConfigLexer.m
 * TRConfigLexer Unit Tests
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
 * 3. Neither the name of Landon Fuller nor the names of any contributors
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

#include <src/TRConfigLexer.h>
#include <src/TRConfigParser.h>

#include <check.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

/* Data Constants */
/* Path Constants */
#define DATA_PATH(relative)	TEST_DATA "/" relative
#define TEST_CONF		DATA_PATH("test-lineNumbers.conf")

START_TEST (test_parse) {
	TRConfigLexer *lexer;
	TRConfigToken *token;
	int configFD;

	/* Open our configuration file */
	configFD = open(TEST_CONF, O_RDONLY);
	fail_if(configFD == -1, "open() returned -1");

	lexer = [[TRConfigLexer alloc] initWithFD: configFD];
	fail_if(lexer == NULL, "-[[TRConfigLexer alloc] initWithFD:] returned NULL");

	while ((token = [lexer scan]) != NULL) {
		/* The configuration file was assembled so that all values match the,
		 * current line number -- that is to say, for any given key/value pair,
		 * the value is set to the current line number of that pair. */
		if ([token tokenID] == TOKEN_VALUE || [token tokenID] == TOKEN_SECTION_NAME || [token tokenID] == TOKEN_SECTION_START) {
			int value;

			/* Get the integer representation */
			fail_unless([token intValue: &value], "-[TRConfigToken getIntValue:] returned false. (String Value: %s)", [token cString]);

			/* Verify that the line number is correct */
			fail_unless(value == [token lineNumber], "-[TRConfigToken getLineNumber] out of sync. (Expected %d, got %d)", value, [token lineNumber]);
		}
		[token dealloc];
	}

	close(configFD);
	[lexer dealloc];
}
END_TEST


Suite *TRConfigLexer_suite(void) {
	Suite *s = suite_create("TRConfigLexer");

	TCase *tc_lex = tcase_create("Lexificate File");
	suite_add_tcase(s, tc_lex);
	tcase_add_test(tc_lex, test_parse);

	return s;
}
