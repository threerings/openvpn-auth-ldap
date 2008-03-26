/*
 * TRString.m vi:ts=4:sw=4:expandtab:
 * Brain-dead Dynamic Strings
 *
 * Copyright (c) 2005 - 2007 Landon Fuller <landonf@threerings.net>
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

#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <stdio.h>
#include <assert.h>

#include "util/strlcpy.h"

#include "util/TRString.h"

#include "util/xmalloc.h"

/**
 * OO String wrapper.
 */
@implementation TRString

- (void) dealloc {
    free(bytes);
    [super dealloc];
}


/**
 * Create a new string using the provided printf-style format
 * string and arguments.
 */
+ (TRString *) stringWithFormat: (const char *) format, ... {
    va_list ap;
    char *output;
    TRString *ret;

    va_start(ap, format);
    vasprintf(&output, format, ap);
    va_end(ap);

    assert(output != NULL);
    ret = [[[TRString alloc] initWithCString: output] autorelease];
    free(output);

    return ret;
}

/**
 * Initialize with a copy of the given C string.
 */
- (id) initWithCString: (const char *) cString {
    self = [self init];
    if (self != NULL) {
        numBytes = strlen(cString) + 1;
        bytes = xmalloc(numBytes);
        strlcpy(bytes, cString, numBytes);
    }
    return (self);
}

/**
 * Initialize with a copy of the provided TRString.
 */
- (id) initWithString: (TRString *) string {
    self = [self init];
    if (self != NULL) {
        numBytes = [string length];
        bytes = xmalloc(numBytes);
        strlcpy(bytes, [string cString], numBytes);
    }
    return (self);
}

/**
 * Initialize with a potentially non-NULL terminated string
 */
- (id) initWithBytes: (const char *) data numBytes: (size_t) length {
    self = [self init];
    if (self != NULL) {
        if (data[length] != '\0') {
            numBytes = length + 1;
            bytes = xmalloc(numBytes);
            strncpy(bytes, data, length);
            bytes[length] = '\0';
        } else {
            numBytes = length;
            bytes = xstrdup(data);
        }
    }
    return (self);
}

/**
 * Return the C string value.
 */
- (const char *) cString {
    return (bytes);
}

/**
 * Return the size in bytes.
 */
- (size_t) length {
    return (numBytes);
}

/**
 * Return a hash value for the receiver.
 * Hash algorithm borrowed from kazlib.
 */
- (unsigned long) hash {
    unsigned long randbox[] = {
        0x49848f1bU, 0xe6255dbaU, 0x36da5bdcU, 0x47bf94e9U,
        0x8cbcce22U, 0x559fc06aU, 0xd268f536U, 0xe10af79aU,
        0xc1af4d69U, 0x1d2917b5U, 0xec4c304dU, 0x9ee5016cU,
        0x69232f74U, 0xfead7bb3U, 0xe9089ab6U, 0xf012f6aeU,
    };
    const char *p;
    unsigned int hash = 0;

    for (p = bytes; *p != '\0'; p++) {
        hash ^= randbox[(*p + hash) & 0xf];
        hash = (hash << 1) | (hash >> 31);
        hash &= 0xffffffffU;
        hash ^= randbox[((*p >> 4) + hash) & 0xf];
        hash = (hash << 2) | (hash >> 30);
        hash &= 0xffffffffU;
    }

    return hash;
}

/**
 * Store the integer value in the provided
 * value argument, and return true if the conversion
 * was successful
 */
- (BOOL) intValue: (int *) value {
    long i;
    char *endptr;
    i = strtol(bytes, &endptr, 10);

    if (*endptr != '\0') {
        *value = 0;
        return (false);
    }

    if (i >= INT_MAX) {
        *value = INT_MAX;
        return (false);
    }

    if (i <= INT_MIN) {
        *value = INT_MIN;
        return (false);
    }

    *value = i;
    return (true);
}

/**
 * Append cString.
 */
