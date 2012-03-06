//
//  File derived from: GTMSenTestCase.m
//
//  Copyright 2007-2008 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import <stdarg.h>
#import "PXTestException.h"

@interface PXTestException (PrivateMethods)
+ (PXTestException *)failureInFile:(TRString *)filename
                        atLine:(int)lineNumber
                        reason:(TRString *)reason;
@end

/**
 * A test case exception. Provides API required by the SenTestCase-compatible assertion macros.
 */ 
@implementation PXTestException

+ (PXTestException *)failureInFile:(TRString *)filename
                        atLine:(int)lineNumber
               withDescription:(TRString *)formatString, ... {

  TRString *testDescription = nil;
  if (formatString) {
    va_list vl;
    va_start(vl, formatString);
    testDescription =
      [[[TRString alloc] initWithFormat:[formatString cString] arguments:vl] autorelease];
    va_end(vl);
  } else {
    testDescription = [TRString stringWithCString: ""];
  }

  TRString *reason = testDescription;

  return [self failureInFile:filename atLine:lineNumber reason:reason];
}

+ (PXTestException *)failureInCondition:(TRString *)condition
                             isTrue:(BOOL)isTrue
                             inFile:(TRString *)filename
                             atLine:(int)lineNumber
                    withDescription:(TRString *)formatString, ... {

  TRString *testDescription = nil;
  if (formatString) {
    va_list vl;
    va_start(vl, formatString);
    testDescription =
      [[[TRString alloc] initWithFormat:[formatString cString] arguments:vl] autorelease];
    va_end(vl);
  } else {
    testDescription = [TRString stringWithCString: ""];
  }

  TRString *reason = [TRString stringWithFormat:"'%s' should be %s. %s",
                      [condition cString], isTrue ? "false" : "true", [testDescription cString] ];

  return [self failureInFile:filename atLine:lineNumber reason:reason];
}

+ (PXTestException *)failureInEqualityBetweenObject:(id)left
                                      andObject:(id)right
                                         inFile:(TRString *)filename
                                         atLine:(int)lineNumber
                                withDescription:(TRString *)formatString, ... {
  TRString *testDescription = nil;
  if (formatString) {
    va_list vl;
    va_start(vl, formatString);
    testDescription =
      [[[TRString alloc] initWithFormat:[formatString cString] arguments:vl] autorelease];
    va_end(vl);
  } else {
    testDescription = [TRString stringWithCString: ""];
  }

// XXX - We need to support -description here
#if TODO_TRSTRING_FORMAT
  TRString *reason =
    [TRString stringWithFormat:"'%@' should be equal to '%@'. %s",
     [left description], [right description], [testDescription cString]];
#else
 TRString *reason =
   [TRString stringWithFormat:"'%p' should be equal to '%p'. %s",
    left, right, [testDescription cString]];
#endif

  return [self failureInFile:filename atLine:lineNumber reason:reason];
}

+ (PXTestException *)failureInEqualityBetweenValue:(id)left
                                      andValue:(id)right
                                  withAccuracy:(id)accuracy
                                        inFile:(TRString *)filename
                                        atLine:(int)lineNumber
                               withDescription:(TRString *)formatString, ... {

  TRString *testDescription = nil;
  if (formatString) {
    va_list vl;
    va_start(vl, formatString);
    testDescription =
      [[[TRString alloc] initWithFormat:[formatString cString] arguments:vl] autorelease];
    va_end(vl);
  } else {
    testDescription = [TRString stringWithCString: ""];
  }

  TRString *reason;
// XXX - We need to support -description here
#if TODO_TRSTRING_FORMAT
  if (accuracy) {
    reason =
      [TRString stringWithFormat:"'%@' should be equal to '%@'. %@",
       left, right, testDescription];
  } else {
    reason =
      [TRString stringWithFormat:"'%@' should be equal to '%@' +/-'%@'. %@",
       left, right, accuracy, testDescription];
  }
#else /* HAVE_FRAMEWORK_FOUNDATION */
  if (accuracy) {
    reason =
      [TRString stringWithFormat:"'%p' should be equal to '%p'. %s",
       left, right, [testDescription cString]];
  } else {
    reason =
      [TRString stringWithFormat:"'%p' should be equal to '%p' +/-'%p'. %s",
       left, right, accuracy, [testDescription cString]];
  }
#endif

  return [self failureInFile:filename atLine:lineNumber reason:reason];
}

+ (PXTestException *)failureInRaise:(TRString *)expression
                         inFile:(TRString *)filename
                         atLine:(int)lineNumber
                withDescription:(TRString *)formatString, ... {

  TRString *testDescription = nil;
  if (formatString) {
    va_list vl;
    va_start(vl, formatString);
    testDescription =
      [[[TRString alloc] initWithFormat:[formatString cString] arguments:vl] autorelease];
    va_end(vl);
  } else {
    testDescription = [TRString stringWithCString: ""];
  }

  TRString *reason = [TRString stringWithFormat:"'%s' should raise. %s",
                      [expression cString], [testDescription cString]];

  return [self failureInFile:filename atLine:lineNumber reason:reason];
}

+ (PXTestException *)failureInRaise:(TRString *)expression
                      exception:(PXTestException *)exception
                         inFile:(TRString *)filename
                         atLine:(int)lineNumber
                withDescription:(TRString *)formatString, ... {

  TRString *testDescription = nil;
  if (formatString) {
    va_list vl;
    va_start(vl, formatString);
    testDescription =
      [[[TRString alloc] initWithFormat:[formatString cString] arguments:vl] autorelease];
    va_end(vl);
  } else {
    testDescription = [TRString stringWithCString: ""];
  }

  TRString *reason;
  if ([exception isKindOfClass: [PXTestException class]]) {
    // it's our exception, assume it has the right description on it.
    reason = [exception reason];
  } else {
    // not one of our exception, use the exceptions reason and our description
    reason = [TRString stringWithFormat:"'%s' raised '%s'. %s",
              [expression cString], [[exception reason] cString], [testDescription cString]];
  }

  return [self failureInFile:filename atLine:lineNumber reason:reason];
}

/**
 * Initialize a new test failure exception.
 *
 * @param reason The test failure reason.
 * @param fileName The test failure file name.
 * @param lineNumber The line number at which the test failure was thrown.
 */
- (id) initWithReason: (TRString *) reason fileName: (TRString *) fileName lineNumber: (int) lineNumber {
    if ((self = [super init]) == nil)
        return nil;

    _reason = [reason retain];
    _fileName = [fileName retain];
    _lineNumber = lineNumber;

    return self;
}

- (void) dealloc {
    [_reason release];
    [_fileName release];

    [super dealloc];
}

/**
 * Return the test failure reason.
 */        
- (TRString *) reason {
    return _reason;
}

/**
 * Return the file name containing the failed test.
 */
- (TRString *) fileName {
    return _fileName;
}

/**
 * Return the line number at which the test failure was thrown.
 */
- (int) lineNumber {
    return _lineNumber;
}


@end

@implementation PXTestException (GTMSenTestPrivateAdditions)

+ (PXTestException *)failureInFile:(TRString *)filename
                        atLine:(int)lineNumber
                        reason:(TRString *)reason {
    return [[[self alloc] initWithReason: reason fileName: filename lineNumber: lineNumber] autorelease];
}

@end
