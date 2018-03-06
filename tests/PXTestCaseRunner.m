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
#import <stdlib.h>

#include <Foundation/NSAutoreleasePool.h>

#import "PXTestCaseRunner.h"
#import "PXTestObjC.h"

/**
 * Implements runtime detection and execution of PLInstrumentCase instrumentation classes.
 */
@implementation PXTestCaseRunner

/**
 * Initialize the instrumentation runner with the provided result handler.
 */
- (id) initWithResultHandler: (id<PXTestResultHandler>) resultHandler {
    if ((self = [super init]) == nil)
        return nil;

    _resultHandler = [resultHandler retain];

    return self;
}

- (void) dealloc {
    [_resultHandler release];

    [super dealloc];
}

/**
 * Locate all subclasses of PLInstrumentCase registed with the Objective-C runtime, and
 * execute all instrumentation methods.
 *
 * @return Returns YES if all tests were run successfully, or NO if any errors were reported.
 *
 * @warning This method may be modified to return a more descriptive object type in the future.
 */
- (BOOL) runAllCases {
    Class *classes;
    int numClasses;

    /* Get the count of classes */
    classes = NULL;
    numClasses = objc_getClassList(NULL, 0);

    /* If none, nothing to do */
    if (numClasses == 0)
        return YES;

    /* Fetch all classes */        
    classes = malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);

    BOOL success = YES;
    for (int i = 0; i < numClasses; i++) {
        Class cls = classes[i];
        Class superClass = cls;
        BOOL isInstrument = NO;

        /* Determine if this is a subclass of PXTestCase. By starting with the class
         * itself, we skip over the non-subclassed PLInstrumentCase class. */
        while ((superClass = class_getSuperclass(superClass)) != NULL) {
            if (superClass == [PXTestCase class]) {
                isInstrument = YES;
                break;
            }
        }

        /* If it is an instrument instance, run the tests */
        if (isInstrument) {
            PXTestCase *obj = [[cls alloc] init];
            if (![self runCase: obj]) {
                success = NO;
            }
            [obj release];
        }
    }

    /* Clean up */
    free(classes);

    return success;
}

/**
 * Execute all test methods for the given test case.
 *
 * @param testCase The test case to run.
 * @return Returns YES if the test was run successfully, or NO if an error was reported.
 *
 * @warning This method may be modified to return a more descriptive object type in the future.
 */
- (BOOL) runCase: (PXTestCase *) testCase {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    Method *methods;
    unsigned int methodCount;

    /* Inform the result handler of initialization */
    [_resultHandler willExecuteTestCase: testCase];
    
    /* Iterate over the available methods */
    methods = class_copyMethodList([testCase class], &methodCount);
    BOOL success = YES;
    for (unsigned int i = 0; i < methodCount; i++) {
        Method m;
        SEL methodSel;
        char retType[256];

        /* Fetch the method meta-data */
        m = methods[i];
        methodSel = method_getName(m);
        method_getReturnType(m, retType, sizeof(retType));

        /* Only invoke methods that start with the name "test" */
        if (strstr(sel_getName(methodSel), "test") == NULL)
            continue;

        PXTestException *e = nil;
        [testCase setUp]; {
            void (*imp)(id self, SEL _cmd) = (void (*)(id self, SEL _cmd)) method_getImplementation(m);
            @try {
                imp(testCase, methodSel);
            } @catch (PXTestException *re) {
                success = NO;
                e = re;
            }
        } [testCase tearDown];

        /* Inform the result handler of method execution */
        if (e != nil) {
            [_resultHandler didExecuteTestCase: testCase selector: methodSel withException: e];
        } else {
            [_resultHandler didExecuteTestCase: testCase selector: methodSel];
        }
    }
    
    /* Inform the result handler of completion */
    [_resultHandler didExecuteTestCase: testCase];
    
    /* Clean up */
    if (methods != NULL)
        free(methods);
    
    [pool release];

    return success;
}

@end
