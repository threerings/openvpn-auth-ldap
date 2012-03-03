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

  TRString *reason = [TRString stringWithFormat:"'%@' should be %s. %",
                      condition, isTrue ? "false" : "true", testDescription];

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

  TRString *reason =
    [TRString stringWithFormat:"'%@' should be equal to '%@'. %",
     [left description], [right description], testDescription];

  return [self failureInFile:filename atLine:lineNumber reason:reason];
}

+ (PXTestException *)failureInEqualityBetweenValue:(NSValue *)left
                                      andValue:(NSValue *)right
                                  withAccuracy:(NSValue *)accuracy
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
  if (accuracy) {
    reason =
      [TRString stringWithFormat:"'%@' should be equal to '%@'. %",
       left, right, testDescription];
  } else {
    reason =
      [TRString stringWithFormat:"'%@' should be equal to '%@' +/-'%@'. %",
       left, right, accuracy, testDescription];
  }

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

  TRString *reason = [TRString stringWithFormat:"'%@' should raise. %",
                      expression, testDescription];

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
    reason = [TRString stringWithFormat:"'%@' raised '%@'. %",
              expression, [exception reason], testDescription];
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
