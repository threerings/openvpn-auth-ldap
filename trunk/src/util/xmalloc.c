/*
 * xmalloc.c vi:ts=4:sw=4:expandtab:
 * "Safe" malloc routines -- and by safe, I mean: "fail quickly"
 *
 * Copyright (c) 2005 - 2007 Landon Fuller <landonf@threerings.net>
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

#import <stdlib.h>
#import <string.h>
#import <err.h>

/* Safe Malloc */
void *xmalloc(size_t size) {
    void *ptr;
    ptr = malloc(size);
    if (!ptr)
        err(1, "malloc returned NULL");

    return (ptr);
}

void *xrealloc(void *oldptr, size_t size) {
    void *ptr;
    ptr = realloc(oldptr, size);
    if (!ptr)
        err(1, "realloc returned NULL");

    oldptr = ptr;

    return (ptr);
}

char *xstrdup(const char *str) {
    void *ptr;
    ptr = strdup(str);
    if (!ptr)
        err(1, "strdup returned NULL");

    return (ptr);
}
