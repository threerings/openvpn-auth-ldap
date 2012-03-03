/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 * Copyright (c) 2008 Plausible Labs Cooperative, Inc.
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

#import "TRObject.h"

#import "PXTestException.h"
#import "PXTestCase.h"
#import "util/TRString.h"

/**
 * Provides handling of test results. The results may be printed
 * to stderr, output as XML, etc.
 */
@protocol PXTestResultHandler <TRObject>

/**
 * Called when preparing to execute a test case.
 *
 * @param testCase The test case to be executed
 */
- (void) willExecuteTestCase: (PXTestCase *) testCase;

/**
 * Called when finished to executing a test case.
 */
- (void) didExecuteTestCase: (PXTestCase *) testCase;

/**
 * Called upon successful execution of an test case's test method.
 *
 * @param testCase The executed test case instance.
 * @param selector The selector executed.
 */
- (void) didExecuteTestCase: (PXTestCase *) testCase selector: (SEL) selector; 

/**
 * Called upon failed execution of an test case's test method.
 *
 * @param testCase The executed test case instance.
 * @param selector The selector executed.
 * @param exception The failure cause.
 */
- (void) didExecuteTestCase: (PXTestCase *) testCase selector: (SEL) selector withException: (PXTestException *) exception;

/**
 * If an test method can not be run, this method will be called.
 *
 * @param testCase The executed test case instance.
 * @param selector The selector executed.
 * @param reason Non-localized human readable reason that the instrumentation method was skipped.
 */
- (void) didSkipTestCase: (PXTestCase *) testCase selector: (SEL) selector reason: (TRString *) reason;

@end
