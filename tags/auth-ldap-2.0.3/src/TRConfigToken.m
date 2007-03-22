/*
 * TRConfigToken.m
 * Configuration Lexer Tokens
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

#include "TRConfigToken.h"

@implementation TRConfigToken

- (void) dealloc {
	if (_string)
		[_string release];
	[super dealloc];
}

- (id) initWithBytes: (const char *) data numBytes: (size_t) length lineNumber: (unsigned int) line tokenID: (int) tokenID {
	self = [self init];
	if (self != NULL) {
		_dataType = TOKEN_DATATYPE_STRING;
		_tokenID = tokenID;
		_lineNumber = line;
		_string = [[LFString alloc] initWithBytes: data numBytes: length];
		if (!_string) {
			[self release];
			return NULL;
		}
	}
	return (self);
}

- (int) tokenID {
	return _tokenID;
}

- (unsigned int) lineNumber {
	return _lineNumber;
}

/*!
 * Return the token's string value.
 */
- (LFString *) string {
	return _string;
}

/*!
 * Return the token's C string value.
 * @return NULL terminated C string. The result is only valid for the
 * lifetime of the TRConfigToken object.
 */
- (const char *) cString {
	return [_string cString];
}

/*!
 * Get the token's integer value.
 * Returns true on success, false on failure.
 * The integer value will be stored in the value argument.
 *
 * If the token is not a valid integer, value will be set to 0
 * and the method will return false.
 * If the token is larger than INT_MAX, value will be set to INT_MAX
 * and the method will return false. If the token is smaller than INT_MIN,
 * value will be set to INT_MIN and the method will also return false.
 *
 * @param value Pointer where the integer value will be stored
 * @result true on success, false on failure.
 */
- (BOOL) intValue: (int *) value {
	BOOL result;

	/* Check if the integer conversion has been cached */
	if (_dataType == TOKEN_DATATYPE_INT) {
		*value = _internalRep._intValue;
		return true;
	}

	/* Otherwise, do the conversion and return the result,
	 * caching on success */
	result = [_string intValue: value];
	if (result) {
		_dataType = TOKEN_DATATYPE_INT;
		_internalRep._intValue = *value;
	}

	return result;
}

/*!
 * Get the token's boolean value.
 * Returns true on success, false on failure.
 * The boolean value will be stored in the value argument.
 *
 * If the token is not a valid boolean ("yes", "no", "true", "false", "1", or "0",
 * value will be set to false and the method will return false.
 *
 * @param value Pointer where the boolean value will be stored
 * @result true on success, false on failure.
 */
- (BOOL) boolValue: (BOOL *) value {
	const char *cString;

	/* Check if the integer conversion has been cached */
	if (_dataType == TOKEN_DATATYPE_BOOL) {
		*value = _internalRep._boolValue;
		return (YES);
	}

	/* Otherwise, do the conversion and return the result,
	 * caching on success */
	cString = [_string cString];

	if (strcasecmp(cString, "yes") == 0 || strcasecmp(cString, "true") == 0 || strcasecmp(cString, "1") == 0) {
		_dataType = TOKEN_DATATYPE_BOOL;
		_internalRep._boolValue = YES;
		*value = YES;
		return (YES);
	} else if (strcasecmp(cString, "no") == 0 || strcasecmp(cString, "false") == 0 || strcasecmp(cString, "0") == 0) {
		_dataType = TOKEN_DATATYPE_BOOL;
		_internalRep._boolValue = NO;
		*value = NO;
		return (YES);
	}
	*value = NO;
	return (NO);
}


@end
