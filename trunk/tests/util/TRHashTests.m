/*
 * TRHash.m vi:ts=4:sw=4:expandtab:
 * TRHash Unit Tests
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

#include <check.h>

#include <TRVPNPlugin.h>

START_TEST(test_initWithCapacity) {
    TRHash *hash = [[TRHash alloc] initWithCapacity: 42];
    [hash release];
}
END_TEST

START_TEST(test_isFull) {
    TRHash *hash = [[TRHash alloc] initWithCapacity: 0];
    fail_unless([hash isFull]);
    [hash release];
}
END_TEST

START_TEST(test_setObjectForKey) {
    TRHash *hash = [[TRHash alloc] initWithCapacity: 1];
    TRString *string = [[TRString alloc] initWithCString: "Hello, World"];
    unsigned int refCount = [string retainCount];

    [hash setObject: string forKey: string];
    /* Verify that the object has been retained twice:
     * - Once as the value
     * - Once as the key
     */
    fail_unless([string retainCount] == refCount + 2);

    /* Release our hash table */
    [hash release];

    /* Verify that the object has been released */
    fail_unless([string retainCount] == refCount);

    [string release];
}
END_TEST

/*
 * Verifies that replacing a key correctly releases key and associated value
 */
START_TEST(test_setObjectForKey_replacement) {
    TRHash *hash = [[TRHash alloc] initWithCapacity: 1];
    TRString *key = [[TRString alloc] initWithCString: "Key"];
    TRString *value1 = [[TRString alloc] initWithCString: "Hello, World"];
    TRString *value2 = [[TRString alloc] initWithCString: "Goodbye, World"];
    unsigned int refCount = [key retainCount];

    /* Insert value1 */
    [hash setObject: value1 forKey: key];
    fail_unless([key retainCount] == refCount + 1);

    /* Replace the node */
    [hash setObject: value2 forKey: key];
    fail_unless([key retainCount] == refCount + 1);
    fail_unless([value1 retainCount] == refCount);

    [hash release];
    /* Verify that the objects have been released */
    fail_unless([key retainCount] == refCount);
    fail_unless([value1 retainCount] == refCount);
    fail_unless([value2 retainCount] == refCount);

    [key release];
    [value1 release];
    [value2 release];
}
END_TEST

START_TEST(test_removeObjectForKey) {
    TRHash *hash = [[TRHash alloc] initWithCapacity: 1];
    TRString *key = [[TRString alloc] initWithCString: "Key"];
    TRString *value = [[TRString alloc] initWithCString: "Value"];
    unsigned int refCount = [key retainCount];

    /* Insert */
    [hash setObject: value forKey: key];

    /* Remove */
    [hash removeObjectForKey: key];

    /* Validate refCounts */
    fail_unless([key retainCount] == refCount);
    fail_unless([value retainCount] == refCount);

    /* Clean up */
    [key release];
    [value release];
    [hash release];
}
END_TEST

START_TEST(test_valueForKey) {
    TRHash *hash = [[TRHash alloc] initWithCapacity: 1];
    TRString *key = [[TRString alloc] initWithCString: "Key"];
    TRString *value = [[TRString alloc] initWithCString: "Value"];

    /* Insert */
    [hash setObject: value forKey: key];

    /* Get value */
    fail_unless([hash valueForKey: key] == value);

    /* Clean up */
    [hash release];
    [key release];
    [value release];
}
END_TEST

START_TEST(test_keyEnumerator) {
    TRHash *hash = [[TRHash alloc] initWithCapacity: HASHCOUNT_T_MAX];
    TRString *key = [[TRString alloc] initWithCString: "Key"];
    TRString *value = [[TRString alloc] initWithCString: "Value"];
    TREnumerator *iter;
    id obj;

    /* Insert */
    [hash setObject: value forKey: key];
    [hash setObject: key forKey: value];

    /* Grab an enumerator */
    iter = [hash keyEnumerator];
    obj = [iter nextObject];
    fail_unless(obj == value || obj == key);
    obj = [iter nextObject];
    fail_unless(obj == value || obj == key);

    /* Clean up */
    [hash release];
    [key release];
    [value release];
}
END_TEST


Suite *TRHash_suite(void) {
    Suite *s = suite_create("TRHash");

    TCase *tc_hash = tcase_create("Hash");
    suite_add_tcase(s, tc_hash);
    tcase_add_test(tc_hash, test_initWithCapacity);
    tcase_add_test(tc_hash, test_isFull);
    tcase_add_test(tc_hash, test_setObjectForKey);
    tcase_add_test(tc_hash, test_setObjectForKey_replacement);
    tcase_add_test(tc_hash, test_removeObjectForKey);
    tcase_add_test(tc_hash, test_valueForKey);
    tcase_add_test(tc_hash, test_keyEnumerator);

    return s;
}