- (void) appendCString: (const char *) cString {
    size_t len;

    if (numBytes == 0) {
        /* String not yet initialized */
        numBytes = strlen(cString) + 1;
        bytes = xmalloc(numBytes);
        strlcpy(bytes, cString, numBytes);
        return;
    }

    len = strlen(cString);
    /* numBytes includes the NULL terminator */
    numBytes = len + numBytes;
    bytes = xrealloc(bytes, numBytes);
    strncat(bytes, cString, len + 1);
}

/**
 * Append string.
 */
- (void) appendString: (TRString *) string {
    size_t len;

    if (numBytes == 0) {
        /* String not yet initialized */
        numBytes = [string length];
        bytes = xmalloc(numBytes);
        strlcpy(bytes, [string cString], numBytes);
        return;
    }

    len = [string length];
    /* numBytes and [string length] both include the NULL terminator */
    numBytes = len + numBytes - 1;
    bytes = xrealloc(bytes, numBytes);
    strncat(bytes, [string cString], len + 1);
}

/**
 * Append a single character.
 */
- (void) appendChar: (char) c {
    char s[2];
    s[0] = c;
    s[1] = '\0';
    [self appendCString: (const char *) &s];
}

/**
 * Return the index of the first match of the given C string.
 */
- (size_t) indexToCString: (const char *) cString {
    size_t index = 0;
    char *p;
    const char *s;
    for (p = bytes; *p != '\0'; p++) {
        char *q = p;
        for (s = cString; *s != '\0'; s++) {
            if (*q == *s) {
                q++;
                continue;
            } else
                break;
        }
        if (*s == '\0') {
            /* Full Match */
            return (index);
        }
        index++;
    }
    return (index);
}

/**
 * Return the index of the character following the first match
 * of the given C string.
 */
- (size_t) indexFromCString: (const char *) cString {
    size_t index = 0;
    char *p;
    const char *s;
    for (p = bytes; *p != '\0'; p++) {
        char *q = p;
        for (s = cString; *s != '\0'; s++) {
            if (*q == *s) {
                q++;
                continue;
            } else
                break;
        }
        if (*s == '\0') {
            /* Full Match */
            index += strlen(cString);
            return (index);
        }
        index++;
    }
    return (index);
}

/**
 * Return the index to the first match for any character
 * in the given set.
 */
- (size_t) indexToCharset: (const char *) cString {
    size_t index = 0;
    char *p;
    const char *s;
    for (p = bytes; *p != '\0'; p++) {
        for (s = cString; *s != '\0'; s++) {
            if (*p == *s)
                return (index);
        }
        index++;
    }
    return (index);
}

- (size_t) indexFromCharset: (const char *) cString {
    size_t index = 0;
    char *p;
    const char *s;
    for (p = bytes; *p != '\0'; p++) {
        for (s = cString; *s != '\0'; s++) {
            if (*p == *s) {
                index++;
                return (index);
            }
        }
        index++;
    }
    return (index);
}

- (char) charAtIndex: (size_t) index {
    return (*(bytes + index));
}

- (TRString *) substringToIndex: (size_t) index {
    TRString *string;
    char *cString;

    if (*(bytes + index) == '\0') {
        return (NULL);
    }

    string = [TRString alloc];
    cString = xmalloc(index + 1);

    strlcpy(cString, bytes, index + 1);
    [string initWithCString: cString];
    free(cString);
    return ([string autorelease]);
}

- (TRString *) substringFromIndex: (size_t) index {
    TRString *string;
    char *cString;

    if (*(bytes + index) == '\0') {
        return (NULL);
    }

    string = [TRString alloc];
    cString = xmalloc(numBytes - index);
    strlcpy(cString, bytes + index, numBytes - index);

    [string initWithCString: cString];
    free(cString);
    return ([string autorelease]);
}

- (TRString *) substringToCString: (const char *) cString {
    return ([self substringToIndex: [self indexToCString: cString]]);
}

- (TRString *) substringFromCString: (const char *) cString {
    return ([self substringFromIndex: [self indexFromCString: cString]]);
}

- (TRString *) substringToCharset: (const char *) cString {
    return ([self substringToIndex: [self indexToCharset: cString]]);
}

- (TRString *) substringFromCharset: (const char *) cString {
    return ([self substringFromIndex: [self indexFromCharset: cString]]);
}

@end
