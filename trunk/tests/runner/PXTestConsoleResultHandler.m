/*
 * Author: Landon Fuller <landonf@plausible.coop>
 * Copyright (c) 2008-2012 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */


#import "PXTestConsoleResultHandler.h"

#import "PXTestObjC.h"

#import <time.h>
#import <locale.h>
#import <langinfo.h>

/**
 * Console test result handler. All results are output to standard error.
 */
@implementation PXTestConsoleResultHandler

- (TRString *) dateString {
    struct tm tm;
    char datestring[256];

    setlocale (LC_ALL, "");
    time_t now = time(NULL);
    localtime_r(&now, &tm);
    size_t bytes = strftime(datestring, sizeof(datestring), nl_langinfo (D_T_FMT), &tm);
    if (bytes == 0)
        return nil;

    return [TRString stringWithCString: datestring];
}

// from PXTestResultHandler protocol
- (void) willExecuteTestCase: (PXTestCase *) testCase {
    TRString *output = [TRString stringWithFormat: "Test suite '%s' started at %s\n", 
                        class_getName([testCase class]), [[self dateString] cString]];
    fprintf(stderr, "%s", [output cString]);
}


// from PXTestResultHandler protocol
- (void) didExecuteTestCase: (PXTestCase *) testCase {
    TRString *output = [TRString stringWithFormat: "Test suite '%s' finished at %s\n", 
                        class_getName([testCase class]), [[self dateString] cString]];
    fprintf(stderr, "%s", [output cString]);
}


// from PXTestResultHandler protocol
- (void) didExecuteTestCase: (PXTestCase *) testCase selector: (SEL) selector {
    TRString *output = [TRString stringWithFormat: "Test case -[%s %s] completed at %s\n", 
                        class_getName([testCase class]), sel_getName(selector), [[self dateString] cString]];

    fprintf(stderr, "%s", [output cString]);
}

// from PXTestResultHandler protocol
- (void) didExecuteTestCase: (PXTestCase *) testCase selector: (SEL) selector withException: (PXTestException *) exception {
    TRString *output = [TRString stringWithFormat: "Test case -[%s %s] (%s:%d) failed with error: %s\n", 
                        class_getName([testCase class]), sel_getName(selector), [[exception fileName] cString], [exception lineNumber],
                        [[exception reason] cString]];

    fprintf(stderr, "%s", [output cString]);
}

// from PXTestResultHandler protocol
- (void) didSkipTestCase: (PXTestCase *) testCase selector: (SEL) selector reason: (TRString *) reason {
    TRString *output = [TRString stringWithFormat: "Test case -[%s %s] failed (%s) at %s\n", 
                        class_getName([testCase class]), sel_getName(selector), [reason cString], [[self dateString] cString]];
    
    fprintf(stderr, "%s", [output cString]);
}



@end
